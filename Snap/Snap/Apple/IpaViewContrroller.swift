//
//  IpaViewContrroller.swift
//  Snap
//
//  Created by Scott, Christopher A on 10/20/19.
//  Copyright © 2019 Scott, Christopher A. All rights reserved.
//

import Cocoa

class IpaViewContrroller: NSViewController, SelectedFile {

    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var ipaTextField: DragNDropFiles!
    @IBOutlet weak var mobileprovisionTextField: DragNDropFiles!
    @IBOutlet weak var entitlementsTextField: DragNDropFiles!
    @IBOutlet weak var signingIdentityPopUp: NSPopUpButton!
    @IBOutlet weak var bundleIdTextField: NSTextField!
    @IBOutlet weak var useBundleIdCheckBox: NSButton!
    @IBOutlet weak var buildNumberTextField: NSTextField!
    @IBOutlet weak var useBuildNumberCheckBox: NSButton!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!

    var appleSigner = AppleSigner()

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.isHidden = true
        activityIndicator.minValue = 0
        activityIndicator.maxValue = 10
        activityIndicator.isIndeterminate = false

        errorLabel.stringValue = ""

        signingIdentityPopUp.removeAllItems()

        ipaTextField.del = self
        ipaTextField.expectedExt = [.ipa]

        mobileprovisionTextField.del = self
        mobileprovisionTextField.expectedExt = [.mobileprovision]

        entitlementsTextField.del = self
        entitlementsTextField.expectedExt = [.plist]

        do {
            try appleSigner.getSigningIdentities(signingIdentityPopUp)
        } catch {
            postError("Unable to get signing identities")
            return
        }

    }

    override func viewDidAppear() {
        super.viewDidAppear()
        bundleIdTextField.resignFirstResponder()

    }


    @IBAction func resignIPA(_ sender: Any) {

        errorLabel.stringValue = ""
        activityIndicator.doubleValue = 0
        activityIndicator.isHidden = false

        //clear entitlements if it isn't set
        if entitlementsTextField.stringValue.count == 0 {
            appleSigner.pathToEntitlementsPlist = nil
        }

        if useBundleIdCheckBox.state == .on {
            appleSigner.bundleID = bundleIdTextField.stringValue
            appleSigner.userProvidedBundleID = true
        } else {
            appleSigner.userProvidedBundleID = false
        }

        if useBuildNumberCheckBox.state == .on {
            appleSigner.buildNumber = buildNumberTextField.stringValue
            appleSigner.userProvidedBuildNumber = true
        } else {
            appleSigner.userProvidedBuildNumber = false
        }

        self.activityIndicator.increment(by: 1)

        appleSigner.signingIdentity = signingIdentityPopUp.selectedItem?.title

        self.activityIndicator.increment(by: 1)

        postMsg("Unzipping ipa in progress")

        do {
            try appleSigner.unzipIPA()
        } catch BuildError.canNotUnzipIPA {
            postError("Unable to unzip IPA")
            return
        }  catch {
            postError("Unable to unzip IPA")
            return
        }

        postMsg("Extracting entitlements in progress")

        do {
            if entitlementsTextField.stringValue.count == 0 {
                appleSigner.userProvidedExportOptions = false
            } else {
                appleSigner.userProvidedExportOptions = true
            }

            try appleSigner.retrieveEntitlements()
        } catch BuildError.canNotListApps {
            postError("Unable to list apps in ipa")
            return
        } catch BuildError.entitlements {
            postError("Unable to copy out entitlements.plist from ipa")
            return
        } catch {
            postError("Unable to retrieve entitlements from ipa")
            return
        }
        self.activityIndicator.increment(by: 1)

        postMsg("Analyzing mobileprovision and entitlements in progress")

        do {
            try appleSigner.createMobileProvisioningPlistFileAndCopyEntitlements()
        } catch BuildError.canNotReadMobileProvisionFile {
            postError("Could not open that mobile provisioning file")
            return
        } catch BuildError.mobileProvisionFile {
            postError("Unable to find entitlements in mobile provisioning file")
            return
        } catch {
            postError("Unable to create mobile provisioning file and find entitlements")
            return
        }
        self.activityIndicator.increment(by: 1)

        postMsg("Removing architectures in progress")

        do {
            try appleSigner.removeArchitectures()
        } catch {
             postError("Could not remove architectures")
            return
        }
        self.activityIndicator.increment(by: 1)

        postMsg("Replacing embedded.mobileprovision in progress")

        do {
            try appleSigner.replaceEmbeddedProvisionFile()
        } catch {
            postError("Could not replace embedded mobile provisioning file")
            return
        }
        self.activityIndicator.increment(by: 1)


        postMsg("Resolving bundle id in progress")

        do {
            try appleSigner.getBundleId()
        } catch BuildError.bundleid {
            postError("Could not find Bundle ID in mobile provisioning file")
            return
        } catch {
            postError("Could not save Export Options plist")
            return
        }
        self.activityIndicator.increment(by: 1)

        postMsg("Updating info.plist in progress")

        do {
            try appleSigner.updateInfoPlist()
        } catch BuildError.updateInfoPlist {
            postError("Could not find CFBundleIdentifier in plist file")
            return
        } catch {
            postError("Could not find CFBundleIdentifier in plist file")
            return
        }
        self.activityIndicator.increment(by: 1)

        postMsg("Code signing in progress.  This stage can take a minute.")

        do {
            try appleSigner.removeCodeSigning()
        } catch {
            // There is no error we catch here
            return
        }
        self.activityIndicator.increment(by: 1)

        do {
            try appleSigner.reCodeSigning()
        } catch {
            // There is no error we catch here
            return
        }
        self.activityIndicator.increment(by: 1)

        do {
            postMsg("Final Stage: Zipping up the ipa!")
            try appleSigner.zipIPA()
        } catch {
            postError("Zipping ipa failed!")
            return
        }
        self.activityIndicator.increment(by: 1)

        do {
            try? appleSigner.cleanup()
        }
        
        activityIndicator.isHidden = true
        activityIndicator.doubleValue = 0

        postMsg("Resigning completed Successfully!")
    }

    @IBAction func selectIPA(_ sender: Any) {

        let dialog = NSOpenPanel();

        dialog.title                   = "Choose a .ipa file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["ipa"];

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path = result!.path
                selectedFile(path, textField: ipaTextField)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }

    @IBAction func selectMobileprovisionFile(_ sender: Any) {

        let dialog = NSOpenPanel();

        dialog.title                   = "Choose an .mobileprovision file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["mobileprovision"];

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path = result!.path
                selectedFile(path, textField: mobileprovisionTextField)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }

    @IBAction func selectEntitlements(_ sender: Any) {

        let dialog = NSOpenPanel();

        dialog.title                   = "Choose an Entitlements.plist file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["plist"];

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path = result!.path
                selectedFile(path, textField: entitlementsTextField)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }

    func selectedFile(_ path: String, textField: NSTextField) {

        switch textField {
        case ipaTextField:
            clearFields()
            ipaTextField.stringValue = path
            ipaTextField.abortEditing()
            appleSigner.pathToIPA = URL(fileURLWithPath: path)
        case mobileprovisionTextField:
            mobileprovisionTextField.stringValue = path
            appleSigner.pathToMobileProvisionForArchive = URL(fileURLWithPath: path)
            mobileprovisionTextField.abortEditing()
        case entitlementsTextField:
            entitlementsTextField.stringValue = path
            appleSigner.pathToEntitlementsPlist = URL(fileURLWithPath: path)
            entitlementsTextField.abortEditing()
        default:
            break
        }
    }

    func clearFields() {
        mobileprovisionTextField.stringValue = ""
        appleSigner.pathToMobileProvisionForArchive = nil

        appleSigner.pathToExportOptionsForArchive = nil
        entitlementsTextField.stringValue = ""
        appleSigner.pathToEntitlementsPlist = nil

        bundleIdTextField.stringValue = ""
        appleSigner.bundleID = nil
        useBundleIdCheckBox.state = .off

        buildNumberTextField.stringValue = ""
        appleSigner.buildNumber = nil
        useBuildNumberCheckBox.state = .off
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
