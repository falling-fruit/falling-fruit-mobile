Falling Fruit Mobile
====================

This is a phonegap/cordova companion application for Falling Fruit.

## Directory Layout

  * bin - grunt and npm configuration
  * docs - our documentation (outside of this readme)
  * src - the core source for the site
    * jade - compiles to html
    * less - compiles to css
    * coffee - compiles to javascript
  * plugins - downloaded cordova plugins
  * www - app code compiled by grunt from stuff in the src directory along with static things like images and js libraries
  * platforms - app code for various platforms (android, ios) compiled by grunt and/or cordova

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
grunt jade
grunt coffee
grunt less
```

If you want to start a watcher that will automatically recompile things when they are saved do:

```
grunt watch
```

If you want to start the local grunt server so you can run the app like a webapp (without compiling a device package or starting the emulator):

```
grunt devserver
```

Then browse to http://localhost:9001

### Download the Android SDK

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

### Setup XCode (iOS SDK)

Seemingly you can only build iOS applications on a Mac. Here are the instructions to setup X-Code:

http://cordova.apache.org/docs/en/4.0.0/guide_platforms_ios_index.md.html
