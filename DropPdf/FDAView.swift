import Cocoa

import SwiftUI

struct FDAView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Full Disk Access Required")
                .font(.title2)
            
            Text("This app needs Full Disk Access to read or write certain protected files. Please enable it in System Settings → Privacy & Security → Full Disk Access.")
                .multilineTextAlignment(.center)
                .frame(width: 300)
            
            Button("Open Full Disk Access Settings") {
                PermissionsManager().openFullDiskAccessSettings()
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}

