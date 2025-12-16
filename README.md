# tax

Payment Link Verifier (PLV)

This project is a client-side Flutter web app to triage payment and invoice links.

Quick local QA & deploy

- Run app locally in Edge/Chrome:

```powershell
flutter run -d edge
```

- Build web and preview:

```powershell
flutter build web --release --base-href /tax-verifier/
# then serve build/web with a static server
```

- Publish to `gh-pages` (manual helper):

```powershell
.\tools\publish_ghpages.ps1
```

Keyboard shortcuts

- Ctrl+V: Paste & Verify
- Ctrl+B: Open Batch dialog

Continuous integration

A GitHub Actions workflow is included at `.github/workflows/ci_deploy.yml` which will run on push to `main` and can also be triggered manually. It analyzes, tests, builds, and publishes `build/web` to the `gh-pages` branch.
