//
//  CmdLine.swift
//  Snap
//
//  Created by Scott, Christopher A on 5/17/20.
//  Copyright © 2020 Scott, Christopher A. All rights reserved.
//

import Foundation

class CmdLine {

    var saveLocation: URL?

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

            //            fileUpdater.seekToEndOfFile()

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
