#!/bin/bash

mkdir -p .build/symbol-graphs
swift build --target Euclid -Xswiftc -emit-symbol-graph -Xswiftc -emit-symbol-graph-dir -Xswiftc .build/symbol-graphs
xcrun docc preview Sources/Euclid.docc --fallback-display-name Euclid --fallback-bundle-identifier com.github.nicklockwood.Euclid --fallback-bundle-version 0.1.0 --additional-symbol-graph-dir .build/symbol-graphs
