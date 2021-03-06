/* API - get_system_types
	1) Return all available system types
*/
CREATE OR REPLACE FUNCTION "api"."get_system_types"() RETURNS SETOF "systems"."device_types" AS $$
	BEGIN
		RETURN QUERY (SELECT * FROM "systems"."device_types" ORDER BY "type");
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_system_types"() IS 'Get a list of all available system types';

/* API - get_operating_systems
	1) Return all available operating systems
*/
CREATE OR REPLACE FUNCTION "api"."get_operating_systems"() RETURNS SETOF TEXT AS $$
	BEGIN
		RETURN QUERY (SELECT "name" FROM "systems"."os" ORDER BY "name" ASC);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_operating_systems"() IS 'Get a list of all available system types';

/* API - get_system_owner */
CREATE OR REPLACE FUNCTION "api"."get_system_owner"(input_system text) RETURNS TEXT AS $$
	BEGIN
		RETURN (SELECT "owner" FROM "systems"."systems" WHERE "system_name" = input_system);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_system_owner"(text) IS 'Easily get the owner of a system';

/* API - get_interface_address_owner */
CREATE OR REPLACE FUNCTION "api"."get_interface_address_owner"(input_address inet) RETURNS TEXT AS $$
	BEGIN
		RETURN (SELECT "owner" FROM "systems"."interface_addresses"
		JOIN "systems"."interfaces" ON "systems"."interface_addresses"."mac" = "systems"."interfaces"."mac"
		JOIN "systems"."systems" ON "systems"."systems"."system_name" = "systems"."interfaces"."system_name"
		WHERE "address" = input_address);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_interface_address_owner"(inet) IS 'Get the owner of an existing interface address';

/* API - get_system_interface_addresses */
CREATE OR REPLACE FUNCTION "api"."get_system_interface_addresses"(input_mac macaddr) RETURNS SETOF "systems"."interface_addresses" AS $$
	BEGIN
		IF input_mac IS NULL THEN
			RETURN QUERY (SELECT * FROM "systems"."interface_addresses" ORDER BY family(address),address);
		ELSE
			RETURN QUERY (SELECT * FROM "systems"."interface_addresses" WHERE "mac" = input_mac ORDER BY family(address),address ASC);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_system_interface_addresses"(macaddr) IS 'Get all interface addresses on a specified MAC';

/* API - get_system_interfaces */
CREATE OR REPLACE FUNCTION "api"."get_system_interfaces"(input_system_name text) RETURNS SETOF "systems"."interfaces" AS $$
	BEGIN
		IF input_system_name IS NULL THEN
			RETURN QUERY (SELECT * FROM "systems"."interfaces" ORDER BY mac);
		ELSE
			RETURN QUERY (SELECT * FROM "systems"."interfaces" WHERE "system_name" = input_system_name  ORDER BY mac);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_system_interfaces"(text) IS 'Get all interface information on a system';

/* API - get_system_interface_data */
CREATE OR REPLACE FUNCTION "api"."get_system_interface_data"(input_mac macaddr) RETURNS SETOF "systems"."interfaces" AS $$
	BEGIN
		RETURN QUERY (SELECT * FROM "systems"."interfaces" WHERE "mac" = input_mac);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_system_interface_data"(macaddr) IS 'Get all interface information on a system for a specific interface';

/* API - get_system_data */
CREATE OR REPLACE FUNCTION "api"."get_system"(input_system_name text) RETURNS SETOF "systems"."systems" AS $$
	BEGIN
		RETURN QUERY (SELECT * FROM "systems"."systems" WHERE "system_name" = input_system_name);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_system"(text) IS 'Get a single system';

/* API - get_systems */
CREATE OR REPLACE FUNCTION "api"."get_systems"(input_username text) RETURNS SETOF "systems"."systems" AS $$
	BEGIN
		IF input_username IS NULL THEN
			RETURN QUERY (SELECT * FROM "systems"."systems" ORDER BY lower("system_name") ASC);
		ELSE
			RETURN QUERY (SELECT * FROM "systems"."systems" WHERE "owner" = input_username  ORDER BY lower("system_name") ASC);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_systems"(text) IS 'Get all system names owned by a given user';

/* API - get_os_family_distribution */
CREATE OR REPLACE FUNCTION "api"."get_os_family_distribution"() RETURNS SETOF "systems"."os_family_distribution" AS $$
	BEGIN
		RETURN QUERY(SELECT "family",count("family")::integer,round(count("family")::numeric/(SELECT count(*)::numeric FROM "systems"."systems")*100,0)::integer AS "percentage"
		FROM "systems"."systems" 
		JOIN "systems"."os" ON "systems"."systems"."os_name" = "systems"."os"."name" 
		GROUP BY "family"
		ORDER BY count("family") DESC);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_os_family_distribution"() IS 'Get fun statistics on registered operating system families';

/* API - get_os_distribution */
CREATE OR REPLACE FUNCTION "api"."get_os_distribution"() RETURNS SETOF "systems"."os_distribution" AS $$
	BEGIN
		RETURN QUERY(SELECT "os_name",count("os_name")::integer,round(count("os_name")::numeric/(SELECT count(*)::numeric FROM "systems"."systems")*100,0)::integer AS "percentage"
		FROM "systems"."systems" 
		JOIN "systems"."os" ON "systems"."systems"."os_name" = "systems"."os"."name" 
		GROUP BY "os_name"
		ORDER BY count("os_name") DESC);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_os_distribution"() IS 'Get fun statistics on registered operating systems';

/* API - get_interface_owner */
CREATE OR REPLACE FUNCTION "api"."get_interface_owner"(input_mac macaddr) RETURNS TEXT AS $$
	BEGIN
		RETURN (SELECT "owner" FROM "systems"."interfaces" 
			JOIN "systems"."systems" ON "systems"."interfaces"."system_name" = "systems"."systems"."system_name"
			WHERE "mac" = input_mac);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_interface_owner"(macaddr) IS 'Get the owner of the system that contains the mac address';

/* API - get_interface_address_system */
CREATE OR REPLACE FUNCTION "api"."get_interface_address_system"(input_address inet) RETURNS TEXT AS $$
	BEGIN
		RETURN (SELECT "system_name" FROM "systems"."interface_addresses"
		JOIN "systems"."interfaces" ON "systems"."interface_addresses"."mac" = "systems"."interfaces"."mac"
		WHERE "address" = input_address);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_interface_address_system"(inet) IS 'Get the name of the system to which the given address is assigned';

/* API - get_system_interface_address */
CREATE OR REPLACE FUNCTION "api"."get_system_interface_address"(input_address inet) RETURNS SETOF "systems"."interface_addresses" AS $$
	BEGIN
		RETURN QUERY (SELECT * FROM "systems"."interface_addresses" WHERE "address" = input_address);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_system_interface_address"(inet) IS 'Get all interface address data for an address';

/* API - get_owned_interface_addresses */
CREATE OR REPLACE FUNCTION "api"."get_owned_interface_addresses"(input_owner text) RETURNS SETOF "systems"."interface_addresses" AS $$
	BEGIN
		IF input_owner IS NULL THEN
			RETURN QUERY (SELECT * FROM "systems"."interface_addresses");
		ELSE
			RETURN QUERY (SELECT * FROM "systems"."interface_addresses" WHERE api.get_interface_address_owner("address") = input_owner);
		END IF;
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_owned_interface_addresses"(text) IS 'Get all interface address data for all addresses owned by a given user';

/* API - get_system_primary_address */
CREATE OR REPLACE FUNCTION "api"."get_system_primary_address"(input_system_name text) RETURNS INET AS $$
	BEGIN
		RETURN (SELECT "address" FROM "systems"."systems" 
		JOIN "systems"."interfaces" ON "systems"."interfaces"."system_name" = "systems"."systems"."system_name"
		JOIN "systems"."interface_addresses" ON "systems"."interfaces"."mac" = "systems"."interface_addresses"."mac"
		WHERE "isprimary" = TRUE AND "systems"."systems"."system_name" = input_system_name
		ORDER BY "systems"."interfaces"."mac" DESC LIMIT 1);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION  "api"."get_system_primary_address"(text) IS 'Get the primary address of a system';

/* API - get_interface_system*/
CREATE OR REPLACE FUNCTION "api"."get_interface_system"(input_mac macaddr) RETURNS TEXT AS $$
	BEGIN
		RETURN (SELECT "system_name" FROM "systems"."interfaces" WHERE "mac" = input_mac);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_interface_system"(macaddr) IS 'Get the system name that a mac address is on';

CREATE OR REPLACE FUNCTION "api"."get_platforms"() RETURNS SETOF "systems"."platforms" AS $$
	BEGIN
		RETURN QUERY (SELECT * FROM "systems"."platforms" ORDER BY CASE WHEN "platform_name" = 'Custom' THEN 1 ELSE 2 END);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_platforms"() IS 'Get information on all system platforms';

CREATE OR REPLACE FUNCTION "api"."get_datacenters"() RETURNS SETOF "systems"."datacenters" AS $$
	BEGIN
		RETURN QUERY (SELECT * FROM "systems"."datacenters" ORDER BY CASE WHEN "datacenter" = (SELECT api.get_site_configuration('DEFAULT_DATACENTER')) THEN 1 ELSE 2 END);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_datacenters"() IS 'Get all of the available datacenters';

CREATE OR REPLACE FUNCTION "api"."get_availability_zones"() RETURNS SETOF "systems"."availability_zones" AS $$
	BEGIN
		RETURN QUERY (SELECT * FROM "systems"."availability_zones" ORDER BY "zone");
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_availability_zones"() IS 'Get all of the configured availability zones';

CREATE OR REPLACE FUNCTION "api"."get_system_architectures"() RETURNS SETOF "systems"."architectures" AS $$
	BEGIN
		RETURN QUERY (SELECT * FROM "systems"."architectures" ORDER BY CASE WHEN "architecture" = 'i386' THEN 1 ELSE 2 END);
	END;
$$ LANGUAGE 'plpgsql';
COMMENT ON FUNCTION "api"."get_system_architectures"() IS 'Get all the available system architectures';
