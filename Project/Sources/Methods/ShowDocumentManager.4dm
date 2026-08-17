//%attributes = {}
// ----------------------------------------------------
// Method: ShowDocumentManager
// Description
//     Open the document manager form 
//
// ----------------------------------------------------

If (Count parameters:C259=0)
	CALL WORKER:C1389(1; Current method name:C684; True:C214)
Else 
	var $win : Integer
	$win:=Open form window("DocumentManager"; Plain form window)
	SET WINDOW TITLE:C213("Document Manager"; $win)
	DIALOG:C40("DocumentManager"; *)
End if
