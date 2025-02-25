import SwiftUI

struct DropView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var processFile: ProcessFile


    var body: some View {
        VStack(spacing: 5) {
            if appDelegate.droppedFiles.isEmpty {
                Text("Drop one or more files here.")
                    .foregroundColor(.secondary)
            } else {
                Text(appDelegate.droppedFiles.map { $0.lastPathComponent }.joined(separator: ", "))
                    .foregroundColor(.gray)
            }

            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: 160, height: 160)
                .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                    // Collect multiple files
                    let dispatchGroup = DispatchGroup()
                    var newFiles: [URL] = []

                    for provider in providers {
                        dispatchGroup.enter()
                        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                            defer { dispatchGroup.leave() }

                            guard
                                let data = item as? Data,
                                let fileURL = URL(dataRepresentation: data, relativeTo: nil)
                            else { return }

                            // Append this file URL in a thread-safe way
                            DispatchQueue.main.async {
                                newFiles.append(fileURL)
                            }
                        }
                    }

                    // When all item providers are done
                    dispatchGroup.notify(queue: .main)  {
                        // Append all newly loaded files
                        appDelegate.droppedFiles.append(contentsOf: newFiles)
                        Task {
                            await processFile.processDroppedFiles(newFiles, appDelegate)
                        }
                    }

                    return true
                }
        }
        .frame(width: 250, height: 250)
    }
}
