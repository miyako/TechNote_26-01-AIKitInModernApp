var $config : cs:C1710.AIConfig
$config:=cs:C1710.AIConfig.me

Case of 
	: ($config.apiKey="")
		ShowAIConfiguration
	: ($config.provider="")
		ShowAIConfiguration
	Else 
		ShowDocumentManager
End case 

