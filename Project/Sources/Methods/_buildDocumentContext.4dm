//%attributes = {}
// ----------------------------------------------------
// Method: _buildDocumentContext
// Description
//     Formats extracted data into a text context for AI prompts
//
// Parameters
//     $extData - ExtractedData Entity
// ----------------------------------------------------



#DECLARE($extData : cs:C1710.ExtractedDataEntity)->$context : Text

var $data : Object

$context:=""

If ($extData#Null:C1517)
	$data:=$extData.extractedData
	
	If ($data#Null:C1517)
		// Return formatted JSON for AI context
		$context:=JSON Stringify:C1217($data; *)
	Else 
		$context:="No extracted data available."
	End if 
End if 

return $context
