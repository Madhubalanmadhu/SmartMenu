# SmartMenu

Flutter frontend for SmartMenu.

## Local Firebase config

Firebase Web values are passed at build time instead of being hardcoded in `web/index.html`.

1. Copy `.env.example` to `.env`.
2. Fill in the Firebase Web app values from Firebase Console.
3. Run the web app with:

```powershell
.\run_web.ps1
```

For a production web build:

```powershell
.\build_web.ps1
```

`.env` is ignored by git. For GitHub Pages or CI, store the same values as repository secrets and pass them as `--dart-define` values during `flutter build web`.
