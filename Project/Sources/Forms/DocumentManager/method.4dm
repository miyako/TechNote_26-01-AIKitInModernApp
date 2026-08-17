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
		Form:C1466.extractedDataArea:=""
		Form:C1466.generatingSummary:=False:C215
		Form:C1466.generatingSummaryDoc:=""
		Form:C1466.generatingSummaryType:=""
		Form:C1466.waitingForChat:=False:C215
		
		// Initialize async managers
		Form:C1466.convManager:=Null:C1517
		Form:C1466.summaryGen:=Null:C1517
		
		
		
	: (Form event code:C388=On Timer:K2:25)
		
		// Poll for document analysis completion (vision callback updates DB)
		If (Form:C1466.processingDocID#"")
			var $doc : cs:C1710.DocumentEntity
			$doc:=ds:C1482.Document.get(Form:C1466.processingDocID)
			
			If ($doc=Null:C1517)
				Form:C1466.processingDocID:=""
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
						
						// Auto-generate Brief summary (async, no polling needed)
						If (Form:C1466.summaryGen=Null:C1517)
							Form:C1466.summaryGen:=cs:C1710.SummaryGenerator.new()
						End if 
						Form:C1466.generatingSummary:=True:C214
						Form:C1466.summaryGen.generateSummary($doc.UUID; "Brief")
					End if 
				Else 
					Form:C1466.extractedDataArea:="❌ ERROR\n\n"+$doc.statusMessage
				End if 
			End if 
		End if 
		
		// Stop timer if nothing is being monitored
		If (Form:C1466.processingDocID="")
			SET TIMER:C645(0)
		End if 
		
End case