//%attributes = {}
// ----------------------------------------------------
// Method: _loadSummary
// Description
//    Loads and displays the brief summary for the selected document
//
// ----------------------------------------------------


If (Form:C1466.selectedDoc#Null:C1517)
	var $summary : cs:C1710.SummariesEntity
	$summary:=ds:C1482.Summaries.query("documentID = :1 AND summaryType = :2"; Form:C1466.selectedDoc.UUID; "Brief").first()
	
	If ($summary#Null:C1517)
		Form:C1466.summaryText:=$summary.summaryText
	End if 
End if 
