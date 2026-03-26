// Object Method: btnProcess

Case of 
	: (Form event code:C388=On Clicked:K2:4)
		If (Form:C1466.selectedDoc#Null:C1517)
			
			var $docID : Text
			$docID:=Form:C1466.selectedDoc.UUID
			Form:C1466.selectedDoc:=ds:C1482.Document.get($docID)
			
			// Check if already processed
			If (Form:C1466.selectedDoc.status="Processed")
				CONFIRM:C162("This document has already been analyzed. Do you really want to reanalyze?"; "OK"; "Cancel")
				If (ok=0)
					return 
				End if 
			End if 
			
			// Check if currently processing
			If (Form:C1466.selectedDoc.status="Processing")
				CONFIRM:C162("This document has already been analyzed. Do you really want to reanalyze?"; "OK"; "Cancel")
				If (ok=0)
					return 
				End if 
			End if 
			
			// Update status to Processing
			Form:C1466.selectedDoc.status:="Processing"
			Form:C1466.selectedDoc.statusMessage:="🔄 Preparing document for analysis..."
			Form:C1466.selectedDoc.save()
			Form:C1466.documents:=Form:C1466.documents
			
			// Process document asynchronously in worker
			CALL WORKER:C1389("DocumentWorker-"+$docID; "_asyncProcessDocument"; $docID)
			
			
			// Start timer to poll for completion (every 2 seconds)
			Form:C1466.processingDocID:=$docID
			SET TIMER:C645(120)  // 120 ticks = 2 seconds
			
			Form:C1466.extractedDataArea:="🔄 Processing document asynchronously...\n\nPlease wait while the AI analyzes your document."
			
		Else 
			ALERT:C41("Please select a document first.")
		End if 
End case 
