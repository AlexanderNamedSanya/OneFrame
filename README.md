# GroupFrame+

ESO addon extending the existing group frames. Installable files are in
[`GroupFramePlus/`](GroupFramePlus/); see its [README](GroupFramePlus/README.md).

Verified source baseline: ESO 12.0.8 / API 101050, upstream commit
`f76cf16c4e5be7b234d15dc7f676febffa64c5bb` (2026-08-10).
The addon deliberately disables frame changes on unverified API versions.

## Development

- [Architecture](docs/ARCHITECTURE.md)
- [Design system](docs/DESIGN_SYSTEM.md)
- [Project context and verification](docs/PROJECT_CONTEXT.md)
- [API evidence](docs/API_VERIFICATION.md)
- [Hodor source investigation](docs/HODOR_INTEGRATION.md)
- [In-game acceptance checklist](docs/TESTING.md)

Run `python tests/run.py` with `lupa` installed (uses its Lua 5.1 runtime).
Optional native-identifier audit expects the `live` source checkout at `.reference/esoui`.
This folder and test dependencies are excluded from Git and distribution.

Package with PowerShell:

```powershell
New-Item -ItemType Directory -Force dist
Compress-Archive -Path GroupFramePlus -DestinationPath dist/GroupFramePlus-1.4.3.zip -Force
```

Automated checks do not replace testing in the ESO client. No in-game execution
has been performed in this development environment.
