DocumentManager form - manual creation instructions

Why this file exists
--------------------
The 4D `.4DForm` binary format is not safe to generate outside the 4D IDE. This folder contains the form method and object-method source so you can quickly recreate the visual form inside 4D and paste the code into the form and object methods.

What to create in 4D
--------------------
Form name: DocumentManager
Type: Project Form
Size: 1200 x 800 pixels
Has Menu Bar: Yes
Published as Web Area: Optional

Form variables (create in Form properties > Variables):
- documents
- selectedDoc
- extractedData
- summaryText
- chatSessionID
- chatMessages
- chatInput
- totalCost
- processing

Form objects and properties (positions in pixels):
1) List Box
   - Name: listDocuments
   - Type: Entity Selection (bind to ds.Documents or Form.documents)
   - Position: x=20, y=80, width=400, height=600
   - Columns: fileName, documentType, uploadDate, status
   - Object method: paste the contents of `listDocuments.ObjectMethod.4dm` into the List Box "Object Method" (On Selection Change / On Double Clicked)

2) Button
   - Name: btnUpload
   - Title: "Upload Document"
   - Position: x=20, y=40

3) Button
   - Name: btnProcess
   - Title: "Analyze Selected"
   - Position: x=140, y=40

4) Preview Area (Web Area or Picture Variable)
   - Name: previewArea
   - Position: x=440, y=80, width=400, height=400

5) Extracted Data Area (Text Area or List Box)
   - Name: extractedDataArea
   - Position: x=440, y=500, width=400, height=180

6) Summary Panel (Text Area multiline)
   - Name: summaryText
   - Position: x=860, y=80, width=320, height=300

7) Chat Messages (List Box)
   - Name: chatMessages
   - Position: x=860, y=400, width=320, height=200
   - Columns: role (hidden), message

8) Chat Input (Text Field)
   - Name: chatInput
   - Position: x=860, y=610, width=250, height=30

9) Send Button
   - Name: btnSendChat
   - Title: "Send"
   - Position: x=1120, y=610

10) Cost Display (Text Variable)
   - Name: costDisplay
   - Position: x=860, y=650
   - Expression: "Total Cost: $"+String(Form.totalCost; "###,##0.0000")

Where to paste the form method
-----------------------------
Open the form in the 4D Form editor, open the Form methods panel and paste the full contents of `DocumentManager.FormMethod.4dm` into the Form "Method" (covering On Load, On Timer, On Clicked, On Unload and the helper functions).

Object methods
--------------
Paste `listDocuments.ObjectMethod.4dm` into the List Box object's method slot. The file contains both the On Selection Change and On Double Clicked handlers.

Notes & testing
----------------
- The form relies on project classes and methods (e.g. `ConversationManager`, `DocumentAnalyzer`, `UploadDocument`, `ProcessDocumentAsync`, `AIUsageLogs`) which already exist in the project sources. Make sure those classes/methods are present.
- Timer granularity: the code uses `SET TIMER(60)` — this value is in ticks. Adjust as needed for your demo.
- If your project uses UUID primary keys (named `UUID`), update any `...ID` usages in the code to use the appropriate field (e.g. `Form.selectedDoc.UUID` or provide a small wrapper to return the correct id). The pasted code assumes `ID` is the document identifier; if you changed to `UUID`, replace `ID` with `UUID` in calls like `ds.Documents.get(Form.selectedDoc.ID)`.

Next steps I can do for you
---------------------------
- Update the code to use `UUID` instead of `ID` throughout (if you want me to apply those textual edits to the method files here, I can).
- Create a simple sample layout PNG showing object placements for quick manual recreation.
- If you can export the `.4DForm` from your 4D IDE and share it, I can insert it into the project folder for you.

Paths of the new helper files I created:
- `Project/Sources/Forms/DocumentManager/DocumentManager.FormMethod.4dm`
- `Project/Sources/Forms/DocumentManager/listDocuments.ObjectMethod.4dm`
- `Project/Sources/Forms/DocumentManager/README.md`

