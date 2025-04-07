import SwiftUI

struct BoxSign: View {
    let isDragging: Bool

    var body: some View {
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
}

struct CheckResult: View {
    let systemName: String
    let systemColor: Color
    @Binding var showMark: Bool

    var body: some View {
        Image(systemName: systemName)
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
}

struct ProcessedFilesButton: View {
    @Binding var showPanel: Bool

    var body: some View {
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
}


struct TopBar: View {
    @Binding var createOneFile: Bool

    var body: some View {
        HStack {
            Toggle(isOn: $createOneFile) {}
                .toggleStyle(SwitchToggleStyle())
                .accessibilityIdentifier("switchButton")
                .padding(.leading, 4)

            Text(createOneFile ? "Create A Bundle" : "Create Separate")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
        .padding(.top, 10)
    }
}


struct DropBox: View {
    @Binding var isDragging: Bool
    @Binding var showMark: Bool
    let systemName: String
    let systemColor: Color
    let handleFileDrop: ([NSItemProvider]) async -> Void

    var body: some View {
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
                CheckResult(systemName: systemName, systemColor: systemColor, showMark: $showMark)
            } else {
                BoxSign(isDragging: isDragging)
            }
        }
        .onDrop(of: ["public.file-url"], isTargeted: $isDragging) { providers in
            Task {
                await handleFileDrop(providers)
            }
            return true
        }
    }
}

struct CenteredProgressView: View {
    @Binding var progress: Double // Bind progress value

    var body: some View {
        if progress > 0.0 && progress < 1.0 { // Show only when progress is active
            ZStack {
                // Add a semi-transparent background overlay
                Color.black.opacity(0.7) // Dark overlay for clarity
                    .edgesIgnoringSafeArea(.all)

                // ProgressView in the center
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white)) // Use white for better contrast
                    .scaleEffect(1.5) // Adjust size of the progress view
                    .padding()
            }
            .transition(.opacity) // Smooth fade-in/out
            .animation(.easeInOut, value: progress)
        }
    }
}


struct WrapperMainBox: View {
    @Binding var createOneFile: Bool
    var dropBox: AnyView

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar(createOneFile: $createOneFile)
                dropBox
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

    /// Determines the correct background color for iOS and macOS
    private func getBackgroundColor() -> Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
}



struct WrapperProcessButton: View {
    @Binding var showPanel: Bool
    var processedFiles: [Int: (URL, Bool)] // Replace `ProcessedFile` with the actual type

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ProcessedFilesButton(showPanel: $showPanel)
                    .padding(.trailing, 5)
                    .padding(.bottom, 20)
                    .sheet(isPresented: $showPanel) {
                        ProcessedFilesPanel(processedFiles: processedFiles, isPresented: $showPanel)
                    }
            }
        }
    }
}
