//
//  ViewController.swift
//  Snap
//
//  Created by Scott, Christopher A on 10/20/19.
//  Copyright © 2019 Scott, Christopher A. All rights reserved.
//

import Cocoa

class ArchiveViewController: NSViewController, SelectedFile {

    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var xcarchiveTextField: DragNDropFiles!
    @IBOutlet weak var entitlementsTextField: DragNDropFiles!
    @IBOutlet weak var exportOptionsTextField: DragNDropFiles!
    @IBOutlet weak var mobileprovisionTextField: DragNDropFiles!
    @IBOutlet weak var signingIdentityPopUp: NSPopUpButton!
    @IBOutlet weak var bundleIdTextField: NSTextField!
    @IBOutlet weak var useBundleIdCheckBox: NSButton!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    @IBOutlet weak var isEnterpriseRelease: NSButton!

    var appleSigner = AppleSigner()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.isHidden = true
        activityIndicator.minValue = 0
        activityIndicator.maxValue = 11
        activityIndicator.isIndeterminate = false
        
        errorLabel.stringValue = ""
        
        signingIdentityPopUp.removeAllItems()
        
        xcarchiveTextField.del = self
        xcarchiveTextField.expectedExt = [.xcarchive]
        
        mobileprovisionTextField.del = self
        mobileprovisionTextField.expectedExt = [.mobileprovision]
        
        exportOptionsTextField.del = self
        exportOptionsTextField.expectedExt = [.plist]
        
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
        clearFields()
    }


    @IBAction func exportIpa(_ sender: Any) {

        errorLabel.stringValue = ""
        activityIndicator.doubleValue = 0
        activityIndicator.isHidden = false

        if useBundleIdCheckBox.state == .on {
            appleSigner.bundleID = bundleIdTextField.stringValue
            appleSigner.userProvidedBundleID = true
        } else {
            appleSigner.userProvidedBundleID = false
        }

        if isEnterpriseRelease.state == .on {
            appleSigner.isEnterpriseRelease = true
        } else {
            appleSigner.isEnterpriseRelease = false
        }

        self.activityIndicator.increment(by: 1)

        appleSigner.signingIdentity = signingIdentityPopUp.selectedItem?.title

        self.activityIndicator.increment(by: 1)

        postMsg("Extracting entitlements in progress")

        do {
            try appleSigner.retrieveEntitlements()
        } catch BuildError.canNotListApps {
            postError("Unable to list apps in xcarchive")
            return
        } catch BuildError.entitlements {
            postError("Unable to copy out entitlements.plist from archive")
            return
        } catch {
            postError("Unable to retrieve entitlements from archive")
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

        postMsg("Creating ExportOptions.plist in progress")

        do {
            try appleSigner.creatExportOPtionsPlist()
        } catch BuildError.exportoptions {
            postError("Could not find Team ID in mobile provisioning file")
            return
        } catch {

            postError("Could not save Export Options plist")
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

        postMsg("Code signing in progress. This stage can take a minute.")

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
            postMsg("Final stage: exporting ipa.  This stage can take a minute.")
            try appleSigner.exportIPA()
        } catch {
            postError("Exporting ipa failed!")
            return
        }
        self.activityIndicator.increment(by: 1)

        do {
            try? appleSigner.cleanup()
        }

        activityIndicator.isHidden = true
        activityIndicator.doubleValue = 0

        postMsg("Export completed successfully!")
    }

    @IBAction func selectXcarchive(_ sender: Any) {

        let dialog = NSOpenPanel();

        dialog.title                   = "Choose a .xcarchive file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["xcarchive"];

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file

            if (result != nil) {
                let path = result!.path
                selectedFile(path, textField: xcarchiveTextField)
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

    @IBAction func selectExportOptions(_ sender: Any) {

        let dialog = NSOpenPanel();

        dialog.title                   = "Choose an ExportOptions.plist file";
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
                selectedFile(path, textField: exportOptionsTextField)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }

    func selectedFile(_ path: String, textField: NSTextField) {

        switch textField {
        case xcarchiveTextField:
            clearFields()
            xcarchiveTextField.stringValue = path
            xcarchiveTextField.abortEditing()
            appleSigner.pathToArchive = URL(fileURLWithPath: path)
        case entitlementsTextField:
            entitlementsTextField.stringValue = path
            appleSigner.pathToEntitlementsPlist = URL(fileURLWithPath: path)

            entitlementsTextField.abortEditing()
        case exportOptionsTextField:
            exportOptionsTextField.stringValue = path
            appleSigner.pathToExportOptionsForArchive = URL(fileURLWithPath: path)
            exportOptionsTextField.abortEditing()
        case mobileprovisionTextField:
            mobileprovisionTextField.stringValue = path
            appleSigner.pathToMobileProvisionForArchive = URL(fileURLWithPath: path)
            mobileprovisionTextField.abortEditing()
        default:
            break
        }
    }

    func clearFields() {
        mobileprovisionTextField.stringValue = ""
        appleSigner.pathToMobileProvisionForArchive = nil
        exportOptionsTextField.stringValue = ""
        appleSigner.pathToExportOptionsForArchive = nil
        entitlementsTextField.stringValue = ""
        appleSigner.pathToEntitlementsPlist = nil
        bundleIdTextField.stringValue = ""
        appleSigner.bundleID = nil
        useBundleIdCheckBox.state = .off

        xcarchiveTextField.resignFirstResponder()
        entitlementsTextField.resignFirstResponder()
        exportOptionsTextField.resignFirstResponder()
        mobileprovisionTextField.resignFirstResponder()
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

