

CREATE OR REPLACE FUNCTION ins_contrib()
  RETURNS trigger AS
$BODY$
DECLARE
	v_investment_amount			real;
	v_period_id					integer;
	v_org_id					integer;
	v_contribution_type_id		integer;
	v_merry_go_round_amount		real;
	 v_mgr_number				integer;
	 v_merry_go_round_number	integer;
	v_money_in					real;
	v_money_out					real;
	v_entity_id			integer;

BEGIN
	
	SELECT   org_id, contribution_type_id, SUM(investment_amount), SUM(merry_go_round_amount)
	INTO  v_org_id, v_contribution_type_id, v_money_in, v_money_out
	FROM contributions
		WHERE paid = true AND period_id = NEW.period_id 
		GROUP BY contribution_type_id,org_id;
	v_period_id := NEW.period_id;
	

		UPDATE contributions SET money_in  = v_money_in WHERE paid = true AND period_id =  v_period_id AND contribution_type_id = v_contribution_type_id;
			IF (v_money_out = 0)THEN
			UPDATE contributions SET money_out  = 0 WHERE paid = true AND period_id =  v_period_id AND contribution_type_id = v_contribution_type_id;
	ELSIF 	(v_money_out != 0)THEN
	
		SELECT mgr_number INTO v_mgr_number FROM periods  WHERE period_id = NEW.period_id AND org_id = v_org_id;
		SELECT entity_id, merry_go_round_number INTO v_entity_id, v_merry_go_round_number 
		FROM vw_member_contrib 
		WHERE merry_go_round_number = v_mgr_number;
		
			UPDATE contributions SET money_out  = v_money_out WHERE paid = true AND period_id =  v_period_id AND contribution_type_id = v_contribution_type_id AND entity_id = v_entity_id;
	
	END IF;

RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql
  
CREATE TRIGGER ins_contrib
AFTER INSERT OR UPDATE of paid
ON contributions
FOR EACH ROW
EXECUTE PROCEDURE ins_contrib();

  CREATE OR REPLACE FUNCTION generate_contribs(
    character varying,
    character varying,
    character varying)
  RETURNS character varying AS
$BODY$
DECLARE
	rec						RECORD;
	v_period_id		integer;
	vi_period_id		integer;
	reca			RECORD;
	v_org_id		integer;
	v_month_name	varchar(50);
	v_member_id		integer;

	msg 			varchar(120);
BEGIN
	SELECT period_id, org_id, to_char(start_date, 'Month YYYY') INTO v_period_id, v_org_id, v_month_name
	FROM periods
	WHERE (period_id = $1::integer);

	SELECT period_id INTO vi_period_id FROM contributions WHERE period_id in (v_period_id) AND org_id in (v_org_id);

	IF( vi_period_id is null) THEN

	FOR reca IN SELECT member_id, entity_id FROM members WHERE (org_id = v_org_id) LOOP
	
	FOR rec IN SELECT org_id, frequency, contribution_type_id, investment_amount, merry_go_round_amount 
	FROM contribution_types WHERE (applies_to_all = true)  AND (org_id = v_org_id) LOOP
		IF (rec.frequency = 'Weekly') THEN
		FOR i in 1..4 LOOP
			INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount, member_id, entity_id)
			VALUES(v_period_id, rec.org_id, rec.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
			reca.member_id, reca.entity_id);
		END LOOP;
		END IF;
		IF (rec.frequency = 'Fortnightly') THEN
		FOR i in 1..2 LOOP
			INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount,member_id, entity_id)
			VALUES(v_period_id, rec.org_id, rec.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
			reca.member_id, reca.entity_id);
		END LOOP;
		END IF;
		IF (rec.frequency = 'Monthly') THEN
			INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount,member_id,entity_id)
			VALUES(v_period_id, rec.org_id, rec.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
			reca.member_id, reca.entity_id);
		END IF;
	
	END LOOP;
	
	END LOOP;
	msg := 'Contributions Generated';
	ELSE
	msg := 'Contributions already exist';
	END IF;
	

RETURN msg;	
END;
$BODY$
  LANGUAGE plpgsql


 CREATE OR REPLACE FUNCTION ins_members()
  RETURNS trigger AS
$BODY$
DECLARE
	rec 			RECORD;
	v_entity_id		integer;
	
BEGIN
	IF (TG_OP = 'INSERT') THEN
	NEW.entity_id := nextval('entitys_entity_id_seq');
	
	INSERT INTO entitys (entity_id,entity_name,org_id,entity_type_id,user_name,primary_email,primary_telephone,function_role,details)
	VALUES (New.entity_id,New.surname,New.org_id::INTEGER,1,NEW.email,NEW.email,NEW.phone,'member',NEW.details) RETURNING entity_id INTO v_entity_id;

	NEW.entity_id := v_entity_id;

	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE members  SET full_name = 
(NEW.Surname || ' ' 
|| NEW.First_name || ' ' 
|| COALESCE(NEW.Middle_name, ''))
	WHERE entity_id = NEW.entity_id;
END IF;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;
  
CREATE TRIGGER ins_members
  BEFORE INSERT
  ON members
  FOR EACH ROW
  EXECUTE PROCEDURE ins_members();

     
CREATE OR REPLACE FUNCTION get_total_repayment(real, real, real) RETURNS real AS $$
DECLARE
	repayment real;
	ri real;
BEGIN
	ri := (($1* $2 * $3)/1200);
	repayment := $1 + (($1* $2 * $3)/1200);
	RETURN repayment;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION get_interest_amount(real,real,real) RETURNS real AS $$
DECLARE
	ri real;
BEGIN
	ri :=(($1* $2 * $3)/1200);
RETURN ri;
END;
$$ LANGUAGE plpgsql;

 
 CREATE OR REPLACE FUNCTION ins_investment()
  RETURNS trigger AS
$BODY$
DECLARE
	v_interests			real;
	
BEGIN
	SELECT interest_amount INTO v_interests FROM  investment_types WHERE investment_type_id = NEW. investment_type_id;
		
	IF (NEW.monthly_payments is null and NEW.principal is not null and  NEW.repayment_period is not null) THEN
		NEW.monthly_payments := NEW.principal/ NEW.repayment_period;
	ELSEIF (NEW.repayment_period is null and NEW.principal is not null and NEW.monthly_payments is not null ) THEN
		NEW.repayment_period := NEW.principal/NEW.monthly_payments;
	ELSEIF (NEW.repayment_period is null AND NEW.monthly_payments is null) THEN
		RAISE EXCEPTION 'Please enter the repayment period or the monthly payments';
	END IF;
	
	RETURN NEW;
END;

$BODY$
  LANGUAGE plpgsql;

CREATE TRIGGER ins_investment BEFORE INSERT OR UPDATE ON investments
	FOR EACH ROW EXECUTE PROCEDURE ins_investment();

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON investments
    FOR EACH ROW EXECUTE PROCEDURE upd_action();


CREATE OR REPLACE FUNCTION investment_aplication(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 		varchar(120);
BEGIN
	msg := 'Investment applied';
	
	UPDATE investments SET approve_status = 'Completed', investment_status = 'Committed'
	WHERE (investment_id = CAST($1 as int)) AND (approve_status = 'Draft') AND investment_status = 'Prospective';

	return msg;
END;
$$ LANGUAGE plpgsql;

  

CREATE TRIGGER ins_inv
  AFTER INSERT OR UPDATE OF monthly_returns
  ON investments
  FOR EACH ROW
  EXECUTE PROCEDURE ins_inv();


CREATE OR REPLACE FUNCTION add_member_meeting(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg		 				varchar(120);
	v_member_id				integer;
	v_org_id				integer;
BEGIN

	SELECT member_id INTO v_member_id
	FROM member_meeting WHERE (member_id = $1::int) AND (meeting_id = $3::int);
	
	IF(v_member_id is null)THEN
		SELECT org_id INTO v_org_id
		FROM meetings WHERE (meeting_id = $3::int);
		
		INSERT INTO  member_meeting (meeting_id, member_id, org_id)
		VALUES ($3::int, $1::int, v_org_id);

		msg := 'Added to meeting';
	ELSE
		msg := 'Already Added to meeting';
	END IF;
	
	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION remove_member_meeting(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg		 				varchar(120);
	v_member_id				integer;
	v_org_id				integer;
BEGIN

	SELECT member_id INTO v_member_id
	FROM member_meeting WHERE (member_id = $1::int) AND (meeting_id = $3::int);
	
	IF(v_member_id is not null)THEN
		SELECT org_id INTO v_org_id
		FROM meetings WHERE (meeting_id = $3::int);
		
		DELETE FROM  member_meeting WHERE member_id = v_member_id AND (meeting_id = $3::int);
		

		msg := 'Removed from meeting';
		END IF;
	
	return msg;
END;
$$ LANGUAGE plpgsql;