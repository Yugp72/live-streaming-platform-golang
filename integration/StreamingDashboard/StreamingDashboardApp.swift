import SwiftUI

@main
struct StreamingDashboardApp: App {
    @StateObject private var eventManager = StreamingEventManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(eventManager)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

