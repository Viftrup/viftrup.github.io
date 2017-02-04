
-- Generating DDL for all required tables, only run if the tables don't exist yet

drop table if exists dw.dim_customer_pk_lookup;

drop sequence if exists dw.dim_customer_seq;

create sequence dw.dim_customer_seq;

create table dw.dim_customer_pk_lookup (
    entity_bk varchar not null primary key,
    entity_key bigint not null default nextval('dw.dim_customer_seq')
);

drop table if exists dw.dim_customer_main_batch_info;

create table dw.dim_customer_main_batch_info (
    entity_key bigint not null primary key,
    is_inferred smallint not null default 0,
    is_deleted smallint not null default 0,
    hash varchar(128),
    batch_date timestamp not null,
    batch_number bigint not null
);

drop table if exists dw.dim_customer_main;

create table dw.dim_customer_main (
    entity_key bigint primary key,
    customer_id bigint,
    date_created timestamp,
    date_updated timestamp,
    email_key bigint,
    email varchar(255),
    first_name varchar(255),
    last_name varchar(255),
    is_enabled bool,
    additional_data json,
    shipping_country varchar(255)
);

create index dim_customer_main_email_key_idx
on dw.dim_customer_main using btree
(email_key);

drop table if exists dw.dim_customer_main_history;

create table dw.dim_customer_main_history (
    -- History part
    is_inferred smallint default 0,
    is_deleted smallint not null default 0,
    hash varchar(128),
    batch_date timestamp,
    batch_number bigint,
    batch_date_new timestamp,
    batch_number_new bigint,
    -- Main part 
    entity_key bigint,
    customer_id bigint,
    date_created timestamp,
    date_updated timestamp,
    email_key bigint,
    email varchar(255),
    first_name varchar(255),
    last_name varchar(255),
    is_enabled bool,
    additional_data json,
    shipping_country varchar(255)
);

create index dim_customer_main_history_entity_key_idx
on dw.dim_customer_main_history using btree
(entity_key);

create index dim_customer_main_history_batch_date_idx
on dw.dim_customer_main_history using btree
(batch_date);

create index dim_customer_main_history_batch_date_new_idx
on dw.dim_customer_main_history using btree
(batch_date_new);

create index dim_customer_main_history_email_key_idx
on dw.dim_customer_main_history using btree
(email_key);

