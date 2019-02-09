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
    @IBOutlet weak var numMatchesFoundLbl: NSTextField!
    @IBOutlet weak var intDstListCountLbl: NSTextField!
    @IBOutlet weak var srcTblListCountLbl: NSTextField!
    @IBOutlet weak var selectedSrcFilePathLbl: NSTextField!
    @IBOutlet weak var selectedDstFilePathLbl: NSTextField!
    
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
    //let fileManager = PhotoFileManager()
    var internalSrcFileList: [URL] = []
    var internalDestFileList: [URL] = []
    //var masterDestFileList: [URL] = []
    //var masterDestFileList: [String] = []
    
    var showInvisibles = false
    var ignoreCase = false
    var nCharsEnabled = false
    var nCharsValue = 3
    var recurseDirs = false
    //var hideNonDups = false;
    
    
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
            self.nCharsEnabled = true
        } else {
            self.nCharsEnabled = false
        }
        
        self.nCharsValue = Int(nCharsSlider.intValue)
        if (Enable_n_chars.state == NSButton.StateValue.on) {
            self.nCharsEnabled = true
        } else {
            self.nCharsEnabled = false
        }
        
//        if (hideNonDupChkbox.state == NSButton.StateValue.on) {
//            fileManager.hideNonDups = true
//        } else {
//            fileManager.hideNonDups = false
//        }
        
        if (recurseCkbx.state == NSButton.StateValue.on) {
            self.recurseDirs = true
        } else {
            self.recurseDirs = false
        }
        if (ignoreCaseCheckbox.state == NSButton.StateValue.on) {
            self.ignoreCase = true
        } else {
            self.ignoreCase = false
        }
    }
    
    // Called when you select the source folder. Adds list of all filenames into
    // the srcFileList array and then forces a redraw of the source folder table
    // at which point you see the files listed.
    // Enables the search button as long as the destination folder has also been selected.
    var selectSrcFolder: URL? {
        didSet {
            if let selectedFolder = self.selectSrcFolder {
                self.srcImgViewer.image = nil
                
                self.dstImgViewer.image = nil
                self.srcFileList.removeAll()
                self.tableView.reloadData()
                
                fillSourceList(folder:
                    selectedFolder, completion: { (files: [URL]) in
                        self.srcFileList = files
                        self.tableView.reloadData()
                        self.tableView.scrollRowToVisible(0)
                        self.srcTblListCountLbl.stringValue = "\(self.srcFileList.count)"

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


            getMatchingFileList(file: selectedUrl, completion: { (files: [URL]) -> Void in
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
            selectedSrcFilePathLbl.stringValue = getRelativePath(parentUrl: selectSrcFolder!, childUrl: selectedUrl)
            
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
            
            //selectedDstFilePathLbl.stringValue = selectedUrl.path
            selectedDstFilePathLbl.stringValue = getRelativePath(parentUrl: selectDstFolder!, childUrl: selectedUrl)
            //}
        }
    }
    
    
    // This function is called to load the source folder
    // list with all file URLs in the source folder
    func fillSourceList(folder: URL, completion: @escaping ([URL]) -> ()) {
        DispatchQueue.global(qos: .userInteractive).async {
            // Start with an empty list.
            self.internalSrcFileList.removeAll()
            self.getFolderContents(folder: folder, completion: { (files: [URL]) in
                self.internalSrcFileList.append(contentsOf: files)
                DispatchQueue.main.async {
                    completion(self.internalSrcFileList)
                }
                
            })
        }
    }
    
    // This function is called to obtain and return a list of URLs representing
    // the files within the specified folder name.
    func getFolderContents(folder: URL, completion: @escaping ([URL]) -> ())  {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
            //print ("first char = \(folder.path.prefix(1))")
            //    .filter { return showInvisibles ? true : $0.characters.first != "." }
            
            let urls = contents
                .filter { return showInvisibles ? true : $0.prefix(1) != "." }
                .map { return folder.appendingPathComponent($0) }
            completion (urls)
        } catch {
            completion ([])
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
    
    // Given a folder name found while searching through search folders, return back a list
    // of file urls from the folder that match files in the source foler.
    func isMatchingSrcFileList(file: URL)  -> Bool {
        var matches: Bool = false
        let dst = file.lastPathComponent
        let dstPath = file.deletingLastPathComponent()
        
        for srcFileURL:URL in internalSrcFileList {
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
    
    func compareFiles(src: String, dst: String) -> Bool {
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
        infoAbout(url: theUrl, completion: { (retStr: NSAttributedString?) -> Void in
            if let infoString = retStr {
                self.infoTextView.textStorage?.setAttributedString(infoString)
            } else {
                print ("couldn't get info string for \(theUrl)")
            }
        })
    }
    
    func getRelativePath(parentUrl: URL, childUrl: URL) -> String {
        let parent = parentUrl.path
        let child = childUrl.path
        var len = child.count - parent.count
        len *= -1
        let index = child.index(child.endIndex, offsetBy: len)
        let mySubstring = child.suffix(from: index) // playground
        
        //let mySubstring = child.suffix(len) // Hello

        return String(mySubstring)
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


