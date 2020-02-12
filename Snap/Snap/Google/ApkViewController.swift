//
//  ApkViewController.swift
//  Snap
//
//  Created by Scott, Christopher A on 10/20/19.
//  Copyright © 2019 Scott, Christopher A. All rights reserved.
//

import Cocoa

class ApkViewController: NSViewController, selectedAPK, selectedKeyFile, NSTextFieldDelegate {

    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var apkTextField: DragNDropApkTextField!

    @IBOutlet weak var keyFileTextField: DragNDropKeyFileTextField!
    @IBOutlet weak var keyFilePasswordTextField: NSSecureTextField!

    @IBOutlet weak var aliasPopUpButton: NSPopUpButton!
    @IBOutlet weak var aliasPasswordTextField: NSSecureTextField!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!

    var googleSigner = GoogleSigner()
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.isHidden = true
        activityIndicator.minValue = 0
        activityIndicator.maxValue = 5
        activityIndicator.isIndeterminate = false

        keyFilePasswordTextField.delegate = self

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

        errorLabel.stringValue = ""
        activityIndicator.doubleValue = 0
        activityIndicator.isHidden = false

        postMsg("Clearing metadata from apk in progress")

        guard apkTextField.stringValue.count > 0 else {
            postError("No path to an apk file defined")
            return
        }

        googleSigner.pathToAPK = URL(fileURLWithPath: apkTextField.stringValue)

        do {
            try googleSigner.clearMetaDataFromAPK()
        } catch GoogleBuildError.canNotClearMetaData {
            postError("Could not clear metadata from apk")
            return
        }  catch {
            postError("generic error: there was a problem trying to clear metadata from apk")
            return
        }

        postMsg("Aligning apk in progress")
        self.activityIndicator.increment(by: 1)

        do {
            try googleSigner.zipalignApk()
        } catch GoogleBuildError.canNotAlignApk {
            postError("Could not align apk")
            return
        }  catch {
            postError("generic error: ther was a problem trying to align the apk")
            return
        }

        postMsg("Signing apk in progress")
        self.activityIndicator.increment(by: 1)

        guard aliasPasswordTextField.stringValue.count > 0 else {
            postError("No alias password defined")
            return
        }

        googleSigner.aliasPwd = aliasPasswordTextField.stringValue
        googleSigner.aliasName = aliasPopUpButton.selectedItem?.title

        do {
            try googleSigner.jarsignApk()
        } catch GoogleBuildError.canNotSignApk {
            postError("Could not sign apk")
            return
        }  catch {
            postError("generic error: ther was a problem trying to sign the apk")
            return
        }

        postMsg("Aligning apk in progress")
        self.activityIndicator.increment(by: 1)

        do {
            try googleSigner.finalZipalignApk()
        } catch GoogleBuildError.canNotAlignApk {
            postError("Could not align apk")
            return
        }  catch {
            postError("generic error: ther was a problem trying to align the apk")
            return
        }

        postMsg("Verifying apk in progress")
        self.activityIndicator.increment(by: 1)

        do {
            try googleSigner.verifyApk()
        } catch GoogleBuildError.canNotVerifyApk {
            postError("Could not verify apk")
            return
        }  catch {
            postError("generic error: ther was a problem trying to verify the apk")
            return
        }

//        postMsg("Renaming apk in progress")
//        self.activityIndicator.increment(by: 1)
//
//        do {
//            try googleSigner.renameVerifiedApk()
//        } catch GoogleBuildError.canNotRenameApk {
//            postError("Could not rename apk")
//            return
//        }  catch {
//            postError("generic error: ther was a problem trying to rename the apk")
//            return
//        }

        self.activityIndicator.increment(by: 1)

        do {
            try? googleSigner.cleanup()
        }

        activityIndicator.isHidden = true
        activityIndicator.doubleValue = 0

        postMsg("Signing completed successfully!")
    }

    public func controlTextDidChange(_ obj: Notification) {
        // check the identifier to be sure you have the correct textfield if more are used
        // keyFilePasswordTextField: NSSecureTextField
        // aliasFilePassword
        if let textField = obj.object as? NSSecureTextField, self.keyFilePasswordTextField.identifier == textField.identifier {

            if timer != nil {
                timer?.invalidate()
                timer = nil
            }

            if textField.stringValue.count > 0 {

                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
                    guard self.keyFileTextField.stringValue.count > 0 else {
                        self.postError("Enter keystore file before typing your password!")
                        return
                    }

                    self.googleSigner.keystorePwd = self.keyFilePasswordTextField.stringValue
                    self.googleSigner.pathToKeyStore = URL(fileURLWithPath: self.keyFileTextField.stringValue)

                    do {
                        try self.googleSigner.getAlias(self.aliasPopUpButton)
                    } catch {
                        self.postError("Unable to get alias from keystore")
                        return
                    }

                    if self.aliasPopUpButton.itemArray.count > 0 {
                        self.postMsg("Found an alias in your keystore")
                    }
                }
            }
        } else if let textField = obj.object as? NSSecureTextField, self.aliasPasswordTextField.identifier == textField.identifier {

            if textField.stringValue.count > 0 {

                googleSigner.aliasPwd = textField.stringValue
            }
        }
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
