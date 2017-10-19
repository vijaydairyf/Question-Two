ALTER TABLE sys_menu_msg ALTER COLUMN menu_id TYPE varchar(16);
ALTER TABLE sys_menu_msg ADD COLUMN xml_file character varying(50);
INSERT INTO sys_menu_msg(menu_id, menu_name, msg, xml_file)
    VALUES ('82:0','policy number','<span>Click on policy number to access certificate& letter to embassy</span>','travelportapps.xml');


CREATE OR REPLACE VIEW vw_passengers AS
  SELECT vw_entitys.org_id,  vw_entitys.org_name, vw_rates.rate_type_id, vw_rates.rate_plan_id, vw_rates.rate_category_name,
  vw_rates.rate_id, vw_rates.rate_plan_name, vw_rates.standard_rate, vw_rates.north_america_rate,
   passengers.days_from,  passengers.days_to,  passengers.corporate_rate_id,
   passengers.approved,  passengers.entity_id,
  passengers.countries,  passengers.passenger_id,  passengers.passenger_name,  passengers.passenger_mobile,
  passengers.passenger_email,  passengers.passenger_age,  passengers.days_covered,  passengers.nok_name,
  passengers.nok_mobile,  passengers.passenger_id_no,  passengers.nok_national_id,  passengers.cover_amount,
  passengers.totalAmount_covered,  passengers.is_north_america,  passengers.details,  passengers.passenger_dob,
  passengers.policy_number,  vw_entitys.entity_name,  passengers.destown,  sys_countrys.sys_country_name,
  passengers.approved_date,  passengers.corporate_id,  passengers.pin_no, passengers.reason_for_travel,
  passengers.departure_country, vw_entitys.entity_role, vw_entitys.function_role, vw_entitys.is_active,passengers.physical_address,
  passengers.is_valid,passengers.is_individual, portal.portal_id,portal.portal_name,passengers.id_no,passengers.relationship,passengers.status,passengers.kesamount,vw_entitys.user_name
  FROM passengers
   JOIN vw_rates ON passengers.rate_id = vw_rates.rate_id
   JOIN vw_entitys ON passengers.entity_id = vw_entitys.entity_id
   JOIN portal ON portal.portal_id = passengers.portal_id
   JOIN sys_countrys ON passengers.sys_country_id = sys_countrys.sys_country_id;


CREATE OR REPLACE VIEW vw_policy_members AS
SELECT
  p.policy_member_id, p.passenger_id, p.org_id, p.entity_id, p.member_name, p.passport_number, p.pin_number,
  p.phone_number,  p.primary_email, p.rate_id, p.amount_covered, p.totalamount_covered, p.age,
  p.passenger_dob, a.countries,a.policy_number, a.destown, a.sys_country_name, a.reason_for_travel,
  a.departure_country, a.entity_name, a.days_from, a.days_to,
  a.rate_type_id, a.approved_date, a.rate_plan_id, a.rate_category_name,a.approved,
  a.rate_plan_name, a.standard_rate, a.north_america_rate,a.org_name,a.function_role,a.entity_role,a.is_active,
  a.is_valid, a.is_individual, a.portal_id, a.portal_name,p.kesamount
  FROM  policy_members p
  JOIN vw_passengers a ON p.passenger_id = a.passenger_id ;

  CREATE OR REPLACE VIEW vw_allpassengers AS
  SELECT a.org_id,  a.org_name, a.rate_type_id,a.rate_plan_id, a.rate_category_name,
  a.rate_id,a.rate_plan_name, a.standard_rate, a.north_america_rate,a.days_from,  a.days_to,  a.corporate_rate_id,
  a.approved, a.entity_id, a.countries, a.passenger_id,  a.passenger_name,  a.passenger_mobile,
  a.passenger_email,  a.passenger_age,  a.days_covered,  a.nok_name, a.nok_mobile,  a.passenger_id_no,
  a.passport_number,  round(a.cover_amount::DECIMAL,2)::real as cover_amount,  round(a.totalAmount_covered::DECIMAL,2)::real as totalAmount_covered,  a.is_north_america,  a.details,  a.passenger_dob,
  a.policy_number,  a.entity_name,  a.destown,  a.sys_country_name, a.approved_date,  a.corporate_id,
  a.pin_no, a.reason_for_travel,  a.departure_country, a.entity_role, a.function_role, a.is_active,a.is_valid,a.is_individual,
  a.portal_id,a.portal_name,  a.id_no, a.relationship,a.kesamount
  FROM ((
  SELECT org_id,org_name,rate_type_id, rate_plan_id, rate_category_name,rate_id, rate_plan_name, standard_rate, north_america_rate,
      days_from,  days_to,  corporate_rate_id,   approved,  entity_id,  countries,  passenger_id,  passenger_name,  passenger_mobile,
      passenger_email,  passenger_age,  days_covered,  nok_name,  nok_mobile,  passenger_id_no,  nok_national_id as passport_number,  cover_amount,
      totalAmount_covered,  is_north_america,  details,  passenger_dob,  policy_number,  entity_name,  destown,  sys_country_name,
      approved_date,  corporate_id,  pin_no, reason_for_travel,  departure_country, entity_role, function_role, is_active,is_valid,is_individual,
      portal_id, portal_name,id_no,relationship,kesamount
  FROM vw_passengers  )
  UNION ALL
  (SELECT org_id,org_name, rate_type_id,  rate_plan_id,  rate_category_name, rate_id,    rate_plan_name,  standard_rate,
      north_america_rate, days_from,days_to,   null::integer as corporate_rate_id,  approved,  entity_id,
      countries,passenger_id, member_name as passenger_name,  phone_number as passenger_mobile,
      primary_email as passenger_email , age as  passenger_age,    null::integer as days_covered, ''::text as nok_name,
      ''::text as nok_mobile,  ''::text as passenger_id_no, passport_number, amount_covered as cover_amount,
      totalamount_covered,  null::boolean as is_north_america, ''::text as details, passenger_dob::text,policy_number,
      entity_name, destown, sys_country_name, approved_date, null::integer as corporate_id, pin_number as pin_no,
      reason_for_travel,     departure_country,   entity_role, function_role ,
      is_active,  is_valid,is_individual,portal_id, portal_name, ''::text as id_no,''::text as relationship,kesamount
  FROM  vw_policy_members )
  )a order by passenger_id DESC;

  DROP view vw_pesapal_trans;


  CREATE OR REPLACE VIEW vw_pesapal_trans AS
   SELECT pesapal_trans.pesapal_trans_id, pesapal_trans.merchant_orderid, pesapal_trans.pesapal_transaction_tracking_id,
       pesapal_trans.status, pesapal_trans.jp_timestamp, pesapal_trans.details,
       vw_allpassengers.kesamount,  vw_allpassengers.passenger_name,pesapal_trans.trans_method
     FROM pesapal_trans
       JOIN vw_allpassengers ON pesapal_trans.merchant_orderid = vw_allpassengers.passenger_id;
