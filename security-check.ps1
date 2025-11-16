# Pre-Push Security Verification Script
# Run this before pushing to GitHub

Write-Host "SORTYX SECURITY CHECK" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

$issues = 0

# Check 1: Verify .env files are ignored
Write-Host "✓ Checking .env files are gitignored..." -ForegroundColor Yellow
$envCheck = git check-ignore backend/.env
if ($envCheck) {
    Write-Host "  ✅ backend/.env is properly ignored" -ForegroundColor Green
} else {
    Write-Host "  ❌ WARNING: backend/.env is NOT ignored!" -ForegroundColor Red
    $issues++
}

# Check 2: Look for potential secrets in staged files
Write-Host ""
Write-Host "✓ Checking for API keys in code..." -ForegroundColor Yellow
$apiKeyCheck = git grep -i "AIzaSy" 2>$null
if ($apiKeyCheck) {
    Write-Host "  ❌ WARNING: Found potential API keys in code!" -ForegroundColor Red
    Write-Host "  $apiKeyCheck" -ForegroundColor Red
    $issues++
} else {
    Write-Host "  ✅ No hardcoded API keys found" -ForegroundColor Green
}

# Check 3: Verify .env contains placeholder only
Write-Host ""
Write-Host "✓ Checking backend/.env contents..." -ForegroundColor Yellow
if (Test-Path "backend/.env") {
    $envContent = Get-Content "backend/.env" -Raw
    if ($envContent -match "your_gemini_api_key_here" -or $envContent -match "your_actual_key_here") {
        Write-Host "  ✅ backend/.env contains placeholder values" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  WARNING: backend/.env may contain real credentials!" -ForegroundColor Red
        Write-Host "  Please verify and replace with placeholder before pushing" -ForegroundColor Yellow
        $issues++
    }
} else {
    Write-Host "  ⚠️  backend/.env not found (okay if deleted)" -ForegroundColor Yellow
}

# Check 4: Verify config.js is present
Write-Host ""
Write-Host "✓ Checking frontend configuration..." -ForegroundColor Yellow
if (Test-Path "frontend/config.js") {
    Write-Host "  ✅ frontend/config.js exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ WARNING: frontend/config.js not found!" -ForegroundColor Red
    $issues++
}

# Check 5: List files that will be committed
Write-Host ""
Write-Host "✓ Files to be committed:" -ForegroundColor Yellow
git status --short

# Check 6: Verify no .env in staged files
Write-Host ""
Write-Host "✓ Verifying no .env files are staged..." -ForegroundColor Yellow
$stagedEnv = git diff --cached --name-only | Select-String "\.env$" | Select-String -NotMatch "\.env\.example"
if ($stagedEnv) {
    Write-Host "  ❌ CRITICAL: .env files are staged for commit!" -ForegroundColor Red
    Write-Host "  $stagedEnv" -ForegroundColor Red
    $issues++
} else {
    Write-Host "  ✅ No .env files staged" -ForegroundColor Green
}

# Final verdict
Write-Host ""
Write-Host "=========================" -ForegroundColor Cyan
if ($issues -eq 0) {
    Write-Host "✅ SECURITY CHECK PASSED" -ForegroundColor Green
    Write-Host "Repository is safe to push to GitHub!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  git add ." -ForegroundColor White
    Write-Host "  git commit -m `"your commit message`"" -ForegroundColor White
    Write-Host "  git push origin main" -ForegroundColor White
} else {
    Write-Host "❌ SECURITY CHECK FAILED" -ForegroundColor Red
    Write-Host "Found $issues issue(s). Please fix before pushing!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Review SECURITY_CHECKLIST.md for details" -ForegroundColor Yellow
}
Write-Host ""
