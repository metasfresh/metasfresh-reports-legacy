

------------in this repo-------------
mondrian_adempiere_fact_acct_analysis.xml
	*current version; more or less functional. the fact table is created using setup_accounting_facts_MV.sql

setup_accounting_facts_MV.sql
	*creates a fact_acct based fact table and a DB-function that can keep it in sync
	
pivot4j-config.xml
	*a sample config file; not needed if we use pivot4j from pentaho

------------somehow related-------------
psw-ce-3.9.0.0-213\schema-workbench
	*swing olap cube designer
	*note: seems to hang at the beginning and then the DB connection is changed. Apparently reads the DB's metadata at that time

pivot4j-analytics-1.0-SNAPSHOT.war
	*olap-webapp
	*when dropping it into a jboss folder, make sure it has enough RAM (-Xmx1G is probably not enough)
	
pivot4j-analytics-1.0-SNAPSHOT.war\WEB-INF\pivot4j-config.xml
	*connects the olap-frontend to the database and adempiere_fact_acct_testing.xml

pivot4j-analytics-1.0-SNAPSHOT.war\WEB-INF\lib\postgresql-9.2-1003-jdbc4.jar
	*jdbc driver for postgres

------------Resources------------
http://olap4j-demo.googlecode.com/svn/trunk/doc/Olap4j_Introduction_An_end_user_perspective.pdf
	*how to create an "OLAP-connection" with the mondrian driver
	
http://mondrian.pentaho.com/documentation/schema.php
	*how an olap cube schema works
	
http://www.pivot4j.org/
	*UI and sample webapp