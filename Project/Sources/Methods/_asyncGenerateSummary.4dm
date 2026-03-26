//%attributes = {}
// ----------------------------------------------------
// Method: _asyncGenerateSummary
// Description
//     Generate summary in worker process
//
// Parameters
//     $docID - UUID of the the document
//     $summaryType - The type of Summary (Brief, Detailed,..) 
//
// ----------------------------------------------------


#DECLARE($docID : Text; $summaryType : Text)

var $summaryGen : cs:C1710.SummaryGenerator

If ($docID#"") & ($summaryType#"")
	$summaryGen:=cs:C1710.SummaryGenerator.new()
	$summaryGen.generateSummary($docID; $summaryType)
End if 
