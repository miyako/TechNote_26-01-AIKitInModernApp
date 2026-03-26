// Form Method: DocumentManager

Case of 
	: (Form event code:C388=On Load:K2:1)
		// Initialize form
		Form:C1466.documents:=ds:C1482.Document.all().orderBy("uploadDate desc")
		Form:C1466.selectedDoc:=Null:C1517
		Form:C1466.summaryText:=""
		Form:C1466.summaryHTML:=""
		Form:C1466.summaryType:="Brief"
		Form:C1466.chatMessages:=New collection:C1472
		Form:C1466.chatDisplay:=""
		Form:C1466.chatInput:=""
		Form:C1466.processing:=False:C215
		Form:C1466.processingStartTime:=0
		Form:C1466.processingDocID:=""
		Form:C1466.extractedDataArea:=""  // Initialize summary generation tracking
		Form:C1466.generatingSummary:=False:C215
		Form:C1466.generatingSummaryDoc:=""
		Form:C1466.generatingSummaryType:=""
		
		// Initialize chat waiting flag
		Form:C1466.waitingForChat:=False:C215
		
		
		
	: (Form event code:C388=On Timer:K2:25)
		
		// Poll for document analysis completion
		If (Form:C1466.processingDocID#"")
			var $doc : cs:C1710.DocumentEntity
			$doc:=ds:C1482.Document.get(Form:C1466.processingDocID)
			
			If ($doc=Null:C1517)
				Form:C1466.processingDocID:=""  // Document deleted
			End if 
			
			If (($doc#Null:C1517) & (($doc.status="Processed") | ($doc.status="Error")))
				// Processing complete
				Form:C1466.processingDocID:=""
				Form:C1466.selectedDoc:=$doc
				
				// Reload and refresh UI
				Form:C1466.documents:=ds:C1482.Document.all().orderBy("uploadDate desc")
				OBJECT SET VISIBLE:C603(*; "listDocuments"; False:C215)
				OBJECT SET VISIBLE:C603(*; "listDocuments"; True:C214)
				
				// Handle results
				If ($doc.status="Processed")
					var $extData : cs:C1710.ExtractedDataEntity
					$extData:=ds:C1482.ExtractedData.query("documentID = :1"; $doc.UUID).first()
					
					If ($extData=Null:C1517)
						Form:C1466.extractedDataArea:="❌ No extracted data found"
					Else 
						Form:C1466.extractedDataArea:=_displayExtractedData($extData)
						
						// Start monitoring for Brief summary (auto-generated)
						Form:C1466.generatingSummary:=True:C214
						Form:C1466.generatingSummaryDoc:=$doc.UUID
						Form:C1466.generatingSummaryType:="Brief"
					End if 
				Else 
					Form:C1466.extractedDataArea:="❌ ERROR\n\n"+$doc.statusMessage
				End if 
			End if 
		End if   // Poll for summary generation completion
		If (Form:C1466.generatingSummary)
			var $summary : cs:C1710.SummariesEntity
			$summary:=ds:C1482.Summaries.query("documentID = :1 AND summaryType = :2"; Form:C1466.generatingSummaryDoc; Form:C1466.generatingSummaryType).first()
			
			If ($summary#Null:C1517)
				// Summary generated
				Form:C1466.generatingSummary:=False:C215
				Form:C1466.generatingSummaryDoc:=""
				Form:C1466.generatingSummaryType:=""
				
				// Display in web area
				var $html : Text
				$html:=_renderSummaryHTML($summary.summaryText)
				WA SET PAGE CONTENT:C1037(*; "summaryText"; $html; "")
			End if 
		End if 
		
		// Stop timer if nothing is being monitored
		If (Form:C1466.processingDocID="") & (Not:C34(Form:C1466.generatingSummary)) & (Not:C34(Form:C1466.waitingForChat))
			SET TIMER:C645(0)
		End if 
		
		// Poll for chat response
		If (Form:C1466.waitingForChat)
			var $conv : cs:C1710.ConversationEntity
			$conv:=ds:C1482.Conversation.query("documentID = :1"; Form:C1466.selectedDoc.UUID).first()
			
			If ($conv#Null:C1517)
				var $msgHistory : Collection
				$msgHistory:=JSON Parse:C1218($conv.messageHistory)
				
				// Check if new messages arrived (excluding system messages)
				var $visibleCount : Integer
				$visibleCount:=0
				If ($msgHistory#Null:C1517)
					var $i : Integer
					For ($i; 0; $msgHistory.length-1)
						If ($msgHistory[$i].role#"system")
							$visibleCount:=$visibleCount+1
						End if 
					End for 
				End if 
				
				// Count real messages (excluding temporary thinking indicator)
				var $realMessageCount : Integer
				$realMessageCount:=0
				For ($i; 0; Form:C1466.chatMessages.length-1)
					If (Form:C1466.chatMessages[$i].isTemporary#True:C214)
						$realMessageCount:=$realMessageCount+1
					End if 
				End for 
				
				If ($visibleCount>$realMessageCount)
					// New message received
					Form:C1466.waitingForChat:=False:C215
					
					// Rebuild message collection (filtering system messages)
					Form:C1466.chatMessages:=New collection:C1472
					For ($i; 0; $msgHistory.length-1)
						If ($msgHistory[$i].role#"system")
							var $timestamp : Text
							$timestamp:=String:C10(Current date:C33; Internal date short special:K1:4)+" "+String:C10(Current time:C178; HH MM:K7:2)
							Form:C1466.chatMessages.push(New object:C1471("role"; $msgHistory[$i].role; "message"; $msgHistory[$i].content; "timestamp"; $timestamp))
						End if 
					End for 
					
					// Update display
					var $chatHTML : Text
					$chatHTML:=_renderChatHTML(Form:C1466.chatMessages)
					WA SET PAGE CONTENT:C1037(*; "chatMessages"; $chatHTML; "")
				End if 
			End if 
		End if 
		
End case 