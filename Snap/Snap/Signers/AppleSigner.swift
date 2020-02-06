//
//  AppleSigner.swift
//  Snap
//
//  Created by Scott, Christopher A on 11/2/19.
//  Copyright © 2019 Scott, Christopher A. All rights reserved.
//

import Foundation
import Cocoa

enum BuildError: Error {
    case entitlements
    case mobileProvisionFile
    case exportoptions
    case embeddingMobileProvision
    case updateInfoPlist
    case removingCodeSigning
    case codeSigning
    case exporting
    case bundleid
    case signingIdentities
    case loggingError
    case noLogFilePath
    case canNotListApps
    case canNotReadMobileProvisionFile
    case canNotUnzipIPA
    case canNotzipIPA
    case canNotRemoveArcs
    case canNotAddAssociatedDomains

}

struct AppleSigner {

    var ipaName: String?
    var saveLocation: URL?
    var pathToApp: URL?
    var pathToIPABuildDir: URL?
    var pathToArchive: URL?  {
        didSet {
            saveLocation = pathToArchive?.deletingLastPathComponent()
            pathToApp = URL(fileURLWithPath: (pathToArchive?.path ?? "") + "/Products/Applications/")

            pathToMobileProvisionForArchive = nil
            bundleID = nil
            buildNumber = nil

            pathToEntitlementsPlist = self.saveLocation
            pathToEntitlementsPlist?.appendPathComponent("entitlements.plist")
            pathToOriginalEntitlementsPlist = self.saveLocation
            pathToOriginalEntitlementsPlist?.appendPathComponent("entitlements.plist")

            pathToExportOptionsForArchive = self.saveLocation
            pathToExportOptionsForArchive?.appendPathComponent("originalEntitlements.plist")

            userProvidedExportOptions = false
            userProvidedEntitlements = false
            userProvidedBundleID = false
            userProvidedBuildNumber = false
        }
    }

    var pathToIPA: URL?  {
        didSet {
            saveLocation = pathToIPA?.deletingLastPathComponent()

            pathToIPABuildDir = URL(fileURLWithPath: (saveLocation?.path ?? "") + "/resigningBuild/")
            pathToApp = URL(fileURLWithPath: (pathToIPABuildDir?.path ?? "") + "/Payload/")

            pathToMobileProvisionForArchive = nil
            bundleID = nil
            buildNumber = nil

            pathToEntitlementsPlist = self.saveLocation
            pathToEntitlementsPlist?.appendPathComponent("entitlements.plist")
            pathToOriginalEntitlementsPlist = self.saveLocation
            pathToOriginalEntitlementsPlist?.appendPathComponent("originalEntitlements.plist")

            userProvidedExportOptions = false
            userProvidedEntitlements = false
            userProvidedBundleID = false
            userProvidedBuildNumber = false
        }
    }

    var pathToMobileProvisionForArchive: URL?
    var pathToEntitlementsPlist: URL?
    var pathToOriginalEntitlementsPlist: URL?
    var pathToExportOptionsForArchive: URL?

    var signingIdentity: String?
    var mobileProvisionPlistData: [String: AnyObject] = [:]

    var bundleID: String?
    var buildNumber: String?

    var userProvidedBundleID = false
    var userProvidedExportOptions = false
    var userProvidedEntitlements = false
    var userProvidedBuildNumber = false
    var isEnterpriseRelease = false

    var delete = [String]()

    mutating func setPathToApp(_ pathExt: String) {
            self.pathToApp = pathToApp?.appendingPathComponent(pathExt)

        let appName = URL(fileURLWithPath: pathExt)
        ipaName = appName.deletingPathExtension().lastPathComponent
    }

    func getSigningIdentities(_ signingIdentityPopUp: NSPopUpButton ) throws {

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "security find-identity -vp codesigning"])

        guard response.exitCode == 0 else {
            signingIdentityPopUp.isEnabled = false
            throw BuildError.signingIdentities
        }

        for entry in response.output {

            let pattern = "\"(.*?)\""

            if let range = entry.range(of: pattern, options: .regularExpression) {
                print("\(entry[range])")
                signingIdentityPopUp.addItem(withTitle: "\(entry[range])")
            }
        }
    }

    //    MARK: - Xcarchive Signing

    func exportIPA() throws {

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "xcodebuild -exportArchive -archivePath \'\(pathToArchive?.path ?? "")\' -exportPath \'\(self.saveLocation?.path ?? "")\' -exportOptionsPlist \'\(self.pathToExportOptionsForArchive?.path ?? "")\'"])

        guard response.exitCode == 0 else {
            throw BuildError.exporting
        }

        let _ = runCommand(cmd: "/bin/sh", args: ["-c", "open \'\(self.saveLocation?.path ?? "")\'"])

    }

    mutating func getBundleId () throws {

        if !userProvidedBundleID, let applicationIdentifier = mobileProvisionPlistData["Entitlements"]?["application-identifier"] as? String {
            let regex = try! NSRegularExpression(pattern: "(^[A-Z0-9]*).", options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, applicationIdentifier.count)
            let modString = regex.stringByReplacingMatches(in: applicationIdentifier, options: [], range: range, withTemplate: "")

            bundleID = modString
        }

        guard let bundleid = bundleID, !bundleid.isEmpty else {
            throw BuildError.bundleid
        }

    }

    mutating func creatExportOPtionsPlist () throws {

        if !userProvidedBundleID, let applicationIdentifier = mobileProvisionPlistData["Entitlements"]?["application-identifier"] as? String {
            let regex = try! NSRegularExpression(pattern: "(^[A-Z0-9]*).", options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, applicationIdentifier.count)
            let modString = regex.stringByReplacingMatches(in: applicationIdentifier, options: [], range: range, withTemplate: "")

            bundleID = modString
        }

        guard let bundleid = bundleID, !bundleid.isEmpty else {
            throw BuildError.bundleid
        }

        if !userProvidedExportOptions {

            pathToExportOptionsForArchive = self.saveLocation
            pathToExportOptionsForArchive?.appendPathComponent("exportOptions.plist")

            var exportOptionsPlistData: [String : Any] = [:]

            if let teamId = mobileProvisionPlistData["TeamIdentifier"]?.firstObject {
                exportOptionsPlistData["teamID"] = teamId
            } else {
                throw BuildError.exportoptions
            }

            exportOptionsPlistData["generateAppStoreInformation"] = false
            exportOptionsPlistData["method"] = "app-store"
            exportOptionsPlistData["signingCertificate"] = signingIdentity?.replacingOccurrences(of: "\"", with: "")
            exportOptionsPlistData["signingStyle"] = "manual"
            exportOptionsPlistData["stripSwiftSymbols"] = true

            exportOptionsPlistData["uploadBitcode"] = true
            exportOptionsPlistData["uploadSymbols"] = true

            if let UUID = mobileProvisionPlistData["UUID"] {
                exportOptionsPlistData["provisioningProfiles"] = [bundleID:UUID]
            }

            let plistContent = NSDictionary(dictionary: exportOptionsPlistData)
            let success:Bool = plistContent.write(to: pathToExportOptionsForArchive!, atomically: true)

            if !success {
                throw BuildError.exportoptions
            }
        }
    }

    //    MARK: - Shared signing functions

    func copyAssociatedDomains() throws {

        guard let originalPath = pathToOriginalEntitlementsPlist else { return }

            var originalEntitlementsPlist: [String: AnyObject] = [:]

            originalEntitlementsPlist = NSDictionary(contentsOf: originalPath) as! [String : AnyObject]

            if let associatedDomains = originalEntitlementsPlist["com.apple.developer.associated-domains"] as? Array<Any> {
                if associatedDomains.count > 0 {

                    guard let entitlementsPath = pathToEntitlementsPlist else { return }

                    var entitlementsPlist: [String: AnyObject] = [:]

                    entitlementsPlist = NSDictionary(contentsOf: entitlementsPath) as! [String : AnyObject]

                    entitlementsPlist["com.apple.developer.associated-domains"] = associatedDomains as AnyObject

                    let plistContent = NSDictionary(dictionary: entitlementsPlist)
                    let success:Bool = plistContent.write(to: entitlementsPath, atomically: true)

                    if !success {
                        throw BuildError.canNotAddAssociatedDomains
                    }
                }
            }
    }

    func reCodeSigning() throws {

        let _ = runCommand(cmd: "/bin/sh", args: ["-c", "codesign -f -s \(signingIdentity ?? "") \(self.pathToApp?.path.replacingOccurrences(of: " ", with: "\\ ") ?? "")/Frameworks/*"])

        let _ = runCommand(cmd: "/bin/sh", args: ["-c", "codesign -f -s \(signingIdentity ?? "") --entitlements \(self.pathToEntitlementsPlist?.path.replacingOccurrences(of: " ", with: "\\ ") ?? "") \(self.pathToApp?.path.replacingOccurrences(of: " ", with: "\\ ") ?? "")"])

    }

    func removeCodeSigning() throws {

        let _ = runCommand(cmd: "/bin/sh", args: ["-c", "rm -rf \(self.pathToApp?.path.replacingOccurrences(of: " ", with: "\\ ") ?? "")/Frameworks/*/_CodeSignature"])
        let _ = runCommand(cmd: "/bin/sh", args: ["-c", "rm -rf \(self.pathToApp?.path.replacingOccurrences(of: " ", with: "\\ ") ?? "")/_CodeSignature"])
    }

    func removeCodesignatures() throws {

        guard let dirPath = pathToIPABuildDir?.path else {
            throw BuildError.removingCodeSigning
        }

        let _ = shell("find \'\(dirPath)\' -type d -name _CodeSignature -exec rm -rf {} \\;")

        try? log("Deleted ._CodeSignature files from \(dirPath) directory and subdirectories.\n")

    }


    func removeArchitectures() throws {

        guard let dirPath = pathToIPABuildDir?.path else {
            throw BuildError.canNotRemoveArcs
        }
        let fileSystem = FileManager.default

        // Enumerate the directory tree (which likely recurses internally)...

        if let fsTree = fileSystem.enumerator(atPath: dirPath) {

            while let fsNodeName = fsTree.nextObject() as? NSString {

                let fullPath = "\(dirPath)/\(fsNodeName)"

                var isDir: ObjCBool = false
                fileSystem.fileExists(atPath: fullPath, isDirectory: &isDir)

                if !isDir.boolValue && fsNodeName.pathExtension == "dylib" {

                    try? log(fsNodeName as String)
                    let filePath = "\(dirPath)" + "/" + "\(fsNodeName)"
                    let lsOutput = shell("lipo -info \'\(filePath)\'")
                    try? log(lsOutput)

                    if lsOutput.contains("arm64e") {
                        let lsOutput1 = shell("lipo \'\(filePath)\' -remove arm64e -output \'\(filePath)\'")
                        try? log(lsOutput1)
                        let lsOutput2 = shell("lipo -info \'\(filePath)\'")
                        try? log("Cleaned --> \(lsOutput2)")
                    }

                }

            }

            let _ = shell("find '\(dirPath)' -name .DS_Store -delete")

            try? log("Deleted .DS_Store files from \(dirPath) directory and subdirectories.\n")
        }
    }

    func updateInfoPlist() throws {


        guard let pathToPlist = self.pathToApp?.appendingPathComponent("info.plist") else { return }

        var customDict = NSDictionary(contentsOf: pathToPlist) as? [String : Any]

        guard customDict?["CFBundleIdentifier"] != nil else {
            throw BuildError.updateInfoPlist
        }

        customDict?["CFBundleIdentifier"] = self.bundleID ?? ""

        if userProvidedBuildNumber {
            customDict?["CFBundleVersion"] = self.buildNumber ?? ""
        }

        NSDictionary(dictionary: customDict!).write(to: pathToPlist, atomically: true)
    }

    func replaceEmbeddedProvisionFile () throws {

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "cp \'\(self.pathToMobileProvisionForArchive?.path ?? "")\' \'\(self.pathToApp?.path ?? "")/embedded.mobileprovision\'"])

        guard response.exitCode == 0 else {
            throw BuildError.embeddingMobileProvision
        }
    }

    mutating func createMobileProvisioningPlistFileAndCopyEntitlements () throws {

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "security cms -D -i \'\(pathToMobileProvisionForArchive?.path ?? "")\'"])

        guard response.exitCode == 0 else {
            throw BuildError.canNotReadMobileProvisionFile
        }

        let file = "mp.plist"

        guard let savePath = self.saveLocation else {
            throw BuildError.mobileProvisionFile
        }

        let fileURL = savePath.appendingPathComponent(file)

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }

        if let fileUpdater = try? FileHandle(forWritingTo: fileURL) {

            fileUpdater.seekToEndOfFile()
            for entry in response.output {
                fileUpdater.write(entry.data(using: .utf8)!)
            }
            fileUpdater.closeFile()
        }

        mobileProvisionPlistData = NSDictionary(contentsOf: fileURL) as! [String : AnyObject]

        if pathToEntitlementsPlist == nil {
            guard let entitlements = mobileProvisionPlistData["Entitlements"] as? [String: AnyObject] else {
                throw BuildError.mobileProvisionFile
            }

            pathToEntitlementsPlist = self.saveLocation
            pathToEntitlementsPlist?.appendPathComponent("entitlements.plist")

            NSDictionary(dictionary: entitlements).write(to: pathToEntitlementsPlist!, atomically: true)
        }

        try? copyAssociatedDomains()
    }

    mutating func retrieveEntitlements() throws {

        let responseLs = runCommand(cmd: "/bin/sh", args: ["-c", "ls \'\(pathToApp?.path ?? "")\'"])

        guard responseLs.exitCode == 0 else {
            throw BuildError.canNotListApps
        }

        for entry in responseLs.output {

            let pattern = "(.*?).app"

            if let range = entry.range(of: pattern, options: .regularExpression) {
                print("\(entry[range])")
                setPathToApp(entry)
            }
        }

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "codesign -d --entitlements :- \'\(pathToApp?.path ?? "")\' > \'\(pathToOriginalEntitlementsPlist?.path ?? "")\'"])

        guard response.exitCode == 0 else {
            throw BuildError.entitlements
        }
    }

    //    MARK: - IPA signing

    func zipIPA() throws {

        var name = "Resigned.ipa"
        let buildPath = (pathToIPABuildDir?.path.replacingOccurrences(of: " ", with: "\\ ") ?? "") + "/"

        if let filename = ipaName {
            name = filename + "_" + name
        }

        name = (saveLocation?.path.replacingOccurrences(of: " ", with: "\\ ") ?? "") + "/" + name.replacingOccurrences(of: " ", with: "\\ ")
        try? log(name)
        try? log(buildPath)

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "cd \(buildPath); zip -r \(name) ."])

        guard response.exitCode == 0 else {
            throw BuildError.canNotzipIPA
        }

        if pathToIPABuildDir?.path != nil {
            let _ = runCommand(cmd: "/bin/sh", args: ["-c", "rm -rf \'\(pathToIPABuildDir?.path ?? "")\'"])
        }

        let _ = runCommand(cmd: "/bin/sh", args: ["-c", "open \'\(self.saveLocation?.path ?? "")\'"])
    }

    func unzipIPA() throws {

        let _ = runCommand(cmd: "/bin/sh", args: ["-c", "rm -rf \'\(pathToIPABuildDir?.path ?? "")\'"])

        let response = runCommand(cmd: "/bin/sh", args: ["-c", "unzip -q \'\(pathToIPA?.path ?? "")\' -d \'\(pathToIPABuildDir?.path ?? "")\'"])

        guard response.exitCode == 0 else {
            throw BuildError.canNotUnzipIPA
        }
    }

    //    MARK: - Shell and Logging

    func runCommand(cmd : String, args : [String]) -> (output: [String], error: [String]?, exitCode: Int32) {

        var output : [String] = []
        var error : [String] = []

        let task = Process()
        task.launchPath = cmd
        task.arguments = args

        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe

        task.launch()

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
        print(words)
    }
}
