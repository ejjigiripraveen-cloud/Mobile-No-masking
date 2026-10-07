# Changelog – Mobile Number Masking

Versioning follows Semantic Versioning. Every version is a git tag in this folder's local-only history (never pushed).

Commands: `Revoke to original` (back to v1.0.0) · `Create checkpoint <name>` · `Revert to <version>`.
Reverting local files is immediate. Reverting the sandbox means redeploying the older metadata and removing newly added components, and happens only after explicit approval.

## v1.5.0 (5d) – Bulk push and Yotel push selection lists masked (deployed to sandbox 2026-10-07)

- **Commit Version:** v1.5.0 (Part 5d)
- **Type:** feat
- **Branch:** `ejjigiripraveen/v1.5.0-part5d-push`
- **Sandbox deploy:** 0Afft000000Lm1dCAC (3/3, **10 tests passed** incl. existing LeadBulkPushControllerTest, LeadYotelBulkPushControllerTest). Coverage: LeadBulkPushController 98.5% · LeadYotelBulkPushController 95.8%. First attempt 0Afft000000LlwnCAC rolled back: my new Yotel test expected real data, but the existing code also swaps in an empty Lead while tests run – test corrected.
- **Testing:** on hold – owner access issue (D2).
- **Backup of originals (before any change):** `backup/v1.5.0-part5d-pre-change` (commit `8e5a8d4`, 29 files; wrappers, apps and the 2 VF host pages first backed up here)
- **Modified Assets:**
  - New: `PhoneMaskingPushTest`.
  - Existing (approved 2026-10-07), 3 lines in total:
    - `LeadBulkPushController.getSelectedLeads` – `w.mobileNumber = PhoneDisplayService.forDisplay(l.MobilePhone)`.
    - `LeadYotelBulkPushController.getSelectedLeads` – `w.mobileNumber = PhoneDisplayService.forDisplay(l.Phone__c)`; the debug line logs `PhoneMaskUtil.mask(l.Phone__c)` (everyone). Eligibility still uses the real number.
  - No change: `pushBulkToDialer`, `pushBulkToYotel` (Lead Ids only; real numbers read on the server), LWCs, wrappers, apps, VF pages.
  - Note: the existing `LeadBulkPushController.getSelectedLeads` replaces its query result with an empty Lead while tests run (`if(Test.isRunningTest())`), so its masked line is checked on that record; the rule itself is tested elsewhere.
- **Deploy:** `sf project deploy start --manifest manifest/v1.5.0-5d/package.xml --test-level RunSpecifiedTests --tests PhoneMaskingPushTest --tests LeadBulkPushControllerTest --tests LeadYotelBulkPushControllerTest`
- **Rollback:** redeploy both controllers from `backup/v1.5.0-part5d-pre-change`, then `manifest/v1.5.0-5d/destructiveChanges.xml`.

### Access sheet – v1.5.0 (5d)

| Item | Who | Action |
|---|---|---|
| Changed classes | Existing users | Already granted; no change |

## v1.5.0 (5c) – Lead Merge and Update Contact Details masked (deployed to sandbox 2026-10-07)

- **Commit Version:** v1.5.0 (Part 5c)
- **Type:** feat
- **Branch:** `ejjigiripraveen/v1.5.0-part5c-lead-tools`
- **Sandbox deploy:** 0Afft000000LkRFCA0 (4/4, **23 tests passed**: PhoneMaskingLeadToolsTest 13, PhoneDisplayServiceTest, existing LeadMergeControllerTest). Coverage: PhoneDisplayService 92.9% · updateContactDetails 84.6% · LeadMergeController 79.3% (whole class).
- **Pre-existing test failure found:** the existing `updateContactDetailsTest.testcontact` fails **before** Part 5c (verified against the unchanged sandbox code): `Too many SOQL queries: 101` in `LeadTrigger` line 232. It is excluded from the 5c test run; `PhoneMaskingLeadToolsTest` now also covers the existing duplicate / formatting / no-change / no-access branches of `savecontactdetails` (one save per test). Attempts 0Afft000000LkMPCA0 (that test) and 0Afft000000LkJCCA0 (coverage 58.2% without it) were rolled back. **Production:** do not include `updateContactDetailsTest` in the specified tests (see deferred item D3).
- **Backup of originals (before any change):** `backup/v1.5.0-part5c-pre-change` (commit `dd2bb88`, 22 files identical to baseline)
- **Found:** `savecontactdetails` saves whatever the screen sends – masking only the display would have overwritten real numbers with masked ones.
- **Modified Assets:**
  - New: `PhoneMaskingLeadToolsTest` (8 tests).
  - Updated (ours): `PhoneDisplayService` (+ `maskRecords`, `prepareContactInput` / `ContactInput`).
  - Existing (approved 2026-10-07):
    - `LeadMergeController` – `getLeads` / `getSearchLeads`: the 2 `return [query]` lines became assign + `maskRecords` + return. `mergeLead` unchanged.
    - `updateContactDetails` – `getcontactdetails`: +1 line (mask). `savecontactdetails`: +7 lines at the top (`prepareContactInput`): masked values replaced by the stored numbers, primary locked for masked users. 0 lines removed.
  - No change: `LeadMergeCmp`, `UpdateContactDetails`.
  - Existing issue noted (not changed): `LeadMergeController.getLeads` returns every Lead except the current one with no limit; class has no sharing keyword.
- **Deploy:** `sf project deploy start --manifest manifest/v1.5.0-5c/package.xml --test-level RunSpecifiedTests --tests PhoneMaskingLeadToolsTest --tests PhoneDisplayServiceTest --tests LeadMergeControllerTest --tests updateContactDetailsTest`
- **Rollback:** redeploy `LeadMergeController`, `updateContactDetails` from `backup/v1.5.0-part5c-pre-change` and `PhoneDisplayService` from the 5b branch, then `manifest/v1.5.0-5c/destructiveChanges.xml`.

### Access sheet – v1.5.0 (5c)

| Item | Who | Action |
|---|---|---|
| Changed classes | Existing users | Already granted; no change |
| New fields / permissions | – | None |

## v1.5.0 (5b) – Call history and logs masked (deployed to sandbox 2026-10-06)

- **Commit Version:** v1.5.0 (Part 5b)
- **Type:** feat
- **Branch:** `ejjigiripraveen/v1.5.0-part5b-history`
- **Sandbox deploy:** 0Afft000000LfszCAC (5/5, **61 tests passed** incl. existing mCubeController_Test, mCubeControllerTestExtended, LeadHistoryandActivityControllerTest).
- **Coverage:** PhoneDisplayService 100% · LeadHistoryandActivityController 87.1% · mCubeController 81.4% (whole 1,969-line class).
- **Backup of originals (before any change):** `backup/v1.5.0-part5b-pre-change` (commit `d21280f`, 23 files; `LeadHistoryandActivityCmp` first backed up here)
- **Found:** `Lead.Phone__c` and `Lead.Secondary_Phone__c` are field-history tracked, and the History & Activity screen returned old / new numbers.
- **Modified Assets:**
  - New: `PhoneMaskingHistoryTest`, `Call_Detail__c.Call_To_Masked__c` (formula).
  - Updated (ours): `PhoneDisplayService` (+ `forDisplay`, `historyValueForDisplay`).
  - Existing (approved 2026-10-06):
    - `mCubeController` – `callRecords`: +7 lines, masks Call From / Call To for masked users (in memory only). `makeCall` / `makeCallZetta`: the 3 `log__c.Request__c` and 2 `Response__c` assignments wrapped in `PhoneMaskUtil.maskInText` – numbers in MCube logs are masked **for everyone**.
    - `LeadHistoryandActivityController` – `GetData`: +3 lines masking phone history values, 2 lines changed to mask call numbers, for masked users.
  - No change: `mCubeLightningPage`, `LeadHistoryandActivityCmp`.
  - Later (Part 7): numbers typed into Task subject / description.
- **Deploy:** `sf project deploy start --manifest manifest/v1.5.0-5b/package.xml --test-level RunSpecifiedTests --tests PhoneMaskingHistoryTest --tests PhoneDisplayServiceTest --tests mCubeController_Test --tests mCubeControllerTestExtended --tests LeadHistoryandActivityControllerTest`
- **Rollback:** redeploy `mCubeController`, `LeadHistoryandActivityController` from `backup/v1.5.0-part5b-pre-change` and `PhoneDisplayService` from the 5a branch, then `manifest/v1.5.0-5b/destructiveChanges.xml`.

### Access sheet – v1.5.0 (5b)

| Item | Who | Action |
|---|---|---|
| `Call_Detail__c.Call_To_Masked__c` (read) | Rep profiles | At go-live (Part 11), with the call list views |
| Changed classes | Existing users | Already granted; no change |

## v1.5.0 (5a) – Calling screens masked (deployed to sandbox 2026-10-06, call panels postponed)

- **Commit Version:** v1.5.0 (Part 5a)
- **Type:** feat
- **Branch:** `ejjigiripraveen/v1.5.0-part5a-calling`
- **Sandbox deploys:** code 0Afft000000Lf3NCAS (7/7, **45 tests passed** incl. existing MakeCallControllerTest, OfflineCallAppAPITest, MaskedDialServiceTest) · pilot 0Afft000000Lf4zCAC (POC profile reads Phone_Masked__c).
- **Coverage:** PhoneDisplayService 100% · MaskedDialService 99.5% · MakeCallController 93.1% · OfflineCallAppAPI 78.5% (whole class).
- **Call panels postponed:** attempts 0Afft000000Lf09CAC and 0Afft000000Lf1lCAC failed and rolled back – the Aura `lightning:recordViewForm` has no `onload` event (it exists only in LWC). `CallPanel` / `CallPanel_Outbound` restored locally to the original; a new approach is proposed for approval. Masked users still see an empty Phone line on the call panels until then (no leak).
- **Observed:** Salesforce gave read on `Phone_Masked__c` to the same 22 profiles as the entry fields (23 incl. POC). Harmless – the field only shows the masked number.
- **Backup of originals (before any change):** `backup/v1.5.0-part5a-pre-change` (commit `3c0330b`, 33 files identical to baseline)
- **Modified Assets:**
  - New: `PhoneDisplayService` (one masking rule for all screens; resolves a masked number on the server with record-access check + audit), `PhoneDisplayServiceTest`, `PhoneMaskingCallScreensTest`, `Lead.Phone_Masked__c` (formula).
  - Updated (ours): `MaskedDialService` (+ `logAccess`), POC Masked Rep (read `Phone_Masked__c`).
  - Existing (approved 2026-10-06):
    - `MakeCallController` – original `readContacts` body renamed `collectPhones` and original `callCustomer` body renamed `placeMcubeCall` (bodies unchanged); new `readContacts` returns masked for masked users; new `callCustomer` resolves a masked selection then calls `placeMcubeCall`. Audit written after the MCube callout.
    - `OfflineCallAppAPI` – `triggerCall` resolves a masked number before enqueueing the G-Talk callout; `getLeadPhone` / `getOppPhone` mask the map for masked users (+33 lines, 0 removed).
    - `CallPanel`, `CallPanel_Outbound` – `isMaskedUser` attribute, `onload` on the view form, `Phone_Masked__c` for masked users; original `Phone__c` line unchanged in the `else`.
  - No change: `MakeCall`, `utilityCallComponent`, `offlineCallQuickActionCmp` (they show what Apex returns and send it back).
- **Rule:** masking applies only to users who cannot read `Lead.Phone__c`; all other users get exactly the previous data.
- **Noted, not changed:** `offlineCallQuickActionCmp` treats the phone map as a text number and shows a debug `alert` – existing issue for its owner.
- **Deploy:**
  1. `sf project deploy start --manifest manifest/v1.5.0-5a/package.xml --test-level RunSpecifiedTests --tests PhoneDisplayServiceTest --tests PhoneMaskingCallScreensTest --tests MakeCallControllerTest --tests OfflineCallAppAPITest --tests MaskedDialServiceTest`
  2. `sf project deploy start --manifest manifest/v1.5.0-5a/package-pilot.xml --test-level NoTestRun`
- **Rollback:** redeploy the 4 changed components from `backup/v1.5.0-part5a-pre-change` and `MaskedDialService` from the v1.4.0 branch, then `manifest/v1.5.0-5a/destructiveChanges.xml`.

### Access sheet – v1.5.0 (5a)

| Item | Who | Action |
|---|---|---|
| `Lead.Phone_Masked__c` (read) | POC Masked Rep | Pilot manifest; all rep profiles at go-live (Part 11) |
| `PhoneDisplayService` | – | Called by other Apex; no class access needed |
| `MakeCallController`, `OfflineCallAppAPI` | Existing users | Already granted; no change |

## v1.4.0 – Lead creation with hidden numbers (deployed to sandbox 2026-10-06)

- **Commit Version:** v1.4.0
- **Type:** feat
- **Branch:** `ejjigiripraveen/v1.4.0-lead-entry`
- **Sandbox deploys:** code 0Afft000000Lc77CAC (7/7, **20 tests passed** incl. existing LeadTriggerTest + LeadTriggerHandlerTest) · pilot 0Afft000000LcALCA0 (POC profile + POC page).
- **Coverage:** LeadPhoneEntryHandler 100% · LeadTrigger 80.1% (whole trigger).
- **Observed after deploy:** Salesforce automatically gave **read-only** access to the two new entry fields to 22 existing profiles (e.g. Sales, Presales TL, Presales Head, MIS). Harmless – the fields are always empty and on no page – and left as is; reviewed again with all profiles at go-live (Part 11).
- **Backup of originals (before any change):** `backup/v1.4.0-pre-change` (commit `9b32c8c`, SHA256SUMS)
- **Modified Assets:**
  - New: `Lead.Phone_Entry__c` (label "Phone"), `Lead.Secondary_Phone_Entry__c` (label "Secondary Phone"), `LeadPhoneEntryHandler`, `LeadPhoneEntryHandlerTest` (11 tests).
  - Existing (approved 2026-10-06), additions only:
    - `LeadTrigger` – +6 lines at the top: `LeadPhoneEntryHandler.beforeSave(Trigger.new, Trigger.oldMap)` for before insert / update. 0 lines removed.
    - `NewLeadCmp`, `NewRefLeadCmp` – +1 attribute `isMaskedUser`; the Phone / Secondary Phone inputs wrapped in `aura:if` (entry fields for masked users, the original inputs unchanged in the `else`); +1 call in the existing `handleCreateLoad`; +1 helper function `detectMaskedUser`. Only the 2 original input lines per form moved into the `else`.
  - Updated (our components): POC Masked Rep (edit access to the 2 entry fields), `Sales_Lead_Record_Page_Masked_POC` (Secondary Phone entry field after Name).
  - Not changed: `RelatedSourceHandler`, `LeadTriggerHandler`, `New_Lead_Page`, `New_Lead_Page1_sales` (Part 11), integrations.
- **Changelog:**
  - Entry values are copied to `Phone__c` / `Secondary_Phone__c` before the existing formatting, duplicate check and validation rules, then cleared.
  - Primary is locked once set: an entry value that would change it fails with "The primary number cannot be changed once it is set…". The same number in another format is accepted. Secondary can always be added or changed.
  - The forms detect a masked user from the form's own field info (no Apex call): users who can see `Phone__c` get exactly the old form.
- **Deploy:**
  1. `sf project deploy start --manifest manifest/v1.4.0/package.xml --test-level RunSpecifiedTests --tests LeadPhoneEntryHandlerTest --tests LeadTriggerTest --tests LeadTriggerHandlerTest`
  2. `sf project deploy start --manifest manifest/v1.4.0/package-pilot.xml --test-level NoTestRun`
- **Rollback:** redeploy `LeadTrigger`, `NewLeadCmp`, `NewRefLeadCmp` from `backup/v1.4.0-pre-change` and the v1.3.0 POC page / profile (`git show ejjigiripraveen/v1.3.0-dialer-adapters:<path>`), then `manifest/v1.4.0/destructiveChanges.xml`.

### Access sheet – v1.4.0

| Item | Who | Action |
|---|---|---|
| `Phone_Entry__c`, `Secondary_Phone_Entry__c` (edit) | POC Masked Rep | Pilot manifest |
| Same fields (edit) | All rep profiles that create Leads | **Go-live (Part 11)** |
| `LeadPhoneEntryHandler` | – | Runs inside LeadTrigger; no class access needed |
| Other users | – | No change |

## v1.3.0 – Dialer adapters MCube + SlashRTC, POC (deployed to sandbox 2026-10-06)

- **Commit Version:** v1.3.0
- **Type:** feat
- **Branch:** `ejjigiripraveen/v1.3.0-dialer-adapters`
- **Sandbox deploys:** code 0Afft000000LY6jCAG (8/8, **60 tests passed** incl. existing McubeSoftphoneAddOnControllerTest) · pilot 0Afft000000LYBZCA4 (page click-to-dial ON, POC profile + MaskedDialServiceCTI). First attempt 0Afft000000LY57CAG failed and rolled back (missing `McubeMaskedClickToCallTest.cls-meta.xml`, added).
- **Coverage:** MaskedDialService 100% · MaskedDialServiceCTI 94.4% · McubeSoftphoneAddOnController 87.9%
- **SlashRTC CTI Adapter URL:** changed **manually in Setup by the project owner** (sandbox only) – the `sandbox-only/` file is kept as reference, not deployed.
- **Production bundle:** `release/prod/part3-dialers` (+ part1-foundations rebuilt with the updated MaskedDialService / MaskedDialServiceCTI).
- **Backup of originals (before any change):** `backup/v1.3.0-pre-change` (commit `f2c7e4f`, SHA256SUMS)
- **Modified Assets:**
  - Existing (approved 2026-10-06):
    - `McubeSoftphoneAddOnController` – **added** `clickToCallMasked(recordId, fieldKey, maskedNumber)`; +37 lines, 0 removed; existing methods untouched.
    - `mcubeSoftphoneCTIAddOn` (page) – `getMaskedClick()` helper + one branch in `onClickToDial`; the original `clickToCallRemote` call is unchanged in the "normal click" branch.
    - `slashPhone` (`slashPhoneHelper.js`) – masked-click step in front of the original flow (`continueClickToDial`, unchanged); only 2 blank lines removed.
  - Updated (our components): `MaskedDialService` (deferred audit for callouts, `fieldKeyForMaskedNumber`), `MaskedDialServiceCTI` (`resolveMaskedClick`), `MaskedDialServiceTest` (+5), `MaskedDialServiceCTITest` (+3), POC Masked Rep (+ `MaskedDialServiceCTI` access), `Sales_Lead_Record_Page_Masked_POC` (click-to-dial ON).
  - New: `McubeMaskedClickToCallTest` (7 tests, MCube mocked).
  - Sandbox only: `sandbox-only/v1.3.0-slashrtc-adapter-url` – SlashRTC adapter URL `/apex/index` (production URL untouched).
- **Changelog:**
  - Masked click detected by `fieldKey=` in the click params **or** an `X` in the clicked number (real numbers never contain X). If the softphone does not pass the params, the field is identified from the masked value (`fieldKeyForMaskedNumber`).
  - MCube: real number resolved and dialed on the server – never sent to the page. Audit row written after the MCube callout, with the call result (`MCube: Call initiated.`).
  - SlashRTC: real number resolved through Open CTI `runApex` and handed to the existing dialer flow (number exists briefly in the softphone – vendor limitation).
  - Normal `Phone__c` clicks follow the original code for every dialer.
- **Deploy:**
  1. `sf project deploy start --manifest manifest/v1.3.0/package.xml --test-level RunSpecifiedTests --tests MaskedDialServiceTest --tests MaskedDialServiceCTITest --tests McubeMaskedClickToCallTest --tests McubeSoftphoneAddOnControllerTest`
  2. `sf project deploy start --manifest manifest/v1.3.0/package-pilot.xml --test-level NoTestRun`
  3. Sandbox only: `sf project deploy start --metadata-dir sandbox-only/v1.3.0-slashrtc-adapter-url`
- **Rollback:** deploy `backup/v1.3.0-pre-change` (page, controller, slashPhone, call center) and the v1.2.0 versions of the Part 1 classes (`git show ejjigiripraveen/v1.2.0-masked-panel:<path>`), then `manifest/v1.3.0/destructiveChanges.xml` to remove `McubeMaskedClickToCallTest`.
- **Before testing:** POC MCube Rep needs `MobilePhone` = agent number registered with MCube; SlashRTC agent for the POC SlashRTC Rep email and sandbox origin allowed; a Pre Sales test Lead per test user.

### Access sheet – v1.3.0

| Item | Who | Action |
|---|---|---|
| `MaskedDialServiceCTI` | POC Masked Rep | Granted by the profile overlay (pilot manifest) |
| `McubeSoftphoneAddOnController` | POC Masked Rep | Already granted (inherited from Presales outbound) |
| Click-to-dial on the panel | POC Masked Rep (masked page) | Page property in the pilot manifest |
| Other users | – | No change |

## v1.2.0 – Masked phone panel, POC users only (built locally 2026-10-05 · NOT deployed)

- **Commit Version:** v1.2.0
- **Type:** feat + permission-update
- **Branch:** `ejjigiripraveen/v1.2.0-masked-panel` (from v1.1.0)
- **Modified Assets:**
  - New: Apex `MaskedPhonePanelController` + `MaskedPhonePanelControllerTest`; LWC `maskedPhonePanel` (+ 2 Jest test files); FlexiPage `Sales_Lead_Record_Page_Masked_POC` (copy of `Sales_Lead_Record_Page` + panel at the top of the left column); profile overlay `POC Masked Rep` (25 phone fields hidden, class access to the panel controller).
  - Existing (approved): `Pre_Sales` app ("Gsquare Housing") – **one new row**: Lead · View · Pre Sales record type · desktop · profile POC Masked Rep → `Sales_Lead_Record_Page_Masked_POC`. No existing row changed. Pre-change snapshot committed as `1adf63f`.
  - Untouched: `Sales_Lead_Record_Page`, `Lead_Record_Page`, all other profiles, users and code.
- **Changelog:**
  - Panel shows Primary / Secondary masked (`98XXXXXX21`), "No secondary number" when empty, error and empty states; reloads when the record is saved.
  - Apex returns masked values only (1 query, no DML, `with sharing`, object access check). The real number never reaches the browser.
  - Click-to-dial is an App Builder option, **off** on the POC page until Part 3; never shown on mobile.
- **Deploy order:**
  1. Admin clones **Presales outbound** → **POC Masked Rep** in Setup → Profiles (manual, new profile).
  2. `sf project deploy start --manifest manifest/v1.2.0/package-code.xml --test-level RunSpecifiedTests --tests MaskedPhonePanelControllerTest`
  3a. `sf project deploy start --manifest manifest/v1.2.0/package-profile.xml --test-level NoTestRun` – ✅ deployed 2026-10-05 (0Afft000000LRzhCAG).
  3b. **Manual, Lightning App Builder:** open `Sales_Lead_Record_Page_Masked_POC` → Activation → App, Record Type, and Profile → app *Gsquare Housing*, form factor *Desktop*, record type *Pre Sales*, profile *POC Masked Rep* → Save. (The `Pre_Sales` app cannot be deployed by metadata: two pairs of same-named "Analytics Cloud" profiles appear as duplicate rows. `package-access.xml` is kept for reference only.)
  4. Create 2 test users (Salesforce licence, profile POC Masked Rep): one with the MCube call center, one with SlashRTC.
- **Rollback:** redeploy the pre-change app (`git show 1adf63f:force-app/main/default/applications/Pre_Sales.app-meta.xml`), then `sf project deploy start --manifest manifest/v1.2.0/package-empty.xml --post-destructive-changes manifest/v1.2.0/destructiveChanges.xml`, then move test users off the POC profile and delete it in Setup.
- **Not yet run:** Apex tests (run in the org at validation) and Jest tests (Node.js is not installed on this machine).

### Access sheet – v1.2.0

| Item | Who | Action |
|---|---|---|
| Apex `MaskedPhonePanelController` | POC Masked Rep | Granted by the profile overlay (step 3). Reps get it at go-live. |
| LWC `maskedPhonePanel` | — | No access setting; it shows only on the cloned page. |
| Page `Sales_Lead_Record_Page_Masked_POC` | POC Masked Rep, Gsquare Housing app, Pre Sales Leads, desktop | One app assignment row (step 3). |
| Phone fields (25) | POC Masked Rep | Read and edit removed (step 3). All other profiles unchanged. |
| Test users (2) | New users | Profile POC Masked Rep; call center MCube / SlashRTC (step 4). |

## v1.1.0 – Foundations (built locally 2026-10-05 · NOT deployed)

- **Commit Version:** v1.1.0
- **Type:** feat
- **Deployed to sandbox 2026-10-05** – quick deploy 0Afft000000LO8zCAG, 44/44 components. Read-only tests 1–2 passed (11/11 masking cases, all settings as expected).
- **Status (before deploy):** built locally and **validated (check-only) in sandbox 2026-10-05** – validation 0Afft000000LMITCA4, 42 tests passed, 0 failures. Nothing saved to the org. Deploy only when told; git tag `v1.1.0` is added after the sandbox test passes.
- **Coverage (validation):** PhoneMaskUtil 100% · MaskedDialService 100% · PhoneMaskingConfig 98.2% · MaskedDialServiceCTI 93.5%
- **Modified Assets (all new – no existing component changed):**
  - Apex: `PhoneMaskingConfig`, `PhoneMaskUtil`, `MaskedDialService`, `MaskedDialServiceCTI`
  - Apex tests: `PhoneTestDataFactory`, `PhoneMaskingConfigTest`, `PhoneMaskUtilTest`, `MaskedDialServiceTest`, `MaskedDialServiceCTITest`
  - Custom metadata types: `Phone_Masking_Setting__mdt` (8 fields) + record `Default`; `Masked_Phone_Field__mdt` (7 fields) + records `Lead_Phone`, `Lead_Secondary_Phone`
  - Custom object: `Phone_Access_Audit__c` (11 fields, Private sharing, list view "All") + tab
  - Permission set: `Phone_Access_Audit_Viewer` (read-only audit access + tab)
- **Changelog:**
  - Masking engine: `98XXXXXX21` format, removes +91 / 0091 / leading 0, masks numbers inside free text, settings from custom metadata.
  - Secure real-number lookup for dialers: approved-field list, object access + record sharing check, kill switch, bulk-safe (1 query per object, 1 insert), audit of every request with the masked number only.
  - Open CTI entry point (`global webservice`) for the SlashRTC softphone.
- **Changes vs. the plan presented before building:** added `PhoneMaskingConfig` (shared settings reader); kill switch named `Resolve_Enabled__c` ("Real Number Lookup Enabled") – it stops number lookups and never un-masks anything; added `Message__c` to the audit object; added `Phone_Access_Audit_Viewer` permission set instead of editing the existing System Administrator profile.
- **Deploy:** `sf project deploy start --manifest manifest/v1.1.0/package.xml --test-level RunSpecifiedTests --tests PhoneMaskingConfigTest PhoneMaskUtilTest MaskedDialServiceTest MaskedDialServiceCTITest`
- **Validation fixes:** audit object Bulk/Streaming/Sharing flags aligned; plain `Database.insert(rows, false)` for audit rows; test assertion fixes (`===` instead of non-existent `Assert.areSame`, non-null assert messages).
- **Rollback:** `sf project deploy start --manifest manifest/v1.1.0/package-empty.xml --post-destructive-changes manifest/v1.1.0/destructiveChanges.xml` (removes only the new components; audit data, if any, is deleted with the object).

### Access sheet – v1.1.0

| Item | Who | Action |
|---|---|---|
| Apex `PhoneMaskingConfig`, `PhoneMaskUtil`, `MaskedDialService` | Nobody | Called only by other Apex; no class access needed. |
| Apex `MaskedDialServiceCTI` | Nobody yet | Added to the POC profile in v1.2.0 / v1.3.0, rep profiles at go-live. |
| `Phone_Access_Audit__c` object + tab | System Administrators | Assign permission set **Phone Access Audit Viewer** (read-only, View All). |
| `Phone_Access_Audit__c` | Reps / other users | No access. Audit rows are written by the service in system mode. |
| Custom metadata | Nobody | Read by Apex. Admins edit records in Setup → Custom Metadata Types. |
| Users | — | Only the permission set assignment above (optional until testing). |

## v1.0.0 – ORIGINAL BASELINE (2026-10-03)

- **Type:** baseline
- **Source:** sandbox `gsquaregroup--prodreplic` (org 00Dft000000AiZFEA0), retrieved read-only with `manifest/baseline-package.xml`.
- **Contents:** current state of every component the masking project may change:
  - 44 Apex classes (21 impacted + 23 test classes), 1 trigger (`LeadTrigger`)
  - 12 Aura bundles, 11 LWC bundles, 21 Visualforce pages (incl. MCube and SlashRTC adapters)
  - 4 Lightning pages, 4 Contact quick actions, 3 screen flows
  - 3 call centers (360CTI, SlashRTC, MCube)
  - 38 phone-related field definitions
  - All profiles and permission sets, scoped to the fields and classes above (field-level security and Apex class access)
- **Notes:** two system profiles named "Analytics Cloud Integration User" / "Analytics Cloud Security User" exist twice in the org; only one copy of each was retrieved. They are not affected by this project.
- **Immutable:** do not change this version unless explicitly told to update the baseline.
