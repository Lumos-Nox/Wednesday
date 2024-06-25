//
//  WednesdayApp.swift
//  Wednesday
//
//  Created by Ai Su on 6/22/24.
//

//import Cocoa
import SwiftUI

@main
struct SOCKSTogglerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set the initial button title
        updateStatusItemTitle()
        
        // Set the button title or image
        if let button = statusItem.button {
            button.action = #selector(toggleSOCKSProxy)
            button.target = self
//            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
//            
//            // Add contextual menu
//            let menu = NSMenu()
//            menu.addItem(withTitle: "Toggle", action: #selector(toggleSOCKSProxy), keyEquivalent: "t")
//            menu.addItem(withTitle: "Quit", action: #selector(quitAction(_:)), keyEquivalent: "q")
//            
//            statusItem.menu = menu
        }
    }
    
    @objc func toggleSOCKSProxy() {
        DispatchQueue.global(qos: .background).async {
            let currentStatus = self.getCurrentSOCKSProxyStatus()
            if currentStatus {
                self.disableSOCKSProxy()
            } else {
                self.enableSOCKSProxy()
            }
            DispatchQueue.main.async {
                self.updateStatusItemTitle()
            }
        }
    }
    
    @objc func quitAction(_ sender: Any?) {
        NSApplication.shared.terminate(self)
    }
    
    func updateStatusItemTitle() {
        let currentStatus = getCurrentSOCKSProxyStatus()
        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                let imageName = currentStatus ? "party.popper.fill" : "party.popper"
                button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "Menubar Icon")
            }
        }
    }
    
    func getCurrentSOCKSProxyStatus() -> Bool {
        // Get the current SOCKS proxy status
        let script = "networksetup -getsocksfirewallproxy Wi-Fi"
        let output = shell(script)
        return output.contains("Yes")
    }
    
    func enableSOCKSProxy() {
        let script = """
        do shell script "sudo networksetup -setsocksfirewallproxystate Wi-Fi on"
        """
        runAppleScript(script)
        print("SOCKS Proxy enabled")
    }
    
    func disableSOCKSProxy() {
        let script = """
        do shell script "sudo networksetup -setsocksfirewallproxystate Wi-Fi off"
        """
        runAppleScript(script)
        print("SOCKS Proxy disabled")
    }
    
    @discardableResult
    func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
    
    @discardableResult
    func runAppleScript(_ script: String) -> (output: String, error: String) {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript Error: \(error)")
                return ("", error.description)
            } else {
                return (output.stringValue ?? "", "")
            }
        }
        return ("", "Failed to create AppleScript object")
    }
}
