# Mobile Number Masking – Project Roadmap & Progress

**Status legend:** ✅ Done · 🟡 In progress · ⬜ Not started · ⏸️ Waiting (on decision / vendor) · ➖ Not needed (skipped)

Every build part follows the same 5 checkpoints:
**Build locally → Approval (only if existing components change) → Deploy to sandbox (only when told) → Test in sandbox → Tag version + access sheet**

---

## Overview

| Part | Version | Name | Status |
|---|---|---|---|
| 0 | v1.0.0 | Preparation & baseline | 🟡 |
| 1 | v1.1.0 | Foundations (masking engine, dial service, audit) | 🟡 |
| 2 | v1.2.0 | Masked phone panel on Lead page (POC users only) | 🟡 |
| 3 | v1.3.0 | Dialer adapters – MCube & SlashRTC (POC) | 🟡 |
| 4 | v1.4.0 | Lead creation with hidden numbers | 🟡 |
| 5 | v1.5.0 | Mask existing screens that leak numbers (5a + 5b deployed, 5c built, 5d–5e ⬜) | 🟡 |
| 6 | v1.6.0 | Reveal for TL / Head / Admin + audit cleanup | ⬜ |
| 7 | v1.7.0 | Free-text auto-masking | ⬜ |
| 8 | v1.8.0 | Find by number (only if POC shows search breaks) | ⏸️ |
| 9 | v1.9.0 | Opportunity, Contact & customer documents (only if Decision 1 = Yes) | ⏸️ |
| 10 | — | Vendor deliveries (runs in parallel) | ⏸️ |
| 11 | v2.0.0 | Go-live access in sandbox (masking switched on) | ⬜ |
| 12 | — | UAT in sandbox | ⬜ |
| 13 | — | Production deployment + pilot (3 users, 1–2 days) | ⬜ |
| 14 | — | Full rollout + handover | ⬜ |

---

## Deferred items (raise after all build parts are done, before go-live)

| # | Item | Why deferred | Proposed fix | Status |
|---|---|---|---|---|
| D1 | Call panels `CallPanel`, `CallPanel_Outbound` show an empty Phone line for masked users | Aura `lightning:recordViewForm` has no `onload` event – two 5a deploys rolled back; owner asked to skip for now (2026-10-06) | New LWC `maskedPhoneField` (Phone__c for users who can see it, Phone_Masked__c otherwise); replace the one Phone line in each panel | ⏸️ Remind owner after Parts 5b–7 |
| D2 | Sandbox testing of Parts 5a and 5b (and results of the Part 2–4 tests) | Owner will test later (2026-10-07) | Test steps given in chat; 5b call history list `mCubeLightningPage` is on no page, so not testable on screen unless added to the POC page (needs approval) | ⏸️ Remind owner at the end |

---

## Part 0 – Preparation & baseline (v1.0.0) 🟡

| Item | Status |
|---|---|
| Connect project to sandbox | ✅ |
| Approach finalized (Option B – masked click-to-dial) | ✅ |
| Vendor Scope of Work shared | ✅ |
| Internal design doc written | ✅ |
| Sandbox refreshed | ✅ |
| Read-only impact inventory of existing components | ✅ |
| Baseline v1.0.0 retrieved and tagged (local git) | ✅ |
| Requirements & working rules listed (REQUIREMENTS.md) | ✅ |
| Roadmap tracker (this file) | ✅ |
| Decision 1 – hide Contact & Opportunity numbers in phase 1? | ⏸️ |
| Decision – 360CTI users: stay unmasked until vendor delivers, or wait? | ⏸️ |
| Decision – POC test users: new or existing? Which Sales profile to copy? | ⏸️ |
| Decision – GitHub remote on this folder: keep or remove? (MCube token in baseline) | ⏸️ |
| Decision – sandbox login: keep ejjigiripraveen or switch to own login? | ⏸️ |
| Remaining read-only inventory: reports, email templates, existing triggers on Task / Call_Detail__c / FeedItem / feedback objects, managed-package screens | ⬜ |
| Update baseline with anything new from the inventory / Decision 1 (needs explicit OK) | ⬜ |
| Refresh CLAUDE.md status section | ⬜ |

## Part 1 – Foundations (v1.1.0) 🟡

**New:** `PhoneMaskingConfig`, `PhoneMaskUtil`, `MaskedDialService`, `MaskedDialServiceCTI` (Open CTI entry point), `Masked_Phone_Field__mdt` (2 records), `Phone_Masking_Setting__mdt` (1 record), `Phone_Access_Audit__c` + tab, `Phone_Access_Audit_Viewer` permission set, `PhoneTestDataFactory` + 4 test classes.
**Existing changed:** none. **User impact:** none.

| Checkpoint | Status |
|---|---|
| Build locally | ✅ |
| Approval | ➖ (new components only) |
| Deploy to sandbox | ✅ 2026-10-05 (0Afft000000LO8zCAG, 44/44) |
| Test (deploy status, tests >85%, masking results, nothing changed for users) | 🟡 deploy ✅, scripts 1–2 ✅, script 3 + permission set + user check pending |
| Tag v1.1.0 + access sheet | ⬜ |

## Part 2 – Masked phone panel (v1.2.0) 🟡

**New:** `MaskedPhonePanelController` (+ test), `maskedPhonePanel` LWC (+ Jest), page `Sales_Lead_Record_Page_Masked_POC` (copy of `Sales_Lead_Record_Page` + panel), "POC Masked Rep" profile (clone of Presales outbound, 25 phone fields hidden), 2 new test users (MCube + SlashRTC).
**Existing changed:** `Pre_Sales` (Gsquare Housing) app – one new page-assignment row for the POC profile (Pre Sales Leads, desktop). `Sales_Lead_Record_Page` is NOT changed. **User impact:** POC users only.

| Checkpoint | Status |
|---|---|
| Build locally | ✅ |
| Approval – clone page + app assignment row | ✅ (approved 2026-10-05) |
| Deploy to sandbox | ✅ step 1 profile clone ✅ · step 2 code ✅ (0Afft000000LRq1CAG) · step 3a profile ✅ (0Afft000000LRzhCAG) · step 3b page activation in App Builder ✅ (verified: 1 row added, 0 changed) · step 4 test users ✅ (POC MCube Rep 005ft000000YFsfAAG, POC SlashRTC Rep 005ft000000YFuHAAW) |
| Test (masked display, no raw fields, no number in browser, other users unchanged) | ⬜ |
| Tag v1.2.0 + access sheet | ⬜ |

## Part 3 – Dialer adapters, POC (v1.3.0) 🟡

**Existing changed:** `mcubeSoftphoneCTIAddOn` (one branch), `McubeSoftphoneAddOnController` (one new method), `slashPhone` helper (one step), SlashRTC call center URL (sandbox only). `index` and `leadOp` unchanged. **New:** `McubeMaskedClickToCallTest`. **User impact:** POC users only.

| Checkpoint | Status |
|---|---|
| Prerequisites: agent logins for test users, test Lead with tester's number | ⬜ |
| Build locally | ✅ 2026-10-06 (backup of originals: backup/v1.3.0-pre-change) |
| Approval – adapters, SlashRTC URL | ✅ 2026-10-06 (`leadOp` needs no change) |
| Deploy to sandbox | ✅ 2026-10-06 code 0Afft000000LY6jCAG (60 tests) · pilot 0Afft000000LYBZCA4 · CTI Adapter URL: manual by you ⬜ |
| Test – Q1 masked click reaches dialer | ⬜ |
| Test – Q2 real number dialed, call log + audit row created | ⬜ |
| Test – Q3 inbound screen pop still works | ⬜ |
| Test – Q4 global search by number (decides Part 8) | ⬜ |
| Test – normal clicks unchanged for MCube / SlashRTC / 360CTI reps | ⬜ |
| **Gate: Option B confirmed, or switch to Option A fallback** | ⬜ |
| Tag v1.3.0 + access sheet | ⬜ |

## Part 4 – Lead creation (v1.4.0) 🟡

**New:** `Lead.Phone_Entry__c`, `Lead.Secondary_Phone_Entry__c`, `LeadPhoneEntryHandler` (+ test, 11 tests). Updates: POC profile (entry fields), POC page (Secondary Phone entry).
**Existing changed (additions only):** `LeadTrigger` (+6 lines at top), `NewLeadCmp`, `NewRefLeadCmp` (entry inputs for masked users). `New_Lead_Page` / `New_Lead_Page1_sales` moved to Part 11. Backup: `backup/v1.4.0-pre-change`.

| Checkpoint | Status |
|---|---|
| Build locally | ✅ 2026-10-06 |
| Approval | ✅ 2026-10-06 |
| Deploy to sandbox | ✅ 2026-10-06 code 0Afft000000Lc77CAC (20 tests) · pilot 0Afft000000LcALCA0 |
| Test (create lead, primary locked, secondary editable, duplicates blocked, website/portal APIs, 200-record load) | ⬜ |
| Tag v1.4.0 + access sheet | ⬜ |

## Part 5 – Mask leaking screens (v1.5.0) 🟡

**New:** masked formula fields (`Phone_Masked__c`, `Secondary_Phone_Masked__c`, `Call_To_Masked__c`).
**Existing changed:** `MakeCall` + controller, G-Talk (`utilityCallComponent`, `offlineCallQuickActionCmp`, `OfflineCallAppAPI`), `CallPanel`, `CallPanel_Outbound`, `mCubeLightningPage`, `LeadHistoryandActivityController`, `mCubeController` (logs), `LeadMergeCmp` + controller, `UpdateContactDetails` + controller, `leadBulkPush` / `leadYotelPush` + controllers, `leadMsgConversationLWC` + controller.

| Checkpoint | Status |
|---|---|
| Build locally | 🟡 5a ✅ · 5b ✅ · 5c ✅ 2026-10-07 (backup/v1.5.0-part5c-pre-change) · 5d–5e ⬜ |
| Deploy 5a | ✅ 2026-10-06 code 0Afft000000Lf3NCAS (45 tests) · pilot 0Afft000000Lf4zCAC · call panels deferred (D1) |
| Deploy 5b | ✅ 2026-10-06 0Afft000000LfszCAC (61 tests) |
| Approval | 🟡 5a ✅ · 5b ✅ · 5c ✅ 2026-10-07 · 5d–5e ⬜ |
| Deploy to sandbox | ⬜ |
| Test (each screen masked; MakeCall, G-Talk, Yotel/bulk push, WhatsApp, merge still work; `log__c` clean) | ⬜ |
| Tag v1.5.0 + access sheet | ⬜ |

## Part 6 – Reveal + audit cleanup (v1.6.0) ⬜

**New:** `PhoneRevealService`, `Reveal_Reason__c` (7 reasons), `Reveal_Phone_Number` custom permission, `PhoneAuditPurgeBatch` (nightly, 1-year retention).
**Existing changed:** none expected.

| Checkpoint | Status |
|---|---|
| Build locally | ⬜ |
| Deploy to sandbox | ⬜ |
| Test (TL/Head reveal 30 s + audit row; reps no button; purge deletes only >1 year) | ⬜ |
| Tag v1.6.0 + access sheet | ⬜ |

## Part 7 – Free-text auto-masking (v1.7.0) ⬜

**New:** `FreeTextMaskService` + triggers on Task, Call_Detail__c, FeedItem, feedback objects.
**Existing changed:** existing handlers on those objects, if they already have triggers (approval).
⚠️ Masking is permanent – cannot be reverted.

| Checkpoint | Status |
|---|---|
| Build locally | ⬜ |
| Approval | ⬜ |
| Deploy to sandbox | ⬜ |
| Test (typed numbers masked on save; vendor call-log number fields untouched; 200-record save) | ⬜ |
| Tag v1.7.0 + access sheet | ⬜ |

## Part 8 – Find by number (v1.8.0) ⏸️ depends on Part 3, Q4

**New:** `findByNumber` LWC + Apex.

| Checkpoint | Status |
|---|---|
| Needed? (Part 3 Q4 result) | ⏸️ |
| Build → Deploy → Test → Tag | ⬜ |

## Part 9 – Opportunity, Contact & documents (v1.9.0) ⏸️ depends on Decision 1

**Existing changed:** `cancellationRequest`, `opportunitySummaryLWC`, `registrationTeamFileUpload`, `kycAndQuotationTabComponent`, `siteVisitFeedbackForm`, `createBookingCmp`, `showConvertedOppRecord` + controllers, 4 Contact quick actions, 19 customer document VF pages (access for document teams).

| Checkpoint | Status |
|---|---|
| Needed? (Decision 1) | ⏸️ |
| Build → Approval → Deploy → Test → Tag | ⬜ |

## Part 10 – Vendor deliveries (parallel) ⏸️

| Vendor | Item | Status |
|---|---|---|
| 360 Degree Cloud | 360CTI adapter supports masked click-to-dial (186 users) | ⏸️ |
| 360 Degree Cloud | Whatsync server-side number resolution | ⏸️ |
| SlashRTC | Server-side start-call API (mobile) | ⏸️ |
| SlashRTC | Agent screen masks number (inbound + outbound) | ⏸️ |
| MCube | Agent screen / caller ID shows virtual number | ⏸️ |
| All | Inbound caller-ID masking | ⏸️ |
| All | Mobile app calling via server API | ⏸️ |

## Part 11 – Go-live access in sandbox (v2.0.0) ⬜ – masking switched ON

**Existing changed:** ~40 rep profiles (remove phone-field access; Export Reports / API Enabled where safe), assign "Phone Number Full Access" to integration users, `Reveal_Phone_Number` to TL/Head/Admin, panel visible to all on Lead pages.

| Checkpoint | Status |
|---|---|
| Build locally (profile + permission set metadata) | ⬜ |
| Approval | ⬜ |
| Deploy to sandbox | ⬜ |
| Full test as Rep / TL / Admin / Integration user (pages, list views, reports, export, search, mobile, API, all integrations) | ⬜ |
| Tag v2.0.0 + final access sheet | ⬜ |

## Part 12 – UAT ⬜

| Item | Status |
|---|---|
| Test checklist shared with business testers | ⬜ |
| UAT by Sales / Presales / GRE / TL / CRM | ⬜ |
| Fixes (if any) as v2.0.x | ⬜ |
| UAT sign-off | ⬜ |

## Part 13 – Production deployment + pilot ⬜

| Item | Status |
|---|---|
| Deployment runbook + rollback plan approved | ⬜ |
| Deploy to production (approval required) | ⬜ |
| Pilot: 1 SlashRTC + 1 360CTI + 1 MCube user, 1–2 days | ⬜ |
| Pilot sign-off | ⬜ |

## Part 14 – Full rollout + handover ⬜

| Item | Status |
|---|---|
| Masking switched on for all users in production | ⬜ |
| User guide / announcement for reps and TLs | ⬜ |
| Design doc updated with final state | ⬜ |
| Handover to Salesforce team (runbook, access sheet, audit reports) | ⬜ |
| Project closed | ⬜ |
