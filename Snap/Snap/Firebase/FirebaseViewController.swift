//
//  FirebaseViewContrroller.swift
//  Snap
//
//  Created by Scott, Christopher A on 10/20/19.
//  Copyright © 2019 Scott, Christopher A. All rights reserved.
//

import Cocoa

class FirebaseViewController: NSViewController, SelectedFile {

    let cmdLine = CmdLine()

    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var servicePlistTextField: DragNDropFiles!
    @IBOutlet weak var dSYMTextField: DragNDropFiles!

    @IBOutlet weak var plistButton: NSButton!
    @IBOutlet weak var dSYMButton: NSButton!

    @IBOutlet weak var activityIndicator: NSProgressIndicator!

    var firebaseUploader = FirebaseUploader()

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.isHidden = true
        activityIndicator.minValue = 0
        activityIndicator.maxValue = 1
        activityIndicator.isIndeterminate = false

        errorLabel.stringValue = ""

        servicePlistTextField.del = self
        servicePlistTextField.expectedExt = [.plist]

        dSYMTextField.del = self
        dSYMTextField.expectedExt = [.zip]

        clearFields()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        clearFields()
    }



    @IBAction func uploadFilesToFirebase(_ sender: Any) {

        errorLabel.stringValue = ""
        activityIndicator.doubleValue = 0
        activityIndicator.isHidden = false

        postMsg("Upload in progress")

        do {
            try firebaseUploader.uploadFileToFirebase()
        } catch FirebaseUploaderError.failedUpload {
            postError("Unable to upload file")
            return
        }  catch {
            postError("Unable to upload file")
            return
        }

        activityIndicator.isHidden = true
        activityIndicator.doubleValue = 1

        postMsg("Upload completed!")
    }

    @IBAction func selectGoogleServiceInfo(_ sender: Any) {

        let dialog = NSOpenPanel();

        dialog.title                   = "Choose a GoogleService-Info.plist file";
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
                selectedFile(path, textField: servicePlistTextField)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }

    @IBAction func selectMobileprovisionFile(_ sender: Any) {

         let dialog = NSOpenPanel();

         dialog.title                   = "Choose a dSYM.zip file";
         dialog.showsResizeIndicator    = true;
         dialog.showsHiddenFiles        = false;
         dialog.canChooseDirectories    = true;
         dialog.canCreateDirectories    = false;
         dialog.allowsMultipleSelection = false;
         dialog.allowedFileTypes        = ["zip"];

         if (dialog.runModal() == NSApplication.ModalResponse.OK) {
             let result = dialog.url // Pathname of the file

             if (result != nil) {
                 let path = result!.path
                 selectedFile(path, textField: dSYMTextField)
             }
         } else {
             // User clicked on "Cancel"
             return
         }
     }

    func selectedFile(_ path: String, textField: NSTextField) {

        switch textField {
        case servicePlistTextField:
            servicePlistTextField.stringValue = ""
            servicePlistTextField.stringValue = path
            servicePlistTextField.abortEditing()
            firebaseUploader.pathToPlist = URL(fileURLWithPath: path)
        case dSYMTextField:
            dSYMTextField.stringValue = ""
            dSYMTextField.stringValue = path
            dSYMTextField.abortEditing()
            firebaseUploader.pathTodSYM = URL(fileURLWithPath: path)
        default:
            break
        }
    }

    func clearFields() {
        servicePlistTextField.stringValue = ""
        dSYMTextField.stringValue = ""
        servicePlistTextField.abortEditing()
        dSYMTextField.abortEditing()

        servicePlistTextField.resignFirstResponder()
        dSYMTextField.resignFirstResponder()
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
