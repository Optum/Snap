//
//  AppDelegate.swift
//  Snap
//
//  Created by Scott, Christopher A on 10/20/19.
//  Copyright © 2019 Scott, Christopher A. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func createEntitlemets(_ sender: Any) {

    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
