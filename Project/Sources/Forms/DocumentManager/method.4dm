// Form Method: DocumentManager

Case of 
	: (Form event code:C388=On Load:K2:1)
		// Initialize form
		Form:C1466.documents:=ds:C1482.Document.all().orderBy("uploadDate desc")
		Form:C1466.selectedDoc:=Null:C1517
		Form:C1466.summaryText:=""
		Form:C1466.summaryHTML:=""
		Form:C1466.summaryType:="Brief"
		Form:C1466.chatMessages:=New collection:C1472
		Form:C1466.chatDisplay:=""
		Form:C1466.chatInput:=""
		Form:C1466.processing:=False:C215
		Form:C1466.processingStartTime:=0
		Form:C1466.processingDocID:=""
		Form:C1466.extractedDataArea:=""
		Form:C1466.generatingSummary:=False:C215
		Form:C1466.generatingSummaryDoc:=""
		Form:C1466.generatingSummaryType:=""
		Form:C1466.waitingForChat:=False:C215
		
		// Initialize async managers
		Form:C1466.convManager:=Null:C1517
		Form:C1466.summaryGen:=Null:C1517
		
		// Load summary HTML page
		WA OPEN URL:C1020(*; "summaryText"; File:C1566("/RESOURCES/summary.html").platformPath)
		WA SET PREFERENCE:C1041(*; "summaryText"; WA enable contextual menu:K62:6; True:C214)
		WA SET PREFERENCE:C1041(*; "summaryText"; WA enable Web inspector:K62:7; True:C214)
		
End case 