# Goat & Fish Farming Business - Offline Android App

Offline-first financial ledger, partner investor management, department tracking, and PDF reports for Goat & Fish Farming Business.

## 🚀 How to Build Release APK in 3 Minutes (Free, Zero Tools Needed)

You can build the signed/installable `app-release.apk` directly in the cloud using GitHub Actions without installing Flutter or Android Studio:

1. Create a repository on [GitHub](https://github.com/new).
2. Push this folder to GitHub:
   ```bash
   git init
   git add .
   git commit -m "Goat & Fish Farm Production Release"
   git branch -M main
   git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_REPO>.git
   git push -u origin main
   ```
3. Open the **Actions** tab in your GitHub repository.
4. The workflow **Build Android APK** will start automatically.
5. In ~3 minutes, click on the workflow run, scroll down to **Artifacts**, and download `Goat_and_Fish_Farm_Release_APK`.
6. Unzip and install `app-release.apk` on any Android phone!

## 💻 Local Build with Flutter SDK
```bash
flutter pub get
flutter build apk --release --no-tree-shake-icons
```
Your APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`
