import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
MenuBuilder.install(on: delegate)
app.run()
