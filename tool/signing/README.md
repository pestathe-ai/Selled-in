# Chiave di firma

`app.jks` è la chiave con cui vengono firmate le versioni, così ogni aggiornamento
si installa sopra il precedente senza perdere i dati.
La password NON è nel repository: sta nel segreto `KEYSTORE_PASSWORD`
(Settings → Secrets and variables → Actions). Senza il segreto l'APK viene firmato
con una chiave di debug temporanea.
