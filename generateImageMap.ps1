$root = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Set-Location $root

$prodText = Get-Content -Raw Product.js
$products = @()
$category = ''

foreach ($line in $prodText -split "`n") {
    if ($line -match '"([A-Z0-9\s\-/]+)"\s*:\s*\[') {
        $category = $Matches[1]
        continue
    }
    if ($line -match '"name"\s*:\s*"([^"]+)"') {
        $products += [pscustomobject]@{
            Category = $category
            Name = $Matches[1]
            Code = ($Matches[1] -split ' ')[0]
        }
    }
}

function Normalize([string]$s) {
    return ($s -replace '[^a-z0-9]', ' ' -replace '\s+', ' ').Trim().ToLower()
}

function CategoryFolder([string]$code) {
    if ($code -like 'BREAD-*') { return 'Bread' }
    if ($code -like 'CAKE-*') { return 'Cake' }
    if ($code -like 'DONUT-*') { return 'Doughnut' }
    if ($code -like 'MCN-*') { return 'Macaron' }
    if ($code -like 'MFF-*') { return 'Muffin' }
    if ($code -like 'PIZZA-*') { return 'Bread' }
    if ($code -match '^(CRT|DP|PP|TR|SCN)-') { return 'Pastry' }
    return 'Pastry'
}

$imageFiles = Get-ChildItem -Recurse -File | Where-Object { $_.Extension -match 'jpg|jpeg|png' }
$images = @()
foreach ($img in $imageFiles) {
    $rel = $img.FullName.Substring($root.Length + 1).Replace('\\', '/')
    $images += [pscustomobject]@{
        Path = $rel
        Norm = Normalize([IO.Path]::GetFileNameWithoutExtension($img.FullName))
        Folder = $rel.Split('/')[0]
    }
}

$lines = @('const IMAGE_MAP = {')

foreach ($p in $products) {
    $nameNorm = Normalize(($p.Name -replace '^\S+', '').Trim())
    $folder = CategoryFolder($p.Code)
    $candidates = $images | Where-Object { $_.Folder -eq $folder }
    if ($candidates.Count -eq 0) { $candidates = $images }

    $bestScore = -1
    $bestPath = ''
    foreach ($img in $candidates) {
        $words = $img.Norm -split ' ' | Where-Object { $_ }
        $nameWords = $nameNorm -split ' ' | Where-Object { $_ }
        $common = 0
        foreach ($w in $words) {
            if ($nameWords -contains $w) { $common++ }
        }
        $score = 0
        if ($nameWords.Count -gt 0) { $score = $common / $nameWords.Count }
        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestPath = $img.Path
        }
    }

    $escapedPath = $bestPath.Replace('\\', '\\\\').Replace('"', '\\"')
    $lines += "  \"$($p.Code)\": \"$escapedPath\"," 
}

$lines += '};'
$lines | Set-Content imageMap.js -Encoding utf8
Write-Output "Created imageMap.js with $($products.Count) entries."
Write-Output "Sample entries:"
$lines[0..20] | ForEach-Object { Write-Output $_ }
