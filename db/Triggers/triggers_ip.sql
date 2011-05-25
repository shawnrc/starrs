/* Trigger subnets_insert 
	1) Check for larger subnets
	2) Check for smaller subnets
	3) Check for existing addresses
	4) Autogenerate addresses
*/
CREATE OR REPLACE FUNCTION "ip"."subnets_insert"() RETURNS TRIGGER AS $$
	DECLARE
		RowCount INTEGER;
	BEGIN
		-- Check for larger subnets
		SELECT COUNT(*) INTO RowCount
		FROM "ip"."subnets"
		WHERE NEW."subnet" << "ip"."subnets"."subnet";
		IF (RowCount > 0) THEN
			RAISE EXCEPTION 'A larger existing subnet was detected. Nested subnets are not supported.';
		END IF;

		-- Check for smaller subnets
		SELECT COUNT(*) INTO RowCount
		FROM "ip"."subnets"
		WHERE NEW."subnet" >> "ip"."subnets"."subnet";
		IF (RowCount > 0) THEN
			RAISE EXCEPTION 'A smaller existing subnet was detected. Nested subnets are not supported.';
		END IF;
		
		-- Check for existing addresses
		SELECT COUNT(*) INTO RowCount
		FROM "ip"."addresses"
		WHERE "ip"."addresses"."address" << NEW."subnet";
		IF RowCount >= 1 THEN
			RAISE EXCEPTION 'Existing addresses detected for your subnet. Modify the existing subnet.';
		END IF;

		-- Autogenerate addresses
		IF NEW."autogen" IS TRUE THEN
			INSERT INTO "ip"."addresses" ("address","last_modifier") SELECT "get_subnet_addresses",api.get_current_user() FROM api.get_subnet_addresses(NEW."subnet");
		END IF;
		
		-- Done
		RETURN NEW;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "ip"."subnets_insert"() IS 'Create a subnet';

/* Trigger - subnets_update 
	1) Check for larger subnets
	2) Check for smaller subnets
	3) Check for existing addresses
	4) Autogenerate addresses
*/
CREATE OR REPLACE FUNCTION "ip"."subnets_update"() RETURNS TRIGGER AS $$
	DECLARE
		RowCount INTEGER;
	BEGIN
		IF NEW."subnet" != OLD."subnet" THEN
			-- Check for larger subnets
			SELECT COUNT(*) INTO RowCount
			FROM "ip"."subnets"
			WHERE NEW."subnet" << "ip"."subnets"."subnet";
			IF (RowCount > 0) THEN
				RAISE EXCEPTION 'A larger existing subnet was detected. Nested subnets are not supported.';
			END IF;

			-- Check for smaller subnets
			SELECT COUNT(*) INTO RowCount
			FROM "ip"."subnets"
			WHERE NEW."subnet" >> "ip"."subnets"."subnet";
			IF (RowCount > 0) THEN
				RAISE EXCEPTION 'A smaller existing subnet was detected. Nested subnets are not supported.';
			END IF;
			
			-- Check for existing addresses
			SELECT COUNT(*) INTO RowCount
			FROM "ip"."addresses"
			WHERE "ip"."addresses"."address" << NEW."subnet";
			IF RowCount >= 1 THEN
				RAISE EXCEPTION 'Existing addresses detected for your subnet. Modify the existing subnet.';
			END IF;
		END IF;

		-- Autogenerate addresses
		IF NEW."autogen" != OLD."autogen" THEN
			IF NEW."autogen" IS TRUE THEN
				DELETE FROM "ip"."addresses" WHERE "ip"."addresses"."address" << OLD."subnet";
				INSERT INTO "ip"."addresses" ("address") SELECT * FROM ip_address_autopopulation(NEW."subnet");
			END IF;
		END IF;
		
		-- Done
		RETURN NEW;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "ip"."subnets_update"() IS 'Modify an existing new subnet';

/* Trigger - subnets_delete 
	1) Check for inuse addresses
	2) Delete autogenerated addresses
*/
CREATE OR REPLACE FUNCTION "ip"."subnets_delete"() RETURNS TRIGGER AS $$
	DECLARE
		RowCount INTEGER;
	BEGIN
		-- Check for inuse addresses
		SELECT COUNT(*) INTO RowCount
		FROM "ip"."addresses"
		WHERE EXISTS (
			SELECT "address" 
			FROM "systems"."interface_addresses" 
			WHERE "systems"."interface_addresses"."address" = "ip"."addresses"."address" )
		AND "ip"."addresses"."address" << OLD."subnet";
		IF (RowCount >= 1) THEN
			RAISE EXCEPTION 'Inuse addresses found. Aborting delete.';
		ELSE

		-- Delete autogenerated addresses
		IF OLD."autogen" = TRUE THEN
			DELETE FROM "ip"."addresses" WHERE "address" << OLD."subnet";
		END IF;

		-- Done
		RETURN OLD;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "ip"."subnets_delete"() IS 'You can only delete a subnet if no addresses from it are inuse.';

/* Trigger - addresses_insert 
	1) Check for existing default action (should never happen)
	2) Create action
*/
CREATE OR REPLACE FUNCTION "ip"."addresses_insert"() RETURNS TRIGGER AS $$
	DECLARE
		RowCount INTEGER;
	BEGIN
		-- Check for existing default action
		SELECT COUNT(*) INTO RowCount
		FROM "firewall"."defaults"
		WHERE "firewall"."defaults"."address" = NEW."address";
		
		-- Create action
		IF (RowCount >= 1) THEN
			RAISE EXCEPTION 'Address % is already has a firewall default action?',NEW."address";
		ELSIF (RowCount = 0) THEN
			-- Insert the new address record, then the firewall. (Foreign keys)
			RETURN NEW;
			INSERT INTO "firewall"."defaults" ("address", "deny", "last_modifier") VALUES (NEW."address", DEFAULT, NEW."last_modifier");
		ELSE
			RAISE EXCEPTION 'Could not activate firewall address %',NEW."address";
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "ip"."addresses_insert"() IS 'Activate a new IP address in the application';

/* Trigger - ranges_insert 
	1) Check for illegal addresses
	2) Check address vs subnet
	3) Check valid range
	4) Check address existance
	5) Define lower boundary for range
	6) Define upper boundry for range
	7) Check for range spanning
*/
CREATE OR REPLACE FUNCTION "ip"."ranges_insert"() RETURNS TRIGGER AS $$
	DECLARE
		LowerBound INET;
		UpperBound INET;
		result RECORD;
		RowCount INTEGER;
	BEGIN
		-- Check for illegal addresses
		IF host(input_subnet) = host(input_first_ip) THEN
			RAISE EXCEPTION 'You cannot have a boundry that is the network identifier';
		END IF;
		
		-- Check address vs subnet
		IF NOT input_first_ip << input_subnet OR NOT input_last_ip << input_subnet THEN
			RAISE EXCEPTION 'Range addresses must be inside the specified subnet';
		END IF;

		-- Check valid range
		IF input_first_ip >= input_last_ip THEN
			RAISE EXCEPTION 'First address is larger or equal to last address.';
		END IF;
		
		-- Check address existance
		SELECT COUNT(*) INTO RowCount
		FROM "ip"."addresses"
		WHERE "ip"."addresses"."address" = input_first_ip;
		IF (RowCount != 1) THEN
			RAISE EXCEPTION 'First address (%) not found in address pool.',input_first_ip;
		END IF;
		
		SELECT COUNT(*) INTO RowCount
		FROM "ip"."addresses"
		WHERE "ip"."addresses"."address" = input_last_ip;
		IF (RowCount != 1) THEN
			RAISE EXCEPTION 'Last address (%) not found in address pool.',input_last_ip;
		END IF;

		-- Define lower boundary for range
		-- Loop through all ranges and find what is near the new range
		FOR result IN SELECT "first_ip","last_ip" FROM "ip"."ranges" WHERE "subnet" = input_subnet LOOP
			IF input_first_ip >= result.first_ip AND input_first_ip <= result.last_ip THEN
				RAISE EXCEPTION 'First address out of bounds.';
			ELSIF input_first_ip > result.last_ip THEN
				LowerBound := result.last_ip;
			END IF;
			IF input_last_ip >= result.first_ip AND input_last_ip <= result.last_ip THEN
				RAISE EXCEPTION 'Last address is out of bounds';
			END IF;
		END LOOP;

		-- Define upper boundry for range
		SELECT "first_ip" INTO UpperBound
		FROM "ip"."ranges"
		WHERE "first_ip" >= LowerBound
		ORDER BY "first_ip" LIMIT 1;

		-- Check for range spanning
		IF input_last_ip >= UpperBound THEN
			RAISE EXCEPTION 'Last address is out of bounds';
		END IF;

		-- Done
		RETURN NEW;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "ip"."ranges_insert"() IS 'Insert a new range of addresses for use';

/* Trigger - ranges_update
	1) Check for illegal addresses
	2) Check address vs subnet
	3) Check valid range
	4) Check address existance
	5) Define lower boundary for range
	6) Define upper boundry for range
	7) Check for range spanning
*/
CREATE OR REPLACE FUNCTION "ip"."ranges_update"() RETURNS TRIGGER AS $$
	DECLARE
		LowerBound	INET;
		UpperBound	INET;
		result		RECORD;
		RowCount	INTEGER;
	BEGIN
		IF NEW."first_ip" != OLD."first_ip" OR NEW."last_ip" != OLD."last_ip" THEN
			-- Check for illegal addresses
			IF host(input_subnet) = host(input_first_ip) THEN
				RAISE EXCEPTION 'You cannot have a boundry that is the network identifier';
			END IF;
			
			-- Check address vs subnet
			IF NOT input_first_ip << input_subnet OR NOT input_last_ip << input_subnet THEN
				RAISE EXCEPTION 'Range addresses must be inside the specified subnet';
			END IF;

			-- Check valid range
			IF input_first_ip >= input_last_ip THEN
				RAISE EXCEPTION 'First address is larger or equal to last address.';
			END IF;
			
			-- Check address existance
			SELECT COUNT(*) INTO RowCount
			FROM "ip"."addresses"
			WHERE "ip"."addresses"."address" = input_first_ip;
			IF (RowCount != 1) THEN
				RAISE EXCEPTION 'First address (%) not found in address pool.',input_first_ip;
			END IF;
			
			SELECT COUNT(*) INTO RowCount
			FROM "ip"."addresses"
			WHERE "ip"."addresses"."address" = input_last_ip;
			IF (RowCount != 1) THEN
				RAISE EXCEPTION 'Last address (%) not found in address pool.',input_last_ip;
			END IF;

			-- Define lower boundary for range
			-- Loop through all ranges and find what is near the new range
			FOR result IN SELECT "first_ip","last_ip" FROM "ip"."ranges" WHERE "subnet" = input_subnet LOOP
				IF input_first_ip >= result.first_ip AND input_first_ip <= result.last_ip THEN
					RAISE EXCEPTION 'First address out of bounds.';
				ELSIF input_first_ip > result.last_ip THEN
					LowerBound := result.last_ip;
				END IF;
				IF input_last_ip >= result.first_ip AND input_last_ip <= result.last_ip THEN
					RAISE EXCEPTION 'Last address is out of bounds';
				END IF;
			END LOOP;

			-- Define upper boundry for range
			SELECT "first_ip" INTO UpperBound
			FROM "ip"."ranges"
			WHERE "first_ip" >= LowerBound
			ORDER BY "first_ip" LIMIT 1;

			-- Check for range spanning
			IF input_last_ip >= UpperBound THEN
				RAISE EXCEPTION 'Last address is out of bounds';
			END IF;
		END IF;
		-- Done
		RETURN NEW;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "ip"."ranges_update"() IS 'Alter a range of addresses for use';