# Asynchronous AI Kit Implementation — Documentation

## Overview

This document describes how to convert synchronous 4D AI Kit (`cs.AIKit.OpenAI`) calls to asynchronous streaming implementations. The async pattern uses callback functions (`formula`) that receive streaming chunks, enabling token-by-token display of LLM responses.

## References

- [AI Kit OpenAIChatCompletionsParameters](https://developer.4d.com/docs/aikit/Classes/openaichatcompletionsparameters) — properties for chat completions including `stream`, `model`, `max_completion_tokens`, `temperature`
- [AI Kit OpenAIParameters](https://developer.4d.com/docs/aikit/Classes/openaiparameters) — base class with `formula`/`onTerminate`, `onResponse`, `onError`, `extraHeaders`, `timeout`
- [AI Kit OpenAIVision](https://developer.4d.com/docs/aikit/Classes/openaivision#fromfile) — `fromFile(imageFile : 4D.File) : OpenAIVisionHelper`
- [AI Kit OpenAIVisionHelper](https://developer.4d.com/docs/aikit/Classes/openaivisionhelper) — `prompt(prompt: Text; parameters: OpenAIChatCompletionsParameters)`
- [AI Kit Asynchronous Call Documentation](https://developer.4d.com/docs/aikit/asynchronous-call)

## Key Concepts

### 1. OpenAIChatCompletionsParameters

The parameters object controls async behavior:

```4d
var $params : cs.AIKit.OpenAIChatCompletionsParameters
$params:=cs.AIKit.OpenAIChatCompletionsParameters.new(This)
$params.model:="gpt-4o"
$params.max_completion_tokens:=1000     // NOT "max_tokens"
$params.temperature:=0.5
$params.stream:=True                     // Enable streaming
$params.formula:=This.myCallback         // Callback function reference
$params.extraHeaders:={myKey: "myValue"} // Pass context to callback
```

**Important**: The first argument to `.new()` is `This` — the object whose method is referenced by `.formula`.

### 2. Property Names (Validated)

| Property | Type | Description |
|----------|------|-------------|
| `model` | Text | Model ID (e.g., "gpt-4o-mini") |
| `stream` | Boolean | Enable streaming (requires formula callback) |
| `max_completion_tokens` | Integer | Max tokens in completion |
| `temperature` | Real | Sampling temperature (0-2) |
| `formula` | 4D.Function | Callback function |
| `extraHeaders` | Object | Custom data accessible in callback via `$result.request.headers` |

**⚠️ `max_tokens` is NOT a valid property.** Use `max_completion_tokens`.

### 3. Callback Function Signature

```4d
Function myCallback($result : cs.AIKit.OpenAIChatCompletionsStreamResult)
```

The `$result` object has these key properties:
- `.success` — Boolean, whether this event represents success
- `.terminated` — Boolean, whether this is the final event
- `.choice` — Object (may be Null), contains delta or message
- `.choice.delta.text` — Text chunk during streaming (non-terminated events)
- `.choice.message` — Object, full message (only on non-streaming terminated events)
- `.choice.message.content` — Full text (non-streaming response)
- `.request.headers` — Object, the `extraHeaders` you passed
- `.errors` — Collection of error objects (when success=False)

### 4. Streaming Event Flow

```
Event 1: success=True, terminated=False, choice.delta.text="Hello"
Event 2: success=True, terminated=False, choice.delta.text=" world"
...
Event N: success=True, terminated=True, choice=Null (or choice.message=Null)
```

The final terminated event may NOT include a `choice` object (it may only contain usage data). Always call `renderFinal()` or equivalent unconditionally when `terminated=True`.

### 5. Vision API Differences

For `chat.vision.fromFile()`:
- `fromFile()` takes ONLY the file: `$helper:=client.chat.vision.fromFile($file)`
- Parameters go to `prompt()`: `$helper.prompt($prompt; $ChatCompletionsParameters)`

**Wrong**: `client.chat.vision.fromFile($file; $params)`
**Correct**: `client.chat.vision.fromFile($file)` then `helper.prompt($text; $params)`

### 6. Non-Modal Dialog Pattern

For callbacks to fire, the form must run in a non-modal dialog:

```4d
If (Count parameters=0)
    CALL WORKER(1; Current method name; True)
Else
    var $win : Integer
    $win:=Open form window("MyForm"; Plain form window)
    DIALOG("MyForm"; *)
End if
```

- `DIALOG("form"; *)` — the `*` makes it non-modal/async
- Do NOT add `CLOSE WINDOW` — the runtime manages the window
- Do NOT use named workers for simple cases — process 1 is sufficient

### 7. Web Area Updates

**Never use `WA SET PAGE CONTENT` on a web area that has been loaded with `WA OPEN URL`** — it replaces the entire page including JavaScript functions.

Instead, use `WA EXECUTE JAVASCRIPT FUNCTION`:
```4d
WA EXECUTE JAVASCRIPT FUNCTION(*; "webAreaName"; "jsFunctionName"; *; $textArgument)
```

The `*` before the text argument means "no return value expected."

### 8. Streaming HTML Content

When the AI returns HTML (e.g., summaries), displaying partial HTML with `textContent` shows raw tags. Instead:

- Use `innerHTML` during streaming — browsers auto-close unclosed tags
- Create a persistent HTML file loaded via `WA OPEN URL` with JS functions
- Functions: `setContent(text)`, `appendContent(chunk)`, `renderFinal()`, `setRenderedHTML(html)`

### 9. Streaming Plain Text (e.g., extractedDataArea)

For text areas (not web areas), use `HIGHLIGHT TEXT` to auto-scroll:
```4d
Form.extractedDataArea:=This._visionResult
var $start; $end : Integer
$start:=Length(Form.extractedDataArea)+1
$end:=$start
HIGHLIGHT TEXT(*; "extractedDataArea"; $start; $end)
```

## Common Pitfalls

1. **Inventing token suffixes** — Never guess `:C...` or `:K...` suffixes. Write commands/constants as plain names; the IDE adds suffixes automatically.
2. **Using `max_tokens`** — The property is `max_completion_tokens`.
3. **Passing params to `fromFile()`** — Parameters go to `prompt()`, not `fromFile()`.
4. **Using `WA SET PAGE CONTENT` after `WA OPEN URL`** — Destroys the page's JS context.
5. **Gating `renderFinal()` behind `choice#Null`** — The final terminated event may not include a choice.
6. **Using `CALL WORKER` + timer polling** — Not needed with true async callbacks. Call the method directly in the form's execution context.
7. **Modal dialogs** — Block the event loop. Use `DIALOG("form"; *)` for async callbacks to fire.
8. **Expecting return values** — Async methods don't return results. Move post-call logic into the callback.
