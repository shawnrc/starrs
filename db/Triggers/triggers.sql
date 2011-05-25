/* dns.a */
CREATE TRIGGER "dns_a_insert"
BEFORE INSERT ON "dns"."a"
FOR EACH ROW EXECUTE PROCEDURE "dns"."a_insert"();

CREATE TRIGGER "dns_a_update"
BEFORE UPDATE ON "dns"."a"
FOR EACH ROW EXECUTE PROCEDURE "dns"."a_update"();

/* dns.mx */
CREATE TRIGGER "dns_mx_insert"
BEFORE INSERT ON "dns"."mx"
FOR EACH ROW EXECUTE PROCEDURE "dns"."mx_insert"();

CREATE TRIGGER "dns_mx_update"
BEFORE UPDATE ON "dns"."mx"
FOR EACH ROW EXECUTE PROCEDURE "dns"."mx_update"();

/* dns.ns */
CREATE TRIGGER "dns_ns_insert"
BEFORE INSERT ON "dns"."ns"
FOR EACH ROW EXECUTE PROCEDURE "dns"."ns_insert"();

CREATE TRIGGER "dns_ns_update"
BEFORE UPDATE ON "dns"."ns"
FOR EACH ROW EXECUTE PROCEDURE "dns"."ns_update"();

/* dns.pointers */
CREATE TRIGGER "dns_pointers_insert"
BEFORE INSERT ON "dns"."pointers"
FOR EACH ROW EXECUTE PROCEDURE "dns"."pointers_insert"();

CREATE TRIGGER "dns_pointers_update"
BEFORE UPDATE ON "dns"."pointers"
FOR EACH ROW EXECUTE PROCEDURE "dns"."pointers_update"();

/* dns.txt */
CREATE TRIGGER "dns_txt_insert"
BEFORE INSERT ON "dns"."txt"
FOR EACH ROW EXECUTE PROCEDURE "dns"."txt_insert"();

CREATE TRIGGER "dns_txt_update"
BEFORE UPDATE ON "dns"."txt"
FOR EACH ROW EXECUTE PROCEDURE "dns"."txt_update"();

/* firewall.metahost_members */
CREATE TRIGGER "firewall_metahost_members_insert"
BEFORE INSERT ON "firewall"."metahost_members"
FOR EACH ROW EXECUTE PROCEDURE "firewall"."metahost_members_insert"();

CREATE TRIGGER "firewall_metahost_members_update"
BEFORE UPDATE ON "firewall"."metahost_members"
FOR EACH ROW EXECUTE PROCEDURE "firewall"."metahost_members_update"();

CREATE TRIGGER "firewall_metahost_members_delete"
BEFORE DELETE ON "firewall"."metahost_members"
FOR EACH ROW EXECUTE PROCEDURE "firewall"."metahost_members_delete"();

/* firewall.rules */
CREATE TRIGGER "firewall_rules_insert"
BEFORE INSERT ON "firewall"."rules"
FOR EACH ROW EXECUTE PROCEDURE "firewall"."rules_insert"();

CREATE TRIGGER "firewall_rules_update"
BEFORE UPDATE ON "firewall"."rules"
FOR EACH ROW EXECUTE PROCEDURE "firewall"."rules_update"();

/* ip.addresses */
CREATE TRIGGER "ip_addresses_insert"
BEFORE INSERT ON "ip"."addresses"
FOR EACH ROW EXECUTE PROCEDURE "ip"."addresses_insert"();

/* ip.ranges */
CREATE TRIGGER "ip_ranges_insert"
BEFORE INSERT ON "ip"."ranges"
FOR EACH ROW EXECUTE PROCEDURE "ip"."ranges_insert"();

CREATE TRIGGER "ip_ranges_update"
BEFORE UPDATE ON "ip"."ranges"
FOR EACH ROW EXECUTE PROCEDURE "ip"."ranges_update"();

/* ip.subnets */
CREATE TRIGGER "ip_subnets_insert"
BEFORE INSERT ON "ip"."subnets"
FOR EACH ROW EXECUTE PROCEDURE "ip"."subnets_insert"();

CREATE TRIGGER "ip_subnets_update"
BEFORE UPDATE ON "ip"."subnets"
FOR EACH ROW EXECUTE PROCEDURE "ip"."subnets_update"();

CREATE TRIGGER "ip_subnets_delete"
BEFORE DELETE ON "ip"."subnets"
FOR EACH ROW EXECUTE PROCEDURE "ip"."subnets_delete"();

/* network.switchports */
CREATE TRIGGER "network_switchports_insert"
BEFORE INSERT ON "network"."switchports"
FOR EACH ROW EXECUTE PROCEDURE "network"."switchports_insert"();

CREATE TRIGGER "network_switchports_update"
BEFORE UPDATE ON "network"."switchports"
FOR EACH ROW EXECUTE PROCEDURE "network"."switchports_update"();

/* systems.interface_addresses */
CREATE TRIGGER "systems_interface_addresses_insert"
BEFORE INSERT ON "systems"."interface_addresses"
FOR EACH ROW EXECUTE PROCEDURE "systems"."interface_addresses_insert"();

CREATE TRIGGER "systems_interface_addresses_update"
BEFORE UPDATE ON "systems"."interface_addresses"
FOR EACH ROW EXECUTE PROCEDURE "systems"."interface_addresses_update"();