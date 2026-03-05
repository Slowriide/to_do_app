# Android Release Signing

This project is configured so **release** builds must use a real release keystore.

Release signing values are resolved in this order:
1. `android/key.properties`
2. CI environment variables

Debug builds continue using the default debug signing config.

## 1) Generate a Keystore

From the project root (or any secure location), run:

```bash
keytool -genkeypair -v \
  -keystore android/app/upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Choose and store the passwords securely.

## 2) Configure `android/key.properties`

Create `android/key.properties` (do not commit this file):

```properties
storeFile=app/upload-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```

Notes:
- `storeFile` can be relative to `android/app` (example above) or an absolute path.
- Keep this file out of source control.

## 3) CI Alternative (Environment Variables)

Instead of `key.properties`, set:

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

If release signing is missing, release tasks fail fast with a clear error.

## 4) Build Signed Releases

```bash
flutter build appbundle --release
flutter build apk --release --split-per-abi
```

Outputs:
- AAB: `build/app/outputs/bundle/release/`
- APKs: `build/app/outputs/flutter-apk/`
