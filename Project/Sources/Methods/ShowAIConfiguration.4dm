//%attributes = {}
// ----------------------------------------------------
// Method: ShowAIConfiguration
// Description
//      Display the AI Configuration Form
//
// ----------------------------------------------------

var $aiconfig : cs:C1710.AIConfig
var $tempConfig : Object
var $sucess : Boolean
$aiconfig:=cs:C1710.AIConfig.me
$tempConfig:={\
provider: $aiconfig.provider; \
apiKey: $aiconfig.apiKey; \
baseURL: $aiconfig.baseURL; \
defaultModel: $aiconfig.defaultModel; \
visionModel: $aiconfig.visionModel; \
maxTokens: $aiconfig.maxTokens; \
temperature: $aiconfig.temperature}
var $win : Integer
$win:=Open form window:C675("AIConfiguration")
SET WINDOW TITLE:C213("AI Configuration"; $win)
DIALOG:C40("AIConfiguration"; $tempConfig)

// If user clicked Save, copy values back
If (ok=1)
	Use ($aiconfig)
		$aiconfig.provider:=$tempConfig.provider
		$aiconfig.apiKey:=$tempConfig.apiKey
		$aiconfig.baseURL:=$tempConfig.baseURL
		$aiconfig.defaultModel:=$tempConfig.defaultModel
		$aiconfig.visionModel:=$tempConfig.visionModel
		$aiconfig.maxTokens:=$tempConfig.maxTokens
		$aiconfig.temperature:=$tempConfig.temperature
		$sucess:=$aiconfig._saveToConfigFile()
		If ($sucess)
			ALERT:C41("Configuration updated successfully")
		End if 
	End use 
End if 
CLOSE WINDOW:C154($win)