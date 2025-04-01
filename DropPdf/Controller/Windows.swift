import Cocoa
import SwiftUI
import UniformTypeIdentifiers

class Windows: ObservableObject {
    var settingsWindow: NSWindow?
    var window: NSWindow?
    var appDelegate: AppDelegate
    weak var menus: Menus? // Add a weak reference to Menus

    init(_ window: NSWindow? = nil, _ appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        self.window = window
    }

    func setupMainWindow(_ window: NSWindow? = nil) {
        // Check if the window already exists and is visible
        if let existingWindow = self.window, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        // Create the SwiftUI view and inject environment objects
        let contentView = DropView()
            .environmentObject(AppDelegate.shared) // Inject AppDelegate.shared
            .environmentObject(AppDelegate.shared.processFile) // Inject processFile

        // Create the hosting controller for the SwiftUI view
        let hostingController = NSHostingController(rootView: contentView)

        // Create a new NSWindow
        let newWindow = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 800, height: 600), // Adjust size as needed
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.center()
        newWindow.title = "Drop To PDF"
        newWindow.contentView = hostingController.view
        newWindow.contentViewController = hostingController // Set the hosting controller
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.isReleasedWhenClosed = false // Prevent the window from being released when closed

        // Store the new window reference
        self.window = newWindow

        // Activate the application
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
        setupMainWindow(window)
    }

    func showSettingsWindow() {
        setupSettingsWindow(window)
    }
}
