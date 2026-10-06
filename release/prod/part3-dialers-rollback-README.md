# Part 3 rollback (production)
Redeploy the original adapter code from `backup/v1.3.0-pre-change` (`mcubeSoftphoneCTIAddOn`, `McubeSoftphoneAddOnController`,
`slashPhone`) – edit its package.xml to keep only those – then remove `McubeMaskedClickToCallTest`:
`sf project deploy start --manifest release/prod/package-empty.xml --post-destructive-changes manifest/v1.3.0/destructiveChanges.xml --target-org <prod>`
