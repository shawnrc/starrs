/* Public */
DROP SCHEMA IF EXISTS "public";

/*Schema firewall*/
CREATE SCHEMA "firewall";
COMMENT ON SCHEMA "firewall" IS 'All firewall data controlling access from the outside world';

/*Schema systems*/
CREATE SCHEMA "systems";
COMMENT ON SCHEMA "systems" IS 'User machine data for devices on the network';

/*Schema dhcp*/
CREATE SCHEMA "dhcp";
COMMENT ON SCHEMA "dhcp" IS 'Configuration for stateful addressing';

/*Schema ip*/
CREATE SCHEMA "ip";
COMMENT ON SCHEMA "ip" IS 'Network resources available for devices';

/*Schema dns*/
CREATE SCHEMA "dns";
COMMENT ON SCHEMA "dns" IS 'All DNS records for the controlled zones/domains';

/*Schema management*/
CREATE SCHEMA "management";
COMMENT ON SCHEMA "management" IS 'Application configuration and data';

/*Schema network*/
CREATE SCHEMA "network";
COMMENT ON SCHEMA "network" IS 'Data on special network devices';

/*Schema api*/
CREATE SCHEMA "api";
COMMENT ON SCHEMA "api" IS 'Interaction with clients';

/*Schema documentation*/
CREATE SCHEMA "documentation";
COMMENT ON SCHEMA "documentation" IS 'Documentation for all functions';

/*Sequence Output ID*/
CREATE SEQUENCE "management"."output_id_seq";
COMMENT ON SEQUENCE "management"."output_id_seq" IS 'Identifier for all output results';

/*Language plperl*/
CREATE LANGUAGE "plperl";

/*Language plperlu*/
CREATE LANGUAGE "plperlu";

set search_path TO "api";