//
//  ApkViewController.swift
//  Snap
//
//  Created by Scott, Christopher A on 10/20/19.
//  Copyright © 2019 Scott, Christopher A. All rights reserved.
//

import Cocoa

class ApkViewController: NSViewController, selectedAPK, selectedKeyFile {

    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var apkTextField: DragNDropApkTextField!
    @IBOutlet weak var keyFileTextField: DragNDropKeyFileTextField!
    @IBOutlet weak var keyFilePasswordTextField: NSSecureTextField!
    @IBOutlet weak var aliasPopUpButton: NSPopUpButton!
    @IBOutlet weak var aliasPasswordTextField: NSSecureTextField!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!

    var googleSigner = GoogleSigner()

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.isHidden = true
        activityIndicator.minValue = 0
        activityIndicator.maxValue = 10
        activityIndicator.isIndeterminate = false

        errorLabel.stringValue = ""

        aliasPopUpButton.removeAllItems()

//        do {
//            try appleSigner.getSigningIdentities(signingIdentityPopUp)
//        } catch {
//            postError("Unable to get signing identities")
//            return
//        }

    }

    override func viewDidAppear() {
        super.viewDidAppear()
//        bundleIdTextField.resignFirstResponder()
    }


    @IBAction func resignApk(_ sender: Any) {
//
//        errorLabel.stringValue = ""
//        activityIndicator.doubleValue = 0
//        activityIndicator.isHidden = false
//
//        if useBundleIdCheckBox.state == .on {
//            appleSigner.bundleID = bundleIdTextField.stringValue
//            appleSigner.userProvidedBundleID = true
//        } else {
//            appleSigner.userProvidedBundleID = false
//        }
//
//        if useBuildNumberCheckBox.state == .on {
//            appleSigner.buildNumber = buildNumberTextField.stringValue
//            appleSigner.userProvidedBuildNumber = true
//        } else {
//            appleSigner.userProvidedBuildNumber = false
//        }
//
//        self.activityIndicator.increment(by: 1)
//
//        appleSigner.signingIdentity = signingIdentityPopUp.selectedItem?.title
//
//        self.activityIndicator.increment(by: 1)
//
//        postMsg("Unzipping ipa in progress")
//
//        do {
//            try appleSigner.unzipIPA()
//        } catch BuildError.canNotUnzipIPA {
//            postError("Unable to unzip IPA")
//            return
//        }  catch {
//            postError("Unable to unzip IPA")
//            return
//        }
//
//        postMsg("Extracting entitlements in progress")
//
//        do {
//            try appleSigner.retrieveEntitlements()
//        } catch BuildError.canNotListApps {
//            postError("Unable to list apps in ipa")
//            return
//        } catch BuildError.etitlements {
//            postError("Unable to copy out entitlements.plist from ipa")
//            return
//        } catch {
//            postError("Unable to retrieve entitlements from ipa")
//            return
//        }
//        self.activityIndicator.increment(by: 1)
//
//        postMsg("Analyzing mobileprovision and entitlements in progress")
//
//        do {
//            try appleSigner.createMobileProvisioningPlistFileAndCopyEntitlements()
//        } catch BuildError.canNotReadMobileProvisionFile {
//            postError("Could not open that mobile provisioning file")
//            return
//        } catch BuildError.mobileProvisionFile {
//            postError("Unable to find entitlements in mobile provisioning file")
//            return
//        } catch {
//            postError("Unable to create mobile provisioning file and find entitlements")
//            return
//        }
//        self.activityIndicator.increment(by: 1)
//
//        postMsg("Removing architectures in progress")
//
//        do {
//            try appleSigner.removeArchitectures()
//        } catch {
//            postError("Could not remove architectures")
//            return
//        }
//        self.activityIndicator.increment(by: 1)
//
//        postMsg("Replacing embedded.mobileprovision in progress")
//
//        do {
//            try appleSigner.replaceEmbeddedProvisionFile()
//        } catch {
//            postError("Could not replace embedded mobile provisioning file")
//            return
//        }
//        self.activityIndicator.increment(by: 1)
//
//
//        postMsg("Resolving bundle id in progress")
//
//        do {
//            try appleSigner.getBundleId()
//        } catch BuildError.bundleid {
//            postError("Could not find Bundle ID in mobile provisioning file")
//            return
//        } catch {
//            postError("Could not save Export Options plist")
//            return
//        }
//        self.activityIndicator.increment(by: 1)
//
//        postMsg("Updating info.plist in progress")
//
//        do {
//            try appleSigner.updateInfoPlist()
//        } catch BuildError.updateInfoPlist {
//            postError("Could not find CFBundleIdentifier in plist file")
//            return
//        } catch {
//            postError("Could not find CFBundleIdentifier in plist file")
//            return
//        }
//        self.activityIndicator.increment(by: 1)
//
//        postMsg("Code signing in progress.  This stage can take a minute.")
//
//        do {
//            try appleSigner.removeCodeSigning()
//        } catch {
//            // There is no error we catch here
//            return
//        }
//        self.activityIndicator.increment(by: 1)
//
//        do {
//            try appleSigner.reCodeSigning()
//        } catch {
//            // There is no error we catch here
//            return
//        }
//        self.activityIndicator.increment(by: 1)
//
//        do {
//            postMsg("Final Stage: Zipping up the ipa!")
//            try appleSigner.zipIPA()
//        } catch {
//            postError("Zipping ipa failed!")
//            return
//        }
//        self.activityIndicator.increment(by: 1)
//
//        activityIndicator.isHidden = true
//        activityIndicator.doubleValue = 0
//
//        postMsg("Resigning completed Successfully!")
    }

    @IBAction func selectApk(_ sender: Any) {

        let dialog = NSOpenPanel();

        dialog.title                   = "Choose a .apk file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["apk"];

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path = result!.path
                selectedAPK(path)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }

    @IBAction func selectKeyFile(_ sender: Any) {

        let dialog = NSOpenPanel();

        dialog.title                   = "Choose a key file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["keystore"];

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path = result!.path
                selectedKeyFile(path)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }

    func selectedAPK(_ path: String) {
        clearFields()
        apkTextField.stringValue = path
        apkTextField.abortEditing()
//        appleSigner.pathToIPA = URL(fileURLWithPath: path)
    }

    func selectedKeyFile(_ path: String) {
        keyFileTextField.stringValue = path
        keyFileTextField.abortEditing()
        googleSigner.pathToKeyStore = URL(fileURLWithPath: path)
    }


    func clearFields() {
//        mobileprovisionTextField.stringValue = ""
//        appleSigner.pathToMobileProvisionForArchive = nil

    }

    func postError(_ errorString: String ) {
        errorLabel.stringValue = errorString
        errorLabel.textColor = .red

        activityIndicator.isHidden = true
        activityIndicator.doubleValue = 0
    }

    func postMsg(_ msgString: String ) {
        errorLabel.stringValue = msgString
        errorLabel.textColor = .green
    }
}