//
//  main.swift
//  iPhoneMirroringPatcher
//
//  Created by Théo De Roy on 26/07/2024.
//

import Foundation
import SIPExamine
import AppKit

if isSIPenabled() {
    let alert = NSAlert()
    alert.messageText = "System Integrity Protection is enabled"
    alert.informativeText = "iPhone Mirroring Patcher will not work with System Integrity Protection enabled. Please disable System Integrity Protection by booting into Recovery Mode, turning off SIP, and rebooting."
    alert.alertStyle = .critical
    alert.addButton(withTitle: "Quit")
    alert.runModal()
} else {
    let filePath = "/private/var/db/os_eligibility/eligibility.plist"
    let backupPath = "\(filePath).bak"

    @discardableResult
    func runCommand(_ command: String, arguments: [String] = []) -> Int32 {
        let process = Process()
        process.launchPath = command
        process.arguments = arguments
        process.launch()
        process.waitUntilExit()
        return process.terminationStatus
    }

    if getuid() != 0 {
        print("This tool requires administrator permissions. Please run as root or with sudo.")
        exit(1)
    }

    let fileManager = FileManager.default

    if fileManager.fileExists(atPath: backupPath) {
        do {
            try fileManager.removeItem(atPath: backupPath)
            print("Existing backup removed.")
        } catch {
            print("Failed to remove existing backup: \(error)")
            exit(1)
        }
    }

    do {
        try fileManager.copyItem(atPath: filePath, toPath: backupPath)
        print("Backup created successfully.")
    } catch {
        print("Failed to create backup: \(error)")
        exit(1)
    }

    guard let fileContent = try? String(contentsOfFile: filePath) else {
        print("Failed to read the file.")
        exit(1)
    }

    let pattern = """
    <key>OS_ELIGIBILITY_DOMAIN_IRON</key>\\s*<dict>\\s*<key>os_eligibility_answer_source_t</key>\\s*<integer>1</integer>\\s*<key>os_eligibility_answer_t</key>\\s*<integer>2</integer>\\s*<key>status</key>\\s*<dict>\\s*<key>OS_ELIGIBILITY_INPUT_COUNTRY_BILLING</key>\\s*<integer>2</integer>\\s*<key>OS_ELIGIBILITY_INPUT_COUNTRY_LOCATION</key>\\s*<integer>2</integer>\\s*<key>OS_ELIGIBILITY_INPUT_DEVICE_CLASS</key>\\s*<integer>3</integer>\\s*</dict>\\s*</dict>
    """

    let replacement = """
    <key>OS_ELIGIBILITY_DOMAIN_IRON</key>\n\t<dict>\n\t\t<key>os_eligibility_answer_source_t</key>\n\t\t<integer>1</integer>\n\t\t<key>os_eligibility_answer_t</key>\n\t\t<integer>4</integer>\n\t\t<key>status</key>\n\t\t<dict>\n\t\t\t<key>OS_ELIGIBILITY_INPUT_COUNTRY_BILLING</key>\n\t\t\t<integer>3</integer>\n\t\t\t<key>OS_ELIGIBILITY_INPUT_COUNTRY_LOCATION</key>\n\t\t\t<integer>3</integer>\n\t\t\t<key>OS_ELIGIBILITY_INPUT_DEVICE_CLASS</key>\n\t\t\t<integer>3</integer>\n\t\t</dict>\n\t</dict>
    """

    do {
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(location: 0, length: fileContent.utf16.count)
        let newContent = regex.stringByReplacingMatches(in: fileContent, options: [], range: range, withTemplate: replacement)
        
        try newContent.write(toFile: filePath, atomically: true, encoding: .utf8)
        print("File updated successfully.")
    } catch {
        print("Failed to perform replacement: \(error)")
        exit(1)
    }

    do {
        let updatedContent = try String(contentsOfFile: filePath)
        if updatedContent.contains("<integer>4</integer>") {
            print("Replacement successful.")
            
            // Open the app with the bundle ID com.apple.ScreenContinuity
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ScreenContinuity") {
                NSWorkspace.shared.open(url)
                print("Opened com.apple.ScreenContinuity.")
            } else {
                print("Failed to find app with bundle ID com.apple.ScreenContinuity.")
            }
        } else {
            print("Replacement failed.")
        }
    } catch {
        print("Failed to read the updated file: \(error)")
        exit(1)
    }
}
