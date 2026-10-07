# Mobile Number Masking – GSquare Salesforce

Salesforce DX project for masking customer mobile numbers from GSquare users (everyone except System Admins and integration users) while keeping click-to-dial working through the existing dialers.

## Status (as of 2026-10-07)

- **Deployed to the sandbox (Sandbox alias, gsquaregroup--prodreplic):** Parts 1, 2, 3, 4, 5a–5e, 6. Masking is visible only to POC test users (profile *POC Masked Rep*); real users are unchanged until the go-live switch (Part 11).
- **Next:** Part 7 (free-text masking – permanent), then Part 11 (go-live switch in the sandbox); Parts 8 / 9 only if needed.
- **Open questions from the owner's last session:** schedule the nightly audit purge (`PhoneAuditPurgeBatch.scheduleNightly()`) – not done yet; test Part 6 now or at the end.
- **Deferred items D1–D4** (call panels, testing of all parts, pre-broken `updateContactDetailsTest`, WhatsApp Messaging object access) – see ROADMAP.md "Deferred items"; raise them at the end.
- **Where things are:** `ROADMAP.md` (progress), `CHANGELOG.md` (every version, deploy IDs, rollback, access sheets), `TEST_GUIDE.md` (step-by-step tests of every part), `REQUIREMENTS.md`, `docs/Mobile_Masking_Component_Register.xlsx` (all components + production deploy list), `release/prod/` (production bundle), `backup/` (originals before each change).
- **Git:** one branch per part (`ejjigiripraveen/v1.x.0-…`), each built on the previous one; latest `ejjigiripraveen/v1.6.0-reveal`; remote `origin` = github.com/ejjigiripraveen-cloud/Mobile-No-masking (public).
- **Test users (sandbox):** POC MCube Rep, POC SlashRTC Rep, POC TL (Phone Reveal).
- **Do not deploy or change anything in any org without explicit approval.** Read-only queries in the sandbox are fine.

## Docs

- Vendor Scope of Work (SlashRTC, Mcube, 360 Degree Cloud): https://claude.ai/code/artifact/8ba4597f-c4a6-4130-b8f9-6083a037ef1e
- Salesforce Internal Design (full component design, data model, risks, delivery plan): https://claude.ai/code/artifact/b8d155a5-852c-44b6-a1e9-001abde4b1fc

The internal design doc is the source of truth. Update it, not just this file, when decisions change.

## Orgs

- Default target org: alias `Sandbox` = gsquaregroup--prodreplic (refreshed, org 00Dft000000AiZFEA0, user ejjigiripraveen@gsquarehousing.com.prodreplic).
- Production is not the default. Never target prod without explicit approval.

## Current dialer setup (as found in sandbox; prod matches per user)

- Calling happens via **Open CTI** call centers (no Service Cloud Voice; Omni-Channel has only Messaging). In prod every calling user has a call center assigned.
- **SlashRTC**: Open CTI adapter is our own code – Visualforce page `/apex/index` + Aura `c:slashPhone`. Inbound screen pop uses Apex `leadOp` (SOSL `FIND :phone IN PHONE FIELDS`). Call logs pushed in via `slashCallLogAPI`.
- **Mcube**: Open CTI call center in prod (unmanaged package). Also `MakeCall` Aura → `MakeCallController.callCustomer` → `mCubeController.makeCall`, and `McubeAutoDailerApi` (status-triggered).
- **360 CTI** (`tdc_360CTI`): managed package – adapter changes must come from the vendor. Whatsync (WhatsApp) is also 360 Degree Cloud.
- **G-Talk / offline call app**: `utilityCallComponent`, `offlineCallQuickActionCmp` → `OfflineCallAppAPI` (AWS trigger-call endpoint).
- **Yotel**: bulk push via `leadYotelPush`.

### Known leaks to fix (methods that send full numbers to the browser)
`readContacts`, `getLeadPhone`, `getOppPhone`, `triggerCall(phoneNumber)`, Yotel `getSelectedLeads.mobileNumber`, `LeadMergeCmp`, `leadOp` responses. `mCubeController` writes full request (with number) to `log__c.Request__c`.

### Security debt (separate fix)
`McubeAutoDailerApi` has a hard-coded API token; Mcube calls use plain `http://` with the API key in the URL. Move to Named Credentials over HTTPS.

## Phone fields in scope

- Lead: `Phone__c`, `Secondary_Phone__c` (primary + secondary shown in the masked component).
- Formula copies (must also be hidden – hiding the source does not hide a formula): `Phone_with_country_code__c`, `Full_phone_number__c`, `Message_Full_Phone__c`, Opportunity `Mobile__c`, `Secondary_Mobile__c`.
- Other copies: `WhatsApp_Number__c`, `Merge_Lead_Phone_No__c`, `Secondary_Phones__c`, `Related_Source__c` phones, Contact co-applicant mobiles, Account `Mobile__c`, Opportunity `PhoneNo__c`, `SFDC_MOBILE_NUMBER__c`.
- Call logs: `Call_Detail__c.Call_To__c`, `Customer_Contact__c`; Task `Call_To__c`, `Caller_number__c`.

## Agreed design (Option B)

- **Masked click-to-dial**: an LWC renders `lightning-click-to-dial` with the masked value plus `recordId` and params `key=<field>` (key=value, comma-separated – not JSON). The user's Open CTI adapter receives `onClickToDial`, calls `MaskedDialService.resolve(recordId, key)` via `runApex`, gets the real number, dials with existing code. The number never reaches the page.
- **Fallback (Option A)**: if the POC shows `lightning-click-to-dial` rejects masked values, the LWC publishes `{recordId, fieldKey}` over a Lightning Message Channel that the adapter subscribes to.
- **Dialer choice**: always the user's assigned call center.
- **Dial permission**: unchanged – same record access as today.
- **Mobile app**: no `tel:` links; calls go through each vendor's server-side start-call API (requested from vendors). Until delivered, mobile shows masked numbers with no call option.
- **Mask format**: `98XXXXXX21` (first 2 + last 2). International numbers masked the same way.
- **Who sees full numbers**: System Admins and integration users (Mcube, Yotel, Zetta, website/portals, vendor call-log users) only. Implemented as: profiles lose access, permission set "Phone Number Full Access" grants it.
- **Reveal**: Team Leads, Heads, Admins only. Pick one of 7 reasons → number shown 30 seconds → audit row.
- **Data entry**: `NewLeadCmp` / `NewRefLeadCmp` (custom Aura forms) write to `Phone_Entry__c` / `Secondary_Phone_Entry__c`; a before-save trigger copies to the hidden fields and clears the entry fields. Primary is locked after creation; reps can add/change secondary only.
- **Find by number**: same search results view as today, numbers masked. Built only if the POC shows global search stops matching hidden fields.
- **Call from**: record page only. List views, related lists and reports lose the phone columns (accepted).
- **Free-text auto-mask on save**: Lead text fields, call-log text, Opportunity & feedback fields, Chatter (Notes only if actually used). Masking is permanent.
- **Existing components** (`MakeCall`, `LeadMergeCmp`, Yotel selection, G-Talk, `leadOp`): return only masked values to the browser. Numbers still go to vendors server-side as today.
- **WhatsApp**: Whatsync (360) in phase 1 – send actions resolve the number server-side.
- **Inbound**: must be masked. Salesforce side: `leadOp` SOSL runs in system mode so screen pop should keep working (verify in POC). Softphone side: vendors mask caller ID.
- **Audit**: one object for reveal, dial and search events; scheduled job deletes records older than 1 year.
- **Logs**: mask numbers in `log__c` and debug statements.
- **Export/API leaks**: FLS is the main control; also remove Export Reports and API Enabled from rep profiles after checking nothing reps use needs them.

## Proof of concept (refreshed sandbox, one SlashRTC user)

1. Does `lightning-click-to-dial` accept the masked value and pass params to the adapter?
2. Does the adapter resolve the real number via Apex and dial?
3. Does inbound screen pop (`leadOp`) still work once `Phone__c` is hidden?
4. Does global search still find leads by number once the field is hidden?

## Rollout

Sandbox refresh → POC → build → UAT → pilot in prod (1 SlashRTC + 1 360 CTI + 1 Mcube user, 1–2 days) → everyone.

## Working conventions

- Discuss and agree on an approach before implementing anything.
- The sandbox is read-only unless a specific change is approved.
- Existing components are changed only after explicit approval (say which component, why, and when).
- Build locally in `force-app` first. Deploy to the sandbox only when told, one component or agreed group at a time.
- For every change, explain what it does: what the component or edit does, what changes for users, and what stays the same.
- After each change, list the components created/changed and the access needed: profiles/permission sets for Apex class access, field and object access, custom permissions, and user assignments.
- Code standards: production-ready from the start (no throwaway POC code), Salesforce best practices, governor-limit safe (no SOQL/DML in loops), bulkified (200+ records), and test classes with **above 85% coverage** per class, **never `SeeAllData=true`** — tests create their own data, mock callouts, include bulk and negative cases with real assertions. Report coverage per class on delivery.
- Never print real customer phone numbers in queries, logs or output – count or mask instead.
