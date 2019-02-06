/**
 * Copyright (c) 2017 Razeware LLC
 *
 */

import Cocoa
import Quartz
import AppKit


class ViewController: NSViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var infoTextView: NSTextView!
    @IBOutlet weak var matchingFilesTableView: NSTableView!
    @IBOutlet weak var srcImageView: IKImageView!

    @IBOutlet weak var srcImgViewer: NSImageView!
    @IBOutlet weak var dstImgViewer: NSImageView!
    
    @IBOutlet weak var selectFromLbl: NSTextField!
    @IBOutlet weak var searchFromLbl: NSTextField!
    @IBOutlet weak var filesMatchingSearchLbl: NSTextField!
    @IBOutlet weak var compare_nCharsLable: NSTextField!

    @IBOutlet weak var startSearchBtn: NSButton!
    @IBOutlet weak var DeleteSrcBtn: NSButton!
    
    @IBOutlet weak var hideNonDupChkbox: NSButton!
    @IBOutlet weak var nCharsSlider: NSSlider!
    @IBOutlet weak var Enable_n_chars: NSButton!
    @IBOutlet weak var recurseCkbx: NSButton!
    @IBOutlet weak var ignoreCaseCheckbox: NSButton!

    // MARK: - Properties
    var srcFileList: [URL] = []
    var matchingFileList: [URL] = []
    let fileManager = PhotoFileManager()

    func showErrorDialogIn(title: String, message: String) {
        let a: NSAlert = NSAlert()
        a.messageText = title
        a.informativeText = message
        a.alertStyle = NSAlert.Style.warning
        
        a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse: NSApplication.ModalResponse) -> Void in
            // if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn)
            // {
            // }
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectFromLbl.stringValue = ""
        searchFromLbl.stringValue = ""
        startSearchBtn.isEnabled = false
        view.window?.title = "PhotoDupFinder"
        DeleteSrcBtn.isEnabled = false
        hideNonDupChkbox.state = NSButton.StateValue.off
        nCharsSlider.intValue = 8
        change_nCharsValue(self)

        // Initialize fileManager object
        if (Enable_n_chars.state == NSButton.StateValue.on) {
            fileManager.nCharsEnabled = true
        } else {
            fileManager.nCharsEnabled = false
        }
        
        fileManager.nCharsValue = Int(nCharsSlider.intValue)
        if (Enable_n_chars.state == NSButton.StateValue.on) {
            fileManager.nCharsEnabled = true
        } else {
            fileManager.nCharsEnabled = false
        }
        
//        if (hideNonDupChkbox.state == NSButton.StateValue.on) {
//            fileManager.hideNonDups = true
//        } else {
//            fileManager.hideNonDups = false
//        }
        
        if (recurseCkbx.state == NSButton.StateValue.on) {
            fileManager.recurseDirs = true
        } else {
            fileManager.recurseDirs = false
        }
        if (ignoreCaseCheckbox.state == NSButton.StateValue.on) {
            fileManager.ignoreCase = true
        } else {
            fileManager.ignoreCase = false
        }
    }
    
    // Called when you select the source folder. Adds list of all filenames into
    // the srcFileList array and then forces a redraw of the source folder table
    // at which point you see the files listed.
    // Enables the search button as long as the destination folder has also been selected.
    var selectSrcFolder: URL? {
        didSet {
            if let selectedFolder = self.selectSrcFolder {
                self.fileManager.fillSourceList(folder:
                    selectedFolder, completion: { (files: [URL]) in
                        self.srcFileList = files
                        self.tableView.reloadData()
                        self.tableView.scrollRowToVisible(0)

                })
                
                selectedItem = nil
                self.view.window?.title = selectedFolder.path
                self.selectFromLbl.stringValue = selectedFolder.path
                
                if (self.searchFromLbl.stringValue.isEmpty) {
                    self.startSearchBtn.isEnabled = false
                } else {
                    self.startSearchBtn.isEnabled = true
                }
                
                //hideNonDupChkbox.state = NSButton.StateValue.on
                
                self.srcImgViewer.image = nil
                
                self.dstImgViewer.image = nil
                self.srcFileList.removeAll()
                self.tableView.reloadData()
            }
        }
    }
    
    // Called when you select the starting destination folder. Adds list of all filenames into
    // the internalDestFileList array. Does not force a redraw of the destination folder table.
    // Enables the search button as long as the search from folder has also been selected.
    var selectDstFolder: URL? {
        didSet {
            if let selectSearchFolder = selectDstFolder {
                matchingSelectedItem = nil
                self.searchFromLbl.stringValue = selectSearchFolder.path
                
                if (self.selectFromLbl.stringValue.isEmpty) {
                    self.startSearchBtn.isEnabled = false
                    
                } else {
                    self.startSearchBtn.isEnabled = true
                }
            }
        }
    }
    
    // This function is called when an item is selected in the left hand table, which
    // contains the list of files from the selected source folder. The selected
    // file image is displayed, and it's file details are obtained and displayed beneath
    // the image.
    var selectedItem: URL? {
        didSet {
            print("entering didSet for selectedItem \(String(describing: selectedItem))")

            guard let selectedUrl = selectedItem else {
                return
            }


            fileManager.getMatchingFileList(file: selectedUrl, completion: { (files: [URL]) -> Void in
                print("clearing matchingFilesTableView")
                self.matchingFileList.removeAll()
                //self.matchingFilesTableView.reloadData()

                print("reloading matchingFilesTableView")
                self.matchingFileList.append(contentsOf: files)
                self.matchingFilesTableView.reloadData()
                print("reloading matchingFilesTableView complete")
            })

            infoTextView.string = ""

 //           displayFileInfo(theUrl: selectedUrl)
            let img = NSImage(byReferencing: selectedUrl)
            srcImgViewer.image = img
            dstImgViewer.image = nil

            
            DeleteSrcBtn.isEnabled = true
//            DispatchQueue.global(qos: .userInitiated).async {
//                print("displaying left image for \(selectedUrl)")
//
//                self.srcImageView.setImageWith(selectedUrl)
//            }
        }
    }
    
    
    // This function is called when an item is selected in the right hand table, which
    // contains files matching the selected file in the left hand table. The selected
    // file image is displayed, and it's file details are obtained and displayed beneath
    // the image.
    var matchingSelectedItem: URL? {
        didSet {
            //print("entering didSet for matchingSelectedItem")
            guard let selectedUrl = matchingSelectedItem else {
                return
            }
            
            infoTextView.string = ""
            
//            displayFileInfo(theUrl: selectedUrl)

            //self.DeleteSrcBtn.isEnabled = false
            //DispatchQueue.global(qos: .userInitiated).async {
                print("displaying right image for \(selectedUrl)")
                
                //self.srcImageView.setImageWith(selectedUrl)
            let img = NSImage(byReferencing: selectedUrl)
            dstImgViewer.image = img
            DeleteSrcBtn.isEnabled = true
            //}
        }
    }
    
    // MARK: - View Lifecycle & error dialog utility
    
    override func viewWillAppear() {
        super.viewWillAppear()
        //restoreCurrentSelections()
    }
    
    override func viewWillDisappear() {
        //saveCurrentSelections()
        super.viewWillDisappear()
    }
}


// MARK: - NSTableViewDataSource

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.tableView {
            return srcFileList.count
        }
        else if tableView == self.matchingFilesTableView {
            return matchingFileList.count
        }
        
        return 0
    }
    
}


// MARK: - NSTableViewDelegate
// Here is where files are added to the internal arrays
extension ViewController: NSTableViewDelegate {
    
    // original code - works for left table
    func tableView(_ tableView: NSTableView, viewFor
        tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableView == self.tableView {
            let item = srcFileList[row]
            print ("adding to left table, row \(row), item \(item)")


            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("FileCell"), owner: nil)
                as? NSTableCellView {
                cell.textField?.stringValue = item.lastPathComponent
                let fileIcon = NSWorkspace.shared.icon(forFile: item.path)
                cell.imageView?.image = fileIcon

                // this works, but it's slow as hell as it loads each large image
//                let img = NSImage(contentsOf: item)
//                let imgRep = NSImageRep.init(contentsOf: item)
//                if let myImage = imgRep {
//                    img!.addRepresentation(imgRep!)
//                    cell.imageView?.image = img
//
//                } else {
//                    cell.imageView?.image = fileIcon
//                }

                return cell
            }
        }
        else if tableView == self.matchingFilesTableView {

            let item = matchingFileList[row]
            print ("adding to right table, row \(row), item \(item)")

            
            if let cell = matchingFilesTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("FileCell"), owner: nil)
                as? NSTableCellView {
                cell.textField?.stringValue = item.lastPathComponent
                //cell.textField?.stringValue = item.relativePath
                
                let fileIcon = NSWorkspace.shared.icon(forFile: item.path)
                cell.imageView?.image = fileIcon
                return cell
            }
            
        }
        else {
            print("Hey, this isn't the right table")
        }
        return nil
    }
    
    //
    func tableViewSelectionDidChange(_ notification: Notification) {
        let table = notification.object as! NSTableView
        
        if (table == self.tableView) {
            if self.tableView.selectedRow < 0 {
                selectedItem = nil
                return
            }
            
            selectedItem = self.srcFileList[self.tableView.selectedRow]
            print ("\(String(describing: selectedItem)) selected from \(self.tableView.selectedRow), left table")
            
            ////////////
//            if let item = selectedItem {
//
//                
//                infoTextView.string = ""
//                
//                //           displayFileInfo(theUrl: selectedUrl)
//                
//                DeleteSrcBtn.isEnabled = true
//                //DispatchQueue.global(qos: .userInitiated).async {
//                    print("displaying left image for \(item)")
//                    
//                    //self.srcImageView.setImageWith(item)
//                //}
//                let img = NSImage(byReferencing: item)
//                imageView.image = img
//                
//                fileManager.getMatchingFileList(file: item, completion: { (files: [URL]) -> Void in
//                    print("clearing matchingFilesTableView")
//                    self.matchingFileList.removeAll()
//                    //self.matchingFilesTableView.reloadData()
//                    
//                    if (files.count > 0) {
//                        print("reloading matchingFilesTableView")
//                        self.matchingFileList.append(contentsOf: files)
//                    } else {
//                        print ("no matching files found")
//                    }
//
//                    self.matchingFilesTableView.reloadData()
//                    print("reloading matchingFilesTableView complete")
//                })
//            }

            ///////////

        }
        else if (table == self.matchingFilesTableView) {
            if self.matchingFilesTableView.selectedRow < 0 {
                matchingSelectedItem = nil
                return
            }
            
            matchingSelectedItem = matchingFileList[self.matchingFilesTableView.selectedRow]
            print ("\(String(describing: matchingSelectedItem)) selected from \(self.matchingFilesTableView.selectedRow), right table")

        }
        else {
            print("wrong table???")
        }
        
        print("leaving tableViewSelectionDidChange")

    }
    
    func displayFileInfo(theUrl: URL) {
        fileManager.infoAbout(url: theUrl, completion: { (retStr: NSAttributedString?) -> Void in
            if let infoString = retStr {
                self.infoTextView.textStorage?.setAttributedString(infoString)
            } else {
                print ("couldn't get info string for \(theUrl)")
            }
        })
    }
}

// MARK: - Save & Restore previous selection

//extension ViewController {
//
//    func saveCurrentSelections() {
//        guard let dataFileUrl = urlForDataStorage() else { return }
//
//        let parentForStorage = selectFromFolder?.path ?? ""
//        let fileForStorage = selectedItem?.path ?? ""
//        let completeData = "\(parentForStorage)\n\(fileForStorage)\n"
//
//        try? completeData.write(to: dataFileUrl, atomically: true, encoding: .utf8)
//    }
//
//    func restoreCurrentSelections() {
//        guard let dataFileUrl = urlForDataStorage() else { return }
//
//        do {
//            let storedData = try String(contentsOf: dataFileUrl)
//            let storedDataComponents = storedData.components(separatedBy: .newlines)
//            if storedDataComponents.count >= 2 {
//                if !storedDataComponents[0].isEmpty {
//                    selectFromFolder = URL(fileURLWithPath: storedDataComponents[0])
//                    if !storedDataComponents[1].isEmpty {
//                        selectedItem = URL(fileURLWithPath: storedDataComponents[1])
//                        selectUrlInTable(selectedItem)
//                    }
//                }
//            }
//        } catch {
//            print(error)
//        }
//    }
//
//    private func selectUrlInTable(_ url: URL?) {
//        guard let url = url else {
//            tableView.deselectAll(nil)
//            return
//        }
//
//        if let rowNumber = filesList.index(of: url) {
//            let indexSet = IndexSet(integer: rowNumber)
//            DispatchQueue.main.async {
//                self.tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
//            }
//        }
//    }
//
//    private func urlForDataStorage() -> URL? {
//        let fileManager = FileManager.default
//        guard let folder = fileManager.urls(for: .applicationSupportDirectory,
//                                            in: .userDomainMask).first else {
//                                                return nil
//        }
//        let appFolder = folder.appendingPathComponent("FileSpy")
//
//        var isDirectory: ObjCBool = false
//        let folderExists = fileManager.fileExists(atPath: appFolder.path, isDirectory: &isDirectory)
//        if !folderExists || !isDirectory.boolValue {
//            do {
//                try fileManager.createDirectory(at: appFolder,
//                                                withIntermediateDirectories: true,
//                                                attributes: nil)
//            } catch {
//                return nil
//            }
//        }
//
//        let dataFileUrl = appFolder.appendingPathComponent("StoredState.txt")
//        return dataFileUrl
//    }
//
//}


