import SwiftUI

struct DropView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var processFile: ProcessFile

    @State private var isDragging = false
    @State private var showMark = false
    @State private var systemName = "checkmark.circle.fill"
    @State private var systemColor: Color = .green
    @State private var showPanel = false

    static let baseSize: CGFloat = 80  // ✅ Use `static let`
    static let dropAreaLength: CGFloat = 2.8 * DropView.baseSize
    static let iconLength: CGFloat = 1 * DropView.baseSize
    static let outerLength: CGFloat = 3 * DropView.baseSize

    var BoxSign : some View {
        VStack {
            Image(systemName: "tray.and.arrow.down.fill")
                .resizable()
                .scaledToFit()
                .frame(width: DropView.baseSize, height: DropView.baseSize)
                .foregroundColor(isDragging ? .blue : .gray)

            Text("Drag & Drop")
                .font(.body)
                .foregroundColor(.primary)
        }
    }
    
    var CheckResult: some View { Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: DropView.iconLength, height: DropView.iconLength)
            .foregroundColor(systemColor)
            .opacity(showMark ? 1.0 : 0.75)
            .animation(.easeIn(duration: 0.2), value: showMark)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showMark = false
                    }
                }
            }
    }
    
    var DropBox : some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isDragging ? Color.blue : Color.gray.opacity(0.5), lineWidth: 3)
                )
                .shadow(color: isDragging ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3), radius: 10, x: 0, y: 5)
                .frame(width: DropView.dropAreaLength, height: DropView.dropAreaLength)

            if showMark {
                CheckResult
            } else {
                BoxSign
            }
        }
        .onDrop(of: ["public.file-url"], isTargeted: $isDragging) { providers in
            Task {
                await handleFileDrop(providers)
            }
            return true
        }
    }
    
    var ProcessedFilesBtn: some View {
        Button(action: {
                showPanel = true
            }) {
                Image(systemName: "info.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle()) // No extra styling
            .accessibilityIdentifier("infoButton")
    }
    
    var TopBar: some View {
        HStack {
            Toggle(isOn: $appDelegate.createOneFile) {}
            .toggleStyle(SwitchToggleStyle())
            .accessibilityIdentifier("switchButton")
            .padding(.leading, 4)

            // Show the on/off result as text
            Text(appDelegate.createOneFile ? "Create A Bundle" : "Create Separate")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
        .padding(.top, 10)
    }
    
    var WrapperMainBox : some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar
                DropBox
            }
        }
        .padding(10)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(getBackgroundColor())
                .shadow(radius: 10)
        )
    }
    
    var WrapperProcessBtn : some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ProcessedFilesBtn
                    .padding(.trailing, 5)
                    .padding(.bottom, 20)
                    .sheet(isPresented: $showPanel) {
                       ProcessedFilesPanel(processedFiles: appDelegate.processResult, isPresented: $showPanel)
                    }
            }
        }
    }

    var body: some View {
        ZStack {
            WrapperMainBox
            WrapperProcessBtn
        }
        .frame(width: DropView.outerLength + 10, height: DropView.outerLength + 40)
    }

    /// Determines the correct background color for iOS and macOS
    private func getBackgroundColor() -> Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #endif
    }


    private func appendNewFiles(providers: [NSItemProvider], dispatchGroup: DispatchGroup) async -> [URL] {
        var newFiles: [URL] = []

        return await withCheckedContinuation { continuation in
            for provider in providers {
                dispatchGroup.enter()
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    defer { dispatchGroup.leave() }

                    guard let data = item as? Data, let fileURL = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    
                    DispatchQueue.main.async {
                        newFiles.append(fileURL)
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                continuation.resume(returning: newFiles)
            }
        }
    }


    private func handleFileDrop(_ providers: [NSItemProvider]) async -> Bool {
        let dispatchGroup = DispatchGroup()
        let newFiles = await appendNewFiles(providers: providers, dispatchGroup: dispatchGroup)

        dispatchGroup.notify(queue: .main) {
            Task {
                let result = await appDelegate.startDrop(newFiles)
    
                showMark = true
                systemName = result.values.contains(false) ?  "xmark.circle.fill" : "checkmark.circle.fill";
                systemColor = result.values.contains(false) ?  .red : .green;
            }
        }

        return true
    }
}
