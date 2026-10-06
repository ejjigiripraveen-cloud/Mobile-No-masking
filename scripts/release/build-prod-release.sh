#!/usr/bin/env bash
# Rebuilds release/prod from the current source (run from the project root).
# Add one "build" line per new part as the project grows; run it again at the end on the final main branch.
set -e
rm -rf release/prod/part1-foundations release/prod/part2-panel release/prod/part2-pilot
build() { sf project convert source --manifest "$2" --output-dir "release/prod/$1" --json > /dev/null && echo "built $1"; }
build part1-foundations manifest/v1.1.0/package.xml
build part2-panel       manifest/v1.2.0/package-prod.xml
build part2-pilot       manifest/v1.2.0/package-pilot.xml
cd release/prod
find . -type f ! -name SHA256SUMS ! -name README.md -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
echo "checksums: $(wc -l < SHA256SUMS) files"
