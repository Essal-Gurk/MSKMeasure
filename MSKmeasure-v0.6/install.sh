#!/bin/bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  printf 'Verwendung: %s [Plugin-Zielordner]\n' "$0" >&2
  exit 2
fi

package_dir="$(cd -- "$(dirname -- "$0")" && pwd -P)"
plugin_name="MSKmeasure.isixplugin"
source="$package_dir/Prebuilt/$plugin_name"
target_dir="${1:-$HOME/Library/Application Support/IsiX/Plugins}"

if [[ ! -d "$source" ]]; then
  printf 'Plugin-Bundle fehlt: %s\n' "$source" >&2
  exit 1
fi

/usr/bin/codesign --verify --strict "$source"
mkdir -p -- "$target_dir"
target_dir="$(cd -- "$target_dir" && pwd -P)"
target="$target_dir/$plugin_name"
if [[ "$source" == "$target" || -L "$target" || ( -e "$target" && ! -d "$target" ) ]]; then
  printf 'Ungültiges Installationsziel: %s\n' "$target" >&2
  exit 1
fi

staging="$target_dir/.MSKmeasure.install"
if ! mkdir -- "$staging"; then
  printf 'Temporärer Installationsordner konnte nicht angelegt werden: %s\n' "$staging" >&2
  exit 1
fi

cleanup() {
  if [[ -d "$staging/previous" && ! -e "$target" && ! -L "$target" ]]; then
    if ! mv -- "$staging/previous" "$target"; then
      printf 'Vorheriges Plugin liegt unter %s/previous\n' "$staging" >&2
      return 1
    fi
  fi
  rm -rf -- "$staging"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

/usr/bin/ditto "$source" "$staging/new"
/usr/bin/codesign --verify --strict "$staging/new"
if [[ -d "$target" ]]; then
  mv -- "$target" "$staging/previous"
fi
mv -- "$staging/new" "$target"

# Keep the old identity so IsiX and stored language preferences recognize the update.
legacy="$target_dir/IsiXMSKMessungen.isixplugin"
if [[ -d "$legacy" && ! -L "$legacy" ]]; then
 legacy_id="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$legacy/Contents/Info.plist" 2>/dev/null || true)"
 if [[ "$legacy_id" == "org.isixmskmessungen.plugin" ]]; then
  backup_root="$target_dir/../MSKmeasure-Backups"
  mkdir -p -- "$backup_root"
  backup="$(mktemp -d "$backup_root/update-XXXXXX")"
  mv -- "$legacy" "$backup/IsiXMSKMessungen.isixplugin"
 fi
fi

printf 'Installiert: %s\n' "$target"
printf 'IsiX starten, eine Bildserie öffnen und im Plugin-Menü „MSKmeasure (v0.6)“ wählen.\n'
