import AppKit  // Required for NSApplication
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var permissionsManager = PermissionsManager.shared
    @State private var draggedFilePath: String?

    var body: some View {
        VStack(spacing: 15) {
            // Show allowed folders list
            Text("Allowed Folders:")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading) {
                    if permissionsManager.grantedFolderURLs.isEmpty {
                        Text("No folders selected.")
                            .foregroundColor(.red)
                    } else {
                        ForEach(
                            Array(permissionsManager.grantedFolderURLs),
                            id: \.self
                        ) { folder in
                            
                            Text(folder.path)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            .frame(width: 340, height: 180)
            .background(Color(NSColor.windowBackgroundColor))  // Light background for contrast (macOS)
            .clipShape(RoundedRectangle(cornerRadius: 10))  // Rounded edges
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)  // Subtle border
            )
            
            HStack(spacing: 10) {
                // Button to select a new folder
                Button(action: {
                    permissionsManager.requestAccess()
                }) {
                    Text("Choose Folder")
                        .frame(width: 100, height: 30)
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderedProminent)
                
                // Button to clear permissions
                Button(action: {
                    permissionsManager.clearSavedFolderBookmarks()
                }) {
                    Text("Clear Permissions")
                        .frame(width: 130, height: 30)
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            .padding(.bottom, 0)
            
            
            Button(action: {
                closeSettingsWindow()
            }) {
                Text("CLOSE")
                    .font(.system(size: 14))
                    .frame(width: 80, height: 30)
                    .background(Color.blue)
                    .cornerRadius(6)
                    .padding(.top, 0)
            }
            .buttonStyle(.plain)
            
        }
        .frame(width: 350, height: 300)
        .padding()
    }

    private func closeSettingsWindow() {
        NSApplication.shared.keyWindow?.close()
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(
            forTypeIdentifier: UTType.fileURL.identifier, options: nil
        ) { (item, error) in
            DispatchQueue.main.async {
                if let urlData = item as? Data,
                    let url = URL(dataRepresentation: urlData, relativeTo: nil)
                {
                    self.draggedFilePath = url.path

                    permissionsManager.ensureFolderAccess(for: url) { granted in
                        if !granted {
                            self.draggedFilePath = "Access Denied"
                        }
                    }
                }
            }
        }
        return true
    }
}
