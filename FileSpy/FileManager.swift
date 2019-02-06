//
//  FileManager.swift
//  FileSpy
//
//  Created by Duane Tucker on 2/2/19.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation
import AppKit
import Cocoa

class PhotoFileManager {
    
    var srcFileList: [URL] = []
    var internalDestFileList: [URL] = []
   // var masterDestFileList: [URL] = []
    var masterDestFileList: [String] = []

    var showInvisibles = false
    var ignoreCase = false
    var nCharsEnabled = false
    var nCharsValue = 3
    var recurseDirs = false
    //var hideNonDups = false;
    
    init () {
    }
    
    // This function is called when the user clicks the Search button
    func startSearch(folder: URL, completion: @escaping ([URL]) -> ()) {
        // Start with an empty destination list.
        self.internalDestFileList.removeAll()
        
        // go get all files
        fillMasterDestList(folder: folder)

        //for fileUrl:URL in self.masterDestFileList {
        for fileUrl:String in self.masterDestFileList {
            let fileUrl = URL(fileURLWithPath: fileUrl)

            if (self.isMatchingSrcFileList(file: fileUrl)) {
                self.internalDestFileList.append(fileUrl)
            }
        }
        
        // done with masterlist; empty it to preserve memory
        self.masterDestFileList.removeAll()

        DispatchQueue.main.async {
            completion(self.internalDestFileList)
        }
    }
    
    // This function is called to load the source folder
    // list with all file URLs in the source folder
    func fillSourceList(folder: URL, completion: @escaping ([URL]) -> ()) {
        DispatchQueue.global(qos: .userInteractive).async {
            // Start with an empty list.
            self.srcFileList.removeAll()
            self.srcFileList = self.getFolderContents(folder: folder)
            DispatchQueue.main.async {
                completion(self.srcFileList)
            }
        }
    }
    


    // Given a file that was selected in the left table, return back a list
    // of file urls from the internal matching list. The returned list will then
    // get displayed in the right table.
    func getMatchingFileList(file: URL, completion: @escaping ([URL]) -> ())  {
        let src = file.lastPathComponent
        
        DispatchQueue.global(qos: .userInteractive).async {
            var fileList: [URL] = []

            print ("entering getMatchingFileList for file \(file)")
            
            for destFileURL:URL in self.internalDestFileList {
                let dst = destFileURL.lastPathComponent
                print("commparing \(src) to \(dst)")
                
                //NOTE: I think this comparison should only be done in the fillInternalMatchingList function
                // That way, the only files in the internal list would have already been verified to match.
                // This function could simply compare the filename components to determine the list to return.
//                if (self.compareFiles(src: src, dst: dst)) {
//                    fileList.append(destFileURL)
//                }
                
                if (src == dst) {
                    print("adding \(destFileURL)")

                    fileList.append(destFileURL)
                }
            }
            
            DispatchQueue.main.async {
                print ("calling completion method for getMatchingFileList")
                completion(fileList)
            }
            
        }
    }
    
    func infoAbout(url: URL, completion: @escaping (NSAttributedString?) -> ())  {
        let fileMgr = FileManager.default
        var retStr: NSAttributedString? = nil
        
        do {
            let attributes = try fileMgr.attributesOfItem(atPath: url.path)
            var report: [String] = ["\(url.path)", ""]
            
            for (key, value) in attributes {
                // ignore NSFileExtendedAttributes as it is a messy dictionary
                if key.rawValue == "NSFileExtendedAttributes" { continue }
                report.append("\(key.rawValue):\t \(value)")
            }
            let infoString = report.joined(separator: "\n")
            if !infoString.isEmpty {
                retStr = formatInfoText(infoString)
            }
        } catch {
            retStr = nil
        }
        
        completion(retStr)
    }
    
    // This function is called to obtain and return a list of URLs representing
    // the files within the specified folder name.
    fileprivate func getFolderContents(folder: URL) -> [URL] {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
            //print ("first char = \(folder.path.prefix(1))")
            //    .filter { return showInvisibles ? true : $0.characters.first != "." }
            
            let urls = contents
                .filter { return showInvisibles ? true : $0.prefix(1) != "." }
                .map { return folder.appendingPathComponent($0) }
            return urls
        } catch {
            return []
        }
    }
    
    // The recursion checkbox is used to determine if subdirectories should be explored.
    fileprivate func fillMasterDestList(folder: URL) {
        // Start with an empty destination list.
        masterDestFileList.removeAll()
        
        if (recurseDirs) {
            addFolderContents(folder: folder)
        } else {  // do not recurse; ignore subfolders
            let searchFolderContents: [URL] = getFolderContents(folder: folder)
            for fileUrl:URL in searchFolderContents {
                //masterDestFileList.append(fileUrl)
                masterDestFileList.append(fileUrl.absoluteString)
            }
        }
    }
    
    fileprivate func addFolderContents(folder: URL) {
        var files: [URL] = getFolderContents(folder: folder)
        
        while (files.count > 0) {
            if (files[0].hasDirectoryPath) {
                // we've found a directory. Get it's contents and add them to the
                // end of master list; they'll be searched later.
                addFolderContents(folder: files[0])
                files.remove(at: 0) // Remove this directory from the search list
            } else {
                // Not a directory so add it to the dest list.
                masterDestFileList.append(files[0].absoluteString)
                //masterDestFileList.append(files[0])
                
                // Remove this file from the list of remaining files/dirs to check
                files.remove(at: 0)
            }
        }
    }
    
    
    // Given a folder name found while searching through search folders, return back a list
    // of file urls from the folder that match files in the source foler.
    fileprivate func getMatchingSrcFileList(folderNm: URL) -> [URL] {
        var fileList: [URL] = []
        let folderContents: [URL] = getFolderContents(folder: folderNm)
        
        for destFileURL:URL in folderContents {
            //print("commparing \(src) to \(dst)")
            if (isMatchingSrcFileList(file: destFileURL)) {
                //print("FOUND \(dst)")
                fileList.append(destFileURL)
            }
        }
        
        return fileList
    }
    
    // Given a folder name found while searching through search folders, return back a list
    // of file urls from the folder that match files in the source foler.
    fileprivate func isMatchingSrcFileList(file: URL)  -> Bool {
        var matches: Bool = false
        let dst = file.lastPathComponent
        let dstPath = file.deletingLastPathComponent()
        
        for srcFileURL:URL in srcFileList {
            let src = srcFileURL.lastPathComponent
            let srcPath = srcFileURL.deletingLastPathComponent()
            
            // make sure we're not comparing the same file in the same directory
            if (srcPath != dstPath) {
                //print("looking up dups for \(src)")
                
                if (compareFiles(src: src, dst: dst)) {
                    //print("FOUND \(dst)")
                    matches = true
                    break
                }
            }
        }
        
        return matches
    }
    
    fileprivate func compareFiles(src: String, dst: String) -> Bool {
        var ret: Bool = false
        
        if (nCharsEnabled) {
            // test only n number of characters in the name
            
            if (ignoreCase) {
                if (src.prefix(Int(nCharsValue)).caseInsensitiveCompare(dst.prefix(Int(nCharsValue))) == .orderedSame){
                    ret = true
                }
            } else {
                if (src.prefix(Int(nCharsValue)) == dst.prefix(Int(nCharsValue))) {
                    ret = true
                }
            }
        } else {
            // test the entire name
            
            if (ignoreCase) {
                if (src.caseInsensitiveCompare(dst) == .orderedSame){
                    ret = true
                }
            } else {
                if (src == dst) {
                    ret = true
                }
            }
        }
        
        return ret
    }
    
    fileprivate func formatInfoText(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.minimumLineHeight = 24
        paragraphStyle?.alignment = .left
        paragraphStyle?.tabStops = [ NSTextTab(type: .leftTabStopType, location: 240) ]
        
//        let textAttributes: [String: Any] = [
//            convertFromNSAttributedStringKey(NSAttributedString.Key.font): NSFont.systemFont(ofSize: 14),
//            convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyle ?? NSParagraphStyle.default
//        ]
        
        let textAttributes: [String: Any] = [
            NSAttributedString.Key.font.rawValue: NSFont.systemFont(ofSize: 14),
            NSAttributedString.Key.paragraphStyle.rawValue: paragraphStyle ?? NSParagraphStyle.default
        ]
        let formattedText = NSAttributedString(string: text, attributes: convertToOptionalNSAttributedStringKeyDictionary(textAttributes))
        return formattedText
    }
    
    // Helper function inserted by Swift 4.2 migrator.
//    func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
//        return input.rawValue
//    }
    
    // Helper function inserted by Swift 4.2 migrator.
    func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
        guard let input = input else { return nil }
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
    }
}
