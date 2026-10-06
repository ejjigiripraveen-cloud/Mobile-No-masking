param([string]$OutFile)
# Builds the Mobile Number Masking component register (.xlsx) without Excel or Python.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function X([string]$s) { if ($null -eq $s) { return '' }; return [System.Security.SecurityElement]::Escape($s) }
function ColName([int]$i) { $n = ''; while ($i -gt 0) { $m = ($i - 1) % 26; $n = [char](65 + $m) + $n; $i = [int](($i - $m) / 26) }; return $n }

# ---------- styles ----------
# 0 normal, 1 header, 2 wrap+border, 3 title, 4 done(green), 5 progress(yellow), 6 planned(grey), 7 conditional(orange), 8 sandbox-only(blue), 9 bold wrap border, 10 note italic
$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="5">
<font><sz val="10"/><name val="Arial"/></font>
<font><b/><sz val="10"/><color rgb="FFFFFFFF"/><name val="Arial"/></font>
<font><b/><sz val="14"/><color rgb="FF1F3864"/><name val="Arial"/></font>
<font><b/><sz val="10"/><name val="Arial"/></font>
<font><i/><sz val="9"/><color rgb="FF595959"/><name val="Arial"/></font>
</fonts>
<fills count="8">
<fill><patternFill patternType="none"/></fill>
<fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF1F3864"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFC6EFCE"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFFEB9C"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFEDEDED"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFCE4D6"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFDDEBF7"/><bgColor indexed="64"/></patternFill></fill>
</fills>
<borders count="2">
<border><left/><right/><top/><bottom/><diagonal/></border>
<border><left style="thin"><color rgb="FFBFBFBF"/></left><right style="thin"><color rgb="FFBFBFBF"/></right><top style="thin"><color rgb="FFBFBFBF"/></top><bottom style="thin"><color rgb="FFBFBFBF"/></bottom><diagonal/></border>
</borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="11">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf>
<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>
<xf numFmtId="0" fontId="0" fillId="3" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="0" fillId="4" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="0" fillId="5" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="0" fillId="6" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="0" fillId="7" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="3" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="4" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
</cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>
'@

function StatusStyle([string]$v) {
    if ($v -match '^(Deployed|Done|Backed up|Verified|Yes - deployed)') { return 4 }
    if ($v -match '^(Built|In progress|Pending approval|Approved)') { return 5 }
    if ($v -match '^(Planned|Not deployed|Not started)') { return 6 }
    if ($v -match '^(Conditional|Vendor)') { return 7 }
    if ($v -match '^(Sandbox only|Manual)') { return 8 }
    return 2
}

$sheets = New-Object System.Collections.ArrayList

# Each sheet: Name, Title, Subtitle, Headers, Widths, Rows (string arrays; a value starting with '=' is a formula), StatusCols (0-based)
function Add-Sheet($name, $title, $subtitle, $headers, $widths, $rows, $statusCols) {
    [void]$sheets.Add([pscustomobject]@{ Name = $name; Title = $title; Subtitle = $subtitle; Headers = $headers; Widths = $widths; Rows = $rows; StatusCols = $statusCols })
}

function SheetXml($s) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">')
    $headerRow = 4
    [void]$sb.Append("<sheetViews><sheetView workbookViewId=""0""><pane ySplit=""$headerRow"" topLeftCell=""A$($headerRow+1)"" activePane=""bottomLeft"" state=""frozen""/></sheetView></sheetViews>")
    [void]$sb.Append('<sheetFormatPr defaultRowHeight="15"/><cols>')
    for ($c = 0; $c -lt $s.Widths.Count; $c++) { [void]$sb.Append("<col min=""$($c+1)"" max=""$($c+1)"" width=""$($s.Widths[$c])"" customWidth=""1""/>") }
    [void]$sb.Append('</cols><sheetData>')
    [void]$sb.Append("<row r=""1""><c r=""A1"" t=""inlineStr"" s=""3""><is><t>$(X $s.Title)</t></is></c></row>")
    [void]$sb.Append("<row r=""2""><c r=""A2"" t=""inlineStr"" s=""10""><is><t>$(X $s.Subtitle)</t></is></c></row>")
    [void]$sb.Append("<row r=""$headerRow"" ht=""30"" customHeight=""1"">")
    for ($c = 0; $c -lt $s.Headers.Count; $c++) { $ref = (ColName ($c+1)) + $headerRow; [void]$sb.Append("<c r=""$ref"" t=""inlineStr"" s=""1""><is><t>$(X $s.Headers[$c])</t></is></c>") }
    [void]$sb.Append('</row>')
    $r = $headerRow
    foreach ($row in $s.Rows) {
        $r++
        [void]$sb.Append("<row r=""$r"">")
        for ($c = 0; $c -lt $s.Headers.Count; $c++) {
            $v = if ($c -lt $row.Count) { [string]$row[$c] } else { '' }
            $ref = (ColName ($c+1)) + $r
            $st = if ($s.StatusCols -contains $c) { StatusStyle $v } elseif ($c -eq 0 -and $s.BoldFirst) { 9 } else { 2 }
            if ($v.StartsWith('=')) {
                [void]$sb.Append("<c r=""$ref"" s=""$st""><f>$(X $v.Substring(1))</f></c>")
            } elseif ($v -match '^-?\d+(\.\d+)?$' -and $v.Length -lt 10) {
                [void]$sb.Append("<c r=""$ref"" s=""$st""><v>$v</v></c>")
            } else {
                [void]$sb.Append("<c r=""$ref"" t=""inlineStr"" s=""$st""><is><t xml:space=""preserve"">$(X $v)</t></is></c>")
            }
        }
        [void]$sb.Append('</row>')
    }
    [void]$sb.Append('</sheetData>')
    $lastCol = ColName $s.Headers.Count
    if ($s.Rows.Count -gt 0) { [void]$sb.Append("<autoFilter ref=""A$($headerRow):$lastCol$r""/>") }
    [void]$sb.Append("<mergeCells count=""2""><mergeCell ref=""A1:$($lastCol)1""/><mergeCell ref=""A2:$($lastCol)2""/></mergeCells>")
    [void]$sb.Append('<pageMargins left="0.5" right="0.5" top="0.6" bottom="0.6" header="0.3" footer="0.3"/><pageSetup orientation="landscape" fitToWidth="1" fitToHeight="0"/></worksheet>')
    return $sb.ToString()
}

# ======================= DATA =======================
. (Join-Path $PSScriptRoot 'xlsx_data.ps1')

# ======================= WRITE =======================
if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
$zip = [System.IO.Compression.ZipFile]::Open($OutFile, 'Create')
function AddEntry($path, $content) {
    $e = $zip.CreateEntry($path)
    $w = New-Object System.IO.StreamWriter($e.Open(), (New-Object System.Text.UTF8Encoding($false)))
    $w.Write($content); $w.Close()
}
$ct = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
for ($i = 1; $i -le $sheets.Count; $i++) { $ct += "<Override PartName=""/xl/worksheets/sheet$i.xml"" ContentType=""application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml""/>" }
$ct += '</Types>'
AddEntry '[Content_Types].xml' $ct
AddEntry '_rels/.rels' '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/></Relationships>'
$now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
AddEntry 'docProps/core.xml' "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?><cp:coreProperties xmlns:cp=""http://schemas.openxmlformats.org/package/2006/metadata/core-properties"" xmlns:dc=""http://purl.org/dc/elements/1.1/"" xmlns:dcterms=""http://purl.org/dc/terms/"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""><dc:title>Mobile Number Masking - Component Register</dc:title><dcterms:created xsi:type=""dcterms:W3CDTF"">$now</dcterms:created></cp:coreProperties>"
$wb = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
$rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
$defNames = ''
for ($i = 1; $i -le $sheets.Count; $i++) {
    $s = $sheets[$i-1]
    $wb += "<sheet name=""$(X $s.Name)"" sheetId=""$i"" r:id=""rId$i""/>"
    $rels += "<Relationship Id=""rId$i"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"" Target=""worksheets/sheet$i.xml""/>"
    if ($s.Rows.Count -gt 0) { $defNames += "<definedName name=""_xlnm._FilterDatabase"" localSheetId=""$($i-1)"" hidden=""1"">'$($s.Name)'!`$A`$4:`$$(ColName $s.Headers.Count)`$$($s.Rows.Count + 4)</definedName>" }
    AddEntry "xl/worksheets/sheet$i.xml" (SheetXml $s)
}
$wb += '</sheets>'
if ($defNames) { $wb += "<definedNames>$defNames</definedNames>" }
$wb += '<calcPr calcId="191029" fullCalcOnLoad="1"/></workbook>'
$rels += "<Relationship Id=""rId$($sheets.Count+1)"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"" Target=""styles.xml""/></Relationships>"
AddEntry 'xl/workbook.xml' $wb
AddEntry 'xl/_rels/workbook.xml.rels' $rels
AddEntry 'xl/styles.xml' $styles
$zip.Dispose()
"Wrote $OutFile with $($sheets.Count) sheets"
