Falling Fruit Mobile
====================

This is a phonegap/cordova companion application for Falling Fruit.

It is an singular page angular app that uses the jade, less, and coffee preprocessors.

The backend is accessed over a RESTful JSON API served up at fallingfruit.org/api/

## Directory Layout

  * bin - grunt and npm configuration
  * docs - extra documentation
  * hooks - Cordova hooks
  * icons - Platform icon and splashscreen graphics
  * platforms - Platform configuration and code compiled by grunt and Cordova
  * plugins - Cordova plugins
  * resources - same as icons (?)
  * src - Source code for the site
    * jade - compiles to html
    * less - compiles to css
    * coffee - compiles to javascript
  * www - Code compiled by grunt from /src, along with static files (e.g. images, js libraries).

## Code Layout

  * Factories (reusable code)
    * misc.coffee - miscellaneous functions
    * i18n.coffee - things pertaining to i18n
    * auth.coffee - things pertaining to and controlling authentication
  * Controllers (do stuff all the time!!!)
    * detail.coffee - display/edit a single location
    * search.coffee - the main map and list view
    * menu.coffee - the settings/filters sidebar
  * Directives (compartmentalized code)
    * directives.coffee - map, spinner, etc

## Build instructions

### Install Node and Dependencies

```
curl https://raw.githubusercontent.com/creationix/nvm/v0.23.3/install.sh | bash
echo "source ~/.nvm/nvm.sh" >> ~/.bashrc
. ~/.bashrc
nvm install 0.10
npm install -g cordova
npm install -g grunt-cli
cd bin
npm install
cd ..
```

### Develop with Grunt

Grunt is used to compile things in the "src" directory into "www". To do this, you:

```
cd bin
grunt jade coffee less
```

If you want to start a watcher that will automatically recompile things when they are saved do:

```
grunt watch
```

If you want to start the local grunt server so you can run the app like a webapp (without compiling a device package or starting the emulator):

```
grunt devserver
```

You'll need to make sure to disable CORS warnings in your browser. The easiest way to do that is to install [this plugin](https://chrome.google.com/webstore/detail/allow-control-allow-origi/nlfbmbojpeacfghkpbjhddihlkkiljbi/related?hl=en).

Then browse to [http://localhost:9001](http://localhost:9001).

### Develop with the Emulators

#### Download the Android SDK

If you want to see how the app looks in an emulator or on a phone, you'll need to install the Android or iOS SDKs. Here are the instructions for Android:

```
wget http://dl.google.com/android/android-sdk_r24.0.2-linux.tgz
tar xvzf android-sdk_r24.0.2-linux.tgz
mv android-sdk-linux ~/android-sdk

export PATH=$PATH:~/android-sdk/tools
export ANDROID_HOME=~/android-sdk
```

Now, run the "android" command and make sure to install Android 19 SDK and 19.1 Build Tools (in addition to whichever other versions seem useful!)
These instructions may be helpful: http://spring.io/guides/gs/android/

Create the android device:

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

To use your keyboard, edit ~/.android/avd/cordova.ini, adding these lines

```
hw.keyboard=yes
hw.dPad=yes
```

Finally to build and emulate on android:

```
cordova emulate android
```

If you want to debug with Chrome, go to: chrome://inspect/#devices

#### Setup XCode (iOS SDK)

You can only build iOS applications on a Mac. Here are the instructions to setup X-Code:

	http://cordova.apache.org/docs/en/4.0.0/guide_platforms_ios_index.md.html

- You may need to run cordova build from the falling-fruit-mobile folder before opening
- From within Xcode open the falling-fruit-mobile/platforms/ios/FallingFruit.xcodeproj file.
- Make sure the .xcodeproj file is selected in the left panel.
- Select the hello app in the panel immediately to the right.
- Select the intended device from the toolbar's Scheme menu, such as the iPhone 6.0 Simulator as highlighted here:
- Press the Run button that appears in the same toolbar to the left of the Scheme. That builds, deploys and runs the application in the emulator. A separate emulator application opens to display the app:
- http://stackoverflow.com/questions/8377970/xcode-ios-project-only-shows-my-mac-64-bit-but-not-simulator-or-device (If My Mac is only build option for Xcode)

```
Only one emulator may run at a time, so if you want to test the app in a different emulator, you need to quit the emulator application and run a different target within Xcode.
```

### Develop with a device

#### Android-based phone

Plug your phone into your computer. Ensure that in the Phone's settings you've enabled USB Debugging (under Developer) and that you can install things from Untrusted sources (under Security).

```
sudo adb start-server
adb devices
```

Should start the adb server with sufficient permissions and list your device. To build and install an APK on the device:

```
cordova build android
adb -d install -r /path/to/thething.apk
```

## Icons and Splash Screens
	http://ionicframework.com/docs/cli/icon-splashscreen.html

- ionic cli must be installed like comes with a new app (http://ionicframework.com/getting-started/)

- Save an icon.png, icon.psd or icon.ai file within the resources directory at the root of the Cordova project. The icon image's minimum dimensions should be 192x192 px, and should have no rounded corners.
- Save a splash.png, splash.psd or splash.ai file within the resources directory at the root of the Cordova project. Splash screen dimensions vary for each platform, device and orientation, so a square source image is required the generate each of various sizes. The source image's minimum dimensions should be 2208x2208 px, and its artwork should be centered within the square, knowning that each generated image will be center cropped into landscape and portait images. The splash screen's artwork should roughly fit within a center square (1200x1200 px).
- Run ionic resources in terminal
- Move new images to the icons folder as this seems to be an older version of cordova/ionic
