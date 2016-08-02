--
-- note: the fix is to also insert C_BankStatementLine_Ref_ID into accounting_facts_MV
--

-- Function: report.accounting_facts_update()

-- DROP FUNCTION report.accounting_facts_update();

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
		C_BankStatementLine_Ref_ID,
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
		C_BankStatementLine_Ref_ID,
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
	-- augment C_BankStatementLine-facts with the respective C_Payment that is referenced by the C_BankStatementLine or C_BankStatementLine_Ref
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


  
--
-- fix existing records
--  
UPDATE report.accounting_facts_MV f
SET C_BankStatementLine_Ref_ID=v.C_BankStatementLine_Ref_ID
FROM report.accounting_facts_v v
WHERE COALESCE(f.C_BankStatementLine_Ref_ID,-1)!=COALESCE(v.C_BankStatementLine_Ref_ID,-1)
	and f.Fact_acct_id=v.Fact_acct_id;
----------------------------------------------

UPDATE report.accounting_facts_MV f_outer
SET 
	C_Payment_ID=data.C_Payment_ID_shall, 
	C_BPartner_ID=data.C_BPartner_ID_shall
FROM (
		SELECT f.Fact_Acct_ID, f.Line_ID, f.SubLine_ID, 
			f.C_BankStatement_ID,
			f.C_BankStatementLine_ID, 
			f.C_BankStatementLine_Ref_ID,
			f.C_Payment_ID as C_Payment_ID_is
			,COALESCE(bslr.C_Payment_ID, bsl.C_Payment_ID, 100) AS C_Payment_ID_shall
			,f.C_BPartner_ID as C_BPartner_ID_is
			,COALESCE(bslr.C_BPartner_ID, bsl.C_BPartner_ID, 100) AS C_BPartner_ID_shall
		FROM report.accounting_facts_MV f
			JOIN C_BankStatementLine bsl ON bsl.C_BankStatementLine_ID=f.C_BankStatementLine_ID
			LEFT JOIN C_BankStatementLine_Ref bslr ON bslr.C_BankStatementLine_Ref_ID=f.C_BankStatementLine_Ref_ID 
		WHERE true
			AND f.AD_Table_ID=get_table_id('C_BankStatement')
	) data
WHERE 
	data.Fact_Acct_ID=f_outer.Fact_Acct_ID 
--AND data.line_id=f_outer.line_id AND data.subline_id=f_outer.subline_id
	AND f_outer.C_BankStatementLine_ID = 		data.C_BankStatementLine_ID
	AND f_outer.C_BankStatementLine_Ref_ID =	data.C_BankStatementLine_Ref_ID
	AND (f_outer.C_Payment_ID != data.C_Payment_ID_shall
		OR f_outer.C_BPartner_ID != data.C_BPartner_ID_shall
	)
--------------------------------------------