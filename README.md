# flutter_whitelabel_example

This project is a demonstration of how to make a [whitelabel](https://en.wikipedia.org/wiki/White-label_product) application, using a flutter app as the base.

## What this does?

**Android Whitelabel (apk)**

1. From the `./app` dir, the app is built: `app-release.apk` (`flutter build apk`)
2. From the root dir, execute `./run-labeller.rb`
   1. Copy the built apk from `./app/..../app-release.apk` to `./builds/base-app.apk`
   2. Decompile the `./builds/base-app.apk` to `./builds/base-app/` (unzips the apk)
   3. For each `$LABEL` configuration (in `./labels`) it does:
      1. In `./builds` Copy decompiled `base-app/` to `$LABEL/`
      2. Read configuration file in `config.json`
      3. In `./builds` Update the manifest (`$LABEL/AndroidManifest.xml`) with values from configuration file
      4. Generate mipmap (icons) from `ic_launcher.png`
      5. Recompile to whitelabel apk `$LABEL.apk`
      6. Signs `$LABEL.apk` using `my-release-key.keystore`
      7. Done
