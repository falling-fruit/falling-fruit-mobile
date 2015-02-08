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

Now, run the "android" command and make sure to install Android 19 SDK and Build Tools (in addition to whichever other versions)

These instructions may be helpful: http://spring.io/guides/gs/android/

### Do the build!

```
cordova build
```
