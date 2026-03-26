// ----------------------------------------------------
// Method: AIConfig Class
// Description
//         Manage AI configuration 
//
// ----------------------------------------------------

property apiKey : Text
property provider : Text
property baseURL : Text
property defaultModel : Text
property visionModel : Text
property maxTokens : Integer
property temperature : Real

shared singleton Class constructor()
	This:C1470.loadConfiguration()
	
Function loadConfiguration()
	var $config : Object
	
	$config:=This:C1470._loadFromConfigFile()
	
	If ($config=Null:C1517)
		ShowAIConfiguration
	Else 
		This:C1470.provider:=$config.provider
		This:C1470.apiKey:=$config.apiKey
		This:C1470.baseURL:=$config.baseURL
		This:C1470.defaultModel:=$config.models.default
		This:C1470.visionModel:=$config.models.vision
		This:C1470.maxTokens:=$config.generation.maxTokens
		This:C1470.temperature:=$config.generation.temperature
	End if 
	
Function getClient()->$client : cs:C1710.AIKit.OpenAI
	If (This:C1470.baseURL#"")
		$client:=cs:C1710.AIKit.OpenAI.new({apiKey: This:C1470.apiKey; baseURL: This:C1470.baseURL})
	Else 
		$client:=cs:C1710.AIKit.OpenAI.new(This:C1470.apiKey)
	End if 
	
	return $client
	
Function _saveToConfigFile()->$success : Boolean
	var $config : Object
	var $file : 4D:C1709.File
	var $json : Text
	var $options : Object
	
	// Build config object from class properties
	$config:={}
	$config.provider:=This:C1470.provider
	$config.apiKey:=This:C1470.apiKey
	$config.baseURL:=This:C1470.baseURL
	
	$config.models:={}
	$config.models.default:=This:C1470.defaultModel
	$config.models.vision:=This:C1470.visionModel
	
	$config.generation:={}
	$config.generation.maxTokens:=This:C1470.maxTokens
	$config.generation.temperature:=This:C1470.temperature
	
	// Target file
	$file:=Folder:C1567(fk database folder:K87:14).file("aiconfig.json")
	
	// JSON options
	$options:={prettyPrint: True:C214}
	$json:=JSON Stringify:C1217($config)
	
	Try
		$file.setText($json)
		$success:=True:C214
	Catch
		$success:=False:C215
	End try
	
	return $success
	
	
Function _loadFromConfigFile()->$config : Object
	var $file : 4D:C1709.File
	var $json : Text
	
	$file:=Folder:C1567(fk database folder:K87:14).file("aiconfig.json")
	
	If (Not:C34($file.exists))
		return Null:C1517
	End if 
	
	Try
		$json:=$file.getText()
		$config:=JSON Parse:C1218($json)
	Catch
		$config:=Null:C1517
	End try
	
	return $config
	
	
	