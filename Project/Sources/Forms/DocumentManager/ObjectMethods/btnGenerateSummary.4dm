// btnGenerateSummary object method
// Generate summary for selected document with chosen type

Case of 
	: (Form event code:C388=On Clicked:K2:4)
		If (Form:C1466.selectedDoc#Null:C1517)
			var $docID : Text
			var $summaryType : Text
			
			$docID:=Form:C1466.selectedDoc.UUID
			$summaryType:=Form:C1466.summaryType
			
			// Default to Brief if not selected
			If ($summaryType="")
				$summaryType:="Brief"
				Form:C1466.summaryType:=$summaryType
			End if 
			
			// Check if this summary type already exists for this document
			var $existingSummary : cs:C1710.SummariesEntity
			$existingSummary:=ds:C1482.Summaries.query("documentID = :1 AND summaryType = :2"; $docID; $summaryType).first()
			
			If ($existingSummary#Null:C1517)
					// Use existing summary — render as HTML
					WA EXECUTE JAVASCRIPT FUNCTION(*; "summaryText"; "setRenderedHTML"; *; $existingSummary.summaryText)
			Else 
					// Show loading state
					WA EXECUTE JAVASCRIPT FUNCTION(*; "summaryText"; "setContent"; *; "⏳ Generating "+$summaryType+" summary...")
				
				// Generate summary asynchronously (streaming callback handles display)
				If (Form:C1466.summaryGen=Null:C1517)
					Form:C1466.summaryGen:=cs:C1710.SummaryGenerator.new()
				End if 
				Form:C1466.generatingSummary:=True:C214
				Form:C1466.summaryGen.generateSummary($docID; $summaryType)
			End if 
		Else 
			ALERT:C41("Please select a processed document first")
		End if 
		
End case