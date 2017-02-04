
-- Generating DDL for all required tables, only run if the tables don't exist yet

drop table if exists dw.dim_email_pk_lookup;

drop sequence if exists dw.dim_email_seq;

create sequence dw.dim_email_seq;

create table dw.dim_email_pk_lookup (
    entity_bk varchar not null primary key,
    entity_key bigint not null default nextval('dw.dim_email_seq')
);

drop table if exists dw.dim_email_main_batch_info;

create table dw.dim_email_main_batch_info (
    entity_key bigint not null primary key,
    is_inferred smallint not null default 0,
    is_deleted smallint not null default 0,
    hash varchar(128),
    batch_date timestamp not null,
    batch_number bigint not null
);

drop table if exists dw.dim_email_main;

create table dw.dim_email_main (
    entity_key bigint primary key,
    email varchar(255)
);

