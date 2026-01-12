import Foundation

enum Language {
    case english
    case chinese

    static var current: Language {
        let identifier = Locale.current.identifier
        // Check for zh, zh-Hans, zh-Hant, zh-CN, etc.
        if identifier.hasPrefix("zh") {
            return .chinese
        }
        // Fallback for current preferred languages if locale is region-specific
        if let lang = Locale.preferredLanguages.first, lang.hasPrefix("zh") {
            return .chinese
        }
        return .english
    }
}

struct L10n {
    static var untitled: String { Language.current == .chinese ? "无标题" : "Untitled" }
    static var newDocument: String { Language.current == .chinese ? "新文档" : "New Document" }
    static var rename: String { Language.current == .chinese ? "重命名" : "Rename" }
    static var delete: String { Language.current == .chinese ? "删除" : "Delete" }
    static var exportMenu: String { Language.current == .chinese ? "导出..." : "Export..." }
    static var exportInk: String {
        Language.current == .chinese ? "导出源码 (.ink)" : "Export Ink (.ink)"
    }
    static var exportJson: String {
        Language.current == .chinese ? "导出编译文件 (.json)" : "Export JSON (.json)"
    }
    static var exportWeb: String {
        Language.current == .chinese ? "导出网页 (.html)" : "Export Web (.html)"
    }
    static var addItem: String { Language.current == .chinese ? "新建文档" : "Add Item" }
    static var renameTitle: String { Language.current == .chinese ? "重命名文档" : "Rename Document" }
    static var newTitle: String { Language.current == .chinese ? "新标题" : "New Title" }
    static var cancel: String { Language.current == .chinese ? "取消" : "Cancel" }
    static var selectDoc: String { Language.current == .chinese ? "请选择一个文档" : "Select a document" }
    static var exportFailed: String { Language.current == .chinese ? "导出失败" : "Export Failed" }
    static var exportSuccess: String { Language.current == .chinese ? "导出成功" : "Export Success" }
    static var compilerError: String {
        Language.current == .chinese
            ? "编译错误：可能是 inklecate 未安装。" : "Compiler Error: inklecate might be missing."
    }
}
