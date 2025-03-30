import Cocoa
import SwiftUI

class Menus {
    var mainMenu: NSMenu?
    var windows: Windows?

    init(_ windows: Windows?) {
        self.windows = windows
        mainMenu = NSMenu()
    }

    func setupMenuBar() {
        guard let mainMenu = mainMenu else { return }

        // App Menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        // "About" menu item
        let aboutMenuItem = NSMenuItem(title: "About \(Bundle.main.appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "b")
        appMenu.addItem(aboutMenuItem)

        // Separator
        appMenu.addItem(NSMenuItem.separator())

        // Settings menu item
        let settingsMenuItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsMenuItem.target = self
        appMenu.addItem(settingsMenuItem)

        // *** Add your custom menu item here, BELOW the "Settings" item ***
        let customMenuItem = NSMenuItem(title: "Show Box", action: #selector(showDropView), keyEquivalent: "o")
        customMenuItem.target = self
        appMenu.addItem(customMenuItem)

        // Support Menu Item
        let supportMenuItem = NSMenuItem(title: "Support", action: #selector(openSupportURL), keyEquivalent: "u")
        supportMenuItem.target = self
        appMenu.addItem(supportMenuItem)

        // *** Add another separator if you want visual separation ***
        appMenu.addItem(NSMenuItem.separator())

        // "Quit" menu item
        let quitMenuItem = NSMenuItem(title: "Quit \(Bundle.main.appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    @objc func openSettings() {
        windows?.showSettingsWindow()
    }

    @objc func showDropView() {
        print("showDropViewWindow!")
        windows?.showDropViewWindow()
    }

    @objc func openSupportURL() {
        if let url = URL(string: "https://twindai.com/droppdf") {
            NSWorkspace.shared.open(url)
        }
    }
}

extension Bundle {
    var appName: String {
        return self.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App"
    }
}
