/* API - modify_system
	1) Check privileges
	2) Check allowed fields
	3) Update record
*/
CREATE OR REPLACE FUNCTION "api"."modify_system"(input_old_name text, input_field text, input_new_value text) RETURNS SETOF "systems"."systems" AS $$
	BEGIN
		PERFORM api.create_log_entry('API', 'DEBUG', 'Begin api.modify_system');

		-- Check privileges
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			IF (SELECT "owner" FROM "systems"."systems" WHERE "system_name" = input_old_name) != api.get_current_user() THEN
				PERFORM api.create_log_entry('API','ERROR','Permission denied');
				RAISE EXCEPTION 'Permission to edit system % denied. You are not owner',input_old_name;
			END IF;

			IF input_field ~* 'owner' AND input_new_value != api.get_current_user() THEN
				PERFORM api.create_log_entry('API','ERROR','Permission denied - wrong owner');
				RAISE EXCEPTION 'Only administrators can define a different owner (%).',input_new_value;
			END IF;
 		END IF;

		-- Check allowed fields
		IF input_field !~* 'system_name|owner|comment|type|os_name|platform_name|asset|group|datacenter' THEN
			PERFORM api.create_log_entry('API','ERROR','Invalid field');
			RAISE EXCEPTION 'Invalid field % specified',input_field;
		END IF;

		-- Update record
		PERFORM api.create_log_entry('API','INFO','update system');

		EXECUTE 'UPDATE "systems"."systems" SET ' || quote_ident($2) || ' = $3, 
		date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
		WHERE "system_name" = $1' 
		USING input_old_name, input_field, input_new_value;

		-- Done
		PERFORM api.create_log_entry('API', 'DEBUG', 'finish api.modify_system');
		IF input_field ~* 'system_name' THEN
			RETURN QUERY (SELECT * FROM "systems"."systems" WHERE "system_name" = input_new_value);
		ELSE
			RETURN QUERY (SELECT * FROM "systems"."systems" WHERE "system_name" = input_old_name);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_system"(text,text,text) IS 'Modify an existing system';

/* API - modify_interface
	1) Check privileges
	2) Check allowed fields
	3) Update record
*/
CREATE OR REPLACE FUNCTION "api"."modify_interface"(input_old_mac macaddr, input_field text, input_new_value text) RETURNS SETOF "systems"."interfaces" AS $$
	BEGIN
		PERFORM api.create_log_entry('API', 'DEBUG', 'Begin api.modify_interface');

		-- Check privileges
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			IF (SELECT "owner" FROM "systems"."interfaces" 
			JOIN "systems"."systems" ON "systems"."systems"."system_name" = "systems"."interfaces"."system_name"
			WHERE "mac" = input_old_mac) != api.get_current_user() THEN
				PERFORM api.create_log_entry('API','ERROR','Permission denied');
				RAISE EXCEPTION 'Permission to edit interface % denied. You are not owner',input_old_mac;
			END IF;
 		END IF;

		-- Check allowed fields
		IF input_field !~* 'mac|comment|system_name|name' THEN
			PERFORM api.create_log_entry('API','ERROR','Invalid field');
			RAISE EXCEPTION 'Invalid field % specified',input_field;
		END IF;

		-- Update record
		PERFORM api.create_log_entry('API','INFO','update interface');

		IF input_field ~* 'mac' THEN
			EXECUTE 'UPDATE "systems"."interfaces" SET ' || quote_ident($2) || ' = $3, 
			date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
			WHERE "mac" = $1' 
			USING input_old_mac, input_field, macaddr(input_new_value);
		ELSE
			EXECUTE 'UPDATE "systems"."interfaces" SET ' || quote_ident($2) || ' = $3, 
			date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
			WHERE "mac" = $1' 
			USING input_old_mac, input_field, input_new_value;
		END IF;

		-- Done
		PERFORM api.create_log_entry('API', 'DEBUG', 'finish api.modify_interface');
		IF input_field ~* 'mac' THEN
			RETURN QUERY (SELECT * FROM "systems"."interfaces" WHERE "mac" = macaddr(input_new_value));
		ELSE
			RETURN QUERY (SELECT * FROM "systems"."interfaces" WHERE "mac" = input_old_mac);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_interface"(macaddr,text,text) IS 'Modify an existing system interface';

/* API - modify_interface_address
	1) Check privileges
	2) Check allowed fields
	3) Update record
*/
CREATE OR REPLACE FUNCTION "api"."modify_interface_address"(input_old_address inet, input_field text, input_new_value text) RETURNS SETOF "systems"."interface_addresses" AS $$
	DECLARE
		isprim BOOLEAN;
		primcount INTEGER;
	BEGIN
		PERFORM api.create_log_entry('API', 'DEBUG', 'Begin api.modify_interface_address');

		-- Check privileges
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			IF api.get_interface_address_owner(input_old_address) != api.get_current_user() THEN
				PERFORM api.create_log_entry('API','ERROR','Permission denied');
				RAISE EXCEPTION 'Permission to edit address % denied. You are not owner of the system',input_old_address;
			END IF;
 		END IF;

		-- Check allowed fields
		IF input_field !~* 'comment|address|config|isprimary|mac|class' THEN
			PERFORM api.create_log_entry('API','ERROR','Invalid field');
			RAISE EXCEPTION 'Invalid field % specified',input_field;
		END IF;
		
		-- Check dynamic
		IF api.ip_is_dynamic(input_old_address) IS TRUE THEN
			IF input_field ~* 'config|class' THEN
				PERFORM api.create_log_entry('API','ERROR','Cannot modify the configuration or class of a dynamic address');
				RAISE EXCEPTION 'Cannot modify the configuration or class of a dynamic address';
			END IF;
		END IF;

		-- Check for primary
		SELECT "isprimary" INTO isprim FROM "systems"."interface_addresses" WHERE "address" = input_old_address;

		IF input_field ~* 'mac' THEN
			SELECT COUNT(*) INTO primcount FROM "systems"."interface_addresses" WHERE "mac" = input_new_value::macaddr AND "isprimary" IS TRUE;
			IF primcount = 0 THEN
				isprim := TRUE;
			ELSE
				isprim := FALSE;
			END IF;
		END IF;

		IF input_field ~* 'address' THEN
			IF (SELECT "use" FROM "api"."get_ip_range"((SELECT "api"."get_address_range"(input_new_value::inet)))) ~* 'ROAM' THEN
				PERFORM api.create_log_entry('API','ERROR','Specified new address is contained within Dynamic range');
				RAISE EXCEPTION 'Specified new address (%) is contained within a Dynamic range',input_new_value;
			END IF;
		END IF;

		-- Update record
		PERFORM api.create_log_entry('API','INFO','update interface address');

		IF input_field ~* 'mac' THEN
			EXECUTE 'UPDATE "systems"."interface_addresses" SET ' || quote_ident($2) || ' = $3, 
			date_modified = localtimestamp(0), last_modifier = api.get_current_user(), isprimary = $4 
			WHERE "address" = $1' 
			USING input_old_address, input_field, macaddr(input_new_value),isprim;
		ELSIF input_field ~* 'address' THEN
			EXECUTE 'UPDATE "systems"."interface_addresses" SET ' || quote_ident($2) || ' = $3, 
			date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
			WHERE "address" = $1' 
			USING input_old_address, input_field, inet(input_new_value);
		ELSIF input_field ~* 'isprimary' THEN
			EXECUTE 'UPDATE "systems"."interface_addresses" SET ' || quote_ident($2) || ' = $3, 
			date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
			WHERE "address" = $1' 
			USING input_old_address, input_field, bool(input_new_value);
		ELSEIF input_field ~* 'config' THEN
			EXECUTE 'UPDATE "systems"."interface_addresses" SET ' || quote_ident($2) || ' = $3, 
			date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
			WHERE "address" = $1' 
			USING input_old_address, input_field, input_new_value;
			-- Need to force DNS records to be created
			IF input_new_value ~* 'static' THEN
				UPDATE "dns"."a" SET "address" = input_old_address WHERE "address" = input_old_address;
			END IF;
		ELSE
			EXECUTE 'UPDATE "systems"."interface_addresses" SET ' || quote_ident($2) || ' = $3, 
			date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
			WHERE "address" = $1' 
			USING input_old_address, input_field, input_new_value;
		END IF;
		
		-- Done
		PERFORM api.create_log_entry('API', 'DEBUG', 'finish api.modify_interface_address');
		IF input_field ~* 'address' THEN
			RETURN QUERY (SELECT * FROM "systems"."interface_addresses" WHERE "address" = inet(input_new_value));
		ELSE
			RETURN QUERY (SELECT * FROM "systems"."interface_addresses" WHERE "address" = input_old_address);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_interface_address"(inet,text,text) IS 'Modify an existing interface address';

CREATE OR REPLACE FUNCTION "api"."modify_datacenter"(input_old_name text, input_field text, input_new_value text) RETURNS SETOF "systems"."datacenters" AS $$
	BEGIN
		PERFORM api.create_log_entry('API', 'DEBUG', 'Begin api.modify_datacenter');

		-- Check privileges
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			PERFORM api.create_log_entry('API','ERROR','Permission denied');
			RAISE EXCEPTION 'Permission to edit address % denied. You are not admin';
 		END IF;

		-- Check allowed fields
		IF input_field !~* 'datacenter|comment' THEN
			PERFORM api.create_log_entry('API','ERROR','Invalid field');
			RAISE EXCEPTION 'Invalid field % specified',input_field;
		END IF;
		
		-- Update record
		PERFORM api.create_log_entry('API','INFO','update interface address');

		EXECUTE 'UPDATE "systems"."datacenters" SET ' || quote_ident($2) || ' = $3, 
		date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
		WHERE "datacenter" = $1' 
		USING input_old_name, input_field, input_new_value;

		-- Done
		PERFORM api.create_log_entry('API', 'DEBUG', 'finish api.modify_datacenter');

		IF input_field ~* 'datacenter' THEN
			RETURN QUERY (SELECT * FROM "systems"."datacenters" WHERE "datacenter" = input_new_value);
		ELSE
			RETURN QUERY (SELECT * FROM "systems"."datacenters" WHERE "datacenter" = input_old_name);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_datacenter"(text, text, text) IS 'modify a datacenter';


CREATE OR REPLACE FUNCTION "api"."modify_availability_zone"(input_old_datacenter text, input_old_zone text, input_field text, input_new_value text) RETURNS SETOF "systems"."availability_zones" AS $$
	BEGIN
		PERFORM api.create_log_entry('API', 'DEBUG', 'Begin api.modify_availability_zone');

		-- Check privileges
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			PERFORM api.create_log_entry('API','ERROR','Permission denied');
			RAISE EXCEPTION 'Permission to edit availability zone denied. You are not admin';
 		END IF;

		-- Check allowed fields
		IF input_field !~* 'datacenter|zone|comment' THEN
			PERFORM api.create_log_entry('API','ERROR','Invalid field');
			RAISE EXCEPTION 'Invalid field % specified',input_field;
		END IF;
		
		-- Update record
		PERFORM api.create_log_entry('API','INFO','update availability zone');

		EXECUTE 'UPDATE "systems"."availability_zones" SET ' || quote_ident($3) || ' = $4, 
		date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
		WHERE "datacenter" = $1 AND "zone" = $2' 
		USING input_old_datacenter, input_old_zone, input_field, input_new_value;

		-- Done
		PERFORM api.create_log_entry('API', 'DEBUG', 'finish api.modify_availability_zone');

		IF input_field ~* 'zone' THEN
			RETURN QUERY (SELECT * FROM "systems"."availability_zones" WHERE "datacenter" = input_old_datacenter AND "zone" = input_new_value);
		ELSEIF input_field ~* 'datacenter' THEN
			RETURN QUERY (SELECT * FROM "systems"."availability_zones" WHERE "datacenter" = input_new_value AND "zone" = input_old_zone);
		ELSE
			RETURN QUERY (SELECT * FROM "systems"."availability_zones" WHERE "datacenter" = input_old_datacenter AND "zone" = input_old_zone);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_availability_zone"(text, text, text, text) IS 'modify a availability_zone';
