#!/bin/bash
set -eu
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
check_dir="$(mktemp -d /tmp/airtype-nearby-check.XXXXXX)"
trap 'rm -rf "$check_dir"' EXIT
cd "$repo_root"
cp IntegrationTests/NearbyMacIntegration.swift "$check_dir/main.swift"
xcrun swiftc NativeShared/NearbyProtocol.swift Shared/LocalNetworkFailure.swift \
  NativeShared/NearbyController.swift NativeShared/NearbyReceiver.swift \
  Shared/NativeKeyboardInput.swift "$check_dir/main.swift" -o "$check_dir/check"
"$check_dir/check" "$@"
