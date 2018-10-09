---
layout: page
title: Projects
permalink: /projects/
---

[DWH SQL CodeGen](https://github.com/dmytro-lytvyn/dwh-sql-codegen)

DWH SQL CodeGen is a cross-platform GUI application with a simple interface, built using Python and WxWidgets, that generates SQL scripts to build and load DWH (PostgreSQL/Redshift) from staging tables.

This application should be considered rather as a working prototype, and needs a lot of refactoring and cleaning up. Nevertheless, it's already useful in its current state, and saves the hours and days you can spend writing thousands of lines of SQL code.

[Data Platform: Ansible Roles](https://github.com/dmytro-lytvyn/dp-ansible-roles)

A set of Ansible roles to install and configure the components of the Data Platform:
- Data Input server with Apache NiFi for data ingestion, Confluent Schema Registry (along with Zookeeper and Kafka to store schemas) for event schema validation, Landoo Schema Registry UI for user-friendly schema editing, and Kafdrop as a simple Kafka UI.
- (TBD) Data Streaming server with Confluent Zookeeper and Kafka to stream the ingested events for further processing.
- (TBD) Data Processing and Storage server, with Cloudera Manager, Spark and Hadoop (or Hortonworks, to be decided later).
- (TBD) Data Output and Presentation server, with Cloudera Hue interface for Hive and Impala for data querying, and Redash for data visualisation and dashboards.
