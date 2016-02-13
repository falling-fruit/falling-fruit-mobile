Falling Fruit Mobile
====================

This is a Cordova mobile application for Falling Fruit. It is a single-page angular app written in jade, less, and coffee. The backend is accessed over a RESTful JSON API served up at [https://fallingfruit.org/api/](https://fallingfruit.org/api/).

## Directory layout

  * `/bin` - grunt and npm configuration
  * `/docs` - extra documentation
  * `/hooks` - Cordova hooks
  * `/icons` - Platform icon and splashscreen graphics
  * `/platforms` - Platform configuration and code compiled by grunt and Cordova
  * `/plugins` - Cordova plugins (not included in repo)
  * `/resources` - same as icons (?)
  * `/src` - Source code for the site
    * `/jade` - compiles to html
    * `/less` - compiles to css
    * `/coffee` - compiles to javascript
  * `/www` - Code compiled by grunt from /src, along with static files (e.g. images, js libraries).

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

  * Node Version Manager (nvm): [installation instructions](https://github.com/creationix/nvm)
  * Node (0.10): 
  
  ```
  nvm install 0.10
  ```
  
  * Cordova (5.4.1): 
  
  ```
  npm install -g cordova@5.4.1
  ```
  
  * grunt-cli: 
  
  ```
  npm install -g grunt-cli
  ```
  
  * Node packages: 
  
  ```
  cd bin
  npm install
  cd ..
  ```

### Develop with grunt

Grunt is used to compile source code in `/src` into `/www`:

```
cd bin
grunt jade coffee less
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

You'll need to disable CORS warnings in your browser. The easiest way to do that is to install [this chrome plugin](https://chrome.google.com/webstore/detail/allow-control-allow-origi/nlfbmbojpeacfghkpbjhddihlkkiljbi/related?hl=en).

### Run on Android

To build the app for Android, you'll need to install the Android SDKs. 

  * Download and install the latest Android SDK Tools: [download links](http://developer.android.com/sdk/index.html#Other),  [instructions](http://spring.io/guides/gs/android/).
  * Add the new folder to your path:

  ```
  export ANDROID_HOME=<installation location>
  export PATH=$PATH:$ANDROID_HOME/tools
  ```

  * Run the Android SDK Manager:
  
  ```
  android
  ```
  *  With it, select and install the following packages:
  
    * Android SDK Platform-tools (latest)
    * Android SDK Platform (v22)
    * Android SDK Build-tools (v22.latest)

#### Android emulators

Create the android emulator:

```
android create avd --name cordova --target 1 --abi default/x86
```

On linux, you may also need to setup KVM and/or force 32 bit:

```
sudo apt-get install cpu-checker
kvm-ok
sudo modprobe kvm_intel
export ANDROID_EMULATOR_FORCE_32BIT=true
```

To use your keyboard, edit `~/.android/avd/cordova.ini`, adding these lines

```
hw.keyboard=yes
hw.dPad=yes
```

Finally to build and emulate on android:

```
cordova emulate android
```

If you want to debug with Chrome, go to [chrome://inspect/#devices](chrome://inspect/#devices).

#### Android devices

Plug the device into your computer. Ensure that you've enabled USB Debugging (Developer menu) and that you can install apps from Untrusted sources (Security menu). Then start the adb server and make sure the device is detected:

```
sudo adb start-server
adb devices
```

To build and install the app on the device:

```
cordova build android
adb -d install -r platforms/android/build/outputs/apk/android-debug.apk
```

If you want to debug with Chrome, go to [chrome://inspect/#devices](chrome://inspect/#devices).

### Run on iOS

You can only build iOS applications on a Mac ([instructions](http://cordova.apache.org/docs/en/5.4.0/guide/platforms/ios/index.html)).

#### iOS emulators

To build and emulate on iOS:

```
cordova build ios
```

Then open `platforms/ios/FallingFruit.xcodeproj` in Xcode and run the app on the selected emulator.

Only one emulator may run at a time, so quit iOS Simulator before running the app in a different target device.


#### iOS devices

(coming soon!)

## Icons and Splashscreens
	http://ionicframework.com/docs/cli/icon-splashscreen.html

  * ionic cli must be installed like comes with a new app (http://ionicframework.com/getting-started/)
  * Save an icon.png, icon.psd or icon.ai file within the resources directory at the root of the Cordova project. The icon image's minimum dimensions should be 192x192 px, and should have no rounded corners.
  * Save a splash.png, splash.psd or splash.ai file within the resources directory at the root of the Cordova project. Splash screen dimensions vary for each platform, device and orientation, so a square source image is required the generate each of various sizes. The source image's minimum dimensions should be 2208x2208 px, and its artwork should be centered within the square, knowning that each generated image will be center cropped into landscape and portait images. The splash screen's artwork should roughly fit within a center square (1200x1200 px).
  * Run ionic resources in terminal
  * Move new images to the icons folder as this seems to be an older version of cordova/ionic
