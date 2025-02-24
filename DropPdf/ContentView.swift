import SwiftUI
import AppKit

struct ContentView: View {
    @State private var hasFullDiskAccess = checkFullDiskAccess()
    
    var body: some View {
        if hasFullDiskAccess {
            DropView() // ✅ Show drop area if FDA is granted
        } else {
            FDAView() // ❌ Show FDA request screen if FDA is missing
        }
    }
}
