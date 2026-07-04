<#
.SYNOPSIS
    One-click build of the Solar & Storage Interconnection Tracker (.accdb).

.DESCRIPTION
    Requires Microsoft Access (Microsoft 365 / 2016+) on Windows.
    Creates a new .accdb at the repo root, imports every VBA module from
    \src, then runs BuildSolarStorageApp, which creates all tables, imports
    data\InterconnectionProjects.xlsx, and generates the forms and reports.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\Build-AccessApp.ps1
#>
param(
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$srcDir   = Join-Path $repoRoot "src"
if (-not $OutputPath) { $OutputPath = Join-Path $repoRoot "SolarStorageTracker.accdb" }

if (Test-Path $OutputPath) {
    Write-Host "Removing existing database: $OutputPath"
    Remove-Item $OutputPath -Force
}

$modules = Get-ChildItem -Path $srcDir -Filter "*.bas" | Sort-Object Name
if ($modules.Count -eq 0) { throw "No .bas modules found in $srcDir" }

Write-Host "Starting Microsoft Access..."
$access = New-Object -ComObject Access.Application
try {
    $access.Visible = $true
    $access.AutomationSecurity = 1   # msoAutomationSecurityLow - allow our just-imported VBA to run

    Write-Host "Creating database: $OutputPath"
    $access.NewCurrentDatabase($OutputPath)

    foreach ($m in $modules) {
        Write-Host "Importing module: $($m.BaseName)"
        # 5 = acModule
        $access.LoadFromText(5, $m.BaseName, $m.FullName)
    }

    Write-Host "Running BuildSolarStorageApp..."
    $access.Run("BuildSolarStorageApp", $true) | Out-Null

    $access.CloseCurrentDatabase()
    Write-Host ""
    Write-Host "Build complete: $OutputPath"
    Write-Host "Open it in Access - the dashboard (frmDashboard) opens automatically."
}
finally {
    $access.Quit()
    [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($access)
}
