/* API - create_firewall_metahost_member
	1) Check privileges
	2) Sanitize Input
	3) Create member (Insertion triggers new rules to be applied and old rules to be deleted)
*/
CREATE OR REPLACE FUNCTION "api"."create_firewall_metahost_member"(input_address inet, input_metahost text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin api.create_firewall_metahost_member');

		-- Sanitize Input
		input_metahost := api.sanitize_general(input_metahost);

		-- Create new member
		PERFORM api.create_log_entry('API','INFO','adding new member to metahost');
		INSERT INTO "firewall"."metahost_members" ("address","name") VALUES (input_address,input_metahost);

		PERFORM api.create_log_entry('API','DEBUG','Finish api.create_firewall_metahost_member');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."create_firewall_metahost_member"(inet, text) IS 'add a member to a metahost. this deletes all previous rules.';

/* API - remove_firewall_metahost_member
	1) Check privileges
	2) Delete member (Deletion triggers metahost rules to be deleted)
*/
CREATE OR REPLACE FUNCTION "api"."remove_firewall_metahost_member"(input_address inet) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin api.remove_firewall_metahost_member');

		-- Remove membership
		PERFORM api.create_log_entry('API','INFO','removing member from metahost');
		DELETE FROM "firewall"."metahost_members" WHERE "address" = input_address;

		PERFORM api.create_log_entry('API','DEBUG','Finish api.remove_firewall_metahost_member');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."remove_firewall_metahost_member"(inet) IS 'remove a member from a metahost. this deletes all previous rules.';

/* API - modify_firewall_default
	1) Check privileges
	2) Alter default action
*/
CREATE OR REPLACE FUNCTION "api"."modify_firewall_default"(input_address inet, input_action boolean) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin api.modify_firewall_default');

		-- Alter default action
		PERFORM api.create_log_entry('API','INFO','altering default action');
		UPDATE "firewall"."defaults" SET "deny" = input_action WHERE "address" = input_address;

		PERFORM api.create_log_entry('API','DEBUG','finish api.modify_firewall_default');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_firewall_default"(inet, boolean) IS 'modify an addresses default firewall action';

/* API - create_metahost
	1) Check privileges
	2) Sanitize input
	3) Create metahost
*/
CREATE OR REPLACE FUNCTION "api"."create_metahost"(input_name text, input_comment text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin api.create_metahost');

		-- Sanitize input
		input_name := api.sanitize_general(input_name);
		input_comment := api.sanitize_general(input_comment);
		
		-- Create metahost
		PERFORM api.create_log_entry('API','INFO','creating new metahost');
		INSERT INTO "firewall"."metahosts" ("name","comment","owner") VALUES 
		(input_name, input_comment, api.get_current_user());
		
		PERFORM api.create_log_entry('API','DEBUG','finish api.create_metahost');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."create_metahost"(text, text) IS 'create a firewall metahost';

/* API - remove_metahost
	1) Check privileges
	2) Sanitize input
	3) Remove metahost
*/
CREATE OR REPLACE FUNCTION "api"."remove_metahost"(input_name text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin api.remove_metahost');

		-- Sanitize input
		input_name := api.sanitize_general(input_name);
		
		-- Create metahost
		PERFORM api.create_log_entry('API','INFO','removing metahost');
		DELETE FROM "firewall"."metahosts" WHERE "name" = input_name;		
		PERFORM api.create_log_entry('API','DEBUG','finish api.remove_metahost');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."remove_metahost"(text) IS 'remove a firewall metahost';

/* API - create_metahost_rule
	1) Check privileges
	2) Sanitize input
	3) Create rule
*/
CREATE OR REPLACE FUNCTION "api"."create_metahost_rule"(input_name text, input_port integer, input_transport text, input_deny boolean, input_comment text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin create_metahost_rule');
		
		-- Sanitize input
		input_name := api.sanitize_general(input_name);
		input_transport := api.sanitize_general(input_transport);
		input_comment := api.sanitize_general(input_comment);
		
		-- Create rule
		PERFORM api.create_log_entry('API','INFO','creating new rule');
		INSERT INTO "firewall"."metahost_rules" ("name","port","transport","deny","comment")
		VALUES (input_name, input_port, input_transport, input_deny, input_comment);
		
		PERFORM api.create_log_entry('API','DEBUG','finish create_metahost_rule');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."create_metahost_rule"(text, integer, text, boolean, text) IS 'Create a firewall metahost rule';

/* API - remove_metahost_rule
	1) Check privileges
	2) Sanitize input
	3) Remove rule
*/
CREATE OR REPLACE FUNCTION "api"."remove_metahost_rule"(input_name text, input_port integer, input_transport text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin remove_metahost_rule');
		
		-- Sanitize input
		input_name := api.sanitize_general(input_name);
		input_transport := api.sanitize_general(input_transport);
		
		-- Remove rule
		PERFORM api.create_log_entry('API','INFO','removing rule');
		DELETE FROM "firewall"."metahost_rules" WHERE "name" = input_name AND "port" = input_port AND "transport" = input_transport;
		
		PERFORM api.create_log_entry('API','DEBUG','finish remove_metahost_rule');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."remove_metahost_rule"(text, integer, text) IS 'Remove a firewall metahost rule';

/* API - create_firewall_system
	1) Check privileges
	2) Sanitize input
	3) Create system
*/
CREATE OR REPLACE FUNCTION "api"."create_firewall_system"(input_name text, input_subnet cidr, input_software text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin create_firewall_system');
		
		-- Sanitize input
		input_name := api.sanitize_general(input_name);
		input_software := api.sanitize_general(input_software);
		
		-- Create system
		PERFORM api.create_log_entry('API','INFO','creating new firewall system');
		INSERT INTO "firewall"."systems" ("system_name","subnet","software_name") VALUES (input_name, input_subnet, input_software);
		
		PERFORM api.create_log_entry('API','DEBUG','finish create_firewall_system');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."create_firewall_system"(text, cidr, text) IS 'Firewall systems are the devices that receive rules for a subnet';

/* API - remove_firewall_system
	1) Check privileges
	2) Sanitize input
	3) Remove system
*/
CREATE OR REPLACE FUNCTION "api"."remove_firewall_system"(input_name text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin remove_firewall_system');
		
		-- Sanitize input
		input_name := api.sanitize_general(input_name);
		
		-- Remove system
		PERFORM api.create_log_entry('API','INFO','removing firewall system');
		DELETE FROM "firewall"."systems" WHERE "system_name" = input_name;
		
		PERFORM api.create_log_entry('API','DEBUG','finish remove_firewall_system');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."remove_firewall_system"(text) IS 'Remove a firewall system';

/* API - create_firewall_rule
	1) Check privileges
	2) Sanitize input
	3) Create rule
*/
CREATE OR REPLACE FUNCTION "api"."create_firewall_rule"(input_address inet, input_port integer, input_transport text, input_deny boolean, input_comment text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin create_firewall_rule');
		
		-- Sanitize input
		input_transport := api.sanitize_general(input_transport);
		input_comment := api.sanitize_general(input_comment);
		
		-- Create rule
		PERFORM api.create_log_entry('API','INFO','creating firewall rule');
		INSERT INTO "firewall"."rules" ("address","port","transport","deny","comment","owner")
		VALUES (input_address, input_port, input_transport, input_deny, input_comment, api.get_current_user());
		
		PERFORM api.create_log_entry('API','DEBUG','finish create_firewall_rule');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."create_firewall_rule"(inet, integer, text, boolean, text) IS 'Create a standalone firewall rule';

/* API - remove_firewall_rule
	1) Check privileges
	2) Sanitize input
	3) Remove rule
*/
CREATE OR REPLACE FUNCTION "api"."remove_firewall_rule"(input_address inet, input_port integer, input_transport text) RETURNS VOID AS $$
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin remove_firewall_rule');
		
		-- Sanitize input
		input_transport := api.sanitize_general(input_transport);
		
		-- Remove rule
		PERFORM api.create_log_entry('API','INFO','removing firewall rule');
		DELETE FROM "firewall"."rules" WHERE "address" = input_address AND "port" = input_port AND "transport" = input_transport;
		
		PERFORM api.create_log_entry('API','DEBUG','finish remove_firewall_rule');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."remove_firewall_rule"(inet, integer, text) IS 'Remove a standalone firewall rule';

/* API - get_firewall_site_default
	1) Get action
*/
CREATE OR REPLACE FUNCTION "api"."get_firewall_site_default"() RETURNS BOOLEAN AS $$
	DECLARE
		Action BOOLEAN;
	BEGIN
		-- Get action
		SELECT bool("value") INTO Action
		FROM "management"."configuration"
		WHERE "option" = 'FW_DEFAULT_ACTION';

		-- Done
		RETURN Action;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_firewall_site_default"() IS 'Return the value of the site firewall default configuration';

/* API - create_firewall_rule_program
	1) Sanitize input
	2) Check privileges
	3) Get program information
	4) Create rule
*/
CREATE OR REPLACE FUNCTION "api"."create_firewall_rule_program"(input_address inet, input_program text, input_deny boolean) RETURNS VOID AS $$
	DECLARE
		Port INTEGER;
		Transport VARCHAR(4);
	BEGIN
		PERFORM api.create_log_entry('API','DEBUG','begin create_firewall_rule_program');

		-- Sanitize input
		input_program := api.sanitize_general(input_program);

		-- Get program information
		SELECT "firewall"."programs"."port","firewall"."programs"."transport" INTO Port,Transport
		FROM "firewall"."programs"
		WHERE "name" = input_program;

		-- Create rule
		PERFORM api.create_log_entry('API','INFO','creating new rule from program');
		INSERT INTO "firewall"."rules"
		("address","port","transport","deny","owner") VALUES
		(input_address,Port,Transport,input_deny,api.get_current_user());
		
		-- Done
		PERFORM api.create_log_entry('API','DEBUG','finish create_firewall_rule_program');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."create_firewall_rule_program"(inet, text, boolean) IS 'Create a firewall rule based on a common program.';

/* API - remove_firewall_rule_program
	1) Sanitize input
	2) Check privileges
	3) Get program information
	4) Remove rule
*/
CREATE OR REPLACE FUNCTION "api"."remove_firewall_rule_program"(input_address inet, input_program text) RETURNS VOID AS $$
	DECLARE
		Port INTEGER;
		Transport VARCHAR(4);
	BEGIN
			PERFORM api.create_log_entry('API','DEBUG','begin remove_firewall_rule_program');

		-- Sanitize input
		input_program := api.sanitize_general(input_program);

		-- Get program information
		SELECT "firewall"."programs"."port","firewall"."programs"."transport" INTO Port,Transport
		FROM "firewall"."programs"
		WHERE "name" = input_program;

		-- Create rule
		PERFORM api.create_log_entry('API','INFO','removing rule based on program');
		DELETE FROM "firewall"."rules"
		WHERE "firewall"."rules"."address" = input_address
		AND "firewall"."rules"."port" = Port
		AND "firewall"."rules"."transport" = Transport;
		
		-- Done
		PERFORM api.create_log_entry('API','DEBUG','finish remove_firewall_rule_program');
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."remove_firewall_rule_program"(inet, text) IS 'Remove a firewall rule based on a common program.';