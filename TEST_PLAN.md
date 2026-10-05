# Mobile Number Masking – Components & Sandbox Test Plan

For each part: what is **new**, what **existing** component changes (approval needed), and the **exact steps to see and test** it in the sandbox after it is deployed.

Sandbox: https://gsquaregroup--prodreplic.sandbox.my.salesforce.com
Before testing: Setup → **Login Access Policies** → "Administrators Can Log in as Any User" must be enabled.
"Login as X" below means: Setup → **Users** → find X → **Login**. Log out to return to your admin session.

**Standard checks after every deploy (all parts):**
1. Setup → **Deployment Status** → latest deploy = **Succeeded**.
2. Setup → **Apex Test Execution** → run the new/changed test classes → all pass; Developer Console shows coverage **> 85%** per class.
3. Quick check as a **normal rep**: open a Lead, click `Phone__c` → works as before (until Part 11).
4. Setup → **Apex Jobs** / `log__c` → no new errors.

---

## Part 0 – Preparation & baseline (v1.0.0)

- **New:** none in the org. **Existing changed:** none.
- **Test:** nothing to test in the sandbox (read-only retrieve only). Locally: `git tag` shows `v1.0.0`.

---

## Part 1 – Foundations (v1.1.0)

| New | Existing changed |
|---|---|
| `PhoneMaskUtil` (Apex), `MaskedDialService` (Apex + Open CTI entry point), `Masked_Phone_Field__mdt` (2 records), `Phone_Masking_Setting__mdt` (1 record), `Phone_Access_Audit__c` (object), `PhoneTestDataFactory` + test classes | None |

**Steps to see it**
1. Setup → **Apex Classes** → `PhoneMaskUtil`, `MaskedDialService`, test classes listed.
2. Setup → **Custom Metadata Types** → *Masked Phone Field* → **Manage Records** → `Lead.Phone__c`, `Lead.Secondary_Phone__c`.
3. Setup → **Custom Metadata Types** → *Phone Masking Setting* → **Manage Records** → default record (2 + 2 digits, `X`, active).
4. Setup → **Object Manager** → *Phone Access Audit* → fields present.

**Steps to test**
1. Developer Console → Debug → **Open Execute Anonymous Window** → run:
   ```apex
   System.debug(PhoneMaskUtil.mask('9876543221'));    // 98XXXXXX21
   System.debug(PhoneMaskUtil.mask('919876543221'));  // 98XXXXXX21
   System.debug(PhoneMaskUtil.mask('+971501234567')); // 97XXXXXXXX67 (first 2 + last 2)
   System.debug(PhoneMaskUtil.mask(''));              // blank, no error
   ```
   Tick **Open Log** → filter **Debug Only** → results match.
2. Open any Lead as admin and as a rep → **nothing changed**.

---

## Part 2 – Masked phone panel (v1.2.0)

| New | Existing changed |
|---|---|
| `maskedPhonePanel` (LWC), "POC Masked Rep" profile (copy of Sales without phone-field access), 2 test users (if "new users" chosen) | `Lead_Record_Page` – panel added, visible to POC profile only |

**Steps to see it**
1. Setup → **Lightning App Builder** → `Lead_Record_Page` → panel present with a visibility filter on the POC profile.
2. Setup → **Profiles** → *POC Masked Rep* → Lead field-level security → `Phone__c`, `Secondary_Phone__c` not visible.

**Steps to test**
1. **As admin** → open a Lead → page exactly as before, no panel.
2. **Login as the POC test user** → open the test Lead:
   - [ ] Panel shows **Primary 98XXXXXX21 📞** and **Secondary 99XXXXXX07 📞**.
   - [ ] Raw phone fields not visible anywhere on the page.
   - [ ] **F12 → Network** → reload → Ctrl+F the real number's last 6 digits → **not found**.
   - [ ] Lead list views show no phone numbers.
   - [ ] Global search the number → note: found / not found (decides Part 8).
3. **Login as a normal Sales rep** → open a Lead → no panel, no change.

---

## Part 3 – Dialer adapters, POC (v1.3.0)

| New | Existing changed |
|---|---|
| New method in `McubeSoftphoneAddOnController` (existing methods untouched); Message channel only if Option A fallback | `mcubeSoftphoneCTIAddOn` page, `McubeSoftphoneAddOnController`, `index` page + `slashPhone` (SlashRTC), `leadOp`, SlashRTC call center adapter URL (sandbox only) |

**Prerequisites:** MCube + SlashRTC agent logins for the test users; test Lead holding the tester's own mobile.

**Steps to see it**
1. Setup → **Call Centers** → *SlashRTC Call Center Adapter* → Adapter URL = sandbox `index` page.
2. Setup → **Users** → test users → Call Center = MCube / SlashRTC.

**Steps to test**
1. **Login as the MCube test user** → bottom utility bar **Phone** → softphone logged in → open test Lead → click **Primary 📞**:
   - [ ] Agent phone rings, then customer phone rings, call connects.
   - [ ] Softphone shows masked / virtual number, not the real one.
   - [ ] F12 → Network → real number not present.
   - [ ] After the call: Lead → Related → **Call Details** → new record.
   - [ ] As admin: App Launcher → **Phone Access Audits** → new row (Dial, user, Lead, number masked).
   - [ ] Repeat with **Secondary 📞**.
2. **Login as the SlashRTC test user** → same steps.
3. **Inbound:** call the MCube / SlashRTC virtual number from the tester's mobile → softphone rings → screen pop opens the **correct Lead**. Note whether the softphone shows the real caller number (vendor item).
4. **Nothing else changed:** login as a normal MCube rep, a normal SlashRTC rep and a 360CTI rep → click `Phone__c` → call works exactly as today.
5. **Fails safely:** as the POC user, try a Lead you can't access → cannot open / dial. Remove the secondary number (as admin) → panel shows "No secondary number".
6. **Gate:** all pass → Option B confirmed; click fails to reach the dialer → switch to Option A.

---

## Part 4 – Lead creation (v1.4.0)

| New | Existing changed |
|---|---|
| `Phone_Entry__c`, `Secondary_Phone_Entry__c` (Lead fields), `LeadPhoneEntryHandler` (Apex) | `NewLeadCmp`, `NewRefLeadCmp`, `LeadTrigger` / `LeadTriggerHandler`, `New_Lead_Page`, `New_Lead_Page1_sales` |

**Steps to test** (as the POC test user unless stated)
1. Leads tab → **New** → fill the form with a test number → **Save**:
   - [ ] Lead created; panel shows the number masked.
   - [ ] As admin: `Phone__c` holds the real number; `Phone_Entry__c` is **empty**.
2. **New** again with the **same number** → duplicate check **blocks** it as today.
3. Referral lead form (`NewRefLeadCmp`) → same as step 1.
4. Edit the Lead → **Primary cannot be changed**; **Secondary can** be added / changed → saved and masked.
5. As admin: create a Lead through the **website / portal API** test (or Postman) → created normally.
6. As admin: Data Loader **insert 200 Leads** → all created, no limit errors.
7. As a **normal rep** → New Lead → works exactly as before.

---

## Part 5 – Mask leaking screens (v1.5.0)

| New | Existing changed |
|---|---|
| `Phone_Masked__c`, `Secondary_Phone_Masked__c`, `Call_To_Masked__c` (formula fields) | `MakeCall` + `MakeCallController`, `utilityCallComponent`, `offlineCallQuickActionCmp`, `OfflineCallAppAPI`, `CallPanel`, `CallPanel_Outbound`, `mCubeLightningPage`, `LeadHistoryandActivityController`, `mCubeController`, `LeadMergeCmp` + `LeadMergeController`, `UpdateContactDetails` + `updateContactDetails`, `leadBulkPush` / `leadYotelPush` + controllers, `leadMsgConversationLWC` + `LeadMsgConversationController` |

**Steps to test** (as the POC test user; check F12 → Network on each screen)

| Screen | Where | Check |
|---|---|---|
| MakeCall | Lead → MakeCall action | Numbers masked; **call still placed** |
| G-Talk | Utility bar → G-Talk / Offline call action | Masked; **call reaches the G-Talk app** |
| Call panels | Lead page call panels | Masked number, not blank |
| Call history | Lead → activity / MCube page | `Call_To__c` masked |
| Lead Merge | Lead → Merge | Masked; **merge completes** |
| Update Contact Details | Lead → action | Primary read-only masked; secondary editable |
| Bulk / Yotel push | Push screens | Masked in selection; **push succeeds** (vendor receives real numbers) |
| WhatsApp chat | Lead → WhatsApp tab | Masked; **message sends** |
| Logs | As admin: App Launcher → `log__c` | New rows have **no full numbers** |

---

## Part 6 – Reveal + audit cleanup (v1.6.0)

| New | Existing changed |
|---|---|
| `PhoneRevealService`, `Reveal_Reason__c` (7 values), `Reveal_Phone_Number` custom permission, `PhoneAuditPurgeBatch` (scheduled) | None expected |

**Steps to test**
1. Give the custom permission to a test **TL** user (via a permission set).
2. **Login as the TL** → open Lead → **Reveal**:
   - [ ] Reason is mandatory (7 options).
   - [ ] Number shows, then hides after **30 seconds**.
   - [ ] As admin: Phone Access Audits → row with action *Reveal* + reason.
3. **Login as the POC rep** → no Reveal button.
4. As admin: Setup → **Scheduled Jobs** → `PhoneAuditPurgeBatch` scheduled nightly. Test: create an audit row with an old date via the test class / Data Loader → run the batch → only rows older than 1 year deleted.

---

## Part 7 – Free-text auto-masking (v1.7.0)

| New | Existing changed |
|---|---|
| `FreeTextMaskService` + triggers on Task, Call_Detail__c, FeedItem, feedback objects | Existing triggers / handlers on those objects (if any – confirmed in Part 0 inventory) |

⚠️ Masking is permanent – use test data only.

**Steps to test**
1. As the POC rep: Lead → Description = `Call him on 9876543221` → Save → shows `Call him on 98XXXXXX21`.
2. Log a call (Task) with the number in Comments → masked.
3. Chatter post on a Lead with a number → masked.
4. Opportunity / feedback text field → masked.
5. As admin: a **vendor-created Call_Detail__c** (or Task from the API) → `Call_To__c` / `Caller_number__c` **unchanged**.
6. Data Loader update 200 Tasks with numbers in Comments → all masked, no errors.

---

## Part 8 – Find by number (v1.8.0) – only if Part 3 showed search breaks

| New | Existing changed |
|---|---|
| `findByNumber` LWC + Apex | Possibly `searchComponent` (approval) |

**Steps to test:** as the POC rep → open Find by Number → enter an existing number → shows "Exists – Lead L-xxx, owner X", number masked → audit row *Search*. Enter an unknown number → "Not found".

---

## Part 9 – Opportunity, Contact & documents (v1.9.0) – only if Decision 1 = Yes

| New | Existing changed |
|---|---|
| Masked fields / services as needed | `cancellationRequest`, `opportunitySummaryLWC`, `registrationTeamFileUpload`, `kycAndQuotationTabComponent`, `siteVisitFeedbackForm`, `createBookingCmp`, `showConvertedOppRecord` + controllers, 4 Contact quick actions, 19 document VF pages (access) |

**Steps to test:** as the POC rep → open an Opportunity → `cancellationRequest` **loads**, summary / KYC / registration screens show masked numbers; Contact → Co-Applicant actions update numbers via masked entry; as a CRM/document user → generate Booking Form, Allotment Letter, Demand Letter, Quotation → **real number printed** on the customer document.

---

## Part 10 – Vendor deliveries

- **New / existing in our org:** depends on vendor.
- **Test:** 360CTI rep clicks masked number → call works; softphones show masked numbers on inbound and outbound; mobile app call through vendor API.

---

## Part 11 – Go-live access in sandbox (v2.0.0)

| New | Existing changed |
|---|---|
| "Phone Number Full Access" permission set | ~40 rep profiles (phone-field access removed; Export Reports / API Enabled where safe), integration users (permission set assigned), TL / Head / Admin users (`Reveal_Phone_Number`), Lead pages (panel visible to all) |

**Steps to test – one pass per user type**

| As | Check |
|---|---|
| **Rep** (each main profile: Sales, Presales, GRE, Referral, CRM) | Lead / Opportunity pages masked; list views and reports show no numbers; **Export** not available; global search; Salesforce **mobile app** masked; click-to-dial works through own dialer |
| **TL / Head** | Same as rep + Reveal works |
| **Admin** | Full numbers everywhere |
| **Integration users** | Website / portal lead creation, MCube / SlashRTC call-log push, Yotel, G-Talk, WhatsApp – all still work |
| **Data Loader / Workbench as a rep** | Login blocked (API disabled) or phone columns empty |

---

## Part 12 – UAT

Business testers repeat the Part 11 table with real scenarios; issues fixed as v2.0.x; sign-off.

## Part 13 – Production pilot

Deploy to prod (approval) → masking on for 1 SlashRTC + 1 360CTI + 1 MCube user → repeat Part 3 + Part 11 checks with real calls for 1–2 days → sign-off.

## Part 14 – Full rollout

Masking on for everyone → spot-check Part 11 table in prod → handover.
