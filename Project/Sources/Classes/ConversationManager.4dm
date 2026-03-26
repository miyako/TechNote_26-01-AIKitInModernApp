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

Class constructor
	This:C1470.config:=cs:C1710.AIConfig.me
	This:C1470.client:=This:C1470.config.getClient()
	
	// Constants
	This:C1470.MAX_TOKENS:=1000
	This:C1470.TEMPERATURE:=0.5
	
Function sendMessage($docID : Text; $userMessage : Text)->$response : Object
	var $conv : cs:C1710.ConversationEntity
	var $history : Collection
	var $result : Object
	
	$response:=New object:C1471("success"; False:C215; "message"; ""; "error"; "")
	
	// Get or create conversation
	$conv:=This:C1470._getOrCreateConversation($docID)
	
	If ($conv#Null:C1517)
		// Load and update message history
		$history:=JSON Parse:C1218($conv.messageHistory)
		
		If ($history#Null:C1517)
			// Add user message
			$history.push(New object:C1471("role"; "user"; "content"; $userMessage))
			This:C1470._updateConversation($conv; $history)
			
			// Get AI response
			$result:=This:C1470._callAI($history)
			
			// Process result
			If ($result.success)
				$history.push(New object:C1471("role"; "assistant"; "content"; $result.choice.message.content))
				This:C1470._updateConversation($conv; $history)
				
				$response.success:=True:C214
				$response.message:=$result.choice.message.content
			Else 
				$response.error:=$result.errors.length>0 ? $result.errors[0] : "Unknown error"
			End if 
		Else 
			$response.error:="Invalid conversation history"
		End if 
	Else 
		$response.error:="Failed to create conversation"
	End if 
	
	return $response
	
	
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
	
	
Function _callAI($history : Collection)->$result : Object
	var $params : Object
	
	$params:=New object:C1471(\
		"model"; This:C1470.config.defaultModel; \
		"max_tokens"; This:C1470.MAX_TOKENS; \
		"temperature"; This:C1470.TEMPERATURE)
	
	$result:=This:C1470.client.chat.completions.create($history; $params)
	
	return $result