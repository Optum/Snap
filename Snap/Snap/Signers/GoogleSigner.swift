//
//  GoogleSigner.swift
//  Snap
//
//  Created by Scott, Christopher A on 11/3/19.
//  Copyright © 2019 Scott, Christopher A. All rights reserved.
//

import Foundation
import Cocoa

enum GoogleBuildError: Error {
    case canNotGetAlias
    case canNotClearMetaData
    case canNotSignApk
    case canNotAlignApk
    case canNotVerifyApk
    case canNotRenameApk
}

struct GoogleSigner {

    var apkName: String?
    var keystorePwd: String? {
           didSet {
            guard pathToAPK != nil else { return }
//               try? getAlias()
           }
       }

    var aliasPwd: String?
    var aliasName: String?

    var saveLocation: URL?
//    var pathToAPK: URL?
    var pathToAppDir: URL?
    var pathToAPK: URL?  {
            didSet {
                saveLocation = pathToAPK?.deletingLastPathComponent()

                let appName = URL(fileURLWithPath: pathToAPK?.path ?? "")
                apkName = appName.deletingPathExtension().lastPathComponent
    //            pathToApp = URL(fileURLWithPath: (pathToAPK?.path ?? "") + "/Products/Applications/")

    //            pathToEntitlementsPlist = self.saveLocation
    //            pathToEntitlementsPlist?.appendPathComponent("entitlements.plist")
            }
        }

    var pathToKeyStore: URL?  {
            didSet {
                guard keystorePwd != nil else { return }
//                try? getAlias()
//                saveLocation = pathToAPK?.deletingLastPathComponent()
    //            pathToApp = URL(fileURLWithPath: (pathToAPK?.path ?? "") + "/Products/Applications/")

    //            pathToEntitlementsPlist = self.saveLocation
    //            pathToEntitlementsPlist?.appendPathComponent("entitlements.plist")
            }
        }

    var aliases = [String]()

    //    MARK: - Shell and Logging

    init() {
        pathToAppDir = Bundle.main.bundleURL

    }

    mutating func getAlias(_ aliasesyPopUp: NSPopUpButton) throws {
        // command for getting list of aliases
        // keytool -list -keystore fooFile.keystore -storepass 'passwordHere'
        let response = runCommand(cmd: "/bin/sh", args: ["-c", "keytool -v -list -keystore \'\(pathToKeyStore?.path ?? "")\' -storepass \'\(keystorePwd ?? "")\'"])

        guard response.exitCode == 0 else {
            aliasesyPopUp.removeAllItems()
            aliasesyPopUp.isEnabled = false
            throw GoogleBuildError.canNotGetAlias
        }

        let regex = try! NSRegularExpression(pattern: "((?<=Alias name: )(.*?))", options: NSRegularExpression.Options.caseInsensitive)

        for words in response.output {
            let matches = regex.matches(in: words, options: [], range: NSRange(location: 0, length: words.utf16.count))

            if matches.first != nil {
                let name = words.replacingOccurrences(of: "Alias name: ", with: "")
                self.aliases.append(name)
                if !aliasesyPopUp.doesContain("\(name)") {
                    aliasesyPopUp.addItem(withTitle: "\(name)")
                }
                aliasesyPopUp.isEnabled = true
            }
        }
        print(aliases)
    }

    func clearMetaDataFromAPK() throws {

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "zip -d \'\(pathToAPK?.path ?? "")\' META-INF/*"])

        guard response.exitCode == 0 || response.exitCode == 12 else {
            throw GoogleBuildError.canNotClearMetaData
        }

    }

    func zipalignApk() throws {

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "\(pathToAppDir?.path ?? "")/contents/Resources/zipalign -f -v 4 \'\(pathToAPK?.path ?? "")\' \'\(saveLocation?.path ?? "")/aligned_\(apkName ?? "").apk\'"])

        guard response.exitCode == 0 else {
            throw GoogleBuildError.canNotAlignApk
        }
    }

    func signApk() throws {

//        ./apksigner sign --ks test.jks --ks-key-alias test --ks-pass pass:testtest --key-pass pass:testtest Test_Aligned.apk

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "\(pathToAppDir?.path ?? "")/contents/Resources/apksigner sign --ks \'\(pathToKeyStore?.path ?? "")\' --ks-key-alias \(aliasName ?? "") --ks-pass pass:\(keystorePwd ?? "") --key-pass pass:\(aliasPwd ?? "") \'\(saveLocation?.path ?? "")/aligned_\(apkName ?? "").apk\'"])

        guard response.exitCode == 0 else {
            throw GoogleBuildError.canNotSignApk
        }
    }

    func jarsignApk() throws {

    //        .jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore your-release-key.keystore android-release-unsigned.apk alias -storepass password

            let response = runCommand(cmd: "/bin/sh", args: ["-c", "/usr/bin/jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore \'\(pathToKeyStore?.path ?? "")\' \'\(saveLocation?.path ?? "")/aligned_\(apkName ?? "").apk\' \(aliasName ?? "") -storepass \(keystorePwd ?? "")"])

            guard response.exitCode == 0 else {
                throw GoogleBuildError.canNotSignApk
            }
        }

    func finalZipalignApk() throws {

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "\(pathToAppDir?.path ?? "")/contents/Resources/zipalign -f -v 4 \'\(saveLocation?.path ?? "")/aligned_\(apkName ?? "").apk\' \'\(saveLocation?.path ?? "")/aligned2_\(apkName ?? "").apk\'"])

        guard response.exitCode == 0 else {
            throw GoogleBuildError.canNotAlignApk
        }
    }

    func verifyApk() throws {

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "\(pathToAppDir?.path ?? "")/contents/Resources/zipalign -f -v 4 \'\(saveLocation?.path ?? "")/aligned2_\(apkName ?? "").apk\' \'\(saveLocation?.path ?? "")/verified_aligned_\(apkName ?? "").apk\'"])

        guard response.exitCode == 0 else {
            throw GoogleBuildError.canNotVerifyApk
        }
    }

    func renameVerifiedApk() throws {

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "mv \'\(saveLocation?.path ?? "")/aligned2_\(apkName ?? "").apk\' \'\(saveLocation?.path ?? "")/aligned_resigned_verified_\(apkName ?? "").apk\'"])

        guard response.exitCode == 0 else {
            throw GoogleBuildError.canNotRenameApk
        }
    }

    //    MARK: - Cleanup functions

    func cleanup() throws {

        guard let savePath = self.saveLocation else {
            throw BuildError.noLogFilePath
        }

        // Remove files
        var file = "log.txt"

        var fileURL = savePath.appendingPathComponent(file)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(atPath: fileURL.path)
        }

        file = "aligned_\(apkName ?? "").apk"
        fileURL = savePath.appendingPathComponent(file)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(atPath: fileURL.path)
        }

        file = "aligned2_\(apkName ?? "").apk"
        fileURL = savePath.appendingPathComponent(file)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(atPath: fileURL.path)
        }
    }

    //    MARK: - Shell and Logging

    func runCommand(cmd : String, args : [String]) -> (output: [String], error: [String]?, exitCode: Int32) {

        var output : [String] = []
        var error : [String] = []

        let task = Process()
        task.launchPath = cmd
        task.arguments = args

        let inpipe = Pipe()
        task.standardInput = inpipe

        let outpipe = Pipe()
        task.standardOutput = outpipe

        let errpipe = Pipe()
        task.standardError = errpipe

        task.launch()

//        inpipe.fileHandleForWriting.write("!nn0vat!0n".data(using: .utf8)!)

        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: "\n")
        }

        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8), string.count > 0 {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: "\n")
        }

        outpipe.fileHandleForReading.readabilityHandler = { fh in
//            let data = fh.availableData
//            print(data)
        }

        task.waitUntilExit()
        let status = task.terminationStatus

        for arg in args {
            do {
                try log(arg)
            }catch {
                //                errorLabel.stringValue = "Unable to write to the log file"
            }
        }

        if output.count > 0 {
            try? log("output")
            for out in output {
                do {

                    try log(out)
                }catch {
                    //                errorLabel.stringValue = "Unable to write to the log file"
                }
            }
        }

        if error.count > 0 {
            for err in error where err.count > 0 {
                do {
                    try log(err)
                }catch {
                    //                errorLabel.stringValue = "Unable to write to the log file"
                }
            }
        }

        do {
            try log("exitCode: \(status)")
        }catch {
            //                errorLabel.stringValue = "Unable to write to the log file"
        }

        return (output, error, status)
    }

    func log(_ logString: String) throws {

        let file = "log.txt"

        guard let savePath = self.saveLocation else {
            throw BuildError.noLogFilePath
        }

        let fileURL = savePath.appendingPathComponent(file)

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }

        if let fileUpdater = try? FileHandle(forWritingTo: fileURL) {

            fileUpdater.seekToEndOfFile()

            fileUpdater.write(logString.data(using: .utf8)!)
            fileUpdater.write("\n\n".data(using: .utf8)!)

            fileUpdater.closeFile()
        }
    }

    func shell(_ command: String) -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        return output

    }

    func say(_ words: String) {
        //        var _ = runCommand(cmd: "/usr/bin/say", args: [words])
//        print(words)
    }
}
