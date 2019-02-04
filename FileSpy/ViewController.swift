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
        // Do any additional setup after loading the view, typically from a nib.
        
        selectFromLbl.stringValue = ""
        searchFromLbl.stringValue = ""
        startSearchBtn.isEnabled = false
        view.window?.title = "PhotoDupFinder"
        DeleteSrcBtn.isEnabled = false
        hideNonDupChkbox.isEnabled = false
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
            if let selectFromFolder = self.selectSrcFolder {
                self.srcFileList = fileManager.getFolderContents(folder: selectFromFolder)
                selectedItem = nil
                self.tableView.reloadData()
                self.tableView.scrollRowToVisible(0)
                self.view.window?.title = selectFromFolder.path
                self.selectFromLbl.stringValue = selectFromFolder.path
                
                if (self.searchFromLbl.stringValue.isEmpty) {
                    self.startSearchBtn.isEnabled = false
                } else {
                    self.startSearchBtn.isEnabled = true
                }
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
                //self.matchingFilesTableView.reloadData()
                //self.matchingFilesTableView.scrollRowToVisible(0)
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
            //print("entering didSet for selectedItem")
            
            guard let selectedUrl = selectedItem else {
                return
            }
            infoTextView.string = ""
            
            //highlightInMatchingTable(file: selectedUrl)
            
            let infoString = fileManager.infoAbout(url: selectedUrl)
            if let formattedText = infoString {
                infoTextView.textStorage?.setAttributedString(formattedText)
            } else {
                print("Unable to get file info for \(selectedUrl)")
            }
            
            DeleteSrcBtn.isEnabled = true
            srcImageView.setImageWith(selectedUrl)
            matchingFileList.removeAll()
            matchingFileList.append(contentsOf: fileManager.getMatchingFileList(file: selectedUrl))
            //self.matchingFileList = getMatchingFileList(file: selectedUrl)
            matchingFilesTableView.reloadData()
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
            
            let infoString = fileManager.infoAbout(url: selectedUrl)
            if let infoString = infoString {
                infoTextView.textStorage?.setAttributedString(infoString)
            } else {
                print ("couldn't get info string for \(selectedUrl)")
            }
            
            //self.DeleteSrcBtn.isEnabled = false
            self.srcImageView.setImageWith(selectedUrl)
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

 
    
    // This function is called as the first step of processing the Search button click.
    // The recursion checkbox is used to determine if subdirectories should be explored.
    //    func fillInternalMatchingList () {
    //        if let selectSearchFolder = selectDstFolder {
    //            // Start with an empty destination list.
    //            internalDestFileList.removeAll()
    //
    //            if (recurseCkbx.state == NSButton.StateValue.on) {
    //                searchFolder(folder: selectSearchFolder)
    //            } else {  // do not recurse; ignore subfolders
    //                let searchFolderContents: [URL] = getFolderContents(folder: selectSearchFolder)
    //                for fileUrl:URL in searchFolderContents {
    //                    if (isMatchingSrcFileList(file: fileUrl)) {
    //                        internalDestFileList.append(fileUrl)
    //                    }
    //                }
    //            }
    //            DispatchQueue.main.async { [unowned self] in
    //                let numMatching = self.internalDestFileList.count
    //                self.filesMatchingSearchLbl.stringValue = "\(numMatching) matching items located"
    //            }
    //        } else {
    //            DispatchQueue.main.async { [unowned self] in
    //                self.filesMatchingSearchLbl.stringValue = ""
    //            }
    //            showErrorDialogIn(title:"Bad Destination", message:"Invalid destination search folder")
    //        }
    //    }




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
            
            let fileIcon = NSWorkspace.shared.icon(forFile: item.path)
            
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("FileCell"), owner: nil)
                as? NSTableCellView {
                cell.textField?.stringValue = item.lastPathComponent
                //cell.textField?.stringValue = item.relativePath
                
                cell.imageView?.image = fileIcon
                return cell
            }
        }
        else if tableView == self.matchingFilesTableView {
            let item = matchingFileList[row]
            
            let fileIcon = NSWorkspace.shared.icon(forFile: item.path)
            
            if let cell = matchingFilesTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("FileCell"), owner: nil)
                as? NSTableCellView {
                cell.textField?.stringValue = item.lastPathComponent
                //cell.textField?.stringValue = item.relativePath
                
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
        //DispatchQueue.main.async { [unowned self] in
        let table = notification.object as! NSTableView
        
        if (table == self.tableView) {
            if self.tableView.selectedRow < 0 {
                selectedItem = nil
                return
            }
            
            selectedItem = self.srcFileList[self.tableView.selectedRow]
            //self.matchingFilesTableView.scrollRowToVisible(0)
        }
        else if (table == self.matchingFilesTableView) {
            if self.matchingFilesTableView.selectedRow < 0 {
                matchingSelectedItem = nil
                return
            }
            
            self.matchingSelectedItem = matchingFileList[self.matchingFilesTableView.selectedRow]
        }
        //}
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


