// Form Method: EditJSONDialog

Case of 
	: (Form event code:C388=On Load:K2:1)
		// Initialize with the JSON to edit
		If (Form:C1466.editedJSON="")
			Form:C1466.editedJSON:=JSON Stringify:C1217(Form:C1466.extractedData; *)
		End if 
End case 
