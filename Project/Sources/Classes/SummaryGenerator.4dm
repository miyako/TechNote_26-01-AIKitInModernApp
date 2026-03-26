// ----------------------------------------------------
// Method: SummaryGenerator
// Description
//      
// ----------------------------------------------------

property config : cs:C1710.AIConfig
property client : cs:C1710.AIKit.OpenAI
property SUMMARY_MAX_TOKENS : Integer
property SUMMARY_TEMPERATURE : Real

Class constructor
	This:C1470.config:=cs:C1710.AIConfig.me
	This:C1470.client:=This:C1470.config.getClient()
	
	// Constants
	This:C1470.SUMMARY_MAX_TOKENS:=800
	This:C1470.SUMMARY_TEMPERATURE:=0.3
	
Function generateSummary($docID : Text; $summaryType : Text)->$summaryID : Text
	var $doc : cs:C1710.DocumentEntity
	var $extData : cs:C1710.ExtractedDataEntity
	var $prompt : Text
	var $result : Object
	
	$summaryID:=""
	
	// Load data
	$doc:=ds:C1482.Document.get($docID)
	$extData:=ds:C1482.ExtractedData.query("documentID = :1"; $docID).first()
	
	// Validate only
	If (Not:C34(This:C1470._validateDocumentData($doc; $extData)))
		return 
	End if 
	
	$prompt:=This:C1470._buildSummaryPrompt($summaryType; $extData)
	$result:=This:C1470._generateWithAI($prompt)
	
	
	If ($result.success)
		$summaryID:=This:C1470._saveSummary($docID; $summaryType; $result.choice.message.content; $result.model)
	End if 
	
	return $summaryID
	
	
	
	// MARK: - Helper Functions
	
Function _validateDocumentData($doc : cs:C1710.DocumentEntity; $extData : cs:C1710.ExtractedDataEntity)->$valid : Boolean
	$valid:=True:C214
	
	If ($doc=Null:C1517)
		ALERT:C41("ERROR: Document not found!")
		$valid:=False:C215
	End if 
	
	If ($extData=Null:C1517)
		ALERT:C41("ERROR: No extracted data found for this document! Please analyze the document first.")
		$valid:=False:C215
	End if 
	return $valid
	
	
Function _buildSummaryPrompt($summaryType : Text; $extData : cs:C1710.ExtractedDataEntity)->$prompt : Text
	var $context : Text
	
	$context:=_buildDocumentContext($extData)
	
	If ($context="")
		ALERT:C41("ERROR: Context is empty!")
		return 
	End if 
	
	Case of 
		: ($summaryType="Brief")
			$prompt:="Provide a 2-3 sentence summary of this document focusing on the most important information.\\n\\n"
			$prompt:=$prompt+"Return as clean HTML with inline CSS styling. Use semantic tags and make it visually appealing.\\n"
			$prompt:=$prompt+"DO NOT include ```html or ``` markers.\\n\\n"
			$prompt:=$prompt+$context
			
		: ($summaryType="Detailed")
			$prompt:="Provide a comprehensive summary covering all key details.\\n\\n"
			$prompt:=$prompt+"Return as clean HTML with inline CSS styling. Structure:\\n"
			$prompt:=$prompt+"- Use <h3> for section headers\\n"
			$prompt:=$prompt+"- Use <ul><li> for bullet points\\n"
			$prompt:=$prompt+"- Use <strong> for emphasis\\n"
			$prompt:=$prompt+"- Use <div style='margin:10px 0'> for spacing\\n"
			$prompt:=$prompt+"DO NOT include ```html or ``` markers.\\n\\n"
			$prompt:=$prompt+"Include sections for: Document Overview, Key Parties, Important Dates & Amounts, Notable Items\\n\\n"
			$prompt:=$prompt+"Document information:\\n"+$context
			
		: ($summaryType="Executive")
			$prompt:="Provide an executive summary suitable for management review.\\n\\n"
			$prompt:=$prompt+"Return as clean HTML with inline CSS styling. Structure:\\n"
			$prompt:=$prompt+"- Start with <div style='background:#f0f9ff;padding:15px;border-left:4px solid #3b82f6;margin-bottom:15px'> for bottom line\\n"
			$prompt:=$prompt+"- Use <h3> for section headers (Key Financials, Action Items)\\n"
			$prompt:=$prompt+"- Use colored badges for priorities: <span style='background:#ef4444;color:white;padding:2px 8px;border-radius:4px;font-size:12px'>HIGH</span>\\n"
			$prompt:=$prompt+"- Keep it concise and action-oriented\\n"
			$prompt:=$prompt+"DO NOT include ```html or ``` markers.\\n\\n"
			$prompt:=$prompt+"Document information:\\n"+$context
			
		: ($summaryType="KeyPoints")
			$prompt:="Analyze this document and extract key points that require attention or action.\\n\\n"
			$prompt:=$prompt+"Return as clean HTML with inline CSS. For each key point, create a card:\\n"
			$prompt:=$prompt+"<div style='border:1px solid #e5e7eb;border-radius:8px;padding:12px;margin:10px 0;background:white'>\\n"
			$prompt:=$prompt+"  <div style='display:flex;justify-content:space-between;margin-bottom:8px'>\\n"
			$prompt:=$prompt+"    <strong>[Description]</strong>\\n"
			$prompt:=$prompt+"    <span style='background:[color];color:white;padding:2px 8px;border-radius:4px;font-size:11px'>[Priority]</span>\\n"
			$prompt:=$prompt+"  </div>\\n"
			$prompt:=$prompt+"  <div style='color:#6b7280;font-size:13px'>Type: [Financial/Deadline/Compliance/General]</div>\\n"
			$prompt:=$prompt+"  <div style='margin-top:8px;color:#374151'>Action: [recommended action]</div>\\n"
			$prompt:=$prompt+"</div>\\n"
			$prompt:=$prompt+"DO NOT include ```html or ``` markers.\\n\\n"
			$prompt:=$prompt+"Priority colors: High=#ef4444, Medium=#f59e0b, Low=#10b981\\n\\n"
			$prompt:=$prompt+"Document data:\\n"+$context
	End case 
	
	return $prompt
	
	
Function _generateWithAI($prompt : Text)->$result : Object
	var $messages : Collection
	var $params : Object
	
	$messages:=New collection:C1472
	$messages.push(New object:C1471("role"; "system"; "content"; "You are a business document analyst."))
	$messages.push(New object:C1471("role"; "user"; "content"; $prompt))
	
	$params:={\
		model: This:C1470.config.defaultModel; \
		max_tokens: This:C1470.SUMMARY_MAX_TOKENS; \
		temperature: This:C1470.SUMMARY_TEMPERATURE}
	
	//use asynchronous call
	//onResponse: Formula(testAsync($1))
	//$result:=This.client.chat.completions.create($messages; $params)
	$result:=This:C1470.client.chat.completions.create($messages; $params)
	
	
	return $result
	
	
Function _saveSummary($docID : Text; $summaryType : Text; $summaryText : Text; $model : Text)->$summaryID : Text
	var $summary : cs:C1710.SummariesEntity
	
	$summaryID:=""
	
	$summary:=ds:C1482.Summaries.new()
	$summary.documentID:=$docID
	$summary.summaryType:=$summaryType
	$summary.summaryText:=$summaryText
	$summary.generatedDate:=Current date:C33
	$summary.generatedTime:=Current time:C178
	$summary.save()
	
	If ($summary.UUID#"")
		$summaryID:=$summary.UUID
	End if 
	
	return $summaryID
	
	