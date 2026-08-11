#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "$BASH_SOURCE")" && pwd)"
template_dir="$script_dir/../templates/xcode_templates"
destination="$HOME/Library/Developer/Xcode/Templates"

if [[ ! -d "$template_dir" ]]; then
    printf 'Template source directory does not exist: %s\n' "$template_dir" >&2
    exit 1
fi

mkdir -p "$destination"
cp -R "$template_dir/." "$destination/"

printf 'Installed Xcode templates in %s\n' "$destination"
