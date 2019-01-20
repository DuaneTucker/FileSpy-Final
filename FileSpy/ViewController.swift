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
    @IBOutlet weak var selectFromLbl: NSTextField!
    @IBOutlet weak var searchFromLbl: NSTextField!
    @IBOutlet weak var filesMatchingSearchLbl: NSTextField!
    @IBOutlet weak var startSearchBtn: NSButton!
    @IBOutlet weak var ignoreCaseCheckbox: NSButton!
    
    @IBOutlet weak var srcImageView: IKImageView!
    
    @IBOutlet weak var compare_nCharsLable: NSTextField!
    @IBOutlet weak var nCharsSlider: NSSlider!
    @IBOutlet weak var Enable_n_chars: NSButton!
    @IBOutlet weak var recurseCkbx: NSButton!
    // MARK: - Properties
    
    var srcFileList: [URL] = []
    var internalDestFileList: [URL] = []
    var matchingFileList: [URL] = []
    var showInvisibles = false
    
    // This function is called as the first step of processing the Search button click.
    // The recursion checkbox is used to determine if subdirectories should be explored.
    func fillInternalMatchingList () {
        if let selectSearchFolder = selectDstFolder {
            internalDestFileList.removeAll()
            
            if (recurseCkbx.state == NSButton.StateValue.on) {
                var files: [URL] = getFolderContents(folder: selectSearchFolder)
                
                while (files.count > 0) {
                    if (files[0].hasDirectoryPath) {
                        //files.append(contentsOf: getFolderFiles(folder: files[0]))
                        files.append(contentsOf: getMatchingSrcFileList(folderNm: files[0]))
                        files.remove(at: 0)
                    } else {
                        if (isMatchingSrcFileList(file: files[0])) {
                            self.internalDestFileList.append(files[0])
                        }
                        files.remove(at: 0)
                    }
                }
            } else {  // do not recurse; ignore subfolders
                let searchFolderContents: [URL] = getFolderContents(folder: selectSearchFolder)
                for fileUrl:URL in searchFolderContents {
                    if (isMatchingSrcFileList(file: fileUrl)) {
                        internalDestFileList.append(fileUrl)
                    }
                }
            }
            
            let numMatching = internalDestFileList.count
            filesMatchingSearchLbl.stringValue = "\(numMatching) matching items located"
        } else {
            filesMatchingSearchLbl.stringValue = ""
            showErrorDialogIn(title:"Bad Destination", message:"Invalid destination search folder", addButtons: false)
        }
    }
    
    // Given a file that was selected in the left table, return back a list
    // of file urls from the internal matching list. The returned list will then
    // get displayed in the right table.
    func getMatchingFileList(file: URL)  -> [URL] {
        var fileList: [URL] = []

        let src = file.lastPathComponent

        for destFileURL:URL in self.internalDestFileList {
            let dst = destFileURL.lastPathComponent
            NSLog("commparing \(src) to \(dst)")
            
            //NOTE: I think this comparison should only be done in the fillInternalMatchingList function
            // That way, the only files in the internal list would have already been verified to match.
            // This function could simply compare the filename components to determine the list to return.
            if (compareFiles(src: src, dst: dst)) {
                fileList.append(destFileURL)
            }
        }
        
        return fileList
    }
    
    // Given a folder name found while searching through search folders, return back a list
    // of file urls from the folder that match files in the source foler.
    func getMatchingSrcFileList(folderNm: URL)  -> [URL] {
        var fileList: [URL] = []
        let folderContents: [URL] = getFolderContents(folder: folderNm)
            
        for destFileURL:URL in folderContents {
            //NSLog("commparing \(src) to \(dst)")
            if (isMatchingSrcFileList(file: destFileURL)) {
                //NSLog("FOUND \(dst)")
                fileList.append(destFileURL)
            }
        }
        
        return fileList
    }
    
    // Given a folder name found while searching through search folders, return back a list
    // of file urls from the folder that match files in the source foler.
    func isMatchingSrcFileList(file: URL)  -> Bool {
        var matches: Bool = false
        let dst = file.lastPathComponent

        for srcFileURL:URL in self.srcFileList {
            let src = srcFileURL.lastPathComponent
            //NSLog("looking up dups for \(src)")
            
            if (compareFiles(src: src, dst: dst)) {
                //NSLog("FOUND \(dst)")
                matches = true
                break
            }
        }
        
        return matches
    }
    
    func showErrorDialogIn(title: String, message: String, addButtons: Bool) {
        let a: NSAlert = NSAlert()
        a.messageText = title
        a.informativeText = message
        a.alertStyle = NSAlert.Style.warning

        if (addButtons) {
            a.addButton(withTitle: "Delete")
            a.addButton(withTitle: "Cancel")
        }
        
        a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse: NSApplication.ModalResponse) -> Void in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("Document deleted")
            }
        })
    }
    
    func compareFiles(src: String, dst: String) -> Bool {
        var ret: Bool = false
        
        if (Enable_n_chars.state == NSButton.StateValue.on) {
            
        }
        if (ignoreCaseCheckbox.state == NSButton.StateValue.on) {
            //NSLog ("ignoring case")
            if(src.caseInsensitiveCompare(dst) == .orderedSame){
                ret = true
            }
        } else {
            //NSLog ("respecting case")
            if (src == dst) {
                ret = true
            }
        }
        
        return ret
    }
    
    @IBAction func change_nCharsValue(_ sender: Any) {
       let numChars = nCharsSlider.intValue
        compare_nCharsLable.stringValue = "Compare at most \(numChars) characters"
    }
    
    // This is the main search function, called when the user clicks the Search button
    @IBAction func startSearch(_ sender: Any) {
        //var myMatchingFilesList: [URL] = []
        //let destSrchList: [URL] = self.destFolderFileList
        startSearchBtn.isEnabled = false
        NSLog("Starting search for matches")
        
        DispatchQueue.main.async { [unowned self] in
            self.matchingFileList.removeAll()
            self.matchingFilesTableView.reloadData()

            NSLog("getting internal list of all available matching files now...")
            self.fillInternalMatchingList()
            
            if (self.internalDestFileList.count > 0) {
                //self.matchingFileList = myMatchingFilesList
                //self.matchingFilesTableView.reloadData()
            } else {
                NSLog("no results found")
                //DispatchQueue.main.async { [unowned self] in
                    self.matchingFileList.removeAll()
                    self.matchingFilesTableView.reloadData()
                //}
                self.showErrorDialogIn(title:"No Results", message:"No matches were found", addButtons: false)
            }
            
            self.startSearchBtn.isEnabled = true
        }
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        selectFromLbl.stringValue = ""
        searchFromLbl.stringValue = ""
        startSearchBtn.isEnabled = false
        view.window?.title = "PhotoDupFinder"
        change_nCharsValue(self)
    }
    
    // Called when you select the source folder. Adds list of all filenames into
    // the srcFileList array and then forces a redraw of the source folder table
    // at which point you see the files listed.
    // Enables the search button as long as the destination folder has also been selected.

    var selectSrcFolder: URL? {
        didSet {
            if let selectFromFolder = selectSrcFolder {
                DispatchQueue.main.async { [unowned self] in
                    self.srcFileList = self.getFolderContents(folder: selectFromFolder)
                    self.selectedItem = nil
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
//            else {
//                view.window?.title = "FileSpy"
//            }
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
                searchFromLbl.stringValue = selectSearchFolder.path
                
                if (selectFromLbl.stringValue.isEmpty) {
                    startSearchBtn.isEnabled = false
                    
                } else {
                    startSearchBtn.isEnabled = true
                }
            }
//            else {
//                view.window?.title = "FileSpy"
//            }
        }
    }
    
    // This function is called when an item is selected in the left hand table, which
    // contains the list of files from the selected source folder. The selected
    // file image is displayed, and it's file details are obtained and displayed beneath
    // the image.
    var selectedItem: URL? {
        didSet {
            //NSLog("entering didSet for selectedItem")
            infoTextView.string = ""
            
            guard let selectedUrl = selectedItem else {
                return
            }
            

                

                //srcImageView.setImageWith(selectedUrl)

                
                DispatchQueue.main.async { [unowned self] in
                    //highlightInMatchingTable(file: selectedUrl)
                    let infoString = self.infoAbout(url: selectedUrl)
                    if !infoString.isEmpty {
                        let formattedText = self.formatInfoText(infoString)
                        self.infoTextView.textStorage?.setAttributedString(formattedText)
                    self.srcImageView.setImageWith(selectedUrl)
                    self.matchingFileList.removeAll()
                    self.matchingFileList.append(contentsOf: self.getMatchingFileList(file: selectedUrl))
                    //self.matchingFileList = getMatchingFileList(file: selectedUrl)
                    self.matchingFilesTableView.reloadData()
                }
                

            }
        }
    }
    
    
    // This function is called when an item is selected in the right hand table, which
    // contains files matching the selected file in the left hand table. The selected
    // file image is displayed, and it's file details are obtained and displayed beneath
    // the image.
    var matchingSelectedItem: URL? {
        didSet {
            infoTextView.string = ""
            //NSLog("entering didSet for matchingSelectedItem")

            guard let selectedUrl = matchingSelectedItem else {
                return
            }
            DispatchQueue.main.async { [unowned self] in
                let infoString = self.infoAbout(url: selectedUrl)
                if !infoString.isEmpty {
                    let formattedText = self.formatInfoText(infoString)
                    self.infoTextView.textStorage?.setAttributedString(formattedText)
                    self.srcImageView.setImageWith(selectedUrl)
                }
            }
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

// MARK: - Getting file or folder information

extension ViewController {
    
    // This function is called to obtain and return a list of URLs representing
    // the files within the specified folder name.
    func getFolderContents(folder: URL) -> [URL] {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
            let urls = contents
                .filter { return showInvisibles ? true : $0.characters.first != "." }
                .map { return folder.appendingPathComponent($0) }
            NSLog("contentsOf is returning \(urls.count) items")
            return urls
        } catch {
            return []
        }
    }
    
    func infoAbout(url: URL) -> String {
        let fileManager = FileManager.default
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            var report: [String] = ["\(url.path)", ""]
            
            for (key, value) in attributes {
                // ignore NSFileExtendedAttributes as it is a messy dictionary
                if key.rawValue == "NSFileExtendedAttributes" { continue }
                report.append("\(key.rawValue):\t \(value)")
            }
            return report.joined(separator: "\n")
        } catch {
            return "No information available for \(url.path)"
        }
    }
    
    func formatInfoText(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.minimumLineHeight = 24
        paragraphStyle?.alignment = .left
        paragraphStyle?.tabStops = [ NSTextTab(type: .leftTabStopType, location: 240) ]
        
        let textAttributes: [String: Any] = [
            convertFromNSAttributedStringKey(NSAttributedString.Key.font): NSFont.systemFont(ofSize: 14),
            convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyle ?? NSParagraphStyle.default
        ]
        
        let formattedText = NSAttributedString(string: text, attributes: convertToOptionalNSAttributedStringKeyDictionary(textAttributes))
        return formattedText
    }
    
    
}

// MARK: - Actions

extension ViewController {
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
    
    @IBAction func selectFolderClicked(_ sender: Any) {
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
    
    //  @IBAction func toggleShowInvisibles(_ sender: NSButton) {
    //    showInvisibles = (sender.state == NSControl.StateValue.on)
    //    if let selectFromFolder = selectFromFolder {
    //      filesList = contentsOf(folder: selectFromFolder)
    //      selectedItem = nil
    //      tableView.reloadData()
    //    }
    //  }
    
    @IBAction func tableViewDoubleClicked(_ sender: Any) {
        NSLog("entering tableViewDoubleClicked; not finished to work with both tables!")
        if tableView.selectedRow < 0 { return }

        let selectedItem = srcFileList[tableView.selectedRow]
        if selectedItem.hasDirectoryPath {
            selectSrcFolder = selectedItem
        }
    }
    
    //  @IBAction func moveUpClicked(_ sender: Any) {
    //    if selectFromFolder?.path == "/" { return }
    //    //selectFromFolder = selectFromFolder?.deletingLastPathComponent()
    //  }
    
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

            if let cell = tableView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier("FileCell"), owner: nil)
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
            
            if let cell = matchingFilesTableView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier("FileCell"), owner: nil)
                as? NSTableCellView {
                cell.textField?.stringValue = item.lastPathComponent
                //cell.textField?.stringValue = item.relativePath

                cell.imageView?.image = fileIcon
                return cell
            }
            
        }
        else {
            NSLog("Hey, this isn't the right table")
        }
        return nil
    }
    
    //
    func tableViewSelectionDidChange(_ notification: Notification) {
        let table = notification.object as! NSTableView

        if (table == self.tableView) {
            if tableView.selectedRow < 0 {
                selectedItem = nil
                return
            }
            
            selectedItem = srcFileList[tableView.selectedRow]
            //self.matchingFilesTableView.scrollRowToVisible(0)
        }
        else if (table == self.matchingFilesTableView) {
            if matchingFilesTableView.selectedRow < 0 {
                matchingSelectedItem = nil
                return
            }
            
            matchingSelectedItem = matchingFileList[matchingFilesTableView.selectedRow]
        }
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSUserInterfaceItemIdentifier(_ input: String) -> NSUserInterfaceItemIdentifier {
    return NSUserInterfaceItemIdentifier(rawValue: input)
}
