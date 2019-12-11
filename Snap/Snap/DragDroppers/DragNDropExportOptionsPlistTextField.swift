import Cocoa

class DragNDropExportOptionsPlistTextField: NSTextField {

    var filePath: String?
    let expectedExt = ["plist"]  //file extensions allowed for Drag&Drop (example: "jpg","png","docx", etc..)
    var bgColor: CGColor?
    var del: selectedExportOptions?

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
            return .copy
        } else {
            return NSDragOperation()
        }
    }

    fileprivate func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        guard let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
            let path = board[0] as? String
            else { return false }

        let suffix = URL(fileURLWithPath: path).pathExtension
        for ext in self.expectedExt {
            if ext.lowercased() == suffix {
                return true
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

        //GET YOUR FILE PATH !!!
        self.stringValue = path
        del?.selectedExportOptions(path)
        
        return true
    }
}

protocol selectedExportOptions {
    func selectedExportOptions(_ path: String)
}
