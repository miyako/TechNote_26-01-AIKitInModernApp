// Object Method: btnSendChat

var $html : Text  // Declare at method level

Case of 
	: (Form event code:C388=On Clicked:K2:4)
		var $userMessage : Text
		
		$userMessage:=Form:C1466.chatInput
		
		If (Form:C1466.selectedDoc#Null:C1517) & ($userMessage#"")
			
			// Add user message to collection
			var $timestamp : Text
			$timestamp:=String:C10(Current date:C33; Internal date short special:K1:4)+" "+String:C10(Current time:C178; HH MM:K7:2)
			Form:C1466.chatMessages.push(New object:C1471("role"; "user"; "message"; $userMessage; "timestamp"; $timestamp))  // Add temporary "thinking" indicator with random variation
			var $thinkingMessages : Collection
			$thinkingMessages:=New collection:C1472("💭 Thinking..."; "🤔 Processing..."; "⚡ Analyzing..."; "🔍 Examining..."; "✨ Generating response...")
			var $randomThinking : Text
			$randomThinking:=$thinkingMessages[Random:C100%$thinkingMessages.length]
			Form:C1466.chatMessages.push(New object:C1471("role"; "assistant"; "message"; $randomThinking; "timestamp"; ""; "isTemporary"; True:C214))
			
			// Update web area display with thinking indicator
			$html:=_renderChatHTML(Form:C1466.chatMessages)
			WA SET PAGE CONTENT:C1037(*; "chatMessages"; $html; "")
			
			// Clear input
			Form:C1466.chatInput:=""
			
			// Store message count before sending to detect response
			Form:C1466.chatMessageCountBefore:=Form:C1466.chatMessages.length
			
			// Send message asynchronously
			CALL WORKER:C1389("ChatWorker-"+Form:C1466.selectedDoc.UUID; "_asyncSendChatMessage"; Form:C1466.selectedDoc.UUID; $userMessage)
			
			// Start timer to poll for response
			Form:C1466.waitingForChat:=True:C214
			SET TIMER:C645(120)  // 2 seconds
		End if 
		
End case 