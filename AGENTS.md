# inkies - Agent Guidelines & Instructions

This file provides operational guidance to AI coding agents (Antigravity, Cursor, Codex, OpenCode, Pi, etc.) working in this repository.

## 1. Quick Reference

- **项目类型**：macOS SwiftUI 应用（Swift 6.0+）
- **工程来源**：`xcodegen` 生成，配置文件为 `project.yml`
- **生成工程**：`sh scripts/generate_project.sh` 或 `xcodegen`
- **构建校验（必须）**：
  ```bash
  xcodebuild -project inkies.xcodeproj -scheme inkies -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
  ```
- **本地化资源**：`inkies/Resources/Localizable.xcstrings`
- **关键约束**：禁止硬编码可见文案；禁止 legacy fallback；优先复用现有 API

## 2. Architecture & Directory Structure

```text
project.yml                    # xcodegen 单一配置源
scripts/
  generate_project.sh          # 生成 Xcode 工程
inkies/
  inkiesApp.swift              # 应用入口
  ContentView.swift            # 主界面容器（三栏布局）
  Models/                      # 领域模型 (Item.swift, AppTheme.swift, InkSnippets.swift, InkIssue.swift)
  Services/                    # 业务服务 (InkCompiler.swift 进程调用与缓存, InkHighlighter.swift)
  Views/
    Editor/                    # 编辑器 (InkTextView.swift, LineNumberRulerView.swift)
    Preview/                   # 预览 WebView (WebView.swift 载入 InkJS)
  Utilities/                   # 辅助能力 (HTMLGenerator.swift, Updater.swift, Extensions.swift)
  Resources/
    Localizable.xcstrings      # 唯一文案资源源
    Compiler/                  # inklecate 与运行时依赖
    Scripts/                   # ink.min.js 等脚本资源
```

## 3. Workflow Rules & Coding Conventions

### Swift & Concurrency
- Swift 6.0+，严格并发模式 (`SWIFT_APPROACHABLE_CONCURRENCY: YES`, `SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor`)。
- `InkCompiler` 中的 `CompilationCache` 使用 `actor` 保证线程安全缓存。
- UI 交互统一在 `@MainActor` 运行。
- 任务结束前清理临时生成的 `*.log` / `*.txt` 文件。

### Localization
- 所有新增或修改的可见文案都必须进入 `Localizable.xcstrings`（支持 en 与 zh-Hans），禁止硬编码。
- 使用 `String(localized:)` 或 `LocalizedStringKey`。

### Release & Sparkle 2.x Guardrails
- **版本号维护**：`project.yml` (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`) 与 `CHANGELOG.md` 双语同步更新。
- **发布脚本防线**：不得随意修改 `.github/workflows/release.yml` 中的版本提取与 Sparkle 签名流程：
  - 私钥清理：`tr -dc A-Za-z0-9+/=`
  - 设置 `DYLD_FRAMEWORK_PATH` 指向 Sparkle tools 目录
  - Stdin 签名：`echo "$KEY" | generate_appcast --ed-key-file -`
  - 签名顺序自内向外：Sparkle.framework → inklecate → app bundle

<!-- BEGIN brain.md -->
## Project Brain

This project keeps a **Project Brain**: a persistent memory layer of its durable decisions, requirements, and constraints. Read `./BRAIN.md` for the full read/write contract.

Maintain the brain as part of normal coding work — not as a separate task. While discussing or implementing features:
- **Start of a task:** load relevant context with the `brain` CLI (`list-pages`, `read-page`, `read-root`). Prefer a narrow read over scanning everything.
- **When a decision, requirement, constraint, or durable insight settles** (in chat or while coding): capture it immediately via the `brain` CLI. Do not wait to be asked and do not batch it for later.
- **Pure implementation with no new decision:** do not write to the brain.
- **When overturning a prior conclusion:** update the page (`update-truth` and/or `append-timeline` with `kind: reversal`, or `archive-page`).
- Only store what will still matter in six months and is hard to reconstruct from the code alone.
- All reads and writes go through the `brain` CLI — never hand-edit brain files.

The brain skills (`brain-setup`, `brain-page`, `brain-ingest`, `brain-bootstrap`) are installed in your global skills directory. Prefer `brain init` to scaffold a new project.
<!-- END brain.md -->
