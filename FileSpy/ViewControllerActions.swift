//
//  ViewControllerActions.swift
//  FileSpy
//
//  Created by Duane Tucker on 2/2/19.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Cocoa
import Quartz
import AppKit

// MARK: - Actions
extension ViewController {
    
    @IBAction func deleteSrcFile(_ sender: Any) {
        guard let selectedUrl = selectedItem else {
            return
        }
        let a: NSAlert = NSAlert()
        
        a.messageText = "Delete File?"
        a.informativeText = "Are you sure you want to delete \(selectedUrl)?"
        a.alertStyle = NSAlert.Style.warning
        a.addButton(withTitle: "Delete")
        a.addButton(withTitle: "Cancel")
        
        a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse: NSApplication.ModalResponse) -> Void in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                DispatchQueue.global(qos: .background).async {
                    let fileMgr = FileManager.default
                    do {
                        //try fileManager.removeItem(at: selectedUrl)
                        try fileMgr.trashItem(at: selectedUrl, resultingItemURL: nil)

                        //DispatchQueue.main.async { [unowned self] in
                            // now remove the file from the table.
                            var index = 0;
                            for fileUrl:URL in self.srcFileList {
                                if (fileUrl == selectedUrl) {
                                    self.srcFileList.remove(at: index)
                                    break
                                }
                                index += 1
                            }
                            self.selectedItem = nil
                            self.tableView.reloadData()
                            self.DeleteSrcBtn.isEnabled = false
                        self.srcTblListCountLbl.stringValue = "\(self.srcFileList.count)"
                        //}
                    }
                    catch let error as NSError {
                        print("Ooops! Something went wrong: \(error)")
                        self.showErrorDialogIn(title:"Major Malfunction", message:"Error occurred deleting \(selectedUrl)")
                    }
                    print("Document deleted")
                }
            }
        })
    }
    
    // This is the main search function, called when the user clicks the Search button
    @IBAction func startSearch(_ sender: Any) {
        print("Starting search for matches")
        self.startSearchBtn.isEnabled = false
        
        self.matchingFileList.removeAll()
        self.matchingFilesTableView.reloadData()
        
        print("getting internal list of all available matching files now...")
        if let searchFolder = selectDstFolder {
            self.internalDestFileList.removeAll()
            
            if (self.recurseDirs) {
                do {
                    //let fileMgr = FileManager.default
                    let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
                    //let documentsURL = try fileMgr.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let enumerator = FileManager.default.enumerator(at: searchFolder,
                                                                    includingPropertiesForKeys: resourceKeys,
                                                                    options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                        print("directoryEnumerator error at \(url): ", error)
                                                                        return true
                    })!
                    
                    for case let fileURL as URL in enumerator {
                        let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                        //print(fileURL.path, resourceValues.creationDate!, resourceValues.isDirectory!)
                        if (!fileURL.hasDirectoryPath) {
                            if (self.isMatchingSrcFileList(file: fileURL)) {
                                self.internalDestFileList.append(fileURL)
                            }
                        }
                    }
                    }catch {
                        print(error)
                    }
                
                getFolderContents(folder: searchFolder, completion: { (files: [URL]) in
//                    while (files.count > 0) {
//                        if (files[0].hasDirectoryPath) {
//                            // we've found a directory. Get it's contents and add them to the
//                            // end of master list; they'll be searched later.
//                            addFolderContents(folder: files[0])
//                            files.remove(at: 0) // Remove this directory from the search list
//                        } else {
//                            // Not a directory so add it to the dest list.
//                            //masterDestFileList.append(files[0].absoluteString)
//                            masterDestFileList.append(files[0])
//
//
//                            // Remove this file from the list of remaining files/dirs to check
//                            files.remove(at: 0)
//                        }
//                    }
                })
            } else {  // do not recurse; ignore subfolders
                getFolderContents(folder: searchFolder, completion: { (files: [URL]) in
                    for fileUrl:URL in files {
                        if (!fileUrl.hasDirectoryPath) {
                            if (self.isMatchingSrcFileList(file: fileUrl)) {
                                self.internalDestFileList.append(fileUrl)
                            }
                        }
                    }
                    let numMatches = self.internalDestFileList.count
                    self.numMatchesFoundLbl.stringValue = "\(numMatches) files found"
                })
            }
            
            
            self.startSearchBtn.isEnabled = true
            self.srcTblListCountLbl.stringValue = "\(srcFileList.count)"
            self.intDstListCountLbl.stringValue = "\(internalDestFileList.count)"

            //for fileUrl:URL in self.masterDestFileList {
            //for fileUrl:String in self.masterDestFileList {
                //let fileUrl = URL(fileURLWithPath: fileUrl)
            //}
        } else {
            print("something wrong with search folder")
        }
    }
//    @IBAction func old_startSearch(_ sender: Any) {
//        print("Starting search for matches")
//        self.startSearchBtn.isEnabled = false
//
//        self.matchingFileList.removeAll()
//        self.matchingFilesTableView.reloadData()
//
//        print("getting internal list of all available matching files now...")
//        if let searchFolder = selectDstFolder {
//
//            self.fileManager.startSearch(folder:
//                searchFolder, completion: { (files: [URL]) in
//                    let numMatching = files.count
//                    self.filesMatchingSearchLbl.stringValue = "\(numMatching) matching items located"
//                    if (numMatching == 0) {
//                        print("no results found")
//                        self.matchingFileList.removeAll()
//                        self.matchingFilesTableView.reloadData()
//                        self.filesMatchingSearchLbl.stringValue = "0 matching items found"
//                        self.showErrorDialogIn(title:"No Results", message:"No matches were found")
//                    }
//                    self.startSearchBtn.isEnabled = true
//            })
//        } else {
//            print("something wrong with search folder")
//        }
//    }

    @IBAction func ignoreCaseChanged(_ sender: Any) {
        if (ignoreCaseCheckbox.state == NSButton.StateValue.on) {
            self.ignoreCase = true
            print("ignoreCase turned on")
        } else {
            self.ignoreCase = false
            print("ignoreCase turned off")
        }
    }
    
    @IBAction func enableNcharsChanged(_ sender: Any) {
        if (Enable_n_chars.state == NSButton.StateValue.on) {
            self.nCharsEnabled = true
            print("nCharsEnabled turned on")
        } else {
            self.nCharsEnabled = false
            print("nCharsEnabled turned off")
        }
    }
    @IBAction func change_nCharsValue(_ sender: Any) {
        let numChars = nCharsSlider.intValue
        compare_nCharsLable.stringValue = "Compare at most \(numChars) characters"
        self.nCharsValue = Int(numChars)
        print("numchars to search set to \(numChars)")
    }

    @IBAction func hideNonDupes(_ sender: Any) {
//        if (hideNonDupChkbox.state == NSButton.StateValue.on) {
//            var newList: [URL] = []
//            selectedItem = nil
//
//            for fileUrl:URL in self.srcFileList {
//                if (fileManager.getMatchingFileList(file: fileUrl).count > 0) {
//                    newList.append(fileUrl)
//                }
//            }
//            self.srcFileList.removeAll()
//            self.srcFileList = newList
//            self.tableView.reloadData()
//        } else {
//            selectedItem = nil
//            self.srcFileList.removeAll()
//
//            self.srcFileList.append(contentsOf: SequencefileManager.srcFileList)
//            self.tableView.reloadData()
//       }
    }

    @IBAction func recurseCkbxChanged(_ sender: Any) {
        if (recurseCkbx.state == NSButton.StateValue.on) {
           self.recurseDirs = true
            print("recurseDirs turned on")
        } else {
            self.recurseDirs = false
            print("recurseDirs turned off")
        }
    }

    @IBAction func selectSrcFolderClicked(_ sender: Any) {
        guard let window = view.window else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModal(for: window) { (result) in
            if result.rawValue == NSFileHandlingPanelOKButton {
                self.selectSrcFolder = panel.urls[0]
            }
        }
    }
    
    @IBAction func selectSearchFolderClicked(_ sender: Any) {
        guard let window = view.window else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModal(for: window) { (result) in
            if result.rawValue == NSFileHandlingPanelOKButton {
                self.selectDstFolder = panel.urls[0]
            }
        }
    }

    @IBAction func tableViewDoubleClicked(_ sender: Any) {
        print("entering tableViewDoubleClicked; not finished to work with both tables!")
        if tableView.selectedRow < 0 { return }
        
        let selectedItem = srcFileList[tableView.selectedRow]
        if selectedItem.hasDirectoryPath {
            selectSrcFolder = selectedItem
        }
    }

    

    //  @IBAction func saveInfoClicked(_ sender: Any) {
    //    guard let window = view.window else { return }
    //    guard let selectedUrl = selectedItem else { return }
    //
    //    let panel = NSSavePanel()
    //    panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
    //    panel.nameFieldStringValue = selectedUrl
    //      .deletingPathExtension()
    //      .appendingPathExtension("fs.txt")
    //      .lastPathComponent
    //
    //    panel.beginSheetModal(for: window) { (result) in
    //      if result.rawValue == NSFileHandlingPanelOKButton,
    //        let url = panel.url {
    //        do {
    //          let infoAsText = self.infoAbout(url: selectedUrl)
    //          try infoAsText.write(to: url, atomically: true, encoding: .utf8)
    //        } catch {
    //          self.showErrorDialogIn(window: window,
    //                                 title: "Unable to save file",
    //                                 message: error.localizedDescription)
    //        }
    //      }
    //    }
    //  }
}
