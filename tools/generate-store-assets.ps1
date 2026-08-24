Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$screensDir = Join-Path $projectRoot 'store\screenshots'
$iconsDir = Join-Path $projectRoot 'icons'
New-Item -ItemType Directory -Force -Path $screensDir, $iconsDir | Out-Null

$palette = @{
  Route = [System.Drawing.Color]::FromArgb(24, 24, 24)
  RouteDeep = [System.Drawing.Color]::FromArgb(0, 0, 0)
  Signal = [System.Drawing.Color]::FromArgb(255, 107, 11)
  Ink = [System.Drawing.Color]::FromArgb(24, 24, 24)
  Muted = [System.Drawing.Color]::FromArgb(104, 104, 104)
  Paper = [System.Drawing.Color]::FromArgb(251, 250, 247)
  White = [System.Drawing.Color]::FromArgb(255, 255, 255)
  Canvas = [System.Drawing.Color]::FromArgb(242, 242, 244)
  Line = [System.Drawing.Color]::FromArgb(228, 228, 231)
  PaleBlue = [System.Drawing.Color]::FromArgb(238, 238, 240)
  PaleCoral = [System.Drawing.Color]::FromArgb(255, 240, 230)
  Success = [System.Drawing.Color]::FromArgb(18, 166, 106)
}

function New-Brush([System.Drawing.Color]$color) {
  return [System.Drawing.SolidBrush]::new($color)
}

function New-Font([float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular, [string]$family = 'Segoe UI Variable Display') {
  return [System.Drawing.Font]::new($family, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function New-Canvas([int]$width, [int]$height, [System.Drawing.Color]$background) {
  $bitmap = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $graphics.Clear($background)
  return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function New-RoundRectPath([float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $diameter = $radius * 2
  $path.AddArc($x, $y, $diameter, $diameter, 180, 90)
  $path.AddArc($x + $width - $diameter, $y, $diameter, $diameter, 270, 90)
  $path.AddArc($x + $width - $diameter, $y + $height - $diameter, $diameter, $diameter, 0, 90)
  $path.AddArc($x, $y + $height - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function Fill-RoundRect($graphics, [System.Drawing.Brush]$brush, [float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
  if ($null -eq $graphics) { throw "Graphics context is null in Fill-RoundRect. Stack: $((Get-PSCallStack | ForEach-Object FunctionName) -join ' > ')" }
  $path = New-RoundRectPath $x $y $width $height $radius
  $graphics.FillPath($brush, $path)
  $path.Dispose()
}

function Draw-TextBlock($graphics, [string]$text, [System.Drawing.Font]$font, [System.Drawing.Brush]$brush, [float]$x, [float]$y, [float]$width, [float]$height, [System.Drawing.StringAlignment]$alignment = [System.Drawing.StringAlignment]::Near) {
  $format = [System.Drawing.StringFormat]::new()
  $format.Alignment = $alignment
  $format.LineAlignment = [System.Drawing.StringAlignment]::Near
  $format.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
  $format.FormatFlags = [System.Drawing.StringFormatFlags]::LineLimit
  $rect = [System.Drawing.RectangleF]::new($x, $y, $width, $height)
  $graphics.DrawString($text, $font, $brush, $rect, $format)
  $format.Dispose()
}

function Draw-DirectMark($graphics, [float]$x, [float]$y, [float]$size, [bool]$withTile = $true) {
  if ($withTile) {
    $tile = New-Brush $palette.Route
    Fill-RoundRect $graphics $tile $x $y $size $size ($size * .235)
    $tile.Dispose()
  }

  $coral = New-Brush $palette.Signal
  $white = New-Brush $palette.Paper
  $graphics.FillEllipse($coral, $x + $size * .156, $y + $size * .414, $size * .172, $size * .172)

  $shaftPen = [System.Drawing.Pen]::new($palette.Paper, $size * .14)
  $shaftPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $shaftPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $graphics.DrawLine($shaftPen, $x + $size * .35, $y + $size * .5, $x + $size * .68, $y + $size * .5)
  $arrowPen = [System.Drawing.Pen]::new($palette.Paper, $size * .14)
  $arrowPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $arrowPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $arrowPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $graphics.DrawLines($arrowPen, [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new($x + $size * .59, $y + $size * .31),
    [System.Drawing.PointF]::new($x + $size * .79, $y + $size * .5),
    [System.Drawing.PointF]::new($x + $size * .59, $y + $size * .69)
  ))
  $shaftPen.Dispose(); $arrowPen.Dispose(); $coral.Dispose(); $white.Dispose()
}

function Draw-Brand($graphics, [float]$x, [float]$y, [float]$iconSize = 40, [System.Drawing.Color]$textColor = $palette.Ink) {
  Draw-DirectMark $graphics $x $y $iconSize
  $brush = New-Brush $textColor
  $font = New-Font ($iconSize * .43) ([System.Drawing.FontStyle]::Bold)
  Draw-TextBlock $graphics 'Web Please' $font $brush ($x + $iconSize + 12) ($y + $iconSize * .18) 220 ($iconSize * .7)
  $font.Dispose(); $brush.Dispose()
}

function Draw-Pill($graphics, [string]$text, [float]$x, [float]$y, [float]$width, [System.Drawing.Color]$fill, [System.Drawing.Color]$color) {
  $background = New-Brush $fill
  Fill-RoundRect $graphics $background $x $y $width 32 16
  $background.Dispose()
  $font = New-Font 12 ([System.Drawing.FontStyle]::Bold) 'Segoe UI Variable Text'
  $brush = New-Brush $color
  Draw-TextBlock $graphics $text $font $brush $x ($y + 7) $width 20 ([System.Drawing.StringAlignment]::Center)
  $font.Dispose(); $brush.Dispose()
}

function Draw-Browser($graphics, [float]$x, [float]$y, [float]$width, [float]$height, [ValidateSet('web','ai','tabs')]$mode = 'web') {
  $shadow = New-Brush ([System.Drawing.Color]::FromArgb(28, 17, 24, 39))
  Fill-RoundRect $graphics $shadow ($x + 10) ($y + 15) $width $height 24
  $shadow.Dispose()
  $white = New-Brush $palette.White
  Fill-RoundRect $graphics $white $x $y $width $height 24
  $white.Dispose()

  $chrome = New-Brush $palette.Canvas
  $graphics.FillRectangle($chrome, $x, $y + 24, $width, 74)
  $chrome.Dispose()
  $dotBrushes = @(
    (New-Brush $palette.Signal),
    (New-Brush ([System.Drawing.Color]::FromArgb(255, 191, 76))),
    (New-Brush $palette.Success)
  )
  for ($i = 0; $i -lt 3; $i++) { $graphics.FillEllipse($dotBrushes[$i], $x + 24 + 22 * $i, $y + 48, 10, 10); $dotBrushes[$i].Dispose() }
  $address = New-Brush $palette.White
  Fill-RoundRect $graphics $address ($x + 110) ($y + 38) ($width - 140) 34 17
  $address.Dispose()
  $muted = New-Brush $palette.Muted
  $addressFont = New-Font 12 ([System.Drawing.FontStyle]::Regular) 'Segoe UI Variable Text'
  Draw-TextBlock $graphics 'how to make great coffee at home' $addressFont $muted ($x + 132) ($y + 47) ($width - 184) 18

  $ink = New-Brush $palette.Ink
  $route = New-Brush $palette.Route
  $small = New-Font 12 ([System.Drawing.FontStyle]::Regular) 'Segoe UI Variable Text'
  $smallBold = New-Font 12 ([System.Drawing.FontStyle]::Bold) 'Segoe UI Variable Text'
  $resultTitle = New-Font 19 ([System.Drawing.FontStyle]::Bold)
  $tabs = @('All', 'Web', 'Images', 'News', 'Shopping')
  $tabX = $x + 38
  foreach ($tab in $tabs) {
    if ($mode -eq 'ai') { $isActive = $tab -eq 'All' } else { $isActive = $tab -eq 'Web' }
    Draw-TextBlock $graphics $tab $(if ($isActive) { $smallBold } else { $small }) $(if ($isActive) { $route } else { $muted }) $tabX ($y + 118) 70 22
    if ($isActive) { $graphics.FillRectangle($route, $tabX, $y + 144, 30, 3) }
    $tabX += 76
  }

  if ($mode -eq 'ai') {
    $panel = New-Brush $palette.PaleCoral
    Fill-RoundRect $graphics $panel ($x + 38) ($y + 174) ($width - 76) 156 18
    $panel.Dispose()
    Draw-Pill $graphics 'AI OVERVIEW' ($x + 58) ($y + 194) 110 $palette.White $palette.Ink
    $line = [System.Drawing.Pen]::new($palette.Signal, 4)
    $line.StartCap = [System.Drawing.Drawing2D.LineCap]::Round; $line.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $graphics.DrawLine($line, $x + 58, $y + 248, $x + $width - 88, $y + 248)
    $graphics.DrawLine($line, $x + 58, $y + 274, $x + $width - 150, $y + 274)
    $graphics.DrawLine($line, $x + 58, $y + 300, $x + $width - 200, $y + 300)
    $line.Dispose()
    $contentY = $y + 360
  } else {
    $contentY = $y + 178
  }

  $resultCount = if ($mode -eq 'ai') { 1 } else { 2 }
  for ($i = 0; $i -lt $resultCount; $i++) {
    $rowY = $contentY + $i * 116
    $favicon = New-Brush $(if ($i -eq 0) { $palette.Route } else { $palette.Signal })
    $graphics.FillEllipse($favicon, $x + 40, $rowY, 24, 24)
    $favicon.Dispose()
    Draw-TextBlock $graphics $(if ($i -eq 0) { 'Home Barista' } else { 'Coffee Notes' }) $small $ink ($x + 74) ($rowY + 2) 180 20
    Draw-TextBlock $graphics $(if ($i -eq 0) { 'A practical guide to better coffee at home' } else { 'Five small changes that improve every cup' }) $resultTitle $route ($x + 40) ($rowY + 36) ($width - 80) 32
    Draw-TextBlock $graphics 'Clear advice, useful links, and the details you came to find.' $small $muted ($x + 40) ($rowY + 73) ($width - 80) 24
  }

  if ($mode -eq 'tabs') {
    $callout = New-Brush $palette.PaleBlue
    Fill-RoundRect $graphics $callout ($x + $width - 188) ($y + 106) 150 48 24
    $callout.Dispose()
    Draw-TextBlock $graphics 'Tabs stay available' $smallBold $route ($x + $width - 172) ($y + 121) 120 20
  }

  $addressFont.Dispose(); $small.Dispose(); $smallBold.Dispose(); $resultTitle.Dispose()
  $muted.Dispose(); $ink.Dispose(); $route.Dispose()
}

function Draw-Popup($graphics, [float]$x, [float]$y, [float]$scale = 1) {
  $width = 360 * $scale; $height = 400 * $scale
  $shadow = New-Brush ([System.Drawing.Color]::FromArgb(42, 17, 24, 39))
  Fill-RoundRect $graphics $shadow ($x + 12 * $scale) ($y + 16 * $scale) $width $height (24 * $scale)
  $shadow.Dispose()
  $paper = New-Brush $palette.Paper
  Fill-RoundRect $graphics $paper $x $y $width $height (24 * $scale)
  $paper.Dispose()

  Draw-Brand $graphics ($x + 20 * $scale) ($y + 20 * $scale) (32 * $scale)
  Draw-Pill $graphics '●  ACTIVE' ($x + 250 * $scale) ($y + 22 * $scale) (86 * $scale) ([System.Drawing.Color]::FromArgb(239,250,245)) ([System.Drawing.Color]::FromArgb(8,122,75))

  $route = New-Brush $palette.Route; $action = New-Brush $palette.Signal; $ink = New-Brush $palette.Ink; $muted = New-Brush $palette.Muted; $white = New-Brush $palette.White
  $eyebrow = New-Font (10 * $scale) ([System.Drawing.FontStyle]::Bold) 'Segoe UI Variable Text'
  $headline = New-Font (27 * $scale) ([System.Drawing.FontStyle]::Bold)
  $body = New-Font (13 * $scale) ([System.Drawing.FontStyle]::Regular) 'Segoe UI Variable Text'
  $label = New-Font (14 * $scale) ([System.Drawing.FontStyle]::Bold)
  $micro = New-Font (10.5 * $scale) ([System.Drawing.FontStyle]::Regular) 'Segoe UI Variable Text'
  Draw-TextBlock $graphics 'GOOGLE WEB MODE' $eyebrow $action ($x + 22 * $scale) ($y + 78 * $scale) (220 * $scale) (20 * $scale)
  Draw-TextBlock $graphics 'Straight to the web.' $headline $ink ($x + 20 * $scale) ($y + 103 * $scale) (310 * $scale) (42 * $scale)
  Draw-TextBlock $graphics 'Skip the AI Overview. Keep the links and search tools you use.' $body $muted ($x + 20 * $scale) ($y + 150 * $scale) (300 * $scale) (44 * $scale)

  Fill-RoundRect $graphics $ink ($x + 20 * $scale) ($y + 212 * $scale) (320 * $scale) (92 * $scale) (18 * $scale)
  Draw-TextBlock $graphics 'Web results are on' $label $white ($x + 37 * $scale) ($y + 233 * $scale) (190 * $scale) (22 * $scale)
  $subtle = New-Brush ([System.Drawing.Color]::FromArgb(184,192,209))
  Draw-TextBlock $graphics "Ordinary searches open in Google's Web view." $micro $subtle ($x + 37 * $scale) ($y + 260 * $scale) (205 * $scale) (32 * $scale)
  Fill-RoundRect $graphics $action ($x + 270 * $scale) ($y + 243 * $scale) (52 * $scale) (30 * $scale) (15 * $scale)
  $graphics.FillEllipse($white, $x + 295 * $scale, $y + 246 * $scale, 24 * $scale, 24 * $scale)

  Draw-TextBlock $graphics '✓  Search processing stays on your device.' $micro $muted ($x + 22 * $scale) ($y + 326 * $scale) (310 * $scale) (22 * $scale)
  $linePen = [System.Drawing.Pen]::new($palette.Line, 1)
  $graphics.DrawLine($linePen, $x + 20 * $scale, $y + 362 * $scale, $x + 340 * $scale, $y + 362 * $scale)
  $linePen.Dispose()
  Draw-TextBlock $graphics 'Images, News, and other tabs still work.' $micro $muted ($x + 22 * $scale) ($y + 375 * $scale) (205 * $scale) (18 * $scale)
  Draw-TextBlock $graphics 'Support on Ko-fi ↗' $micro $route ($x + 240 * $scale) ($y + 375 * $scale) (100 * $scale) (18 * $scale) ([System.Drawing.StringAlignment]::Far)

  $route.Dispose(); $action.Dispose(); $ink.Dispose(); $muted.Dispose(); $white.Dispose(); $subtle.Dispose()
  $eyebrow.Dispose(); $headline.Dispose(); $body.Dispose(); $label.Dispose(); $micro.Dispose()
}

function Save-Jpeg($canvas, [string]$path) {
  $canvas.Graphics.Dispose()
  $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
  $parameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
  $parameters.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, [long]94)
  $canvas.Bitmap.Save($path, $codec, $parameters)
  $parameters.Dispose(); $canvas.Bitmap.Dispose()
}

function Write-Headline($graphics, [string]$kicker, [string]$headline, [string]$body, [float]$x, [float]$y, [float]$width, [System.Drawing.Color]$headlineColor = $palette.Ink) {
  $route = New-Brush $palette.Route; $ink = New-Brush $headlineColor; $muted = New-Brush $palette.Muted
  $kickerFont = New-Font 14 ([System.Drawing.FontStyle]::Bold) 'Segoe UI Variable Text'
  $headlineFont = New-Font 48 ([System.Drawing.FontStyle]::Bold)
  $bodyFont = New-Font 20 ([System.Drawing.FontStyle]::Regular) 'Segoe UI Variable Text'
  Draw-TextBlock $graphics $kicker $kickerFont $route $x $y $width 24
  Draw-TextBlock $graphics $headline $headlineFont $ink $x ($y + 42) $width 188
  Draw-TextBlock $graphics $body $bodyFont $muted $x ($y + 232) $width 84
  $route.Dispose(); $ink.Dispose(); $muted.Dispose(); $kickerFont.Dispose(); $headlineFont.Dispose(); $bodyFont.Dispose()
}

function Save-Icon([int]$size) {
  $sourceSize = 1024
  $bitmap = [System.Drawing.Bitmap]::new($sourceSize, $sourceSize, [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.Clear([System.Drawing.Color]::Transparent)
  Draw-DirectMark $graphics 128 128 768
  $graphics.Dispose()

  $output = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
  $resize = [System.Drawing.Graphics]::FromImage($output)
  $resize.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $resize.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $resize.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $resize.DrawImage($bitmap, 0, 0, $size, $size)
  $resize.Dispose(); $bitmap.Dispose()
  $output.Save((Join-Path $iconsDir "icon$size.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $output.Dispose()
}

foreach ($iconSize in @(16, 32, 48, 128)) { Save-Icon $iconSize }

# Screenshot 1 — core promise
$canvas = New-Canvas 1280 800 $palette.Paper; $g = $canvas.Graphics
Draw-Brand $g 68 56 42
Write-Headline $g 'NO DETOURS' "Skip AI Overviews.`nKeep the web." "Every ordinary Google search opens in Google's clean Web view." 68 158 520
Draw-Browser $g 632 94 582 620 'web'
Save-Jpeg $canvas (Join-Path $screensDir '01-straight-to-the-web.jpg')

# Screenshot 2 — product UI
$canvas = New-Canvas 1280 800 $palette.Canvas; $g = $canvas.Graphics
$bluePanel = New-Brush $palette.Route; Fill-RoundRect $g $bluePanel 54 54 1172 692 34; $bluePanel.Dispose()
$white = New-Brush $palette.White; $coral = New-Brush $palette.Signal
$kicker = New-Font 14 ([System.Drawing.FontStyle]::Bold) 'Segoe UI Variable Text'; $headline = New-Font 58 ([System.Drawing.FontStyle]::Bold); $body = New-Font 20
Draw-TextBlock $g 'ONE SWITCH. ZERO SETUP.' $kicker $white 100 132 430 28
Draw-TextBlock $g "Set it once.`nSearch as usual." $headline $white 96 185 480 190
Draw-TextBlock $g 'Pause it any time from the Chrome toolbar.' $body $white 100 390 390 64
$g.FillEllipse($coral, 100, 493, 18, 18); $g.FillRectangle($white, 126, 499, 290, 6)
Draw-Popup $g 706 94 1.38
$white.Dispose(); $coral.Dispose(); $kicker.Dispose(); $headline.Dispose(); $body.Dispose()
Save-Jpeg $canvas (Join-Path $screensDir '02-one-switch.jpg')

# Screenshot 3 — before and after
$canvas = New-Canvas 1280 800 $palette.Paper; $g = $canvas.Graphics
Draw-Brand $g 68 48 38
$ink = New-Brush $palette.Ink; $muted = New-Brush $palette.Muted
$headline = New-Font 46 ([System.Drawing.FontStyle]::Bold); $body = New-Font 18
Draw-TextBlock $g 'Same search. Less preamble.' $headline $ink 68 120 760 72
Draw-TextBlock $g 'Web Please changes the destination—not the page after it loads.' $body $muted 70 195 760 38
Draw-Pill $g 'WITHOUT' 70 274 92 $palette.PaleCoral $palette.Ink
Draw-Pill $g 'WITH WEB PLEASE' 650 274 144 $palette.PaleBlue $palette.Route
Draw-Browser $g 70 322 540 410 'ai'
Draw-Browser $g 650 322 560 410 'web'
$ink.Dispose(); $muted.Dispose(); $headline.Dispose(); $body.Dispose()
Save-Jpeg $canvas (Join-Path $screensDir '03-before-after.jpg')

# Screenshot 4 — privacy and technical differentiation
$canvas = New-Canvas 1280 800 $palette.Ink; $g = $canvas.Graphics
Draw-Brand $g 68 56 42 $palette.White
$white = New-Brush $palette.White; $soft = New-Brush ([System.Drawing.Color]::FromArgb(184,192,209)); $route = New-Brush $palette.Route
$headline = New-Font 54 ([System.Drawing.FontStyle]::Bold); $body = New-Font 19; $cardTitle = New-Font 20 ([System.Drawing.FontStyle]::Bold); $cardBody = New-Font 14
Draw-TextBlock $g 'Quiet by design.' $headline $white 68 158 520 75
Draw-TextBlock $g 'No account. No analytics. No page scanning.' $body $soft 70 244 620 42
$cardData = @()
$cardData += [pscustomobject]@{ X = 70; Label = '01'; Title = 'Local only'; Body = 'Your queries never leave Chrome.' }
$cardData += [pscustomobject]@{ X = 465; Label = '02'; Title = 'No fragile hiding'; Body = "Uses Google's own Web view." }
$cardData += [pscustomobject]@{ X = 860; Label = '03'; Title = 'Open source'; Body = 'Small enough to inspect yourself.' }
foreach ($card in $cardData) {
  $cardBrush = New-Brush ([System.Drawing.Color]::FromArgb(38,38,38)); Fill-RoundRect $g $cardBrush $card.X 368 350 272 24; $cardBrush.Dispose()
  Draw-Pill $g $card.Label ($card.X + 26) 394 48 $palette.Route $palette.White
  Draw-TextBlock $g $card.Title $cardTitle $white ($card.X + 26) 470 296 34
  Draw-TextBlock $g $card.Body $cardBody $soft ($card.X + 26) 524 296 56
  $orangePen = [System.Drawing.Pen]::new($palette.Signal, 4); $orangePen.StartCap = 'Round'; $orangePen.EndCap = 'Round'
  $g.DrawLine($orangePen, $card.X + 26, 600, $card.X + 112, 600); $orangePen.Dispose()
}
$white.Dispose(); $soft.Dispose(); $route.Dispose(); $headline.Dispose(); $body.Dispose(); $cardTitle.Dispose(); $cardBody.Dispose()
Save-Jpeg $canvas (Join-Path $screensDir '04-private-by-design.jpg')

# Screenshot 5 — search verticals
$canvas = New-Canvas 1280 800 $palette.Paper; $g = $canvas.Graphics
Draw-Brand $g 68 48 38
Write-Headline $g 'YOUR SEARCH, INTACT' "Web by default.`nEvery tab stays." 'Images, News, Shopping, and other search tabs remain one click away.' 68 142 480
Draw-Browser $g 590 92 620 630 'tabs'
Save-Jpeg $canvas (Join-Path $screensDir '05-tabs-stay-yours.jpg')

# Small promo tile
$canvas = New-Canvas 440 280 $palette.Route; $g = $canvas.Graphics
$paper = New-Brush $palette.Paper; $signal = New-Brush $palette.Signal
Draw-DirectMark $g 28 26 54
$brandFont = New-Font 17 ([System.Drawing.FontStyle]::Bold); $headline = New-Font 34 ([System.Drawing.FontStyle]::Bold); $body = New-Font 14
Draw-TextBlock $g 'Web Please' $brandFont $paper 96 39 210 28
Draw-TextBlock $g "Skip AI Overviews.`nKeep the web." $headline $paper 28 106 360 92
Draw-TextBlock $g 'Google Web results, automatically.' $body $paper 30 226 300 26
$g.FillEllipse($signal, 389, 225, 18, 18)
$paper.Dispose(); $signal.Dispose(); $brandFont.Dispose(); $headline.Dispose(); $body.Dispose()
Save-Jpeg $canvas (Join-Path $projectRoot 'store\promo-small.jpg')

# Marquee promo tile
$canvas = New-Canvas 1400 560 $palette.Ink; $g = $canvas.Graphics
$blue = New-Brush $palette.Route; Fill-RoundRect $g $blue 810 -80 670 720 80; $blue.Dispose()
Draw-Brand $g 70 60 46 $palette.White
$white = New-Brush $palette.White; $soft = New-Brush ([System.Drawing.Color]::FromArgb(184,192,209)); $signal = New-Brush $palette.Signal
$kicker = New-Font 15 ([System.Drawing.FontStyle]::Bold) 'Segoe UI Variable Text'; $headline = New-Font 58 ([System.Drawing.FontStyle]::Bold); $body = New-Font 19
Draw-TextBlock $g 'GOOGLE WEB MODE, AUTOMATICALLY' $kicker $signal 70 166 590 28
Draw-TextBlock $g "Skip the summary.`nKeep the web." $headline $white 66 220 640 180
Draw-TextBlock $g 'One switch. No tracking. No page scanning.' $body $soft 70 400 600 36
Draw-Popup $g 906 36 1.2
$white.Dispose(); $soft.Dispose(); $signal.Dispose(); $kicker.Dispose(); $headline.Dispose(); $body.Dispose()
Save-Jpeg $canvas (Join-Path $projectRoot 'store\promo-marquee.jpg')

Write-Output 'Generated Web Please icons and Chrome Web Store assets.'
