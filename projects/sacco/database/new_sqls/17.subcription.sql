

ALTER TABLE orgs ADD employee_limit integer default 5 not null;
ALTER TABLE orgs ADD transaction_limit integer default 100 not null;
ALTER TABLE orgs ADD expiry_date date;

CREATE TABLE subscriptions (
	subscription_id			serial primary key,
	industry_id				integer references industry,
	entity_id				integer references entitys,
	account_manager_id		integer references entitys,
	org_id					integer references orgs,

	business_name			varchar(50),
	business_address		varchar(100),
	city					varchar(30),
	state					varchar(50),
	country_id				char(2) references sys_countrys,
	number_of_employees		integer,
	telephone				varchar(50),
	website					varchar(120),
	
	primary_contact			varchar(120),
	job_title				varchar(120),
	primary_email			varchar(120),
	confirm_email			varchar(120),

	system_key				varchar(64),
	subscribed				boolean,
	subscribed_date			timestamp,
	
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	details					text
);
CREATE INDEX subscriptions_industry_id ON subscriptions(industry_id);
CREATE INDEX subscriptions_entity_id ON subscriptions(entity_id);
CREATE INDEX subscriptions_account_manager_id ON subscriptions(account_manager_id);
CREATE INDEX subscriptions_country_id ON subscriptions(country_id);
CREATE INDEX subscriptions_org_id ON subscriptions(org_id);

CREATE TABLE products (
	product_id				serial primary key,
	org_id					integer references orgs,
	product_name			varchar(50),
	is_singular				boolean default true not null,
	align_expiry			boolean default true not null,
	is_montly_bill			boolean default false not null,
	montly_cost				real default 0 not null,
	is_annual_bill			boolean default true not null,
	annual_cost				real default 0 not null,
	
	details					text not null
);
CREATE INDEX products_org_id ON products(org_id);

CREATE TABLE receipt_sources (
	receipt_source_id		serial primary key,
	org_id					integer references orgs,
	receipt_source_name		varchar(50) not null,
	details					text
);
CREATE INDEX receipt_sources_org_id ON receipt_sources(org_id);

CREATE TABLE product_receipts (
	product_receipt_id		serial primary key,
	receipt_source_id		integer references receipt_sources,
	org_id					integer references orgs,
	
	is_paid					boolean default false not null,
	receipt_amount			real not null,
	receipt_date			date not null,
	receipt_time			timestamp default current_timestamp not null,
	receipt_reference		varchar(32),
	narrative				varchar(320)
);
CREATE INDEX product_receipts_receipt_source_id ON product_receipts(receipt_source_id);
CREATE INDEX product_receipts_org_id ON product_receipts(org_id);

CREATE TABLE productions (
	production_id			serial primary key,
	product_id				integer references products,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	
	quantity				integer not null,
	price					real not null,
	transaction_time		timestamp default current_timestamp not null,
	expiry_date				date not null,
	montly_billing			boolean default false not null,
	is_renewed				boolean default false not null,
	auto_renew				boolean default false not null,
	
	details					text
);
CREATE INDEX productions_product_id ON productions(product_id);
CREATE INDEX productions_entity_id ON productions(entity_id);
CREATE INDEX productions_org_id ON productions(org_id);

CREATE VIEW vw_subscriptions AS
	SELECT industry.industry_id, industry.industry_name, sys_countrys.sys_country_id, sys_countrys.sys_country_name,
		entitys.entity_id, entitys.entity_name, 
		account_manager.entity_id as account_manager_id, account_manager.entity_name as account_manager_name,
		orgs.org_id, orgs.org_name, 
		
		subscriptions.subscription_id, subscriptions.business_name, 
		subscriptions.business_address, subscriptions.city, subscriptions.state, subscriptions.country_id, 
		subscriptions.number_of_employees, subscriptions.telephone, subscriptions.website, 
		subscriptions.primary_contact, subscriptions.job_title, subscriptions.primary_email, 
		subscriptions.approve_status, subscriptions.workflow_table_id, subscriptions.application_date, subscriptions.action_date, 
		subscriptions.system_key, subscriptions.subscribed, subscriptions.subscribed_date,
		subscriptions.details
	FROM subscriptions INNER JOIN industry ON subscriptions.industry_id = industry.industry_id
		INNER JOIN sys_countrys ON subscriptions.country_id = sys_countrys.sys_country_id
		LEFT JOIN entitys ON subscriptions.entity_id = entitys.entity_id
		LEFT JOIN entitys as account_manager ON subscriptions.account_manager_id = account_manager.entity_id
		LEFT JOIN orgs ON subscriptions.org_id = orgs.org_id;	
		
CREATE VIEW vw_product_receipts AS
	SELECT orgs.org_id, orgs.org_name, receipt_sources.receipt_source_id, receipt_sources.receipt_source_name, 
		product_receipts.product_receipt_id, product_receipts.is_paid, product_receipts.receipt_amount, 
		product_receipts.receipt_date, product_receipts.receipt_time, product_receipts.receipt_reference, 
		product_receipts.narrative
	FROM product_receipts INNER JOIN orgs ON product_receipts.org_id = orgs.org_id
		INNER JOIN receipt_sources ON product_receipts.receipt_source_id = receipt_sources.receipt_source_id;
		
CREATE VIEW vw_productions AS
	SELECT orgs.org_id, orgs.org_name, products.product_id, products.product_name, 
		products.is_montly_bill, products.montly_cost, products.is_annual_bill, products.annual_cost,
		
		productions.production_id, productions.transaction_time, productions.montly_billing, productions.is_renewed,
		productions.quantity, productions.price, productions.expiry_date, productions.auto_renew,
		productions.details,
		(productions.price * productions.quantity) as amount
	FROM productions INNER JOIN orgs ON productions.org_id = orgs.org_id
		INNER JOIN products ON productions.product_id = products.product_id;
		
CREATE VIEW vws_productions AS
	SELECT orgs.org_id, orgs.org_name, products.product_id, products.product_name, 
		products.is_montly_bill, products.montly_cost, products.is_annual_bill, products.annual_cost,
		products.details,
		productions.is_renewed, productions.expiry_date, 
		
		count(productions.production_id) as count_production,
		sum(productions.quantity) as sum_quantity,
		sum(productions.price * productions.quantity) as amount
		
	FROM productions INNER JOIN orgs ON productions.org_id = orgs.org_id
		INNER JOIN products ON productions.product_id = products.product_id
		
	GROUP BY orgs.org_id, orgs.org_name, products.product_id, products.product_name, 
		products.is_montly_bill, products.montly_cost, products.is_annual_bill, products.annual_cost,
		products.details,
		productions.is_renewed, productions.expiry_date;

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON subscriptions
    FOR EACH ROW EXECUTE PROCEDURE upd_action();
    
CREATE OR REPLACE FUNCTION ins_subscriptions() RETURNS trigger AS $$
DECLARE
	v_entity_id				integer;
	v_org_id				integer;
	v_currency_id			integer;
	v_department_id			integer;
	v_bank_id				integer;
	v_tax_type_id			integer;
	v_workflow_id			integer;
	v_org_suffix			char(2);
	myrec 					RECORD;
BEGIN

	IF (TG_OP = 'INSERT') THEN
		SELECT entity_id INTO v_entity_id
		FROM entitys WHERE lower(trim(user_name)) = lower(trim(NEW.primary_email));

		IF(v_entity_id is null)THEN
			NEW.entity_id := nextval('entitys_entity_id_seq');
			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, User_name, primary_email,  function_role, first_password)
			VALUES (NEW.entity_id, 0, 5, NEW.primary_contact, lower(trim(NEW.primary_email)), lower(trim(NEW.primary_email)), 'subscription', null);
		
			INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name)
			VALUES (4, 0, NEW.entity_id, 'subscription');
		
			NEW.approve_status := 'Completed';
		ELSE
			RAISE EXCEPTION 'You already have an account, login and request for services';
		END IF;
	ELSIF(NEW.approve_status = 'Approved')THEN

		NEW.org_id := nextval('orgs_org_id_seq');
		INSERT INTO orgs(org_id, currency_id, org_name, org_sufix, default_country_id)
		VALUES(NEW.org_id, 2, NEW.business_name, NEW.org_id, NEW.country_id);
		
		INSERT INTO address (address_name, sys_country_id, table_name, table_id, premises, town, phone_number, website, is_default) 
		VALUES (NEW.business_name, NEW.country_id, 'orgs', NEW.org_id, NEW.business_address, NEW.city, NEW.telephone, NEW.website, true);
		
		v_currency_id := nextval('currency_currency_id_seq');
		INSERT INTO currency (org_id, currency_id, currency_name, currency_symbol) VALUES (NEW.org_id, v_currency_id, 'Default Currency', 'DC');
		UPDATE orgs SET currency_id = v_currency_id WHERE org_id = NEW.org_id;
		
		INSERT INTO currency_rates (org_id, currency_id, exchange_rate) VALUES (NEW.org_id, v_currency_id, 1);
		
		INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key)
		SELECT NEW.org_id, entity_type_name, entity_role, use_key
		FROM entity_types WHERE org_id = 1;
		
		INSERT INTO subscription_levels (org_id, subscription_level_name)
		SELECT NEW.org_id, subscription_level_name
		FROM subscription_levels WHERE org_id = 1;
		
		INSERT INTO locations (org_id, location_name) VALUES (NEW.org_id, 'Main office');

		v_department_id := nextval('departments_department_id_seq');
		INSERT INTO Departments (org_id, department_id, department_name) VALUES (NEW.org_id, v_department_id, 'Board of Directors');
		INSERT INTO department_roles (org_id, department_id, department_role_name, active) VALUES (NEW.org_id, v_department_id, 'Board of Directors', true);
		
		v_bank_id := nextval('banks_bank_id_seq');
		INSERT INTO banks (org_id, bank_id, bank_name) VALUES (NEW.org_id, v_bank_id, 'Cash');
		INSERT INTO bank_branch (org_id, bank_id, bank_branch_name) VALUES (NEW.org_id, v_bank_id, 'Cash');
		
		INSERT INTO transaction_counters(transaction_type_id, org_id, document_number)
		SELECT transaction_type_id, NEW.org_id, 1
		FROM transaction_types;
		
		INSERT INTO sys_emails (org_id, use_type,  sys_email_name, title, details) 
		SELECT NEW.org_id, use_type, sys_email_name, title, details
		FROM sys_emails
		WHERE org_id = 1;
		
		INSERT INTO accounts_class (org_id, accounts_class_no, chat_type_id, chat_type_name, accounts_class_name)
		SELECT NEW.org_id, accounts_class_no, chat_type_id, chat_type_name, accounts_class_name
		FROM accounts_class
		WHERE org_id = 1;
		
		INSERT INTO account_types (org_id, accounts_class_id, account_type_no, account_type_name)
		SELECT a.org_id, a.accounts_class_id, b.account_type_no, b.account_type_name
		FROM accounts_class a INNER JOIN vw_account_types b ON a.accounts_class_no = b.accounts_class_no
		WHERE (a.org_id = NEW.org_id) AND (b.org_id = 1);
		
		INSERT INTO accounts (org_id, account_type_id, account_no, account_name)
		SELECT a.org_id, a.account_type_id, b.account_no, b.account_name
		FROM account_types a INNER JOIN vw_accounts b ON a.account_type_no = b.account_type_no
		WHERE (a.org_id = NEW.org_id) AND (b.org_id = 1);
	
		UPDATE entitys SET org_id = NEW.org_id, function_role='subscription,admin,staff,finance'
		WHERE entity_id = NEW.entity_id;

		INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name)
		VALUES (5, NEW.org_id, NEW.entity_id, 'subscription');
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_subscriptions BEFORE INSERT OR UPDATE ON subscriptions
    FOR EACH ROW EXECUTE PROCEDURE ins_subscriptions();

CREATE OR REPLACE FUNCTION ins_productions() RETURNS trigger AS $$
DECLARE
BEGIN

	IF(NEW.product_id = 1)THEN
		UPDATE orgs SET employee_limit = employee_limit + NEW.quantity, expiry_date = NEW.expiry_date
		WHERE org_id = NEW.org_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_productions BEFORE INSERT ON productions
    FOR EACH ROW EXECUTE PROCEDURE ins_productions();

	
CREATE OR REPLACE FUNCTION ins_transactions_limit() RETURNS trigger AS $$
DECLARE
	v_transaction_count	integer;
	v_transaction_limit	integer;
BEGIN

	SELECT count(transaction_id) INTO v_transaction_count
	FROM transactions
	WHERE (org_id = NEW.org_id);
	
	SELECT transaction_limit INTO v_transaction_limit
	FROM orgs
	WHERE (org_id = NEW.org_id);
	
	IF(v_transaction_count > v_transaction_limit)THEN
		RAISE EXCEPTION 'You have reached the maximum transaction limit, request for a quite for more';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_transactions_limit BEFORE INSERT ON transactions
    FOR EACH ROW EXECUTE PROCEDURE ins_transactions_limit();