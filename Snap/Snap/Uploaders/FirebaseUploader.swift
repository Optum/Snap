//
//  FirebaseUploader.swift
//  Snap
//
//  Created by Scott, Christopher A on 11/2/19.
//  Copyright © 2019 Scott, Christopher A. All rights reserved.
//

import Foundation
import Cocoa

enum FirebaseUploaderError: Error {
    case failedUpload
}

struct FirebaseUploader {

    let cmdLine = CmdLine()
    var pathToAppDir: URL?

    var pathTodSYM: URL?
    var pathToPlist: URL?

    init() {
        pathToAppDir = Bundle.main.bundleURL

    }

    func uploadFileToFirebase() throws {

           let response = cmdLine.runCommand(cmd: "/bin/sh", args: ["-c", "\(pathToAppDir?.path ?? "")/contents/Resources/upload-symbols -gsp \'\(pathToPlist?.path ?? "")\' -p ios \'\(pathTodSYM?.path ?? "")\'"])

           guard response.exitCode == 0 else {
               throw FirebaseUploaderError.failedUpload
           }
       }
}
