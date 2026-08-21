---
slug: flow
title: Key flows
role: key flows
updated: "2026-08-21T06:38:37"
---

# Key flows

```mermaid
sequenceDiagram
    autonumber
    Writer->>Editor: Type Ink story script
    Editor->>Engine: Debounced compile request
    Engine->>JS: Execute inkjs compiler
    JS-->>Preview: Update story state machine
    Preview-->>Writer: Render interactive dialogue choices
```
