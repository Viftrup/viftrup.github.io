
-- ETL code for loading stage.customer to dw.dim_email_main

drop table if exists stage.dim_email_main_batch; -- Won't drop to avoid unnoticed collisions

create table stage.dim_email_main_batch as
select
    current_timestamp as batch_date,
    #JOB_ID# as batch_number
;


drop table if exists stage.dim_email_main_stage1;

create table stage.dim_email_main_stage1 as
select 
    email,
    entity_bk, 
    hash,
    row_number() over (partition by entity_bk order by hash) as row_number
from (
    select 
        email,
        coalesce(email || '', '') as entity_bk,  
        cast(null as varchar) as hash
    from (
        select 
            lower(trim(email)) as email
        from stage.customer
    ) s2
) s1;

create index dim_email_main_stage1_entity_bk_idx
on stage.dim_email_main_stage1 using btree
(entity_bk);

create index dim_email_main_stage1_row_number_idx
on stage.dim_email_main_stage1 using btree
(row_number);


-- Generating the list of new/updated/deleted entities

begin;
lock table dw.dim_email_pk_lookup in exclusive mode;
lock table dw.dim_email_main_batch_info in exclusive mode;
lock table dw.dim_email_main in exclusive mode;

drop table if exists stage.dim_email_main_pk_batch_info_stage;

create table stage.dim_email_main_pk_batch_info_stage as
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
from stage.dim_email_main_stage1 s1
    left join dw.dim_email_pk_lookup p
        on p.entity_bk = s1.entity_bk
    left join dw.dim_email_main_batch_info bi
        on bi.entity_key = p.entity_key
    cross join stage.dim_email_main_batch b
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

create index dim_email_main_pk_batch_info_stage_entity_bk_idx
on stage.dim_email_main_pk_batch_info_stage using btree
(entity_bk);


-- Inserting new entities to PK Lookup, generating keys

insert into dw.dim_email_pk_lookup (entity_bk)
select ps.entity_bk
from stage.dim_email_main_pk_batch_info_stage ps
where ps.entity_key is null -- Only new entities
;

analyze dw.dim_email_pk_lookup;

-- Inserting Batch information and Hash for new entities

insert into dw.dim_email_main_batch_info (
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
from stage.dim_email_main_pk_batch_info_stage ps
    join dw.dim_email_pk_lookup p
        on p.entity_bk = ps.entity_bk
where ps.batch_number_old is null -- This entity subname wasn't loaded before
;

-- Updating Batch information and Hash for changed entities

update dw.dim_email_main_batch_info
set
    is_inferred = ps.is_inferred,
    is_deleted = ps.is_deleted,
    hash = ps.hash,
    batch_date = ps.batch_date,
    batch_number = ps.batch_number
from stage.dim_email_main_pk_batch_info_stage ps
where ps.entity_key = dw.dim_email_main_batch_info.entity_key
    and ps.batch_number_old is not null -- This entity subname was already loaded
;

analyze dw.dim_email_main_batch_info;

-- Generating Stage2 table, similar to target table by structure

drop table if exists stage.dim_email_main_stage2;

create table stage.dim_email_main_stage2 as
select
    p.entity_key, 
    s1.email as email
from stage.dim_email_main_pk_batch_info_stage as ps    -- Only new, inferred or updated entities
    join stage.dim_email_main_stage1 as s1    -- Taking other columns from the source table
        on s1.entity_bk = ps.entity_bk
    join dw.dim_email_pk_lookup as p    -- Using just generated or already exising keys
        on p.entity_bk = ps.entity_bk 
where s1.entity_bk is not null -- Entity not deleted
    and s1.row_number = 1
;

-- Deleting updated entities from target table

delete from dw.dim_email_main
where entity_key in ( -- or where exists
    select ps.entity_key
    from stage.dim_email_main_pk_batch_info_stage ps
    where ps.entity_key is not null
        and ps.batch_number_old is not null -- This entity suffix already existed
);

-- Inserting new, inferred and updated entities to the target table

insert into dw.dim_email_main ( 
    entity_key,
    email
)
select 
    entity_key,
    email
from stage.dim_email_main_stage2
;

analyze dw.dim_email_main;

commit;
