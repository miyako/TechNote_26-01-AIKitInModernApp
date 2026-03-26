// summaryTypeDropdown object method
// When user changes summary type, check if it exists or prompt to generate

If (Form event code:C388=On Data Change:K2:15)
	If (Form:C1466.selectedDoc#Null:C1517)
		var $summaryType : Text
		var $summary : cs:C1710.SummariesEntity
		
		$summaryType:=Form:C1466.summaryType
		
		// Check if this summary type already exists
		$summary:=ds:C1482.Summaries.query("documentID = :1 AND summaryType = :2"; Form:C1466.selectedDoc.UUID; $summaryType).first()
		
		If ($summary#Null:C1517)
			// Display existing summary
			var $html : Text
			$html:=_renderSummaryHTML($summary.summaryText)
			WA SET PAGE CONTENT:C1037(*; "summaryText"; $html; "")
		Else 
			// Check if currently generating this type
			If (Form:C1466.generatingSummaryFor=Form:C1466.selectedDoc.UUID) & (Form:C1466.generatingSummaryType=$summaryType)
				// Show generating state
				var $loadingHTML : Text
				$loadingHTML:="<div style='text-align:center;padding:40px;color:#6b7280'>⏳ Generating "+$summaryType+" summary...</div>"
				$loadingHTML:=_renderSummaryHTML($loadingHTML)
				WA SET PAGE CONTENT:C1037(*; "summaryText"; $loadingHTML; "")
			Else 
				// Show message to generate
				var $promptHTML : Text
				$promptHTML:="<div style='text-align:center;padding:40px;color:#6b7280'>"
				$promptHTML:=$promptHTML+"<div style='font-size:16px;margin-bottom:10px'>📝</div>"
				$promptHTML:=$promptHTML+"<div>No <strong>"+$summaryType+"</strong> summary available.</div>"
				$promptHTML:=$promptHTML+"<div style='margin-top:10px;font-size:13px'>Click <strong>Generate</strong> to create one.</div>"
				$promptHTML:=$promptHTML+"</div>"
				$promptHTML:=_renderSummaryHTML($promptHTML)
				WA SET PAGE CONTENT:C1037(*; "summaryText"; $promptHTML; "")
			End if 
		End if 
	End if 
End if 
