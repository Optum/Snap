import Cocoa

protocol SelectedFile {
    func selectedFile(_ path: String, textField: NSTextField)
}

enum DropFileType: String {
    case apk = "apk"
    case ipa = "ipa"
    case jks = "jks"
    case keystore = "keystore"
    case mobileprovision = "mobileprovision"
    case plist = "plist"
    case xcarchive = "xcarchive"

    var displayName: String {
        return self.rawValue as String
    }
}

class DragNDropFiles: NSTextField {

    var filePath: String?
    var expectedExt = [DropFileType]()  //file extensions allowed for Drag&Drop (example: "jpg","png","docx", etc..)
    var bgColor: CGColor?
    var del: SelectedFile?

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.wantsLayer = true

        bgColor = self.layer?.backgroundColor

        if #available(OSX 10.13, *) {
            registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
        } else {
            // Fallback on earlier versions
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if checkExtension(sender) == true {
            self.layer?.backgroundColor = NSColor.darkGray.cgColor
            self.textColor = .white
            return .copy
        } else {
            return NSDragOperation()
        }
    }

    fileprivate func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        guard let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
            let path = board[0] as? String
            else { return false }

        if let suffix = DropFileType(rawValue: URL(fileURLWithPath: path).pathExtension) {
            for ftype in self.expectedExt {
                if ftype == suffix {
                    return true
                }
            }
        }

        return false
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.backgroundColor = bgColor
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.layer?.backgroundColor = bgColor
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
            let path = pasteboard[0] as? String
            else { return false }

        self.stringValue = path
        del?.selectedFile(path, textField: self)

        return true
    }
}
