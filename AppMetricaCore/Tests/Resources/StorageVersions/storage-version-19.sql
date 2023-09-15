BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "kv" (
"k"    STRING NOT NULL,
"v"    STRING NOT NULL DEFAULT '',
PRIMARY KEY("k")
);
INSERT INTO "kv" VALUES ('schema.version',19);
INSERT INTO "kv" VALUES ('old.init.migration.applied',1);
INSERT INTO "kv" VALUES ('library.version','3.8.0');
INSERT INTO "kv" VALUES ('uuid','59a050e331fe457ab300882db3e2f2c5');
INSERT INTO "kv" VALUES ('api.keys.migration.applied',1);
INSERT INTO "kv" VALUES ('libs.last.report.date',1568284200.38964);
INSERT INTO "kv" VALUES ('libs.collecting.enabled',1);
INSERT INTO "kv" VALUES ('libs.collecting.delay.first',0);
INSERT INTO "kv" VALUES ('server.time.offset',-0.160047054290772);
INSERT INTO "kv" VALUES ('location.collecting.hosts','["https:\/\/rosenberg.appmetrica.test.net"]');
INSERT INTO "kv" VALUES ('redirect.host','https://redirect.appmetrica.com');
INSERT INTO "kv" VALUES ('startup.hosts','["https:\/\/unavailable.startup.tst.mobile.appmetrica.net","https:\/\/startup.tst.mobile.appmetrica.net"]');
INSERT INTO "kv" VALUES ('extensions.reporting.launch.delay',3);
INSERT INTO "kv" VALUES ('startup.first_update.date',1568284190.07959);
INSERT INTO "kv" VALUES ('extensions.reporting.enabled',1);
INSERT INTO "kv" VALUES ('extensions.reporting.interval',120);
INSERT INTO "kv" VALUES ('libs.last.report.buildid',1568284184);
INSERT INTO "kv" VALUES ('initial.country','by');
INSERT INTO "kv" VALUES ('location.collecting.batch.records.count',100);
INSERT INTO "kv" VALUES ('location.collecting.flush.records.count',100);
INSERT INTO "kv" VALUES ('report.hosts','["https:\/\/report.appmetrica.test.net"]');
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
INSERT INTO "kv" VALUES ('fallback-keychain-AMAMetricaPersistentConfigurationDeviceIDStorageKey','8B1C3660-9F81-4FC4-A720-85032F5F9849');
INSERT INTO "kv" VALUES ('fallback-keychain-AMAMetricaPersistentConfigurationDeviceIDHashStorageKey','1.52152921444808e+19');
COMMIT;
