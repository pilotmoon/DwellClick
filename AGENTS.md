# AGENTS.md

For sandboxed verification builds, use:

```sh
xcodebuild -project dc.xcodeproj -scheme "DwellClick SA" -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/DwellClickDerivedData CODE_SIGNING_ALLOWED=NO build
```

`CODE_SIGNING_ALLOWED=NO` avoids local certificate/keychain failures; this is for build verification only.
