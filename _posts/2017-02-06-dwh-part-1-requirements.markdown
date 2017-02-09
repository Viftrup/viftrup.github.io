---
layout: post
title: DWH, part 1 - Requirements
author: Dmytro Lytvyn
categories: DWH
---

So, Data Warehouse. Before we start discussing the architecture and technical implementation, we need to agree on our expectations from it and put together a list of requirements.

OK Google, define Data Warehouse.

> [Data warehouse](https://en.m.wikipedia.org/wiki/Data_warehouse) (DW or DWH) is a system used for reporting and data analysis, and is considered a core component of business intelligence. DWs are central repositories of integrated data from one or more disparate sources. They store current and historical data and are used for creating analytical reports... The data stored in the warehouse is uploaded from the operational systems (such as marketing or sales). 

Good, it already gives us some basic information. The DWH is basically a storage of the information, already existing in the company. Sounds simple!

From my experience, there are several types, or rather stages, of BI implementation in different companies:

### 1. No separate BI system at all.

A lot of companies in the beginning simply use their operational systems for some basic reporting. Most reporting is done in Excel at this stage, by manually populating the numbers like monthly totals, and copying them from one spreadsheet to another.

However, this approach works worse as the company grows. New operational systems are being added - for example in addition to the main sales database, the company adds ERP and CRM systems, Google Analytics reporting becomes insufficient for detailed website visits analysis and the company adds a new tracking system.

The information from other third party systems needs to be analysed, like customer support system, mobile application tracking, TV ads tracking, etc.

Thus, the company now requires a single storage for all these data, allowing to somehow link them together.

### 2. BI system as a plain copy of one or more operational systems.

At this point, we already can see the first requirement to our DWH.

**Requirement to DWH #1**: it must be a separate system, holding the information from various data sources in a unified format, allowing to link these data together and preferably providing standard SQL access.

**Requirement to DWH #2**: the tables structure in the DWH should preferably be as close as possible to that of the source systems, because the developers and analysts are already used to it, and there are existing reports using this naming conventions, etc.

This is not a strict requirement and there are approaches to DWH that heavily normalize the data or completely rearrange all data structures to be "Subject Oriented", following Bill Inmon's characteristics of the DWH. This, however, makes the DWH development more complicated, and the development cycle - longer. Additionally, it's better when analysts and developers talk the same language and refer more or less the same tables and column names, otherwise the transparency is lost. In principal, modern approaches to data warehousing like Data Vault (or even Data Lake) also try to keep the structure of the source data as is, so we're on the right track here.

Following the basic requirements, companies choose the simplest approach to data warehousing: simply copying all data from operational systems to a dedicated BI database as is, often not even incrementally, but the complete tables every day. Then, some transformations and aggregations are done, to prepare the data for the reports.

Such approach might help to assemble data from different systems in one, and keeps the familiar tables structure of the operational systems, but does not provide any storage capabilities - if something is lost in Operational database, it's lost in DWH, too. If some data are broken in the operational system, they are broken in DWH too, and are useless for reporting.

Additionally, as the company grows, the amount of data grows even faster, and "full daily reloads" very quickly start to take the whole night to finish.

### 3. Fully-featured DWH system

In order to optimize the loading times, we need to introduce the incremental data loads, i.e. only the recently changed data should be written to the DWH during the load. Unfortunately, when implementing the incremental data load "by hand", it's very easy to either miss some data, or load it twice (for example, when you try to delete and then reload the recently changed data by timestamp). DWH must "natively" support the incremental data loads, so that it never has duplicated data. This will also help with tracking the changes and storing the historical data.

**Requirement to DWH #3**: it must support incremental data loading and ensure the best performance for writing, but most importantly, reading the data.

Additionally, it's not rare that operational systems have inconsistent or duplicate data because of the design issues and "organic growth" of those systems, and simply because it might not interfere with their work. Of course, these issues become obvious when somebody starts to analyse the data. Therefore, we need to think about how to fix such issues on DWH level.

The modern approaches to data warehousing, mentioned earlier (Data Vault and Data Lake), try to avoid being the "single point of truth" and push the responsibility for the data quality either to the systems that generate it, or to the consumers of the data.

Logically, it makes sense, but in real life, the developers of operational systems have their own urgent problems to deal with, and if the data quality issue doesn't break the system, they will try to avoid fixing it for as long as they can. Therefore, in such systems the data can be stored in its "broken" form, and only be fixed during export/publishing.

Obviously, it means that nobody should use these raw data before "cleansing", which somewhat limits the usefulness of the DWH. Thus, BI can take initiative and try to fix the most obvious data issues before loading them to DWH.

**Requirement to DWH #4**: DWH design must support the loading processes that properly handle the duplicates, missing data and fix other major inconsistencies coming from the source systems.

As we have already discussed, one of the major requirements to the DWH is storing the historical data (for example all previous addresses of the customers). This is something that operational systems usually don't do, and therefore all previous versions of the data are simply lost. Therefore, we need to start storing them in DWH as early as possible.

**Requirement to DWH #5**: when information is stored, it must not be lost. Therefore, all changes of the source data must be reflected in the history tables.

If we now look at Oracle's [Introduction to Data Warehousing Concepts](https://docs.oracle.com/database/121/DWHSG/concept.htm), we'll see that Bill Inmon's DWH characteristics are very close to what we came up with: "Integrated" means of possibility to link diverse data and avoid inconsistencies, "Nonvolatile" and "Time Variant" refer to the requirement to keep all incoming information and track the history of changes. The only thing we deceded to avoid is the reorganization of data to be "Subject Oriented", because it contradicts the requirements #2 and #3 (keeping the existing data structures and best performance for both writing and reading the data).

### Summary

Let's review the list requirements to the DWH we came up with:

1. DWH must be a separate system with SQL interface, holding the information from various data sources.
2. The tables structure in the DWH should preferably be as close as possible to that of the source systems.
3. DWH must support incremental data loading and ensure the best performance for reading and writing the data.
4. DWH design must support the loading processes that properly handle the duplicates, missing data, etc.
5. All changes of the source data must be reflected in the DWH history tables.
