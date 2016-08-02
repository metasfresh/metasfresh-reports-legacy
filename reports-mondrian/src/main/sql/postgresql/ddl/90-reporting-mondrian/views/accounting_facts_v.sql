-- View: report.accounting_facts_v

-- DROP VIEW report.accounting_facts_v;

CREATE OR REPLACE VIEW report.accounting_facts_v AS 
 SELECT 
        CASE
            WHEN fa.ad_table_id = get_table_id('M_MatchInv'::character varying) THEN fa.record_id
            ELSE NULL::numeric
        END AS m_matchinv_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('M_Inventory'::character varying) THEN fa.record_id
            ELSE NULL::numeric
        END AS m_inventory_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('M_Inventory'::character varying) THEN fa.line_id
            ELSE NULL::numeric
        END AS m_inventoryline_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('GL_Journal'::character varying) THEN fa.record_id
            ELSE NULL::numeric
        END AS gl_journal_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('M_InOut'::character varying) THEN fa.record_id
            ELSE NULL::numeric
        END AS m_inout_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('M_InOut'::character varying) THEN fa.line_id
            ELSE NULL::numeric
        END AS m_inoutline_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('C_Payment'::character varying) THEN fa.record_id
            ELSE NULL::numeric
        END AS c_payment_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('C_Invoice'::character varying) THEN fa.record_id
            ELSE NULL::numeric
        END AS c_invoice_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('C_Invoice'::character varying) THEN fa.line_id
            ELSE NULL::numeric
        END AS c_invoiceline_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('C_BankStatement'::character varying) THEN fa.record_id
            ELSE NULL::numeric
        END AS c_bankstatement_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('C_BankStatement'::character varying) THEN fa.line_id
            ELSE NULL::numeric
        END AS c_bankstatementline_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('C_BankStatement'::character varying) THEN fa.subline_id
            ELSE NULL::numeric
        END AS c_bankstatementline_ref_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('M_Movement'::character varying) THEN fa.record_id
            ELSE NULL::numeric
        END AS m_movement_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('M_Movement'::character varying) THEN fa.line_id
            ELSE NULL::numeric
        END AS m_movementline_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('C_AllocationHdr'::character varying) THEN fa.record_id
            ELSE NULL::numeric
        END AS c_allocationhdr_id, 
        CASE
            WHEN fa.ad_table_id = get_table_id('C_AllocationHdr'::character varying) THEN fa.line_id
            ELSE NULL::numeric
        END AS c_allocationline_id, rl.ad_ref_list_id AS ad_ref_list_docstatus_id, 
		fa.fact_acct_id, fa.ad_client_id, fa.ad_org_id, fa.isactive, fa.created, fa.createdby, fa.updated, fa.updatedby, fa.c_acctschema_id, fa.account_id, fa.datetrx, fa.dateacct, fa.c_period_id, fa.ad_table_id, fa.record_id, fa.line_id, fa.gl_category_id, fa.gl_budget_id, fa.c_tax_id, fa.m_locator_id, fa.postingtype, fa.c_currency_id, fa.amtsourcedr, fa.amtsourcecr, fa.amtacctdr, fa.amtacctcr, fa.c_uom_id, fa.qty, fa.m_product_id, fa.c_bpartner_id, fa.ad_orgtrx_id, fa.c_locfrom_id, fa.c_locto_id, fa.c_salesregion_id, fa.c_project_id, fa.c_campaign_id, fa.c_activity_id, fa.user1_id, fa.user2_id, fa.description, fa.a_asset_id, fa.c_subacct_id, fa.userelement1_id, fa.userelement2_id, fa.c_projectphase_id, fa.c_projecttask_id, fa.currencyrate, fa.balance, fa.balance_cr, fa.balance_dr, fa.issusaaugmented, fa.accountingfactsstatus, fa.docstatus, fa.subline_id
   FROM fact_acct fa
   LEFT JOIN report.ad_ref_list_docstatus_v rl ON rl.value::text = fa.docstatus::text;
