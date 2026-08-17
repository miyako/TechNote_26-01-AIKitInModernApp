// ----------------------------------------------------
// Method: DocumentAnalyzer
// Description
//      Manages document analysis
// ----------------------------------------------------


property config : cs:C1710.AIConfig
property client : cs:C1710.AIKit.OpenAI
property PDF_DPI : Integer
property MAX_TOKENS : Integer
property TEMPERATURE : Real
property stream : Boolean
property _visionResult : Text


Class constructor
	This:C1470.config:=cs:C1710.AIConfig.me
	This:C1470.client:=This:C1470.config.getClient()
	
	// Constants
	This:C1470.PDF_DPI:=144
	This:C1470.MAX_TOKENS:=1000
	This:C1470.TEMPERATURE:=0.1
	This:C1470.stream:=True:C214
	This:C1470._visionResult:=""
	
Function analyzeDocument($docID : Text)
	var $doc : cs:C1710.DocumentEntity
	
	$doc:=ds:C1482.Document.get($docID)
	
	If ($doc#Null:C1517)
		// Update status
		$doc.status:="Processing"
		$doc.statusMessage:="🔄 Analyzing document and extracting data..."
		$doc.save()
		
		// Extract data using AI (async — callback handles status update)
		This:C1470._extractGenericData($doc)
	End if
	
Function _convertPdfToImage($pdfFile : 4D:C1709.File)->$imageFile : 4D:C1709.File
	// Convert PDF to PNG using the pdfium plugin
	// Returns PNG file of first page(you can choose as much pages as you want) , or original file on error
	
	var $tempFile : 4D:C1709.File
	var $tempFolder : 4D:C1709.Folder
	var $folder : Text
	var $images : Collection
	var $options : Object
	var $blob : Blob
	
	Try
		// Create temp folder for converted images in Resources folder
		$folder:=Folder:C1567(fk resources folder:K87:11).path+"pdf_to_png"
		$tempFolder:=Folder:C1567($folder)
		
		If (Not:C34($tempFolder.exists) || $tempFolder=Null:C1517)
			$tempFolder.create()
		End if 
		
		// Set DPI options for better quality (144 DPI = 2x scaling)
		$options:=New object:C1471("dpi"; 144)
		
		// Convert PDF to images collection (uses pdfium plugin)
		$images:=pdf to image($pdfFile; $options)
		
		If ($images#Null:C1517) & ($images.length>0)
			// Create a temp file 
			$tempFile:=File:C1566($tempFolder.path+"page_1_"+String:C10(Milliseconds:C459)+".png")
			
			// Convert picture to blob and write to file, only the first page has been selected
			PICTURE TO BLOB:C692($images[0]; $blob; "image/png")
			$tempFile.setContent($blob)
			
			// Return the temp file
			$imageFile:=$tempFile
		Else 
			// No images extracted
			$imageFile:=$pdfFile
		End if 
	Catch
		// On any error, return original file
		$imageFile:=$pdfFile
	End try
	
Function _extractGenericData($doc : cs:C1710.DocumentEntity)
	var $file : 4D:C1709.File
	var $prompt : Text
	
	// Prepare document file
	$file:=This:C1470._prepareDocumentFile($doc)
	
	If ($file#Null:C1517) & ($file.exists)
		// Build extraction prompt
		$prompt:=This:C1470._buildExtractionPrompt()
		
		// Call AI vision API (async — callback handles saving)
		This:C1470._analyzeDocumentWithAI($file; $prompt; $doc.UUID)
	End if
	
	
	// MARK: - Private Functions
	
Function _prepareDocumentFile($doc : cs:C1710.DocumentEntity)->$file : 4D:C1709.File
	var $filePath : Text
	
	$filePath:=Convert path system to POSIX:C1106($doc.filePath)
	$file:=File:C1566($filePath)
	
	// Convert PDF to image if needed
	If ($file.exists) & (Lowercase:C14($file.extension)=".pdf")
		$file:=This:C1470._convertPdfToImage($file)
	End if 
	
	return $file
	
	
Function _buildExtractionPrompt()->$prompt : Text
	$prompt:="You are analyzing a document. Extract ALL relevant information you can find:\\n\\n"
	$prompt:=$prompt+"1. Document type (e.g., Invoice, Receipt, Contract, Letter, Report, etc.)\\n"
	$prompt:=$prompt+"2. Document title or subject\\n"
	$prompt:=$prompt+"3. Document date (format: YYYY-MM-DD)\\n"
	$prompt:=$prompt+"4. Main content summary (2-3 sentences)\\n"
	$prompt:=$prompt+"5. Key entities (names, organizations, amounts, dates, etc.)\\n"
	$prompt:=$prompt+"6. Any other relevant fields specific to this document type\\n\\n"
	$prompt:=$prompt+"Return ONLY valid JSON. Include ALL fields you can extract.\\n"
	$prompt:=$prompt+"Required keys: documentType, title, documentDate, summary, keyEntities\\n"
	$prompt:=$prompt+"Add any other relevant fields based on document type.\\n"
	$prompt:=$prompt+"DO NOT include ```json or ``` markers.\\n"
	$prompt:=$prompt+"DO NOT include any text before or after the JSON."
	
	return $prompt
	
	
Function _analyzeDocumentWithAI($file : 4D:C1709.File; $prompt : Text; $docID : Text)
	var $visionHelper : Object
	var $ChatCompletionsParameters : cs:C1710.AIKit.OpenAIChatCompletionsParameters
	
	$ChatCompletionsParameters:=cs:C1710.AIKit.OpenAIChatCompletionsParameters.new(This:C1470)
	$ChatCompletionsParameters.model:=This:C1470.config.visionModel
	$ChatCompletionsParameters.max_completion_tokens:=This:C1470.MAX_TOKENS
	$ChatCompletionsParameters.temperature:=This:C1470.TEMPERATURE
	$ChatCompletionsParameters.stream:=This:C1470.stream
	$ChatCompletionsParameters.formula:=This:C1470.onEventStreamVision
	$ChatCompletionsParameters.extraHeaders:={docID: $docID}
	
	This:C1470._visionResult:=""
	
	$visionHelper:=This:C1470.client.chat.vision.fromFile($file; $ChatCompletionsParameters)
	$visionHelper.prompt($prompt)
	
	
Function onEventStreamVision($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsStreamResult)
	If ($chatCompletionsResult.success)
		If ($chatCompletionsResult.terminated)
			// Stream complete
			var $content : Text
			If ($chatCompletionsResult.choice#Null:C1517)
				If ($chatCompletionsResult.choice.message=Null:C1517)
					$content:=This:C1470._visionResult
				Else 
					If ($chatCompletionsResult.choice.message.content#Null:C1517)
						$content:=$chatCompletionsResult.choice.message.content
					End if 
				End if 
			End if 
			// Save extracted data
			var $docID : Text
			$docID:=$chatCompletionsResult.request.headers.docID
			If ($docID#"") & ($content#"")
				var $extracted : Object
				$extracted:=JSON Parse:C1218($content)
				If ($extracted#Null:C1517)
					This:C1470._saveExtractedData($docID; $extracted)
					// Update document status
					var $doc : cs:C1710.DocumentEntity
					$doc:=ds:C1482.Document.get($docID)
					If ($doc#Null:C1517)
						$doc.status:="Processed"
						$doc.statusMessage:="✅ Analysis complete"
						$doc.save()
					End if 
				End if 
			End if 
		Else 
			// Partial result — accumulate
			If ($chatCompletionsResult.choice#Null:C1517)
				If ($chatCompletionsResult.choice.delta.text#"")
					This:C1470._visionResult:=This:C1470._visionResult+$chatCompletionsResult.choice.delta.text
				End if 
			End if 
		End if 
	Else 
		If ($chatCompletionsResult.terminated)
			// Error
			var $errDocID : Text
			$errDocID:=$chatCompletionsResult.request.headers.docID
			If ($errDocID#"")
				var $errDoc : cs:C1710.DocumentEntity
				$errDoc:=ds:C1482.Document.get($errDocID)
				If ($errDoc#Null:C1517)
					$errDoc.status:="Error"
					$errDoc.statusMessage:=$chatCompletionsResult.errors.extract("message").join("\r")
					$errDoc.save()
				End if 
			End if 
		End if 
	End if
	
	
Function _saveExtractedData($documentID : Text; $extracted : Object)->$success : Boolean
	var $extData : cs:C1710.ExtractedDataEntity
	var $doc : cs:C1710.DocumentEntity
	
	$extData:=ds:C1482.ExtractedData.new()
	$extData.documentID:=$documentID
	$extData.extractionDate:=Current date:C33
	$extData.extractedData:=$extracted
	$extData.save()
	
	$success:=($extData.UUID#"")
	
	// Update document type if extracted
	If ($success) & ($extracted.documentType#Null:C1517)
		$doc:=ds:C1482.Document.get($documentID)
		If ($doc#Null:C1517)
			$doc.documentType:=String:C10($extracted.documentType)
			$doc.save()
		End if 
	End if 
	
	return $success
	