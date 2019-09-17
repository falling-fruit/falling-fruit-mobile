Falling Fruit Mobile
====================

This is a Cordova mobile application for Falling Fruit. It is a single-page angular app written in pug, less, and coffee. The backend is accessed over a RESTful JSON API served up at [https://fallingfruit.org/api/](https://fallingfruit.org/api/).

## Directory layout

  * `/bin` - grunt and npm configuration
  * `/docs` - extra documentation
  * `/hooks` - Cordova hooks
  * `/icons` - Platform icon and splashscreen graphics. Same as `/resources` ?
  * (`/platforms`) - Platform configuration and code compiled by Cordova and grunt (not version-controlled)
  * (`/plugins`) - Cordova plugins (not version-controlled)
  * `/resources` - same as `/icons` (?)
  * `/src` - Source code for the site
    * `/pug` - compiles to html
    * `/less` - compiles to css
    * `/coffee` - compiles to javascript
  * `/www` - Code compiled by grunt from `/src` (not version controlled), along with static files (e.g. images, js libraries).

### Plugins & Platforms

Cordova installs plugins (`/plugins/*`) and builds platforms (`/platforms/*`) based on the content of the root `/package.json` file, which is why these directories are not version-controlled. Run `cordova prepare` to generate these directories.

## Code layout

  * Factories (reusable code)
    * `misc.coffee` - miscellaneous functions
    * `i18n.coffee` - units and language localization
    * `auth.coffee` - authentication
  * Controllers (do stuff all the time!!!)
    * `detail.coffee` - add, display, edit, and review a location
    * `search.coffee` - main map and list view
    * `menu.coffee` - settings and filters sidebar
  * Directives (compartmentalized code)
    * `directives.coffee` - map, spinner, etc

## Build instructions

### Install node and dependencies

  * Install `nvm` (Node Version Manager): [instructions](https://github.com/creationix/nvm)
  * Install `npm` (Node Package Manager) (10.15.3):

  ```
  nvm install 10.15.3
  nvm use 10.15.3
  ```

  * Install `cordova` (9.0.0):

  ```
  npm install -g cordova@9.0.0
  ```

  * Install `grunt-cli`:

  ```
  npm install -g grunt-cli
  ```

  * Install Node packages:

  ```
  cd bin
  npm install
  cd ..
  ```

  * Install and configure `phraseapp`:

  ```
  brew tap phrase/brewed
  brew install phraseapp
  cp .phraseapp.yml.sample .phraseapp.yml
  ```

Edit `.phraseapp.yml`, and replace `YOUR_ACCESS_TOKEN` with your
[phraseapp.com](phraseapp.com) access token. You can
generate an access token [here](https://phraseapp.com/settings/oauth_access_tokens).

### Add new language translations

Adding a new translation is easy!

*Step 1*: Add the new translation key on [phraseapp.com](phraseapp.com).

Sign in to [phraseapp.com](http://phraseapp.com), browse to the Falling Fruit (mobile)
project, select the default locale (English/en), and add a new translation key.

When naming your key, follow this convention:

`<template name>.<key name>`

For example, if you're adding a key called `map_btn` to the `search.pug` template,
you'll want to name the full key `search.map_btn`.
If the same word or phrase appears often, you can file it as `glossary.<key name>` to avoid
making many keys with identical or derived (pluralized, capitalized, etc) values.

*Step 2*: Update your translation files.

Provided you've installed `phraseapp` (instructions above), run:

```
phraseapp pull
```

This will update the translation files in `www/locales/*.json`.

*Step 3*: Replace the string in your template with the translation key.

```pug
/ Instead of this:
button(type='button', ng-class='map-btn') Map

/ Add a translate="YOUR_TRANSLATION_KEY" attribute and remove the innerHTML
button(type='button', ng-class='map-btn', translate='search.map_btn')
```

Your commit should look something like this example:
[1f65a50](https://github.com/bion/falling-fruit-mobile/commit/1f65a504ab4d0bfb70e3063d30040174c0071cf1)

#### Manage empty translation keys

By design, `angular-translate` falls back to the default language for a key only if the key is missing in the desired language, not if the key in the desired language is empty (see [here](https://github.com/angular-translate/angular-translate/issues/815)). To ensure that language fallbacks work as expected, empty translation keys can be filled with the value for that key in the default language using the following default parameters for `phraseapp pull` (included in `.phraseapp.yml.sample`):

```
fallback_locale_id: 53d2ae32ea5672ed2a5f322670c95d98
```

### Develop with grunt

Grunt is used to compile source code in `/src` into `/www`:

```
cd bin
grunt pug coffee less
```

To start a watcher that automatically recompiles when files are saved:

```
grunt watch
```

To run the app in a browser:

```
grunt devserver
```

Then browse to [http://localhost:9001](http://localhost:9001).

You'll need to disable CORS warnings in your browser. The easiest way to do that is to install [this Chrome plugin](https://chrome.google.com/webstore/detail/allow-control-allow-origi/nlfbmbojpeacfghkpbjhddihlkkiljbi/related?hl=en).

### Run on Android

To build the app for Android, follow these [instructions](https://cordova.apache.org/docs/en/latest/guide/platforms/android/index.html) to install the requirements.

You will need to download the following packages:

  * SDK Platforms:
    * Android 9.0 (API 29)
  * SDK Tools:
    * Android SDK Build-Tools (29-latest)
    * Android SDK Platform-Tools (latest)
    * Android SDK Tools (latest)

You can then initialize the Android platform following the dependencies defined in `package.json`:

```
cordova prepare android
```

And build!

```
cordova build android
```

#### Android emulators

Follow [these instructions](https://developer.android.com/studio/run/managing-avds.html) for creating and managing Android Virtual Devices (AVD) in Android Studio, or use `avdmanager` from the command line.

List available physical and virtual devices:

```
cordova run android --list
```

Build and run the app on the default virtual device:

```
cordova run android --emulator
```

or on a specific device:

```
cordova run android --target=<DEVICE_NAME>
```

You can debug with Chrome at [chrome://inspect/#devices](chrome://inspect/#devices).

#### Android devices

First, enable USB Debugging (Developer menu) and allow apps from untrusted sources (Security menu).
Then plug the device into your computer, start the `adb` (Android Debug Bridge) server, and check that the device is listed:

```
sudo adb start-server
cordova run android --list
```

Build and run the app on the default physical device:

```
cordova run android --device
```

or on a specific device:

```
cordova run android --target=<DEVICE_NAME>
```

You can debug with Chrome at [chrome://inspect/#devices](chrome://inspect/#devices).

#### Submit to Google Play

Generate a release build:

```
cordova build android --release
```

Then sign and zipalign the build for submission to Google Play using the (secret) application keystore:

```
cd platforms/android/app/build/outputs/apk/release
jarsigner -keystore KEYSTORE_PATH -storepass KEYSTORE_PASS app-release-unsigned.apk ALIAS_NAME
mv app-release-unsigned.apk app-release-signed.apk
zipalign -v 4 app-release-signed.apk app-release.apk
rm app-release-signed.apk
cd ../../../../../../../
```

### Run on iOS

You can only build iOS applications on a Mac. Follow these [instructions](https://cordova.apache.org/docs/en/latest/guide/platforms/ios/index.html) to install the requirements.

You can then initialize the ios platform directory (deleting any deprecated one):

```
cordova platform rm ios
cordova platform add ios
```

And build!

```
cordova build ios
```

#### iOS emulators

Once you have built successfully, open `platforms/ios/Falling\ Fruit.xcworkspace` in Xcode and run the app on the selected emulator.

#### iOS devices

(coming soon!)

## Icons & Splashscreens
    http://ionicframework.com/docs/cli/icon-splashscreen.html

  * ionic cli must be installed like comes with a new app (http://ionicframework.com/getting-started/)
  * Save an icon.png, icon.psd or icon.ai file within the resources directory at the root of the Cordova project. The icon image's minimum dimensions should be 192x192 px, and should have no rounded corners.
  * Save a splash.png, splash.psd or splash.ai file within the resources directory at the root of the Cordova project. Splash screen dimensions vary for each platform, device and orientation, so a square source image is required the generate each of various sizes. The source image's minimum dimensions should be 2208x2208 px, and its artwork should be centered within the square, knowning that each generated image will be center cropped into landscape and portait images. The splash screen's artwork should roughly fit within a center square (1200x1200 px).
  * Run ionic resources in terminal
  * Move new images to the icons folder as this seems to be an older version of cordova/ionic
