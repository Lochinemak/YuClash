#!/usr/bin/env bash

set -euo pipefail

file="${1:-pubspec.yaml}"

if [[ ! -f "$file" ]]; then
  echo "resolve_pubspec_version: no such file: $file" >&2
  exit 1
fi

resolved="$(mktemp)"
trap 'rm -f "$resolved"' EXIT

state=plain
blocks=0
ours=''
ours_count=0
theirs=''
theirs_count=0

is_version_line() {
  [[ "$1" =~ ^version:\ [0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?$ ]]
}

while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$state" == plain && "$line" == '<<<<<<<'* ]]; then
    state=ours
    ours=''
    ours_count=0
    theirs=''
    theirs_count=0
  elif [[ "$state" == ours && "$line" == '|||||||'* ]]; then
    state=base
  elif [[ ("$state" == ours || "$state" == base) && "$line" == '======='* ]]; then
    state=theirs
  elif [[ "$state" == theirs && "$line" == '>>>>>>>'* ]]; then
    if ((ours_count != 1 || theirs_count != 1)) ||
      ! is_version_line "$ours" || ! is_version_line "$theirs"; then
      echo "resolve_pubspec_version: conflict in $file is not confined to the version line" >&2
      exit 1
    fi
    printf '%s\n' "$ours" >>"$resolved"
    blocks=$((blocks + 1))
    state=plain
  elif [[ "$state" == ours ]]; then
    ours="$line"
    ours_count=$((ours_count + 1))
  elif [[ "$state" == theirs ]]; then
    theirs="$line"
    theirs_count=$((theirs_count + 1))
  elif [[ "$state" == base ]]; then
    :
  else
    printf '%s\n' "$line" >>"$resolved"
  fi
done <"$file"

if [[ "$state" != plain ]]; then
  echo "resolve_pubspec_version: unterminated conflict marker in $file" >&2
  exit 1
fi

if ((blocks == 0)); then
  echo "resolve_pubspec_version: no conflict markers in $file" >&2
  exit 1
fi

cat "$resolved" >"$file"
echo "resolve_pubspec_version: kept our version line in $file"
