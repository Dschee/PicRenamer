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
    @IBOutlet weak var renameButton: NSButton?
    @IBOutlet weak var progressIndicator: NSProgressIndicator?
    @IBOutlet weak var imagesCountLabel: NSTextField?
    var fileURLGroups = Array<FileURLGroup>()
    
    func updateUI(){
        self.table.reloadData()
        self.updateImagesCount()
        self.table.setNeedsDisplay()
    }

    func updateImagesCount() {
        self.imagesCountLabel?.stringValue = "\(self.table.numberOfRows) images"
    }
    
    @IBAction func openFiles(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = NSImage.imageTypes()
        openPanel.allowsMultipleSelection = true
        
        if let window = NSApplication.shared().windows.first {
            openPanel.beginSheetModal(for: window, completionHandler: { (result: Int) -> Void in

                if result == NSModalResponseOK {

                    self.renameButton?.isEnabled = false
                    self.progressIndicator?.isHidden = false
                    self.progressIndicator?.startAnimation(nil)
                    self.imagesCountLabel?.isHidden = false

                    DispatchQueue.global(qos: .userInteractive).async {

                        for (i, URL) in openPanel.urls.enumerated() {

                            let imageData = NSData(contentsOf: URL as URL)
                            let imageSource = CGImageSourceCreateWithData(CFBridgingRetain(imageData) as! CFData, nil)
                            let metaDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil) as! NSDictionary
                            guard let exifData = metaDictionary["{Exif}"] as? NSDictionary else {
                                continue
                            }

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

                            if i % 5 == 0 {
                                DispatchQueue.main.async {
                                    self.updateUI()
                                }
                            }
                            
                        }

                        DispatchQueue.main.async {
                            self.updateUI()
                            self.renameButton?.isEnabled = true
                            self.progressIndicator?.isHidden = true
                            self.progressIndicator?.stopAnimation(nil)
                        }

                    }

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
        self.imagesCountLabel?.isHidden = true
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
