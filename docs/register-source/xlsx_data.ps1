# Data for the component register. Dot-sourced by build_xlsx.ps1.
$asOf = '2026-10-06'
$D1 = '0Afft000000LO8zCAG'
$D2 = '0Afft000000LRq1CAG'
$D2P = '0Afft000000LRzhCAG'

# ---------------- NEW COMPONENTS ----------------
$new = New-Object System.Collections.ArrayList
function N($part, $ver, $type, $api, $parent, $what, $test, $status, $dep, $prod, $notes) {
    [void]$new.Add(@($part, $ver, $type, $api, $parent, $what, $test, $status, $dep, $prod, $notes))
}
$P1 = 'Part 1'; $V1 = 'v1.1.0'; $S1 = 'Deployed (Sandbox)'
N $P1 $V1 'Custom Metadata Type' 'Phone_Masking_Setting__mdt' '' 'Masking settings: format, reveal seconds, retention, kill switches' '' $S1 $D1 'Yes' ''
foreach ($f in @(
    @('Visible_Prefix_Digits__c','Digits shown at start (2)'), @('Visible_Suffix_Digits__c','Digits shown at end (2)'),
    @('Mask_Character__c','Mask character (X)'), @('Country_Code_To_Strip__c','Country code removed (91)'),
    @('Reveal_Seconds__c','Reveal duration (30)'), @('Audit_Retention_Days__c','Audit retention (365)'),
    @('Resolve_Enabled__c','Kill switch: real number lookup on/off'), @('Audit_Enabled__c','Audit on/off'))) {
    N $P1 $V1 'Custom Field' $f[0] 'Phone_Masking_Setting__mdt' $f[1] '' $S1 $D1 'Yes' ''
}
N $P1 $V1 'Custom Metadata Type' 'Masked_Phone_Field__mdt' '' 'Approved list of phone fields that may be dialed / revealed' '' $S1 $D1 'Yes' ''
foreach ($f in @(
    @('Object_API_Name__c','Object, e.g. Lead'), @('Field_API_Name__c','Field, e.g. Phone__c'), @('Display_Label__c','Label in panel'),
    @('Sort_Order__c','Display order'), @('Allow_Dial__c','May be dialed'), @('Allow_Reveal__c','May be revealed'), @('Active__c','Active'))) {
    N $P1 $V1 'Custom Field' $f[0] 'Masked_Phone_Field__mdt' $f[1] '' $S1 $D1 'Yes' ''
}
N $P1 $V1 'Custom Metadata Record' 'Phone_Masking_Setting.Default' 'Phone_Masking_Setting__mdt' 'Default settings record (2 / 2 / X / 91 / 30 / 365 / on / on)' '' $S1 $D1 'Yes' ''
N $P1 $V1 'Custom Metadata Record' 'Masked_Phone_Field.Lead_Phone' 'Masked_Phone_Field__mdt' 'Approves Lead.Phone__c (Primary)' '' $S1 $D1 'Yes' ''
N $P1 $V1 'Custom Metadata Record' 'Masked_Phone_Field.Lead_Secondary_Phone' 'Masked_Phone_Field__mdt' 'Approves Lead.Secondary_Phone__c (Secondary)' '' $S1 $D1 'Yes' ''
N $P1 $V1 'Custom Object' 'Phone_Access_Audit__c' '' 'Audit trail of every dial / reveal / search (masked number only); Private' '' $S1 $D1 'Yes' ''
foreach ($f in @('Action__c','Outcome__c','User__c','Record_Id__c','Object_Name__c','Field_Key__c','Masked_Number__c','Channel__c','Reason__c','Message__c','Event_Time__c')) {
    N $P1 $V1 'Custom Field' $f 'Phone_Access_Audit__c' 'Audit field' '' $S1 $D1 'Yes' ''
}
N $P1 $V1 'List View' 'Phone_Access_Audit__c.All' 'Phone_Access_Audit__c' 'All audit rows' '' $S1 $D1 'Yes' ''
N $P1 $V1 'Custom Tab' 'Phone_Access_Audit__c' '' 'Phone Access Audits tab' '' $S1 $D1 'Yes' ''
N $P1 $V1 'Apex Class' 'PhoneMaskingConfig' '' 'Reads masking settings and approved field list' 'PhoneMaskingConfigTest' $S1 $D1 'Yes' 'Coverage 98.2%'
N $P1 $V1 'Apex Class' 'PhoneMaskUtil' '' 'Masks numbers (98XXXXXX21), also inside free text' 'PhoneMaskUtilTest' $S1 $D1 'Yes' 'Coverage 100%'
N $P1 $V1 'Apex Class' 'MaskedDialService' '' 'Secure real-number lookup for dialers; access check; audit' 'MaskedDialServiceTest' $S1 $D1 'Yes' 'Coverage 100%'
N $P1 $V1 'Apex Class' 'MaskedDialServiceCTI' '' 'Open CTI entry point (global webservice) for softphones' 'MaskedDialServiceCTITest' $S1 $D1 'Yes' 'Coverage 93.5%'
foreach ($t in @('PhoneTestDataFactory','PhoneMaskingConfigTest','PhoneMaskUtilTest','MaskedDialServiceTest','MaskedDialServiceCTITest')) {
    N $P1 $V1 'Apex Class (test)' $t '' 'Test class / test data factory (no SeeAllData)' '' $S1 $D1 'Yes' ''
}
N $P1 $V1 'Permission Set' 'Phone_Access_Audit_Viewer' '' 'Read-only audit access + tab for admins' '' $S1 $D1 'Yes' 'Assign to admins after deploy'

$P2 = 'Part 2'; $V2 = 'v1.2.0'
N $P2 $V2 'Apex Class' 'MaskedPhonePanelController' '' 'Returns masked numbers only to the panel (1 query, no DML)' 'MaskedPhonePanelControllerTest' $S1 $D2 'Yes' 'Coverage 100%'
N $P2 $V2 'Apex Class (test)' 'MaskedPhonePanelControllerTest' '' '11 tests' '' $S1 $D2 'Yes' ''
N $P2 $V2 'Lightning Web Component' 'maskedPhonePanel' '' 'Masked phone panel on Lead page; optional click-to-dial (desktop)' 'Jest (2 files, not deployed)' $S1 $D2 'Yes' 'Jest needs Node.js locally'
N $P2 $V2 'Lightning Page' 'Sales_Lead_Record_Page_Masked_POC' '' 'Copy of Sales_Lead_Record_Page + masked panel; POC profile only' '' $S1 $D2 'Pilot only' 'Deleted after go-live (Part 11)'
N $P2 $V2 'Profile' 'POC Masked Rep' '' 'Clone of Presales outbound, 25 phone fields hidden, panel class access' '' 'Deployed (Sandbox)' $D2P 'Pilot only (decide)' 'Cloned manually in Setup; overlay deployed'
N $P2 $V2 'User (data)' 'POC MCube Rep' '' 'Test user, MCube call center' '' 'Sandbox only' '005ft000000YFsfAAG' 'No' ''
N $P2 $V2 'User (data)' 'POC SlashRTC Rep' '' 'Test user, SlashRTC call center' '' 'Sandbox only' '005ft000000YFuHAAW' 'No' ''

$P3 = 'Part 3'; $V3 = 'v1.3.0'
N $P3 $V3 'Apex Class (test)' 'McubeMaskedClickToCallTest' '' 'Tests the new MCube masked click-to-dial method (mocked callout)' '' 'Planned' '' 'Yes' 'New class so the existing test class stays untouched'
N $P3 $V3 'Profile (update of new)' 'POC Masked Rep' '' 'Add class access: MaskedDialServiceCTI (SlashRTC runApex)' '' 'Planned' '' 'Pilot only (decide)' ''
N $P3 $V3 'Lightning Page (update of new)' 'Sales_Lead_Record_Page_Masked_POC' '' 'Turn panel property Enable click-to-dial = true' '' 'Planned' '' 'Pilot only' ''
N $P3 $V3 'Lightning Message Channel' 'MaskedDialRequest__c' '' 'Fallback Option A only: panel sends {recordId, fieldKey} to adapters' '' 'Conditional' '' 'Conditional' 'Only if POC shows masked click-to-dial fails'

$P4 = 'Part 4'; $V4 = 'v1.4.0'
N $P4 $V4 'Custom Field' 'Phone_Entry__c' 'Lead' 'Entry field for primary number; copied to Phone__c and cleared' '' 'Planned' '' 'Yes' ''
N $P4 $V4 'Custom Field' 'Secondary_Phone_Entry__c' 'Lead' 'Entry field for secondary number' '' 'Planned' '' 'Yes' ''
N $P4 $V4 'Apex Class' 'LeadPhoneEntryHandler' '' 'Copies entry fields, locks primary after creation' 'LeadPhoneEntryHandlerTest' 'Planned' '' 'Yes' ''
N $P4 $V4 'Apex Class (test)' 'LeadPhoneEntryHandlerTest' '' 'Tests incl. 200-record bulk' '' 'Planned' '' 'Yes' ''

$P5 = 'Part 5'; $V5 = 'v1.5.0'
N $P5 $V5 'Custom Field' 'Phone_Masked__c' 'Lead' 'Formula: masked primary for layouts / list views / reports' '' 'Planned' '' 'Yes' ''
N $P5 $V5 'Custom Field' 'Secondary_Phone_Masked__c' 'Lead' 'Formula: masked secondary' '' 'Planned' '' 'Yes' ''
N $P5 $V5 'Custom Field' 'Call_To_Masked__c' 'Call_Detail__c' 'Formula: masked call number' '' 'Planned' '' 'Yes' ''

$P6 = 'Part 6'; $V6 = 'v1.6.0'
N $P6 $V6 'Apex Class' 'PhoneRevealService' '' 'Reveal for TL / Head / Admin: reason, 30 s, audit' 'PhoneRevealServiceTest' 'Planned' '' 'Yes' ''
N $P6 $V6 'Apex Class (test)' 'PhoneRevealServiceTest' '' '' '' 'Planned' '' 'Yes' ''
N $P6 $V6 'Custom Field' 'Reveal_Reason__c' 'Phone_Access_Audit__c' 'Picklist, 7 agreed reasons' '' 'Planned' '' 'Yes' ''
N $P6 $V6 'Custom Permission' 'Reveal_Phone_Number' '' 'Who may reveal' '' 'Planned' '' 'Yes' ''
N $P6 $V6 'Permission Set' 'Phone_Number_Reveal' '' 'Grants Reveal_Phone_Number to TL / Head / Admin' '' 'Planned' '' 'Yes' ''
N $P6 $V6 'Apex Class' 'PhoneAuditPurgeBatch' '' 'Nightly delete of audit rows older than 1 year (batch + schedulable)' 'PhoneAuditPurgeBatchTest' 'Planned' '' 'Yes' 'Schedule after deploy'
N $P6 $V6 'Apex Class (test)' 'PhoneAuditPurgeBatchTest' '' '' '' 'Planned' '' 'Yes' ''
N $P6 $V6 'Lightning Web Component (update)' 'maskedPhonePanel' '' 'Add Reveal button + reason picker' '' 'Planned' '' 'Yes' ''

$P7 = 'Part 7'; $V7 = 'v1.7.0'
N $P7 $V7 'Apex Class' 'FreeTextMaskService' '' 'Masks numbers typed in free text on save' 'FreeTextMaskServiceTest' 'Planned' '' 'Yes' 'Permanent masking'
N $P7 $V7 'Apex Class (test)' 'FreeTextMaskServiceTest' '' '' '' 'Planned' '' 'Yes' ''
N $P7 $V7 'Apex Trigger' 'FeedItemPhoneMaskTrigger' 'FeedItem' 'Masks numbers in Chatter posts' 'FreeTextMaskServiceTest' 'Planned' '' 'Yes' ''

$P8 = 'Part 8'; $V8 = 'v1.8.0'
N $P8 $V8 'Lightning Web Component' 'findByNumber' '' 'Search a number, masked result, audited' 'Jest' 'Conditional' '' 'Conditional' 'Only if POC shows global search breaks'
N $P8 $V8 'Apex Class' 'FindByNumberController' '' 'Server side of findByNumber' 'FindByNumberControllerTest' 'Conditional' '' 'Conditional' ''
N $P8 $V8 'Apex Class (test)' 'FindByNumberControllerTest' '' '' '' 'Conditional' '' 'Conditional' ''

$P11 = 'Part 11'; $V11 = 'v2.0.0'
N $P11 $V11 'Permission Set' 'Phone_Number_Full_Access' '' 'Full phone-field access for integration users' '' 'Planned' '' 'Yes' 'Assign to integration users'

$PS = 'Security fix'; $VS = 'optional'
N $PS $VS 'Named Credential' 'MCube_API' '' 'MCube endpoint + key over HTTPS instead of hard-coded token / http' '' 'Planned' '' 'Yes (optional)' 'Separate approval'

# ---------------- EXISTING COMPONENTS ----------------
$ex = New-Object System.Collections.ArrayList
function E($part, $ver, $type, $api, $change, $why, $approval, $backup, $status, $prod, $notes) {
    [void]$ex.Add(@($part, $ver, $type, $api, $change, $why, $approval, $backup, $status, $prod, $notes))
}
E $P2 $V2 'Lightning App (assignment)' 'Pre_Sales (Gsquare Housing)' 'One new page-assignment row: Lead, Pre Sales, desktop, POC Masked Rep -> masked page' 'Show the masked page to POC users only' 'Approved 2026-10-05' 'Commit 1adf63f (snapshot)' 'Done (Sandbox, App Builder)' 'Pilot only (manual)' 'App cannot be deployed by metadata (duplicate Analytics Cloud profile names)'
E $P3 $V3 'Visualforce Page' 'mcubeSoftphoneCTIAddOn' 'In onClickToDial: if the click comes from the masked panel, call the new server method with recordId + fieldKey' 'MCube receives 98XXXXXX21, which it cannot dial' 'Pending approval' 'backup/v1.3.0-pre-change' 'Planned' 'Yes' 'Normal clicks unchanged'
E $P3 $V3 'Apex Class' 'McubeSoftphoneAddOnController' 'Add new @RemoteAction clickToCallMasked(recordId, fieldKey): resolves via MaskedDialService, then reuses clickToCallRemote' 'Real number resolved on the server, never in the browser' 'Pending approval' 'backup/v1.3.0-pre-change' 'Planned' 'Yes' 'Existing methods not edited'
E $P3 $V3 'Aura Component' 'slashPhone (slashPhoneHelper.js)' 'In onClickToDial listener: if masked click, runApex MaskedDialServiceCTI.resolveForDial, then continue existing flow' 'SlashRTC receives 98XXXXXX21' 'Pending approval' 'backup/v1.3.0-pre-change' 'Planned' 'Yes' 'Number exists briefly inside the SlashRTC softphone (vendor limitation)'
E $P3 $V3 'Call Center' 'SlashRTCAdapter' 'Adapter URL -> sandbox index page' 'Sandbox adapter points to production' 'Pending approval' 'backup/v1.3.0-pre-change' 'Sandbox only' 'No' 'Production URL is already correct'
E $P3 $V3 'User (data)' 'POC MCube Rep' 'Set MobilePhone = agent number registered with MCube' 'MCube rings the agent on User.MobilePhone first' 'Pending' '' 'Sandbox only' 'No' ''
E $P4 $V4 'Aura Component' 'NewLeadCmp' 'Phone inputs use entry fields' 'Phone__c input disappears for masked users' 'Not requested yet' 'Baseline v1.0.0' 'Planned' 'Yes' ''
E $P4 $V4 'Aura Component' 'NewRefLeadCmp' 'Phone inputs use entry fields' 'Same' 'Not requested yet' 'Baseline v1.0.0' 'Planned' 'Yes' ''
E $P4 $V4 'Apex Trigger' 'LeadTrigger' 'Call LeadPhoneEntryHandler before insert / update' 'Copy entry fields' 'Not requested yet' 'Baseline v1.0.0' 'Planned' 'Yes' ''
E $P4 $V4 'Apex Class' 'LeadTriggerHandler' 'Hook for entry-field copy (if routed through handler)' 'Keep trigger thin' 'Not requested yet' 'Baseline v1.0.0' 'Planned' 'Yes' ''
E $P4 $V4 'Lightning Page' 'New_Lead_Page' 'Swap phone fields for entry fields' 'Fields vanish for masked users' 'Not requested yet' 'Baseline v1.0.0' 'Planned' 'Yes' ''
E $P4 $V4 'Lightning Page' 'New_Lead_Page1_sales' 'Swap phone fields for entry fields' 'Same' 'Not requested yet' 'Baseline v1.0.0' 'Planned' 'Yes' ''
foreach ($c in @(
    @('Aura Component','MakeCall','Masked numbers on screen'), @('Apex Class','MakeCallController','Return masked values; number resolved server-side'),
    @('Lightning Web Component','utilityCallComponent','G-Talk: send recordId only'), @('Lightning Web Component','offlineCallQuickActionCmp','G-Talk: send recordId only'),
    @('Apex Class','OfflineCallAppAPI','Server-side number lookup'), @('Aura Component','CallPanel','Show masked field'), @('Aura Component','CallPanel_Outbound','Show masked field'),
    @('Aura Component','mCubeLightningPage','Show Call_To__c masked'), @('Apex Class','LeadHistoryandActivityController','Return Call_To__c masked'),
    @('Apex Class','mCubeController','Mask numbers before writing log__c'), @('Aura Component','LeadMergeCmp','Masked numbers'), @('Apex Class','LeadMergeController','Return masked values'),
    @('Aura Component','UpdateContactDetails','Primary read-only masked; secondary masked entry'), @('Apex Class','updateContactDetails','Same'),
    @('Lightning Web Component','leadBulkPush','Masked selection list'), @('Apex Class','LeadBulkPushController','Return masked values'),
    @('Lightning Web Component','leadYotelPush','Masked selection list'), @('Apex Class','LeadYotelBulkPushController','Return masked values'),
    @('Lightning Web Component','leadMsgConversationLWC','Masked numbers in chat'), @('Apex Class','LeadMsgConversationController','Resolve number server-side for send'))) {
    E $P5 $V5 $c[0] $c[1] $c[2] 'Sends full numbers to the browser' 'Not requested yet' 'Baseline v1.0.0' 'Planned' 'Yes' 'Plus its existing test class'
}
E $P7 $V7 'Apex Trigger' 'TaskTrigger' 'Call FreeTextMaskService on save' 'Numbers typed in call notes' 'Not requested yet' 'Add to baseline first' 'Planned' 'Yes' ''
E $P7 $V7 'Apex Trigger' 'CallDetailTrigger' 'Call FreeTextMaskService on save (free-text fields only)' 'Numbers typed in call logs' 'Not requested yet' 'Add to baseline first' 'Planned' 'Yes' 'Structured number fields untouched'
E $P7 $V7 'Apex Trigger / Class' 'Opportunity + feedback object triggers (TBD)' 'Call FreeTextMaskService on save' 'Numbers typed in Opportunity / feedback text' 'Not requested yet' 'Add to baseline first' 'Planned' 'Yes' 'Exact names confirmed before Part 7'
E $P8 $V8 'Lightning Web Component' 'searchComponent' 'Possibly reuse for Find by number' 'Global search may stop matching hidden fields' 'Not requested yet' 'Baseline v1.0.0' 'Conditional' 'Conditional' ''
foreach ($c in @(
    @('Lightning Web Component','cancellationRequest','Fails completely if Opportunity Mobile__c is hidden'), @('Lightning Web Component','opportunitySummaryLWC','Masked display'),
    @('Lightning Web Component','registrationTeamFileUpload','Masked display'), @('Lightning Web Component','kycAndQuotationTabComponent','Masked co-applicant entry'),
    @('Aura Component','siteVisitFeedbackForm','Masked display'), @('Aura Component','createBookingCmp','Masked display'), @('Lightning Web Component','showConvertedOppRecord','Masked display'),
    @('Quick Action','Contact.Co_Applicant_1 / 2 / 3, Contact.Update_Contact_Details','Masked entry'), @('Visualforce Page','19 customer document pages (BookingForm, letters, quotations, receipts)','Keep real number for document teams'))) {
    E 'Part 9' 'v1.9.0' $c[0] $c[1] $c[2] 'Only if Decision 1 = hide Contact / Opportunity numbers' 'Waiting on Decision 1' 'Baseline v1.0.0' 'Conditional' 'Conditional' ''
}
E $P11 $V11 'Profile' '~40 rep profiles (Presales outbound, Sales, CRM Team, Referral Team, TLs ...)' 'Remove phone-field access; Export Reports / API Enabled where safe' 'This switches masking on' 'Not requested yet' 'Baseline v1.0.0' 'Planned' 'Yes' 'The go-live switch'
foreach ($pg in @('Lead_Record_Page','Sales_Lead_Record_Page','New_Lead_Page','New_Lead_Page1_sales','Lead_Record_Page3')) {
    E $P11 $V11 'Lightning Page' $pg 'Add maskedPhonePanel (click-to-dial on)' 'Reps need the panel on every Lead page they use' 'Not requested yet' $(if ($pg -eq 'Lead_Record_Page3') { 'Add to baseline first' } else { 'Baseline v1.0.0' }) 'Planned' 'Yes' ''
}
E $P11 $V11 'Lightning App (assignment)' 'Pre_Sales (Gsquare Housing)' 'Remove POC assignment row' 'Cleanup' 'Not requested yet' 'Commit 1adf63f' 'Planned' 'Pilot cleanup' ''
foreach ($c in @('McubeAutoDailerApi','mCubeController','McubeSoftphoneAddOnController')) {
    E $PS $VS 'Apex Class' $c 'Use Named Credential MCube_API instead of hard-coded token / http URL' 'Security debt' 'Not requested yet' 'Baseline v1.0.0' 'Planned' 'Yes (optional)' ''
}

# ---------------- MANUAL STEPS ----------------
$manual = @(
    @('M1', $P1, 'Assign permission set Phone Access Audit Viewer to admins who review audits', 'Setup > Permission Sets', 'Not done', 'Yes'),
    @('M2', $P2, 'Clone profile Presales outbound -> POC Masked Rep', 'Setup > Profiles > Clone', 'Done', 'Pilot only (decide)'),
    @('M3', $P2, 'Activate Sales_Lead_Record_Page_Masked_POC for Gsquare Housing / Desktop / Pre Sales / POC Masked Rep', 'Lightning App Builder > Activation', 'Done', 'Pilot only'),
    @('M4', $P2, 'Create test users POC MCube Rep, POC SlashRTC Rep', 'Setup > Users', 'Done', 'No'),
    @('M5', $P2, 'Create Pre Sales test Leads owned by each test user (tester or dummy numbers)', 'Leads', 'Not done', 'No'),
    @('M6', $P3, 'Set POC MCube Rep MobilePhone = agent number registered with MCube', 'Setup > Users', 'Not done', 'No'),
    @('M7', $P3, 'SlashRTC agent exists for POC SlashRTC Rep email (tptUniqueId = user email); sandbox origin allowed by SlashRTC', 'SlashRTC admin / vendor', 'Not done', 'No'),
    @('M8', $P3, 'SlashRTC call center adapter URL -> sandbox index page', 'Setup > Call Centers', 'Not done', 'No'),
    @('M9', $P6, 'Schedule PhoneAuditPurgeBatch nightly', 'Setup > Apex Classes > Schedule Apex', 'Not started', 'Yes'),
    @('M10', $P6, 'Assign Phone_Number_Reveal to TLs, Heads, Admins', 'Setup > Permission Sets', 'Not started', 'Yes'),
    @('M11', $P11, 'Assign Phone_Number_Full_Access to integration users (MCube, Yotel, Zetta, website/portal, SlashRTC log user)', 'Setup > Permission Sets', 'Not started', 'Yes'),
    @('M12', $P11, 'Activate pages / assignments that cannot be deployed (Pre_Sales app)', 'Lightning App Builder', 'Not started', 'Yes'),
    @('M13', 'Part 13', 'Production: Validate change set with Run specified tests, then Quick Deploy', 'Setup > Inbound Change Sets', 'Not started', 'Yes')
)

# ---------------- TEST CLASSES ----------------
$tests = @(
    @('PhoneMaskUtilTest', 'PhoneMaskUtil', $P1, '12', '100%', 'Deployed (Sandbox)'),
    @('PhoneMaskingConfigTest', 'PhoneMaskingConfig', $P1, '6', '98.2%', 'Deployed (Sandbox)'),
    @('MaskedDialServiceTest', 'MaskedDialService', $P1, '18', '100%', 'Deployed (Sandbox)'),
    @('MaskedDialServiceCTITest', 'MaskedDialServiceCTI', $P1, '6', '93.5%', 'Deployed (Sandbox)'),
    @('PhoneTestDataFactory', '(test data utility)', $P1, '-', '-', 'Deployed (Sandbox)'),
    @('MaskedPhonePanelControllerTest', 'MaskedPhonePanelController', $P2, '11', '100%', 'Deployed (Sandbox)'),
    @('McubeMaskedClickToCallTest', 'McubeSoftphoneAddOnController.clickToCallMasked', $P3, '', 'target > 85%', 'Planned'),
    @('LeadPhoneEntryHandlerTest', 'LeadPhoneEntryHandler', $P4, '', 'target > 85%', 'Planned'),
    @('(existing test classes of Part 5 components)', 'Part 5 changed classes', $P5, '', 'keep >= current', 'Planned'),
    @('PhoneRevealServiceTest', 'PhoneRevealService', $P6, '', 'target > 85%', 'Planned'),
    @('PhoneAuditPurgeBatchTest', 'PhoneAuditPurgeBatch', $P6, '', 'target > 85%', 'Planned'),
    @('FreeTextMaskServiceTest', 'FreeTextMaskService, FeedItemPhoneMaskTrigger', $P7, '', 'target > 85%', 'Planned'),
    @('FindByNumberControllerTest', 'FindByNumberController', $P8, '', 'target > 85%', 'Conditional')
)

# ---------------- BACKUPS ----------------
$backups = @(
    @('Baseline v1.0.0', '528 files: 44 Apex, LeadTrigger, 12 Aura, 11 LWC, 21 VF, 4 Lightning pages, 4 quick actions, 3 flows, 3 call centers, 38 phone fields, 167 profiles, 47 permission sets', 'force-app (git tag v1.0.0)', '2026-10-03', '9a87598', 'Backed up'),
    @('Pre_Sales app snapshot', 'Gsquare Housing app before the POC row', 'force-app/main/default/applications (commit 1adf63f)', '2026-10-05', '1adf63f', 'Backed up'),
    @('Part 3 pre-change backup', 'mcubeSoftphoneCTIAddOn, McubeSoftphoneAddOnController (+Test), index, slashPhone, slashPhoneApp, leadOp (+Test), 3 call centers', 'backup/v1.3.0-pre-change (with SHA256SUMS)', '2026-10-06', 'f2c7e4f', 'Backed up'),
    @('Before Part 4', 'Re-retrieve Part 4 components and compare with baseline', 'backup/v1.4.0-pre-change', '', '', 'Planned'),
    @('Before Part 5', 'Re-retrieve Part 5 components and compare with baseline', 'backup/v1.5.0-pre-change', '', '', 'Planned'),
    @('Before Part 7', 'TaskTrigger, CallDetailTrigger and handlers (not in baseline)', 'backup/v1.7.0-pre-change', '', '', 'Planned'),
    @('Before Part 11', 'All rep profiles, Lead_Record_Page3', 'backup/v2.0.0-pre-change', '', '', 'Planned')
)

# ---------------- PART 3 PLAN ----------------
$p3 = @(
    @('New', 'Apex test class', 'McubeMaskedClickToCallTest', 'Tests the new MCube method: masked click resolves the real number on the server and places the call (MCube callout mocked); denied / no-access / blank cases', 'None (tests only)', 'None'),
    @('Existing', 'Apex Class', 'McubeSoftphoneAddOnController', 'ADD one method clickToCallMasked(recordId, fieldKey): MaskedDialService.resolveOne -> existing clickToCallRemote(recordId, realNumber). Existing methods not edited.', 'POC MCube user can call from the masked panel; the real number never reaches the browser', 'Low: additive only'),
    @('Existing', 'Visualforce Page', 'mcubeSoftphoneCTIAddOn', 'In the onClickToDial listener: IF the click carries fieldKey (masked panel) -> call clickToCallMasked; ELSE existing code unchanged', 'Normal Phone__c clicks behave exactly as today', 'Low: one branch'),
    @('Existing', 'Aura Component', 'slashPhone (slashPhoneHelper.js)', 'In the onClickToDial listener: IF masked click -> runApex MaskedDialServiceCTI.resolveForDial(recordId, fieldKey), replace the number, then run the existing flow (leadOp lookup + postMessage to SlashRTC iframe)', 'POC SlashRTC user can call from the panel. Real number exists briefly inside the SlashRTC softphone (vendor limitation)', 'Medium: SlashRTC must accept sandbox origin'),
    @('Existing (sandbox only)', 'Call Center', 'SlashRTCAdapter', 'Adapter URL -> sandbox index page', 'SlashRTC softphone in sandbox loads the sandbox page', 'None in production'),
    @('New (update)', 'Profile', 'POC Masked Rep', 'Add class access MaskedDialServiceCTI', 'SlashRTC runApex allowed for POC users', 'None'),
    @('New (update)', 'Lightning Page', 'Sales_Lead_Record_Page_Masked_POC', 'Panel property Enable click-to-dial = true', 'Masked numbers become clickable for POC users', 'None for other users'),
    @('Data', 'User', 'POC MCube Rep', 'MobilePhone = agent number registered with MCube', 'MCube can ring the agent', 'None'),
    @('No change', 'Apex Class', 'leadOp', 'None: returns record Ids only (earlier plan corrected)', '-', '-'),
    @('No change', 'Visualforce Page', 'index', 'None: screen pop uses recordId', '-', '-'),
    @('Not in POC', 'Managed package', '360CTI (186 users)', 'Vendor change required', '-', 'Vendor dependency')
)

# ---------------- BUILD SHEETS ----------------
$readme = @(
    @('Purpose', 'Single register of every component of the Mobile Number Masking project: new components, existing components that change, backups, manual steps, tests, and the full production deployment list. Kept until the project completes.'),
    @('As of', $asOf),
    @('Source', 'Local git repository (branches ejjigiripraveen/v1.x.0-*), CHANGELOG.md, ROADMAP.md. Sandbox deploy IDs from sandbox gsquaregroup--prodreplic.'),
    @('Status colours', 'Green = deployed / done / backed up · Yellow = built locally / pending approval · Grey = planned / not started · Orange = conditional / vendor · Blue = sandbox only / manual'),
    @('Production list', 'Sheet "Prod Deployment List" is generated from "New Components" and "Existing Components" (rows needed in production) plus the production manual steps, in deploy order. Update the Prod Status column as you deploy.'),
    @('Rule', 'Existing components are changed only after approval; original code is backed up first (sheet "Backups").'),
    @('Rule', 'Sandbox first, then production pilot (1 SlashRTC + 1 360CTI + 1 MCube user), then everyone.')
)
Add-Sheet 'Read Me' 'Mobile Number Masking - Component Register' "As of $asOf" @('Item', 'Details') @(22, 130) $readme @()

$parts = @(
    @('Part 1', 'v1.1.0', 'Foundations', 'Deployed (Sandbox)'), @('Part 2', 'v1.2.0', 'Masked phone panel (POC users)', 'Deployed (Sandbox)'),
    @('Part 3', 'v1.3.0', 'Dialer adapters MCube + SlashRTC (POC)', 'Pending approval'), @('Part 4', 'v1.4.0', 'Lead creation with hidden numbers', 'Planned'),
    @('Part 5', 'v1.5.0', 'Mask leaking screens', 'Planned'), @('Part 6', 'v1.6.0', 'Reveal + audit cleanup', 'Planned'),
    @('Part 7', 'v1.7.0', 'Free-text auto-masking', 'Planned'), @('Part 8', 'v1.8.0', 'Find by number', 'Conditional'),
    @('Part 9', 'v1.9.0', 'Opportunity, Contact, documents', 'Conditional'), @('Part 10', '-', 'Vendor deliveries', 'Vendor'),
    @('Part 11', 'v2.0.0', 'Go-live access (masking ON)', 'Planned'), @('Security fix', 'optional', 'MCube Named Credential', 'Planned')
)
$sumRows = @()
$i = 4
foreach ($p in $parts) {
    $i++
    $sumRows += , @($p[0], $p[1], $p[2], $p[3],
        "=COUNTIFS('New Components'!`$B:`$B,A$i)",
        "=COUNTIFS('Existing Components'!`$B:`$B,A$i)",
        "=COUNTIFS('New Components'!`$B:`$B,A$i,'New Components'!`$I:`$I,""Deployed*"")",
        "=COUNTIFS('Prod Deployment List'!`$B:`$B,A$i)")
}
$i++
$sumRows += , @('Total', '', '', '', "=SUM(E5:E$($i-1))", "=SUM(F5:F$($i-1))", "=SUM(G5:G$($i-1))", "=SUM(H5:H$($i-1))")
Add-Sheet 'Summary' 'Summary by Part' 'Counts are formulas over the other sheets' @('Part', 'Version', 'Scope', 'Status', 'New components', 'Existing components changed', 'New deployed to sandbox', 'Rows in prod list') @(14, 10, 40, 22, 16, 22, 20, 16) $sumRows @(3)

$newRows = @(); $n = 0; foreach ($r in $new) { $n++; $newRows += , (@("$n") + $r) }
Add-Sheet 'New Components' 'New Components' 'Everything this project creates' @('#', 'Part', 'Version', 'Metadata Type', 'API Name', 'Parent / Object', 'What it does', 'Test class', 'Status', 'Sandbox Deploy ID / Record Id', 'Needed in Production', 'Notes') @(5, 11, 9, 24, 36, 26, 50, 28, 20, 22, 16, 34) $newRows @(8)

$exRows = @(); $n = 0; foreach ($r in $ex) { $n++; $exRows += , (@("$n") + $r) }
Add-Sheet 'Existing Components' 'Existing Components that Change' 'Changed only after approval; original backed up first' @('#', 'Part', 'Version', 'Metadata Type', 'API Name', 'What changes', 'Why', 'Approval', 'Original backup', 'Status', 'Needed in Production', 'Notes') @(5, 11, 9, 22, 36, 50, 34, 20, 26, 20, 16, 34) $exRows @(9)

# Production list: rows needed in production, ordered by part then by type dependency order
$typeRank = @{ 'Custom Metadata Type' = 1; 'Custom Object' = 2; 'Custom Field' = 3; 'Custom Metadata Record' = 4; 'List View' = 5; 'Custom Tab' = 6; 'Custom Permission' = 7; 'Named Credential' = 8; 'Lightning Message Channel' = 9; 'Apex Class' = 10; 'Apex Class (test)' = 11; 'Apex Trigger' = 12; 'Apex Trigger / Class' = 12; 'Visualforce Page' = 13; 'Aura Component' = 14; 'Lightning Web Component' = 15; 'Lightning Web Component (update)' = 15; 'Quick Action' = 16; 'Lightning Page' = 17; 'Lightning Page (update of new)' = 17; 'Permission Set' = 18; 'Profile' = 19; 'Profile (update of new)' = 19; 'Lightning App (assignment)' = 20 }
$partRank = @{ 'Part 1' = 1; 'Part 2' = 2; 'Part 3' = 3; 'Part 4' = 4; 'Part 5' = 5; 'Part 6' = 6; 'Part 7' = 7; 'Part 8' = 8; 'Part 9' = 9; 'Part 11' = 11; 'Security fix' = 12; 'Part 13' = 13 }
$prodItems = @()
foreach ($r in $new) { if ($r[9] -notmatch '^No') { $prodItems += [pscustomobject]@{ Part = $r[0]; Ver = $r[1]; Type = $r[2]; Api = $r[3]; Parent = $r[4]; Kind = 'New'; Method = $(if ($r[2] -match 'User') { 'Manual' } else { 'Change set' }); Tests = $r[6]; Needed = $r[9]; Notes = $r[10] } } }
foreach ($r in $ex) { if ($r[9] -notmatch '^No') { $prodItems += [pscustomobject]@{ Part = $r[0]; Ver = $r[1]; Type = $r[2]; Api = $r[3]; Parent = ''; Kind = 'Existing (change)'; Method = $(if ($r[2] -match 'assignment|Profile') { 'Manual / Change set' } else { 'Change set' }); Tests = ''; Needed = $r[9]; Notes = $r[4] } } }
$prodItems = $prodItems | Sort-Object @{ e = { $partRank[$_.Part] } }, @{ e = { if ($typeRank.ContainsKey($_.Type)) { $typeRank[$_.Type] } else { 50 } } }, Api
$prodRows = @(); $n = 0
foreach ($p in $prodItems) { $n++; $prodRows += , @("$n", $p.Part, $p.Ver, $p.Type, $p.Api, $p.Parent, $p.Kind, $p.Method, $p.Tests, $p.Needed, 'Not deployed', $p.Notes) }
foreach ($m in $manual) { if ($m[5] -notmatch '^No') { $n++; $prodRows += , @("$n", $m[1], '', 'Manual step', $m[0], '', 'Manual', 'Manual', '', $m[5], 'Not deployed', $m[2]) } }
Add-Sheet 'Prod Deployment List' 'Production Deployment List (all parts)' 'Deploy in this order, part by part. Change set test level: Run specified tests (classes in column I). Update "Prod Status" as you go.' @('Order', 'Part', 'Version', 'Change Set Type', 'API Name', 'Parent / Object', 'New / Existing', 'Deploy Method', 'Test class to run', 'Needed in Production', 'Prod Status', 'Notes') @(7, 11, 9, 24, 36, 24, 16, 18, 28, 16, 16, 50) $prodRows @(10)

$manRows = @(); foreach ($m in $manual) { $manRows += , @($m[0], $m[1], $m[2], $m[3], $m[4], $m[5]) }
Add-Sheet 'Manual Steps' 'Manual Steps (cannot be deployed)' 'Do these in Setup at the right point of each part' @('Step', 'Part', 'What to do', 'Where', 'Sandbox status', 'Needed in Production') @(7, 11, 70, 32, 16, 18) $manRows @(4)

Add-Sheet 'Test Classes' 'Test Classes and Coverage' 'Target above 85% per class, never SeeAllData' @('Test class', 'Covers', 'Part', 'Tests', 'Coverage (sandbox)', 'Status') @(34, 40, 11, 8, 18, 20) $tests @(5)

Add-Sheet 'Backups' 'Backups of Original Code' 'Taken before any existing component changes' @('Backup', 'Contents', 'Location', 'Retrieved', 'Git commit', 'Status') @(26, 70, 42, 12, 12, 14) $backups @(5)

Add-Sheet 'Part 3 Plan' 'Part 3 (v1.3.0) - Dialer adapters, POC' 'Explained before implementation; nothing changed yet' @('New / Existing', 'Type', 'Component', 'Change', 'Effect for users', 'Risk') @(18, 18, 34, 70, 50, 26) $p3 @()
