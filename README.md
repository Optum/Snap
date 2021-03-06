![FileImage](./Files.png)

Thanks for your interest in Optum’s Snap project!  Unfortunately, we have moved on and this project is no longer actively maintained or monitored by our Open Source Program Office.  This copy is provided for reference only.  Please fork the code if you are interested in further development.  The project and all artifacts including code and documentation remain subject to use and reference under the terms and conditions of the open source license indicated.  All copyrights reserved.

# Snap 
![Snap Icon](https://github.com/Optum/Snap/blob/master/icons/SNAPIcon.png)

Snap is a Mac application that helps sign **iOS** (xcarchive & ipa bundles) and **Android** (apk bundles) mobile apps for publishing to the app stores.  This app gives you the ability to select the files needed to resign your app, and then runs through the lengthy list of commands needed for each scenario.

## New feature
### Snap now has a tab to upload iOS dSYM files to Firebase.

## What you need installed:
1. Xcode
2. Android Studio
3. JDK

## Current functionality
### Apple, iOS
1. Export an .ipa from an Xcarchive
2. Resign an .ipa
- resigns frameworks and main bundle.  Does **not** resign extensions or watch apps, yet.
- removes arm64e architecture
- allows for build version changes
- choose to sign for enterprise distribution
3. Leaves a log.txt file in the directory next to the .xcarchive or .ipa file

### Needed for iOS apps
In order to export or resign an iOS application, you need to have your distribution certificate for the Apple App Store, and the mobile.provision file for the app. You need to have Xcode installed.

##
### Google, Android
1. Resign an .apk for Google Play Store
2. Resign using either a keystore or jks fils
3. Leaves a log.txt file in the directory next to the .apk file

### Needed for Android apps 
In order to align an apk for the Google Play Store, you need to have the .keystore file for the correct account you are distributing through.  You need to have Android Studio installed, and a JDK.

## Contributing to Snap

[Contributor Guidelines](./CONTRIBUTING.md)


## License

[Apache License v2.0](./LICENSE)
