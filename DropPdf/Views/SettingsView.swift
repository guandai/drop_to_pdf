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
            
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading) {
                    if permissionsManager.grantedFolderURLs.isEmpty {
                        Text("No folders selected.")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(Array(permissionsManager.grantedFolderURLs), id: \.self) { folder in
                            Text(folder.path)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)  // Add this
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 4)  // Only top padding for vertical alignment
                .frame(
                    maxWidth: .infinity,
                    minHeight: 180,  // Match scroll view height
                    alignment: .topLeading
                )
            }
            .frame(width: 350, height: 180)
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )

            
            HStack(spacing: 10) {
                // Button to select a new folder
                Button(action: {
                    if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        permissionsManager.requestAccess(documentsURL.path)
                    } else {
                        permissionsManager.requestAccess(FileManager.default.homeDirectoryForCurrentUser.path)
                    }
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
}
