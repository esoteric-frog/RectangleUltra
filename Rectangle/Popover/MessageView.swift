/// MessageView.swift

import Cocoa

class MessagePopover {
    
    var messageView: MessageView
    var popover: NSPopover
    
    init() {
        popover = NSPopover()
        messageView = MessageView()
        popover.behavior = .transient
        popover.contentViewController = messageView
    }
    
    public func show(message: String, sender: NSView) {
        let positioningView = sender
        let positioningRect = NSZeroRect
        let preferredEdge: NSRectEdge = .maxX
        messageView.message = message

        popover.show(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)
    }
}

class MessageView: NSViewController {
    
    var messageField: NSTextField!

    // Reproduces MessageView.xib: mini/smallSystem label, 10pt insets, wraps at the view width.
    override func loadView() {
        let field = NSTextField(wrappingLabelWithString: "")
        field.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        field.textColor = .labelColor
        field.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 195, height: 34))
        container.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            field.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            field.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
        ])
        messageField = field
        view = container
    }
    
    var message: String?
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if let message = message {
            self.messageField?.stringValue = message
        }
    }
}
