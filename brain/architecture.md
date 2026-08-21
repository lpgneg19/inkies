---
slug: architecture
title: System architecture
role: system architecture
updated: "2026-08-21T06:38:37"
---

# System architecture

```mermaid
graph TD
    App[Inkies App] --> Editor[SwiftUI Ink Script Editor]
    App --> Engine[Ink Engine & Compiler Bridge]
    App --> Preview[Interactive Story Preview Surface]
    Engine --> JS[JavaScriptCore / inkjs Runtime]
```
