//
//  ViewController.swift
//  PicRenamer
//
//  Created by Peng Jingwen on 2015-02-26.
//  Copyright (c) 2015 PrettyX. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTabViewDelegate {

    class FileURLGroup {
        var oldFileURL: URL
        var newFileURL: URL
        
        init(oldFileURL: URL, newFileURL: URL) {
            self.oldFileURL = oldFileURL
            self.newFileURL = newFileURL
        }
    }
    
    @IBOutlet weak var table: NSTableView!
    var fileURLGroups = Array<FileURLGroup>()
    
    func updateUI(){
        self.table.reloadData()
        self.table.setNeedsDisplay()
    }
    
    @IBAction func openFiles(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = NSImage.imageTypes()
        openPanel.allowsMultipleSelection = true
        
        if let window = NSApplication.shared().windows.first {
            openPanel.beginSheetModal(for: window, completionHandler: { (result: Int) -> Void in

                if result == NSModalResponseOK {
                    
                    for URL in openPanel.urls {
        
                        let imageData = NSData(contentsOf: URL as URL)
                        let imageSource = CGImageSourceCreateWithData(CFBridgingRetain(imageData) as! CFData, nil)
                        let metaDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil) as! NSDictionary
                        let exifData = metaDictionary["{Exif}"] as! NSDictionary

                        if let dateStringCapture = exifData["DateTimeDigitized"] as? String ?? exifData["DateTimeOriginal"] as? String {

                            let components = dateStringCapture.components(separatedBy: " ")

                            let folderPart = components[0].replacingOccurrences(of: ":", with: "/")
                            let fileNameToSecond = components[1].replacingOccurrences(of: ":", with: "_")

                            if let milliSecondsString = exifData["SubsecTimeDigitized"] as? String ?? exifData["SubsecTimeOriginal"] as? String, let milliSeconds = Int(milliSecondsString) {

                                let newFileName = folderPart + "/" + fileNameToSecond + String(format: "_%03d", milliSeconds)

                                let fileURL = FileURLGroup(
                                    oldFileURL: URL as URL,
                                    newFileURL:
                                    URL.deletingLastPathComponent()
                                        .appendingPathComponent(newFileName)
                                        .appendingPathExtension(URL.pathExtension)
                                )

                                self.fileURLGroups.append(fileURL)

                            }

                        }
                    }
                    
                    self.updateUI()
                }
            })
        }
    }
    
    @IBAction func renameFiles(_ sender: NSButton) {
        let fileManager = FileManager.default
        
        for group in self.fileURLGroups {

            let folderUrl = group.newFileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: folderUrl.absoluteString.substring(from: "file://".endIndex)) {
                try! fileManager.createDirectory(at: folderUrl, withIntermediateDirectories: true)
            }

            if !fileManager.fileExists(atPath: group.newFileURL.absoluteString.substring(from: "file://".endIndex)) {
                try! fileManager.moveItem(at: group.oldFileURL, to: group.newFileURL)
                group.oldFileURL = group.newFileURL
            }
        }
        
        self.updateUI()
    }
    
    @IBAction func clearFiles(_ sender: NSButton) {
        self.fileURLGroups.removeAll(keepingCapacity: false)
        self.updateUI()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.fileURLGroups.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn?.identifier == "Before" {
            return self.fileURLGroups[row].oldFileURL.lastPathComponent
        } else if tableColumn?.identifier == "After" {
            return self.fileURLGroups[row].newFileURL.lastPathComponent
        } else {
            return nil
        }
    }
    
}
