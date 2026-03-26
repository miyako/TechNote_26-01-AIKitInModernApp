//%attributes = {}
// ----------------------------------------------------
// Method: _editExtractedData
// Description
//     Allow user to edit extracted data JSON
//
// Parameters
//     $extData - ExtractedData Entity
// ----------------------------------------------------



#DECLARE($extData : cs:C1710.ExtractedDataEntity)->$modified : Boolean

var $jsonText : Text
var $newData : Object

$modified:=False:C215

If ($extData=Null:C1517)
	ALERT:C41("No extracted data to edit")
	return 
End if 

// Convert extracted data to pretty JSON for editing
$jsonText:=JSON Stringify:C1217($extData.extractedData; *)

// Prepare form data
var $dialogForm : Object
$dialogForm:=New object:C1471
$dialogForm.editedJSON:=$jsonText
$dialogForm.extractedData:=$extData.extractedData
$dialogForm.extractedDataEntity:=$extData

// Show dialog
var $windowRef : Integer
$windowRef:=Open form window:C675("EditJSONDialog"; Movable form dialog box:K39:8)
DIALOG:C40("EditJSONDialog"; $dialogForm)

If (OK=1)
	$modified:=True:C214
End if 

return $modified
