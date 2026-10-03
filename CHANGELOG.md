# Changelog – Mobile Number Masking

Versioning follows Semantic Versioning. Every version is a git tag in this folder's local-only history (never pushed).

Commands: `Revoke to original` (back to v1.0.0) · `Create checkpoint <name>` · `Revert to <version>`.
Reverting local files is immediate. Reverting the sandbox means redeploying the older metadata and removing newly added components, and happens only after explicit approval.

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
