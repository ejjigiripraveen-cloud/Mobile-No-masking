/**
 * @description Mobile number masking (v1.6.0): deletes Phone_Access_Audit__c rows older than the retention period
 *              (Phone_Masking_Setting__mdt.Audit_Retention_Days__c, default 365). Runs as a batch; also Schedulable so
 *              it can run nightly: PhoneAuditPurgeBatch.scheduleNightly() (02:00 every day).
 *              "without sharing" on purpose: audit rows are private to the user who created them, and the purge must
 *              remove every old row whoever owns it. It only ever deletes audit rows past the retention period.
 * @group       Phone Masking
 */
public without sharing class PhoneAuditPurgeBatch implements Database.Batchable<SObject>, Schedulable {
    public static final String JOB_NAME = 'Phone Access Audit purge (nightly)';
    public static final String NIGHTLY_CRON = '0 0 2 * * ?';
    private static final Integer DEFAULT_RETENTION_DAYS = 365;
    private static final Integer BATCH_SIZE = 2000;

    public Database.QueryLocator start(Database.BatchableContext context) {
        Datetime cutoff = System.now().addDays(-retentionDays());
        return Database.getQueryLocator([SELECT Id FROM Phone_Access_Audit__c WHERE CreatedDate < :cutoff]);
    }

    public void execute(Database.BatchableContext context, List<Phone_Access_Audit__c> scope) {
        delete scope;
    }

    public void finish(Database.BatchableContext context) {
        System.debug(LoggingLevel.INFO, 'Phone Access Audit purge finished; retention ' + retentionDays() + ' days.');
    }

    /**
     * @description Schedulable entry point: starts the batch.
     */
    public void execute(SchedulableContext context) {
        Database.executeBatch(new PhoneAuditPurgeBatch(), BATCH_SIZE);
    }

    /**
     * @description Schedules the nightly purge (02:00). Run once after deployment, e.g. from Execute Anonymous.
     */
    public static Id scheduleNightly() {
        return System.schedule(JOB_NAME, NIGHTLY_CRON, new PhoneAuditPurgeBatch());
    }

    @TestVisible
    private static Integer retentionDays() {
        Decimal days = PhoneMaskingConfig.getSetting().Audit_Retention_Days__c;
        return (days == null || days < 1) ? DEFAULT_RETENTION_DAYS : days.intValue();
    }
}
