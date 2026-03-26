//%attributes = {}
// ----------------------------------------------------
// Method: _uploadDocument
// Description
//      Handles document upload and initial processing
//
// Parameters
//      $filePath - File path of the uploaded document
// ----------------------------------------------------


#DECLARE($filePath : Text)->$docID : Text

var $fileName : Text
var $fileSize : Integer
var $doc : cs:C1710.DocumentEntity
var $valid : Boolean

$docID:=""

// Validate file exists
$valid:=(Test path name:C476($filePath)=Is a document:K24:1)
If (Not:C34($valid))
	ALERT:C41("File not found: "+$filePath)
	return 
End if 

// Get file information
$fileName:=Path to object:C1547($filePath).name
$fileSize:=Get document size:C479($filePath)


// Validate file size (10MB limit for vision processing)
If ($fileSize>=(10*1024*1024))
	ALERT:C41("File too large. Maximum size is 10MB.")
	return 
End if 

// Create document record
$doc:=ds:C1482.Document.new()
$doc.fileName:=$fileName
$doc.filePath:=$filePath
$doc.uploadDate:=Current date:C33
$doc.uploadTime:=Current time:C178
$doc.fileSize:=$fileSize
$doc.documentType:="Unknown"
$doc.status:="Uploaded"
$doc.statusMessage:="Document uploaded successfully"
$doc.createdBy:=Current user:C182
$doc.save()

If ($doc.UUID#"")
	$docID:=$doc.UUID
Else 
	ALERT:C41("Failed to save document record")
End if 

return $docID