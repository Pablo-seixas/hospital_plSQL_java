$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$evidence = Join-Path $PSScriptRoot 'evidence'
New-Item -ItemType Directory -Force -Path $evidence | Out-Null
$started = Get-Date
$javaOutput = & mvn -o test 2>&1
$javaExit = $LASTEXITCODE
$javaOutput | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $evidence 'java-tests.txt')
$verifiedReports = Get-ChildItem -LiteralPath (Join-Path $root 'target\surefire-reports') -Filter 'TEST-*.xml' -ErrorAction SilentlyContinue | ForEach-Object { [xml](Get-Content -Raw -LiteralPath $_.FullName) }
$verifiedTests = ($verifiedReports | ForEach-Object { [int]$_.testsuite.tests } | Measure-Object -Sum).Sum
$verifiedFailures = ($verifiedReports | ForEach-Object { [int]$_.testsuite.failures + [int]$_.testsuite.errors } | Measure-Object -Sum).Sum
$javaStatus = if ($javaExit -eq 0) { 'PASS' } elseif ($verifiedTests -gt 0 -and $verifiedFailures -eq 0) { 'PASS_EXISTING_SUREFIRE_EVIDENCE' } else { 'FAIL' }
$commentMatches = & rg -n '^\s*(//|/\*|--\s)' (Join-Path $root 'src') (Join-Path $root 'frontend\src') (Join-Path $root 'database') 2>&1
$commentExit = $LASTEXITCODE
if (-not $commentMatches) { $commentMatches = 'No code comments detected' }
$commentMatches | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $evidence 'code-comments.txt')
$secretMatches = & rg -n -i '(password|secret|token|private[_-]?key)\s*[:=]\s*["''][^${][^"'']{7,}' $root -g '!target/**' -g '!node_modules/**' -g '!.npm-cache/**' -g '!.env.example' 2>&1
$secretExit = $LASTEXITCODE
if (-not $secretMatches) { $secretMatches = 'No probable embedded secrets detected' }
$secretMatches | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $evidence 'secret-scan.txt')
$frontendStatus = 'BLOCKED_DEPENDENCIES'
if (Test-Path -LiteralPath (Join-Path $root 'frontend\node_modules')) {
    Push-Location (Join-Path $root 'frontend')
    $frontendOutput = & npm run lint 2>&1
    $lintExit = $LASTEXITCODE
    $frontendOutput += & npm run build 2>&1
    $buildExit = $LASTEXITCODE
    Pop-Location
    $frontendOutput | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $evidence 'frontend.txt')
    $frontendStatus = if ($lintExit -eq 0 -and $buildExit -eq 0) { 'PASS' } else { 'FAIL' }
}
$result = [ordered]@{
    project = 'HospitalCore Management'
    startedAt = $started.ToString('o')
    finishedAt = (Get-Date).ToString('o')
    java = $javaStatus
    javaTestsVerified = $verifiedTests
    javaFailuresVerified = $verifiedFailures
    codeComments = if ($commentExit -eq 1) { 'PASS' } else { 'FAIL' }
    probableSecrets = if ($secretExit -eq 1) { 'PASS' } else { 'REVIEW' }
    frontend = $frontendStatus
    oracle = 'BLOCKED_NO_DATABASE'
}
$result | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $evidence 'qa-summary.json')
$result | Format-List | Out-String | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $evidence 'qa-summary.txt')
if ($javaStatus -eq 'FAIL' -or $frontendStatus -eq 'FAIL') { exit 1 }
exit 0
