# GRID 26 Racing — Android v0.2

Versione prototipo 3D non ufficiale sviluppata con **Godot 4.5**, Android ARM64.

## Cosa cambia in v0.2
- **Sterzo realmente manuale**: il giocatore ruota la vettura, non viene agganciato automaticamente al tracciato.
- **ACCELERA manuale**, freno e boost (il boost funziona tenendo anche premuto ACCELERA).
- La vettura rallenta rilasciando il gas, e serve **frenare forte per le curve strette**.
- Nuova pista originale **Aurora GP**: rettilinei, due tornanti, varianti a S, frenate anticipate; tracciato ispirato a categorie di curve di Monza, Bahrain e Suzuka, senza riprodurle.
- Telecamera ravvicinata sopra e dietro l'alettone, con piani near/far ottimizzati.
- Circuito ricalcolato con **un'unica mesh senza superfici sovrapposte**; ombre dinamiche disabilitate per evitare artefatti su alcuni driver mobili.
- 21 IA con anticipazione della frenata, sorpassi laterali, protezione posizione e prestazioni di scuderia differenziate.
- Uscita di pista: rallentamento su erba, recupero automatico solo per uscite profonde. Pulsante ↺ per riallinearsi se necessario.

## Gara
11 scuderie e 22 piloti della stagione 2026, 3 giri, nessuna qualifica, posizione di partenza selezionabile. Vetture e scenario 3D originali semplificati.

## Controlli
- Sinistra: **◀ / ▶** per sterzare davvero.
- Destra: **ACCELERA** da tenere premuto, **FRENO**, **BOOST** (assieme all'acceleratore).
- **↺** (in alto a sinistra rispetto ai comandi) per recuperare la vettura.
- Tastiera: A/D sterzo, W gas, S freno, Spazio boost, R recupero.

## Installazione
In **Actions** del ramo `f1-2026-android` scarica l'artefatto **GRID26-APK** della build riuscita più recente ed estrai l'APK di debug. Android 64-bit. Il package rimane `org.tony90sa.grid26`, installabile sopra la v0.1 (potrebbe essere necessario disinstallare la versione precedente se la chiave debug è diversa). Sorgenti nel repository.

## Note
Progetto indipendente, non affiliato a Formula 1 o squadre. I valori prestazionali sono stime di gioco e non dati telemetrici.
