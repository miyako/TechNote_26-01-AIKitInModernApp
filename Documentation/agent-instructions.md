# Instructions: Convert Synchronous AI Kit to Asynchronous Implementation

## Objective

Transform a 4D project that uses **synchronous** AI Kit calls (blocking the UI) into one that uses **asynchronous** callbacks with streaming support. The UI should display LLM responses token-by-token as they arrive.

## Prerequisites

- The project uses AI Kit (`cs.AIKit.OpenAI`) for file upload and chat completions
- The project has a form with a web area displaying a chat interface
- The project has an `AIManager` class (or similar) that wraps AI Kit calls

## Step-by-Step Instructions

### Step 1: Modify the AIManager Class

#### 1.1 Add Properties

Add these properties at the top of the class:

```4dm
property stream : Boolean
property provider : Text
property model : Text
property _chatResult : Text
property _onResponse : 4D.Function
```

#### 1.2 Add a Constructor

```4dm
Class constructor()
    This.provider:="openai"
    This.model:="chat-reasoning"
    This.stream:=True
    This._chatResult:=""
```

#### 1.3 Convert `uploadFile` to Async

**Before (synchronous):**
```4dm
Function uploadFile($path : 4D.File)
    var $clientAI:=cs.AIKit.OpenAI.new({provider: "OpenAI Provider"})
    var $createRes:=$clientAI.files.create($path; "user_data"; {expires_after: ...})
    If ($createRes.success)
        This._fileInfo:=$createRes.file
        return True
    End if 
    return False
```

**After (asynchronous):**
```4dm
Function uploadFile($path : Text)
    var $file : 4D.File
    $file:=File($path; fk platform path)
    
    var $clientAI:=cs.AIKit.OpenAI.new({provider: This.provider})
    
    var $FileParameters : cs.AIKit.OpenAIFileParameters
    $FileParameters:=cs.AIKit.OpenAIFileParameters.new(This)
    $FileParameters.formula:=This.onEventStreamFile
    $FileParameters.expires_after:={anchor: "created_at"; seconds: 3600}
    $FileParameters.extraHeaders:={name: $file.fullName}
    
    $clientAI.files.create($file; "user_data"; $FileParameters)
```

Key changes:
- Parameter changes from `4D.File` to `Text` (platform path)
- Uses `OpenAIFileParameters` with `.formula` callback
- No return value — result arrives via callback
- Pass `This` to parameter constructor so the callback can access the AIManager instance

#### 1.4 Add the File Upload Callback

```4dm
Function onEventStreamFile($fileResult : cs.AIKit.OpenAIChatCompletionsStreamResult)
    var $success : Boolean
    $success:=($fileResult.terminated) && ($fileResult.success)
    
    If (Form=Null)
        return 
    End if 
    
    var $name : Text
    $name:=$fileResult.request.headers.name
    
    If ($success)
        Form._fileInfo:=$fileResult.data
        WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "addAssistantMessage"; $success; "The file "+$name+" has been uploaded successfully.")
        OBJECT SET ENABLED(*; "Button"; True)
    Else 
        Form._fileInfo:=Null
        WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "addAssistantMessage"; $success; "Upload failed.")
    End if 
```

Key points:
- Check `Form=Null` defensively (form may have been closed)
- Store file info on `Form._fileInfo` (not `This._fileInfo`) so it's accessible to all form objects
- The file name is retrieved from `$fileResult.request.headers.name` (set via `extraHeaders`)
- **Important principle**: Any logic that previously followed the synchronous call (e.g., enabling a button, updating UI state, triggering the next step) must now be moved into the callback. Since the async call returns immediately, code after it executes *before* the result arrives. The callback is the only place where you know the operation has completed.

#### 1.5 Convert `chatWithFile` to Async

**Before (synchronous):**
```4dm
Function chatWithFile($myPrompt : Text) : Text
    If (This._fileInfo=Null)
        return "No File uploaded"
    End if 
    var $clientAI:=cs.AIKit.OpenAI.new()
    var $chatHelper:=$clientAI.chat.create($firstPrompt; {model: "model openai"})
    var $message:=cs.AIKit.OpenAIMessage.new({role: "user"; content: $myPrompt})
    $message.addFileId(This._fileInfo.id)
    $response:=$chatHelper.prompt($message)
    If ($response.success)
        return $response.choice.message.text
    End if 
```

**After (asynchronous):**
```4dm
Function chatWithFile($myPrompt : Text) : Text
    If (Form._fileInfo=Null)
        return "No File uploaded"
    End if 
    
    This._chatResult:=""
    
    var $ChatCompletionsParameters : cs.AIKit.OpenAIChatCompletionsParameters
    $ChatCompletionsParameters:=cs.AIKit.OpenAIChatCompletionsParameters.new(This)
    $ChatCompletionsParameters.model:=This.model
    $ChatCompletionsParameters.stream:=This.stream
    $ChatCompletionsParameters.formula:=This.onEventStreamChat
    
    var $clientAI:=cs.AIKit.OpenAI.new()
    
    var $firstPrompt : Text
    $firstPrompt:="You are an assistant specializing in file analysis and parsing. Before we begin, several files have been uploaded to the server."
    $firstPrompt+=" Your task is to read and analyze these files, then extract the requested information."
    $firstPrompt+=" You must return a response in text format that I can display directly in a web browser without Markdown tags or ```. The pictures are not allowed in the response"
    
    var $chatHelper:=$clientAI.chat.create($firstPrompt; $ChatCompletionsParameters)
    
    var $message:=cs.AIKit.OpenAIMessage.new({role: "user"; content: $myPrompt})
    $message.addFileId(Form._fileInfo.id)
    
    $chatHelper.prompt($message)
```

Key changes:
- Reset `This._chatResult:=""` before each call
- Use `OpenAIChatCompletionsParameters` with `.stream:=True` and `.formula` callback
- Pass `This` to parameter constructor
- File info is read from `Form._fileInfo` (not `This._fileInfo`)
- No return value from `prompt()` — result arrives via callback
- Remove the `If ($response.success)` block — handled in callback

#### 1.6 Add the Chat Streaming Callback

```4dm
Function onEventStreamChat($chatCompletionsResult : cs.AIKit.OpenAIChatCompletionsStreamResult)
    If ($chatCompletionsResult.success)
        If ($chatCompletionsResult.terminated)
            // Stream complete — handle final result if needed
            If ($chatCompletionsResult.choice#Null)
                If ($chatCompletionsResult.choice.message=Null)
                    // Was streaming: reconstruct final message
                    $chatCompletionsResult:=JSON Parse(JSON Stringify($chatCompletionsResult))
                    $chatCompletionsResult.choice.message:={role: "assistant"; content: This._chatResult}
                Else 
                    // Was NOT streaming: display full message
                    If ($chatCompletionsResult.choice.message.content#Null)
                        This._chatResult+=$chatCompletionsResult.choice.message.content
                        WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "addAssistantMessage"; *; This._chatResult)
                    End if 
                End if 
            End if 
        Else 
            // Partial result — streaming chunk
            If ($chatCompletionsResult.choice#Null)
                If ($chatCompletionsResult.choice.delta.text#"")
                    If (This._chatResult="")
                        If (Form#Null)
                            // First chunk: create new bubble
                            WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "addAssistantMessage"; *; $chatCompletionsResult.choice.delta.text)
                        End if 
                    Else 
                        // Subsequent chunks: grow existing bubble
                        WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "appendAssistantMessage"; *; $chatCompletionsResult.choice.delta.text)
                    End if 
                    This._chatResult+=$chatCompletionsResult.choice.delta.text
                End if 
            End if 
        End if 
    Else 
        If ($chatCompletionsResult.terminated)
            // Error occurred
            This._chatResult+=$chatCompletionsResult.errors.extract("message").join("\r")
        End if 
    End if 
```

### Step 2: Update the Form Object Methods

#### 2.1 Analyze/Upload Button (was synchronous, now async)

**Before:**
```4dm
var $path:=File(Form.pdfPath; fk platform path)
var $result:=Form.aiManager.uploadFile($path)
If ($result)
    WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "addAssistantMessage"; $result; "The file "+$path.name+" has been uploaded successfully.")
Else 
    WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "addAssistantMessage"; $result; "Upload failed.")
End if 
```

**After:**
```4dm
If (FORM Event.code=On Clicked)
    Form.aiManager.uploadFile(Form.pdfPath)
End if 
```

Key changes:
- UI feedback is now handled in the callback, not here
- Just pass the path as Text — the AIManager converts it to a File
- Guard with `FORM Event.code` check

#### 2.2 Send/Chat Button (was synchronous, now async)

**Before:**
```4dm
WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "addUserMessage"; $result; Form.prompt)
var $response : Text:=Form.aiManager.chatWithFile(Form.prompt)
WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "addAssistantMessage"; $result; $response)
Form.prompt:=""
```

**After:**
```4dm
WA EXECUTE JAVASCRIPT FUNCTION(*; "web area"; "addUserMessage"; *; Form.prompt)
Form.aiManager.chatWithFile(Form.prompt)
Form.prompt:=""
```

Key changes:
- Remove the assistant message display — handled by streaming callback
- The `*` parameter in `WA EXECUTE JAVASCRIPT FUNCTION` means "no return value expected"
- `chatWithFile` no longer returns a value

### Step 3: Update the HTML Chat Interface

Add an `appendAssistantMessage` JavaScript function to support streaming:

```javascript
function appendAssistantMessage(chunk) {
    const rows = messagesEl.children;
    const lastRow = rows[rows.length - 1];
    const lastBubble = lastRow ? lastRow.querySelector('.bubble.assistant') : null;

    if (!lastBubble) {
        appendBubble('assistant', chunk);
        return;
    }

    // Accumulate raw markdown and re-render (handles split tokens like ``` or **)
    lastBubble._raw = (lastBubble._raw || '') + chunk;
    lastBubble.innerHTML = markdownToHtml(lastBubble._raw);

    messagesEl.scrollTop = messagesEl.scrollHeight;
}
```

Also modify `appendBubble` to store `_raw` on new assistant bubbles and return the bubble element:

```javascript
function appendBubble(role, content) {
    // ... existing code to create the row ...
    const bubble = row.querySelector('.bubble');
    if (role === 'assistant') bubble._raw = content;
    messagesEl.appendChild(row);
    messagesEl.scrollTop = messagesEl.scrollHeight;
    return bubble;
}
```

### Step 4: Update the Form Load Method

Ensure the form initialization:
1. Creates the AIManager: `Form.aiManager:=cs.AIManager.new()`
2. Sets the web area context: `WA SET CONTEXT(*; "web area"; Form.aiManager)`
3. Opens the chat URL: `WA OPEN URL(*; "web area"; "http://localhost/chat2.htm")`

Note: `WA SET CONTEXT` is required for the web area to access the 4D object context, but it is **not** what makes the callbacks work — that's the event loop.

### Step 5: Create a Launcher Method

Create a project method to open the form correctly for async callbacks:

```4dm
// Method: OpenAIChat
If (Count parameters=0)
    CALL WORKER(1; Current method name; True)
Else 
    var $window : Integer
    $window:=Open form window("Demo_4D_AIKit"; Plain form window)
    DIALOG("Demo_4D_AIKit"; *)
End if 
```

This uses the recursive worker pattern:
- First call dispatches to the main worker (process 1)
- Second call opens the non-modal dialog
- `DIALOG(*)` is async — the runtime manages the window
- Do **NOT** add `CLOSE WINDOW`

## Common Pitfalls

1. **Modal dialog blocks callbacks** — Always use `DIALOG("form"; *)` (with the `*`), never without
2. **Creating unnecessary workers** — Process 1 (main worker) is sufficient; don't create named workers for simple dialogs
3. **Accessing `Form` without null check** — The form may close before HTTP completes
4. **Storing state on `This` instead of `Form`** — File info should be on `Form` so all form objects can access it
5. **Expecting a return value** — Async methods don't return results; they fire callbacks
6. **Closing the window manually** — `DIALOG(*)` windows are managed by the runtime; `CLOSE WINDOW` will error
7. **Forgetting to reset `_chatResult`** — Must be cleared to `""` before each new chat call so the first-chunk detection works

## File Checklist

After conversion, your project should have:

- [ ] `Project/Sources/Classes/AIManager.4dm` — with constructor, properties, `formula` callbacks, async `uploadFile` and `chatWithFile`
- [ ] `Project/Sources/Forms/<form>/ObjectMethods/Analyze.4dm` — simplified to just call `uploadFile`
- [ ] `Project/Sources/Forms/<form>/ObjectMethods/Button.4dm` — simplified to just call `chatWithFile`
- [ ] `WebFolder/chat2.htm` — with `appendAssistantMessage()` function added
- [ ] `Project/Sources/Methods/OpenAIChat.4dm` — launcher method with `CALL WORKER(1;...)` + `DIALOG(*)`
- [ ] Form method — initializes `Form.aiManager`, sets web area context
