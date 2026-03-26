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
var $success : Boolean

If ($docID#"")
	$analyzer:=cs:C1710.DocumentAnalyzer.new()
	$success:=$analyzer.analyzeDocument($docID)
End if 