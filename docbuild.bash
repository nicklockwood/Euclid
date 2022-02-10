#!/bin/bash

echo "Make sure you've rebased over the current HEAD branch:"
echo "git rebase -i origin/master docs"

set -e
set -x

rm -rf .build
mkdir -p .build/symbol-graphs

swift build --target Euclid \
-Xswiftc -emit-symbol-graph \
-Xswiftc -emit-symbol-graph-dir -Xswiftc .build/symbol-graphs

xcrun docc convert Sources/Euclid.docc \
--analyze \
--fallback-display-name Euclid \
--fallback-bundle-identifier com.charcoaldesign.Euclid \
--fallback-bundle-version 0.5.16 \
--additional-symbol-graph-dir .build/symbol-graphs \
--experimental-documentation-coverage \
--level brief

# Generate a list of all the identifiers for DocC curation
#

cat docs/linkable-entities.json| jq '.[].referenceURL' -r > all_identifiers.txt
sort all_identifiers.txt | sed -e 's/doc:\/\/Euclid\/documentation\///g' \
| sed -e 's/^/- ``/g' | sed -e 's/$/``/g' > all_symbols.txt

# Swift package plugin for hosted content:
#
swift package \
    --allow-writing-to-directory ./docs \
    --target Euclid \
    generate-documentation \
    --output-path ./docs \
    --fallback-display-name Euclid \
    --fallback-bundle-identifier com.charcoaldesign.Euclid \
    --fallback-bundle-version 0.5.16 \
    --emit-digest \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path 'Euclid'

echo "Page will be available at https://nicklockwood.github.io/Euclid/documentation/euclid/"
