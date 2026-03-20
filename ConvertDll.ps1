param(
    [Parameter(Mandatory=$true)] [string]$inFile,
    [Parameter(Mandatory=$true)] [string]$outFile
)

if (-not (Test-Path $inFile)) {
    Write-Host "Waiting for DLL..."
    Start-Sleep -Seconds 1
    if (-not (Test-Path $inFile)) {
        Write-Error "DLL not found: $inFile"
        exit 1
    }
}

$bytes = [IO.File]::ReadAllBytes($inFile)
$sb = [System.Text.StringBuilder]::new()
$sb.AppendLine("#pragma once") | Out-Null
$sb.AppendLine("") | Out-Null
$sb.AppendLine("static const unsigned char g_CheatDll[] = {") | Out-Null

for ($i = 0; $i -lt $bytes.Length; $i++) {
    if ($i % 16 -eq 0) { $sb.Append("    ") | Out-Null }
    $sb.Append("0x{0:X2}, " -f $bytes[$i]) | Out-Null
    if ($i % 16 -eq 15) { $sb.AppendLine() | Out-Null }
}

$sb.AppendLine() | Out-Null
$sb.AppendLine("};") | Out-Null
$sb.AppendLine("") | Out-Null
$sb.AppendFormat("static const unsigned int g_CheatDllSize = {0};`r`n", $bytes.Length) | Out-Null

[IO.File]::WriteAllText($outFile, $sb.ToString())
Write-Host "Successfully generated $outFile"
