// Delete selected document
Case of 
	: (FORM Event:C1606.code=On Clicked:K2:4)
		If (Form:C1466.selectedDoc#Null:C1517)
			// Show confirmation dialog
			var $message : Text
			$message:="Delete document '"+Form:C1466.selectedDoc.fileName+"'? This action cannot be undone."
			CONFIRM:C162($message; "Delete"; "Cancel")
			
			If (ok=1)  // Delete confirmed
				var $docID : Text
				var $tempFolder : 4D:C1709.Folder
				var $tempFile : 4D:C1709.File
				
				$docID:=Form:C1466.selectedDoc.UUID
				
				
				// Delete related records (cascade delete)
				var $extractedData : cs:C1710.ExtractedDataSelection
				$extractedData:=ds:C1482.ExtractedData.query("documentID = :1"; $docID)
				$extractedData.drop()
				
				var $summaries : cs:C1710.SummariesSelection
				$summaries:=ds:C1482.Summaries.query("documentID = :1"; $docID)
				$summaries.drop()
				
				var $conversations : cs:C1710.ConversationSelection
				$conversations:=ds:C1482.Conversation.query("documentID = :1"; $docID)
				$conversations.drop()
				
				// Delete document entity
				Form:C1466.selectedDoc.drop()
				
				// Refresh document list
				Form:C1466.documents:=ds:C1482.Document.all().orderBy("uploadDate desc")
				Form:C1466.selectedDoc:=Null:C1517
				Form:C1466.extractedDataArea:=""
				
				// Clear summary web area
				var $emptyHTML : Text
				$emptyHTML:=_renderSummaryHTML("<div style='text-align:center;padding:40px;color:#9ca3af'>No document selected</div>")
				WA SET PAGE CONTENT:C1037(*; "summaryText"; $emptyHTML; "")
				
				// Clear chat web area
				Form:C1466.chatMessages:=New collection:C1472()
				Form:C1466.chatDisplay:=""
				var $emptyChatHTML : Text
				$emptyChatHTML:=_renderChatHTML(Form:C1466.chatMessages)
				WA SET PAGE CONTENT:C1037(*; "chatMessages"; $emptyChatHTML; "")
				
				// Clear preview
				WA OPEN URL:C1020(*; "previewArea"; "about:blank")
				ALERT:C41("Document and all related data deleted successfully")
			End if 
		Else 
			ALERT:C41("Please select a document to delete")
		End if 
End case 