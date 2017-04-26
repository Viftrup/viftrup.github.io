---
layout: post
title: "DWH, part 2: Architecture"
author: Dmytro Lytvyn
categories: DWH
---

Let's quickly recall the requirements to the DWH we came up with in the [first article](/2017/02/06/dwh-part-1-requirements/):

1. DWH must be a separate system with SQL interface, holding the information from various data sources.
2. The tables structure in the DWH should preferably be as close as possible to that of the source systems.
3. DWH must support incremental data loading and ensure the best performance for reading and writing the data.
4. DWH design must support the loading processes that properly handle the duplicates, missing data, etc.
5. All changes of the source data must be reflected in the DWH history tables.

Now, we can discuss how to approach the implementation of the DWH system, satisfying these requirements.

## 1. Choosing the system

The easiest way to have a separate system with SQL interface is to set up a new database server (it must not be the same physical machine as one of the operational databases, of course). It can be a cloud server like Amazon Redshift, or a normal server, preferably in a Data Center, with all proper monitoring and high availability cluster setup.

Data migration can be set up natively between the DBMS of the same provider (Oracle to Oracle, SQL Server to SQL Server or Postgres to Postgres), so you might want to choose for DWH the same DBMS provider as for your biggest operational database. Of course, it will not solve all your ETL needs, and you will have to choose and set up a proper ETL solution for your DWH, supporting various types of jobs, scheduling and dependencies between them. I will cover this topic in future articles.

## 2. Tables structure

Moving on to the second requirement, we can set up a similarly structured database by just copying the tables structure 1:1 from the operational databases. Later, we'll discuss what minor changes are needed to satisfy other DWH requirements.

For simplicity, let's assume we will simply copy the data from the operational database to our DWH fully every day, keeping the same tables structure. Now we can move on to other requirements: incremental loading, handling duplicates and storing the changes history.

## 3. Incremental loading

### Getting the source data

There are several approaches for getting the source data incrementally that I personally observed in real systems, but let's try to find the one that will work for all situations.

**Option #1**: using the date_created field, always delete the last 3 days (for example) of data, and insert again everything created within those last 3 days.

It will only work with the data that never changes, because you won't load a recently changed record if it was created more than 3 days ago, and if the date_created itself is changed, you might either load the same record twice, or just completely miss it.

**Option #2**: load all records where date_created or record ID is bigger than the maximal date or ID you already have in your table.

This, again, eliminates the possibility to load the changes, plus it requires you to either store the maximal date/ID per source table somewhere, or select it from DWH tables dynamically, and somehow link this information to the source systems. And joining data between separate systems is a bad idea from the performance point of view. 
Moreover, nobody can guarantee that the newly created ID or even date_created is always bigger than previous values in the same table.

**Option #3**: loading the most recent changes using date_updated column.

At this point, we realized that we need a date_updated column in almost every table we load from, unless the data in the table is never updated by design (audit log, website tracking events, etc.) - then it's enough to have just date_created column, or just a tiny dimension table (countries or payment methods) - then it can be just fully loaded every time.

Luckily, such column is very easy to implement with a default value of now() or current_timestamp for this column (just as it should be for date_created), and a trigger on row update, setting it to current timestamp again.

However, I saw examples when the value in date_updated column is set by a backend application, and not on a database level. This is of course wrong, because we can't rely on this column to be updated properly. For example, you should expect the cases when the record is updated (manually), but the date_updated remains unchanged, or has an earlier date than date_created for the same record, etc.

In case the data in the table can be altered, but date_updated column is not available (for whatever reasons), we can only load the full table to get all the changes. This is also necessary when the data can be deleted from the source table, and we must somehow reflect it in the DWH. In such situations, I usually load daily only the new records if possible (using date_created), and perform a full table synchronization once per week, for example.

For incremental loading, we'll need a set of so-called "staging" tables of exactly the same structure as our source tables. We'll use them as a temporary disposable buffer between the source system and DWH tables. Normally, the amount of data in staging tables is much smaller than in source tables, because we only load the recently created/updated records to them, and then copy the data to the target tables.

If we load the data from untyped data sources, like CSV files, we can choose to have all staging tables columns typed as varchar, so that the loading process doesn't fail on type conversions, but then we have to manage such issues when loading the data from staging to target tables. Some ETL processes allow to store the "bad" records in separate tables for further investigation, and load all "good" ones.

### Merging the data

#### Traditional approach

We made sure we're not missing any new or changed records now, but how to merge them with our previously loaded records? For that, we need to know the Primary Keys for every table (one or more columns that uniquely identify the record and can't be changed themselves). Knowing them, we can just insert all new records (where PK doesn't exist in the target table yet), and update all columns for the existing records with the updated values.

This method will work, but there are two performance/usability concerns:

- To find out whether you need to insert or to update a record, you need to scan the whole target table for every record in a staging table, to see if it already exists there. This becomes even harder if the table's Primary Key is composite (consists of two or more columns). SQL becomes clumsy:

Syntax with NOT IN for multiple columns, working in Postgres/Oracle:

```sql
-- Inserting new records
insert into target_table
select *
from staging_table s
where (s.pk_column1, s.pk_column2) not in (
    select t.pk_column1, t.pk_column2 from target_table t
);
```

More generic syntax using LEFT JOIN:

```sql
-- Inserting new records
insert into target_table
select *
from staging_table s
    left join target_table t
        on t.pk_column1 = s.pk_column1
            and t.pk_column2 = s.pk_column2
where t.pk_column1 is null
;
```

Another syntax using NOT EXISTS subquery, working in SQL Server:

```sql
-- Inserting new records
insert into target_table
select *
from staging_table s
where not exists (
    select 1
    from target_table t
    where t.pk_column1 = s.pk_column1
        and t.pk_column2 = s.pk_column2
);
```

- For every record that already exists in the target table, you will run a table update statement, even if nothing was changed. Or, you will have to compare every column's value in staging and target tables (using the slow OR conditions), taking into consideration NULLs.

To deal with NULLs, we could write 3 (!) OR conditions per column:

```sql
-- Updating changed records
update target_table t
set
    text_column1 = s.text_column1,
    int_column2 = s.int_column2,
    date_column3 = s.date_column3
from staging_table s
where t.pk_column1 = s.pk_column1
    and t.pk_column2 = s.pk_column2
    and (
        t.text_column1 != s.text_column1
        or (t.text_column1 is null and s.text_column1 is not null)
        or (t.text_column1 is not null and s.text_column1 is null)
        --
        or t.int_column2 != s.int_column2
        or (t.int_column2 is null and s.int_column2 is not null)
        or (t.int_column2 is not null and s.int_column2 is null)
        --
        or t.date_column3 != s.date_column3
        or (t.date_column3 is null and s.date_column3 is not null)
        or (t.date_column3 is not null and s.date_column3 is null)
    )
;
```

Alternatively, we can use coalesce(), and either set the NULL value to some "magical" values, like -1 for integers and '0001-01-01' for dates (which is ugly), or just cast() the value to varchar and set NULL values to empty strings, and then compare them.

```sql
-- Updating changed records
update target_table t
set
    text_column1 = s.text_column1,
    int_column2 = s.int_column2,
    date_column3 = s.date_column3
from staging_table s
where t.pk_column1 = s.pk_column1
    and t.pk_column2 = s.pk_column2
    and (
        colesce(t.text_column1, '<NULL>') != colesce(s.text_column1, '<NULL>')
        or colesce(cast(t.int_column2 as varchar), '') != colesce(cast(s.int_column2 as varchar), '')
        or colesce(to_char(t.date_column3, 'YYYY-MM-DD'), '') != colesce(to_char(s.date_column3, 'YYYY-MM-DD'), '')
    )
);
```

Now imagine you need to write that for a table with 130 columns (i.e. Snowplow events), and for 200 more source tables with different keys and data types? Of course, this SQL is unmanageable and very slow, because we're joining our target table to the staging table 2 times just to load new/updated data, and using a lot of OR conditions.

#### Optimized approach

Let's think how to optimize this from the performance point of view, and also whether we can make those SQLs more generic.

##### PK Lookup table

First of all, how to avoid scanning the whole target table just to check, whether the record already exists in it? One obvious solution is to just have an additional small table, only consisting of this primary key and nothing else. Then, we can join it wherever we need to without any serious performance issues.

But what about those composite (multi-column) primary keys? We don't want our small dictionary table to contain an arbitrary number of columns with random names for every source table we load. In fact, it would be better if all such "helper" tables had exactly the same structure.

To solve this, I prefer to concatenate all source primary key columns into one string value, and call it a Business Key (a key that makes sense for the business), and generate a corresponding numeric Entity Key (surrogate key for this entity), which would be used as a unified key for this table across the whole DWH (including Foreign Keys in other tables). Therefore, every target table should be enriched with one more column: entity_key, and should have a small "helper" table alongside it - let's call it "PK Lookup", containing the columns entity_bk (varchar) and entity_key (bigint). We can simply create a sequence for every target table and use it to generate Entity Keys for every Business key as soon as it's inserted to the PK Lookup table.

This is the structure of our PK Lookup table:

```sql
create sequence target_table_seq;

create table target_table_pk_lookup (
    entity_bk varchar not null primary key,
    entity_key bigint not null default nextval('target_table_seq')
);
```

Since the primary key columns can have different data types, we can use the same approach as for comparing fields for changes: convert to varchar and use coalesce to handle NULLs:

```sql
coalesce(cast(s.pk_column1 as varchar), '') || '^' ||  coalesce(cast(s.pk_column2 as varchar), '') as entity_bk
```

The ^ character you see above helps to avoid treating different PKs, which concatenate to the same value, as the same PK. For example, both '123' \|\| '123' and '12' \|\| '3123' result in '123123'. Using ^ (or any other rarely-used character) turns them into '123^123' and '12^3123', respectively.

##### Batch Info table

One more problem we need to address is that ugly comparison of each and every column's value, to find out whether the record was changed or not. This is especially problematic when we synchronize the full table (by mistake, or in case when date_updated is not available, or when we also need to locate and mark the deleted records). We want to make our DWH design as bulletproof as possible, so that there were no implicit rules like "never load the full source table to staging".

What if we somehow calculate the hash of every record we load to our DWH, and then simply compare it with the hash for incoming records? If the hash has changed, we need to update the record, if not - we don't touch it. Moreover, we could store those hashes in a separate small "helper" table (along with a unified Entity Key we already have) and then we don't even have to read our big target table at all during the data load process!

To calculate the hash for the whole record, we can cast all the records except primary keys to varchar (depending on the data type), concatenate them together and use for example MD5 function to get our 128-character hash for the record.

I would not like to store it in the same PK Lookup table we invented, because that table must stay as small as possible to serve one goal - figuring out whether we already have this Business Key loaded to the target table in DWH or not.

Hash value for every record serves a completely different goal: figuring out whether the record was changed or not, and for some biggest tables we don't even need to check for changes at all (audit log, or website tracking, as I mentioned earlier). Therefore, it doesn't make sense to have a separate varchar column with a hash for every record in their PK Lookup tables.

Plus, and we also need to store some additional metadata fields (ETL batch number and loading date, and others) somewhere, and it would be a perfect place for this optional record hash column. I'll call this new "helper" table "Batch Info".

Here's the current structure of our Batch Info table:

```sql
create table target_table_batch_info (
    entity_key bigint not null primary key,
    hash varchar(128),
    batch_date timestamp not null,
    batch_number bigint not null
);
```

##### Tracking deleted records

We already mentioned the possible requirement to mark some records as "deleted". Of course, we don't want to actually delete anything from DWH, but sometimes we need to know, whether the record was deleted or not in the source system. For that, we can use "Is Deleted" flag, and store it in our "Batch Info" table. For such flags, I personally prefer using the "integer" data type, and not "boolean", because it might not be supported by the DBMS, and I would like to have the DWH architecture as portable as possible.

After adding the new column, we have the following structure of our Batch Info table:

```sql
create table target_table_batch_info (
    entity_key bigint not null primary key,
    is_deleted smallint not null default 0,
    hash varchar(128),
    batch_date timestamp not null,
    batch_number bigint not null
);
```

##### Inferred records

Since we mentioned the primary keys and foreign keys, let's discuss what happens if our currently loaded record has a reference to another table, but that table doesn't contain the corresponding key yet. Let's say, since our last data load, a new record was created in Customer table in the operational database, and it has a foreign key to Address table. But when we load this Customer record, we try to get the Entity Key for this Address in out DWH, and we see that it was not loaded yet. Maybe we simply did not load Address table yet, or maybe there is an inconsistency in the source tables. Such problem is often referred to as *"Late Arriving Dimensions"*, although it may as well happen with the fact tables.

If we simply keep this broken referred Entity Key value as NULL, we'll have to somehow track the appearance of that key in Address table and then update all records in all tables that are linked to it. Of course, that's not a good approach. A good practice in such cases is to create so-called inferred keys (dummy records). We will add any keys, missing in the referenced FK table, to that table, and populate the original Business Key column with the value we know, but keep all other columns NULL. Alternatively, we can only insert a record to the PK Lookup table, but not to the actual target table. We will also mark this record as "inferred", to be sure we overwrite it as soon as the original record for that table arrives. So, we need to also add the "Is Inferred" flag to the metadata of every record in "Batch Info" table.

This is the resulting structure of our Batch Info table:

```sql
create table target_table_batch_info (
    entity_key bigint not null primary key,
    is_inferred smallint not null default 0,
    is_deleted smallint not null default 0,
    hash varchar(128),
    batch_date timestamp not null,
    batch_number bigint not null
);
```

## 4. Handling duplicates

This requirement will be easy to fulfill, because we already have defined a Business Key for every Entity we load, and even found an optimized approach as to how to figure out, whether the Business Key already exists in the target table or not.

But we still haven't considered the case, when there are possible duplicates in the source table, or in the staging table we load from (for example, because of some issue with the ETL process). Of course, we need to load only one of such duplicated records, but the question is - which one? Preferrably, the one with the most recent data. This is where we also need date_updated column. We can assign the duplicated records the sequential numbers using the analytical function row_number(), and sort them by date_updated in descending order. But what if even the date_updated is the same for the duplicated records? If the records are completely equal, we don't care which one to take, but what if at least one field differs? Well, we still need to choose only one, but what is important, is that we always select the same one if we run the script twice, or load the same data on the different servers. Luckily, we already have an answer for comparing the differences in two records, which is the Hash field. It's (almost) guaranteed to be different for different records, so we can use it in the "order by" statement to always order the records in the same way.

As a result, we have the following calculation of the row number per Business Key and we will only load the records with row_number = 1:

```sql
row_number() over (partition by entity_bk order by date_updated desc nulls last, hash) as row_number
```

If date_updated field is not available, we can order by any other field instead (version or date_created, for example), or, if there is absolutely no way to find out which record is the latest, we will simply order by hash field only, to at least have a deterministic result.

## 5. Storing the changes history

We only have one final piece of DWH architecture missing, which is storing the history of record changes.

### Theoretical background

In DWH theory, this is usually called Slowly Changing Dimensions (SCD) and there are different approaches to handling them. You can read more about them [here](https://en.wikipedia.org/wiki/Slowly_changing_dimension) and [here](http://datawarehouse4u.info/SCD-Slowly-Changing-Dimensions.html).

Of course, changes can happen not only in Dimensions, but also in Facts, although significantly less often. In our DWH, all source tables are equal, and merely represent Business Entities that we want to load into DWH. Therefore, we will allow both Dimension and Fact tables to have a history.

### Choosing the best approach

If you have already read about the different types of Slowly Changing Dimensions, you might be surprised by some of them (Type 1 - "overwrite" and Type 3 - "add new attribute"), where we simply overwrite the previous values, or only store one previous value per attribute instead of the whole history. I think the explanation is simple: these approaches made sense decades ago, when every kilobyte of disk space was valuable. Nowadays, disk space is negligibly cheap and the data is significantly more valuable the disk space, so we can disregard those approaches.

Now we can choose, whether to use SCD Type 2 - "add new row", Type 4 - "add history table", or a so-called Type 6 - "hybrid" approach. From my point of view, we should not generate a new surrogate Entity Key for every change of the record, because then a) we'll have to make sure all facts referring this dimension are assigned a correct key, and b) it simply forces the users to always select the historical data, which might not be their intention. In fact, from my experience, we need to get the historical data significantly more rarely than just a simple current state, which is what people expect "by default".

### Hybrid approach implementation

Therefore, we go with Type 6 - "[pure type 6 implementation](https://en.wikipedia.org/wiki/Slowly_changing_dimension#Pure_type_6_implementation)". But we still have a choice of how to arrange it:
1. Keep all history in the same table as the original;
2. Have a normal table with current values, plus a separate table with both the current values and history;
3. Have a normal table with current values, plus a separate table with just the history.

Obviously, if we need to select some historical data, options 1 and 2 look more preferable, because we won't have to join 2 tables to get the value we need by date.

#### 1. Keep all history in the same table as the original

Unfortunately, option 1 makes the normal data querying more complicated and error-prone, because all users will have to remember that they always need to join tables not just by the key, but also by the date, or by some flag of the current version of record, even though most of the time they simply need the current versions of data. It also contradicts our requirement to be developer-friendly and provide the tables structure as close as possible to the source tables.

#### 2. Have a normal table with current values, plus a separate table with both the current values and history

With the second option, this issue is solved. When users need the current versions of data, they just select from the main table as usual, and when they need the history, they use the historical table instead, and apply a condition by date.

However, that means that the current version of the record will have to be in two tables at once (which is not a big issue), but also that we'll have to update those current records not only in the main table, but also the history table, as soon as they become obsolete (to set them the ending date). And this is already a more serious problem, because if we want to achieve the best performance, we should avoid updating the records that were written to the DWH. Each update is essentially a combination of delete and insert operations, and it requires the database engine to perform vacuuming if the tables, etc.

An alternative to that is to simply not have the ending date for a historical record, and just have a starting date. If course, it means that every select of historical data requires users to write a window function, getting the next starting date per Entity Key (which would be the ending date), wrap it in a sub-query, and only then use it in the join or filter expression. The performance of such queries will be low and the complexity will be high.

#### 3. Have a normal table with current values, plus a separate table with just the history

Let's see how we can address all of these issues with our option number three.

Here, again, when users need the current versions of data, they just select from the main table as usual. But when they need the history (which happens quite rarely), they have to select from a "union all" of the historical and main tables, and just apply a condition by date.

This way, we only insert to our history table once - when the record becomes obsolete and we already know its starting and ending dates, and never update it. We also don't need to use performance-expensive window functions every time we need to get historical data. The only downside is the need to union the main and history tables, but since it's not required that often, we can live with that.

### History tables structure

Now that we understood how our history tables will work, we can think about their structure.

We definitely need the same fields as we had in the original target table, plus we need some metadata about the record, similar to what we already have in "Batch Info" table. As we agreed before, it makes sense to also add the ending date column, to be able to select a historical record easily. For that, we can use batnch_number and batch_date columns, but from the new batch - the one that caused this record to move to history.
