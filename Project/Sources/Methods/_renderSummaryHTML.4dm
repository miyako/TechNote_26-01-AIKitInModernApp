//%attributes = {}
// ----------------------------------------------------
// Method: _renderSummaryHTML
// Description
//    Wraps AI-generated HTML summary in a styled template
//
// Parameters
//    $content - Summary content
// ----------------------------------------------------

#DECLARE($content : Text)->$html : Text

var $styles : Text

// Cleanup AI markdown markers if present
$content:=Replace string:C233($content; "```html"; "")
$content:=Replace string:C233($content; "```"; "")

// Build styles
$styles:="body { margin: 0; padding: 20px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;"
$styles:=$styles+" font-size: 13px; line-height: 1.6; background: #ffffff; color: #1f2937; }"

$styles:=$styles+"h1, h2 { font-size: 15px; font-weight: 600; margin: 12px 0 10px 0; color: #1f2937; }"
$styles:=$styles+"h3 { font-size: 14px; font-weight: 600; margin: 16px 0 8px 0; color: #1f2937; }"

$styles:=$styles+"p { margin: 8px 0; }"

$styles:=$styles+"ul { margin: 8px 0; padding-left: 20px; }"
$styles:=$styles+"li { margin: 4px 0; }"

$styles:=$styles+"strong { font-weight: 600; color: #111827; }"

// Optional: subtle section separator if AI uses <hr>
$styles:=$styles+"hr { border: none; border-top: 1px solid #e5e7eb; margin: 16px 0; }"

// Wrap in HTML template
$html:="<!DOCTYPE html>"
$html:=$html+"<html><head>"
$html:=$html+"<meta charset='UTF-8'>"
$html:=$html+"<meta name='viewport' content='width=device-width, initial-scale=1.0'>"
$html:=$html+"<style>"+$styles+"</style>"
$html:=$html+"</head><body>"
$html:=$html+$content
$html:=$html+"</body></html>"

return $html
