select api.initialize('root');

DELETE FROM "management"."configuration" WHERE "option" IS NOT NULL;
DELETE FROM "dhcp"."class_options" WHERE "option" IS NOT NULL;
DELETE FROM "dns"."a" WHERE "address" IS NOT NULL;
DELETE FROM "firewall"."metahost_rules" WHERE "name" IS NOT NULL;
DELETE FROM "firewall"."metahost_members" WHERE "name" IS NOT NULL;
DELETE FROM "firewall"."metahost_program_rules" WHERE "name" IS NOT NULL;
DELETE FROM "firewall"."rules" WHERE "address" IS NOT NULL;
DELETE FROM "firewall"."program_rules" WHERE "address" IS NOT NULL;
DELETE FROM "firewall"."metahosts" WHERE "name" IS NOT NULL;	
DELETE FROM "systems"."interface_addresses" WHERE "address" IS NOT NULL;
DELETE FROM "ip"."addresses" WHERE "address" IS NOT NULL;
DELETE FROM "dhcp"."range_options" WHERE "option" IS NOT NULL;
DELETE FROM "ip"."ranges" WHERE "subnet" IS NOT NULL;
DELETE FROM "ip"."subnets" WHERE "subnet" IS NOT NULL;
DELETE FROM "dns"."zones" WHERE "zone" IS NOT NULL;
DELETE FROM "dns"."keys" WHERE "keyname" IS NOT NULL;
DELETE FROM "dhcp"."global_options" WHERE "option" IS NOT NULL;
DELETE FROM "dhcp"."subnet_options" WHERE "option" IS NOT NULL;
DELETE FROM "dhcp"."classes" WHERE "class" IS NOT NULL;
DELETE FROM "systems"."systems" WHERE "system_name" IS NOT NULL;
DELETE FROM "systems"."interfaces" WHERE "mac" IS NOT NULL;



BEGIN;
SELECT api.create_site_configuration('DHCPD_HEADER','# dhcpd.conf\n# autogenerated from postgres database\n# Edit this block to change any of the global options for dhcp.');
SELECT api.create_site_configuration('NETWORK_NAME','impulse-net');
SELECT api.create_site_configuration('DNS_DEFAULT_KEY','impulse');
SELECT api.create_site_configuration('DNS_DEFAULT_ZONE','impulse.net');
SELECT api.create_site_configuration('DNS_KEY_ENCTYPE','rc4-hmac');
SELECT api.create_site_configuration('FW_DEFAULT_ACTION','TRUE');
SELECT api.create_site_configuration('DHCPD_DEFAULT_CLASS','default');
SELECT api.create_site_configuration('DYNAMIC_SUBNET','172.31.252.0/22');
SELECT api.create_site_configuration('DHCPD_MIN_LEASE_TIME','3600');
SELECT api.create_site_configuration('DHCPD_DEFAULT_LEASE_TIME','7200');
SELECT api.create_site_configuration('DHCPD_MAX_LEASE_TIME','14400');
COMMIT;

BEGIN;
SELECT api.create_dhcp_class('default','Base class for everyone');
SELECT api.create_dhcp_class('netboot','PXE boot server project');
COMMIT;

BEGIN;
SELECT api.create_dhcp_class_option('default','match pick-first-value','(option dhcp-client-identifier, hardware)');
SELECT api.create_dhcp_class_option('netboot','match pick-first-value','(option dhcp-client-identifier, hardware)');
SELECT api.create_dhcp_class_option('netboot','filename','"pxelinux.0"');
SELECT api.create_dhcp_class_option('netboot','next-server','10.21.50.9');
COMMIT;

BEGIN;
SELECT api.create_dns_key('impulse','123456asdfgh',NULL,'IMPULSE test key');
SELECT api.create_dns_zone('impulse.net','impulse',TRUE,TRUE,NULL,'Testing zone for the project');
SELECT api.create_dns_zone('impulse.nfs','impulse',TRUE,TRUE,NULL,'Another testing zone for the project');
COMMIT;

BEGIN;
SELECT api.create_subnet('10.21.60.0/23','Unregistered','Unregd machines',FALSE,TRUE,'impulse.net','root');
SELECT api.create_subnet('10.21.49.0/24','49net','Server room',TRUE,TRUE,'impulse.net','root');
SELECT api.create_subnet('10.21.50.0/24','50net','Workstations',TRUE,TRUE,'impulse.net','root');
SELECT api.create_subnet('10.6.9.0/24','NFSnet','NFS network',TRUE,FALSE,'impulse.nfs','root');
SELECT api.create_subnet('2001:db0::/64','IMPULSEv6','IPv6 network',FALSE,TRUE,'impulse.net','root');
SELECT api.create_subnet(cidr(api.get_site_configuration('DYNAMIC_SUBNET')),'Dynamic Placeholder','Placeholder for dynamic IP addresses',TRUE,FALSE,NULL,NULL);
COMMIT;

BEGIN;
SELECT api.create_address_range('10.21.60.1','10.21.60.50','10.21.60.0/23');
SELECT api.create_address_range('2001:db0::2000:1','2001:db0::2000:3ff','2001:db0::/64');
COMMIT;

BEGIN;
SELECT api.create_ip_range('Unregistered','10.21.60.1','10.21.60.50','10.21.60.0/23','ROAM',NULL,'Unregistered machines');
SELECT api.create_ip_range('Projects','10.21.50.1','10.21.50.64','10.21.50.0/24','UREG','default','Projects and random things');
SELECT api.create_ip_range('Workstations','10.21.50.65','10.21.50.170','10.21.50.0/24','UREG','default','Office machines');
SELECT api.create_ip_range('Dynamic Pool','10.21.50.171','10.21.50.249','10.21.50.0/24','ROAM',NULL,'Dynamic pool');
SELECT api.create_ip_range('Personal Servers','10.21.49.1','10.21.49.80','10.21.49.0/24','UREG','default','User rack machines');
SELECT api.create_ip_range('Cluster','10.21.49.81','10.21.49.127','10.21.49.0/24','UREG','default','Xen Cluster');
SELECT api.create_ip_range('Servers','10.21.49.128','10.21.49.249','10.21.49.0/24','UREG','default','Server room machines');
SELECT api.create_ip_range('DHCPv6','2001:db0::2000:1','2001:db0::2000:3ff','2001:db0::/64','ROAM','default','Dynamic pool for IPv6');
COMMIT;

BEGIN;
SELECT api.create_dhcp_global_option('option dhcp-server-identifier','wopr.impulse.net');
SELECT api.create_dhcp_global_option('option space','PXE');
SELECT api.create_dhcp_global_option('option PXE.mtftp-ip','code 1 = ip-address');
SELECT api.create_dhcp_global_option('option PXE.mtftp-cport','code 2 = unsigned integer 16');
SELECT api.create_dhcp_global_option('option PXE.mtftp-sport','code 3 = unsigned integer 16');
SELECT api.create_dhcp_global_option('option PXE.mtftp-tmout','code 4 = unsigned integer 8');
SELECT api.create_dhcp_global_option('option PXE.mtftp-delay','code 5 = unsigned integer 8');
SELECT api.create_dhcp_global_option('option PXE.discovery-control','code 6 = unsigned integer 8');
SELECT api.create_dhcp_global_option('option PXE.discovery-mcast-addr','code 7 = ip-address');
SELECT api.create_dhcp_global_option('option rfc3442-classless-static-routes','code 121 = array of integer 8');
SELECT api.create_dhcp_global_option('option ms-classless-static-routes','code 249 = array of integer 8');
SELECT api.create_dhcp_global_option('ddns-update-style','interim');
SELECT api.create_dhcp_global_option('ignore','client-updates');
SELECT api.create_dhcp_global_option('update-static-leases','on');
SELECT api.create_dhcp_global_option('ddns-rev-domainname','"in-addr.arpa"');
COMMIT;

BEGIN;
SELECT api.create_dhcp_subnet_option('10.21.60.0/23','option subnet-mask','255.255.254.0');
SELECT api.create_dhcp_subnet_option('10.21.60.0/23','min-lease-time','3600');
SELECT api.create_dhcp_subnet_option('10.21.60.0/23','default-lease-time','7200');
SELECT api.create_dhcp_subnet_option('10.21.60.0/23','max-lease-time','14400');
SELECT api.create_dhcp_subnet_option('10.21.60.0/23','option domain-name-servers','10.21.60.9');
SELECT api.create_dhcp_subnet_option('10.21.50.0/24','option subnet-mask','255.255.255.0');
SELECT api.create_dhcp_subnet_option('10.21.50.0/24','min-lease-time','3600');
SELECT api.create_dhcp_subnet_option('10.21.50.0/24','default-lease-time','7200');
SELECT api.create_dhcp_subnet_option('10.21.50.0/24','max-lease-time','14400');
SELECT api.create_dhcp_subnet_option('10.21.50.0/24','option routers','10.21.50.254');
SELECT api.create_dhcp_subnet_option('10.21.50.0/24','option domain-name-servers','10.21.49.186, 10.21.3.17, 10.21.4.18');
SELECT api.create_dhcp_subnet_option('10.21.50.0/24','option ms-classless-static-routes','24, 10, 21, 49, 10, 21, 50, 254, 0, 10, 21, 50, 254');
SELECT api.create_dhcp_subnet_option('10.21.50.0/24','option rfc3442-classless-static-routes','24, 10, 21, 49, 10, 21, 50, 254, 0, 10, 21, 50, 254');
SELECT api.create_dhcp_subnet_option('10.21.49.0/24','option subnet-mask','255.255.255.0');
SELECT api.create_dhcp_subnet_option('10.21.49.0/24','min-lease-time','3600');
SELECT api.create_dhcp_subnet_option('10.21.49.0/24','default-lease-time','7200');
SELECT api.create_dhcp_subnet_option('10.21.49.0/24','max-lease-time','14400');
SELECT api.create_dhcp_subnet_option('10.21.49.0/24','option routers','10.21.50.254');
SELECT api.create_dhcp_subnet_option('10.21.49.0/24','option domain-name-servers','10.21.49.186, 10.21.3.17, 10.21.4.18');
COMMIT;

BEGIN;
SELECT api.create_dhcp_range_option('Dynamic Pool','option domain-name','"impulse.net"');
SELECT api.create_dhcp_range_option('Dynamic Pool','min-lease-time','3600');
SELECT api.create_dhcp_range_option('Dynamic Pool','default-lease-time','3600');
SELECT api.create_dhcp_range_option('Dynamic Pool','max-lease-time','7200');
SELECT api.create_dhcp_range_option('Unregistered','option domain-name','"impulse.net"');
SELECT api.create_dhcp_range_option('Unregistered','default-lease-time','300');
SELECT api.create_dhcp_range_option('Unregistered','max-lease-time','700');
SELECT api.create_dhcp_range_option('Unregistered','deny','dynamic bootp clients');
SELECT api.create_dhcp_range_option('Unregistered','ddns-updates','off');
COMMIT;

-- Lets become a user!
SELECT api.deinitialize();
SELECT api.initialize('user');

BEGIN;
SELECT api.create_system('Hactar',NULL,'Server','Debian','The file server');
SELECT api.create_interface('Hactar','00:0c:29:69:f4:21','eth0','External interface');
SELECT api.create_interface_address('00:0c:29:69:f4:21','10.21.49.131','static',NULL,TRUE,'host address');
SELECT api.create_interface_address('00:0c:29:69:f4:21','10.21.49.215','static',NULL,FALSE,'old filer address since we are lazy');
SELECT api.create_interface_address('00:0c:29:69:f4:21','2001:db0::020c:29ff:fe69:f421','autoconf',NULL,TRUE,'host address');
--SELECT api.create_interface_address('00:0c:29:69:f4:21','2001:db0::020c:29ff:fe11:4513','static',NULL,FALSE,'old filer address since we are lazy');
SELECT api.create_dns_address('10.21.49.131','hactar','impulse.net',NULL,NULL);
SELECT api.create_dns_address('10.21.49.215','hactar-old','impulse.net',NULL,NULL);
SELECT api.create_dns_address('2001:db0::020c:29ff:fe69:f421','hactar','impulse.net',NULL,NULL);
--SELECT api.create_dns_address('2001:db0::020c:29ff:fe11:4513','hactar-old','impulse.net',NULL,NULL);
SELECT api.create_interface('Hactar','00:0c:29:69:f4:22','eth1','NFS network');
SELECT api.create_interface_address('00:0c:29:69:f4:22','10.6.9.131','static',NULL,TRUE,NULL);
SELECT api.create_dns_address('10.6.9.131','hactar','impulse.nfs',NULL,NULL);
COMMIT;

BEGIN;
SELECT api.create_system('Skynet',NULL,'Server','FreeBSD','Misc services');
SELECT api.create_interface('Skynet','00:0c:29:69:21:21','fxp0','External interface');
SELECT api.create_interface_address('00:0c:29:69:21:21','10.21.49.166','static',NULL,TRUE,'host address');
SELECT api.create_interface_address('00:0c:29:69:21:21','2001:db0::020c:29ff:fe69:2121','autoconf',NULL,TRUE,'host address');
SELECT api.create_dns_address('10.21.49.166','skynet','impulse.net',NULL,NULL);
SELECT api.create_dns_address('2001:db0::020c:29ff:fe69:2121','skynet','impulse.net',NULL,NULL);
SELECT api.create_interface('Skynet','00:0c:29:69:21:22','fxp1','NFS network');
SELECT api.create_interface_address('00:0c:29:69:21:22','10.6.9.166','static',NULL,TRUE,NULL);
SELECT api.create_dns_address('10.6.9.166','skynet','impulse.nfs',NULL,NULL);
COMMIT;

BEGIN;
SELECT api.create_system('LCARS',NULL,'Server','Windows Server 2003','Library');
SELECT api.create_interface('LCARS','00:0c:29:69:dd:21','Local Area Connection','External interface');
SELECT api.create_interface_address('00:0c:29:69:dd:21','10.21.49.139','static',NULL,TRUE,'host address');
SELECT api.create_interface_address('00:0c:29:69:dd:21','2001:db0::020c:29ff:fe69:dd21','autoconf',NULL,TRUE,'host address');
SELECT api.create_dns_address('10.21.49.139','lcars','impulse.net',NULL,NULL);
SELECT api.create_dns_address('2001:db0::020c:29ff:fe69:dd21','lcars','impulse.net',NULL,NULL);
COMMIT;

BEGIN;
SELECT api.create_system('WOPR',NULL,'Server','FreeBSD','Network server');
SELECT api.create_interface('WOPR','00:0c:29:69:ee:21','en0','49net interface');
SELECT api.create_interface_address('00:0c:29:69:ee:21','10.21.49.200','static',NULL,TRUE,'49net address');
SELECT api.create_interface_address('00:0c:29:69:ee:21','2001:db0::020c:29ff:fe69:ee21','autoconf',NULL,TRUE,'49net address');
SELECT api.create_dns_address('10.21.49.200','wopr49','impulse.net',NULL,NULL);
SELECT api.create_interface('WOPR','00:0c:29:69:ee:22','en1','50net interface');
SELECT api.create_interface_address('00:0c:29:69:ee:22','10.21.50.200','static',NULL,TRUE,'50net address');
SELECT api.create_interface_address('00:0c:29:69:ee:22','2001:db0::020c:29ff:fe69:ee22','autoconf',NULL,TRUE,'50net address');
SELECT api.create_dns_address('10.21.50.200','wopr50','impulse.net',NULL,NULL);
SELECT api.create_dns_address('2001:db0::020c:29ff:fe69:ee22','wopr50','impulse.net',NULL,NULL);
COMMIT;

-- Admin
SELECT api.deinitialize();
SELECT api.initialize('admin');

BEGIN;
SELECT api.create_system('Firewall','root','Firewall','Cisco IOS','Firewall for all out');
SELECT api.create_interface('Firewall','00:0c:29:69:f1:43','System','Internal access interface');
SELECT api.create_interface_address('00:0c:29:69:f1:43','10.21.49.253','static',NULL,TRUE,'Main firewall');
SELECT api.create_interface_address('00:0c:29:69:f1:43','2001:db0::020c:29ff:fe69:f143','autoconf',NULL,TRUE,'Main firewall');
SELECT api.create_dns_address('10.21.49.253','firewall','impulse.net',NULL,NULL);
SELECT api.create_dns_address('2001:db0::020c:29ff:fe69:f143','firewall','impulse.net',NULL,NULL);
COMMIT;

BEGIN;
SELECT api.create_system('Head Switch','root','Switch','Cisco IOS','Main switch');
SELECT api.create_interface('Head Switch','00:0c:29:c1:c3:c0','VLAN','Access to the switch');
SELECT api.create_interface_address('00:0c:29:c1:c3:c0','10.21.49.252','static',NULL,TRUE,'Switch address');
SELECT api.create_interface_address('00:0c:29:c1:c3:c0','2001:db0::020c:29ff:fec1:c3c0','autoconf',NULL,TRUE,'Switch address');
SELECT api.create_dns_address('10.21.49.252','headswitch','impulse.net',NULL,NULL);
SELECT api.create_dns_address('2001:db0::020c:29ff:fec1:c3c0','headswitch','impulse.net',NULL,NULL);
COMMIT;

-- Lets become a user!
SELECT api.deinitialize();
SELECT api.initialize('user');

BEGIN;
SELECT api.create_system('Tron',NULL,'Desktop','Windows 7',NULL);
SELECT api.create_interface('Tron','00:0c:29:69:10:1e','Local Area Connection','Upper interface');
SELECT api.create_interface_address('00:0c:29:69:10:1e','10.21.50.1','dhcp',NULL,TRUE,NULL);
SELECT api.create_dns_address('10.21.50.1','tron','impulse.net',NULL,NULL);
COMMIT;

BEGIN;
SELECT api.create_system('Pacman',NULL,'Desktop','Debian','My desktop');
SELECT api.create_interface('Pacman','00:0c:29:69:9a:ca','eth0',NULL);
SELECT api.create_interface_address('00:0c:29:69:9a:ca','10.21.50.2','dhcp',NULL,TRUE,NULL);
SELECT api.create_dns_address('10.21.50.2','pacman','impulse.net',NULL,NULL);
COMMIT;

BEGIN;
SELECT api.create_system('Joust',NULL,'Desktop','Windows 7','Broken');
SELECT api.create_interface('Joust','00:0c:29:69:99:18','Local Area Connection','IMPULSEnet');
SELECT api.create_interface_address('00:0c:29:69:99:18','10.21.50.3','dhcp',NULL,TRUE,NULL);
SELECT api.create_dns_address('10.21.50.3','joust','impulse.net',NULL,NULL);
COMMIT;

BEGIN;
SELECT api.create_system('Encom',NULL,'Server','CentOS','Webserver');
SELECT api.create_interface('Encom','00:0c:29:69:e7:c0','eth0',NULL);
SELECT api.create_interface_address('00:0c:29:69:e7:c0','10.21.50.4','dhcp',NULL,TRUE,NULL);
SELECT api.create_dns_address('10.21.50.4','encom','impulse.net',NULL,NULL);
COMMIT;

BEGIN;
SELECT api.create_firewall_metahost('IMP',NULL,'All my machines');
COMMIT;

BEGIN;
SELECT api.create_firewall_metahost_member('10.21.50.1','IMP');
SELECT api.create_firewall_metahost_member('10.21.50.2','IMP');
SELECT api.create_firewall_metahost_member('10.21.50.3','IMP');
SELECT api.create_firewall_metahost_member('10.21.50.4','IMP');
COMMIT;

BEGIN;
SELECT api.create_firewall_metahost_rule('IMP',23,'TCP',FALSE,'Allow telnet');
SELECT api.create_firewall_metahost_rule('IMP',31337,'TCP',FALSE,'Allow elite');
SELECT api.create_firewall_metahost_rule('IMP',3389,'TCP',FALSE,'Block Windows RDP');
COMMIT;

BEGIN;
SELECT api.create_firewall_rule('10.21.50.1',585,'UDP',TRUE,NULL,'Block something');
SELECT api.create_firewall_rule('10.21.50.1',475,'UDP',TRUE,NULL,'Block internal apps');
SELECT api.create_firewall_rule('10.21.50.4',8080,'TCP',FALSE,NULL,'Allow special web');
SELECT api.create_firewall_rule('10.21.50.4',53,'TCP',FALSE,NULL,'Allow DNS');
COMMIT;

BEGIN;
SELECT api.create_firewall_rule_program('10.21.50.1','HTTP',FALSE,NULL);
SELECT api.create_firewall_rule_program('10.21.50.1','HTTPS',FALSE,NULL);
COMMIT;

BEGIN;
SELECT api.create_firewall_metahost_rule_program('IMP','SSH',FALSE);
SELECT api.create_firewall_metahost_rule_program('IMP','LDAP',FALSE);
COMMIT;
















