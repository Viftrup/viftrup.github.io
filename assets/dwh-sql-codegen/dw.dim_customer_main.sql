
-- ETL code for loading stage.customer to dw.dim_customer_main

drop table if exists stage.dim_customer_main_batch; -- Won't drop to avoid unnoticed collisions

create table stage.dim_customer_main_batch as
select
    current_timestamp as batch_date,
    #JOB_ID# as batch_number
;


drop table if exists stage.dim_customer_main_stage1;

create table stage.dim_customer_main_stage1 as
select 
    customer_id,
    date_created,
    date_updated,
    email,
    first_name,
    last_name,
    is_enabled,
    additional_data,
    shipping_country,
    entity_bk, 
    email_dim_email_bk,
    hash,
    row_number() over (partition by entity_bk order by date_updated desc nulls last, hash) as row_number
from (
    select 
        customer_id,
        date_created,
        date_updated,
        email,
        first_name,
        last_name,
        is_enabled,
        additional_data,
        shipping_country,
        version,
        coalesce(customer_id || '', '') as entity_bk, 
        email || '' as email_dim_email_bk, 
        md5( 
            coalesce(customer_id || '', '') ||
            coalesce(to_char(date_created, 'YYYYMMDDHH24MISS') || '', '') ||
            coalesce(email || '', '') ||
            coalesce(first_name || '', '') ||
            coalesce(last_name || '', '') ||
            coalesce(is_enabled || '', '') ||
            coalesce(additional_data || '', '') ||
            coalesce(shipping_country || '', '')
        ) as hash
    from (
        select 
            customer_id,
            date_created,
            date_updated,
            lower(trim(email)) as email,
            first_name,
            last_name,
            is_enabled,
            additional_data,
            json_extract_path_text(additional_data, 'attributes', 'shippingCountry') as shipping_country,
            version
        from stage.customer
    ) s2
) s1;

create index dim_customer_main_stage1_entity_bk_idx
on stage.dim_customer_main_stage1 using btree
(entity_bk);

create index dim_customer_main_stage1_row_number_idx
on stage.dim_customer_main_stage1 using btree
(row_number);

create index dim_customer_main_stage1_email_dim_email_bk_idx
on stage.dim_customer_main_stage1 using btree
(email_dim_email_bk);


-- Inferred entities loading start

-- Inferred entity: dim_email_main

begin;
lock table dw.dim_email_pk_lookup in exclusive mode;
lock table dw.dim_email_main_batch_info in exclusive mode;
lock table dw.dim_email_main in exclusive mode;

drop table if exists stage.dim_email_main_inferred_#JOB_ID#;

create table stage.dim_email_main_inferred_#JOB_ID# as
select
    p.entity_key, -- Not null if entity exists, but was not loaded to this entity suffix before
    s1.email_dim_email_bk as entity_bk ,
    max(s1.email) as email
from stage.dim_customer_main_stage1 s1
    left join dw.dim_email_pk_lookup p
        on p.entity_bk = s1.email_dim_email_bk
    left join dw.dim_email_main_batch_info bi
        on bi.entity_key = p.entity_key
where s1.row_number = 1
    and s1.email_dim_email_bk is not null -- Ignoring NULL FKs
    and bi.entity_key is null -- Entity either completely new or was not loaded to this entity suffix before
group by 1,2
;

create index dim_email_main_inferred_#JOB_ID#_entity_bk_idx
on stage.dim_email_main_inferred_#JOB_ID# using btree
(entity_bk);


insert into dw.dim_email_pk_lookup (entity_bk)
select i.entity_bk
from stage.dim_email_main_inferred_#JOB_ID# i
where i.entity_key is null -- Entity is completely new
;

-- Analyze takes too much time, disabled for inferred entities
-- analyze dw.dim_email_pk_lookup;

insert into dw.dim_email_main_batch_info (
    entity_key,
    is_inferred,
    is_deleted,
    hash,
    batch_date,
    batch_number
)
select
    p.entity_key, -- Using just generated or already exising key which was not loaded to this entity suffix before
    1 as is_inferred,
    0 as is_deleted,
    'dw.dim_customer_main' as hash,
    b.batch_date,
    b.batch_number
from stage.dim_email_main_inferred_#JOB_ID# i
    left join dw.dim_email_pk_lookup p
        on p.entity_bk = i.entity_bk
    cross join stage.dim_customer_main_batch b
;

-- Analyze takes too much time, disabled for inferred entities
-- analyze dw.dim_email_main_batch_info;

insert into dw.dim_email_main (
    entity_key ,
    email
)
select
    p.entity_key ,
    i.email
from stage.dim_email_main_inferred_#JOB_ID# i
    join dw.dim_email_pk_lookup p
        on p.entity_bk = i.entity_bk
;

-- Analyze takes too much time, disabled for inferred entities
-- analyze dw.dim_email_main;

commit;

-- Inferred entities loading end


-- Generating the list of new/updated/deleted entities

begin;
lock table dw.dim_customer_pk_lookup in exclusive mode;
lock table dw.dim_customer_main_batch_info in exclusive mode;
lock table dw.dim_customer_main in exclusive mode;

drop table if exists stage.dim_customer_main_pk_batch_info_stage;

create table stage.dim_customer_main_pk_batch_info_stage as
select
    s1.entity_bk,
    p.entity_key, -- Will be null for new entities
    bi.is_inferred as is_inferred_old,
    0 as is_inferred,
    bi.is_deleted as is_deleted_old,
    case when s1.entity_bk is null then 1 else 0 end as is_deleted,
    bi.hash as hash_old, -- Saving old hash and batch information for updated entities
    s1.hash,
    bi.batch_date as batch_date_old,
    bi.batch_number as batch_number_old,
    b.batch_date,
    b.batch_number
from stage.dim_customer_main_stage1 s1
    left join dw.dim_customer_pk_lookup p
        on p.entity_bk = s1.entity_bk
    left join dw.dim_customer_main_batch_info bi
        on bi.entity_key = p.entity_key
    cross join stage.dim_customer_main_batch b
where (s1.entity_bk is not null
        and s1.row_number = 1
        and ((p.entity_key is null)     -- New entity
            or (bi.entity_key is null)  -- Entity key exists, but not in this entity subname (sattelite)
            or (bi.is_inferred = 1)     -- This entity subname was loaded, but as inferred
            or (bi.is_deleted = 1)      -- This entity subname was deleted before, but arrived again now
            or (coalesce(bi.hash, '') != s1.hash)) -- This entity subname was loaded, but the attributes changed (or we didn't track history before)
    )
    or (s1.entity_bk is null            -- Entity is missing from loaded full snapshot data (deleted)
        and bi.is_deleted = 0           -- Entity is not deleted before
        and bi.is_inferred = 0          -- We will not delete inferred records, because they were never actually loaded
    )
;

create index dim_customer_main_pk_batch_info_stage_entity_bk_idx
on stage.dim_customer_main_pk_batch_info_stage using btree
(entity_bk);


-- Inserting new entities to PK Lookup, generating keys

insert into dw.dim_customer_pk_lookup (entity_bk)
select ps.entity_bk
from stage.dim_customer_main_pk_batch_info_stage ps
where ps.entity_key is null -- Only new entities
;

analyze dw.dim_customer_pk_lookup;

-- Inserting Batch information and Hash for new entities

insert into dw.dim_customer_main_batch_info (
    entity_key,
    is_inferred,
    is_deleted,
    hash,
    batch_date,
    batch_number
)
select
    p.entity_key,
    ps.is_inferred,
    ps.is_deleted,
    ps.hash,
    ps.batch_date,
    ps.batch_number
from stage.dim_customer_main_pk_batch_info_stage ps
    join dw.dim_customer_pk_lookup p
        on p.entity_bk = ps.entity_bk
where ps.batch_number_old is null -- This entity subname wasn't loaded before
;

-- Updating Batch information and Hash for changed entities

update dw.dim_customer_main_batch_info
set
    is_inferred = ps.is_inferred,
    is_deleted = ps.is_deleted,
    hash = ps.hash,
    batch_date = ps.batch_date,
    batch_number = ps.batch_number
from stage.dim_customer_main_pk_batch_info_stage ps
where ps.entity_key = dw.dim_customer_main_batch_info.entity_key
    and ps.batch_number_old is not null -- This entity subname was already loaded
;

analyze dw.dim_customer_main_batch_info;

-- Generating Stage2 table, similar to target table by structure

drop table if exists stage.dim_customer_main_stage2;

create table stage.dim_customer_main_stage2 as
select
    p.entity_key, 
    s1.customer_id as customer_id,
    s1.date_created as date_created,
    s1.date_updated as date_updated,
    p_email_dim_email.entity_key as email_key,
    s1.email as email,
    s1.first_name as first_name,
    s1.last_name as last_name,
    s1.is_enabled as is_enabled,
    s1.additional_data as additional_data,
    s1.shipping_country as shipping_country
from stage.dim_customer_main_pk_batch_info_stage as ps    -- Only new, inferred or updated entities
    join stage.dim_customer_main_stage1 as s1    -- Taking other columns from the source table
        on s1.entity_bk = ps.entity_bk
    join dw.dim_customer_pk_lookup as p    -- Using just generated or already exising keys
        on p.entity_bk = ps.entity_bk 
    left join dw.dim_email_pk_lookup as p_email_dim_email
        on p_email_dim_email.entity_bk = s1.email_dim_email_bk
where s1.entity_bk is not null -- Entity not deleted
    and s1.row_number = 1
;

-- Inserting updated entities to History

insert into dw.dim_customer_main_history
select
    ps.is_inferred_old as is_inferred,
    ps.is_deleted_old as is_deleted,
    ps.hash_old as hash,
    ps.batch_date_old as batch_date,
    ps.batch_number_old as batch_number,
    ps.batch_date as batch_date_new,
    ps.batch_number as batch_number_new,
    t.*
from dw.dim_customer_main t
    join stage.dim_customer_main_pk_batch_info_stage ps
        on ps.entity_key = t.entity_key
where ps.batch_number_old is not null -- This entity suffix already existed
    -- Not keeping the history, generated by the same Batch (parent IDs coming in the same Batch as child)
    and not (ps.batch_number_old = ps.batch_number and ps.is_inferred_old = 1)
;

analyze dw.dim_customer_main_history;

-- Deleting updated entities from target table

delete from dw.dim_customer_main
where entity_key in ( -- or where exists
    select ps.entity_key
    from stage.dim_customer_main_pk_batch_info_stage ps
    where ps.entity_key is not null
        and ps.batch_number_old is not null -- This entity suffix already existed
);

-- Inserting new, inferred and updated entities to the target table

insert into dw.dim_customer_main ( 
    entity_key,
    customer_id,
    date_created,
    date_updated,
    email_key,
    email,
    first_name,
    last_name,
    is_enabled,
    additional_data,
    shipping_country
)
select 
    entity_key,
    customer_id,
    date_created,
    date_updated,
    email_key,
    email,
    first_name,
    last_name,
    is_enabled,
    additional_data,
    shipping_country
from stage.dim_customer_main_stage2
;

analyze dw.dim_customer_main;

commit;
