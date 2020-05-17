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

    let cmdLine = CmdLine()
    var apkName: String?
    var keystorePwd: String? {
           didSet {
            guard pathToAPK != nil else { return }
//               try? getAlias()
           }
       }

    var aliasPwd: String?
    var aliasName: String?

    var saveLocation: URL? {
           didSet {
               cmdLine.saveLocation = saveLocation
           }
       }
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
        let response = cmdLine.runCommand(cmd: "/bin/sh", args: ["-c", "keytool -v -list -keystore \'\(pathToKeyStore?.path ?? "")\' -storepass \'\(keystorePwd ?? "")\'"])

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

        let response = cmdLine.runCommand(cmd: "/bin/sh", args: ["-c", "zip -d \'\(pathToAPK?.path ?? "")\' META-INF/*"])

        guard response.exitCode == 0 || response.exitCode == 12 else {
            throw GoogleBuildError.canNotClearMetaData
        }

    }

    func zipalignApk() throws {

        let response = cmdLine.runCommand(cmd: "/bin/sh", args: ["-c", "\(pathToAppDir?.path ?? "")/contents/Resources/zipalign -f -v 4 \'\(pathToAPK?.path ?? "")\' \'\(saveLocation?.path ?? "")/aligned_\(apkName ?? "").apk\'"])

        guard response.exitCode == 0 else {
            throw GoogleBuildError.canNotAlignApk
        }
    }

    func signApk() throws {

//        ./apksigner sign --ks test.jks --ks-key-alias test --ks-pass pass:testtest --key-pass pass:testtest Test_Aligned.apk

        let response = cmdLine.runCommand(cmd: "/bin/sh", args: ["-c", "\(pathToAppDir?.path ?? "")/contents/Resources/apksigner sign --ks \'\(pathToKeyStore?.path ?? "")\' --ks-key-alias \(aliasName ?? "") --ks-pass pass:\(keystorePwd ?? "") --key-pass pass:\(aliasPwd ?? "") \'\(saveLocation?.path ?? "")/aligned_\(apkName ?? "").apk\'"])

        guard response.exitCode == 0 else {
            throw GoogleBuildError.canNotSignApk
        }
    }

    func jarsignApk() throws {

    //        .jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore your-release-key.keystore android-release-unsigned.apk alias -storepass password

            let response = cmdLine.runCommand(cmd: "/bin/sh", args: ["-c", "/usr/bin/jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore \'\(pathToKeyStore?.path ?? "")\' \'\(saveLocation?.path ?? "")/aligned_\(apkName ?? "").apk\' \(aliasName ?? "") -storepass \(keystorePwd ?? "")"])

            guard response.exitCode == 0 else {
                throw GoogleBuildError.canNotSignApk
            }
        }

    func finalZipalignApk() throws {

        let response = cmdLine.runCommand(cmd: "/bin/sh", args: ["-c", "\(pathToAppDir?.path ?? "")/contents/Resources/zipalign -f -v 4 \'\(saveLocation?.path ?? "")/aligned_\(apkName ?? "").apk\' \'\(saveLocation?.path ?? "")/aligned2_\(apkName ?? "").apk\'"])

        guard response.exitCode == 0 else {
            throw GoogleBuildError.canNotAlignApk
        }
    }

    func verifyApk() throws {

        let response = cmdLine.runCommand(cmd: "/bin/sh", args: ["-c", "\(pathToAppDir?.path ?? "")/contents/Resources/zipalign -p -f -v 4 \'\(saveLocation?.path ?? "")/aligned2_\(apkName ?? "").apk\' \'\(saveLocation?.path ?? "")/verified_aligned_\(apkName ?? "").apk\'"])

        guard response.exitCode == 0 else {
            throw GoogleBuildError.canNotVerifyApk
        }
    }

    func renameVerifiedApk() throws {

        let response = cmdLine.runCommand(cmd: "/bin/sh", args: ["-c", "mv \'\(saveLocation?.path ?? "")/aligned2_\(apkName ?? "").apk\' \'\(saveLocation?.path ?? "")/aligned_resigned_verified_\(apkName ?? "").apk\'"])

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
}
