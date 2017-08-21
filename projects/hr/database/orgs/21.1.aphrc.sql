
CREATE OR REPLACE FUNCTION ins_employees() RETURNS trigger AS $$
DECLARE
	v_entity_type_id		integer;
	v_use_type				integer;
	v_org_sufix 			varchar(4);
	v_first_password		varchar(12);
	v_user_count			integer;
	v_user_name				varchar(120);
BEGIN
	IF (TG_OP = 'INSERT') THEN
		IF(NEW.entity_id IS NULL) THEN
			SELECT org_sufix INTO v_org_sufix
			FROM orgs WHERE (org_id = NEW.org_id);
			
			IF(v_org_sufix is null)THEN v_org_sufix := ''; END IF;

			NEW.entity_id := nextval('entitys_entity_id_seq');

			IF(NEW.employee_id is null) THEN
				NEW.employee_id := NEW.entity_id;
			END IF;
			
			SELECT entity_type_id INTO v_entity_type_id
			FROM entity_types 
			WHERE (org_id = NEW.org_id) AND (use_key_id = 1);

			v_first_password := first_password();
			v_user_name := lower(substring(NEW.first_name from 1 for 1) || NEW.surname);

			SELECT count(entity_id) INTO v_user_count
			FROM entitys
			WHERE (org_id = NEW.org_id) AND (user_name = v_user_name);
			IF(v_user_count > 0) THEN v_user_name := v_user_name || v_user_count::varchar; END IF;

			INSERT INTO entitys (entity_id, org_id, entity_type_id, use_key_id,
				entity_name, user_name, function_role, 
				first_password, entity_password, primary_email, primary_telephone)
			VALUES (NEW.entity_id, NEW.org_id, v_entity_type_id, 1, 
				(NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, '')),
				v_user_name, 'staff',
				v_first_password, md5(v_first_password),
				v_user_name || '@aphrc.org', NEW.phone);
				
			INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name, email_type)
			SELECT org_id, sys_email_id, NEW.entity_id, 'entitys', 1
			FROM sys_emails
			WHERE (use_type = 3) AND (org_id = NEW.org_id);
		END IF;

		v_use_type := 2;
		IF(NEW.gender = 'M')THEN v_use_type := 3; END IF;

		--- Add default leave types
		INSERT INTO employee_leave_types (entity_id, org_id, leave_type_id, leave_balance)
		SELECT NEW.entity_id, NEW.org_id, leave_type_id, 0
		FROM leave_types
		WHERE (org_id = NEW.org_id) AND ((use_type = 1) OR (use_type = v_use_type));
		
		--- Add default task rate definations
		INSERT INTO task_entitys (entity_id, org_id, task_type_id, task_entity_cost, task_entity_price)
		SELECT NEW.entity_id, NEW.org_id, task_type_id, default_cost, default_price
		FROM task_types
		WHERE (org_id = NEW.org_id);
	
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE entitys  SET entity_name = (NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, ''))
		WHERE entity_id = NEW.entity_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

