// ----------------------------------------------------
// User name (OS): Soukaina BACHIKH
// Date and time: 01/13/26, 17:01:58
// ----------------------------------------------------
// Method: ConversationManager
// Description
//      Manages the chatbot
// ----------------------------------------------------


property config : cs:C1710.AIConfig
property client : cs:C1710.AIKit.OpenAI
property MAX_TOKENS : Integer
property TEMPERATURE : Real
property stream : Boolean
property _chatResult : Text

Class constructor
	This:C1470.config:=cs:C1710.AIConfig.me
	This:C1470.client:=This:C1470.config.getClient()
	
	// Constants
	This:C1470.MAX_TOKENS:=1000
	This:C1470.TEMPERATURE:=0.5
	This:C1470.stream:=True:C214
	This:C1470._chatResult:=""
	
Function sendMessage($docID : Text; $userMessage : Text)
	var $conv : cs:C1710.ConversationEntity
	var $history : Collection
	
	// Get or create conversation
	$conv:=This:C1470._getOrCreateConversation($docID)
	
	If ($conv#Null:C1517)
		// Load and update message history
		$history:=JSON Parse:C1218($conv.messageHistory)
		
		If ($history#Null:C1517)
			// Add user message
			$history.push(New object:C1471("role"; "user"; "content"; $userMessage))
			This:C1470._updateConversation($conv; $history)
			
			// Get AI response asynchronously (callback handles result)
			This:C1470._callAI($history)
		End if 
	End if
	
	
	// MARK: - Helper Functions
	
Function _getOrCreateConversation($docID : Text)->$conv : cs:C1710.ConversationEntity
	$conv:=ds:C1482.Conversation.query("documentID = :1"; $docID).first()
	
	If ($conv=Null:C1517)
		$conv:=This:C1470._createNewConversation($docID)
	End if 
	
	return $conv
	
	
Function _createNewConversation($docID : Text)->$conv : cs:C1710.ConversationEntity
	var $systemMessage : Text
	var $history : Collection
	
	$conv:=ds:C1482.Conversation.new()
	$conv.documentID:=$docID
	$conv.startDate:=Current date:C33
	$conv.startTime:=Current time:C178
	$conv.messageCount:=0
	
	// Build and save system message
	$systemMessage:=This:C1470._buildSystemMessage($docID)
	$history:=New collection:C1472
	$history.push(New object:C1471("role"; "system"; "content"; $systemMessage))
	$conv.messageHistory:=JSON Stringify:C1217($history)
	
	return $conv
	
	
Function _buildSystemMessage($docID : Text)->$systemMessage : Text
	var $doc : cs:C1710.DocumentEntity
	var $extData : cs:C1710.ExtractedDataEntity
	
	$systemMessage:="You are a helpful assistant that answers questions about business documents. "
	
	If ($docID#"")
		$doc:=ds:C1482.Document.query("UUID = :1"; $docID).first()
		$extData:=ds:C1482.ExtractedData.query("documentID = :1"; $docID).first()
		
		If ($doc#Null:C1517) & ($extData#Null:C1517)
			$systemMessage:=$systemMessage+"You have access to the following document information:\\n\\n"
			$systemMessage:=$systemMessage+"Document: "+$doc.fileName+" (Type: "+$doc.documentType+")\\n\\n"
			$systemMessage:=$systemMessage+"Extracted Data:\\n"+_buildDocumentContext($extData)+"\\n"
		End if 
	End if 
	
	$systemMessage:=$systemMessage+"Answer questions based on this information. If information is not available, "
	$systemMessage:=$systemMessage+"say so rather than making assumptions. Be concise and professional."
	
	return $systemMessage
	
	
Function _updateConversation($conv : cs:C1710.ConversationEntity; $history : Collection)
	$conv.messageHistory:=JSON Stringify:C1217($history)
	$conv.messageCount:=$conv.messageCount+1
	$conv.lastMessageDate:=Current date:C33
	$conv.lastMessageTime:=Current time:C178
	$conv.save()
	
	
Function _callAI($history : Collection)
	var $ChatCompletionsParameters : cs:C1710.AIKit.OpenAIChatCompletionsParameters
	$ChatCompletionsParameters:=cs:C1710.AIKit.OpenAIChatCompletionsParameters.new(This:C1470)
	$ChatCompletionsParameters.model:=This:C1470.config.defaultModel
	$ChatCompletionsParameters.max_completion_tokens:=This:C1470.MAX_TOKENS
	$ChatCompletionsParameters.temperature:=This:C1470.TEMPERATURE
	$ChatCompletionsParameters.stream:=This:C1470.stream
	$ChatCompletionsParameters.formula:=This:C1470.onEventStreamChat
	
	This:C1470._chatResult:=""
	
	This:C1470.client.chat.completions.create($history; $ChatCompletionsParameters)
	
	
Function onEventStreamChat($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsStreamResult)
	If ($chatCompletionsResult.success)
		If ($chatCompletionsResult.terminated)
			// Stream complete
			If ($chatCompletionsResult.choice#Null:C1517)
				If ($chatCompletionsResult.choice.message=Null:C1517)
					// Was streaming: reconstruct final message
					$chatCompletionsResult:=JSON Parse:C1218(JSON Stringify:C1217($chatCompletionsResult))
					$chatCompletionsResult.choice.message:={role: "assistant"; content: This:C1470._chatResult}
				Else 
					// Was NOT streaming: display full message
					If ($chatCompletionsResult.choice.message.content#Null:C1517)
						This:C1470._chatResult:=This:C1470._chatResult+$chatCompletionsResult.choice.message.content
						If (Form:C1466#Null:C1517)
							WA EXECUTE JAVASCRIPT FUNCTION:C1043(*; "chatMessages"; "addAssistantMessage"; *; This:C1470._chatResult)
						End if 
					End if 
				End if 
			End if 
			// Update conversation history in database
			If (Form:C1466#Null:C1517)
				If (Form:C1466.selectedDoc#Null:C1517)
					var $conv : cs:C1710.ConversationEntity
					$conv:=ds:C1482.Conversation.query("documentID = :1"; Form:C1466.selectedDoc.UUID).first()
					If ($conv#Null:C1517)
						var $msgHistory : Collection
						$msgHistory:=JSON Parse:C1218($conv.messageHistory)
						If ($msgHistory#Null:C1517)
							$msgHistory.push(New object:C1471("role"; "assistant"; "content"; This:C1470._chatResult))
							$conv.messageHistory:=JSON Stringify:C1217($msgHistory)
							$conv.messageCount:=$conv.messageCount+1
							$conv.lastMessageDate:=Current date:C33
							$conv.lastMessageTime:=Current time:C178
							$conv.save()
						End if 
					End if 
				End if 
				Form:C1466.waitingForChat:=False:C215
			End if 
		Else 
			// Partial result — streaming chunk
			If ($chatCompletionsResult.choice#Null:C1517)
				If ($chatCompletionsResult.choice.delta.text#"")
					If (This:C1470._chatResult="")
						If (Form:C1466#Null:C1517)
							// First chunk: create new bubble
							WA EXECUTE JAVASCRIPT FUNCTION:C1043(*; "chatMessages"; "addAssistantMessage"; *; $chatCompletionsResult.choice.delta.text)
						End if 
					Else 
						If (Form:C1466#Null:C1517)
							// Subsequent chunks: grow existing bubble
							WA EXECUTE JAVASCRIPT FUNCTION:C1043(*; "chatMessages"; "appendAssistantMessage"; *; $chatCompletionsResult.choice.delta.text)
						End if 
					End if 
					This:C1470._chatResult:=This:C1470._chatResult+$chatCompletionsResult.choice.delta.text
				End if 
			End if 
		End if 
	Else 
		If ($chatCompletionsResult.terminated)
			// Error occurred
			This:C1470._chatResult:=$chatCompletionsResult.errors.extract("message").join("\r")
			If (Form:C1466#Null:C1517)
				WA EXECUTE JAVASCRIPT FUNCTION:C1043(*; "chatMessages"; "addAssistantMessage"; *; "❌ Error: "+This:C1470._chatResult)
				Form:C1466.waitingForChat:=False:C215
			End if 
		End if 
	End if