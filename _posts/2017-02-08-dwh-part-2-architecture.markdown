---
layout: post
title: DWH\, part 2\: Architecture
author: Dmytro Lytvyn
categories: DWH
---

Let's quickly recall the requirements to the DWH we came up with in the first article:

1. DWH must be a separate system with SQL interface, holding the information from various data sources.
2. The tables structure in the DWH should preferably be as close as possible to that of the source systems.
3. DWH must support incremental data loading and ensure the best performance for reading and writing the data.
4. DWH design must support the loading processes that properly handle the duplicates, missing data, etc.
5. All changes of the source data must be reflected in the DWH history tables.

Now, we can discuss how to approach the implementation of the DWH system, satisfying these requirements.

### 1. Choosing the system

The easiest way to have a separate system with SQL interface is to set up a new database server (it must not be the same physical machine as one of the operational databases, of course). It can be a cloud server like Amazon Redshift, or a normal server, preferably in a Data Center, with all proper monitoring and high availability cluster setup.

Data migration can be set up natively between the DBMS of the same provider (Oracle to Oracle, SQL Server to SQL Server or Postgres to Postgres), so you might want to choose for DWH the same DBMS provider as for your biggest operational database. Of course, it will not solve all your ETL needs, and you will have to choose and set up a proper ETL solution for your DWH, supporting various types of jobs, scheduling and dependencies between them. I will cover this topic in future articles.

### 2. Tables structure

Moving on to the second requirement, we can set up a similarly structured database by just copying the tables structure 1:1 from the operational databases. Later, we'll discuss what minor changes are needed to satisfy other DWH requirements.

For now, let's assume we can simply copy the data from the operational database to our DWH fully every day, keeping the same tables structure. Now we can move on to other requirements: incremental loading, handling duplicates and storing the changes history.

### 3. Incremental loading

#### Getting the source data

There are several approaches for getting the source data incrementally, that I personally observed in real systems, but let's try to find the one that will work for all situations.

**Option #1**: using the date_created field, always deleting the last 3 days (for example) of data, and inserting again everything created within those last 3 days.

It will only work with the data that never changes, because you won't load the recently changed record, if it was created more than 3 days ago, and if the date_created itself is changed, you might either load the same record twice, or just completely lose it.

**Option #2**: load all records where date_created or record ID is bigger than the maximal date or ID you already have in your table.

This, again, eliminates the possibility to load the changes, plus it requires you to either store the maximal date/ID per source table somewhere, or select it from DWH tables dynamically, and somehow link this information to the source systems. And joining data between separate systems is a bad idea from performance point of view. 
Moreover, nobody can guarantee that the newly created ID or even date_created is always bigger than previous values in the same table.

**Option #3**: loading the most recent changes using date_updated column.

At this point, we realized that we need a date_updated column in almost every table we load from, unless the data in the table is never updated by design (audit log, website tracking events, etc.) - then it's enough to have just date_created column.

Luckily, such column is very easy to implement with a default value of now() or current_timestamp for this column (just as it should be for date_created), and a trigger on update, setting it to current timestamp again.

However, I saw examples when the value in date_updated column is set by a backend application, and not on a database level. This is of course wrong, because we can't rely on this column to be updated properly. For example, you can expect the record to be updated (manually), but the date_updated remain unchanged, or to have the date_updated earlier than date_created for the same record, etc.

In case the data in the table can be altered, but date_updated column is not available (for whatever reasons), we can only load the full table to get all the changes. This is also necessary when the data can be deleted from the source table, and we must somehow reflect it in the DWH. In such situations, I usually load daily only the new records if possible (using date_created), and perform a full table synchronization once per week, for example.

For this approach, we'll need a set of so-called "staging" tables of exactly the same structure as our source tables. We'll use them as a temporary disposable buffer between the source system and DWH tables. Normally, the amount of data in staging tables is much smaller than in source tables, because we only load the recently created/updated records to them, and then copy the data to the target tables.

#### Merging the data

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
        or t.int_column2 != s.int_column2
        or (t.int_column2 is null and s.int_column2 is not null)
        or (t.int_column2 is not null and s.int_column2 is null)
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

Let's think how to optimize this from performance point of view, and also whether we can make those SQLs more generic.
