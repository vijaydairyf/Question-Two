CREATE OR REPLACE FORCE VIEW vw_approvals AS
  SELECT approvals.approval_id,
    approvals.approve_status,
    approvals.forward_id,
    approvals.is_ad_hoc,
    approvals.table_name,
    approvals.table_id,
    approvals.escalation_time,
    approvals.application_date,
    approvals.completion_date,
    approvals.action_date,
    approvals.approval_narrative,
    approvals.to_be_done,
    approvals.what_is_done,
    workflow_phases.notice_file,
    workflow_phases.workflow_phase_id,
    workflow_phases.approval_level,
    approvals.approval_group,
    workflow_phases.notice_email,
    workflow_phases.advice_email,
    workflow_phases.review_email,
    workflow_phases.return_level,
    workflow_phases.escalation_hours,
    workflow_phases.notice,
    workflow_phases.required_approvals,
    workflow_phases.phase_narrative,
    workflows.workflow_id,
    workflows.workflow_name,
    entity_types.entity_type_id,
    entity_types.entity_type_name,
    actual.entity_id     AS actual_entity_id,
    actual.entity_name   AS actual_entity_name,
    actual.primary_email AS actual_entity_email,
    origin.entity_id     AS origin_entity_id,
    origin.entity_name   AS origin_entity_name,
    origin.primary_email AS origin_entity_email,
    appr.entity_id       AS approving_entity_id,
    appr.entity_name     AS approving_entity_name,
    appr.primary_email   AS approving_entity_email,
    client.client_id,
    COALESCE(client.client_name, approvals.task_source, COALESCE(client_inspection.complainant_name,'SCHEDULE')) AS client_name,
    client.id_number,
    client.pin,
    client.postal_code,
    client.email,
    license.license_id,
    COALESCE(license.license_name, approvals.task_type, DECODE(client_inspection.activity_type_id, 1, 'Interference', 2, 'Monitoring', 3, 'Inspection', 'INSPECTION')) AS license_name,
    license.license_type_id
  FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
	INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
	LEFT JOIN entitys actual ON approvals.entity_id = actual.entity_id
	INNER JOIN entitys origin ON approvals.org_entity_id = origin.entity_id
	INNER JOIN entitys appr ON approvals.app_entity_id = appr.entity_id
	INNER JOIN entity_types ON workflow_phases.approval_entity_id = entity_types.entity_type_id
	LEFT JOIN client_license ON approvals.table_id = client_license.workflow_table_id
	LEFT JOIN client_inspection ON approvals.table_id = client_inspection.workflow_table_id
	LEFT JOIN license ON client_license.license_id = license.license_id
	LEFT JOIN client ON client_license.client_id = client.client_id;



CREATE OR REPLACE TRIGGER trg_upd_approvals AFTER UPDATE OF approve_status ON approvals FOR EACH ROW
  DECLARE

	PRAGMA AUTONOMOUS_TRANSACTION;
	
	this_wf_id				 integer; 	--id of the xponding wf
	nxt_phase_level			integer;
	nxt_phase_id		    integer;

	this_phase_level		 integer;
  
	req_approvals       integer;    --required approvals
	curr_approvals      integer;    --current approvals
  
	nxt_pay_type_id 	integer;
	pay_header_id		integer;
  
	app_fee				real;
	initial_fee			real;
	vsat_fee			real;
	type_appr_fee		real;
	pending_pay			integer;

	billid				integer;
	penalty_fee			real;
	
	parent_table        varchar(50);    --first table used in this approval
	table_link			varchar(50);
	wf_table            varchar(50);

	ret_level			integer;	--return level number
	ret_wf_phase		integer;	--return workflow phase

	cli_lic_id			integer;		--corresponding client license id 
	lic_id				integer;		--license id
	cli_id				integer;		--client id
	lic_type_id			integer;
	
	p_checklists		integer;		--pending uncleared and manadatory checklists
	appr_group			integer;

	a_checklist 		char(1);
	l_sql_stmt			VARCHAR2(1000);

BEGIN
	
	IF :NEW.is_ad_hoc = '2' THEN
		RETURN;
	END IF;

	SELECT approvals.table_name, workflows.table_link_field INTO parent_table, table_link
	FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
		INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
	WHERE approvals.approval_id = :NEW.approval_id;
	
	SELECT seq_approval_group.nextval INTO appr_group FROM dual;

	IF parent_table = 'CLIENT_LICENSE' THEN
  
		SELECT client_license.client_license_id, client_license.client_id,license.license_id, license.license_type_id INTO cli_lic_id, cli_id, lic_id, lic_type_id
		FROM client_license 
		INNER JOIN license ON client_license.license_id = license.license_id
		LEFT JOIN license_type ON license.license_type_id = license_type.license_type_id
		WHERE workflow_table_id = :NEW.table_id;
    
	END IF;
    
	IF :NEW.approve_status = 'X' THEN
		--LOCATE return level
		SELECT return_level, workflow_id INTO ret_level,this_wf_id 
		FROM workflow_phases WHERE workflow_phase_id = :NEW.workflow_phase_id AND rownum = 1;

		--identify the workflow phase
		SELECT workflow_phase_id INTO ret_wf_phase 
		FROM workflow_phases WHERE approval_level = ret_level AND workflow_id = this_wf_id;

		--send approvals
		INSERT INTO approvals (workflow_phase_id, parent_approval_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done, task_source, task_type)
		SELECT workflow_phases.workflow_phase_id, :NEW.approval_id, appr_group, parent_table, :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'REVIEW THIS: - ' || workflow_phases.phase_narrative, :NEW.task_source, :NEW.task_type
		FROM workflow_phases
			INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
			WHERE workflow_phases.workflow_phase_id = ret_wf_phase;
		COMMIT;	

		--GET PENDING CHECKLISTS INTO THE ADHOC TASK
		SELECT count(approval_checklist_id) as cl_count INTO p_checklists
		FROM approval_checklists
		INNER JOIN checklists ON approval_checklists.checklist_id = checklists.checklist_id
		INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
		WHERE workflow_phases.workflow_phase_id = :NEW.workflow_phase_id AND approval_checklists.workflow_table_id = :NEW.table_id
			AND checklists.is_mandatory = '1' AND approval_checklists.done = '0';
		
	ELSIF(:OLD.approve_status != 'C' AND :NEW.approve_status = 'C') THEN		

		--COUNT PENDING (MANDATORY) CHECKLISTS
		SELECT count(approval_checklist_id) as cl_count INTO p_checklists
			FROM approval_checklists
			INNER JOIN checklists ON approval_checklists.checklist_id = checklists.checklist_id
			INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
		WHERE workflow_phases.workflow_phase_id = :NEW.workflow_phase_id AND approval_checklists.workflow_table_id = :NEW.table_id
			AND checklists.is_mandatory = '1' AND approval_checklists.done = '0';

		SELECT allow_checklist INTO a_checklist
		FROM workflow_phases WHERE workflow_phase_id = :NEW.workflow_phase_id;

		IF(a_checklist = '1') THEN p_checklists := 0; END IF;
		
		IF p_checklists = 0 THEN		--IF NO MANDATORY CHECKLISTS REMAINING

			--NOW CONFIRM PENDING PAYMENTS
			SELECT count(license_payment_header_id) INTO pending_pay FROM license_payment_header 
			WHERE workflow_table_id = :NEW.table_id AND is_paid = '0';
			IF(pending_pay > 0) THEN
				RAISE_APPLICATION_ERROR(-20011,'SORRY. THE LICENSEE NEEDS TO CLEAR WITH FINANCE BEFORE PROCEEDING');		
			END IF;
			
			--IF THIS IS A CHILD...REVIVE THE PARENT
			IF (:NEW.parent_approval_id IS NOT NULL) THEN  
			 	RETURN;
			END IF;
	        
			SELECT workflow_id, approval_level, required_approvals INTO this_wf_id, this_phase_level, req_approvals
			FROM workflow_phases WHERE workflow_phase_id = :NEW.workflow_phase_id;
      
			--get next phase (in same workflow) with 
			SELECT MIN(approval_level) INTO nxt_phase_level
			FROM workflow_phases 
			WHERE workflow_id = this_wf_id AND approval_level > this_phase_level;

			SELECT MIN(workflow_phase_id) INTO nxt_phase_id 
			FROM workflow_phases 
			WHERE workflow_id = this_wf_id AND approval_level = nxt_phase_level;
			
			--check payment_type for next phase 
			IF nxt_phase_id IS NOT NULL THEN
				SELECT payment_type_id INTO nxt_pay_type_id FROM workflow_phases WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
			ELSIF :NEW.is_ad_hoc = '1' THEN        
				RETURN;
			ELSE --if this is the final phase		
				nxt_pay_type_id := -1;
			
				EXECUTE IMMEDIATE 'UPDATE ' || parent_table || ' SET is_workflow_complete = ''1''  WHERE workflow_table_id = ' || :NEW.table_id;
				COMMIT;

				IF (table_link = 'IS_NOTICE') THEN
					UPDATE notice SET appr_notice = '1' WHERE workflow_table_id = :NEW.table_id;
					COMMIT;
				END IF;
				IF (table_link = 'IS_PENALTY') THEN
					UPDATE notice SET appr_penalty = '1' WHERE workflow_table_id = :NEW.table_id;
					COMMIT;

					SELECT bill_license_id, penalty INTO billid, penalty_fee
					FROM vw_notice 
					WHERE workflow_table_id = :NEW.table_id;

					--INSERT INTO LICENSE PAYMENT OR EQUIV. client_license_id id will be updated after confirmation by user via(gui/xml)
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;

					--INSERT INTO license_payment_header(license_payment_header,workflow_phase_id,client_license_id,description) VALUES(pay_header_id,nxt_phase_id,?,'LICENSE APPLICATION');
					INSERT INTO license_payment_header(license_payment_header_id, client_license_id, workflow_phase_id, workflow_table_id, description) 
					VALUES(pay_header_id, billid, nxt_phase_id, :NEW.table_id, 'Penalty');
					COMMIT;

					--GET TYPE APPROVAL FEE
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description, amount) 
					VALUES(pay_header_id, 'EAC2DCB2C5B54A7C953E7C10F105B246', 'Penalty Fee (KES)', penalty_fee);
					COMMIT;
				END IF;
				IF (table_link = 'IS_REVOCATION') THEN
					UPDATE notice SET appr_revocation = '1' WHERE workflow_table_id = :NEW.table_id;
					COMMIT;
				END IF;

			END IF;
			
			--IF NO PAYMENT (in next fase) CONTINUE
			IF nxt_pay_type_id = 1 THEN

				INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done, task_source, task_type)
				SELECT workflow_phases.workflow_phase_id, appr_group, parent_table, :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Approve - ' || workflow_phases.phase_narrative, :NEW.task_source, :NEW.task_type
				FROM workflow_phases INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
				WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
				COMMIT;		

			ELSIF nxt_pay_type_id = 6 THEN		--TYPE APPROVAL FEE
				
				SELECT ta_fee INTO type_appr_fee FROM client_license WHERE client_license_id = cli_lic_id;

				IF(type_appr_fee = 0 OR type_appr_fee IS NULL) THEN
					RAISE_APPLICATION_ERROR(-20012,'SORRY. U NEED TO INPUT THE TYPE APPROVAL FEE FOR ALL EQUIPMENT IN THIS APPLICATION');		
				END IF;

				--INSERT INTO LICENSE PAYMENT OR EQUIV. client_license_id id will be updated after confirmation by user via(gui/xml)
				SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;

				--INSERT INTO license_payment_header(license_payment_header,workflow_phase_id,client_license_id,description) VALUES(pay_header_id,nxt_phase_id,?,'LICENSE APPLICATION');
				INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
				VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'TYPE APPROVAL');
				COMMIT;

				--GET TYPE APPROVAL FEE
				INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
					VALUES(pay_header_id,'EAC2DCB2C5B54A7C953E7C10F105B246','Type Approval Fee (KES)',type_appr_fee);
				COMMIT;

				--FINALY THE APPROVALS
				INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
				SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
					FROM workflow_phases				
					INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
					WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
				COMMIT;	

			--IF NEXT WORKFLOW NEEDS PAYMENT		
			ELSIF nxt_pay_type_id = 2 THEN		--LICENSE APPLICATION FEE
				--INSERT INTO LICENSE PAYMENT OR EQUIV. client_license_id id will be updated after confirmation by user via(gui/xml)
				SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;
				--INSERT INTO license_payment_header(license_payment_header,workflow_phase_id,client_license_id,description) VALUES(pay_header_id,nxt_phase_id,?,'LICENSE APPLICATION');
				INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
				VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE APPLICATION');
				COMMIT;
				
				--get license stuff
				SELECT application_fee INTO app_fee FROM license 
					INNER JOIN client_license ON license.license_id = client_license.license_id
					WHERE client_license.workflow_table_id = :NEW.table_id;

				INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
					VALUES(pay_header_id,'DED128EAB8C746DD93121305EBBE0488','Application Fee (KES)',app_fee);
				COMMIT;
				
				--FINALY THE APPROVALS
				INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
				SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
					FROM workflow_phases				
					INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
					WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
				COMMIT;	

			ELSIF nxt_pay_type_id = 3 THEN		--LICENSE INITIAL FEE
				
				--IF LAND MOBILE ...
				IF lic_id = 12 THEN		--IF LAND MOBILE
					--FIRST CALCULATE THE CHARGES
					SELECT sum(prorated_charge) INTO initial_fee
						FROM station					
						INNER JOIN vhf_network ON station.vhf_network_id = vhf_network.vhf_network_id					
						WHERE vhf_network.client_license_id = cli_lic_id;
					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'CLIENT_LICENSE', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	

				ELSIF lic_id = 20 THEN		--IF ALARM
					--FIRST CALCULATE THE CHARGES
					SELECT sum(prorated_charge) INTO initial_fee
						FROM station					
						INNER JOIN vhf_network ON station.vhf_network_id = vhf_network.vhf_network_id					
						WHERE vhf_network.client_license_id = cli_lic_id;
					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'CLIENT_LICENSE', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	


				ELSIF lic_id = 8 THEN		--AIRCRAFT 
					--FIRST CALCULATE THE CHARGES  - this is a stop gap measure.. i need to use prorated_charge
					SELECT sum(annual_station_charge) INTO initial_fee
						FROM station											
						WHERE station.client_license_id = cli_lic_id AND rownum = 1;
					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	

				ELSIF lic_id = 21 THEN		--P2P
					--FIRST CALCULATE THE CHARGES  - this is a stop gap measure.. i need to use prorated_charge
					SELECT round(sum(annual_station_charge)+0.4) INTO initial_fee
						FROM terrestrial_link											
						WHERE terrestrial_link.client_license_id = cli_lic_id;
					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	


				ELSIF lic_id = 24 THEN		--FIXED WIRELESS
					--FIRST CALCULATE THE CHARGES  - this is a stop gap measure.. i need to use prorated_charge
					SELECT round(sum(annual_station_charge)+0.4) INTO initial_fee
						FROM station											
						WHERE station.client_license_id = cli_lic_id;
					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	


				ELSIF (lic_id = 136 or lic_id = 137) THEN		--VSAT LOCAL/KENYA
					--FIRST CALCULATE THE CHARGES  - this is a stop gap measure.. i need to use prorated_charge
					SELECT round(sum(station_charge.amount) + 0.4) INTO vsat_fee
					FROM station INNER JOIN station_charge ON station.station_charge_id = station_charge.station_charge_id
					WHERE station.client_license_id = cli_lic_id AND rownum = 1;

					SELECT COALESCE(initial_fee,0) INTO initial_fee 
					FROM license 
					INNER JOIN client_license ON license.license_id = client_license.license_id
					WHERE client_license.workflow_table_id = :NEW.table_id;

					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;

					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id, client_license_id, workflow_phase_id, workflow_table_id, description) 
					VALUES(pay_header_id, cli_lic_id, nxt_phase_id, :NEW.table_id, 'LICENSE INITIAL FEE');
					COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) 
					VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id, product_code, description, amount) 
					VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
					COMMIT;

					INSERT INTO license_payment_line(license_payment_header_id, product_code, description, amount) 
					VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', vsat_fee);
					COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
					SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
					FROM workflow_phases INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
					WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
					COMMIT;	

				ELSIF (lic_type_id = 11) OR (lic_type_id = 13) OR (lic_type_id = 14) OR (lic_type_id = 16) OR (lic_type_id = 17) THEN		--ASP,CSP, TEC

					--get license stuff
					SELECT COALESCE(initial_fee,0) INTO initial_fee FROM license 
						INNER JOIN client_license ON license.license_id = client_license.license_id
						WHERE client_license.workflow_table_id = :NEW.table_id;
	

					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	
				
				END IF;		--IF LICENS TYPE ID

			END IF;		--END IF PAY_TYPE ......

			--WE ADD checklists for the NEXT PHASE.. REGARDLESS OF THE VARIABLES ABOVE
			INSERT INTO approval_checklists (checklist_id, workflow_table_id)				
			SELECT checklist_id, :NEW.table_id
				FROM checklists
					INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
					INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id					
					WHERE workflow_phases.is_utility = '0' AND workflow_phases.workflow_phase_id = nxt_phase_id
					ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
          
			COMMIT;
		
		ELSE			--IF THERE ARE PENDING CHECKLISTS
			--raise_application_error(-20030,'Client email NOT DEFINED ('||fsm_pay_rec.clientname|| '). Offer not sent');
			--INSERT INTO sys_errors(sys_error,error_message) VALUES('SORRY. THERE ARE PENDING (mandatory) CHECKLISTS. Approval Rejected',NULL);
			--COMMIT;
			RAISE_APPLICATION_ERROR(-20010,'SORRY. THERE ARE  '|| p_checklists|| ' PENDING (mandatory) CHECKLISTS. Approval Rejected');		
		END IF;
	
	END IF;		--END IF APPROVE_STATUS... (C OR COMPLETE ETC)
	
end;
/


create or replace TRIGGER trg_approvals BEFORE INSERT OR UPDATE ON approvals for each row 
begin     
	if inserting then 
		if :NEW.approval_id is null then
			SELECT seq_approval_id.nextval into :NEW.approval_id from dual;
		end if;
								
		IF :NEW.is_ad_hoc = '1' AND :NEW.approval_group = '0' THEN
			SELECT seq_approval_group.nextval INTO :NEW.approval_group FROM dual;
		END IF;

		IF :NEW.is_ad_hoc = '2' THEN
			SELECT seq_approval_group.nextval INTO :NEW.approval_group FROM dual;

			SELECT workflow_phase_id, table_name, table_id
			INTO :NEW.workflow_phase_id, :NEW.table_name, :NEW.table_id
			FROM approvals WHERE approval_id = :NEW.forward_id;
		END IF;

		--BUG FIX.. unable to link adhoc approval via xml.. baraza inserts client_license_id instead..
		if :NEW.is_ad_hoc = '1' AND :NEW.table_name = 'LICENSE' THEN
			SELECT workflow_table_id INTO :NEW.table_id FROM client_license WHERE client_license_id = :NEW.table_id;
		elsif :NEW.is_ad_hoc = '1' AND :NEW.table_name = 'CLIENT_INSPECTION' THEN --:NEW.table_name = 'ACTIVITY_TYPE' THEN
			UPDATE client_inspection SET assign_to = :NEW.app_entity_id WHERE client_inspection_id = :NEW.table_id;			
			SELECT workflow_table_id INTO :NEW.table_id FROM client_inspection WHERE client_inspection_id = :NEW.table_id;
		end if;

		--SCHEDULE EMAIL TO BE SENT.. table_id links to the specific approval in the system
		INSERT INTO sys_emailed (sys_email_id,table_id, table_name, email_type) VALUES (1,:NEW.approval_id, 'APPROVALS', 1);			
		
	elsif updating then
		--LOGISTICS
		:NEW.completion_date := CURRENT_TIMESTAMP;
	end if; 
end;
/

