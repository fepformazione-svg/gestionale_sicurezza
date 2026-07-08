# BACKUP001G - Ripristino controllato pre-MIG001 da NAS
# ATTENZIONE:
# Questo script ripristina il database operativo del gestionale da un backup NAS verificato.
# Usarlo solo in caso di necessita, con gestionale chiuso.
# Non usare se non si e certi di voler sostituire il database operativo.

$ErrorActionPreference = "Stop"

$expectedHash = "424A3FF7374D7488EC01F378DC4D860692BB96A6516A1CE7B65655BDFBA77B05"

$base = Join-Path $env:USERPROFILE "Documents\Gestionale Sicurezza"
$dbOperativo = Join-Path $base "gestionale_sicurezza.db"

$nasDir = "Z:\Gestionale Sicurezza Backup\pre_MIG001_20260708_094820"
$backupName = "manuale_pre_MIG001_20260708_094820.db"
$nasBackup = Join-Path $nasDir $backupName
$nasManifest = "$nasBackup.sha256.txt"

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$safetyDir = Join-Path $base "Ripristino_SICUREZZA"
$safetyBackup = Join-Path $safetyDir "prima_del_ripristino_$timestamp.db"
$restoreReport = Join-Path $safetyDir "report_ripristino_pre_MIG001_$timestamp.txt"

Write-Host "=== RIPRISTINO CONTROLLATO PRE-MIG001 DA NAS ==="
Write-Host ""
Write-Host "Questo script SOSTITUIRA il database operativo solo dopo conferma esplicita."
Write-Host "Gestionale da tenere CHIUSO prima di continuare."
Write-Host ""

Write-Host "Database operativo:"
Write-Host $dbOperativo

Write-Host ""
Write-Host "Backup NAS:"
Write-Host $nasBackup

if (-not (Test-Path $dbOperativo)) {
    throw "Database operativo non trovato: $dbOperativo"
}

if (-not (Test-Path $nasBackup)) {
    throw "Backup NAS non trovato: $nasBackup"
}

if (-not (Test-Path $nasManifest)) {
    throw "Manifest NAS non trovato: $nasManifest"
}

$dbWal = "$dbOperativo-wal"
$dbShm = "$dbOperativo-shm"

if ((Test-Path $dbWal) -or (Test-Path $dbShm)) {
    throw "Sono presenti file SQLite -wal o -shm. Chiudere il gestionale e riprovare."
}

$nasHash = Get-FileHash -Algorithm SHA256 $nasBackup

Write-Host ""
Write-Host "Hash atteso:"
Write-Host $expectedHash
Write-Host "Hash backup NAS:"
Write-Host $nasHash.Hash

if ($nasHash.Hash -ne $expectedHash) {
    throw "Hash NAS non corrispondente. Ripristino interrotto."
}

if (-not (Test-Path $safetyDir)) {
    New-Item -ItemType Directory -Path $safetyDir | Out-Null
}

if (Test-Path $safetyBackup) {
    throw "Backup di sicurezza gia esistente. Ripristino interrotto: $safetyBackup"
}

Write-Host ""
Write-Host "Prima del ripristino verra creata questa copia di sicurezza del DB attuale:"
Write-Host $safetyBackup

Write-Host ""
Write-Host "Per procedere scrivere esattamente:"
Write-Host "RIPRISTINA PRE MIG001"
$confirm = Read-Host "Conferma"

if ($confirm -ne "RIPRISTINA PRE MIG001") {
    Write-Host "Conferma non valida. Nessuna modifica eseguita."
    exit 1
}

Copy-Item -Path $dbOperativo -Destination $safetyBackup -ErrorAction Stop

$safetyHash = Get-FileHash -Algorithm SHA256 $safetyBackup
$dbBeforeHash = Get-FileHash -Algorithm SHA256 $dbOperativo

Copy-Item -Path $nasBackup -Destination $dbOperativo -Force -ErrorAction Stop

$dbAfterHash = Get-FileHash -Algorithm SHA256 $dbOperativo

if ($dbAfterHash.Hash -ne $expectedHash) {
    throw "Ripristino eseguito ma hash finale non coerente. Verificare immediatamente."
}

@"
BACKUP001G - RIPRISTINO CONTROLLATO PRE-MIG001 DA NAS
Eseguito il: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Database operativo ripristinato:
$dbOperativo

Backup NAS usato:
$nasBackup

Copia di sicurezza del DB precedente:
$safetyBackup

SHA256 atteso:
$expectedHash

SHA256 DB operativo prima del ripristino:
$($dbBeforeHash.Hash)

SHA256 copia sicurezza:
$($safetyHash.Hash)

SHA256 DB operativo dopo il ripristino:
$($dbAfterHash.Hash)

Esito:
OK - database operativo ripristinato dal backup NAS pre-MIG001

Nota:
Il DB precedente non e stato eliminato. E conservato nella cartella Ripristino_SICUREZZA.
"@ | Set-Content -Path $restoreReport -Encoding UTF8

Write-Host ""
Write-Host "=== ESITO RIPRISTINO ==="
Write-Host "OK: database operativo ripristinato dal backup NAS pre-MIG001."
Write-Host "Copia di sicurezza precedente:"
Write-Host $safetyBackup
Write-Host "Report:"
Write-Host $restoreReport
