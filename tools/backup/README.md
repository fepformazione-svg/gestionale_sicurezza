# BACKUP001 - Procedura backup e ripristino pre-MIG001

Questa cartella contiene la procedura di sicurezza per il database SQLite del gestionale prima dell'importazione dati Access MIG001.

## Punto di ripristino ufficiale

Backup locale:
C:\Users\srlsf\Documents\Gestionale Sicurezza\Backup\manuale_pre_MIG001_20260708_094820.db

Backup NAS:
Z:\Gestionale Sicurezza Backup\pre_MIG001_20260708_094820\manuale_pre_MIG001_20260708_094820.db

Hash SHA256 ufficiale:
424A3FF7374D7488EC01F378DC4D860692BB96A6516A1CE7B65655BDFBA77B05

## Copie ufficiali

Sono considerate ufficiali solo:
- copia locale in Documents\Gestionale Sicurezza\Backup
- copia NAS su Z:\Gestionale Sicurezza Backup

L'unita E: e una USB esterna/removibile e non fa parte della procedura ufficiale BACKUP001.

## Regole operative

Prima di backup, importazione o ripristino:
1. chiudere il gestionale;
2. verificare che non siano presenti file gestionale_sicurezza.db-wal o gestionale_sicurezza.db-shm;
3. non sovrascrivere mai backup esistenti;
4. usare sempre nomi file con data e ora;
5. verificare sempre hash SHA256 dopo ogni copia;
6. mantenere almeno una copia locale e una copia NAS;
7. prima di un ripristino reale creare sempre una copia di sicurezza del database corrente.

## Verifica hash

Comando PowerShell per verificare un backup:

Get-FileHash -Algorithm SHA256 "PERCORSO_DEL_BACKUP.db"

L'hash deve coincidere con quello ufficiale:
424A3FF7374D7488EC01F378DC4D860692BB96A6516A1CE7B65655BDFBA77B05

## Test ripristino non distruttivo

BACKUP001 ha eseguito un test di ripristino non distruttivo dal NAS in:
C:\Users\srlsf\Documents\Gestionale Sicurezza\Ripristino_TEST\test_restore_pre_MIG001_20260708_094820

Esito: OK. Il database operativo non e stato modificato.

## Ripristino reale controllato

Script versionato:
tools\backup\ripristino_controllato_pre_MIG001_da_NAS.ps1

Lo script esegue:
- controllo backup NAS;
- controllo manifest sha256;
- verifica hash;
- controllo file SQLite -wal e -shm;
- copia di sicurezza del database corrente;
- richiesta conferma testuale;
- ripristino controllato;
- report finale.

Conferma obbligatoria richiesta dallo script:
RIPRISTINA PRE MIG001

Non eseguire lo script per prova. Usarlo solo in caso di necessita reale.

## Procedura prima di MIG001

Prima di avviare MIG001:
1. chiudere il gestionale;
2. verificare git status;
3. verificare esistenza database operativo;
4. creare backup manuale con hash;
5. copiare backup su NAS;
6. verificare hash su NAS;
7. procedere con import Access solo dopo esito positivo.

## Stato atteso

Dopo BACKUP001L il repository deve risultare:
- branch main allineato a origin/main;
- working tree clean.
