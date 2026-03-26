//%attributes = {}
// ----------------------------------------------------
// Method: _displayExtractedData
// Description
//     display extracted data dynamically based on what AI extracted
//
// Parameters
//     $extData - ExtractedData Entity
// ----------------------------------------------------

#DECLARE($extData : cs:C1710.ExtractedDataEntity)->$display : Text

var $data : Object
var $doc : cs:C1710.DocumentEntity

If ($extData=Null:C1517)
	$display:="No extracted data available"
	return 
End if 

$data:=$extData.extractedData

If ($data=Null:C1517)
	$display:="⚠️ No extracted data found"
	return 
End if 

$doc:=ds:C1482.Document.get($extData.documentID)

If ($doc=Null:C1517)
	$display:="Document not found"
	return 
End if 

// Display document type as header
$display:="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
$display:=$display+"📄"+Uppercase:C13($doc.documentType)+" DETAILS\n"
$display:=$display+"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

// Display all extracted fields dynamically
var $keys : Collection
var $key : Text
var $value : Variant

$keys:=OB Keys:C1719($data)

For each ($key; $keys)
	$value:=$data[$key]
	
	// Display based on value type
	Case of 
		: (Value type:C1509($value)=Is collection:K8:32)
			$display:=$display+$key+":\n"
			var $item : Variant
			For each ($item; $value)
				If (Value type:C1509($item)=Is object:K8:27)
					$display:=$display+"  • "+JSON Stringify:C1217($item)+"\n"
				Else 
					$display:=$display+"  • "+String:C10($item)+"\n"
				End if 
			End for each 
			$display:=$display+"\n"
			
		: (Value type:C1509($value)=Is object:K8:27)
			$display:=$display+$key+":\n"
			$display:=$display+JSON Stringify:C1217($value; *)+"\n\n"
			
		Else 
			$display:=$display+$key+": "+String:C10($value)+"\n"
	End case 
	//End if 
End for each 

$display:=$display+"\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
$display:=$display+"Extracted: "+String:C10($extData.extractionDate)

