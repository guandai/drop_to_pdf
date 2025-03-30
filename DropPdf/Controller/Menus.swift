import Cocoa
import SwiftUI
import UniformTypeIdentifiers

class Windows: ObservableObject {
    var settingsWindow: NSWindow?
    var window: NSWindow?
    var appDelegate: AppDelegate

    init(_ window: NSWindow? = nil, _ appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        self.window = window
    }

    func setupMainWindow(_ window: NSWindow? = nil) {
        if let existingWindow = self.window, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(
            rootView: AnyView(
                DropView()
                    .environmentObject(appDelegate)
                    .environmentObject(appDelegate.processFile)
            ))

        let newWindow = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.center()
        newWindow.title = "> Drop To PDF"
        newWindow.contentView = hostingController.view
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.isReleasedWhenClosed = false

        self.window = newWindow
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func setupSettingsWindow(_ window: NSWindow? = nil) {
        if settingsWindow == nil {
            let settingsHostingController = NSHostingController(rootView: SettingsView())
            
            let newSettingsWindow = NSWindow(
                contentRect: NSRect(x: 200, y: 200, width: 400, height: 300),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            newSettingsWindow.center()
            newSettingsWindow.title = "Settings"
            newSettingsWindow.contentView = settingsHostingController.view
            newSettingsWindow.makeKeyAndOrderFront(nil)
            newSettingsWindow.isReleasedWhenClosed = false
            
            self.settingsWindow = newSettingsWindow
        } else {
            settingsWindow?.makeKeyAndOrderFront(nil)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }


    func showDropViewWindow() {
        setupMainWindow()
    }
    
    func showSettingsWindow() {
        setupSettingsWindow()
    }
}
