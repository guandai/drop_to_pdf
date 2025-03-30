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
        newWindow.title = "Drop To PDF"
        newWindow.contentView = hostingController.view
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.isReleasedWhenClosed = false

        self.window = newWindow
        NSApplication.shared.activate(ignoringOtherApps: true)
    }


    func showDropViewWindow() {
        setupMainWindow()
    }

    func setupMenuBar() {
        DispatchQueue.main.async {
            if let mainMenu = NSApplication.shared.mainMenu { // Get the main menu
                let appMenuItem = NSMenuItem() // Create an app menu item
                mainMenu.addItem(appMenuItem) // Add it to the main menu

                let appMenu = NSMenu() // Create the submenu
                appMenuItem.submenu = appMenu // Set the submenu

                // Clear existing items before adding new ones
                appMenu.removeAllItems()

                // Add standard app menu items (e.g., About, Quit)
                if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
                    let aboutMenuItem = NSMenuItem(title: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
                    aboutMenuItem.target = self // Target for About
                    appMenu.addItem(aboutMenuItem)

                    appMenu.addItem(NSMenuItem.separator())

                    let hideMenuItem = NSMenuItem(title: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
                    hideMenuItem.target = self // Target for Hide
                    appMenu.addItem(hideMenuItem)

                    let hideOtherMenuItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "H")
                    hideOtherMenuItem.keyEquivalentModifierMask = [.command, .option]
                    hideOtherMenuItem.target = self // Target for Hide Others
                    appMenu.addItem(hideOtherMenuItem)

                    let showAllMenuItem = NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
                    showAllMenuItem.target = self // Target for Show All
                    appMenu.addItem(showAllMenuItem)

                    appMenu.addItem(NSMenuItem.separator())

                    let quitMenuItem = NSMenuItem(title: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
                    quitMenuItem.target = self // Target for Quit
                    appMenu.addItem(quitMenuItem)
                }

                appMenu.addItem(NSMenuItem.separator())

                // Add "Open Drop Window" menu item
                let openWindowMenuItem = NSMenuItem(
                    title: "Open Drop Window",
                    action: #selector(self.openWindowAction),
                    keyEquivalent: "o"
                )
                openWindowMenuItem.target = self
                appMenu.addItem(openWindowMenuItem)

                // Add "Settings..." menu item
                let settingsMenuItem = NSMenuItem(
                    title: "Settings...",
                    action: #selector(self.openSettingsWindow),
                    keyEquivalent: ","
                )
                settingsMenuItem.target = self
                appMenu.addItem(settingsMenuItem)
            } else {
                print("Could not access main menu")
            }
        }
    }

    @objc func openWindowAction() {
        showDropViewWindow()
    }

    @objc func openSettingsWindow() {
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

}
