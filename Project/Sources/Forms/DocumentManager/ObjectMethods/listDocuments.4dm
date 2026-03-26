// Object Method: listDocuments

var $chatHTML : Text
var $extData : cs:C1710.ExtractedDataEntity
var $msgHistory : Collection

Case of 
	: (Form event code:C388=On Selection Change:K2:29)
		// Update selected document
		var $displayExtracted : Text
		
		$displayExtracted:=""
		
		If (Form:C1466.selectedDoc#Null:C1517)
			// Reload document from database to get fresh data
			var $docID : Text
			$docID:=Form:C1466.selectedDoc.UUID
			Form:C1466.selectedDoc:=ds:C1482.Document.get($docID)
			
			// Reset summary type to Brief
			Form:C1466.summaryType:="Brief"  // Display document in preview area
			_displayDocumentPreview(Form:C1466.selectedDoc)
			
			// Load associated data
			$extData:=ds:C1482.ExtractedData.query("documentID = :1"; Form:C1466.selectedDoc.UUID).first()
			
			If ($extData#Null:C1517)
				Form:C1466.extractedData:=$extData
				
				// Display extracted data
				$displayExtracted:=_displayExtractedData($extData)
				Form:C1466.extractedDataArea:=$displayExtracted
			Else 
				// Check if document is currently being processed
				If (Form:C1466.processingDocID=Form:C1466.selectedDoc.UUID)
					// Show processing state
					$displayExtracted:="🔄 Processing document asynchronously...\n\nPlease wait while the AI analyzes your document."
				Else 
					// no extracted data and not processing
					$displayExtracted:="No extracted data available.\n\nPlease click 'Analyze Selected' to extract data from this document."
				End if 
			End if 
			
			Form:C1466.extractedDataArea:=$displayExtracted
			
			// Load summary - default to Brief type
			var $summary : cs:C1710.SummariesEntity
			$summary:=ds:C1482.Summaries.query("documentID = :1 AND summaryType = :2"; Form:C1466.selectedDoc.UUID; "Brief").first()
			
			If ($summary#Null:C1517)
				// Display in web area
				var $html : Text
				$html:=_renderSummaryHTML($summary.summaryText)
				WA SET PAGE CONTENT:C1037(*; "summaryText"; $html; "")
			Else 
				// Check if summary is currently being generated for this document
				If ((Form:C1466.generatingSummary) & (Form:C1466.generatingSummaryDoc=Form:C1466.selectedDoc.UUID))
					// Show generating state with specific summary type
					var $loadingHTML : Text
					$loadingHTML:="<div style='text-align:center;padding:40px;color:#6b7280'>⏳ Generating "+Form:C1466.generatingSummaryType+" summary...</div>"
					$loadingHTML:=_renderSummaryHTML($loadingHTML)
					WA SET PAGE CONTENT:C1037(*; "summaryText"; $loadingHTML; "")
				Else 
					// Clear web area if no summary
					var $emptyHTML : Text
					$emptyHTML:=_renderSummaryHTML("<div style='color:#6b7280;text-align:center;padding:40px'>No summary available. Click Generate to create one.</div>")
					WA SET PAGE CONTENT:C1037(*; "summaryText"; $emptyHTML; "")
				End if 
			End if 
			
			// Load existing conversation history
			var $conv : cs:C1710.ConversationEntity
			$conv:=ds:C1482.Conversation.query("documentID = :1"; Form:C1466.selectedDoc.UUID).orderBy("startDate desc").first()
			
			If ($conv#Null:C1517)
				// Decide whether to rebuild the system message (avoid doing it every selection)
				var $doc : cs:C1710.DocumentEntity
				var $needUpdate : Boolean
				var $tmpHistory : Collection
				var $systemMessage : Text
				
				$doc:=Form:C1466.selectedDoc
				$extData:=ds:C1482.ExtractedData.query("documentID = :1"; $doc.UUID).first()
				$needUpdate:=False:C215
				
				If ($extData#Null:C1517)
					// If extracted data is newer than the conversation's last update, refresh system message
					If ($conv.lastMessageDate=Null:C1517) | ($extData.extractionDate>$conv.lastMessageDate)
						$needUpdate:=True:C214
					End if 
				Else 
					// No extracted data: ensure there is at least a system message
					$tmpHistory:=JSON Parse:C1218($conv.messageHistory)
					If ($tmpHistory=Null:C1517) | ($tmpHistory.length=0) | ($tmpHistory[0].role#"system")
						$needUpdate:=True:C214
					End if 
				End if 
				
				If ($needUpdate)
					$extData:=ds:C1482.ExtractedData.query("documentID = :1"; $doc.UUID).first()
					
					$systemMessage:="You are a helpful assistant that answers questions about business documents. "
					
					If ($extData#Null:C1517)
						$systemMessage:=$systemMessage+"You have access to the following document information:\\n\\n"
						$systemMessage:=$systemMessage+"Document: "+$doc.fileName+" (Type: "+$doc.documentType+")\\n\\n"
						$systemMessage:=$systemMessage+"Extracted Data:\\n"+_buildDocumentContext($extData)+"\\n\\n"
					End if 
					
					$systemMessage:=$systemMessage+"Answer questions based on this information. If information is not available, "
					$systemMessage:=$systemMessage+"say so rather than making assumptions. Be concise and professional."  // Update the system message in history
					$msgHistory:=JSON Parse:C1218($conv.messageHistory)
					If ($msgHistory#Null:C1517) & ($msgHistory.length>0)
						// Update first message if it's a system message
						If ($msgHistory[0].role="system")
							$msgHistory[0].content:=$systemMessage
						Else 
							// Insert system message at the beginning
							$msgHistory.insert(0; New object:C1471("role"; "system"; "content"; $systemMessage))
						End if 
						$conv.messageHistory:=JSON Stringify:C1217($msgHistory)
					End if 
					
					$conv.save()
				End if 
				
				Form:C1466.chatMessages:=New collection:C1472
				
				// Parse message history
				$msgHistory:=JSON Parse:C1218($conv.messageHistory)
				
				// Build Form.chatMessages collection from history
				// Skip system messages - they guide the AI but shouldn't be shown to users
				If ($msgHistory#Null:C1517) & ($msgHistory.length>0)
					var $i : Integer
					var $msg : Object
					
					For ($i; 0; $msgHistory.length-1)
						$msg:=$msgHistory[$i]
						If ($msg.role#"system")
							Form:C1466.chatMessages.push(New object:C1471("role"; $msg.role; "message"; $msg.content; "timestamp"; String:C10(Current date:C33; Internal date short special:K1:4)+" "+String:C10(Current time:C178; HH MM:K7:2)))
						End if 
					End for 
				End if 
				
				// Render chat history in web area (empty or with messages)
				$chatHTML:=_renderChatHTML(Form:C1466.chatMessages)
				WA SET PAGE CONTENT:C1037(*; "chatMessages"; $chatHTML; "")
			Else 
				// No existing conversation - reset for new chat
				Form:C1466.chatMessages:=New collection:C1472
				
				// Clear chat web area
				$chatHTML:=_renderChatHTML(Form:C1466.chatMessages)
				WA SET PAGE CONTENT:C1037(*; "chatMessages"; $chatHTML; "")
			End if 
		End if 
		
End case 
