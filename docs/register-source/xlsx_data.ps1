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
N $P3 $V3 'Apex Class (test)' 'McubeMaskedClickToCallTest' '' 'Tests the new MCube masked click-to-dial method (mocked callout)' '' 'Deployed (Sandbox)' '0Afft000000LY6jCAG' 'Yes' 'New class so the existing test class stays untouched'
N $P3 $V3 'Apex Class (update of new)' 'MaskedDialService' '' 'Adds deferred audit (callout-safe) + field lookup from masked value' 'MaskedDialServiceTest' 'Deployed (Sandbox)' '0Afft000000LY6jCAG' 'Yes' 'Part 1 component updated'
N $P3 $V3 'Apex Class (update of new)' 'MaskedDialServiceCTI' '' 'Adds resolveMaskedClick (SlashRTC masked click)' 'MaskedDialServiceCTITest' 'Deployed (Sandbox)' '0Afft000000LY6jCAG' 'Yes' 'Part 1 component updated'
N $P3 $V3 'Apex Class (test, update)' 'MaskedDialServiceTest' '' '+5 tests' '' 'Deployed (Sandbox)' '0Afft000000LY6jCAG' 'Yes' ''
N $P3 $V3 'Apex Class (test, update)' 'MaskedDialServiceCTITest' '' '+3 tests' '' 'Deployed (Sandbox)' '0Afft000000LY6jCAG' 'Yes' ''
N $P3 $V3 'Profile (update of new)' 'POC Masked Rep' '' 'Add class access: MaskedDialServiceCTI (SlashRTC runApex)' '' 'Deployed (Sandbox)' '0Afft000000LYBZCA4' 'Pilot only (decide)' ''
N $P3 $V3 'Lightning Page (update of new)' 'Sales_Lead_Record_Page_Masked_POC' '' 'Turn panel property Enable click-to-dial = true' '' 'Deployed (Sandbox)' '0Afft000000LYBZCA4' 'Pilot only' ''
N $P3 $V3 'Lightning Message Channel' 'MaskedDialRequest__c' '' 'Fallback Option A only: panel sends {recordId, fieldKey} to adapters' '' 'Conditional' '' 'Conditional' 'Only if POC shows masked click-to-dial fails'

$P4 = 'Part 4'; $V4 = 'v1.4.0'
N $P4 $V4 'Custom Field' 'Phone_Entry__c' 'Lead' 'Entry field for primary number; copied to Phone__c and cleared' '' 'Deployed (Sandbox)' '0Afft000000Lc77CAC' 'Yes' ''
N $P4 $V4 'Custom Field' 'Secondary_Phone_Entry__c' 'Lead' 'Entry field for secondary number' '' 'Deployed (Sandbox)' '0Afft000000Lc77CAC' 'Yes' ''
N $P4 $V4 'Apex Class' 'LeadPhoneEntryHandler' '' 'Copies entry fields, locks primary after creation' 'LeadPhoneEntryHandlerTest' 'Deployed (Sandbox)' '0Afft000000Lc77CAC' 'Yes' ''
N $P4 $V4 'Apex Class (test)' 'LeadPhoneEntryHandlerTest' '' 'Tests incl. 200-record bulk' '' 'Deployed (Sandbox)' '0Afft000000Lc77CAC' 'Yes' ''
N $P4 $V4 'Profile (update of new)' 'POC Masked Rep' '' 'Edit access to Phone_Entry__c, Secondary_Phone_Entry__c' '' 'Deployed (Sandbox)' '0Afft000000LcALCA0' 'Pilot only (decide)' 'Reps get it at go-live (Part 11)'
N $P4 $V4 'Lightning Page (update of new)' 'Sales_Lead_Record_Page_Masked_POC' '' 'Add Secondary_Phone_Entry__c (New secondary number) to the details' '' 'Deployed (Sandbox)' '0Afft000000LcALCA0' 'Pilot only' ''

$P5 = 'Part 5'; $V5 = 'v1.5.0'
N $P5 $V5 'Apex Class' 'PhoneDisplayService' '' '5a: one rule for all screens - is this user masked? masks numbers for display; resolves a masked number back to the real one (with sharing, audited)' 'PhoneDisplayServiceTest' 'Pending approval' '' 'Yes' ''
N $P5 $V5 'Apex Class (test)' 'PhoneDisplayServiceTest' '' '' '' 'Pending approval' '' 'Yes' ''
N $P5 $V5 'Apex Class (update of new)' 'MaskedDialService' '' '5a: + logAccess (audit rows for MakeCall / G-Talk, deferred when a callout follows)' 'MaskedDialServiceTest' 'Pending approval' '' 'Yes' ''
N $P5 $V5 'Custom Field' 'Phone_Masked__c' 'Lead' '5a: Formula: masked primary (call panels; later list views / reports)' '' 'Pending approval' '' 'Yes' ''
N $P5 $V5 'Custom Field' 'Secondary_Phone_Masked__c' 'Lead' 'Formula: masked secondary' '' 'Planned' '' 'Yes' ''
N $P5 $V5 'Custom Field' 'Call_To_Masked__c' 'Call_Detail__c' '5b: Formula: masked call number' '' 'Pending approval' '' 'Yes' ''

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
E $P3 $V3 'Visualforce Page' 'mcubeSoftphoneCTIAddOn' 'In onClickToDial: if the click comes from the masked panel, call the new server method with recordId + fieldKey' 'MCube receives 98XXXXXX21, which it cannot dial' 'Approved 2026-10-06' 'backup/v1.3.0-pre-change' 'Deployed (Sandbox) 0Afft000000LY6jCAG' 'Yes' 'Normal clicks unchanged'
E $P3 $V3 'Apex Class' 'McubeSoftphoneAddOnController' 'Add new @RemoteAction clickToCallMasked(recordId, fieldKey): resolves via MaskedDialService, then reuses clickToCallRemote' 'Real number resolved on the server, never in the browser' 'Approved 2026-10-06' 'backup/v1.3.0-pre-change' 'Deployed (Sandbox) 0Afft000000LY6jCAG' 'Yes' 'Existing methods not edited'
E $P3 $V3 'Aura Component' 'slashPhone (slashPhoneHelper.js)' 'In onClickToDial listener: if masked click, runApex MaskedDialServiceCTI.resolveForDial, then continue existing flow' 'SlashRTC receives 98XXXXXX21' 'Approved 2026-10-06' 'backup/v1.3.0-pre-change' 'Deployed (Sandbox) 0Afft000000LY6jCAG' 'Yes' 'Number exists briefly inside the SlashRTC softphone (vendor limitation)'
E $P3 $V3 'Call Center' 'SlashRTCAdapter' 'Adapter URL -> sandbox index page' 'Sandbox adapter points to production' 'Manual by you (Setup)' 'backup/v1.3.0-pre-change' 'Sandbox only - manual' 'No' 'Production URL is already correct'
E $P3 $V3 'User (data)' 'POC MCube Rep' 'Set MobilePhone = agent number registered with MCube' 'MCube rings the agent on User.MobilePhone first' 'Pending' '' 'Sandbox only' 'No' ''
E $P4 $V4 'Aura Component' 'NewLeadCmp' 'On form load: if the user cannot see Phone__c, show Phone (entry) + Secondary Phone (entry) inputs instead' 'Phone__c input disappears for masked users, so they could not create Leads' 'Approved 2026-10-06' 'backup/v1.4.0-pre-change' 'Deployed (Sandbox) 0Afft000000Lc77CAC' 'Yes' 'No change for users who can see Phone__c'
E $P4 $V4 'Aura Component' 'NewRefLeadCmp' 'Same as NewLeadCmp (New Referral Lead quick action)' 'Same' 'Approved 2026-10-06' 'backup/v1.4.0-pre-change' 'Deployed (Sandbox) 0Afft000000Lc77CAC' 'Yes' ''
E $P4 $V4 'Apex Trigger' 'LeadTrigger' 'One call at the very top (before insert / update): LeadPhoneEntryHandler copies entry fields before the existing formatting and duplicate check' 'Copy must run before RelatedSourceHandler.checkMobileNumber / duplicateCheck' 'Approved 2026-10-06' 'backup/v1.4.0-pre-change' 'Deployed (Sandbox) 0Afft000000Lc77CAC' 'Yes' 'Existing logic untouched'
E $P4 $V4 'Apex Class' 'LeadTriggerHandler / RelatedSourceHandler' 'No change (existing tests re-run)' 'Dependency' '-' 'backup/v1.4.0-pre-change' 'No change' 'No' ''
E $P11 $V11 'Lightning Page' 'New_Lead_Page' 'Swap phone fields for entry fields' 'Fields vanish for masked users' 'Not requested yet' 'backup/v1.4.0-pre-change' 'Planned' 'Yes' ''
E $P11 $V11 'Lightning Page' 'New_Lead_Page1_sales' 'Swap phone fields for entry fields' 'Same' 'Not requested yet' 'backup/v1.4.0-pre-change' 'Planned' 'Yes' ''
foreach ($c in @(
    @('Aura Component','MakeCall','5a: NO CHANGE needed - shows what readContacts returns and sends it back'), @('Apex Class','MakeCallController','5a: readContacts returns masked for masked users; callCustomer resolves a masked number on the server'),
    @('Lightning Web Component','utilityCallComponent','5a: NO CHANGE needed - sends the number back to triggerCall, resolved on the server'), @('Lightning Web Component','offlineCallQuickActionCmp','5a: NO CHANGE needed (same as utilityCallComponent)'),
    @('Apex Class','OfflineCallAppAPI','5a: getLeadPhone / getOppPhone masked for masked users; triggerCall resolves a masked number on the server'), @('Aura Component','CallPanel','5a: show Phone_Masked__c for masked users'), @('Aura Component','CallPanel_Outbound','5a: show Phone_Masked__c for masked users'),
    @('Aura Component','mCubeLightningPage','5b: NO CHANGE - shows what callRecords returns'), @('Apex Class','LeadHistoryandActivityController','5b: GetData masks phone history values and call numbers for masked users'),
    @('Apex Class','mCubeController','5b: callRecords masked for masked users; log__c Request / Response masked for everyone'), @('Aura Component','LeadMergeCmp','Masked numbers'), @('Apex Class','LeadMergeController','Return masked values'),
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

# Part 5a status (v1.5.0, built 2026-10-06)
foreach ($row in $ex) {
    if ($row[0] -ne 'Part 5') { continue }
    if (@('MakeCallController', 'OfflineCallAppAPI') -contains $row[3]) {
        $row[6] = 'Approved 2026-10-06'; $row[7] = 'backup/v1.5.0-part5a-pre-change'; $row[8] = 'Deployed (Sandbox) 0Afft000000Lf3NCAS'
    } elseif (@('CallPanel', 'CallPanel_Outbound') -contains $row[3]) {
        $row[4] = 'Postponed: the Aura view form has no onload event. Proposed: replace the Phone line with a new LWC maskedPhoneField'
        $row[6] = 'New approach pending approval'; $row[7] = 'backup/v1.5.0-part5a-pre-change'; $row[8] = 'Pending approval'
    } elseif (@('MakeCall', 'utilityCallComponent', 'offlineCallQuickActionCmp') -contains $row[3]) {
        $row[6] = '-'; $row[7] = 'backup/v1.5.0-part5a-pre-change'; $row[8] = 'No change (5a)'; $row[9] = 'No'
    }
}
foreach ($row in $new) {
    if ($row[0] -eq 'Part 5' -and @('PhoneDisplayService', 'PhoneDisplayServiceTest', 'MaskedDialService', 'Phone_Masked__c') -contains $row[3]) { $row[7] = 'Deployed (Sandbox) 0Afft000000Lf3NCAS' }
}
N $P5 $V5 'Apex Class (test)' 'PhoneMaskingCallScreensTest' '' '5a: masked paths of MakeCallController and OfflineCallAppAPI (callouts mocked)' '' 'Deployed (Sandbox)' '' 'Yes' 'Existing test classes unchanged'
N $P5 $V5 'Profile (update of new)' 'POC Masked Rep' '' '5a: read access to Lead.Phone_Masked__c' '' 'Deployed (Sandbox)' '' 'Pilot only (decide)' ''

# Part 5b status (v1.5.0, built 2026-10-06)
foreach ($row in $ex) {
    if ($row[0] -ne 'Part 5') { continue }
    if (@('mCubeController', 'LeadHistoryandActivityController') -contains $row[3]) {
        $row[6] = 'Approved 2026-10-06'; $row[7] = 'backup/v1.5.0-part5b-pre-change'; $row[8] = 'Deployed (Sandbox) 0Afft000000LfszCAC'
    } elseif ($row[3] -eq 'mCubeLightningPage') {
        $row[6] = '-'; $row[7] = 'backup/v1.5.0-part5b-pre-change'; $row[8] = 'No change (5b)'; $row[9] = 'No'
    }
}
foreach ($row in $new) {
    if ($row[0] -eq 'Part 5' -and $row[3] -eq 'Call_To_Masked__c') { $row[7] = 'Deployed (Sandbox) 0Afft000000LfszCAC' }
}
N $P5 $V5 'Apex Class (test)' 'PhoneMaskingHistoryTest' '' '5b: call history, History & Activity and MCube log masking (callouts mocked)' '' 'Deployed (Sandbox)' '0Afft000000LfszCAC' 'Yes' ''
N $P5 $V5 'Apex Class (update of new)' 'PhoneDisplayService' '' '5b: + forDisplay, historyValueForDisplay' 'PhoneMaskingHistoryTest' 'Deployed (Sandbox)' '0Afft000000LfszCAC' 'Yes' ''
E $P5 $V5 'Aura Component' 'LeadHistoryandActivityCmp' '5b: NO CHANGE - shows what GetData returns' 'History & Activity on 4 Lead pages' '-' 'backup/v1.5.0-part5b-pre-change' 'No change (5b)' 'No' 'First backed up in 5b'

# Part 5c status (v1.5.0, planned 2026-10-07)
foreach ($row in $ex) {
    if ($row[0] -ne 'Part 5') { continue }
    if (@('LeadMergeController', 'updateContactDetails') -contains $row[3]) {
        $row[6] = 'Approved 2026-10-07'; $row[7] = 'backup/v1.5.0-part5c-pre-change'; $row[8] = 'Deployed (Sandbox) 0Afft000000LkRFCA0'
    } elseif (@('LeadMergeCmp', 'UpdateContactDetails') -contains $row[3]) {
        $row[4] = '5c: NO CHANGE - shows what Apex returns'; $row[6] = '-'; $row[7] = 'backup/v1.5.0-part5c-pre-change'; $row[8] = 'No change (5c)'; $row[9] = 'No'
    }
}

N $P5 $V5 'Apex Class (test)' 'PhoneMaskingLeadToolsTest' '' '5c: merge lists masked; Update Contact never saves masked values, primary locked for masked users' '' 'Deployed (Sandbox)' '0Afft000000LkRFCA0' 'Yes' ''
N $P5 $V5 'Apex Class (update of new)' 'PhoneDisplayService' '' '5c: + maskRecords, prepareContactInput' 'PhoneMaskingLeadToolsTest' 'Deployed (Sandbox)' '0Afft000000LkRFCA0' 'Yes' ''

# Part 5d status (planned 2026-10-07)
foreach ($row in $ex) {
    if ($row[0] -ne 'Part 5') { continue }
    if (@('LeadBulkPushController', 'LeadYotelBulkPushController') -contains $row[3]) {
        $row[6] = 'Approved 2026-10-07'; $row[7] = 'backup/v1.5.0-part5d-pre-change'; $row[8] = 'Deployed (Sandbox) 0Afft000000Lm1dCAC'
    } elseif (@('leadBulkPush', 'leadYotelPush') -contains $row[3]) {
        $row[4] = '5d: NO CHANGE - shows what Apex returns'; $row[6] = '-'; $row[7] = 'backup/v1.5.0-part5d-pre-change'; $row[8] = 'No change (5d)'; $row[9] = 'No'
    }
}

N $P5 $V5 'Apex Class (test)' 'PhoneMaskingPushTest' '' '5d: selection lists masked for masked users; eligibility unchanged' '' 'Deployed (Sandbox)' '0Afft000000Lm1dCAC' 'Yes' ''

# Part 5e status (planned 2026-10-07)
foreach ($row in $ex) {
    if ($row[0] -ne 'Part 5') { continue }
    if ($row[3] -eq 'LeadMsgConversationController') { $row[4] = '5e: mask numbers in conversation message / rawJson / senderName for masked users'; $row[6] = 'Pending approval'; $row[7] = 'backup/v1.5.0-part5e-pre-change' }
    elseif ($row[3] -eq 'leadMsgConversationLWC') { $row[4] = '5e: NO CHANGE - shows what Apex returns'; $row[6] = '-'; $row[7] = 'backup/v1.5.0-part5e-pre-change'; $row[8] = 'No change (5e)'; $row[9] = 'No' }
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
    @('M8', $P3, 'SlashRTC call center CTI Adapter URL -> /apex/index (sandbox only, done manually by you)', 'Setup > Call Centers > SlashRTC Call Center Adapter > Edit', 'Manual - pending', 'No'),
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
    @('McubeMaskedClickToCallTest + McubeSoftphoneAddOnControllerTest', 'McubeSoftphoneAddOnController', $P3, '-', '87.9%', 'Deployed (Sandbox)'),
    @('MaskedDialServiceTest (v1.3.0, +5)', 'MaskedDialService', $P3, '23', '100%', 'Deployed (Sandbox)'),
    @('MaskedDialServiceCTITest (v1.3.0, +3)', 'MaskedDialServiceCTI', $P3, '9', '94.4%', 'Deployed (Sandbox)'),
    @('LeadPhoneEntryHandlerTest (+ LeadTriggerTest, LeadTriggerHandlerTest)', 'LeadPhoneEntryHandler, LeadTrigger', $P4, '20', 'Handler 100% · LeadTrigger 80.1%', 'Deployed (Sandbox)'),
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
    @('Part 4 pre-change backup', 'LeadTrigger, NewLeadCmp, NewRefLeadCmp, RelatedSourceHandler, LeadTriggerHandler (+tests), New_Lead_Page, New_Lead_Page1_sales (changed since baseline: +8 lines tab display), Lead.New_Referral_Lead', 'backup/v1.4.0-pre-change (with SHA256SUMS)', '2026-10-06', '9b32c8c', 'Backed up'),
    @('Part 5a pre-change backup', 'MakeCall + MakeCallController (+Test), OfflineCallAppAPI (+Test), utilityCallComponent, offlineCallQuickActionCmp, CallPanel, CallPanel_Outbound - identical to baseline', 'backup/v1.5.0-part5a-pre-change (with SHA256SUMS)', '2026-10-06', '3c0330b', 'Backed up'),
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
    @('Part 3', 'v1.3.0', 'Dialer adapters MCube + SlashRTC (POC)', 'Deployed (Sandbox)'), @('Part 4', 'v1.4.0', 'Lead creation with hidden numbers', 'Deployed (Sandbox)'),
    @('Part 5', 'v1.5.0', 'Mask leaking screens (5a-5d deployed, call panels deferred D1)', 'Deployed (Sandbox) - 5a to 5d'), @('Part 6', 'v1.6.0', 'Reveal + audit cleanup', 'Planned'),
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
$typeRank = @{ 'Custom Metadata Type' = 1; 'Custom Object' = 2; 'Custom Field' = 3; 'Custom Metadata Record' = 4; 'List View' = 5; 'Custom Tab' = 6; 'Custom Permission' = 7; 'Named Credential' = 8; 'Lightning Message Channel' = 9; 'Apex Class' = 10; 'Apex Class (test)' = 11; 'Apex Class (update of new)' = 10; 'Apex Class (test, update)' = 11; 'Apex Trigger' = 12; 'Apex Trigger / Class' = 12; 'Visualforce Page' = 13; 'Aura Component' = 14; 'Lightning Web Component' = 15; 'Lightning Web Component (update)' = 15; 'Quick Action' = 16; 'Lightning Page' = 17; 'Lightning Page (update of new)' = 17; 'Permission Set' = 18; 'Profile' = 19; 'Profile (update of new)' = 19; 'Lightning App (assignment)' = 20 }
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

# ---------------- RELEASE BUNDLE (built components, Parts 1-2) ----------------
$releaseDir = Join-Path $PSScriptRoot '..\..\release\prod'
$sumFile = Join-Path $releaseDir 'SHA256SUMS'
$bundleMeta = @{
    'part1-foundations' = @('1', 'Part 1', 'v1.1.0', 'Production - everyone', 'sf project deploy validate --metadata-dir release/prod/part1-foundations --test-level RunSpecifiedTests --tests PhoneMaskingConfigTest --tests PhoneMaskUtilTest --tests MaskedDialServiceTest --tests MaskedDialServiceCTITest', 'Deployed (Sandbox) 0Afft000000LO8zCAG')
    'part2-panel'       = @('2', 'Part 2', 'v1.2.0', 'Production - everyone', 'sf project deploy validate --metadata-dir release/prod/part2-panel --test-level RunSpecifiedTests --tests MaskedPhonePanelControllerTest', 'Deployed (Sandbox) 0Afft000000LRq1CAG')
    'part3-dialers'     = @('3', 'Part 3', 'v1.3.0', 'Production - everyone', 'sf project deploy validate --metadata-dir release/prod/part3-dialers --test-level RunSpecifiedTests --tests McubeMaskedClickToCallTest --tests McubeSoftphoneAddOnControllerTest', 'Deployed (Sandbox) 0Afft000000LY6jCAG')
    'part4-lead-entry'  = @('4', 'Part 4', 'v1.4.0', 'Production - everyone', 'sf project deploy validate --metadata-dir release/prod/part4-lead-entry --test-level RunSpecifiedTests --tests LeadPhoneEntryHandlerTest --tests LeadTriggerTest --tests LeadTriggerHandlerTest', 'Deployed (Sandbox) 0Afft000000Lc77CAC')
    'part5a-calling'    = @('5', 'Part 5', 'v1.5.0 (5a)', 'Production - everyone', 'sf project deploy validate --metadata-dir release/prod/part5a-calling --test-level RunSpecifiedTests --tests PhoneDisplayServiceTest --tests PhoneMaskingCallScreensTest --tests MakeCallControllerTest --tests OfflineCallAppAPITest --tests MaskedDialServiceTest', 'Deployed (Sandbox) 0Afft000000Lf3NCAS')
    'part5b-history'    = @('6', 'Part 5', 'v1.5.0 (5b)', 'Production - everyone', 'sf project deploy validate --metadata-dir release/prod/part5b-history --test-level RunSpecifiedTests --tests PhoneMaskingHistoryTest --tests PhoneDisplayServiceTest --tests mCubeController_Test --tests mCubeControllerTestExtended --tests LeadHistoryandActivityControllerTest', 'Deployed (Sandbox) 0Afft000000LfszCAC')
    'part5c-lead-tools' = @('7', 'Part 5', 'v1.5.0 (5c)', 'Production - everyone', 'sf project deploy validate --metadata-dir release/prod/part5c-lead-tools --test-level RunSpecifiedTests --tests PhoneMaskingLeadToolsTest --tests PhoneDisplayServiceTest --tests LeadMergeControllerTest (not updateContactDetailsTest - fails before 5c, D3)', 'Deployed (Sandbox) 0Afft000000LkRFCA0')
    'part5d-push'       = @('8', 'Part 5', 'v1.5.0 (5d)', 'Production - everyone', 'sf project deploy validate --metadata-dir release/prod/part5d-push --test-level RunSpecifiedTests --tests PhoneMaskingPushTest --tests LeadBulkPushControllerTest --tests LeadYotelBulkPushControllerTest', 'Deployed (Sandbox) 0Afft000000Lm1dCAC')
    'part2-pilot'       = @('9', 'Part 2', 'v1.2.0', 'Production pilot only (clone POC profile first)', 'sf project deploy start --metadata-dir release/prod/part2-pilot --test-level NoTestRun', 'Deployed (Sandbox) 0Afft000000LRq1CAG / 0Afft000000LRzhCAG')
}
$typeOf = @{ 'pages' = 'Visualforce Page'; 'aura' = 'Aura Component'; 'classes' = 'Apex Class'; 'lwc' = 'Lightning Web Component'; 'objects' = 'Custom Object / Custom Metadata Type (with fields)'; 'customMetadata' = 'Custom Metadata Record'; 'tabs' = 'Custom Tab'; 'permissionsets' = 'Permission Set'; 'flexipages' = 'Lightning Page'; 'profiles' = 'Profile' }
$relRows = @()
if (Test-Path $sumFile) {
    foreach ($line in (Get-Content $sumFile)) {
        if ($line -notmatch '^([0-9a-f]{64})\s+\*?\./(.+)$') { continue }
        $hash = $Matches[1]; $path = $Matches[2]
        $parts = $path -split '/'
        $folder = $parts[0]
        if (-not $bundleMeta.ContainsKey($folder)) { continue }
        $m = $bundleMeta[$folder]
        $kind = if ($parts.Count -ge 3) { $typeOf[$parts[1]] } else { 'Manifest (package.xml)' }
        $file = $parts[$parts.Count - 1]
        $component = if ($parts.Count -ge 4) { $parts[2] } elseif ($parts.Count -eq 3) { ($file -replace '\.(cls|page|object|md|tab|permissionset|flexipage|profile)(-meta\.xml)?$', '' -replace '-meta\.xml$', '') } else { 'package.xml' }
        $isTest = if ($kind -eq 'Apex Class' -and $component -match 'Test|Factory') { ' (test)' } else { '' }
        $relRows += , @($m[0], $folder, $m[1], $m[2], ($kind + $isTest), $component, "release/prod/$path", $hash.Substring(0, 12), $m[3], $m[5], 'Not deployed')
    }
}
$relRows = $relRows | Sort-Object @{ e = { [int]$_[0] } }, @{ e = { $_[4] } }, @{ e = { $_[6] } }
$stepRows = @(
    @('1', 'part1-foundations', 'Validate in production, then quick deploy', $bundleMeta['part1-foundations'][4] + ' --target-org <prod>   then   sf project deploy quick --job-id <id> --target-org <prod>', 'Not deployed'),
    @('2', 'part2-panel', 'Validate in production, then quick deploy', $bundleMeta['part2-panel'][4] + ' --target-org <prod>   then   sf project deploy quick --job-id <id> --target-org <prod>', 'Not deployed'),
    @('3', 'part2-pilot', 'Pilot only: clone Presales outbound -> POC Masked Rep in Setup, then deploy', $bundleMeta['part2-pilot'][4] + ' --target-org <prod>', 'Not deployed'),
    @('3b', 'part3-dialers', 'Validate in production, then quick deploy', $bundleMeta['part3-dialers'][4] + ' --target-org <prod>   then   sf project deploy quick --job-id <id> --target-org <prod>', 'Not deployed'),
    @('3c', 'part4-lead-entry', 'Validate in production, then quick deploy', $bundleMeta['part4-lead-entry'][4] + ' --target-org <prod>   then   sf project deploy quick --job-id <id> --target-org <prod>', 'Not deployed'),
    @('3d', 'part5a-calling', 'Validate in production, then quick deploy', $bundleMeta['part5a-calling'][4] + ' --target-org <prod>   then   sf project deploy quick --job-id <id> --target-org <prod>', 'Not deployed'),
    @('3e', 'part5b-history', 'Validate in production, then quick deploy', $bundleMeta['part5b-history'][4] + ' --target-org <prod>   then   sf project deploy quick --job-id <id> --target-org <prod>', 'Not deployed'),
    @('3f', 'part5c-lead-tools', 'Validate in production, then quick deploy', $bundleMeta['part5c-lead-tools'][4] + ' --target-org <prod>   then   sf project deploy quick --job-id <id> --target-org <prod>', 'Not deployed'),
    @('3g', 'part5d-push', 'Validate in production, then quick deploy', $bundleMeta['part5d-push'][4] + ' --target-org <prod>   then   sf project deploy quick --job-id <id> --target-org <prod>', 'Not deployed'),
    @('4', '(manual)', 'Assign Phone Access Audit Viewer to admins', 'Setup > Permission Sets', 'Not deployed'),
    @('5', '(manual, pilot)', 'Activate masked POC page: Gsquare Housing / Desktop / Pre Sales / POC Masked Rep', 'Lightning App Builder > Activation', 'Not deployed'),
    @('6', '(check)', 'Run scripts/apex/v1.1.0-1 and -2 (read-only)', 'Developer Console > Execute Anonymous', 'Not deployed')
)
Add-Sheet 'Release Bundle' 'Production Release Bundle - built components (Parts 1-5d)' "Every file in release/prod, converted from the sandbox-tested source. Checksums in release/prod/SHA256SUMS. Rebuild: bash scripts/release/build-prod-release.sh" @('Deploy order', 'Bundle folder', 'Part', 'Version', 'Metadata Type', 'Component', 'File path', 'SHA-256 (first 12)', 'For', 'Tested in sandbox', 'Prod Status') @(9, 20, 9, 9, 30, 34, 70, 16, 30, 34, 14) $relRows @(9, 10)
Add-Sheet 'Release Steps' 'Production Deploy Steps (Parts 1-5d)' 'Validate first, then quick deploy. Replace <prod> with the production org alias.' @('Step', 'Bundle', 'What', 'Command / Where', 'Prod Status') @(6, 20, 50, 110, 14) $stepRows @(4)

# ---------------- PART 4 PLAN ----------------
$p4 = @(
    @('New', 'Custom Field (Phone)', 'Lead.Phone_Entry__c', 'Label "Phone". Reps type the primary number here when creating a Lead. Always empty after save.', 'Masked reps can create Leads', 'None'),
    @('New', 'Custom Field (Phone)', 'Lead.Secondary_Phone_Entry__c', 'Label "Secondary Phone". Add / change the secondary number. Always empty after save.', 'Masked reps can add or change the secondary number', 'None'),
    @('New', 'Apex Class', 'LeadPhoneEntryHandler', 'Before insert / update: copies entry -> Phone__c / Secondary_Phone__c and clears the entry fields. Primary is locked once set (error if an entry value tries to change it). Bulk-safe, no SOQL / DML.', 'Numbers are saved in the real (hidden) fields exactly as today', 'Low'),
    @('New', 'Apex Class (test)', 'LeadPhoneEntryHandlerTest', 'Insert, update, lock, secondary change, blank, 200-record bulk, runAs masked user; > 85%, no SeeAllData', '-', '-'),
    @('Existing', 'Apex Trigger', 'LeadTrigger', 'Add ONE call at the very top (after the bypass check): LeadPhoneEntryHandler.beforeSave(...) for before insert / update. Everything else unchanged.', 'Formatting, duplicate check, round robin and validation rules all see the copied number as today', 'Medium: LeadTrigger runs for every Lead save; covered by existing LeadTrigger tests + new tests'),
    @('Existing', 'Aura Component', 'NewLeadCmp (Lead New button, desktop + mobile)', 'In the existing onload step: if the form did not receive Phone__c (user cannot see it), show the entry inputs (required Phone + Secondary Phone) instead.', 'Users who can see Phone__c: no change. Masked users: same form, entry inputs.', 'Low'),
    @('Existing', 'Aura Component', 'NewRefLeadCmp (New Referral Lead quick action)', 'Same as NewLeadCmp', 'Same', 'Low'),
    @('New (update)', 'Profile', 'POC Masked Rep', 'Edit access to the 2 entry fields', 'POC users can type numbers', 'None'),
    @('New (update)', 'Lightning Page', 'Sales_Lead_Record_Page_Masked_POC', 'Add "Secondary Phone" entry field to the details so POC users can add / change the secondary number', 'POC users only', 'None'),
    @('No change', 'Apex', 'RelatedSourceHandler, LeadTriggerHandler', 'Existing formatting + duplicate check keep working on Phone__c', '-', '-'),
    @('Deferred to Part 11', 'Lightning Page', 'New_Lead_Page, New_Lead_Page1_sales', 'Phone fields swapped for panel + entry field at go-live', 'No change now', '-'),
    @('Unaffected', 'Integrations', 'Website / portals / MCube / LeadCreationAPI', 'Still write Phone__c directly; entry fields not used', 'No change', '-')
)
Add-Sheet 'Part 4 Plan' 'Part 4 (v1.4.0) - Lead creation with hidden numbers' 'Explained before implementation; originals backed up in backup/v1.4.0-pre-change' @('New / Existing', 'Type', 'Component', 'Change', 'Effect for users', 'Risk') @(18, 20, 36, 70, 50, 34) $p4 @()

# ---------------- PART 5a PLAN ----------------
$p5a = @(
    @('New', 'Apex Class', 'PhoneDisplayService (+ PhoneDisplayServiceTest)', 'isMaskedUser(): true when the user cannot read Lead.Phone__c. maskForDisplay(): "+91 9876543221" -> "+91 98XXXXXX21". resolve(recordId, maskedValue, candidates): finds the real number on the server (with sharing) and writes an audit row.', 'Same masking rule on every screen', 'Low'),
    @('New', 'Custom Field (formula)', 'Lead.Phone_Masked__c', 'LEFT 2 + X + RIGHT 2 of Phone__c', 'Masked number on the call panels', 'None'),
    @('Updated (ours)', 'Apex Class', 'MaskedDialService', '+ logAccess(): one audit row per MakeCall / G-Talk dial (deferred when a callout follows)', 'Every masked call is audited', 'Low'),
    @('Existing', 'Apex Class', 'MakeCallController', 'readContacts: masked list for masked users (Lead + Related Source numbers). callCustomer: if the number contains X, find the real one on the server, then call MCube exactly as today.', 'Current users: no change. Masked users: masked list, call still placed.', 'Low-medium'),
    @('Existing', 'Apex Class', 'OfflineCallAppAPI', 'getLeadPhone / getOppPhone: masked for masked users. triggerCall: if the number contains X, find the real one on the server before the G-Talk callout.', 'Same', 'Low-medium'),
    @('Existing', 'Aura Component', 'CallPanel, CallPanel_Outbound', 'Show Phone_Masked__c instead of the blank Phone__c for masked users (detected on load).', 'Masked users see 98XXXXXX21 instead of an empty line', 'Low'),
    @('No change', 'Aura / LWC', 'MakeCall, utilityCallComponent, offlineCallQuickActionCmp', 'They display what Apex returns and send it back; Apex now handles masked values.', '-', '-'),
    @('Note', 'LWC', 'offlineCallQuickActionCmp', 'Existing issue found (not changed): treats the getLeadPhone result (a map) as a text number and shows a debug alert.', 'Report to the owner of this component', '-')
)
Add-Sheet 'Part 5a Plan' 'Part 5a (v1.5.0) - Calling screens' 'Explained before implementation; originals in backup/v1.5.0-part5a-pre-change' @('New / Existing', 'Type', 'Component', 'Change', 'Effect for users', 'Risk') @(16, 20, 40, 80, 44, 14) $p5a @()

# ---------------- PART 5b PLAN ----------------
$p5b = @(
    @('New', 'Custom Field (formula)', 'Call_Detail__c.Call_To_Masked__c', 'Masked customer number of a call (first 2 + last 2)', 'Masked column for call list views / reports (used at go-live)', 'None'),
    @('New', 'Apex Class (test)', 'PhoneMaskingHistoryTest', 'Tests the masked paths of callRecords, GetData and the log masking (callouts mocked)', '-', '-'),
    @('Existing', 'Apex Class', 'mCubeController.callRecords', 'For masked users, mask Call_From__c / Call_To__c on the returned call list (in memory, never saved)', 'Call history list (mCubeLightningPage) shows 98XXXXXX21 for masked users; unchanged for others', 'Low'),
    @('Existing', 'Apex Class', 'mCubeController.makeCall / makeCallZetta (log__c)', 'Wrap the 3 Request__c and 2 Response__c values in PhoneMaskUtil.maskInText - numbers in the MCube logs are masked for everyone', 'Admins reading log__c see masked numbers (by design); MCube calls unchanged', 'Low'),
    @('Existing', 'Apex Class', 'LeadHistoryandActivityController.GetData', 'For masked users: mask OldValue / NewValue of phone-field history rows (Phone__c, Secondary_Phone__c are history-tracked) and callfrom / callto', 'History screen shows masked old / new numbers for masked users; unchanged for others', 'Low'),
    @('No change', 'Aura', 'mCubeLightningPage, LeadHistoryandActivityCmp', 'They display what Apex returns', '-', '-'),
    @('Later', 'Free text', 'Task Subject / Description in the history', 'Numbers typed in notes are handled by Part 7 (free-text masking)', '-', '-')
)
Add-Sheet 'Part 5b Plan' 'Part 5b (v1.5.0) - Call history and logs' 'Explained before implementation; originals in backup/v1.5.0-part5b-pre-change' @('New / Existing', 'Type', 'Component', 'Change', 'Effect for users', 'Risk') @(16, 22, 44, 80, 50, 12) $p5b @()

# ---------------- PART 5c PLAN ----------------
$p5c = @(
    @('Updated (ours)', 'Apex Class', 'PhoneDisplayService', '+ maskRecords(records, fields): masks phone fields on a result list for masked users (in memory only). + prepareContactInput(recordId, phone, secondaryPhone): a masked value sent back by a screen is replaced by the stored number (never saved masked); for masked users the primary stays locked once set.', 'Same rules as Parts 4 / 5a', 'Low'),
    @('New', 'Apex Class (test)', 'PhoneMaskingLeadToolsTest', 'Merge lists masked / unchanged; Update Contact: masked values never saved, secondary change saved, primary change refused for masked users, unmasked users unchanged', '-', '-'),
    @('Existing', 'Apex Class', 'LeadMergeController', 'getLeads / getSearchLeads: phone numbers in the results masked for masked users (2 return lines become assign + mask + return). mergeLead unchanged.', 'Merge screen shows 98XXXXXX21 for masked users; merge works as before', 'Low'),
    @('Existing', 'Apex Class', 'updateContactDetails', 'getcontactdetails: +1 line (mask for masked users). savecontactdetails: +5 lines at the top (prepareContactInput) - masked values restored to the stored numbers, primary locked for masked users.', 'Masked users: see masked, can change secondary + emails; a masked value is never written back. Others: unchanged.', 'Medium (writes data) - covered by new + existing tests'),
    @('No change', 'Aura', 'LeadMergeCmp, UpdateContactDetails', 'Screens show what Apex returns; the phone inputs have no format check, so masked values pass validation', '-', '-'),
    @('Existing issue (not changed)', 'Apex Class', 'LeadMergeController.getLeads', 'Returns every Lead except the current one with no limit, and the class has no sharing keyword', 'Report to the owner; out of scope', '-')
)
Add-Sheet 'Part 5c Plan' 'Part 5c (v1.5.0) - Lead Merge and Update Contact Details' 'Explained before implementation; originals in backup/v1.5.0-part5c-pre-change' @('New / Existing', 'Type', 'Component', 'Change', 'Effect for users', 'Risk') @(18, 18, 34, 90, 50, 22) $p5c @()

# ---------------- PART 5d PLAN ----------------
$p5d = @(
    @('Existing', 'Apex Class', 'LeadBulkPushController.getSelectedLeads', 'w.mobileNumber = PhoneDisplayService.forDisplay(l.MobilePhone) - 1 line', 'Masked users: masked in the data sent to the screen (Bulk push does not display it). Others: unchanged', 'Low'),
    @('Existing', 'Apex Class', 'LeadYotelBulkPushController.getSelectedLeads', 'w.mobileNumber = PhoneDisplayService.forDisplay(l.Phone__c) - 1 line; eligibility still computed from the real number; the debug line logs the masked number', 'Masked users: Yotel selection table shows 98XXXXXX21. Others: unchanged', 'Low'),
    @('No change', 'Apex', 'pushBulkToDialer, pushBulkToYotel', 'Receive Lead Ids only and read the real numbers on the server - vendors still get real numbers', '-', '-'),
    @('No change', 'LWC / Aura / VF', 'leadBulkPush, leadYotelPush, wrappers, apps, BulkLeadPUSHpage, BulkLeadPushYotel', 'Display what Apex returns', '-', '-'),
    @('New', 'Apex Class (test)', 'PhoneMaskingPushTest', 'Selection lists masked for masked users, unchanged for others; eligibility unchanged', '-', '-'),
    @('Not in scope', 'Apex', 'getUserPicklistValues, rmMobileNumber', 'Agent / user numbers, not customer numbers', '-', '-')
)
Add-Sheet 'Part 5d Plan' 'Part 5d (v1.5.0) - Bulk push and Yotel push' 'Explained before implementation; originals in backup/v1.5.0-part5d-pre-change' @('New / Existing', 'Type', 'Component', 'Change', 'Effect for users', 'Risk') @(16, 18, 44, 80, 54, 10) $p5d @()

# ---------------- PART 5e PLAN ----------------
$p5e = @(
    @('Existing', 'Apex Class', 'LeadMsgConversationController.getConversationViaConnectApi', 'Before returning the conversation: for masked users, mask numbers inside message, rawJson and senderName (PhoneMaskUtil.maskInText) - one call to a new @TestVisible helper', 'Masked users: chat shows the same messages with any phone number masked; the raw data never carries the WhatsApp number. Others: unchanged', 'Low'),
    @('No change', 'Apex', 'getMessagingSessionId, getTransferContext, transferMessagingSession, getSessionAttachments', 'Use Full_phone_number__c on the server only; return Ids, status, files - no number', '-', '-'),
    @('No change', 'LWC', 'leadMsgConversationLWC', 'Displays what Apex returns', '-', '-'),
    @('New', 'Apex Class (test)', 'PhoneMaskingWhatsAppTest', 'Conversation rows masked for masked users, unchanged for others (Connect API not called - helper tested directly)', '-', '-'),
    @('Go-live decision (D4)', 'Standard objects', 'MessagingEndUser / MessagingSession', 'Presales outbound has View All on both; the WhatsApp customer record shows the number in standard screens, reports, search. Needs a go-live decision (remove View All / restrict) without breaking chat for reps', 'Not changed in 5e', 'Decision'),
    @('Later (Part 7)', 'Apex', 'notifyLeadStakeholders(messagePreview)', 'Preview text typed in chat - free-text masking', '-', '-'),
    @('Test limit', 'Data', 'Sandbox has 0 MessagingEndUser records', 'The chat cannot be tested on screen in the sandbox (no WhatsApp data copied)', '-', '-')
)
Add-Sheet 'Part 5e Plan' 'Part 5e (v1.5.0) - WhatsApp chat' 'Explained before implementation; originals in backup/v1.5.0-part5e-pre-change' @('New / Existing', 'Type', 'Component', 'Change', 'Effect for users', 'Risk') @(18, 18, 48, 84, 54, 12) $p5e @()
