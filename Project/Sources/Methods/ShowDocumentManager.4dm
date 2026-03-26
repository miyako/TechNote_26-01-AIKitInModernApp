//%attributes = {}
// ----------------------------------------------------
// Method: ShowDocumentManager
// Description
//     Open the document manager form 
//
// ----------------------------------------------------

var $win : Integer
$win:=Open form window:C675("DocumentManager")
SET WINDOW TITLE:C213("Document Manager"; $win)
DIALOG:C40("DocumentManager")
CLOSE WINDOW:C154($win)
