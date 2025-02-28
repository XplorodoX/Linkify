import SwiftUI
import SwiftData

@main
struct LinkifyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LinkItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, minHeight: 500)
        }
        .modelContainer(sharedModelContainer)
    }
}
