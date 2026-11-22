#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
sdk_source="${1:-${MSKMEASURE_SDK:-$HOME/Downloads/IsiXPluginKit-SDK-6.0.5}}"
mkdir -p .build/ModuleCache Prebuilt
if [[ -d "$sdk_source/IsiXPluginKit.framework" ]]; then
 sdk_dir="$(cd "$sdk_source" && pwd)"
elif [[ -f "$sdk_source" ]]; then
 sdk_unpack="$(mktemp -d "$PWD/.build/sdk-XXXXXX")"
 ditto -x -k "$sdk_source" "$sdk_unpack"
 sdk_metadata="$(find "$sdk_unpack" -name SDK.json -print -quit)"
 sdk_dir="$(dirname "$sdk_metadata")"
else
 echo "IsiXPluginKit API-v1-SDK fehlt. Verzeichnis oder ZIP als Argument angeben." >&2
 exit 1
fi
python3 - "$sdk_dir" <<'PY'
import json,sys,hashlib
from pathlib import Path
p=Path(sys.argv[1]);d=json.loads((p/'SDK.json').read_text())
assert d['apiVersion']==1 and d['kitVersion']=='1.0.0','SDK v1 / Kit 1.0.0 erforderlich'
b=p/'IsiXPluginKit.framework/Versions/A/IsiXPluginKit'
assert hashlib.sha256(b.read_bytes()).hexdigest()==d['binarySHA256'],'SDK checksum mismatch'
Path('.build/SDK.json').write_text(json.dumps(d,indent=2)+'\n')
PY
bundle="$PWD/.build/MSKmeasure.isixplugin"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
cp Info.plist "$bundle/Contents/"
cp Resources/*.json "$bundle/Contents/Resources/"
cp .build/SDK.json "$bundle/Contents/Resources/SDK.json"
compiler_options=()
if [[ "${MSK_NESTED_SANDBOX_UNAVAILABLE:-0}" == "1" ]]; then
 compiler_options+=(-Xfrontend -disable-sandbox)
fi
xcrun swiftc "${compiler_options[@]}" -module-name MSKmeasure -parse-as-library \
 -target arm64-apple-macos15.0 -F "$sdk_dir" \
 -module-cache-path "$PWD/.build/ModuleCache" \
 -framework IsiXPluginKit -framework AppKit -framework SwiftUI \
 -Xlinker -bundle -o "$bundle/Contents/MacOS/MSKmeasure" Sources/*.swift
codesign --force --sign - "$bundle"
codesign --verify --strict "$bundle"
ditto "$bundle" Prebuilt/MSKmeasure.isixplugin
echo "Plugin: $PWD/Prebuilt/MSKmeasure.isixplugin"
