/**
 * Copyright (c) 2017 Razeware LLC
 *
 */

import Cocoa
import Quartz

class ViewController: NSViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var infoTextView: NSTextView!
    @IBOutlet weak var matchingFilesTableView: NSTableView!
    @IBOutlet weak var selectFromLbl: NSTextField!
    @IBOutlet weak var searchFromLbl: NSTextField!
    @IBOutlet weak var startSearchBtn: NSButton!
    @IBOutlet weak var ignoreCaseCheckbox: NSButton!
    
    @IBOutlet weak var srcImageView: IKImageView!
    
    // MARK: - Properties
    
    var srcFileList: [URL] = []
    var destFolderFileList: [URL] = []
    var matchingFileList: [URL] = []
    var showInvisibles = false
    

    func showErrorDialogIn(title: String, message: String) {
        let a: NSAlert = NSAlert()
        a.messageText = title
        a.informativeText = message
        //a.addButton(withTitle: "Delete")
        //a.addButton(withTitle: "Cancel")
        a.alertStyle = NSAlert.Style.warning
        
        a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse: NSApplication.ModalResponse) -> Void in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("Document deleted")
            }
        })
    }
    
    @IBAction func startSearch(_ sender: Any) {
        var myMatchingFilesList: [URL] = []
        //let destSrchList: [URL] = self.destFolderFileList
        
        self.matchingFileList.removeAll()
        NSLog("Starting search")
        for fileURL:URL in self.srcFileList {
            let src = fileURL.lastPathComponent
            //NSLog("looking up dups for \(src)")
            
            for destFileURL:URL in self.destFolderFileList {
                let dst = destFileURL.lastPathComponent
                //NSLog("commparing \(src) to \(dst)")

                if (ignoreCaseCheckbox.state == NSButton.StateValue.on) {
                    //NSLog ("ignoring case")
                    if(src.caseInsensitiveCompare(dst) == .orderedSame){
                        NSLog("FOUND \(dst)")
                        myMatchingFilesList.append(destFileURL)
                    }
                } else {
                    //NSLog ("respecting case")
                    if (src == dst) {
                        NSLog("FOUND \(dst)")
                        myMatchingFilesList.append(destFileURL)
                    }
                }
            }
        }
        
        if (myMatchingFilesList.count > 0) {
            self.matchingFileList = myMatchingFilesList
            self.matchingFilesTableView.reloadData()
        } else {
            NSLog("no results found")
            self.matchingFileList.removeAll()
            showErrorDialogIn(title:"No Results", message:"No matches were found")
        }
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        selectFromLbl.stringValue = ""
        searchFromLbl.stringValue = ""
        startSearchBtn.isEnabled = false
        view.window?.title = "PhotoDupFinder"
    }
    var selectSrcFolder: URL? {
        didSet {
            if let selectFromFolder = selectSrcFolder {
                srcFileList = contentsOf(folder: selectFromFolder)
                selectedItem = nil
                self.tableView.reloadData()
                self.tableView.scrollRowToVisible(0)
                view.window?.title = selectFromFolder.path
                selectFromLbl.stringValue = selectFromFolder.path
                
                if (searchFromLbl.stringValue.isEmpty) {
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
    var selectDstFolder: URL? {
        didSet {
            if let selectSearchFolder = selectDstFolder {
                self.matchingFileList = contentsOf(folder: selectSearchFolder)
                self.destFolderFileList = contentsOf(folder: selectSearchFolder)

                selectedItem = nil
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
    
    var selectedItem: URL? {
        didSet {
            infoTextView.string = ""
            
            guard let selectedUrl = selectedItem else {
                return
            }
            
            let infoString = infoAbout(url: selectedUrl)
            if !infoString.isEmpty {
                let formattedText = formatInfoText(infoString)
                infoTextView.textStorage?.setAttributedString(formattedText)
            }
        }
    }
    
//    @IBAction func matchingItemSelected(_ sender: Any) {
//        NSLog("item selected")
//        if matchingFilesTableView.selectedRow < 0 {
//            self.matchingSelectedItem = nil
//            return
//        }
//
//        matchingSelectedItem = matchingFileList[matchingFilesTableView.selectedRow]
//   }

    
    var matchingSelectedItem: URL? {
        didSet {
            infoTextView.string = ""
            //saveInfoButton.isEnabled = false

            guard let selectedUrl = matchingSelectedItem else {
                return
            }

            let infoString = infoAbout(url: selectedUrl)
            if !infoString.isEmpty {
                let formattedText = formatInfoText(infoString)
                infoTextView.textStorage?.setAttributedString(formattedText)
                //saveInfoButton.isEnabled = true
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
    
    func contentsOf(folder: URL) -> [URL] {
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
                cell.imageView?.image = fileIcon
                return cell
            }        }
        return nil
    }
    
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let table = notification.object as! NSTableView

        if (table == self.tableView) {
            if tableView.selectedRow < 0 {
                selectedItem = nil
                return
            }
            
            selectedItem = srcFileList[tableView.selectedRow]
            self.matchingFilesTableView.scrollRowToVisible(0)
        }
        else if (table == self.matchingFilesTableView) {
            if matchingFilesTableView.selectedRow < 0 {
                self.matchingSelectedItem = nil
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
