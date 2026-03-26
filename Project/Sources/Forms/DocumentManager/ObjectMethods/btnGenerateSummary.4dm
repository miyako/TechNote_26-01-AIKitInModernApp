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
				// Use existing summary
				var $html : Text
				$html:=_renderSummaryHTML($existingSummary.summaryText)
				WA SET PAGE CONTENT:C1037(*; "summaryText"; $html; "")
			Else 
				// Generate new summary asynchronously
				var $loadingHTML : Text
				$loadingHTML:="<div style='text-align:center;padding:40px;color:#6b7280'>⏳ Generating "+$summaryType+" summary...</div>"
				$loadingHTML:=_renderSummaryHTML($loadingHTML)
				WA SET PAGE CONTENT:C1037(*; "summaryText"; $loadingHTML; "")
				
				// Call worker to generate summary
				CALL WORKER:C1389("SummaryWorker-"+$docID; "_asyncGenerateSummary"; $docID; $summaryType)
				//GenerateSummaryAsync($docID; $summaryType)
				
				
				// Start timer to poll for completion - store doc ID and type
				Form:C1466.generatingSummary:=True:C214
				Form:C1466.generatingSummaryDoc:=$docID
				Form:C1466.generatingSummaryType:=$summaryType
				SET TIMER:C645(120)  // 2 seconds
			End if 
		Else 
			ALERT:C41("Please select a processed document first")
		End if 
		
End case 