//
//  inkiesApp.swift
//  inkies
//
//  Created by 石屿 on 2026/1/12.
//

import SwiftData
import SwiftUI

@main
struct inkiesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
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
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .importExport) {
                Section {
                    Button(L10n.exportInk) {
                        NotificationCenter.default.post(
                            name: Notification.Name("ExportInk"), object: nil)
                    }
                    .keyboardShortcut("e", modifiers: .command)

                    Button(L10n.exportJson) {
                        NotificationCenter.default.post(
                            name: Notification.Name("ExportJSON"), object: nil)
                    }
                    .keyboardShortcut("j", modifiers: .command)

                    Button(L10n.exportWeb) {
                        NotificationCenter.default.post(
                            name: Notification.Name("ExportWeb"), object: nil)
                    }
                    .keyboardShortcut("b", modifiers: .command)  // 'b' for Build/Browser
                }
            }
        }
    }
}

extension inkiesApp {
    @MainActor
    private func handleIncomingURL(_ url: URL) {
        // ... (rest of logic)
        guard let schema = sharedModelContainer.schema as? Schema else { return }
        let context = sharedModelContainer.mainContext

        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            let filename = url.deletingPathExtension().lastPathComponent
            let content = try String(contentsOf: url, encoding: .utf8)

            // Create new item
            let newItem = Item(timestamp: Date(), title: filename, content: content)
            context.insert(newItem)
            // Try to force save
            try? context.save()
        } catch {
            print("Import error: \(error.localizedDescription)")
        }
    }
}
