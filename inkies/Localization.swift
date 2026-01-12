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
    static var addItem: String { Language.current == .chinese ? "新建文件" : "Add Item" }
    static var newInkFile: String { Language.current == .chinese ? "新建ink文件" : "New Ink File" }
    static var saveProject: String { Language.current == .chinese ? "保存项目" : "Save Project" }
    static var close: String { Language.current == .chinese ? "关闭" : "Close" }
    static var search: String { Language.current == .chinese ? "搜索" : "Search" }
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

    // MARK: - Story Menu
    static var storyMenu: String { Language.current == .chinese ? "故事" : "Story" }
    static var gotoAnything: String {
        Language.current == .chinese ? "跳转到..." : "Go to anything..."
    }
    static var nextIssue: String { Language.current == .chinese ? "下一个问题" : "Next Issue" }
    static var addWatchExpression: String {
        Language.current == .chinese ? "添加监视表达式..." : "Add watch expression..."
    }
    static var tagsVisible: String { Language.current == .chinese ? "显示标签" : "Tags visible" }
    static var wordCount: String { Language.current == .chinese ? "字数统计" : "Word count and more" }

    // MARK: - Ink Menu
    static var inkMenu: String { Language.current == .chinese ? "Ink" : "Ink" }

    // MARK: - Dialogs
    static var ok: String { Language.current == .chinese ? "好" : "OK" }
    static var watchExpressionTitle: String {
        Language.current == .chinese ? "添加监视表达式" : "Add Watch Expression"
    }
    static var watchExpressionPrompt: String {
        Language.current == .chinese ? "输入要监视的变量名" : "Enter variable name to watch"
    }
    static var noDocumentSelected: String {
        Language.current == .chinese ? "未选择文档" : "No document selected"
    }
    static var wordCountTitle: String {
        Language.current == .chinese ? "文档统计" : "Document Statistics"
    }
    static var words: String { Language.current == .chinese ? "字数" : "Words" }
    static var characters: String { Language.current == .chinese ? "字符" : "Characters" }
    static var lines: String { Language.current == .chinese ? "行数" : "Lines" }
    static var knots: String { Language.current == .chinese ? "结" : "Knots" }
}
