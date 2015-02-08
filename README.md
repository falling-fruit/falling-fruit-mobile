Falling Fruit Mobile
====================

This is a phonegap/cordova companion application for Falling Fruit.

## Build instructions

### Install Node and Dependencies

```
curl https://raw.githubusercontent.com/creationix/nvm/v0.23.3/install.sh | bash
echo "source ~/.nvm/nvm.sh" >> ~/.bashrc
. ~/.bashrc
nvm install 0.10
npm install -g cordova
cd bin
npm install
cd ..
```

### Download the Android SDK

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

### Setup XCode (iOS SDK)

Seemingly you can only build iOS applications on a Mac. Here are the instructions to setup X-Code:

http://cordova.apache.org/docs/en/4.0.0/guide_platforms_ios_index.md.html
