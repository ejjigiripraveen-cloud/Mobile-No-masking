param([string]$In, [string]$OutDocx, [string]$OutTxt)
# Converts the project's Markdown guide to a .docx (WordprocessingML written directly, no Word needed)
# and a plain-text copy for Notepad.

function X([string]$s) { return [System.Security.SecurityElement]::Escape($s) }

# Inline runs: **bold**, `code`, [text](link) -> text
function Runs([string]$s, [int]$size = 20, [bool]$allBold = $false, [string]$color = '') {
    $s = [regex]::Replace($s, '\[([^\]]+)\]\([^)]+\)', '$1')
    $out = New-Object System.Text.StringBuilder
    foreach ($part in [regex]::Split($s, '(\*\*[^*]+\*\*|`[^`]+`)')) {
        if ($part -eq '') { continue }
        $bold = $allBold; $code = $false; $t = $part
        if ($part -match '^\*\*(.+)\*\*$') { $bold = $true; $t = $Matches[1] }
        elseif ($part -match '^`(.+)`$') { $code = $true; $t = $Matches[1] }
        $rpr = ''
        if ($code) { $rpr += '<w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:color w:val="833C0B"/>' }
        elseif ($color) { $rpr += "<w:color w:val=`"$color`"/>" }
        if ($bold) { $rpr += '<w:b/>' }
        $rpr += "<w:sz w:val=`"$size`"/>"
        [void]$out.Append("<w:r><w:rPr>$rpr</w:rPr><w:t xml:space=`"preserve`">$(X $t)</w:t></w:r>")
    }
    return $out.ToString()
}

function Para([string]$text, [int]$size = 20, [bool]$bold = $false, [string]$color = '', [int]$before = 0, [int]$after = 80, [string]$extraPPr = '') {
    return "<w:p><w:pPr><w:spacing w:before=`"$before`" w:after=`"$after`"/>$extraPPr</w:pPr>$(Runs $text $size $bold $color)</w:p>"
}

$lines = Get-Content -LiteralPath $In -Encoding UTF8
$body = New-Object System.Text.StringBuilder
$table = $null; $code = $null

function FlushTable {
    if ($null -eq $script:table) { return }
    $rows = $script:table
    $cols = ($rows | ForEach-Object { $_.Count } | Measure-Object -Maximum).Maximum
    $w = [int](14400 / [Math]::Max($cols, 1))
    $b = '<w:tblBorders>' + (('top','left','bottom','right','insideH','insideV' | ForEach-Object { "<w:$_ w:val=`"single`" w:sz=`"4`" w:color=`"8EAADB`"/>" }) -join '') + '</w:tblBorders>'
    [void]$script:body.Append("<w:tbl><w:tblPr><w:tblW w:w=`"5000`" w:type=`"pct`"/>$b<w:tblLayout w:type=`"autofit`"/></w:tblPr><w:tblGrid>")
    for ($i = 0; $i -lt $cols; $i++) { [void]$script:body.Append("<w:gridCol w:w=`"$w`"/>") }
    [void]$script:body.Append('</w:tblGrid>')
    for ($r = 0; $r -lt $rows.Count; $r++) {
        $hdr = ($r -eq 0)
        [void]$script:body.Append('<w:tr>' + $(if ($hdr) { '<w:trPr><w:tblHeader/></w:trPr>' } else { '' }))
        for ($c = 0; $c -lt $cols; $c++) {
            $txt = if ($c -lt $rows[$r].Count) { $rows[$r][$c] } else { '' }
            $shade = if ($hdr) { '<w:shd w:val="clear" w:color="auto" w:fill="D9E2F3"/>' } else { '' }
            [void]$script:body.Append("<w:tc><w:tcPr>$shade</w:tcPr><w:p><w:pPr><w:spacing w:before=`"20`" w:after=`"20`"/></w:pPr>$(Runs $txt 17 $hdr)</w:p></w:tc>")
        }
        [void]$script:body.Append('</w:tr>')
    }
    [void]$script:body.Append('</w:tbl>' + (Para '' 8 $false '' 0 60))
    $script:table = $null
}

foreach ($line in $lines) {
    if ($line -match '^```') {
        if ($null -ne $code) {
            foreach ($cl in $code) {
                [void]$body.Append("<w:p><w:pPr><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"F2F2F2`"/><w:spacing w:before=`"0`" w:after=`"0`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Consolas`" w:hAnsi=`"Consolas`"/><w:sz w:val=`"16`"/></w:rPr><w:t xml:space=`"preserve`">$(X $cl)</w:t></w:r></w:p>")
            }
            [void]$body.Append((Para '' 8 $false '' 0 60))
            $code = $null
        } else { FlushTable; $code = New-Object System.Collections.ArrayList }
        continue
    }
    if ($null -ne $code) { [void]$code.Add($line); continue }

    if ($line -match '^\s*\|') {
        if ($line -match '^\s*\|[\s\-:|]+\|\s*$') { continue }
        if ($null -eq $table) { $table = New-Object System.Collections.ArrayList }
        [void]$table.Add(@($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() }))
        continue
    }
    FlushTable

    if ($line -match '^#\s+(.*)$') {
        [void]$body.Append((Para $Matches[1] 32 $true '1F3864' 360 120 '<w:keepNext/><w:pBdr><w:bottom w:val="single" w:sz="8" w:color="1F3864"/></w:pBdr>'))
    } elseif ($line -match '^##\s+(.*)$') {
        [void]$body.Append((Para $Matches[1] 26 $true '2E5597' 240 100 '<w:keepNext/>'))
    } elseif ($line -match '^###\s+(.*)$') {
        [void]$body.Append((Para $Matches[1] 22 $true '2E5597' 160 80 '<w:keepNext/>'))
    } elseif ($line -match '^---\s*$') {
        continue
    } elseif ($line -match '^\s*(-|\d+\.)\s+(.*)$') {
        $mark = if ($Matches[1] -eq '-') { [string][char]0x2022 } else { $Matches[1] }
        [void]$body.Append((Para "$mark  $($Matches[2])" 20 $false '' 0 40 '<w:ind w:left="360" w:hanging="240"/>'))
    } elseif ($line.Trim().Length -gt 0) {
        [void]$body.Append((Para $line))
    }
}
FlushTable

# Landscape A4, 0.5" margins
$sect = '<w:sectPr><w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/><w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="360" w:footer="360" w:gutter="0"/></w:sectPr>'
$doc = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>' + $body.ToString() + $sect + '</w:body></w:document>'
$styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/><w:sz w:val="20"/></w:rPr></w:rPrDefault></w:docDefaults></w:styles>'
$ct = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>'
$rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'
$docRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>'

Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
if (Test-Path $OutDocx) { Remove-Item $OutDocx }
$zip = [System.IO.Compression.ZipFile]::Open($OutDocx, 'Create')
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($e in @(@('[Content_Types].xml', $ct), @('_rels/.rels', $rels), @('word/document.xml', $doc), @('word/styles.xml', $styles), @('word/_rels/document.xml.rels', $docRels))) {
    $entry = $zip.CreateEntry($e[0])
    $sw = New-Object System.IO.StreamWriter($entry.Open(), $utf8)
    $sw.Write($e[1]); $sw.Close()
}
$zip.Dispose()

# Validate the XML parts parse
[xml]$null = $doc
$txt = ($lines | ForEach-Object { $_ -replace '\*\*', '' -replace '`', '' }) -join "`r`n"
[System.IO.File]::WriteAllText($OutTxt, $txt, (New-Object System.Text.UTF8Encoding($true)))
"docx: $((Get-Item $OutDocx).Length) bytes"
"txt:  $((Get-Item $OutTxt).Length) bytes"
