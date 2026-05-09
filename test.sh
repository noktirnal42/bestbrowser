#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# On the current Swift 6.3/macOS 26 toolchain, plain `swift test` can emit
# unrelated CoreData NSXPCConnection noise during otherwise passing XCTest runs.
# Running through an explicit all-tests filter keeps the output clean while
# exercising the same test cases.
swift test --filter '.*'
