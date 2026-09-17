#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
resolver="$script_dir/resolve_pubspec_version.sh"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

pubspec="$temp_dir/pubspec.yaml"
expected="$temp_dir/expected.yaml"

version_only_conflict() {
  cat >"$pubspec" <<'EOF'
name: fl_clash
description: A multi-platform proxy client.
publish_to: 'none'
<<<<<<< HEAD
version: 1.0.0+2026091702
=======
version: 0.8.99+2026091801
>>>>>>> upstream/main

environment:
  sdk: ^3.10.0
EOF
}

version_only_conflict
bash "$resolver" "$pubspec" >/dev/null
cat >"$expected" <<'EOF'
name: fl_clash
description: A multi-platform proxy client.
publish_to: 'none'
version: 1.0.0+2026091702

environment:
  sdk: ^3.10.0
EOF
diff -u "$expected" "$pubspec"

cat >"$pubspec" <<'EOF'
name: fl_clash
<<<<<<< HEAD
version: 1.0.0+2026091702
dependency_overrides:
  dio: ^5.9.0
=======
version: 0.8.99+2026091801
>>>>>>> upstream/main
EOF
cp "$pubspec" "$temp_dir/before.yaml"
if bash "$resolver" "$pubspec" 2>/dev/null; then
  echo 'expected a conflict touching more than the version line to be refused' >&2
  exit 1
fi
diff -u "$temp_dir/before.yaml" "$pubspec"

cat >"$pubspec" <<'EOF'
name: fl_clash
<<<<<<< HEAD
version: 1.0.0+2026091702
||||||| merged common ancestors
version: 0.8.98+2026091401
=======
version: 0.8.99+2026091801
>>>>>>> upstream/main
EOF
bash "$resolver" "$pubspec" >/dev/null
cat >"$expected" <<'EOF'
name: fl_clash
version: 1.0.0+2026091702
EOF
diff -u "$expected" "$pubspec"

cat >"$pubspec" <<'EOF'
name: fl_clash
<<<<<<< HEAD
version: 1.0.0+2026091702
=======
version: 0.8.99+2026091801
>>>>>>> upstream/main
dependencies:
<<<<<<< HEAD
  dio: ^5.9.0
=======
  dio: ^5.8.0
>>>>>>> upstream/main
EOF
cp "$pubspec" "$temp_dir/before.yaml"
if bash "$resolver" "$pubspec" 2>/dev/null; then
  echo 'expected a second non-version conflict block to be refused' >&2
  exit 1
fi
diff -u "$temp_dir/before.yaml" "$pubspec"

cat >"$pubspec" <<'EOF'
name: fl_clash
version: 1.0.0+2026091702
EOF
cp "$pubspec" "$temp_dir/before.yaml"
if bash "$resolver" "$pubspec" 2>/dev/null; then
  echo 'expected a file without conflict markers to be refused' >&2
  exit 1
fi
diff -u "$temp_dir/before.yaml" "$pubspec"

if bash "$resolver" "$temp_dir/missing.yaml" 2>/dev/null; then
  echo 'expected a missing file to be refused' >&2
  exit 1
fi

echo 'resolve_pubspec_version_test: ok'
