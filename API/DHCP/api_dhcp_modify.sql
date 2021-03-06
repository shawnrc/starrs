/* api_dhcp_modify.sql
	1) modify_dhcp_class
	2) modify_dhcp_class_option
	3) modify_dhcp_subnet_option
	4) modify_dhcp_global_option
*/

/* API - modify_dhcp_class
	1) Check privileges
	2) Check allowed fields
	3) Validate class name
	4) Update record
*/
CREATE OR REPLACE FUNCTION "api"."modify_dhcp_class"(input_old_class text, input_field text, input_new_value text) RETURNS SETOF "dhcp"."classes" AS $$
	BEGIN
		-- Check privileges		
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			RAISE EXCEPTION 'Permission to modify dhcp class denied for %. Not admin.',api.get_current_user();
		END IF;

		-- Check allowed fields
		IF input_field !~* 'class|comment' THEN
			RAISE EXCEPTION 'Invalid field specified (%)',input_field;
		END IF;

		-- Validate class name
		IF input_field !~* 'class' THEN
			input_new_value := api.validate_nospecial(input_new_value);
		END IF;

		-- Update record
		EXECUTE 'UPDATE "dhcp"."classes" SET ' || quote_ident($2) || ' = $3, 
		date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
		WHERE "class" = $1' 
		USING input_old_class, input_field, input_new_value;	

		-- Done
		PERFORM api.syslog('modify_dhcp_class:"'||input_old_class||'","'||input_field||'","'||input_new_value||'"');
		IF input_field ~* 'class' THEN
			RETURN QUERY (SELECT * FROM "dhcp"."classes" WHERE "class" = input_new_value);
		ELSE
			RETURN QUERY (SELECT * FROM "dhcp"."classes" WHERE "class" = input_old_class);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_dhcp_class"(text, text, text) IS 'Modify a field of a DHCP setting';

/* API - modify_dhcp_class_option
	1) Check privileges
	2) Check allowed fields
	3) Update record
*/
CREATE OR REPLACE FUNCTION "api"."modify_dhcp_class_option"(input_old_class text, input_old_option text, input_old_value text, input_field text, input_new_value text) RETURNS SETOF "dhcp"."class_options" AS $$
	BEGIN
		-- Check privileges		
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			RAISE EXCEPTION 'Permission to modify dhcp class option denied for %. Not admin.',api.get_current_user();
		END IF;

		-- Check allowed fields
		IF input_field !~* 'class|option|value' THEN
			RAISE EXCEPTION 'Invalid field specified (%)',input_field;
		END IF;

		-- Update record
		EXECUTE 'UPDATE "dhcp"."class_options" SET ' || quote_ident($4) || ' = $5, 
		date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
		WHERE "class" = $1 AND "option" = $2 AND "value" = $3' 
		USING input_old_class, input_old_option, input_old_value, input_field, input_new_value;

		-- Done
		PERFORM api.syslog('modify_dhcp_class_option:"'||input_old_class||'","'||input_old_option||'","'||input_old_value||'","'||input_field||'","'||input_new_value||'"');
		IF input_field ~* 'class' THEN
			RETURN QUERY (SELECT * FROM "dhcp"."class_options" 
			WHERE "class" = input_new_value AND "option" = input_old_option AND "value" = input_old_value);
		ELSIF input_field ~* 'option' THEN
			RETURN QUERY (SELECT * FROM "dhcp"."class_options" 
			WHERE "class" = input_old_class AND "option" = input_new_value AND "value" = input_old_value);
		ELSE
			RETURN QUERY (SELECT * FROM "dhcp"."class_options" 
			WHERE "class" = input_old_class AND "option" = input_old_option AND "value" = input_new_value);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_dhcp_class_option"(text, text, text, text, text) IS 'Modify a field of a DHCP class option';

/* API - modify_dhcp_subnet_option
	1) Check privileges
	2) Check allowed fields
	3) Update record
*/
CREATE OR REPLACE FUNCTION "api"."modify_dhcp_subnet_option"(input_old_subnet cidr, input_old_option text, input_old_value text, input_field text, input_new_value text) RETURNS SETOF "dhcp"."subnet_options" AS $$
	BEGIN
		-- Check privileges		
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			RAISE EXCEPTION 'Permission to modify dhcp subnet option denied for %. Not admin.',api.get_current_user();
		END IF;

		-- Check allowed fields
		IF input_field !~* 'subnet|option|value' THEN
			RAISE EXCEPTION 'Invalid field specified (%)',input_field;
		END IF;

		-- Update record
		EXECUTE 'UPDATE "dhcp"."subnet_options" SET ' || quote_ident($4) || ' = $5, 
		date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
		WHERE "subnet" = $1 AND "option" = $2 AND "value" = $3' 
		USING input_old_subnet, input_old_option, input_old_value, input_field, input_new_value;

		-- Done
		PERFORM api.syslog('modify_dhcp_subnet_option:"'||input_old_subnet||'","'||input_old_option||'","'||input_old_value||'","'||input_field||'","'||input_new_value||'"');
		IF input_field ~* 'subnet' THEN
			RETURN QUERY (SELECT * FROM "dhcp"."subnet_options" 
			WHERE "subnet" = input_new_value AND "option" = input_old_option AND "value" = input_old_value);
		ELSIF input_field ~* 'option' THEN
			RETURN QUERY (SELECT * FROM "dhcp"."subnet_options" 
			WHERE "subnet" = input_old_subnet AND "option" = input_new_value AND "value" = input_old_value);
		ELSE
			RETURN QUERY (SELECT * FROM "dhcp"."subnet_options" 
			WHERE "subnet" = input_old_subnet AND "option" = input_old_option AND "value" = input_new_value);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_dhcp_subnet_option"(cidr, text, text, text, text) IS 'Modify a field of a DHCP subnet option';

/* API - modify_dhcp_range_option
	1) Check privileges
	2) Check allowed fields
	3) Check if range is marked for DHCP
	4) Update record
*/
CREATE OR REPLACE FUNCTION "api"."modify_dhcp_range_option"(input_old_range text, input_old_option text, input_old_value text, input_field text, input_new_value text) RETURNS SETOF "dhcp"."range_options" AS $$
	BEGIN
		-- Check privileges		
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			RAISE EXCEPTION 'Permission to modify dhcp range option denied for %. Not admin.',api.get_current_user();
		END IF;

		-- Check allowed fields
		IF input_field !~* 'name|option|value' THEN
			RAISE EXCEPTION 'Invalid field specified (%)',input_field;
		END IF;
		
		-- Check if range is marked for DHCP
		IF input_field ~* 'name' THEN
			IF (SELECT "use" FROM "ip"."ranges" WHERE "name" = input_new_value) !~* 'ROAM' THEN
				RAISE EXCEPTION 'Range % is not marked for DHCP configuration',input_new_value;
			END IF;
		END IF;

		-- Update record
		EXECUTE 'UPDATE "dhcp"."range_options" SET ' || quote_ident($4) || ' = $5, 
		date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
		WHERE "name" = $1 AND "option" = $2 AND "value" = $3' 
		USING input_old_range, input_old_option, input_old_value, input_field, input_new_value;

		-- Done
		PERFORM api.syslog('modify_dhcp_range_option:"'||input_old_range||'","'||input_old_option||'","'||input_old_value||'","'||input_field||'","'||input_new_value||'"');
		IF input_field ~* 'name' THEN
			RETURN QUERY (SELECT * FROM "dhcp"."range_options" 
			WHERE "name" = input_new_value AND "option" = input_old_option AND "value" = input_old_value);
		ELSIF input_field ~* 'option' THEN
			RETURN QUERY (SELECT * FROM "dhcp"."range_options" 
			WHERE "name" = input_old_range AND "option" = input_new_value AND "value" = input_old_value);
		ELSE
			RETURN QUERY (SELECT * FROM "dhcp"."range_options" 
			WHERE "name" = input_old_range AND "option" = input_old_option AND "value" = input_new_value);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_dhcp_range_option"(text, text, text, text, text) IS 'Modify a field of a DHCP range option';

/* API - modify_dhcp_global_option
	1) Check privileges
	2) Check allowed fields
	3) Update record
*/
CREATE OR REPLACE FUNCTION "api"."modify_dhcp_global_option"(input_old_option text, input_old_value text, input_field text, input_new_value text) RETURNS SETOF "dhcp"."global_options" AS $$
	BEGIN
		-- Check privileges		
		IF (api.get_current_user_level() !~* 'ADMIN') THEN
			RAISE EXCEPTION 'Permission to modify dhcp global option denied for %. Not admin.',api.get_current_user();
		END IF;

		-- Check allowed fields
		IF input_field !~* 'option|value' THEN
			RAISE EXCEPTION 'Invalid field specified (%)',input_field;
		END IF;

		-- Update record
		EXECUTE 'UPDATE "dhcp"."global_options" SET ' || quote_ident($3) || ' = $4, 
		date_modified = localtimestamp(0), last_modifier = api.get_current_user() 
		WHERE "option" = $1 AND "value" = $2' 
		USING input_old_option, input_old_value, input_field, input_new_value;

		-- Done
		PERFORM api.syslog('modify_dhcp_global_option:"'||input_old_option||'","'||input_old_value||'","'||input_field||'","'||input_new_value||'"');
		IF input_field ~* 'option' THEN
			RETURN QUERY (SELECT * FROM "dhcp"."global_options" 
			WHERE "option" = input_new_value AND "value" = input_old_value);
		ELSE
			RETURN QUERY (SELECT * FROM "dhcp"."global_options" 
			WHERE "option" = input_old_option AND "value" = input_new_value);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."modify_dhcp_global_option"(text, text, text, text) IS 'Modify a field of a DHCP global option';
