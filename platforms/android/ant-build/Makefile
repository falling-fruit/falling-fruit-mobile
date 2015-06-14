release:
	#cordova build --release android
	jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore my-release-key.keystore CordovaApp-release-unsigned.apk alias_name
	zipalign -f -v 4 CordovaApp-release-unsigned.apk fallingfruit.apk
