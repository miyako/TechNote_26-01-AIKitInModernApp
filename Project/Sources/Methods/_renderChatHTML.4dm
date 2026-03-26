//%attributes = {}
// ----------------------------------------------------
// Method: _renderChatHTML
// Description
//     Renders chat messages as styled HTML
//
// Parameters
//     $messages - Exchanged messages
// ----------------------------------------------------

#DECLARE($messages : Collection)->$html : Text

var $msg : Object
var $i : Integer
var $body : Text
var $styles : Text

// Build message body
$body:=""

If ($messages=Null:C1517) | ($messages.length=0)
	$body:="<div class='empty'>💬 No messages yet. Start a conversation!</div>"
Else 
	For ($i; 0; $messages.length-1)
		$msg:=$messages[$i]
		
		// Skip system messages
		If ($msg.role="system")
			continue
		End if 
		
		// Build message card
		var $role : Text
		var $content : Text
		var $timestamp : Text
		var $cssClass : Text
		
		$role:=$msg.role="user" ? "👤 You" : "🤖 Assistant"
		$content:=String:C10($msg.message)
		$timestamp:=String:C10($msg.timestamp)
		
		$cssClass:=$msg.role
		If ($msg.isTemporary=True:C214)
			$cssClass:=$cssClass+" thinking"
		End if 
		
		//Beginning of the card
		$body:=$body+"<div class='message "+$cssClass+"'>"
		$body:=$body+"<div class='role'>"+$role+"</div>"
		$body:=$body+"<div class='content'>"+$content+"</div>"
		
		If ($timestamp#"")
			$body:=$body+"<div class='timestamp'>"+$timestamp+"</div>"
		End if 
		
		$body:=$body+"</div>"
		//The end of the card 
		
		// Add separator after assistant messages
		If ($msg.role="assistant") & ($i<($messages.length-1))
			$body:=$body+"<div class='separator'></div>"
		End if 
	End for 
End if 

// Build styles
$styles:="body { margin: 0; padding: 10px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; font-size: 13px; background: #f9fafb; }"
$styles:=$styles+".message { margin-bottom: 12px; padding: 12px; border-radius: 8px; max-width: 85%; word-wrap: break-word; }"
$styles:=$styles+".user { background: #3B82F6; color: white; margin-left: auto; text-align: right; }"
$styles:=$styles+".assistant { background: white; color: #1f2937; border: 1px solid #e5e7eb; }"
$styles:=$styles+".thinking { background: #f3f4f6; color: #6b7280; border: 1px dashed #d1d5db; font-style: italic; }"
$styles:=$styles+".role { font-weight: 600; font-size: 11px; margin-bottom: 4px; opacity: 0.8; }"
$styles:=$styles+".content { line-height: 1.5; white-space: pre-wrap; }"
$styles:=$styles+".timestamp { font-size: 10px; margin-top: 4px; opacity: 0.6; }"
$styles:=$styles+".separator { height: 1px; background: #e5e7eb; margin: 16px 0; }"
$styles:=$styles+".empty { text-align: center; color: #9ca3af; padding: 40px; font-style: italic; }"
$styles:=$styles+"@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }"
$styles:=$styles+".thinking .content { animation: pulse 1.5s ease-in-out infinite; }"

// Wrap in HTML template
$html:="<!DOCTYPE html>"
$html:=$html+"<html><head><meta charset='UTF-8'>"
$html:=$html+"<style>"+$styles+"</style>"
$html:=$html+"</head><body>"
$html:=$html+$body
$html:=$html+"<script>window.scrollTo(0, document.body.scrollHeight);</script>"
$html:=$html+"</body></html>"

return $html
