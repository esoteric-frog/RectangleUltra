/// LogViewer.swift

import Cocoa

class Logger {
    
    static var logging = false
    
    static private var logWindowController: LogWindowController?
    
    static func showLogging(sender: Any?) {
        if logWindowController == nil {
            logWindowController = LogWindowController.freshController()
        }
        NSApp.activate(ignoringOtherApps: true)
        logWindowController?.showWindow(sender)
        logging = true
    }
    
    static func log(_ string: String) {
        if logging {
            logWindowController?.append(string)
        }
    }
}

class LogWindowController: NSWindowController, NSWindowDelegate {

    @objc func clearClicked(_ sender: Any) {
        (contentViewController as? LogViewController)?.clear()
    }
    
    func append(_ string: String) {
        let datestamp = String(NSDate().timeIntervalSince1970)
        (contentViewController as? LogViewController)?.append(datestamp + ": " + string + "\n")
    }
    
    func windowWillClose(_ notification: Notification) {
        Logger.logging = false
        clearClicked(self)
    }
}

extension LogWindowController {
    // Reproduces LogViewer.storyboard: 480x270 titled/closable/miniaturizable/resizable window,
    // min size 100x50, "Clear" toolbar item (trash icon), non-editable text view in a vertical scroller.
    static func freshController() -> LogWindowController {
        let window = NSWindow(
            contentRect: NSRect(x: 245, y: 301, width: 480, height: 270),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: true)
        window.title = "Rectangle Logging"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 100, height: 50)
        window.contentViewController = LogViewController()

        let windowController = LogWindowController(window: window)
        let toolbar = NSToolbar(identifier: "LogToolbar")
        toolbar.delegate = windowController
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        window.toolbar = toolbar
        window.delegate = windowController
        return windowController
    }
}

extension LogWindowController: NSToolbarDelegate {
    private static let clearItemId = NSToolbarItem.Identifier("LogClear")

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] { [Self.clearItemId] }
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] { [Self.clearItemId] }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard itemIdentifier == Self.clearItemId else { return nil }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = "Clear"
        item.paletteLabel = "Clear"
        item.image = NSImage(named: NSImage.trashEmptyName)
        item.target = self
        item.action = #selector(clearClicked(_:))
        return item
    }
}


class LogViewController: NSViewController {
    
    var textView: NSTextView!

    override func loadView() {
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 480, height: 270))
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]
        let text = KeyDownTextView(frame: scrollView.bounds)
        text.minSize = NSSize(width: 480, height: 270)
        text.maxSize = NSSize(width: 480, height: 10_000_000)
        text.isVerticallyResizable = true
        text.isHorizontallyResizable = false
        text.autoresizingMask = [.width, .height]
        text.isRichText = false
        text.importsGraphics = false
        text.textContainer?.widthTracksTextView = true
        text.textColor = .textColor
        text.backgroundColor = .textBackgroundColor
        scrollView.documentView = text
        textView = text
        view = scrollView
    }
    
    let font = NSFont(name:"Monaco", size: 10) ?? NSFont.systemFont(ofSize: 10)
    
    let textColorAttribute =
        [NSAttributedString.Key.foregroundColor: NSColor.textColor,
         NSAttributedString.Key.font: NSFont(name:"Monaco", size: 10) ?? NSFont.systemFont(ofSize: 10)]
            
            as [NSAttributedString.Key: Any]
    
    func append(_ string: String) {
        let smartScroll = self.textView.visibleRect.maxY == self.textView.bounds.maxY
        
        textView.textStorage?.append(NSAttributedString(string: string, attributes: textColorAttribute))
        
        if smartScroll{
            textView.scrollToEndOfDocument(self)
        }
    }

    func clear() {
        textView.string = ""
    }
    
    override func viewDidLoad() {
        textView.isEditable = false
    }
    
}

class KeyDownTextView: NSTextView {
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(NSEvent.ModifierFlags.command) {
            switch event.charactersIgnoringModifiers! {
            case "w":
                self.window?.close()
            case "h":
                self.window?.orderOut(self)
            default:
                super.keyDown(with: event)
            }
        } else {
            super.keyDown(with: event)
        }
    }
}
