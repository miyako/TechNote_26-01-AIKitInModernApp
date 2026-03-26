//%attributes = {}
// ----------------------------------------------------
// Method: _displayDocumentPreview
// Description
//    Display document preview in web area
//
// Parameters
//    $doc - Document Entity
// ----------------------------------------------------


#DECLARE($doc : cs:C1710.DocumentEntity)


If ($doc#Null:C1517) & ($doc.filePath#Null:C1517)
	
	WA OPEN URL:C1020(*; "previewArea"; $doc.filePath)
Else 
	// Show blank page if no document 
	WA OPEN URL:C1020(*; "previewArea"; "about:blank")
End if 