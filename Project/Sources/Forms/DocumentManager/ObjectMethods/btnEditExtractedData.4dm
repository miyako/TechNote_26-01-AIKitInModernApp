// Button: Edit Extracted Data

Case of 
	: (Form event code:C388=On Clicked:K2:4)
		If (Form:C1466.selectedDoc#Null:C1517)
			// Get extracted data for current document
			var $extData : cs:C1710.ExtractedDataEntity
			$extData:=ds:C1482.ExtractedData.query("documentID = :1"; Form:C1466.selectedDoc.UUID).first()
			
			If ($extData#Null:C1517)
				// Open edit dialog
				var $modified : Boolean
				$modified:=_editExtractedData($extData)
				
				If ($modified)
					// Reload entity to get fresh data
					$extData:=ds:C1482.ExtractedData.get($extData.UUID)
					
					// Refresh display with updated data
					var $display : Text
					$display:=_displayExtractedData($extData)
					Form:C1466.extractedDataArea:=$display
				End if 
			Else 
				ALERT:C41("No extracted data found for this document.\n\nPlease analyze the document first.")
			End if 
		Else 
			ALERT:C41("Please select a document first.")
		End if 
End case 
