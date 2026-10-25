/// MenuBuilder.swift
/// Replaces Main.storyboard: builds the app main menu and the two status-item menus in code.

import Cocoa

enum MenuBuilder {

    /// Builds all menus, sets `NSApp.mainMenu`, and hands the status menus to the delegate (which owns them strongly).
    static func install(on delegate: AppDelegate) {
        NSApp.mainMenu = makeMainMenu(delegate: delegate)

        // Status menu. Storyboard items have an empty modifier mask except Quit.
        let status = NSMenu(title: "")
        let ignore = item("Ignore frontmost.app", #selector(AppDelegate.ignoreFrontMostApp(_:)), target: delegate, mask: [])
        status.addItem(ignore)
        status.addItem(.separator())
        status.addItem(item("Settings…", #selector(AppDelegate.openPreferences(_:)), target: delegate, mask: []))
        status.addItem(item("About", #selector(AppDelegate.showAbout(_:)), target: delegate, mask: []))
        let logging = item("View Logging…", #selector(AppDelegate.viewLogging(_:)), target: delegate, mask: .option)
        logging.isAlternate = true
        status.addItem(logging)
        let quit = item("Quit Rectangle Ultra", #selector(NSApplication.terminate(_:)), key: "q", target: NSApp)
        status.addItem(quit)

        // Menu shown when Accessibility access has not been granted.
        let unauthorized = NSMenu(title: "")
        let header = item("Not Authorized to Control Your Computer", nil, mask: [])
        header.isEnabled = false
        unauthorized.addItem(header)
        unauthorized.addItem(item("Authorize…", #selector(AppDelegate.authorizeAccessibility(_:)), target: delegate, mask: []))
        unauthorized.addItem(.separator())
        unauthorized.addItem(item("About", #selector(NSApplication.orderFrontStandardAboutPanel(_:)), target: NSApp, mask: []))
        unauthorized.addItem(item("Quit Rectangle Ultra", #selector(NSApplication.terminate(_:)), key: "q", target: NSApp))

        delegate.mainStatusMenu = status
        delegate.unauthorizedMenu = unauthorized
        delegate.ignoreMenuItem = ignore
        delegate.viewLoggingMenuItem = logging
        delegate.quitMenuItem = quit
    }

    private static func makeMainMenu(delegate: AppDelegate) -> NSMenu {
        let main = NSMenu(title: "Main Menu")

        // Application menu
        let services = NSMenu(title: "Services")
        NSApp.servicesMenu = services
        let servicesItem = item("Services", nil, mask: [])
        servicesItem.submenu = services
        let app = menu("Rectangle Ultra", [
            item("About Rectangle Ultra", #selector(NSApplication.orderFrontStandardAboutPanel(_:)), mask: []),
            .separator(),
            item("Preferences…", #selector(AppDelegate.openPreferences(_:)), key: ",", target: delegate),
            .separator(),
            servicesItem,
            .separator(),
            item("Hide Rectangle Ultra", #selector(NSApplication.hide(_:)), key: "h"),
            item("Hide Others", #selector(NSApplication.hideOtherApplications(_:)), key: "h", mask: [.option, .command]),
            item("Show All", #selector(NSApplication.unhideAllApplications(_:)), mask: []),
            .separator(),
            item("Quit Rectangle Ultra", #selector(NSApplication.terminate(_:)), key: "q"),
        ])
        add(app, to: main)

        // File menu (storyboard New/Open/Save dropped: the app has no documents)
        add(menu("File", [item("Close", #selector(NSWindow.performClose(_:)), key: "w")]), to: main)

        // Edit menu
        let find = menu("Find", [
            item("Find…", #selector(NSTextView.performFindPanelAction(_:)), key: "f", tag: 1),
            item("Find and Replace…", #selector(NSTextView.performFindPanelAction(_:)), key: "f", mask: [.option, .command], tag: 12),
            item("Find Next", #selector(NSTextView.performFindPanelAction(_:)), key: "g", tag: 2),
            item("Find Previous", #selector(NSTextView.performFindPanelAction(_:)), key: "G", tag: 3),
            item("Use Selection for Find", #selector(NSTextView.performFindPanelAction(_:)), key: "e", tag: 7),
            item("Jump to Selection", #selector(NSResponder.centerSelectionInVisibleArea(_:)), key: "j"),
        ])
        let findItem = item("Find", nil, mask: [])
        findItem.submenu = find
        let edit = menu("Edit", [
            item("Undo", Selector(("undo:")), key: "z"),
            item("Redo", Selector(("redo:")), key: "Z"),
            .separator(),
            item("Cut", #selector(NSText.cut(_:)), key: "x"),
            item("Copy", #selector(NSText.copy(_:)), key: "c"),
            item("Paste", #selector(NSText.paste(_:)), key: "v"),
            item("Paste and Match Style", #selector(NSTextView.pasteAsPlainText(_:)), key: "V", mask: [.option, .command]),
            item("Delete", #selector(NSText.delete(_:)), mask: []),
            item("Select All", #selector(NSText.selectAll(_:)), key: "a"),
            .separator(),
            findItem,
        ])
        add(edit, to: main)

        // View menu
        add(menu("View", [
            item("Enter Full Screen", #selector(NSWindow.toggleFullScreen(_:)), key: "f", mask: [.control, .command]),
        ]), to: main)

        // Window menu
        let window = menu("Window", [item("Minimize", #selector(NSWindow.performMiniaturize(_:)), key: "m")])
        NSApp.windowsMenu = window
        add(window, to: main)

        // Help menu
        let help = menu("Help", [item("Rectangle Ultra Help", #selector(NSApplication.showHelp(_:)), key: "?")])
        NSApp.helpMenu = help
        add(help, to: main)

        return main
    }

    /// Menu item. `mask` defaults to ⌘, which is what Interface Builder uses when a key equivalent is set.
    private static func item(_ title: String, _ action: Selector?, key: String = "", target: AnyObject? = nil,
                             mask: NSEvent.ModifierFlags = .command, tag: Int = 0) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
        menuItem.keyEquivalentModifierMask = mask
        menuItem.target = target
        menuItem.tag = tag
        return menuItem
    }

    private static func menu(_ title: String, _ items: [NSMenuItem]) -> NSMenu {
        let menu = NSMenu(title: title)
        items.forEach(menu.addItem)
        return menu
    }

    private static func add(_ submenu: NSMenu, to main: NSMenu) {
        let menuItem = NSMenuItem(title: submenu.title, action: nil, keyEquivalent: "")
        menuItem.submenu = submenu
        main.addItem(menuItem)
    }
}
