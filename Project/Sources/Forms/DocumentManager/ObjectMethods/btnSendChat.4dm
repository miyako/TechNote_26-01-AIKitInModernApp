// Object Method: btnSendChat

Case of 
	: (Form event code:C388=On Clicked:K2:4)
		var $userMessage : Text
		
		$userMessage:=Form:C1466.chatInput
		
		If (Form:C1466.selectedDoc#Null:C1517) & ($userMessage#"")
			
			// Add user message to web area
			WA EXECUTE JAVASCRIPT FUNCTION:C1043(*; "chatMessages"; "addUserMessage"; *; $userMessage)
			
			// Clear input
			Form:C1466.chatInput:=""
			
			// Send message asynchronously (streaming callback handles response display)
			If (Form:C1466.convManager=Null:C1517)
				Form:C1466.convManager:=cs:C1710.ConversationManager.new()
			End if 
			Form:C1466.convManager.sendMessage(Form:C1466.selectedDoc.UUID; $userMessage)
		End if 
		
End case