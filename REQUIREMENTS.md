# Mobile Number Masking – Requirements & Working Rules

Everything the project owner has asked for, in one place. Each item is checked before a part is marked complete in [ROADMAP.md](ROADMAP.md).

## A. How we work (process rules)

| # | Rule |
|---|---|
| A1 | Discuss and finalize the approach before implementing anything. |
| A2 | Sandbox is **read-only** unless a specific change is approved. Production is never targeted without approval. |
| A3 | **Existing components** are changed only after approval – say which component, why, and when. |
| A4 | Build **locally first**. Deploy to the sandbox **only when told**, one component or agreed group at a time. |
| A5 | For every change, explain **what it does**, **what changes for users**, and **what stays the same**. |
| A6 | After every change, give the **components list** and the **access sheet**: profiles / permission sets for Apex class access, field and object access, custom permissions, user assignments. |
| A7 | Work is split into **parts / versions** and tracked in ROADMAP.md (done / not done). |
| A8 | Never show real customer phone numbers in queries, logs or output. |

## B. Code quality

| # | Rule |
|---|---|
| B1 | **Production-ready** from the first version – no throwaway POC code. |
| B2 | Salesforce **best practices**: trigger → handler → service, `with sharing`, no hard-coded IDs or credentials, Named Credentials, clean error handling. |
| B3 | **Governor-limit safe**: no SOQL or DML inside loops, collections and maps, only needed fields. |
| B4 | **Bulkified**: handles 200+ records per transaction. |
| B5 | Test classes **above 85% coverage** per class, **never `SeeAllData=true`**; own test data, mocked callouts, positive / negative / bulk / `runAs` tests with real assertions. Coverage reported per class. |

## C. Version control & rollback

| # | Rule |
|---|---|
| C1 | **ORIGINAL BASELINE v1.0.0** = current state of all impacted components, profiles, permission sets and config. Immutable unless told to update it. |
| C2 | Every change is a **Semantic Version** (v1.1.0, v1.1.1 …) with: Commit Version, Type (feat / fix / permission-update / refactor), Modified Assets, Changelog. |
| C3 | **"Revoke to original"** – restore everything to v1.0.0 and give a log of what was reverted. |
| C4 | **"Create checkpoint [name]"** – save the current state as a restore point. |
| C5 | **"Revert to [version]"** – roll back to any earlier version. |
| C6 | Storage: **local git** in this folder, tags per version, CHANGELOG.md. Sandbox reverts = redeploy + remove new components, only after approval. |

## D. Functional requirements

| # | Requirement |
|---|---|
| D1 | Keep today's behaviour: **click the number → the dialer calls** (Open CTI). Approach: **Option B** – masked click-to-dial, real number resolved on the server. Fallback Option A if the POC fails. |
| D2 | Dialers in scope: **SlashRTC, MCube, 360CTI**. Dialer = the user's **assigned call center**. |
| D3 | Mask format **`98XXXXXX21`**; international numbers masked the same way. |
| D4 | **Nobody** sees full numbers except **System Admins and integration users**. |
| D5 | **Reveal**: Team Leads, Heads, Admins only – pick 1 of **7 reasons**, number shown **30 seconds**, every reveal **logged**. |
| D6 | Dial permission: **same record access as today**, no change. |
| D7 | Calling: from the **record page**. List views / related lists / reports lose the phone columns (accepted). |
| D8 | **Mobile app**: calls through the user's dialer via vendor server APIs (requested from vendors). |
| D9 | Lead entry: **keep the current custom form**; numbers entered then hidden. **Primary locked** after creation, reps can add / change **secondary only**. |
| D10 | **Find by number**: same view as today with masked numbers (if global search stops working). |
| D11 | **Call logs** masked for users (Call_Detail__c, Task). |
| D12 | **WhatsApp (Whatsync / 360)** and SMS included in phase 1 – number resolved on the server. |
| D13 | **Inbound calls** must be masked too (screen pop keeps working; vendors mask caller ID). |
| D14 | Sending numbers **to vendors is fine**; masking is for **GSquare users other than admins**. |
| D15 | **Free-text auto-mask on save**: Lead text fields, call logs, Opportunity & feedback, Chatter / Notes. |
| D16 | **Stop leaks** through reports, exports, Data Loader and API (field security + closing code paths + removing export / API permissions). |
| D17 | **G-Talk** fixed with server-side lookup. |
| D18 | Access model: **profiles hide, permission set grants**. |
| D19 | **Audit** of reveal / dial / search kept **1 year**. |
| D20 | Rollout: sandbox → UAT → **pilot (1 SlashRTC + 1 360CTI + 1 MCube user, 1–2 days)** → everyone. |

## E. Documents delivered / to deliver

| # | Item | Status |
|---|---|---|
| E1 | Vendor Scope of Work | ✅ |
| E2 | Internal design doc | ✅ (update at the end) |
| E3 | CLAUDE.md project notes | ✅ (needs status refresh) |
| E4 | ROADMAP.md progress tracker | ✅ |
| E5 | CHANGELOG.md + access sheet per version | Ongoing |
| E6 | Test checklist, deployment runbook, rollback plan, user guide | Before UAT / go-live |

## F. Still open

| # | Question |
|---|---|
| F1 | Decision 1 – hide Contact & Opportunity numbers in phase 1? |
| F2 | 360CTI users (186): stay unmasked until the vendor delivers, or wait? |
| F3 | POC test users: new or existing? Which Sales profile to copy? |
| F4 | GitHub remote on this folder: keep it or remove it? |
