import SwiftUI

@main
struct HDRemoveApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 560)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 860, height: 620)
    }
}