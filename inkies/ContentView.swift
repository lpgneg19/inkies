import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import WebKit

// MARK: - Localization Helper (Moved to Localization.swift)

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var selection: Item?
    @State private var showingRenameAlert = false
    @State private var itemToRename: Item?
    @State private var renameTitle = ""

    // Export States
    @State private var showingExportInk = false
    @State private var showingExportJson = false
    @State private var showingExportWeb = false
    @State private var showingExportError = false
    @State private var exportErrorMessage = ""
    @State private var exportDocument: InkDocument?
    @State private var exportJsonDocument: JSONDocument?
    @State private var exportWebDocument: WebExportDocument?
    @State private var isExporting = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        Text(item.title.isEmpty ? L10n.untitled : item.title)
                    }
                    .contextMenu {
                        Button(L10n.rename) {
                            itemToRename = item
                            renameTitle = item.title
                            showingRenameAlert = true
                        }
                        Button(L10n.delete, role: .destructive) {
                            modelContext.delete(item)
                        }
                        Divider()
                        Menu(L10n.exportMenu) {
                            Button(L10n.exportInk) { prepareExportInk(item) }
                            Button(L10n.exportJson) { Task { await prepareExportJson(item) } }
                            Button(L10n.exportWeb) { Task { await prepareExportWeb(item) } }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label(L10n.addItem, systemImage: "plus")
                    }
                }
            }
            .alert(L10n.renameTitle, isPresented: $showingRenameAlert) {
                TextField(L10n.newTitle, text: $renameTitle)
                Button(L10n.rename) {
                    if let item = itemToRename {
                        item.title = renameTitle
                    }
                }
                Button(L10n.cancel, role: .cancel) {}
            }
        } detail: {
            if let item = selection {
                EditorView(item: item)
                    .onReceive(
                        NotificationCenter.default.publisher(for: Notification.Name("ExportInk"))
                    ) { _ in
                        prepareExportInk(item)
                    }
                    .onReceive(
                        NotificationCenter.default.publisher(for: Notification.Name("ExportJSON"))
                    ) { _ in
                        Task { await prepareExportJson(item) }
                    }
                    .onReceive(
                        NotificationCenter.default.publisher(for: Notification.Name("ExportWeb"))
                    ) { _ in
                        Task { await prepareExportWeb(item) }
                    }
            } else {
                Text(L10n.selectDoc)
                    .foregroundColor(.secondary)
            }
        }
        // Attached to the SplitView itself
        .fileExporter(
            isPresented: $showingExportInk, document: exportDocument, contentType: .ink,
            defaultFilename: "Story"
        ) { result in
            handleExportResult(result)
        }
        .fileExporter(
            isPresented: $showingExportJson, document: exportJsonDocument, contentType: .json,
            defaultFilename: "story"
        ) { result in
            handleExportResult(result)
        }
        .fileExporter(
            isPresented: $showingExportWeb, document: exportWebDocument, contentType: .html,
            defaultFilename: "index"
        ) { result in
            handleExportResult(result)
        }
        .alert("Error", isPresented: $showingExportError) {
            Button("OK") {}
        } message: {
            Text(exportErrorMessage)
        }
    }

    // MARK: - Export Logic

    private func prepareExportInk(_ item: Item) {
        exportDocument = InkDocument(text: item.content)
        showingExportInk = true
    }

    private func prepareExportJson(_ item: Item) async {
        isExporting = true
        do {
            let json = try await InkCompiler.shared.compile(item.content)
            exportJsonDocument = JSONDocument(jsonContent: json)
            showingExportJson = true
        } catch {
            print("Export Failed: \(error.localizedDescription)")
            exportErrorMessage = "\(L10n.compilerError)\n\(error.localizedDescription)"
            showingExportError = true
        }
        isExporting = false
    }

    private func prepareExportWeb(_ item: Item) async {
        isExporting = true
        do {
            let json = try await InkCompiler.shared.compile(item.content)
            // Generate full HTML
            let html = generateHTML(for: json)  // Reusing existing preview generator!
            exportWebDocument = WebExportDocument(content: html, type: .html)
            showingExportWeb = true
        } catch {
            print("Web Export Failed: \(error.localizedDescription)")
            exportErrorMessage = "\(L10n.compilerError)\n\(error.localizedDescription)"
            showingExportError = true
        }
        isExporting = false
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Saved to \(url)")
        case .failure(let error):
            print("Export failed: \(error.localizedDescription)")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date(), title: L10n.newDocument, content: "")
            modelContext.insert(newItem)
            selection = newItem
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

struct EditorView: View {
    @Bindable var item: Item
    @State private var previewContent: String = ""

    var body: some View {
        HStack(spacing: 0) {
            TextEditor(text: $item.content)
                .font(.custom("Menlo", size: 14))
                .scrollContentBackground(.hidden)
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            WebView(content: $previewContent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
        }
        .padding(.top)
        .task(id: item.content) {
            let text = item.content

            // Quick check for empty or JSON
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                previewContent = ""
                return
            }
            if trimmed.hasPrefix("{") {
                previewContent = text
                return
            }

            // Debounce for Ink compilation
            try? await Task.sleep(nanoseconds: 600 * 1_000_000)  // 600ms

            if Task.isCancelled { return }

            do {
                let json = try await InkCompiler.shared.compile(text)
                if !Task.isCancelled {
                    previewContent = json
                }
            } catch {
                if !Task.isCancelled {
                    previewContent = "COMPILER_ERROR: \(error.localizedDescription)"
                }
            }
        }
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#if os(macOS)
    struct WebView: NSViewRepresentable {
        @Binding var content: String

        func makeNSView(context: Context) -> WKWebView {
            let webView = WKWebView()
            webView.navigationDelegate = context.coordinator

            // Enable developer tools for Safari debugging
            webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
            return webView
        }

        func updateNSView(_ nsView: WKWebView, context: Context) {
            print("WebView: updateNSView called. Content length: \(content.count)")
            let html = generateHTML(for: content)

            if context.coordinator.lastContent != content {
                print("WebView: Loading new HTML...")
                nsView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
                context.coordinator.lastContent = content
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, WKNavigationDelegate {
            var parent: WebView
            var lastContent: String = ""

            init(_ parent: WebView) {
                self.parent = parent
            }
        }
    }
#else
    struct WebView: UIViewRepresentable {
        @Binding var content: String

        func makeUIView(context: Context) -> WKWebView {
            let webView = WKWebView()
            webView.navigationDelegate = context.coordinator
            return webView
        }

        func updateUIView(_ uiView: WKWebView, context: Context) {
            print("WebView: updateUIView called.")
            let html = generateHTML(for: content)
            if context.coordinator.lastContent != content {
                uiView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
                context.coordinator.lastContent = content
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, WKNavigationDelegate {
            var parent: WebView
            var lastContent: String = ""

            init(_ parent: WebView) {
                self.parent = parent
            }
        }
    }
#endif

// Helper to find the InkJS library
private func getInkScript() -> String {
    if let path = Bundle.main.path(forResource: "ink.min", ofType: "js") {
        if let content = try? String(contentsOfFile: path, encoding: .utf8) {
            return
                "<script>/* InkJS included from Bundle (\(content.count) bytes) */\n\(content)</script>"
        } else {
            return
                "<script>console.error('INKIES DEBUG: local ink.min.js found but failed to read');</script>"
        }
    }
    // Fallback to CDN if local file not found (User needs to add it to bundle)
    return
        #"<script src="https://unpkg.com/inkjs/dist/ink.js"></script><script>console.warn('INKIES DEBUG: local ink.min.js NOT found in bundle, using CDN');</script>"#
}

private func generateHTML(for inkContext: String) -> String {
    let safeContent = inkContext.replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "")

    let inkScriptTag = getInkScript()

    return """
        <!doctype html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Ink Preview</title>
            \(inkScriptTag)
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; padding: 20px; line-height: 1.6; color: #333; }
                @media (prefers-color-scheme: dark) {
                    body { color: #eee; background: #1e1e1e; }
                    a { color: #64b5f6; }
                }
                .choice { 
                    cursor: pointer; 
                    color: #007aff; 
                    margin-top: 10px; 
                    padding: 6px 12px; 
                    border: 1px solid #007aff; 
                    border-radius: 6px; 
                    transition: background 0.2s; 
                    display: block;
                    width: fit-content;
                }
                .choice:hover { 
                    background: rgba(0, 122, 255, 0.1); 
                    text-decoration: none;
                }
                p { margin-bottom: 12px; }
                pre { background: #f4f4f4; padding: 10px; border-radius: 4px; overflow-x: auto; color: #333; }
                #debug {
                    margin-top: 40px;
                    padding: 10px;
                    background: #fff3cd;
                    color: #856404;
                    border: 1px solid #ffeeba;
                    border-radius: 4px;
                    font-size: 0.85em;
                    font-family: monospace;
                }
            </style>
        </head>
        <body>
            <div id="story"></div>
            
            <div id="debug" style="display:none;">
                <strong>Debug Console:</strong>
                <div id="debug-log"></div>
            </div>

            <script>
                function log(msg) {
                    var d = document.getElementById('debug');
                    d.style.display = 'block';
                    var l = document.getElementById('debug-log');
                    l.innerHTML += "<div>" + msg + "</div>";
                    console.log(msg);
                }

                window.onerror = function(msg, url, line) {
                    log("JS Error: " + msg + " (Line " + line + ")");
                    return false;
                };

                var storyContent = "\(safeContent)";
                
                try {
                    if (typeof inkjs === 'undefined') {
                        log("CRITICAL: inkjs library is missing! Please make sure 'ink.min.js' is added to the Xcode Target, or you have internet connection.");
                    }

                    if (storyContent.trim().length === 0) {
                         document.getElementById('story').innerHTML = "<p><em>Start writing...</em></p>";
                    } else if (storyContent.trim().startsWith('{')) {
                        // JSON Mode (Compiled)
                        try {
                            var jsonContent = JSON.parse(storyContent);
                            var story = new inkjs.Story(jsonContent);
                            var storyContainer = document.getElementById('story');
                            
                            function continueStory() {
                                while(story.canContinue) {
                                    var paragraph = story.Continue();
                                    var p = document.createElement('p');
                                    p.innerText = paragraph;
                                    storyContainer.appendChild(p);
                                }
                                
                                if (story.currentChoices.length > 0) {
                                    story.currentChoices.forEach(function(choice) {
                                        var choiceDiv = document.createElement('div');
                                        choiceDiv.classList.add('choice');
                                        choiceDiv.innerText = choice.text;
                                        choiceDiv.onclick = function() {
                                            story.ChooseChoiceIndex(choice.index);
                                            var choices = document.querySelectorAll('.choice');
                                            choices.forEach(c => c.remove());
                                            continueStory();
                                        };
                                        storyContainer.appendChild(choiceDiv);
                                    });
                                } else {
                                    var endP = document.createElement('p');
                                    endP.innerHTML = "<em>--- End of Story ---</em>";
                                    endP.style.color = "#777";
                                    storyContainer.appendChild(endP);
                                }
                            }
                            
                            continueStory();
                        } catch(jsonErr) {
                             log("JSON Parse/Run Error: " + jsonErr.message);
                        }
                    } else if (storyContent.startsWith('COMPILER_ERROR:')) {
                        // Compiler Error Mode
                        var errorMsg = storyContent.substring('COMPILER_ERROR:'.length);
                        document.getElementById('story').innerHTML = `
                            <div style="background:#fee; color:#c00; padding:15px; border-left:4px solid #c00; border-radius:4px;">
                                <strong>Compilation Failed:</strong><br/>
                                <pre style="background:none; padding:0; margin-top:8px; white-space:pre-wrap;">${errorMsg}</pre>
                            </div>
                        `;
                    } else {
                        // Raw Ink Mode (Instruction)
                        document.getElementById('story').innerHTML = `
                            <p><strong>Raw Ink Code Detected</strong></p>
                            <p>Compiling...</p>
                        `;
                    }
                    
                } catch(e) {
                    log("Setup Error: " + e.message);
                }
            </script>
        </body>
        </html>
        """
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

// MARK: - UTType Extensions
extension UTType {
    static let ink = UTType(exportedAs: "com.inkle.ink")
    static let inkJson = UTType(exportedAs: "com.inkle.ink-json")
    static let inkJs = UTType(exportedAs: "com.inkle.ink-js")
}

// MARK: - Ink Source Document
struct InkDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.ink, .plainText] }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
            let content = String(data: data, encoding: .utf8)
        {
            text = content
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - JSON Export Document
struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .inkJson] }

    var jsonContent: String

    init(jsonContent: String) {
        self.jsonContent = jsonContent
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
            let content = String(data: data, encoding: .utf8)
        {
            jsonContent = content
        } else {
            jsonContent = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = jsonContent.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Web/JS Export Document
struct WebExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.html, .inkJs] }

    var content: String
    var type: UTType

    init(content: String, type: UTType = .html) {
        self.content = content
        self.type = type
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
            let content = String(data: data, encoding: .utf8)
        {
            self.content = content
        } else {
            self.content = ""
        }
        self.type = .html
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Ink Compiler Class
class InkCompiler {
    static let shared = InkCompiler()

    // Potential paths for inklecate
    private let possiblePaths = [
        "/opt/homebrew/bin/inklecate",
        "/usr/local/bin/inklecate",
    ]

    func findInklecate() -> String? {
        // 1. Check App Bundle (Preferred for standalone)
        if let bundledPath = Bundle.main.path(forResource: "inklecate", ofType: nil) {
            return bundledPath
        }

        // 2. Check System Paths
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    func compile(_ inkCode: String) async throws -> String {
        guard let compilerPath = findInklecate() else {
            throw NSError(
                domain: "InkCompiler", code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "inklecate compiler not found. Please install manually or drag into Xcode."
                ])
        }

        // 1. Write temp file
        let tempDir = FileManager.default.temporaryDirectory
        let tempInkFile = tempDir.appendingPathComponent("temp.ink")
        let tempJsonFile = tempDir.appendingPathComponent("temp.json")

        do {
            try inkCode.write(to: tempInkFile, atomically: true, encoding: .utf8)
        } catch {
            throw NSError(
                domain: "InkCompiler", code: 500,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Failed to write temp file: \(error.localizedDescription)"
                ])
        }

        // 2. Run inklecate process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: compilerPath)
        process.arguments = ["-o", tempJsonFile.path, tempInkFile.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    do {
                        let jsonData = try String(contentsOf: tempJsonFile, encoding: .utf8)
                        continuation.resume(returning: jsonData)
                    } catch {
                        continuation.resume(
                            throwing: NSError(
                                domain: "InkCompiler", code: 502,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Compiler finished but JSON output unreadable."
                                ]))
                    }
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? "Unknown compiler error"
                    continuation.resume(
                        throwing: NSError(
                            domain: "InkCompiler", code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: output]))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
