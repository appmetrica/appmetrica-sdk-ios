BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "sessions" (
"id"    INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
"start_time"    STRING NOT NULL,
"server_time_offset"    DOUBLE,
"last_event_time"    STRING,
"pause_time"    STRING NOT NULL,
"locale"    STRING NOT NULL,
"event_seq"    INTEGER NOT NULL DEFAULT 0,
"api_key"    STRING NOT NULL,
"type"    INTEGER NOT NULL,
"app_state"    STRING,
"finished"    BOOL NOT NULL DEFAULT 0,
"session_id"    STRING NOT NULL,
"attribution_id"    STRING
);
INSERT INTO "sessions" VALUES (1,1568284188.4791,NULL,1568284188.4791,1568284188.4791,'en_US',3,'550e8400-e29b-41d4-a716-446655440000',1,'{"os_api_level":"12","uuid":"59a050e331fe457ab300882db3e2f2c5","ifa":"C3531E71-A803-465C-8923-32A9389E667C","app_version_name":"371","analytics_sdk_build_type":"static","app_build_number":"0","ifv":"189973FE-FE69-40D8-BFC5-5E00744585E4","analytics_sdk_version_name":"3.7.1","locale":"en_US","is_rooted":"1","analytics_sdk_build_number":"0","deviceid":"96A20D12-E5D6-4F36-8886-77B3E56B64C0","os_version":"12.2","app_debuggable":"1","limit_ad_tracking":"0"}',1,10000000000,1);
INSERT INTO "sessions" VALUES (2,1568284188.62191,NULL,1568284198.59294,1568284198.59294,'en_US',10,'550e8400-e29b-41d4-a716-446655440000',0,'{"os_api_level":"12","uuid":"59a050e331fe457ab300882db3e2f2c5","ifa":"C3531E71-A803-465C-8923-32A9389E667C","app_version_name":"371","analytics_sdk_build_type":"static","app_build_number":"0","ifv":"189973FE-FE69-40D8-BFC5-5E00744585E4","analytics_sdk_version_name":"3.7.1","locale":"en_US","is_rooted":"1","analytics_sdk_build_number":"0","deviceid":"96A20D12-E5D6-4F36-8886-77B3E56B64C0","os_version":"12.2","app_debuggable":"1","limit_ad_tracking":"0"}',1,10000000001,1);
INSERT INTO "sessions" VALUES (3,1568284188.67252,NULL,1568284200.38984,1568284188.67252,'en_US',9,'20799a27-fa80-4b36-b2db-0f8141f24180',1,'{"os_api_level":"12","uuid":"59a050e331fe457ab300882db3e2f2c5","ifa":"C3531E71-A803-465C-8923-32A9389E667C","app_version_name":"371","analytics_sdk_build_type":"static","app_build_number":"0","ifv":"189973FE-FE69-40D8-BFC5-5E00744585E4","analytics_sdk_version_name":"3.7.1","locale":"en_US","is_rooted":"1","analytics_sdk_build_number":"0","deviceid":"96A20D12-E5D6-4F36-8886-77B3E56B64C0","os_version":"12.2","app_debuggable":"1","limit_ad_tracking":"0"}',1,10000000000,1);
INSERT INTO "sessions" VALUES (4,1568284198.6164,-0.160047054290771,1568284198.62691,1568284198.6164,'en_US',5,'6e0b1717-fe18-4112-a5e9-95102fbf0747',1,'{"os_api_level":"12","uuid":"59a050e331fe457ab300882db3e2f2c5","ifa":"C3531E71-A803-465C-8923-32A9389E667C","app_version_name":"371","analytics_sdk_build_type":"static","app_build_number":"0","ifv":"189973FE-FE69-40D8-BFC5-5E00744585E4","analytics_sdk_version_name":"3.7.1","locale":"en_US","is_rooted":"1","analytics_sdk_build_number":"0","deviceid":"96A20D12-E5D6-4F36-8886-77B3E56B64C0","os_version":"12.2","app_debuggable":"1","limit_ad_tracking":"0"}',1,10000000000,1);
INSERT INTO "sessions" VALUES (5,1568284198.62958,-0.160047054290771,1568284198.63881,1568284228.77062,'en_US',5,'6e0b1717-fe18-4112-a5e9-95102fbf0747',0,'{"os_api_level":"12","uuid":"59a050e331fe457ab300882db3e2f2c5","ifa":"C3531E71-A803-465C-8923-32A9389E667C","app_version_name":"371","analytics_sdk_build_type":"static","app_build_number":"0","ifv":"189973FE-FE69-40D8-BFC5-5E00744585E4","analytics_sdk_version_name":"3.7.1","locale":"en_US","is_rooted":"1","analytics_sdk_build_number":"0","deviceid":"96A20D12-E5D6-4F36-8886-77B3E56B64C0","os_version":"12.2","app_debuggable":"1","limit_ad_tracking":"0"}',0,10000000001,1);
INSERT INTO "sessions" VALUES (6,1568284198.59294,-0.160047054290771,1568284221.69894,1568284221.69894,'en_US',5,'550e8400-e29b-41d4-a716-446655440000',0,'{"os_api_level":"12","uuid":"59a050e331fe457ab300882db3e2f2c5","ifa":"C3531E71-A803-465C-8923-32A9389E667C","app_version_name":"371","analytics_sdk_build_type":"static","app_build_number":"0","ifv":"189973FE-FE69-40D8-BFC5-5E00744585E4","analytics_sdk_version_name":"3.7.1","locale":"en_US","is_rooted":"1","analytics_sdk_build_number":"0","deviceid":"96A20D12-E5D6-4F36-8886-77B3E56B64C0","os_version":"12.2","app_debuggable":"1","limit_ad_tracking":"0"}',1,10000000002,2);
INSERT INTO "sessions" VALUES (7,1568284233.6743,-0.160047054290772,1568284233.6743,1568284233.6743,'en_US',2,'550e8400-e29b-41d4-a716-446655440000',0,'{"os_api_level":"12","uuid":"59a050e331fe457ab300882db3e2f2c5","ifa":"C3531E71-A803-465C-8923-32A9389E667C","app_version_name":"371","analytics_sdk_build_type":"static","app_build_number":"0","ifv":"189973FE-FE69-40D8-BFC5-5E00744585E4","analytics_sdk_version_name":"3.7.1","locale":"en_US","is_rooted":"1","analytics_sdk_build_number":"0","deviceid":"96A20D12-E5D6-4F36-8886-77B3E56B64C0","os_version":"12.2","app_debuggable":"0","limit_ad_tracking":"0"}',1,10000000003,2);
INSERT INTO "sessions" VALUES (8,1568284335.37126,-0.160047054290772,1568284335.37126,1568284335.37126,'en_US',2,'550e8400-e29b-41d4-a716-446655440000',1,'{"os_api_level":"12","uuid":"59a050e331fe457ab300882db3e2f2c5","ifa":"C3531E71-A803-465C-8923-32A9389E667C","app_version_name":"371","analytics_sdk_build_type":"static","app_build_number":"0","ifv":"189973FE-FE69-40D8-BFC5-5E00744585E4","analytics_sdk_version_name":"3.7.1","locale":"en_US","is_rooted":"1","analytics_sdk_build_number":"0","deviceid":"96A20D12-E5D6-4F36-8886-77B3E56B64C0","os_version":"12.2","app_debuggable":"0","limit_ad_tracking":"0"}',1,10000000004,2);
INSERT INTO "sessions" VALUES (9,1568284335.41832,-0.160047054290772,1568284335.41832,1568284339.75976,'en_US',2,'550e8400-e29b-41d4-a716-446655440000',0,'{"os_api_level":"12","uuid":"59a050e331fe457ab300882db3e2f2c5","ifa":"C3531E71-A803-465C-8923-32A9389E667C","app_version_name":"371","analytics_sdk_build_type":"static","app_build_number":"0","ifv":"189973FE-FE69-40D8-BFC5-5E00744585E4","analytics_sdk_version_name":"3.7.1","locale":"en_US","is_rooted":"1","analytics_sdk_build_number":"0","deviceid":"96A20D12-E5D6-4F36-8886-77B3E56B64C0","os_version":"12.2","app_debuggable":"0","limit_ad_tracking":"0"}',0,10000000005,2);
INSERT INTO "sessions" VALUES (10,1568284338.49622,-0.160047054290772,1568284338.49622,1568284338.49622,'en_US',2,'20799a27-fa80-4b36-b2db-0f8141f24180',1,'{"os_api_level":"12","uuid":"59a050e331fe457ab300882db3e2f2c5","ifa":"C3531E71-A803-465C-8923-32A9389E667C","app_version_name":"371","analytics_sdk_build_type":"static","app_build_number":"0","ifv":"189973FE-FE69-40D8-BFC5-5E00744585E4","analytics_sdk_version_name":"3.7.1","locale":"en_US","is_rooted":"1","analytics_sdk_build_number":"0","deviceid":"96A20D12-E5D6-4F36-8886-77B3E56B64C0","os_version":"12.2","app_debuggable":"0","limit_ad_tracking":"0"}',0,10000000001,1);
CREATE TABLE IF NOT EXISTS "kv" (
"k"    STRING NOT NULL,
"v"    STRING NOT NULL DEFAULT '',
PRIMARY KEY("k")
);
INSERT INTO "kv" VALUES ('schema.version',18);
INSERT INTO "kv" VALUES ('old.init.migration.applied',1);
INSERT INTO "kv" VALUES ('library.version','3.7.1');
INSERT INTO "kv" VALUES ('uuid','59a050e331fe457ab300882db3e2f2c5');
INSERT INTO "kv" VALUES ('api.keys.migration.applied',1);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_13.550e8400-e29b-41d4-a716-446655440000',0);
INSERT INTO "kv" VALUES ('550e8400-e29b-41d4-a716-446655440000session_first_event_sent','YES');
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_13.20799a27-fa80-4b36-b2db-0f8141f24180',0);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_1.550e8400-e29b-41d4-a716-446655440000',0);
INSERT INTO "kv" VALUES ('20799a27-fa80-4b36-b2db-0f8141f24180session_first_event_sent','YES');
INSERT INTO "kv" VALUES ('20799a27-fa80-4b36-b2db-0f8141f24180session_update_event_sent','YES');
INSERT INTO "kv" VALUES ('550e8400-e29b-41d4-a716-446655440000session_init_event_sent','YES');
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_5.550e8400-e29b-41d4-a716-446655440000',0);
INSERT INTO "kv" VALUES ('550e8400-e29b-41d4-a716-446655440000session_referrer_event_sent','YES');
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_11.20799a27-fa80-4b36-b2db-0f8141f24180',1);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_21.550e8400-e29b-41d4-a716-446655440000',0);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_13.6e0b1717-fe18-4112-a5e9-95102fbf0747',0);
INSERT INTO "kv" VALUES ('6e0b1717-fe18-4112-a5e9-95102fbf0747session_first_event_sent','YES');
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_27.550e8400-e29b-41d4-a716-446655440000',0);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.profileid.550e8400-e29b-41d4-a716-446655440000','PROFILE_ID');
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_20.550e8400-e29b-41d4-a716-446655440000',1);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_11.6e0b1717-fe18-4112-a5e9-95102fbf0747',0);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_7.6e0b1717-fe18-4112-a5e9-95102fbf0747',0);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.sessions.6e0b1717-fe18-4112-a5e9-95102fbf0747',10000000001);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_2.6e0b1717-fe18-4112-a5e9-95102fbf0747',1);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.attribution.id.550e8400-e29b-41d4-a716-446655440000',2);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_1.6e0b1717-fe18-4112-a5e9-95102fbf0747',0);
INSERT INTO "kv" VALUES ('6e0b1717-fe18-4112-a5e9-95102fbf0747session_init_event_sent','YES');
INSERT INTO "kv" VALUES ('6e0b1717-fe18-4112-a5e9-95102fbf0747session_referrer_is_empty','YES');
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_16.550e8400-e29b-41d4-a716-446655440000',0);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.appenvironment.6e0b1717-fe18-4112-a5e9-95102fbf0747','{"foo":"bar"}');
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_4.6e0b1717-fe18-4112-a5e9-95102fbf0747',2);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_4.550e8400-e29b-41d4-a716-446655440000',3);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.global.6e0b1717-fe18-4112-a5e9-95102fbf0747',9);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_12.6e0b1717-fe18-4112-a5e9-95102fbf0747',0);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.request.identifier.550e8400-e29b-41d4-a716-446655440000',3);
INSERT INTO "kv" VALUES ('libs.last.report.date',1568284200.38964);
INSERT INTO "kv" VALUES ('libs.collecting.enabled',1);
INSERT INTO "kv" VALUES ('libs.collecting.delay.first',0);
INSERT INTO "kv" VALUES ('server.time.offset',-0.160047054290772);
INSERT INTO "kv" VALUES ('location.collecting.hosts','["https:\/\/rosenberg.appmetrica.test.net"]');
INSERT INTO "kv" VALUES ('redirect.host','https://redirect.appmetrica.com');
INSERT INTO "kv" VALUES ('startup.hosts','["https:\/\/unavailable.startup.tst.mobile.appmetrica.net","https:\/\/startup.tst.mobile.appmetrica.net"]');
INSERT INTO "kv" VALUES ('easy.attribution.enabled',0);
INSERT INTO "kv" VALUES ('extensions.reporting.launch.delay',3);
INSERT INTO "kv" VALUES ('startup.first_update.date',1568284190.07959);
INSERT INTO "kv" VALUES ('extensions.reporting.enabled',1);
INSERT INTO "kv" VALUES ('extensions.reporting.interval',120);
INSERT INTO "kv" VALUES ('libs.last.report.buildid',1568284184);
INSERT INTO "kv" VALUES ('initial.country','by');
INSERT INTO "kv" VALUES ('location.collecting.batch.records.count',100);
INSERT INTO "kv" VALUES ('location.collecting.flush.records.count',100);
INSERT INTO "kv" VALUES ('report.hosts','["https:\/\/report.appmetrica.test.net"]');
INSERT INTO "kv" VALUES ('user.info','{"user_id":"USER_ID","type":"USER_TYPE","options":{"foo":"bar"}}');
INSERT INTO "kv" VALUES ('startup.had.first',1);
INSERT INTO "kv" VALUES ('location.collecting.flush.age.max',600);
INSERT INTO "kv" VALUES ('libs.collecting.delay.launch',10);
INSERT INTO "kv" VALUES ('stat.sending.disabled.reporting.interval',86400);
INSERT INTO "kv" VALUES ('location.collecting.store.records.max',5000);
INSERT INTO "kv" VALUES ('location.collecting.update.distance.min',50);
INSERT INTO "kv" VALUES ('location.collecting.update.interval.min',60);
INSERT INTO "kv" VALUES ('extensions.reporting.last.date',1568284194.54097);
INSERT INTO "kv" VALUES ('get_url_schemes.host','http://appmetrica.heroism.com');
INSERT INTO "kv" VALUES ('startup.permissions','[{"name":"NSLocationDescription","enabled":true}]');
INSERT INTO "kv" VALUES ('report_ad.host','https://mobile-ads-beta.appmetrica.io:4443');
INSERT INTO "kv" VALUES ('libs.collecting.interval',120);
INSERT INTO "kv" VALUES ('user.startup.hosts','["https:\/\/startup.tst.mobile.appmetrica.net"]');
INSERT INTO "kv" VALUES ('startup.updated_at',1568284190.23964);
INSERT INTO "kv" VALUES ('location.collecting.enabled',1);
INSERT INTO "kv" VALUES ('get_ad.host','https://mobile-ads-beta.appmetrica.io:4443');
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_7.550e8400-e29b-41d4-a716-446655440000',3);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_26.550e8400-e29b-41d4-a716-446655440000',0);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.sessions.550e8400-e29b-41d4-a716-446655440000',10000000005);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.global.550e8400-e29b-41d4-a716-446655440000',21);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_2.550e8400-e29b-41d4-a716-446655440000',5);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_7.20799a27-fa80-4b36-b2db-0f8141f24180',0);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.sessions.20799a27-fa80-4b36-b2db-0f8141f24180',10000000001);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_2.20799a27-fa80-4b36-b2db-0f8141f24180',1);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.global.20799a27-fa80-4b36-b2db-0f8141f24180',10);
INSERT INTO "kv" VALUES ('com.yandex.mobile.appmetrica.event.number.type_4.20799a27-fa80-4b36-b2db-0f8141f24180',4);
INSERT INTO "kv" VALUES ('550e8400-e29b-41d4-a716-446655440000.state.last.send.date',1568281190.23964);
CREATE TABLE IF NOT EXISTS "events" (
"id"    INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
"created_at"    STRING NOT NULL,
"session_id"    INTEGER NOT NULL,
"seq"    INTEGER NOT NULL,
"global_number"    INTEGER NOT NULL,
"number_of_type"    INTEGER NOT NULL,
"offset"    STRING NOT NULL,
"name"    STRING,
"value"    STRING,
"type"    INTEGER NOT NULL,
"latitude"    DOUBLE,
"longitude"    DOUBLE,
"location_timestamp"    STRING,
"location_horizontal_accuracy"    INTEGER,
"location_vertical_accuracy"    INTEGER,
"location_direction"    INTEGER,
"location_speed"    INTEGER,
"location_altitude"    INTEGER,
"location_enabled"    INTEGER DEFAULT -1,
"error_environment"    STRING,
"app_environment"    STRING,
"user_info"    STRING,
"bytes_truncated"    INTEGER,
"user_profile_id"    STRING,
"encryption_type"    INTEGER NOT NULL,
"first_occurrence"    INTEGER DEFAULT -1
);
INSERT INTO "events" VALUES (1,1568284188.4791,1,0,0,0,0,'','',13,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (2,1568284188.4791,1,1,1,0,0,'','',2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (3,1568284188.4791,1,2,2,0,0,'','',7,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (4,1568284188.62191,2,0,3,1,0,'','',2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (5,1568284188.67252,3,0,0,0,0,'','',13,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (6,1568284188.62191,2,1,4,0,0,'','',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (7,1568284188.67252,3,1,1,0,0,'','',2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (8,1568284188.6972,3,2,2,0,0.024676,'AppleSearchAdsAttempt','',4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,NULL,1,1);
INSERT INTO "events" VALUES (9,1568284188.86305,2,2,5,0,0.241139,'','{"status":"success","data":{"Version3.1":{"iad-purchase-date":"2019-09-12T10:29:48Z","iad-keyword":"Keyword","iad-adgroup-id":"1234567890","iad-creativeset-id":"1234567890","iad-creativeset-name":"CreativeSetName","iad-campaign-id":"1234567890","iad-lineitem-id":"1234567890","iad-org-id":"1234567890","iad-org-name":"OrgName","iad-campaign-name":"CampaignName","iad-keyword-id":"KeywordID","iad-conversion-date":"2019-09-12T10:29:48Z","iad-conversion-type":"Download","iad-country-or-region":"US","iad-click-date":"2019-09-12T10:29:48Z","iad-attribution":"true","iad-adgroup-name":"AdGroupName","iad-lineitem-name":"LineName","iad-keyword-matchtype":"Broad"}}}',5,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (10,1568284188.87105,3,3,3,1,0.198528,'AppleSearchAdsCompletion','{"type":"success"}',4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,NULL,1,1);
INSERT INTO "events" VALUES (11,1568284190.39326,3,4,4,0,1.720744,'provided_request_schedule','{"id":"1"}',11,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (12,1568284190.50448,3,5,5,1,1.831961,'provided_request_schedule','{"id":"2"}',11,37.3316045,-122.03041139,1568284190.47159,30,-1,-1,2.8,0,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (13,1568284194.54125,3,6,6,2,5.868732,'extensions_list','{"extensions":{"com.apple.widget-extension":["io.appmetrica.mobile.MetricaSample.MetricaSampleToday"],"com.apple.photo-editing":["io.appmetrica.mobile.MetricaSample.MetricaSamplePhoto"],"com.apple.keyboard-service":["io.appmetrica.mobile.MetricaSample.MetricaSampleKeyboard"]},"own_type":{"app":""},"app_bundle_id":"io.appmetrica.mobile.MetricaSample"}',4,37.33157962,-122.03054783,1568284193.46648,30,-1,222.05,3.1,0,1,NULL,'','',0,NULL,1,1);
INSERT INTO "events" VALUES (14,1568284198.57149,2,3,6,0,9.949579,'','CAQaA0JZTiIKUFJPRFVDVF9JRCoNeyJmb28iOiJiYXIifTIeCgxSRUNFSVBUX0RBVEEaDlRSQU5TQUNUSU9OX0lEOOC4lQs=',21,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (15,1568284198.57431,2,4,7,0,9.952401,'','ChQKA2ZvbxAAGgQIABAAIgUKA2Jhcg==',20,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (16,1568284198.6164,4,0,0,0,0,'','',13,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (17,1568284198.5771,2,5,8,0,9.955191,'ERROR_NAME','CjMKBTMuMi4wEiRBOTFGOTgzQy0yNkJBLTQwMDktQkIyQy0xMUZGMEZGOTczODQYprzo6wUSgwIIgKDw4BAQgKDYARiHgIAIIAMoADAAOABCwgEvVXNlcnMvYmFteDIzL0xpYnJhcnkvRGV2ZWxvcGVyL0NvcmVTaW11bGF0b3IvRGV2aWNlcy9BQUI2OUExQi00QTM5LTQ1MjEtODE5OC03MUNGM0UxREFGNjEvZGF0YS9Db250YWluZXJzL0J1bmRsZS9BcHBsaWNhdGlvbi81RUVFQ0U0MS1ENTEwLTQwNzgtQjA0Mi1FOEQ1MzM0NTQ2REIvTWV0cmljYVNhbXBsZS5hcHAvTWV0cmljYVNhbXBsZUokMENEOEMzNkItRkU0MC0zQzI3LTg0NzEtMDQzREY1QjYyRUQzEoYCCICgvPUQEICA4AMYh4CACCADKOQBMAA4AELEAS9BcHBsaWNhdGlvbnMvWGNvZGUxMC4yLjEuYXBwL0NvbnRlbnRzL0RldmVsb3Blci9QbGF0Zm9ybXMvaVBob25lT1MucGxhdGZvcm0vRGV2ZWxvcGVyL0xpYnJhcnkvQ29yZVNpbXVsYXRvci9Qcm9maWxlcy9SdW50aW1lcy9pT1Muc2ltcnVudGltZS9Db250ZW50cy9SZXNvdXJjZXMvUnVudGltZVJvb3QvdXNyL2xpYi9saWJvYmpjLkEuZHlsaWJKJDE1ODkzMkRDLThEQzMtMzFFOS05MUJBLUMxRjNBMDUzQTc2NRKwAgiAwN/9EBCAwOMBGIeAgAggAyiiDDAPOABC7gEvQXBwbGljYXRpb25zL1hjb2RlMTAuMi4xLmFwcC9Db250ZW50cy9EZXZlbG9wZXIvUGxhdGZvcm1zL2lQaG9uZU9TLnBsYXRmb3JtL0RldmVsb3Blci9MaWJyYXJ5L0NvcmVTaW11bGF0b3IvUHJvZmlsZXMvUnVudGltZXMvaU9TLnNpbXJ1bnRpbWUvQ29udGVudHMvUmVzb3VyY2VzL1J1bnRpbWVSb290L1N5c3RlbS9MaWJyYXJ5L0ZyYW1ld29ya3MvQ29yZUZvdW5kYXRpb24uZnJhbWV3b3JrL0NvcmVGb3VuZGF0aW9uSiRFMkYwN0U3Qi1FMEZFLTNDQUMtOEUxNy0zQUI2QTEwNDJDNTQSuQIIgMCYjxEQgIAFGIeAgAggAygOMAA4AEL5AS9BcHBsaWNhdGlvbnMvWGNvZGUxMC4yLjEuYXBwL0NvbnRlbnRzL0RldmVsb3Blci9QbGF0Zm9ybXMvaVBob25lT1MucGxhdGZvcm0vRGV2ZWxvcGVyL0xpYnJhcnkvQ29yZVNpbXVsYXRvci9Qcm9maWxlcy9SdW50aW1lcy9pT1Muc2ltcnVudGltZS9Db250ZW50cy9SZXNvdXJjZXMvUnVudGltZVJvb3QvU3lzdGVtL0xpYnJhcnkvUHJpdmF0ZUZyYW1ld29ya3MvR3JhcGhpY3NTZXJ2aWNlcy5mcmFtZXdvcmsvR3JhcGhpY3NTZXJ2aWNlc0okMzUwQjExNTctMjBGMC0zRDIzLUE3RTMtMEM2NjNGRTEyOEFFEp0CCICA3KAREICgEBiHgIAIIAMo8Acw+gE4B0LbAS9BcHBsaWNhdGlvbnMvWGNvZGUxMC4yLjEuYXBwL0NvbnRlbnRzL0RldmVsb3Blci9QbGF0Zm9ybXMvaVBob25lT1MucGxhdGZvcm0vRGV2ZWxvcGVyL0xpYnJhcnkvQ29yZVNpbXVsYXRvci9Qcm9maWxlcy9SdW50aW1lcy9pT1Muc2ltcnVudGltZS9Db250ZW50cy9SZXNvdXJjZXMvUnVudGltZVJvb3QvdXNyL2xpYi9zeXN0ZW0vaW50cm9zcGVjdGlvbi9saWJkaXNwYXRjaC5keWxpYkokMjA0MkQ2RTEtQzE0NS0zQkYwLThBQzgtNjczMjc5MzMwN0E3EooCCIDg+aAREIDAChiHgIAIIAMoigUwAzgDQskBL0FwcGxpY2F0aW9ucy9YY29kZTEwLjIuMS5hcHAvQ29udGVudHMvRGV2ZWxvcGVyL1BsYXRmb3Jtcy9pUGhvbmVPUy5wbGF0Zm9ybS9EZXZlbG9wZXIvTGlicmFyeS9Db3JlU2ltdWxhdG9yL1Byb2ZpbGVzL1J1bnRpbWVzL2lPUy5zaW1ydW50aW1lL0NvbnRlbnRzL1Jlc291cmNlcy9SdW50aW1lUm9vdC91c3IvbGliL3N5c3RlbS9saWJkeWxkLmR5bGliSiQ2NDIxRjdGQi1COEJCLTM5ODYtOTk1QS02MzM4MzYwRTZDNTISrgIIgIDR5xEQgKDrCBiHgIAIIAMoyNwDMAA4AELrAS9BcHBsaWNhdGlvbnMvWGNvZGUxMC4yLjEuYXBwL0NvbnRlbnRzL0RldmVsb3Blci9QbGF0Zm9ybXMvaVBob25lT1MucGxhdGZvcm0vRGV2ZWxvcGVyL0xpYnJhcnkvQ29yZVNpbXVsYXRvci9Qcm9maWxlcy9SdW50aW1lcy9pT1Muc2ltcnVudGltZS9Db250ZW50cy9SZXNvdXJjZXMvUnVudGltZVJvb3QvU3lzdGVtL0xpYnJhcnkvUHJpdmF0ZUZyYW1ld29ya3MvVUlLaXRDb3JlLmZyYW1ld29yay9VSUtpdENvcmVKJDJFNzczRDU3LUQxMkItMzRGNS1CQTJFLTJBQTdENkRDMjE5RBquAwphRGFyd2luIEtlcm5lbCBWZXJzaW9uIDE4LjcuMDogVGh1IEp1biAyMCAxODo0MjoyMSBQRFQgMjAxOTsgcm9vdDp4bnUtNDkwMy4yNzAuNDd+NC9SRUxFQVNFX1g4Nl82NBIFMThHODQYj5Dg6wUgnLzo6wUqwgEvVXNlcnMvYmFteDIzL0xpYnJhcnkvRGV2ZWxvcGVyL0NvcmVTaW11bGF0b3IvRGV2aWNlcy9BQUI2OUExQi00QTM5LTQ1MjEtODE5OC03MUNGM0UxREFGNjEvZGF0YS9Db250YWluZXJzL0J1bmRsZS9BcHBsaWNhdGlvbi81RUVFQ0U0MS1ENTEwLTQwNzgtQjA0Mi1FOEQ1MzM0NTQ2REIvTWV0cmljYVNhbXBsZS5hcHAvTWV0cmljYVNhbXBsZTIDeDg2OAdACEiHgIAIUANaDU1ldHJpY2FTYW1wbGVg5yxo6CxwAXiAwILBxg6CAREIgICAgEAQgKCFzjIYgKCVRYoBLggAEAAYACAAKQAAAAAAAAAAMQAAAAAAAAAAOABBAAAAAAAAAABJAAAAAAAAAAAimQgKRgj7jaj+EBIGUkVBU09OGAMiBggKEAAYACoECAYQADIkCg5FWENFUFRJT04gTkFNRRISewogICAgZm9vID0gYmFyOwp9OgASzgcKxwcKOQj7jaj+EBIOQ29yZUZvdW5kYXRpb24YgMDf/RAiFV9fZXhjZXB0aW9uUHJlcHJvY2Vzcyiwi6j+EAo5CMW1vfUQEg9saWJvYmpjLkEuZHlsaWIYgKC89RAiFG9iamNfZXhjZXB0aW9uX3Rocm93KJW1vfUQCjgI6YSo/hASDkNvcmVGb3VuZGF0aW9uGIDA3/0QIhQtW05TRXhjZXB0aW9uIHJhaXNlXSjghKj+EAp4CP2EguEQEg1NZXRyaWNhU2FtcGxlGICg8OAQIlVfXzY4LVtNTVNNZXRyaWNhRXh0ZW5kZWRTYW1wbGVIYW5kbGVyIGFjdGl2YXRlTWV0cmljYVdpdGhDb25maWd1cmF0aW9uOl1fYmxvY2tfaW52b2tlKJD9geEQCj8ItfvcoBESEWxpYmRpc3BhdGNoLmR5bGliGICA3KARIhhfZGlzcGF0Y2hfY2xpZW50X2NhbGxvdXQorfvcoBEKQQiV2d2gERIRbGliZGlzcGF0Y2guZHlsaWIYgIDcoBEiGl9kaXNwYXRjaF9jb250aW51YXRpb25fcG9wKO3U3aARCj4Ik53ioBESEWxpYmRpc3BhdGNoLmR5bGliGICA3KARIhdfZGlzcGF0Y2hfc291cmNlX2ludm9rZSjKi+KgEQpICK2d4KAREhFsaWJkaXNwYXRjaC5keWxpYhiAgNygESIhX2Rpc3BhdGNoX21haW5fcXVldWVfY2FsbGJhY2tfNENGKPyU4KARClYIqfGB/hASDkNvcmVGb3VuZGF0aW9uGIDA3/0QIjJfX0NGUlVOTE9PUF9JU19TRVJWSUNJTkdfVEhFX01BSU5fRElTUEFUQ0hfUVVFVUVfXyig8YH+EAoyCNa+gP4QEg5Db3JlRm91bmRhdGlvbhiAwN/9ECIOX19DRlJ1bkxvb3BSdW4o0KyA/hAKOAiCpoD+EBIOQ29yZUZvdW5kYXRpb24YgMDf/RAiFENGUnVuTG9vcFJ1blNwZWNpZmljKJChgP4QCjUI/sWbjxESEEdyYXBoaWNzU2VydmljZXMYgMCYjxEiD0dTRXZlbnRSdW5Nb2RhbCi9xZuPEQowCKK3pOwREglVSUtpdENvcmUYgIDR5xEiEVVJQXBwbGljYXRpb25NYWluKJa2pOwRCicI0vTz4BASDU1ldHJpY2FTYW1wbGUYgKDw4BAiBG1haW4o0PPz4BAKKAjBivqgERINbGliZHlsZC5keWxpYhiA4PmgESIFc3RhcnQowIr6oBEKCwgBEgM/Pz8YACgAIAAoAQ==',27,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,'{"foo":"bar"}','','',0,NULL,1,-1);
INSERT INTO "events" VALUES (18,1568284198.6164,4,1,1,0,0,'','',2,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (19,1568284198.58189,2,6,9,0,9.959978,'EVENT_1','{"foo":"bar"}',4,37.33155419,-122.03068145,1568284196.46777,30,10,241.62,4.14,23.15,1,NULL,'','',0,NULL,1,1);
INSERT INTO "events" VALUES (20,1568284198.62395,4,2,2,0,0.007553,'EVENT_R_1','{"foo":"bar"}',4,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,NULL,1,1);
INSERT INTO "events" VALUES (21,1568284198.58526,2,7,10,1,9.963353,'','',20,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,'PROFILE_ID',1,-1);
INSERT INTO "events" VALUES (22,1568284198.62691,4,3,3,0,0.010512,'STATBOX_NAME','STATBOX_VALUE',11,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (23,1568284198.58919,2,8,11,1,9.967276,'EVENT_2','{"foo":"bar"}',4,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,'PROFILE_ID',1,1);
INSERT INTO "events" VALUES (24,1568284198.62691,4,4,4,0,0.01051,'','',7,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (25,1568284198.59294,2,9,12,1,9.971033,'','',7,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,'PROFILE_ID',1,-1);
INSERT INTO "events" VALUES (26,1568284198.62958,5,0,5,1,0,'','',2,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (27,1568284198.59294,6,0,13,2,0,'','',2,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,'PROFILE_ID',1,-1);
INSERT INTO "events" VALUES (28,1568284198.62958,5,1,6,0,0,'','',1,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (29,1568284198.59294,6,1,14,0,0,'','{"link":"https:\/\/ya.ru?referrer=reattribution%3D1","type":"open"}',16,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,'PROFILE_ID',1,-1);
INSERT INTO "events" VALUES (30,1568284198.63243,5,2,7,1,0.00285,'EVENT_R_2','{"foo":"bar"}',4,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,NULL,1,1);
INSERT INTO "events" VALUES (31,1568284198.59956,6,2,15,2,0.006623,'EVENT_3','{"foo":"bar"}',4,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,'PROFILE_ID',1,1);
INSERT INTO "events" VALUES (32,1568284198.63736,5,3,8,2,0.007782,'EVENT_R_3','{"foo":"bar"}',4,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'{"foo":"bar"}','',0,NULL,1,1);
INSERT INTO "events" VALUES (33,1568284198.60823,6,3,16,3,0.015288,'EVENT_4','{"foo":"bar"}',4,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'','',0,'PROFILE_ID',1,1);
INSERT INTO "events" VALUES (34,1568284198.63881,5,4,9,0,0.009234,'','{"foo":"bar"}',12,37.33155419,-122.03068145,1568284196.46777,30,-1,241.62,4.14,0,1,NULL,'{"foo":"bar"}','{"user_id":"USER_ID","type":"USER_TYPE","options":{"foo":"bar"}}',0,NULL,1,-1);
INSERT INTO "events" VALUES (35,1568284200.38984,3,7,7,3,11.717317,'sdk_list','{"AppMetrica":{"classes":["AMAAppMetrica","AMAAppMetricaConfiguration"]}}',4,37.33144466,-122.03075535,1568284199.46924,30,-1,180.98,6.01,0,1,NULL,'','',0,NULL,1,1);
INSERT INTO "events" VALUES (36,1568284221.69894,6,4,17,2,23.106,'','',7,37.33045275,-122.02953296,1568284233.59097,10,-1,90.99,7.22,0,1,NULL,'','',0,'PROFILE_ID',1,-1);
INSERT INTO "events" VALUES (37,1568284233.6743,7,0,18,3,0,'','',2,37.33045275,-122.02953296,1568284230.47521,10,-1,90.99,7.22,0,1,NULL,'','',0,'PROFILE_ID',1,-1);
INSERT INTO "events" VALUES (38,1568284233.6743,7,1,19,3,0,'','',7,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,'PROFILE_ID',1,-1);
INSERT INTO "events" VALUES (39,1568284335.37126,8,0,20,4,0,'','',2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,'PROFILE_ID',1,-1);
INSERT INTO "events" VALUES (40,1568284335.37126,8,1,0,0,0,'','015EFEA0-FA89-44EC-BBFB-FD429BF01EF6',26,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,'PROFILE_ID',1,-1);
INSERT INTO "events" VALUES (41,1568284335.41832,9,0,21,5,0,'','',2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,'','',0,'PROFILE_ID',1,-1);
INSERT INTO "events" VALUES (42,1568284200.38984,3,8,8,0,11.71732,'','',7,37.33159275,-122.03051033,1568284335.83325,30,-1,254.74,3.58,0,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (43,1568284338.49622,10,0,9,1,0,'','',2,37.33159275,-122.03051033,1568284335.83325,30,-1,254.74,3.58,0,1,NULL,'','',0,NULL,1,-1);
INSERT INTO "events" VALUES (44,1568284338.49622,10,1,10,4,0,'extensions_list','{"extensions":{"com.apple.widget-extension":["io.appmetrica.mobile.MetricaSample.MetricaSampleToday"],"com.apple.photo-editing":["io.appmetrica.mobile.MetricaSample.MetricaSamplePhoto"],"com.apple.keyboard-service":["io.appmetrica.mobile.MetricaSample.MetricaSampleKeyboard"]},"own_type":{"app":""},"app_bundle_id":"io.appmetrica.mobile.MetricaSample"}',4,37.33159275,-122.03051033,1568284335.83325,30,-1,254.74,3.58,0,1,NULL,'','',0,NULL,1,0);
CREATE INDEX IF NOT EXISTS "events_created_at" ON "events" (
"created_at"    ASC
);
CREATE INDEX IF NOT EXISTS "events_session_id" ON "events" (
"session_id"
);
COMMIT;
