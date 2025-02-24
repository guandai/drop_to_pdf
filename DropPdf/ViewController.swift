import Cocoa

class ViewController: NSViewController {
    
    let explanationLabel: NSTextField = {
        let label = NSTextField(labelWithString: "This app needs Full Disk Access to function properly.\n\nGo to System Settings > Privacy & Security > Full Disk Access, then enable access for this app.")
        label.font = NSFont.systemFont(ofSize: 14)
        label.isEditable = false
        label.isBezeled = false
        label.isSelectable = true
        label.alignment = .center
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 5
        return label
    }()
    
    let openSettingsButton: NSButton = {
        let button = NSButton(title: "Open Full Disk Access Settings", target: nil, action: #selector(openFullDiskAccessSettings))
        button.bezelStyle = .rounded
        button.font = NSFont.systemFont(ofSize: 14)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI
        view.addSubview(explanationLabel)
        view.addSubview(openSettingsButton)
        
        // Layout
        explanationLabel.translatesAutoresizingMaskIntoConstraints = false
        openSettingsButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            explanationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            explanationLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            explanationLabel.widthAnchor.constraint(equalToConstant: 400),
            
            openSettingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openSettingsButton.topAnchor.constraint(equalTo: explanationLabel.bottomAnchor, constant: 20)
        ])
        
        // ✅ Hide or show the button based on Full Disk Access
        if PermissionsManager.hasFullDiskAccess() {
            openSettingsButton.isHidden = true
        } else {
            openSettingsButton.isHidden = false
        }
    }
    
    @objc func openFullDiskAccessSettings() {
        let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(settingsURL)
    }
}
