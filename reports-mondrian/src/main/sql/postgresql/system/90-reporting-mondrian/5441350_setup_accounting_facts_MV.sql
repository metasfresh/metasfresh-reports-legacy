

CREATE SEQUENCE report.datedimension_seq
  INCREMENT 1
  MINVALUE 0
  MAXVALUE 999999999
  START 1000000
  CACHE 1;

CREATE TABLE report.datedimension
(
  datedimension_id bigint NOT NULL,
  date timestamp without time zone NOT NULL,
  year double precision NOT NULL,
  month double precision NOT NULL,
  day double precision NOT NULL,
  dow double precision NOT NULL,
  doy double precision NOT NULL,
  quarter double precision NOT NULL,
  week double precision NOT NULL,
  CONSTRAINT datedimension_pkey PRIMARY KEY (datedimension_id )
)
WITH (
  OIDS=FALSE
);
-- Index: report.datedimension_day
-- DROP INDEX report.datedimension_day;
CREATE INDEX datedimension_day
  ON report.datedimension
  USING btree
  (day );
-- Index: report.datedimension_week
-- DROP INDEX report.datedimension_week;
CREATE INDEX datedimension_week
  ON report.datedimension
  USING btree
  (week );
-- Index: report.datedimension_year
-- DROP INDEX report.datedimension_year;
CREATE INDEX datedimension_year
  ON report.datedimension
  USING btree
  (year );


--select distinct(t.TableName) from fact_acct fa join AD_Table t ON t.AD_Table_ID=fa.AD_Table_ID
--select count(7) from fact_acct; --3.878.949

ALTER TABLE fact_acct DROP COLUMN IF EXISTS accountingfactsstatus CASCADE;
ALTER TABLE fact_acct ADD COLUMN accountingfactsstatus character(1) /* NOT NULL DEFAULT 'S' */; --don't define a default value as we already have millions of fact_accts. it's just a waste of time
ALTER TABLE fact_acct ADD CONSTRAINT fact_acct_accountingfactsstatus_check CHECK (accountingfactsstatus = ANY (ARRAY['S', 'U', 'P'])); -- Stale, UptoDate, InProcesseing
COMMENT ON COLUMN report.accounting_facts_mv.accountingfactsstatus IS 'S=Stale, U=UptoDate, P=InProcesseing';

CREATE INDEX fact_acct_accountingfactsstatus ON fact_acct (accountingfactsstatus);

DROP VIEW IF EXISTS report.AD_Ref_List_DocStatus_V CASCADE;
CREATE VIEW report.AD_Ref_List_DocStatus_V AS
SELECT * 
FROM AD_Ref_List l 
WHERE l.AD_Reference_ID=131 AND Value IN ('CO','CL','RE','VO')
;

DROP VIEW IF EXISTS report.accounting_facts_V;
CREATE VIEW report.accounting_facts_V AS
SELECT
	-- add explicit columns, so we can create indexes and join efficiently
	CASE WHEN fa.AD_Table_ID=get_table_id('M_MatchInv') THEN fa.Record_ID ELSE NULL END AS M_MatchInv_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('M_Inventory') THEN fa.Record_ID ELSE NULL END AS M_Inventory_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('M_Inventory') THEN fa.Line_ID ELSE NULL END AS M_InventoryLine_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('GL_Journal') THEN fa.Record_ID ELSE NULL END AS GL_Journal_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('M_InOut') THEN fa.Record_ID ELSE NULL END AS M_InOut_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('M_InOut') THEN fa.Line_ID ELSE NULL END AS M_InOutLine_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('C_Payment') THEN fa.Record_ID ELSE NULL END AS C_Payment_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('C_Invoice') THEN fa.Record_ID ELSE NULL END AS C_Invoice_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('C_Invoice') THEN fa.Line_ID ELSE NULL END AS C_InvoiceLine_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('C_BankStatement') THEN fa.Record_ID ELSE NULL END AS C_BankStatement_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('C_BankStatement') THEN fa.Line_ID ELSE NULL END AS C_BankStatementLine_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('C_BankStatement') THEN fa.SubLine_ID ELSE NULL END AS C_BankStatementLine_Ref_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('M_Movement') THEN fa.Record_ID ELSE NULL END AS M_Movement_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('M_Movement') THEN fa.Line_ID ELSE NULL END AS M_MovementLine_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('C_AllocationHdr') THEN fa.Record_ID ELSE NULL END AS C_AllocationHdr_ID,
	CASE WHEN fa.AD_Table_ID=get_table_id('C_AllocationHdr') THEN fa.Line_ID ELSE NULL END AS C_AllocationLine_ID,

	-- we join the DocStatus  dimension via this key, because using accounting_facts_MV.DocStatus as a directly as degenerate dimension was not performant, even with an index on the column
	rl.AD_Ref_List_ID AS AD_Ref_List_DocStatus_ID,

	-- the rest
	fa.* 
FROM fact_acct fa
	LEFT JOIN report.AD_Ref_List_DocStatus_V rl ON rl.Value=fa.DocStatus -- docstatus
;

--SELECT * FROM report.accounting_facts_V LIMIT 1000

DROP TABLE IF EXISTS report.accounting_facts_MV;
CREATE TABLE report.accounting_facts_MV AS
SELECT * FROM report.accounting_facts_V 
LIMIT 0 -- just creating the table, not selecting anything into it
;

ALTER TABLE report.accounting_facts_MV ADD COLUMN DateDimension_ID bigint;
ALTER TABLE report.accounting_facts_MV
  ADD CONSTRAINT DateDimension_ID FOREIGN KEY (DateDimension_ID)
      REFERENCES report.DateDimension (DateDimension_ID) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE;

-- same PK as fact_acct
ALTER TABLE report.accounting_facts_MV
  ADD CONSTRAINT accounting_facts_MV_pkey PRIMARY KEY(Fact_Acct_ID);

-- create an FK constraint and let the DB automatically delete MV records if their fact_acct record is deleted
ALTER TABLE report.accounting_facts_MV
  ADD CONSTRAINT Fact_Acct_ID FOREIGN KEY (Fact_Acct_ID)
      REFERENCES Fact_Acct (Fact_Acct_ID) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE;

	  
CREATE INDEX accounting_facts_MV_AD_Table_ID ON report.accounting_facts_MV (AD_Table_ID);
CREATE INDEX accounting_facts_MV_accountingfactsstatus ON report.accounting_facts_MV (accountingfactsstatus);
CREATE INDEX accounting_facts_MV_M_MatchInv_ID ON report.accounting_facts_MV (M_MatchInv_ID);
CREATE INDEX accounting_facts_MV_M_Inventory_ID ON report.accounting_facts_MV (M_Inventory_ID);
CREATE INDEX accounting_facts_MV_M_InventoryLine_ID ON report.accounting_facts_MV (M_InventoryLine_ID);
CREATE INDEX accounting_facts_MV_GL_Journal_ID ON report.accounting_facts_MV (GL_Journal_ID);
CREATE INDEX accounting_facts_MV_M_InOut_ID ON report.accounting_facts_MV (M_InOut_ID);
CREATE INDEX accounting_facts_MV_M_InOutLine_ID ON report.accounting_facts_MV (M_InOutLine_ID);
CREATE INDEX accounting_facts_MV_C_Payment_ID ON report.accounting_facts_MV (C_Payment_ID);
CREATE INDEX accounting_facts_MV_C_Invoice_ID ON report.accounting_facts_MV (C_Invoice_ID);
CREATE INDEX accounting_facts_MV_C_InvoiceLine_ID ON report.accounting_facts_MV (C_InvoiceLine_ID);
CREATE INDEX accounting_facts_MV_C_BankStatement_ID ON report.accounting_facts_MV (C_BankStatement_ID);
CREATE INDEX accounting_facts_MV_C_BankStatementLine_ID ON report.accounting_facts_MV (C_BankStatementLine_ID);
CREATE INDEX accounting_facts_MV_C_BankStatementLine_Ref_ID ON report.accounting_facts_MV (C_BankStatementLine_Ref_ID);
CREATE INDEX accounting_facts_MV_M_Movement_ID ON report.accounting_facts_MV (M_Movement_ID);
CREATE INDEX accounting_facts_MV_M_MovementLine_ID ON report.accounting_facts_MV (M_MovementLine_ID);
CREATE INDEX accounting_facts_MV_C_AllocationHdr_ID ON report.accounting_facts_MV (C_AllocationHdr_ID);
CREATE INDEX accounting_facts_MV_C_AllocationLine_ID ON report.accounting_facts_MV (C_AllocationLine_ID);
CREATE INDEX accounting_facts_MV_C_BPartner_ID ON report.accounting_facts_MV (C_BPartner_ID);
CREATE INDEX accounting_facts_MV_M_Product_ID ON report.accounting_facts_MV (M_Product_ID);
CREATE INDEX accounting_facts_MV_C_Period_ID ON report.accounting_facts_MV (C_Period_ID);
CREATE INDEX accounting_facts_MV_C_Activity_ID ON report.accounting_facts_MV (C_Activity_ID);
CREATE INDEX accounting_facts_MV_Account_ID ON report.accounting_facts_MV (Account_ID);
CREATE INDEX accounting_facts_MV_AD_Ref_List_DocStatus_ID ON report.accounting_facts_MV (AD_Ref_List_DocStatus_ID);
CREATE INDEX accounting_facts_MV_DateDimension_ID ON report.accounting_facts_MV (DateDimension_ID);

----------------------------

CREATE OR REPLACE FUNCTION report.accounting_facts_update()
  RETURNS void AS
$BODY$
begin
	-- General note:
	-- remember about accountingfactsstatus: S=Stale, U=UpToDate, P=InProcesseing

	-----------------------------------------------------------------
	-- update the docStatus of prexisting accounting_facts_MV records
	-- here we have a large potential for improvement, e.g. by adding a trigger to delete the accounting_facts_MV record and set the fact_acct's accountingfactsstatus to S
	UPDATE report.accounting_facts_MV r
	SET 
		AD_Ref_List_DocStatus_ID=v.AD_Ref_List_DocStatus_ID,
		DocStatus=v.DocStatus
	FROM	
		report.accounting_facts_V v 
	where true
		AND r.fact_acct_id=v.fact_acct_id
		AND r.AD_Ref_List_DocStatus_ID!=v.AD_Ref_List_DocStatus_ID
	;
	
	-----------------------------------------------------------------
	-- update the Account_id of prexisting accounting_facts_MV records
	-- this doesn't actually happen, and the udpate costs us aprox 30seconds each time, so we comment it out for now
	/*
	UPDATE report.accounting_facts_MV r
	SET 
		Account_ID=v.Account_ID
	FROM	
		report.accounting_facts_V v 
	where true
		AND r.fact_acct_id=v.fact_acct_id
		AND r.Account_ID!=v.Account_ID
	;
	*/
	-----------------------------------------------------------------
	-- check for fact_acct records that are flagged as "done", but have no accounting_facts_mv (!for whatever reason!), 
	-- and set them back to not-done
	-- note: we grab 60000 instead of 30000 to make sure that if the following updates do'nt recrify the situation, but still set the accountingfactsstatus back to U, then the number of fact_accts with accountingfactsstatus='S' st
	UPDATE fact_acct
	SET accountingfactsstatus='S'
	WHERE fact_acct_ID IN (
		SELECT 
			f.fact_acct_id
	--		count(7)
		FROM fact_Acct f
			LEFT JOIN report.accounting_facts_mv mv ON f.Fact_Acct_ID=mv.Fact_Acct_ID
		WHERE f.accountingfactsstatus='U' 
			AND mv.Fact_Acct_ID IS NULL
		LIMIT 60000
	);

	-----------------------------------------------------------------
	-- grab 30.000 fact_accts each time we run
	UPDATE fact_acct SET accountingfactsstatus='P' 
	WHERE Fact_Acct_ID IN (
		SELECT Fact_Acct_ID
		FROM Fact_Acct
		WHERE COALESCE(accountingfactsstatus,'S')='S' -- we avoided giving the an initial value, so it might still be null, meaning that it needs processing
		ORDER BY Fact_Acct_ID
		LIMIT 30000
	);

	-----------------------------------------------------------------
	-- insert the "unaugmented" data which the view provides
	-- note that i'm explicitly listing each column, because there were often problems with new columns in fact_acct 
	-- that failed this whole function
	INSERT INTO report.accounting_facts_MV (
		m_matchinv_id, -- numeric,
		m_inventory_id, -- numeric,
		m_inventoryline_id, -- numeric,
		gl_journal_id, -- numeric,
		m_inout_id, -- numeric,
		m_inoutline_id, -- numeric,
		c_payment_id, -- numeric,
		c_invoice_id, -- numeric,
		c_invoiceline_id, -- numeric,
		c_bankstatement_id, -- numeric,
		c_bankstatementline_id, -- numeric,
		m_movement_id, -- numeric,
		m_movementline_id, -- numeric,
		c_allocationhdr_id, -- numeric,
		c_allocationline_id, -- numeric,
		fact_acct_id, -- numeric(10,0) NOT, -- NULL,
		ad_client_id, -- numeric(10,0),
		ad_org_id, -- numeric(10,0),
		isactive, -- character(1),
		created, -- timestamp, -- with, -- time, -- zone,
		createdby, -- numeric(10,0),
		updated, -- timestamp, -- with, -- time, -- zone,
		updatedby, -- numeric(10,0),
		c_acctschema_id, -- numeric(10,0),
		account_id, -- numeric(10,0),
		datetrx, -- timestamp, -- without, -- time, -- zone,
		dateacct, -- timestamp, -- without, -- time, -- zone,
		c_period_id, -- numeric(10,0),
		ad_table_id, -- numeric(10,0),
		record_id, -- numeric(10,0),
		line_id, -- numeric(10,0),
		gl_category_id, -- numeric(10,0),
		gl_budget_id, -- numeric(10,0),
		c_tax_id, -- numeric(10,0),
		m_locator_id, -- numeric(10,0),
		postingtype, -- character(1),
		c_currency_id, -- numeric(10,0),
		amtsourcedr, -- numeric,
		amtsourcecr, -- numeric,
		amtacctdr, -- numeric,
		amtacctcr, -- numeric,
		c_uom_id, -- numeric(10,0),
		qty, -- numeric,
		m_product_id, -- numeric(10,0),
		c_bpartner_id, -- numeric(10,0),
		ad_orgtrx_id, -- numeric(10,0),
		c_locfrom_id, -- numeric(10,0),
		c_locto_id, -- numeric(10,0),
		c_salesregion_id, -- numeric(10,0),
		c_project_id, -- numeric(10,0),
		c_campaign_id, -- numeric(10,0),
		c_activity_id, -- numeric(10,0),
		user1_id, -- numeric(10,0),
		user2_id, -- numeric(10,0),
		description, -- character varying(255),
		a_asset_id, -- numeric(10,0),
		c_subacct_id, -- numeric(10,0),
		userelement1_id, -- numeric(10,0),
		userelement2_id, -- numeric(10,0),
		c_projectphase_id, -- numeric(10,0),
		c_projecttask_id, -- numeric(10,0),
		currencyrate, -- numeric,
		balance, -- numeric,
		balance_cr, -- numeric,
		balance_dr, -- numeric,
		issusaaugmented, -- character(1),
		accountingfactsstatus, -- character(1), -- S=Stale, U=UptoDate, P=InProcesseing
		docstatus, -- character varying(25),
		subline_id,
		ad_ref_list_docstatus_id -- numeric,
	)
	SELECT 
		m_matchinv_id, -- numeric,
		m_inventory_id, -- numeric,
		m_inventoryline_id, -- numeric,
		gl_journal_id, -- numeric,
		m_inout_id, -- numeric,
		m_inoutline_id, -- numeric,
		COALESCE(c_payment_id, 100), -- numeric,
		COALESCE(c_invoice_id, 100), -- numeric,
		c_invoiceline_id, -- numeric,
		c_bankstatement_id, -- numeric,
		c_bankstatementline_id, -- numeric,
		m_movement_id, -- numeric,
		m_movementline_id, -- numeric,
		c_allocationhdr_id, -- numeric,
		c_allocationline_id, -- numeric,
		fact_acct_id, -- numeric(10,0) NOT, -- NULL,
		ad_client_id, -- numeric(10,0),
		ad_org_id, -- numeric(10,0),
		isactive, -- character(1),
		created, -- timestamp, -- with, -- time, -- zone,
		createdby, -- numeric(10,0),
		updated, -- timestamp, -- with, -- time, -- zone,
		updatedby, -- numeric(10,0),
		c_acctschema_id, -- numeric(10,0),
		account_id, -- numeric(10,0),
		datetrx, -- timestamp, -- without, -- time, -- zone,
		dateacct, -- timestamp, -- without, -- time, -- zone,
		c_period_id, -- numeric(10,0),
		ad_table_id, -- numeric(10,0),
		record_id, -- numeric(10,0),
		line_id, -- numeric(10,0),
		gl_category_id, -- numeric(10,0),
		gl_budget_id, -- numeric(10,0),
		c_tax_id, -- numeric(10,0),
		m_locator_id, -- numeric(10,0),
		postingtype, -- character(1),
		c_currency_id, -- numeric(10,0),
		amtsourcedr, -- numeric,
		amtsourcecr, -- numeric,
		amtacctdr, -- numeric,
		amtacctcr, -- numeric,
		c_uom_id, -- numeric(10,0),
		qty, -- numeric,
		m_product_id, -- numeric(10,0),
		COALESCE(c_bpartner_id, 100), -- numeric(10,0),
		ad_orgtrx_id, -- numeric(10,0),
		c_locfrom_id, -- numeric(10,0),
		c_locto_id, -- numeric(10,0),
		c_salesregion_id, -- numeric(10,0),
		c_project_id, -- numeric(10,0),
		c_campaign_id, -- numeric(10,0),
		c_activity_id, -- numeric(10,0),
		user1_id, -- numeric(10,0),
		user2_id, -- numeric(10,0),
		description, -- character varying(255),
		a_asset_id, -- numeric(10,0),
		c_subacct_id, -- numeric(10,0),
		userelement1_id, -- numeric(10,0),
		userelement2_id, -- numeric(10,0),
		c_projectphase_id, -- numeric(10,0),
		c_projecttask_id, -- numeric(10,0),
		currencyrate, -- numeric,
		balance, -- numeric,
		balance_cr, -- numeric,
		balance_dr, -- numeric,
		issusaaugmented, -- character(1),
		accountingfactsstatus, -- character(1), -- S=Stale, U=UptoDate, P=InProcesseing
		docstatus, -- character varying(25),
		subline_id,
		ad_ref_list_docstatus_id -- numeric,
	FROM 
		report.accounting_facts_V
	WHERE 
		accountingfactsstatus='P'
	;

	-----------------------------------------------------------------
	-- update the date dimenstion table and link the newly inserted records to it
	INSERT INTO report.dateDimension
	SELECT DISTINCT ON (f.DateAcct::Date)
		nextval('report.datedimension_seq') as DateDimension_id,
		f.DateAcct as date,
		EXTRACT(YEAR from f.DateAcct) as year,
		EXTRACT(MONTH from f.DateAcct) as month,
		EXTRACT(DAY from f.DateAcct) as day,
		EXTRACT(DOW from f.DateAcct) as dow, -- day of week
		EXTRACT(DOW from f.DateAcct) as doy, -- day of year
		EXTRACT(QUARTER  from f.DateAcct) as quarter,
		EXTRACT(WEEK  from f.DateAcct) as week
	FROM
		fact_acct f
	WHERE true
		AND f.accountingfactsstatus!='U'	
		AND NOT EXISTS (
			select 1 from report.dateDimension d 
			where d.Date=f.DateAcct
		);
	UPDATE report.accounting_facts_MV f
	SET DateDimension_id=d.DateDimension_id
	FROM report.dateDimension d
	WHERE true
		AND d.Date=f.DateAcct
		AND f.DateDimension_id IS NULL
	;

	-----------------------------------------------------------------
	-- augment C_AllocationHdr-facts with the respective allocation lines' C_Invoice_ID and C_Payment_ID
	UPDATE report.accounting_facts_MV f_outer
	SET 
		C_Payment_ID=data.C_Payment_ID,
		C_Invoice_ID=data.C_Invoice_ID
	FROM (
			SELECT f.Fact_Acct_ID,
				al.C_Payment_ID,
				al.C_Invoice_ID
			FROM report.accounting_facts_MV f
				JOIN C_AllocationLine al ON al.C_AllocationLine_ID=f.C_AllocationLine_ID
			WHERE true
				AND f.AD_Table_ID=get_table_id('C_AllocationHdr')
				AND (al.C_Payment_ID IS NOT NULL OR al.C_Invoice_ID IS NOT NULL)
				AND f.accountingfactsstatus!='U'
		) data 
	WHERE data.Fact_Acct_ID=f_outer.Fact_Acct_ID;

	-----------------------------------------------------------------
	-- augment M_Matchinv-facts with the respective C_Invoice_ID and the invoice's DocStatus
	UPDATE report.accounting_facts_MV f_outer
	SET 
		C_Invoice_ID=data.C_Invoice_ID,
		C_InvoiceLine_ID=data.C_InvoiceLine_ID,
		DocStatus=data.DocStatus,
		AD_Ref_List_DocStatus_ID=data.AD_Ref_List_DocStatus_ID
	FROM (
			SELECT f.Fact_Acct_ID,
				mi.C_Invoice_ID,
				mi.C_InvoiceLine_ID,
				i.DocStatus,
				rl.AD_Ref_List_ID AS AD_Ref_List_DocStatus_ID
			FROM report.accounting_facts_MV f
				JOIN M_MatchInv mi ON mi.M_MatchInv_ID=f.M_MatchInv_ID
					JOIN C_Invoice i ON i.C_Invoice_ID=mi.C_Invoice_ID
						JOIN report.AD_Ref_List_DocStatus_V rl ON rl.Value=i.DocStatus
			WHERE true
				AND f.AD_Table_ID=get_table_id('M_MatchInv')
				AND (f.accountingfactsstatus!='U' OR COALESCE(f.AD_Ref_List_DocStatus_ID,-1)!=rl.AD_Ref_List_ID)
		) data 
	WHERE data.Fact_Acct_ID=f_outer.Fact_Acct_ID;

	-----------------------------------------------------------------
	-- augment C_BankStatementLine-facts with the respective C_Payment that is references by the C_BankStatementLine or C_BankStatementLine_Ref
	UPDATE report.accounting_facts_MV f_outer
	SET 
		C_Payment_ID=data.C_Payment_ID
	FROM (
			SELECT f.Fact_Acct_ID,
				COALESCE(bslr.C_Payment_ID, bsl.C_Payment_ID) AS C_Payment_ID
			FROM report.accounting_facts_MV f
				JOIN C_BankStatementLine bsl ON bsl.C_BankStatementLine_ID=f.C_BankStatementLine_ID
				LEFT JOIN C_BankStatementLine_Ref bslr ON bslr.C_BankStatementLine_Ref_ID=f.C_BankStatementLine_Ref_ID 
			WHERE true
				AND f.AD_Table_ID=get_table_id('C_BankStatement')
				AND f.accountingfactsstatus!='U'
		) data 
	WHERE data.Fact_Acct_ID=f_outer.Fact_Acct_ID;

	-----------------------------------------------------------------
	-- finish
	UPDATE fact_acct SET accountingfactsstatus='U' WHERE accountingfactsstatus='P';

	UPDATE report.accounting_facts_MV f
	SET accountingfactsstatus=fa.accountingfactsstatus 
	FROM fact_acct fa
	WHERE f.Fact_Acct_ID=fa.Fact_Acct_ID 
		AND fa.accountingfactsstatus='U' 
		AND f.accountingfactsstatus!='U';

end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
;


--select report.accounting_facts_update();
--select count(7),accountingfactsstatus from fact_acct group by accountingfactsstatus;
