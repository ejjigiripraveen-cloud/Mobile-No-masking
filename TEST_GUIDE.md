# Mobile Number Masking – Sandbox Test Guide (all parts)

Detailed, step-by-step tests for every part **as deployed**. Run them in this order at the end of the build
(the project owner asked to test everything together). Each part has a result sheet.

| | |
|---|---|
| Sandbox | https://gsquaregroup--prodreplic.sandbox.my.salesforce.com |
| App | **Gsquare Housing** |
| "Login as X" | Setup → **Users** → X → **Login** (needs Setup → Login Access Policies → "Administrators Can Log in as Any User") |
| Test users | **POC MCube Rep** (MCube), **POC SlashRTC Rep** (SlashRTC) – profile *POC Masked Rep* (phone fields hidden) |
| Normal rep | Any active **Presales outbound** user (sees full numbers – must see **no change**) |
| Numbers | **Only your own or dummy numbers** – never a customer's |
| Golden rule | For every screen: **normal rep = exactly as before; POC user = masked (98XXXXXX21) and still works** |
| Browser check | **F12 → Network** → open the `aura?…` / `apexremote` responses → Ctrl+F part of the real number → **must not be found** |

---

## Shared preparation (do once)

| # | Step | Where |
|---|---|---|
| P1 | SlashRTC call center **CTI Adapter URL** = `/apex/index` (sandbox only) | Setup → Call Centers → SlashRTC Call Center Adapter → Edit |
| P2 | **POC MCube Rep → Mobile** = tester's phone registered as an agent in MCube (used by the masked panel click, Part 3) | Setup → Users → POC MCube Rep → Edit |
| P3 | **POC MCube Rep → Mcube Phone** = same agent phone (used by MakeCall, Part 5a) | same |
| P4 | SlashRTC agent exists for the POC users' email (SlashRTC logs in by email); SlashRTC allows the sandbox address | SlashRTC admin / vendor |
| P5 | G-Talk: the POC username is registered in G-Talk (otherwise G-Talk calls can be checked only via the audit row) | G-Talk admin |
| P6 | Assign **Phone Access Audit Viewer** to yourself (to see the audit tab) | Setup → Permission Sets |
| P7 | **Test Lead A** – Pre Sales, owner POC MCube Rep, Phone 9876543221, Secondary 9123456780, Email testa@example.com | Leads → New (as admin) |
| P8 | **Test Lead B** – Pre Sales, owner POC MCube Rep, Phone 9555555555, Email testb@example.com | same |
| P9 | **Test Lead S** – Pre Sales, owner **POC SlashRTC Rep**, Phone = a second tester phone | same |
| P10 | **Normal Lead N** – owned by the normal rep, test numbers | same |
| P11 | Copy the Lead Ids (start with `00Q`) from the address bar – used in queries below | — |

⚠️ MCube call logs in the sandbox may be sent to the **production** callback URL (Mcube__mdt CallBackUrl was copied by the refresh) – check with the MCube admin before many test calls.

---

## Part 1 – Foundations (v1.1.0) · deployed 0Afft000000LO8zCAG

| # | Step | Expected |
|---|---|---|
| 1.1 | Setup → Apex Classes | `PhoneMaskUtil`, `MaskedDialService`, `MaskedDialServiceCTI`, `PhoneMaskingConfig`, test classes |
| 1.2 | Setup → Custom Metadata Types → *Phone Masking Setting* → Manage Records → Default | 2 / 2 / X / 91 / 30 / 365 / both checkboxes ticked |
| 1.3 | Same → *Masked Phone Field* → Manage Records | `Lead_Phone`, `Lead_Secondary_Phone` – active, dial + reveal ticked |
| 1.4 | App Launcher → **Phone Access Audits** → All | Tab opens |
| 1.5 | Developer Console → Execute Anonymous → `scripts/apex/v1.1.0-1-mask-format.apex` | `RESULT: 11 passed, 0 failed` |
| 1.6 | Same → `scripts/apex/v1.1.0-2-settings.apex` | Every value matches its "expected" |
| 1.7 | `scripts/apex/v1.1.0-3-dial-service.apex` (put Test Lead A Id on line 7) | 3a Success, real number matches · 3c Denied · 3d success · 3e Denied |
| 1.8 | `scripts/apex/v1.1.0-4-audit-check.apex` | Rows with masked numbers only |

---

## Part 2 – Masked phone panel (v1.2.0) · deployed 0Afft000000LRq1CAG / 0Afft000000LRzhCAG

| # | As | Step | Expected |
|---|---|---|---|
| 2.1 | Admin | Open any Lead | Page unchanged, **no** masked panel |
| 2.2 | Normal rep | Open Lead N | Page unchanged, no panel |
| 2.3 | POC MCube Rep | Open **Test Lead A** (Pre Sales, desktop) | **Phone Numbers** panel top-left: Primary `98XXXXXX21`, Secondary `91XXXXXX80`; real phone fields not visible |
| 2.4 | POC MCube Rep | F12 → Network → reload | Real number not found |
| 2.5 | POC MCube Rep | Lead list views | No phone numbers |
| 2.6 | POC MCube Rep | Global search for the full real number | Note: found / not found (decides Part 8) |

---

## Part 3 – Dialers MCube + SlashRTC (v1.3.0) · deployed 0Afft000000LY6jCAG / 0Afft000000LYBZCA4

Needs P1–P4. If the 📞 icon is crossed out: open the **Phone** utility (bottom bar), wait until the softphone is ready, refresh the Lead.

| # | As | Step | Expected |
|---|---|---|---|
| 3.1 | POC MCube Rep | Phone utility → MCube ready → Test Lead A → click **Primary 98XXXXXX21** | Agent phone rings, then customer phone, connected |
| 3.2 | POC MCube Rep | F12 → Network during the click | Only record Id / field / masked value sent; response success; no real number |
| 3.3 | POC MCube Rep | Click **Secondary** | Same |
| 3.4 | POC SlashRTC Rep | Phone utility → SlashRTC logged in → Test Lead S → click Primary | Call connects (number briefly inside the SlashRTC softphone – vendor limitation) |
| 3.5 | Admin | Phone Access Audits | Dial · Success rows, masked number; MCube row message "MCube: Call initiated." |
| 3.6 | POC user | Call the MCube / SlashRTC virtual number from the "customer" phone | Screen pop opens the right Lead |
| 3.7 | Normal MCube / SlashRTC / 360CTI reps | Click the normal Phone field | Calls exactly as before |
| 3.8 | Admin | Setup → Custom Metadata → Phone Masking Setting → untick "Real Number Lookup Enabled"; POC clicks a number | Call refused, audit Denied – **tick it again** |

---

## Part 4 – Lead creation (v1.4.0) · deployed 0Afft000000Lc77CAC / 0Afft000000LcALCA0

| # | As | Step | Expected |
|---|---|---|---|
| 4.1 | Normal rep | Leads → **New**; any Lead → **New Referral Lead** | Forms exactly as before; save works |
| 4.2 | POC MCube Rep | Leads → **New** | Same form; Phone / Secondary Phone are the entry fields; save works (no "Phone required" error) |
| 4.3 | POC MCube Rep | New Referral Lead | Same |
| 4.4 | POC MCube Rep | Open the new Lead | Panel shows masked numbers |
| 4.5 | Admin | Query: `SELECT Phone__c, Secondary_Phone__c, Phone_Entry__c, Secondary_Phone_Entry__c FROM Lead WHERE LastName LIKE 'POC Test%'` | Real fields filled, **entry fields empty** |
| 4.6 | POC MCube Rep | Test Lead A → "Secondary Phone" entry field (under Name) → new number → Save | Panel shows new masked secondary; entry field empty again |
| 4.7 | Admin | Execute Anonymous: `update new Lead(Id='00Q…', Phone_Entry__c='9000000000');` via `Database.update(l,false)` | Fails with "The primary number cannot be changed once it is set…" |
| 4.8 | POC MCube Rep | New Lead with an existing number | Same duplicate behaviour as a normal rep |
| 4.9 | Admin | Execute Anonymous: insert a Lead with `Phone__c` (integration style) | Saved normally, entry field empty |
| 4.10 | POC MCube Rep | Mobile app → Leads → New (optional) | Entry fields, save works |

Note: round robin may reassign a new Lead – check it as admin if the POC user cannot open it.

---

## Part 5a – Calling screens (v1.5.0) · deployed 0Afft000000Lf3NCAS / 0Afft000000Lf4zCAC

Call panels (`CallPanel`, `CallPanel_Outbound`) are **not** in 5a – deferred item D1.

| # | As | Step | Expected |
|---|---|---|---|
| 5a.1 | Normal rep | Lead N → **MakeCall** → number list; G-Talk utility; call | Full numbers, calls as before; no audit rows |
| 5a.2 | POC MCube Rep | Test Lead A → **MakeCall** → Select Number | `+91 98XXXXXX21` style; no full number in Network |
| 5a.3 | POC MCube Rep | Pick a masked number → Call (needs P3) | Agent then customer phone ring; connected |
| 5a.4 | POC MCube Rep | **G-Talk** utility | Primary / Secondary `98XXXXXX21`; Call → no error |
| 5a.5 | Admin | Phone Access Audits | Dial · Success rows: channel **MCube (MakeCall)** (message "MakeCall: …") and **G-Talk**; masked only |
| 5a.6 | Admin | Execute Anonymous: `System.debug(MakeCallController.callCustomer('00Q…', '+91 11XXXXXX00'));` | "The selected number could not be identified…"; audit Dial · Not Found; no call |

---

## Part 5b – Call history and logs (v1.5.0) · deployed 0Afft000000LfszCAC

Preparation: as admin change Test Lead A's Secondary Phone and Phone once (creates field history), and create one call record:
```apex
Id leadId = '00Q...';
insert new Call_Detail__c(Lead__c = leadId, Parent_ID__c = leadId, Parent_URL__c = '/' + leadId + '/view',
    Status__c = 'Call Complete', Call_From__c = '9898989898', Call_To__c = '9876543221', Start_Time__c = System.now().addMinutes(-10));
```

| # | As | Step | Expected |
|---|---|---|---|
| 5b.1 | Normal rep | Lead N → **History & Activity** (right side) → Field Updates / Calls | Full old → new numbers and call numbers, as before |
| 5b.2 | POC MCube Rep | Test Lead A → History & Activity → **Field Updates** | Phone / Secondary rows masked (`98XXXXXX21 → 97XXXXXX07`); other fields normal |
| 5b.3 | POC MCube Rep | Filter **Calls** / **All** | Call numbers masked; nothing in Network |
| 5b.4 | Admin | Query `SELECT Call_From__c, Call_To__c, Call_To_Masked__c FROM Call_Detail__c WHERE Parent_ID__c='00Q…'` | Real numbers stored; `Call_To_Masked__c` = `98XXXXXX21` |
| 5b.5 | Admin | One real MCube test call, then `SELECT Request__c, Response__c FROM log__c ORDER BY CreatedDate DESC LIMIT 3` | Newest log shows the customer number masked; call worked |
| 5b.6 | – | Call history list `mCubeLightningPage` | **Not on any page** – not testable unless added to the POC page (needs approval) |

---

## Part 5c – Lead Merge + Update Contact Details (v1.5.0) · deployed 0Afft000000LkRFCA0

Buttons at the top right of the Lead page (or under ▼): **Update Contact Details**, **Merge Lead**.

| # | As | Step | Expected |
|---|---|---|---|
| 5c.1 | Normal rep | Lead N → Update Contact Details → change Secondary → Save | Full numbers shown; "Success" |
| 5c.2 | Normal rep | Merge Lead (close without merging) | List with full numbers |
| 5c.3 | POC MCube Rep | Test Lead A → Update Contact Details | Phone `98XXXXXX21`, Secondary `91XXXXXX80`; nothing in Network |
| 5c.4 | POC MCube Rep | Change **only the Email** → Save | "Success" – numbers must **not** be overwritten (check 5c.8) |
| 5c.5 | POC MCube Rep | Secondary → 9333333333 → Save | "Success"; reopen shows `93XXXXXX33` |
| 5c.6 | POC MCube Rep | Phone → 9000000000 → Save | "The primary number cannot be changed once it is set…"; nothing saved |
| 5c.7 | POC MCube Rep | Merge Lead → list, search "Test Lead" → (optional) merge Test Lead B | Masked numbers; merge works |
| 5c.8 | Admin | Query `SELECT Phone__c, Secondary_Phone__c, Email FROM Lead WHERE Id IN ('00Q…A','00Q…B')` | Real numbers (Phone still 9876543221, Secondary 9333333333), **no "X" in any phone field** |

## Part 5d – Bulk push + Yotel push (v1.5.0) · deployed 0Afft000000Lm1dCAC

Leads tab → list view → tick Leads → list buttons **Add Leads to Call List** (Bulk push → MCube) and **Create Lead List For Yotel** (Yotel). ⚠️ Pushing is real – MCube / Yotel may call the numbers: use a private list view with only test Leads (e.g. filter Last Name contains "Test Lead") and check with the MCube / Yotel admins before pressing Push. Yotel eligibility needs `Gi_BOT_Camp_ID__c` (ask the Yotel admin for a test campaign Id). **On hold:** the owner could not test 5d yet because of an access issue (2026-10-07).

| # | As | Step | Expected |
|---|---|---|---|
| 5d.1 | Normal rep | Lead list → select 2 test Leads → **Yotel push** | Table shows full numbers, as before |
| 5d.2 | POC MCube Rep | Lead list → select Test Lead A + B → **Yotel push** | Table shows `98XXXXXX21`; eligibility column unchanged; nothing in Network |
| 5d.3 | POC MCube Rep | Click Push (only with test numbers / a test campaign) | Push succeeds – Yotel receives the real numbers from the server |
| 5d.4 | POC MCube Rep | Lead list → select test Leads → **Bulk push** | Screen as before; F12 → Network: no full customer number in the response |
| 5d.5 | POC MCube Rep | Pick the agent and push (test Leads only) | Push to MCube succeeds |
| 5d.6 | Normal rep | Bulk push | Exactly as before |

---

## Part 5e – WhatsApp chat (v1.5.0) · deployed 0Afft000000Lmb7CAC · testing on hold (owner, 2026-10-07)

⚠️ The sandbox has **0 WhatsApp customers** (`MessagingEndUser`), so the chat cannot be tested on screen there. The Apex tests cover the masking; check on screen during the production pilot.

| # | As | Step | Expected |
|---|---|---|---|
| 5e.1 | Sandbox | Setup → Apex Test Execution → `PhoneMaskingWhatsAppTest`, `LeadMsgConversationControllerTest` | All pass |
| 5e.1b | Sandbox – normal rep and POC MCube Rep | Open a non–Pre Sales Lead (New_Lead_Page has the chat) | Chat component loads without error ("no conversation" – no WhatsApp data) |
| 5e.1c | Sandbox – optional, only if a test WhatsApp channel is connected | Send "call me on 9123456780" from your phone to the sandbox number (Lead Phone = your WhatsApp number); open the Lead as normal rep, then as POC user | Normal rep: unchanged · POC user: "call me on 91XXXXXX80"; your WhatsApp number not in Network |
| 5e.2 | Normal rep (prod pilot) | Lead with a WhatsApp chat → chat component | Messages exactly as before |
| 5e.3 | Pilot (masked) user | Same Lead → chat | Same messages; any phone number typed in a message shows as `98XXXXXX21` |
| 5e.4 | Pilot (masked) user | F12 → Network → chat response | The customer's WhatsApp number is not in the data (`rawJson` masked) |
| 5e.5 | Pilot (masked) user | Transfer chat, open attachments | Work as before |

Related go-live decision **D4**: reps have View All on `MessagingEndUser` / `MessagingSession` (standard WhatsApp records show the number).

---

## Part 6 – Reveal + audit cleanup (v1.6.0) · built, not yet deployed

Preparation: test user **POC TL** (profile POC Masked Rep + permission set **Phone Reveal**), created at deploy time; it owns or can see **Test Lead A**.

| # | As | Step | Expected |
|---|---|---|---|
| 6.1 | POC MCube Rep (no Phone Reveal) | Test Lead A → Phone Numbers panel | **No** Reveal (eye) icon |
| 6.2 | POC TL | Test Lead A → panel | Eye icon next to Primary (and Secondary if filled) |
| 6.3 | POC TL | Click the eye → dialog | 7 reasons in the dropdown; Reveal disabled until a reason is chosen |
| 6.4 | POC TL | Choose **Other**, leave Comment empty | Reveal stays disabled |
| 6.5 | POC TL | Choose **Management review** → Reveal | Real number shown under the masked one with "Hides after 30 seconds"; after 30 s it disappears |
| 6.6 | POC TL | Other + comment "test" → Reveal | Number shown; comment stored (6.7) |
| 6.7 | Admin | Phone Access Audits → All | Action **Reveal**, Outcome Success, user POC TL, Reason and Comment filled, Masked Number only |
| 6.8 | Normal rep / admin | Lead page | No change (panel only on the POC page) |
| 6.9 | Admin | Execute Anonymous: `System.debug(PhoneAuditPurgeBatch.scheduleNightly());` (once) | Setup → Scheduled Jobs shows "Phone Access Audit purge (nightly)" at 02:00 |
| 6.10 | Admin | Execute Anonymous: `Database.executeBatch(new PhoneAuditPurgeBatch());` | Apex Jobs: completes; only audit rows older than 365 days are deleted (none yet in the sandbox) |

---

## Parts still to be built – sections added as each part is built

| Part | Status |
|---|---|
| 5d – Dialer push (Bulk, Yotel) | Section above |
| 5e – WhatsApp | Section above |
| 6 – Reveal + audit cleanup | Section above |
| 7 – Free-text masking | ⬜ |
| 8 / 9 | Only if needed |
| D1 – Call panels | Deferred |
| 11 – Go-live switch (sandbox) | ⬜ – full test as Rep / TL / Admin / Integration user |

---

## Overall result sheet

| Part | Pass / Fail | Tester | Date | Notes |
|---|---|---|---|---|
| 1 Foundations | | | | |
| 2 Masked panel | | | | |
| 3 Dialers | | | | |
| 4 Lead creation | | | | |
| 5a Calling | | | | |
| 5b History + logs | | | | |
| 5c Merge + Update Contact | | | | |
| 5d Bulk + Yotel push | | | | |
| 5e WhatsApp chat | | | | |
| 6 Reveal + purge | | | | |
