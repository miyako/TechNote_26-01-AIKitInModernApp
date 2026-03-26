// Object Method: btnUpload

Case of 
	: (Form event code:C388=On Clicked:K2:4)
		var $filePath : Text
		var $docID : Text
		
		var $doc:=Select document:C905(""; "*.*"; "Select a document to upload"; 0)
		
		If (OK=1)
			$filePath:=Document
			$docID:=_uploadDocument($filePath)
			
			If ($docID#"")
				ALERT:C41("Document uploaded successfully. Click 'Analyze Selected' to extract data.")
				
				// Refresh documents list
				Form:C1466.documents:=ds:C1482.Document.all().orderBy("uploadDate desc")
			End if 
		End if 
End case 
