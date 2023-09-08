BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS `sessions` (
	`id`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	`start_time`	STRING NOT NULL,
	`server_time_offset`	DOUBLE,
	`last_event_time`	STRING,
	`pause_time`	STRING NOT NULL,
	`locale`	STRING NOT NULL,
	`event_seq`	INTEGER NOT NULL DEFAULT 0,
	`api_key`	STRING NOT NULL,
	`type`	INTEGER NOT NULL,
	`app_state`	STRING,
	`finished`	BOOL NOT NULL DEFAULT 0,
	`session_id`	STRING NOT NULL
);
INSERT INTO `sessions` VALUES (2,1418737481.27388,NULL,1418737783.80572,1418737783.80572,'en-BY',2,1111,0,'{"deviceid":"EF5FFD5E-C28D-484E-B747-32E128F5B99D","ifv":"E1198B1E-5C2D-45B3-878B-A0F633D0FACF","app_version_name":"1.42","analytics_sdk_version_name":"1.42","is_rooted":"1","locale":"en-BY","os_version":"8.1","analytics_sdk_version":"142","app_build_number":"456","uuid":"a1234567890123456789012345678901"}',1,1418737481);
INSERT INTO `sessions` VALUES (3,1418742210.1385,NULL,1418742210.99402,1418742210.99402,'en-BY',1,1111,0,'{"deviceid":"EF5FFD5E-C28D-484E-B747-32E128F5B99D","ifv":"E1198B1E-5C2D-45B3-878B-A0F633D0FACF","app_version_name":"1.42","analytics_sdk_version_name":"1.42","is_rooted":"1","locale":"en-BY","os_version":"8.1","analytics_sdk_version":"142","app_build_number":"456","uuid":"a1234567890123456789012345678901"}',0,1418742210);
INSERT INTO `sessions` VALUES (4,1418750601.40308,NULL,1418750814.96349,1418750814.96349,'en-BY',12,7633,0,'{"deviceid":"EF5FFD5E-C28D-484E-B747-32E128F5B99D","ifv":"E1198B1E-5C2D-45B3-878B-A0F633D0FACF","app_version_name":"1.42","analytics_sdk_version_name":"1.61","is_rooted":"1","locale":"en-BY","os_version":"8.1","analytics_sdk_version":"161","app_build_number":"456","uuid":"a1234567890123456789012345678901"}',1,1418750601);
INSERT INTO `sessions` VALUES (5,1418750825.31046,NULL,1418750825.31046,1418750825.31046,'en-BY',3,7633,0,'{"deviceid":"EF5FFD5E-C28D-484E-B747-32E128F5B99D","ifv":"E1198B1E-5C2D-45B3-878B-A0F633D0FACF","app_version_name":"1.42","analytics_sdk_version_name":"1.61","is_rooted":"1","locale":"en-BY","os_version":"8.1","analytics_sdk_version":"161","app_build_number":"456","uuid":"a1234567890123456789012345678901"}',1,1418750825);
INSERT INTO `sessions` VALUES (6,1418750830.76632,NULL,1418750830.76632,1418750830.76632,'en-BY',1,7633,0,'{"deviceid":"EF5FFD5E-C28D-484E-B747-32E128F5B99D","ifv":"E1198B1E-5C2D-45B3-878B-A0F633D0FACF","app_version_name":"1.42","analytics_sdk_version_name":"1.61","is_rooted":"1","locale":"en-BY","os_version":"8.1","analytics_sdk_version":"161","app_build_number":"456","uuid":"a1234567890123456789012345678901"}',0,1418750830);
CREATE TABLE IF NOT EXISTS `kv` (
	`k`	STRING NOT NULL,
	`v`	STRING NOT NULL DEFAULT '',
	PRIMARY KEY(`k`)
);
INSERT INTO `kv` VALUES ('indentity.sent.date',1418737133.47083);
INSERT INTO `kv` VALUES ('migrated.to.version',150);
INSERT INTO `kv` VALUES ('startup.host','http://startup.heroism.com');
INSERT INTO `kv` VALUES ('uuid','a1234567890123456789012345678901');
INSERT INTO `kv` VALUES ('report_ad.host','https://mobile-ads-beta.appmetrica.io:4443');
INSERT INTO `kv` VALUES ('get_url_schemes.host','http://appmetrica.heroism.com');
INSERT INTO `kv` VALUES ('get_ad.host','https://mobile-ads-beta.appmetrica.io:4443');
INSERT INTO `kv` VALUES ('schema.version',16);
INSERT INTO `kv` VALUES ('startup.updated_at',0);
INSERT INTO `kv` VALUES ('report.hosts','["http://appmetrica.heroism.com"]');
CREATE TABLE IF NOT EXISTS `events` (
	`id`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	`created_at`	STRING NOT NULL,
	`session_id`	INTEGER NOT NULL,
	`seq`	INTEGER NOT NULL,
	`offset`	STRING NOT NULL,
	`name`	STRING,
	`value`	STRING,
	`type`	INTEGER NOT NULL,
	`latitude`	DOUBLE,
	`longitude`	DOUBLE,
	`location_timestamp`	STRING,
	`location_horizontal_accuracy`	INTEGER,
	`location_vertical_accuracy`	INTEGER,
	`location_direction`	INTEGER,
	`location_speed`	INTEGER,
	`location_altitude`	INTEGER,
	`error_environment`	STRING,
	`user_info`	STRING,
	`app_environment`	STRING,
	`bytes_truncated`	INTEGER,
	`location_enabled`	INTEGER,
	`user_profile_id`	INTEGER,
	`encryption_type`	INTEGER
);
INSERT INTO `events` VALUES (7,1418737481.27388,2,0,0,'','',2,123.123,456.456,NULL,100,-1,-1,-1,NULL,NULL,NULL,NULL,0,NULL,'john_doe',1);
INSERT INTO `events` VALUES (8,0,2,1,302.531841,'','',7,123.123,456.456,NULL,100,-1,-1,-1,NULL,NULL,NULL,NULL,0,NULL,'john_doe',1);
INSERT INTO `events` VALUES (9,1418742210.1385,3,0,0,'','',2,123.123,456.456,NULL,100,-1,-1,-1,NULL,NULL,NULL,NULL,0,NULL,'john_doe',1);
INSERT INTO `events` VALUES (10,1418750601.40308,4,0,0,'','',1,123.123,456.456,1418750598.33363,65,10,-1,-1,974.811904907227,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (11,1418750601.40308,4,1,0,'','',2,123.123,456.456,1418750598.33363,65,10,-1,-1,974.811904907227,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (12,1418750812.43682,4,2,211.033744,'EVENT-A 1','',4,123.123,456.456,1418750811.24483,65,10,-1,-1,974.633102416992,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (13,1418750812.77094,4,3,211.367859,'EVENT-B 1','',4,123.123,456.456,1418750811.24483,65,10,-1,-1,974.633102416992,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (14,1418750813.02633,4,4,211.623249,'EVENT-A 2','',4,123.123,456.456,1418750811.24483,65,10,-1,-1,974.633102416992,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (15,1418750813.27189,4,5,211.868817,'EVENT-B 2','',4,123.123,456.456,1418750811.24483,65,10,-1,-1,974.633102416992,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (16,1418750813.48868,4,6,212.085607,'EVENT-A 3','',4,123.123,456.456,1418750811.24483,65,10,-1,-1,974.633102416992,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (17,1418750813.74471,4,7,212.341632,'EVENT-B 3','',4,123.123,456.456,1418750811.24483,65,10,-1,-1,974.633102416992,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (18,1418750814.00285,4,8,212.599773,'EVENT-A 4','',4,123.123,456.456,1418750811.24483,65,10,-1,-1,974.633102416992,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (19,1418750814.65908,4,9,213.255998,'ERROR 1','',6,123.123,456.456,1418750811.24483,65,10,-1,-1,974.633102416992,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (20,1418750814.96349,4,10,213.560413,'EXCEPTION 1','CrashReporter Key: 495d98a3ffd75e97d561b8cd242d60892a0d29dd
Hardware Model: iPhone4,1
Process: MetricaSample [601]
Path: <null>
Identifier: io.appmetrica.mobile.MetricaSample
App Version: 1.42 (456)
CPU Arch: armv7f
Parent Process: debugserver [600]
OS Version: iPhone OS 8.1 (12B411)
Report Version: 1

Exception time: 2014-12-16T17:26:54Z
UserInfo: 
Reason: test exception
Name: EXCEPTION 1
Stacktrace: 
0   CoreFoundation                      0x292e0d7f <redacted> + 150
1   libobjc.A.dylib                     0x36b3fc77 objc_exception_throw + 38
2   CoreFoundation                      0x292e0a75 <redacted> + 0
3   MetricaSample                       0x0007ec3d +[MMSReportingUtils reportException] + 252
4   MetricaSample                       0x0008e76b __42+[MMSListItemsProvider reportingListItems]_block_invoke_8 + 90
5   MetricaSample                       0x00090e7d -[MMSListViewController tableView:didSelectRowAtIndexPath:] + 304
6   UIKit                               0x2c89b897 <redacted> + 918
7   UIKit                               0x2c94d2f7 <redacted> + 194
8   UIKit                               0x2c7ff471 <redacted> + 308
9   UIKit                               0x2c77b1af <redacted> + 458
10  CoreFoundation                      0x292a7625 <redacted> + 20
11  CoreFoundation                      0x292a4d09 <redacted> + 276
12  CoreFoundation                      0x292a510b <redacted> + 914
13  CoreFoundation                      0x291f2981 CFRunLoopRunSpecific + 476
14  CoreFoundation                      0x291f2793 CFRunLoopRunInMode + 106
15  GraphicsServices                    0x305cb051 GSEventRunModal + 136
16  UIKit                               0x2c7e4981 UIApplicationMain + 1440
17  MetricaSample                       0x0007c32d main + 116
18  libdyld.dylib                       0x370dbaaf <redacted> + 2',6,123.123,456.456,1418750811.24483,65,10,-1,-1,974.633102416992,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (21,0,4,11,213.560413,'','',7,123.123,456.456,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,1,'john_doe',1);
INSERT INTO `events` VALUES (22,1418750825.31046,5,0,0,'','',2,123.123,456.456,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,'john_doe',1);
INSERT INTO `events` VALUES (23,0,5,1,0,'','',7,123.123,456.456,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,'john_doe',1);
INSERT INTO `events` VALUES (24,1418750830.76632,6,0,0,'','',2,123.123,456.456,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,'john_doe',1);
INSERT INTO `events` VALUES (25,1418750835.76632,6,1,17.0123,'EXC_CRASH','Crash Body
Multiline',3,123.123,456.456,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'john_doe',1);
COMMIT;
