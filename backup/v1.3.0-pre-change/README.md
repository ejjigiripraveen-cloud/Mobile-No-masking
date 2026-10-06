# Backup – existing components before Part 3 (v1.3.0)

Original code of every existing component Part 3 may touch, retrieved **read-only** from the sandbox
before any change. Use it to restore the original if needed.

| | |
|---|---|
| Retrieved | 2026-10-06 |
| Org | gsquaregroup--prodreplic (sandbox, 00Dft000000AiZFEA0) |
| Format | Metadata API format (deployable as-is with `sf project deploy start --metadata-dir backup/v1.3.0-pre-change`) |
| Checksums | `SHA256SUMS` |
| Compared with baseline v1.0.0 | Identical, except `slashPhoneApp` (not in the baseline; first backed up here) |

| Component | Type | Part 3 plan |
|---|---|---|
| `mcubeSoftphoneCTIAddOn` | Visualforce page (MCube Open CTI adapter) | Change: masked click branch |
| `McubeSoftphoneAddOnController` | Apex class | Change: one new method added; existing methods untouched |
| `McubeSoftphoneAddOnControllerTest` | Apex test | No change (new tests go in a new class) |
| `slashPhone` | Aura component (SlashRTC softphone logic) | Change: masked click branch in `slashPhoneHelper.js` |
| `slashPhoneApp` | Aura app (loads `slashPhone` in the adapter page) | No change |
| `index` | Visualforce page (SlashRTC Open CTI adapter) | No change expected |
| `leadOp`, `leadOpTest` | Apex | No change (returns record Ids only, never numbers) |
| `SlashRTCAdapter` | Call center | Sandbox only: adapter URL points to production |
| `MCubeSoftphoneCTIAddOn`, `Adapter360CTI` | Call centers | No change |

**Restore one component:** `sf project deploy start --metadata-dir backup/v1.3.0-pre-change --target-org <org>`
(edit `package.xml` first to keep only the components you want to restore).
