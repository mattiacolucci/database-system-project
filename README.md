# database-system-project

This is a complete design and development of an object relational database in Oracle starting from the specifications (written in the documentation)

In this project, following phases have been conducted:
- Creation of the conceptual schema
- Logical analysis
	- Volume table
	- Access tables
	- Analysis or redundancies
	- Selections of main identifiers
	- Merge and split
- Refactoring of the conceptual schema
- Creation of the logical schema (UML)
- Oracle implementation (types and typed tables)(contraints)
- implementation of triggers
- Checking of the correct function of all the triggers
- Physical analysis
	- Algebraic optimization
	- Intermediate results volume estimation with relation profiles
	- Analysis with autotrace of the query operations
	- Selection of auxiliary structures such as hash/B+tree indexes to implement
		- Analysis of the fan out and depth of a B+tree (if implemented some) and analysis of the complexity of joints operations
- Realization of the logical schema of a possible data warehouse
- Implementation of a simple ReactJS and NodeJS Client application to try out all the operations expressed by the specifications on the database


In this folder there are different sql files:
- schema_tables_and_types.sql
	Plans to create all the types and tables needed to implement the database
- insert_in_tables.sql
	Contains different procedures to populate all the created tables with random generated data (generation process and tuples distribution is expressed in the ducumentation)
- triggers.sql
	Contains all implemented triggers to maintain the database into a consistent state
- tigger_check.sql
	Contains blocks of code that plans to check if the implemented triggers work correctly by recreating a scenario in which the triggers fire
- operations.sql
	Contains all 5 operations expressed in the specifications 
- physical_analysis.sql
	Contains the operations 4 and 5 in order to run on them the autotrace command, and check if implemented auxiliary structures are effectively used by the DBMS during the execution of the query
	Contains also some useful commands to get the block size or the length of an attribute, used to conduct the physical analysis


The client application is put into the 'application_frontend' and 'application_backend' folders
