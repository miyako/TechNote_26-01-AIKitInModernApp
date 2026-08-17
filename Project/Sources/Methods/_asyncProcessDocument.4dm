//%attributes = {}
// ----------------------------------------------------
// Method: _asyncProcessDocument
// Description
//    Process document in worker process
//
// Parameters
//    $docID - UUID of the the document
// ----------------------------------------------------

#DECLARE($docID : Text)

var $analyzer : cs:C1710.DocumentAnalyzer

If ($docID#"")
	$analyzer:=cs:C1710.DocumentAnalyzer.new()
	$analyzer.analyzeDocument($docID)
End if