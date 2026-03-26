//%attributes = {}
// ----------------------------------------------------
// Method: _asyncSendChatMessage
// Description
//    Sends a chat message asynchronously in a worker process
//
// Parameters
//    $docID - UUID of the the document
//    $message - The message of the user
// ----------------------------------------------------


#DECLARE($docID : Text; $message : Text)

var $convMgr : cs:C1710.ConversationManager
var $response : Object

If ($docID#"") & ($message#"")
	$convMgr:=cs:C1710.ConversationManager.new()
	$response:=$convMgr.sendMessage($docID; $message)
End if 
