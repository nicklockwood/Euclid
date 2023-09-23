#!/bin/bash

echo "Make sure you've rebased over the current HEAD branch:"
echo "git rebase -i origin/master docs"

set -e
set -x

rm -rf .build
mkdir -p .build/symbol-graphs

$(xcrun --find swift) build --target Euclid \
-Xswiftc -emit-symbol-graph \
-Xswiftc -emit-symbol-graph-dir -Xswiftc .build/symbol-graphs

# Enables deterministic output
# - useful when you're committing the results to host on github pages
export DOCC_JSON_PRETTYPRINT=YES

$(xcrun --find docc) convert Euclid.docc \
--analyze \
--fallback-display-name Euclid \
--fallback-bundle-identifier com.charcoaldesign.Euclid \
--fallback-bundle-version 0.5.16 \
--additional-symbol-graph-dir .build/symbol-graphs \
--experimental-documentation-coverage \
--level brief

$(xcrun --find docc) convert Euclid.docc \
    --output-path ./docs \
    --fallback-display-name Euclid \
    --fallback-bundle-identifier com.charcoaldesign.Euclid \
    --fallback-bundle-version 0.5.16 \
    --additional-symbol-graph-dir .build/symbol-graphs \
    --emit-digest \
    --transform-for-static-hosting \
    --hosting-base-path 'Euclid'

# Generate a list of all the identifiers for DocC curation
#

cat docs/linkable-entities.json | jq '.[].referenceURL' -r | sort > all_identifiers.txt
sort all_identifiers.txt | sed -e 's/doc:\/\/Euclid\/documentation\///g' \
| sed -e 's/^/- ``/g' | sed -e 's/$/``/g' > all_symbols.txt

echo "Page will be available at https://nicklockwood.github.io/Euclid/documentation/euclid/"
