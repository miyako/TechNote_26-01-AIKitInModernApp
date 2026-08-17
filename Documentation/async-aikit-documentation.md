# Asynchronous AI Kit Implementation in 4D

## Overview

This document summarises the key concepts for implementing asynchronous AI Kit callbacks in a 4D project. The asynchronous pattern enables **streaming LLM responses** (token-by-token delivery to the UI) and **non-blocking file uploads**, providing a responsive user experience instead of freezing the UI while waiting for API responses.

## Architecture

### Execution Context Requirements

The async callback mechanism in AI Kit is built on [`4D.HTTPRequest`](https://developer.4d.com/docs/API/HTTPRequestClass). The callback is dispatched within the **current process's event loop**. This means:

| Execution context | Callback dispatch | `Form` availability |
|---|---|---|
| `DIALOG("form"; *)` (non-modal) | Implicit `CALL FORM` — form's event loop | ✅ resolves to form data |
| Worker with no UI | Implicit `CALL WORKER` — worker's event loop | ❌ returns `Null` |
| Modal `DIALOG("form")` without `*` | ❌ **Never fires** — event loop is blocked | N/A |
| Regular process (not a worker) | ❌ **May never fire** — process may end | N/A |

> ⚠️ If your process ends at the conclusion of the current method (e.g., using `New process`, or playing in the method editor), the callback formula might not be called. ([AI Kit docs](https://github.com/4d/4D-AIKit/blob/main/Documentation/asynchronous-call.md))

### How to Open the Form Correctly

For the async callbacks to fire, the form must run in a context with an active event loop:

1. **From the Form Editor** — for quick testing (the editor provides its own event loop)
2. **Using `CALL WORKER` + `DIALOG` with `*`** — for production use

The recommended pattern uses **process 1 (the main worker)**, which always exists and has its own event loop. Since `DIALOG(*)` is asynchronous, multiple dialogs can coexist in the same process:

```4dm
// Recursive pattern: dispatch to main worker, then open non-modal dialog
If (Count parameters=0)
    // First call: dispatch to main worker (process 1)
    CALL WORKER(1; Current method name; True)
Else 
    // Second call: running inside the main worker
    var $window : Integer
    $window:=Open form window("MyForm"; Plain form window)
    DIALOG("MyForm"; *)
End if 
```

**Important notes:**
- Do **not** use `CLOSE WINDOW` — the runtime manages the window lifecycle for `DIALOG(*)`
- Do **not** create a new named worker unless you need a separate language/database context (process variables, current record, etc.)
- The main worker (process 1) is sufficient and avoids wasting resources

## The `formula` Callback Pattern

### Callback Mechanisms in AI Kit

AI Kit provides two approaches for async callbacks:

#### Explicit callbacks (fine-grained)

```4dm
property onTerminate : 4D.Function  // fires when request completes
property onResponse : 4D.Function   // fires on success
property onError : 4D.Function      // fires on error
property onData : 4D.Function       // fires per streaming chunk (chat only)
```

#### Generic callback (unified)

```4dm
property formula : 4D.Function      // fires for every event
```

### Invocation Order

When both are assigned (not recommended), the order is:

1. **(if streaming)** `onData` → `formula` — repeats per chunk
2. **(on completion)** `onResponse` (if success) / `onError` (if failure)
3. `onTerminate` → `formula`

### Why Prefer `formula`

The `formula` approach is preferred because:
- It absorbs the difference between singular (non-streaming) and incremental (streaming) callbacks
- Streaming `onData` + `onTerminate` are two parts of the same feature — splitting them across separate functions requires coordinating shared state
- For non-streaming APIs (files, embeddings, models), there's only one response anyway
- One function handles the complete lifecycle, distinguished by `$result.terminated` and `$result.success`

## The `This` and `Form` Resolution

### `This` — Object-Bound (Stable)

`This` inside the callback is determined by what you pass to the parameters constructor:

```4dm
$Parameters:=cs.AIKit.OpenAIChatCompletionsParameters.new(This)
$Parameters.formula:=This.onEventStreamChat
```

Here, `This` (the class instance, e.g. `AIManager`) is passed to `.new()`. AI Kit stores it and invokes the formula on that object. So inside `onEventStreamChat`, `This` reliably references the AIManager.

### `Form` — Context-Dependent (Dynamic)

`Form` is a **function** (not an object) that resolves based on the current execution context:
- If a form dialog is loaded → returns the form's data object
- If the form was closed while HTTP was still running → returns `Null`

**Defensive pattern:**
```4dm
If (Form=Null)
    return 
End if 
```

This handles the edge case where the user closes the dialog before the response arrives. Commands like `WA EXECUTE JAVASCRIPT FUNCTION` silently fail when no form is present, but accessing `Form.property` would error.

## Streaming Chat Implementation

### AIManager Class Pattern

```4dm
property stream : Boolean
property _chatResult : Text

Class constructor()
    This.stream:=True
    This._chatResult:=""

Function onEventStreamChat($result : cs.AIKit.OpenAIChatCompletionsStreamResult)
    If ($result.success)
        If ($result.terminated)
            // Final result — stream complete
        Else 
            // Partial result — append chunk to UI
            If ($result.choice#Null)
                If ($result.choice.delta.text#"")
                    If (This._chatResult="")
                        // First chunk: create new bubble
                        WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "addAssistantMessage"; *; $result.choice.delta.text)
                    Else 
                        // Subsequent chunks: grow existing bubble
                        WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "appendAssistantMessage"; *; $result.choice.delta.text)
                    End if 
                    This._chatResult+=$result.choice.delta.text
                End if 
            End if 
        End if 
    Else 
        If ($result.terminated)
            // Error handling
        End if 
    End if 
```

### Chat Completion Call

```4dm
Function chatWithFile($prompt : Text)
    This._chatResult:=""
    
    var $Params : cs.AIKit.OpenAIChatCompletionsParameters
    $Params:=cs.AIKit.OpenAIChatCompletionsParameters.new(This)
    $Params.model:=This.model
    $Params.stream:=This.stream
    $Params.formula:=This.onEventStreamChat
    
    var $clientAI:=cs.AIKit.OpenAI.new()
    var $chatHelper:=$clientAI.chat.create($systemPrompt; $Params)
    
    // prompt() returns immediately — result arrives via callback
    $chatHelper.prompt($message)
```

### JavaScript Side (Web Area)

The web area needs an `appendAssistantMessage()` function to grow the last chat bubble:

```javascript
function appendAssistantMessage(chunk) {
    const lastBubble = /* find last assistant bubble */;
    if (!lastBubble) {
        appendBubble('assistant', chunk);
        return;
    }
    lastBubble._raw = (lastBubble._raw || '') + chunk;
    lastBubble.innerHTML = markdownToHtml(lastBubble._raw);
    messagesEl.scrollTop = messagesEl.scrollHeight;
}
```

## Async File Upload

```4dm
Function onEventStreamFile($fileResult : cs.AIKit.OpenAIChatCompletionsStreamResult)
    var $success : Boolean
    $success:=($fileResult.terminated) && ($fileResult.success)
    
    If (Form=Null)
        return 
    End if 
    
    If ($success)
        Form._fileInfo:=$fileResult.data
    Else 
        Form._fileInfo:=Null
    End if 

Function uploadFile($path : Text)
    var $file : 4D.File
    $file:=File($path; fk platform path)
    
    var $clientAI:=cs.AIKit.OpenAI.new({provider: This.provider})
    
    var $FileParameters : cs.AIKit.OpenAIFileParameters
    $FileParameters:=cs.AIKit.OpenAIFileParameters.new(This)
    $FileParameters.formula:=This.onEventStreamFile
    $FileParameters.expires_after:={anchor: "created_at"; seconds: 3600}
    
    // Returns immediately — result arrives via callback
    $clientAI.files.create($file; "user_data"; $FileParameters)
```

## Configuration

### AIProviders.json

Provider configuration is stored in `AIProviders.json` next to the active `settings.4DSettings` file. This file contains API keys and **must not be committed to source control**.

Configure via **Settings > AI** (introduced in [4D 21 R3](https://developer.4d.com/docs/21-R3/settings/ai)).

### Dependencies

AI Kit is managed via the Dependency Manager (`Project/Sources/dependencies.json`):

```json
{
    "dependencies": {
        "4D AIKit": {
            "github": "4d/4D-AIKit",
            "version": "4d"
        }
    }
}
```

`"version": "4d"` means "follow 4D version" — automatically selects the matching release. ([Blog: Follow 4D Version](https://blog.4d.com/follow-4d-version-a-smarter-way-to-manage-your-dependencies/))

## References

- [AI Kit Source Code](https://github.com/4d/4D-AIKit)
- [AI Kit Async Documentation](https://github.com/4d/4D-AIKit/blob/main/Documentation/asynchronous-call.md)
- [4D 21 R3 AI Settings](https://developer.4d.com/docs/21-R3/settings/ai)
- [Dependency Manager (20 R6)](https://blog.4d.com/integrate-4d-components-directly-from-github/)
- [Follow 4D Version (20 R9)](https://blog.4d.com/follow-4d-version-a-smarter-way-to-manage-your-dependencies/)
