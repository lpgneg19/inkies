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

    @AppStorage("appTheme") private var appTheme: AppTheme = .light

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appTheme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(L10n.newInkFile) {
                    NotificationCenter.default.post(
                        name: Notification.Name("AddItem"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(replacing: .saveItem) {
                Button(L10n.saveProject) {
                    NotificationCenter.default.post(
                        name: Notification.Name("SaveProject"), object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button(L10n.close) {
                    if let window = NSApplication.shared.keyWindow {
                        window.close()
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Button(L10n.search) {
                    NotificationCenter.default.post(
                        name: Notification.Name("SearchItems"), object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Picker(L10n.theme, selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.localizedName).tag(theme)
                    }
                }
            }

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

            // MARK: - Story Menu
            CommandMenu(L10n.storyMenu) {
                Button(L10n.gotoAnything) {
                    NotificationCenter.default.post(
                        name: Notification.Name("GotoAnything"), object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)

                Button(L10n.nextIssue) {
                    NotificationCenter.default.post(
                        name: Notification.Name("NextIssue"), object: nil)
                }
                .keyboardShortcut(".", modifiers: .command)

                Button(L10n.addWatchExpression) {
                    NotificationCenter.default.post(
                        name: Notification.Name("AddWatchExpression"), object: nil)
                }

                Divider()

                Toggle(L10n.tagsVisible, isOn: .constant(true))

                Divider()

                Button(L10n.wordCount) {
                    NotificationCenter.default.post(
                        name: Notification.Name("ShowWordCount"), object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }

            // MARK: - Ink Menu
            CommandMenu(L10n.inkMenu) {
                ForEach(InkSnippets.allCategories.indices, id: \.self) { index in
                    let category = InkSnippets.allCategories[index]
                    Menu(category.localizedName) {
                        ForEach(category.snippets.indices, id: \.self) { snippetIndex in
                            let snippet = category.snippets[snippetIndex]
                            Button(snippet.localizedName) {
                                NotificationCenter.default.post(
                                    name: Notification.Name("InsertSnippet"),
                                    object: snippet.ink)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension inkiesApp {
    @MainActor
    private func handleIncomingURL(_ url: URL) {
        // ... (rest of logic)
        let schema = sharedModelContainer.schema
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
