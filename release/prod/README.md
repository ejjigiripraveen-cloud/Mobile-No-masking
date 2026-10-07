# Production Release Bundle – Parts 1 to 4

Deploy-ready copies (Metadata API format) of the exact source that was deployed and tested in the
sandbox. At the end of the project, deploy these folders to production in the order below, after any
later parts that change them have been rebuilt (see "Rebuild").

| Folder | Part | For | Sandbox deploy (tested) |
|---|---|---|---|
| `part1-foundations/` | Part 1 – v1.1.0 (+ v1.3.0 updates of MaskedDialService / MaskedDialServiceCTI) | **Production – everyone** | 0Afft000000LO8zCAG, updated 0Afft000000LY6jCAG · MaskedDialService 100%, MaskedDialServiceCTI 94.4% |
| `part2-panel/` | Part 2 – v1.2.0 | **Production – everyone** | 0Afft000000LRq1CAG · 11 tests · 100% |
| `part2-pilot/` | Part 2 + 3 | **Production pilot only** (removed after go-live) | 0Afft000000LRq1CAG / 0Afft000000LRzhCAG / 0Afft000000LYBZCA4 (v1.3.0: click-to-dial on, softphone class access) |
| `part3-dialers/` | Part 3 – v1.3.0 | **Production – everyone** (MCube + SlashRTC adapters) | 0Afft000000LY6jCAG · 60 tests · McubeSoftphoneAddOnController 87.9% |

Checksums of every file: `SHA256SUMS`. Full component list and order: `docs/Mobile_Masking_Component_Register.xlsx` → sheet *Prod Deployment List*.

---

## What is in each folder

### part1-foundations (deploy first)
| Type | Components |
|---|---|
| Custom metadata types | `Phone_Masking_Setting__mdt` (8 fields), `Masked_Phone_Field__mdt` (7 fields) |
| Custom metadata records | `Phone_Masking_Setting.Default`, `Masked_Phone_Field.Lead_Phone`, `Masked_Phone_Field.Lead_Secondary_Phone` |
| Custom object | `Phone_Access_Audit__c` (11 fields, list view All) + tab |
| Apex | `PhoneMaskingConfig`, `PhoneMaskUtil`, `MaskedDialService`, `MaskedDialServiceCTI` |
| Apex tests | `PhoneTestDataFactory`, `PhoneMaskingConfigTest`, `PhoneMaskUtilTest`, `MaskedDialServiceTest`, `MaskedDialServiceCTITest` |
| Permission set | `Phone_Access_Audit_Viewer` |

### part2-panel (deploy second)
| Type | Components |
|---|---|
| Apex | `MaskedPhonePanelController` + `MaskedPhonePanelControllerTest` |
| LWC | `maskedPhonePanel` (Jest tests are excluded – they never deploy) |

### part2-pilot (only for the production pilot)
| Type | Components | Before deploying |
|---|---|---|
| Lightning page | `Sales_Lead_Record_Page_Masked_POC` | – |
| Profile overlay | `POC Masked Rep` (25 phone fields hidden, panel class access) | **Clone `Presales outbound` → `POC Masked Rep` in Setup first** |

---

## Pre-checks in production
1. Lead fields `Phone__c`, `Secondary_Phone__c` exist.
2. Apex class `Utility` has `public static Boolean bypassLeadTrigger` (used by the tests).
3. Profiles **Standard User** and **Minimum Access - Salesforce** exist (used by the tests).
4. Deployment user has "Modify All Data" / "Author Apex".

## Deploy commands (Salesforce CLI)
Replace `<prod>` with the production org alias. Always **validate first**, then quick-deploy the validation.

```bash
# 1. Part 1 – validate, then quick deploy
sf project deploy validate --metadata-dir release/prod/part1-foundations --target-org <prod> \
  --test-level RunSpecifiedTests --tests PhoneMaskingConfigTest --tests PhoneMaskUtilTest --tests MaskedDialServiceTest --tests MaskedDialServiceCTITest
sf project deploy quick --job-id <validation id> --target-org <prod>

# 2. Part 2 panel – validate, then quick deploy
sf project deploy validate --metadata-dir release/prod/part2-panel --target-org <prod> \
  --test-level RunSpecifiedTests --tests MaskedPhonePanelControllerTest
sf project deploy quick --job-id <validation id> --target-org <prod>

# 3. Pilot only – after cloning the POC profile in Setup
sf project deploy start --metadata-dir release/prod/part2-pilot --target-org <prod> --test-level NoTestRun
```

Without the CLI: build an outbound change set in the sandbox with the same components (list in the Excel register), test level **Run specified tests** with the test classes above.

## Manual steps after deploy
| # | Step | Where |
|---|---|---|
| 1 | Assign **Phone Access Audit Viewer** to the admins who review audits | Setup → Permission Sets |
| 2 | (Pilot) Activate `Sales_Lead_Record_Page_Masked_POC` for app *Gsquare Housing*, Desktop, record type *Pre Sales*, profile *POC Masked Rep* | Lightning App Builder → Activation |
| 3 | (Pilot) Assign the pilot users to *POC Masked Rep* | Setup → Users |

The `Pre_Sales` app cannot be deployed by metadata (two pairs of same-named "Analytics Cloud" profiles), so step 2 is always manual.

## Check after deploy
Run `scripts/apex/v1.1.0-1-mask-format.apex` and `v1.1.0-2-settings.apex` in Execute Anonymous (read-only) → `RESULT: 11 passed, 0 failed` and all settings as expected. Full test steps: `DEPLOYMENT_v1.1.0.md`, `TEST_PLAN.md`.

## Rollback
```bash
# Part 2 panel (remove from any Lightning page first)
sf project deploy start --manifest release/prod/package-empty.xml --post-destructive-changes release/prod/part2-panel-rollback-destructiveChanges.xml --target-org <prod>
# Part 1
sf project deploy start --manifest release/prod/package-empty.xml --post-destructive-changes release/prod/part1-foundations-rollback-destructiveChanges.xml --target-org <prod>
```
Pilot: deactivate the page in App Builder, move pilot users back to their profile, delete the page and the POC profile.

## Rebuild
Later parts change some of these components (for example Part 6 adds Reveal to `maskedPhonePanel`). Before the production deployment, rebuild from the final code:

```bash
bash scripts/release/build-prod-release.sh
```
Each new part adds its own folder (`part3-…`, `part4-…`) and a line to that script.

---

## Part 3 – v1.3.0 (added 2026-10-06)

### part3-dialers (deploy third, after part1-foundations and part2-panel)
| Type | Components | Change |
|---|---|---|
| Apex | `McubeSoftphoneAddOnController` | **Existing** – adds `clickToCallMasked` only |
| Apex test | `McubeMaskedClickToCallTest` | New (MCube mocked) |
| Visualforce | `mcubeSoftphoneCTIAddOn` | **Existing** – masked-click branch; normal clicks unchanged |
| Aura | `slashPhone` | **Existing** – masked-click step; normal clicks unchanged |

Originals: `backup/v1.3.0-pre-change`. Rollback: `part3-dialers-rollback-README.md`.

```bash
sf project deploy validate --metadata-dir release/prod/part3-dialers --target-org <prod> \
  --test-level RunSpecifiedTests --tests McubeMaskedClickToCallTest --tests McubeSoftphoneAddOnControllerTest
sf project deploy quick --job-id <validation id> --target-org <prod>
```

Notes for production:
- The SlashRTC **CTI Adapter URL change is sandbox only** – production keeps `https://gsquaregroup.lightning.force.com/apex/index`.
- Click-to-dial on the panel is switched on by the Lightning page property (pilot page in `part2-pilot`; real pages at go-live, Part 11).
- Pilot MCube users need `User.MobilePhone` = agent number registered with MCube; SlashRTC users need a SlashRTC agent for their email.

---

## Part 4 – v1.4.0 (built 2026-10-06)

### part4-lead-entry (deploy fourth) – tested in sandbox 0Afft000000Lc77CAC · 20 tests · LeadPhoneEntryHandler 100%
| Type | Components | Change |
|---|---|---|
| Custom fields | `Lead.Phone_Entry__c`, `Lead.Secondary_Phone_Entry__c` | New – always empty after save |
| Apex | `LeadPhoneEntryHandler` + `LeadPhoneEntryHandlerTest` | New |
| Apex trigger | `LeadTrigger` | **Existing** – one call added at the top |
| Aura | `NewLeadCmp`, `NewRefLeadCmp` | **Existing** – entry inputs for users who cannot see `Phone__c` |

Originals: `backup/v1.4.0-pre-change`. Rollback: `manifest/v1.4.0/destructiveChanges.xml` (after redeploying the originals).

```bash
sf project deploy validate --metadata-dir release/prod/part4-lead-entry --target-org <prod> \
  --test-level RunSpecifiedTests --tests LeadPhoneEntryHandlerTest --tests LeadTriggerTest --tests LeadTriggerHandlerTest
sf project deploy quick --job-id <validation id> --target-org <prod>
```

Notes for production:
- Field-level security on the two entry fields: **edit** for every rep profile that creates Leads – granted at go-live (Part 11). Until then nobody sees them (the forms show them only to users who cannot see `Phone__c`).
- `part2-pilot` now also contains the v1.4.0 POC profile (entry fields) and POC page (Secondary Phone entry field).

---

## Part 5a – v1.5.0 calling screens (built 2026-10-06)

### part5a-calling (deploy fifth)
| Type | Components | Change |
|---|---|---|
| Apex | `PhoneDisplayService` + `PhoneDisplayServiceTest`, `PhoneMaskingCallScreensTest` | New |
| Field | `Lead.Phone_Masked__c` (formula) | New |
| Apex | `MaskedDialService` | Updated (`logAccess`) – also inside part1-foundations |
| Apex | `MakeCallController`, `OfflineCallAppAPI` | **Existing** – masked for masked users, resolved on the server |
| Aura | `CallPanel`, `CallPanel_Outbound` | **Existing** – masked line for masked users |

Originals: `backup/v1.5.0-part5a-pre-change`.

```bash
sf project deploy validate --metadata-dir release/prod/part5a-calling --target-org <prod> \
  --test-level RunSpecifiedTests --tests PhoneDisplayServiceTest --tests PhoneMaskingCallScreensTest \
  --tests MakeCallControllerTest --tests OfflineCallAppAPITest --tests MaskedDialServiceTest
sf project deploy quick --job-id <validation id> --target-org <prod>
```
Go-live: read access to `Lead.Phone_Masked__c` for all rep profiles (Part 11).

---

## Part 5b – v1.5.0 call history and logs (built 2026-10-06)

### part5b-history (deploy after part5a-calling) – tested in sandbox 0Afft000000LfszCAC · 61 tests
| Type | Components | Change |
|---|---|---|
| Apex | `PhoneDisplayService` | Updated (`forDisplay`, `historyValueForDisplay`) – also in part5a-calling |
| Apex | `mCubeController` | **Existing** – `callRecords` masked for masked users; 5 `log__c` Request / Response lines masked for everyone |
| Apex | `LeadHistoryandActivityController` | **Existing** – `GetData` masks phone history values and call numbers for masked users |
| Apex test | `PhoneMaskingHistoryTest` | New |
| Field | `Call_Detail__c.Call_To_Masked__c` (formula) | New |

Originals: `backup/v1.5.0-part5b-pre-change`.

```bash
sf project deploy validate --metadata-dir release/prod/part5b-history --target-org <prod> \
  --test-level RunSpecifiedTests --tests PhoneMaskingHistoryTest --tests PhoneDisplayServiceTest \
  --tests mCubeController_Test --tests mCubeControllerTestExtended --tests LeadHistoryandActivityControllerTest
sf project deploy quick --job-id <validation id> --target-org <prod>
```

---

## Part 5c – v1.5.0 Lead Merge + Update Contact Details (built 2026-10-07)

### part5c-lead-tools (deploy after part5b-history) - tested in sandbox 0Afft000000LkRFCA0, 23 tests
| Type | Components | Change |
|---|---|---|
| Apex | `PhoneDisplayService` | Updated (`maskRecords`, `prepareContactInput`) |
| Apex | `LeadMergeController` | **Existing** – merge lists masked for masked users |
| Apex | `updateContactDetails` | **Existing** – masked for masked users; masked values never saved; primary locked for masked users |
| Apex test | `PhoneMaskingLeadToolsTest` | New |

Originals: `backup/v1.5.0-part5c-pre-change`.

```bash
sf project deploy validate --metadata-dir release/prod/part5c-lead-tools --target-org <prod> \
  --test-level RunSpecifiedTests --tests PhoneMaskingLeadToolsTest --tests PhoneDisplayServiceTest \
  --tests LeadMergeControllerTest   (not updateContactDetailsTest: it fails before 5c - see D3)
sf project deploy quick --job-id <validation id> --target-org <prod>
```

---

## Part 5d – v1.5.0 Bulk push + Yotel push (built 2026-10-07)

### part5d-push (deploy after part5c-lead-tools) - tested in sandbox 0Afft000000Lm1dCAC, 10 tests
| Type | Components | Change |
|---|---|---|
| Apex | `LeadBulkPushController` | **Existing** – selection list mobile masked for masked users (1 line) |
| Apex | `LeadYotelBulkPushController` | **Existing** – selection list masked for masked users (1 line); debug line masked |
| Apex test | `PhoneMaskingPushTest` | New |

Originals: `backup/v1.5.0-part5d-pre-change`.

```bash
sf project deploy validate --metadata-dir release/prod/part5d-push --target-org <prod> \
  --test-level RunSpecifiedTests --tests PhoneMaskingPushTest --tests LeadBulkPushControllerTest --tests LeadYotelBulkPushControllerTest
sf project deploy quick --job-id <validation id> --target-org <prod>
```

---

## Part 5e – v1.5.0 WhatsApp chat (deployed to sandbox 2026-10-07)

### part5e-whatsapp (deploy after part5d-push) - tested in sandbox 0Afft000000Lmb7CAC, 37 tests
| Type | Components | Change |
|---|---|---|
| Apex | `LeadMsgConversationController` | **Existing** – conversation numbers (message, rawJson, senderName) masked for masked users; +1 call, +1 helper |
| Apex test | `PhoneMaskingWhatsAppTest` | New |

Originals: `backup/v1.5.0-part5e-pre-change`. Note the go-live decision D4 (Messaging object access).

```bash
sf project deploy validate --metadata-dir release/prod/part5e-whatsapp --target-org <prod> \
  --test-level RunSpecifiedTests --tests PhoneMaskingWhatsAppTest --tests LeadMsgConversationControllerTest
sf project deploy quick --job-id <validation id> --target-org <prod>
```
