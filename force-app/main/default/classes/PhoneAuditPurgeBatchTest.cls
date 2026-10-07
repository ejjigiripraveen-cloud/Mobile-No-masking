@IsTest
private class PhoneAuditPurgeBatchTest {
    private static Phone_Access_Audit__c auditRow(String channel) {
        return new Phone_Access_Audit__c(
            Action__c = 'Dial', Outcome__c = 'Success', Channel__c = channel,
            Masked_Number__c = '98XXXXXX21', User__c = UserInfo.getUserId(), Event_Time__c = System.now()
        );
    }

    @IsTest
    static void deletesOnlyRowsOlderThanRetention() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        List<Phone_Access_Audit__c> rows = new List<Phone_Access_Audit__c>();
        for (Integer i = 0; i < 200; i++) {
            rows.add(auditRow(i < 150 ? 'old' : 'recent'));
        }
        insert rows;
        for (Phone_Access_Audit__c row : rows) {
            if (row.Channel__c == 'old') {
                Test.setCreatedDate(row.Id, System.now().addDays(-400));
            } else {
                Test.setCreatedDate(row.Id, System.now().addDays(-100));
            }
        }

        Test.startTest();
        Database.executeBatch(new PhoneAuditPurgeBatch(), 2000);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Phone_Access_Audit__c WHERE Channel__c = 'old'], 'Older than 365 days deleted');
        Assert.areEqual(50, [SELECT COUNT() FROM Phone_Access_Audit__c WHERE Channel__c = 'recent'], 'Recent rows kept');
    }

    @IsTest
    static void usesConfiguredRetention() {
        Phone_Masking_Setting__mdt setting = PhoneMaskingConfig.defaultSetting();
        setting.Audit_Retention_Days__c = 30;
        PhoneMaskingConfig.settingOverride = setting;
        Phone_Access_Audit__c row = auditRow('mid');
        insert row;
        Test.setCreatedDate(row.Id, System.now().addDays(-60));

        Test.startTest();
        Database.executeBatch(new PhoneAuditPurgeBatch());
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Phone_Access_Audit__c], '60-day-old row deleted with 30-day retention');
    }

    @IsTest
    static void defaultRetentionWhenSettingInvalid() {
        Phone_Masking_Setting__mdt setting = PhoneMaskingConfig.defaultSetting();
        setting.Audit_Retention_Days__c = 0;
        PhoneMaskingConfig.settingOverride = setting;
        Assert.areEqual(365, PhoneAuditPurgeBatch.retentionDays());
    }

    @IsTest
    static void schedulesNightlyAndRunsFromSchedule() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();

        Test.startTest();
        Id jobId = PhoneAuditPurgeBatch.scheduleNightly();
        new PhoneAuditPurgeBatch().execute((SchedulableContext) null);
        Test.stopTest();

        CronTrigger cron = [SELECT CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(PhoneAuditPurgeBatch.NIGHTLY_CRON, cron.CronExpression);
    }
}
