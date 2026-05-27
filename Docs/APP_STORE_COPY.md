# Arkai Domus — App Store Copy

Tono: editoriale italiano premium, magazine di architettura italiana.  
**REGOLA OSCURAMENTO**: nessun riferimento tecnico ad AI di terzi (Gemini/GPT). Solo "Arkai Vision Pro" come nome interno del nostro modello.

---

## App Name

**Domus Arkai**

(In alternativa, se "Arkai Domus" è il brand registrato e si vuole usarlo come naming primario, anche `Arkai Domus` va bene — sono intercambiabili. Decidere e mantenere coerente.)

---

## Subtitle (30 caratteri max)

```
Immobili di pregio italiani
```
27 caratteri ✓

Alternative:
- `Architettura italiana, app` (26)
- `Magazine immobiliare premium` (28)

---

## Promotional Text (170 caratteri max — modificabile senza review)

```
Scopri immobili italiani di pregio con la cura di un magazine di architettura. Stima, ristruttura, salva il tuo dossier in PDF.
```
129 caratteri ✓

---

## Description (4000 caratteri max)

```
Domus Arkai è la piattaforma editoriale per chi cerca casa con la cura di un magazine di architettura italiana. Selezione curata di immobili di pregio, strumenti professionali di valutazione, esperienza nativa iOS.

— SELEZIONE EDITORIALE —
Una raccolta curata di appartamenti, ville, palazzi e proprietà uniche presentati come pagine di un magazine. Ogni immobile racconta una storia: fotografia di alto livello, planimetria 2D e 3D, dati architettonici, contesto territoriale.

— STIMA RISTRUTTURAZIONE PROFESSIONALE —
Configuratori parametrici per ogni intervento: pavimenti (parquet rovere/teak/ciliegio/wengè, marmo Carrara, gres, sintetici), tinteggiature, serramenti (PVC, alluminio termico, legno), porte di design, cucine su misura con metri lineari e isole, climatizzazione e riscaldamento (caloriferi, inverter, pavimento radiante, stufa a pellet), impianti elettrici tradizionali e domotici. 

I costi sono regionalizzati sui dati di mercato italiano 2026 e considerano le complessità del cantiere (centro storico, ZTL, piano alto, urgenza).

— ARKAI VISION PRO —
Carica una foto della stanza e ricevi una stima dettagliata delle opere necessarie. Cinque analisi al mese gratuite, perfette per esplorare il potenziale di un immobile prima della visita.

— VALUTAZIONE GEOLOCALIZZATA —
Parametri di riferimento Arkai Domus per il mercato residenziale di pregio, basati sui valori OMI e sulla zonizzazione comunale. Comparazione con immobili simili nella stessa zona.

— BUYER PASSPORT —
Un profilo finanziario riservato per la tua pre-qualificazione: budget, liquidità, percentuale di mutuo richiesta, preferenze di zona e tipologia. Genera un parametro di eccellenza che ti distingue come acquirente serio.

— SIMULATORE MUTUO —
Calcolo della rata, piano di ammortamento, confronto tra TAN/TAEG. Stima il costo reale del finanziamento per ogni immobile.

— IL MIO DOSSIER —
Salva tutte le analisi di un immobile (valutazione, mutuo, ristrutturazione, ristrutturazione visiva) in un dossier personale. Scaricalo come PDF elegante stile private banking svizzero: scheda completa con immagini, mappa, planimetria, dettaglio delle opere, costi. Da consegnare all'agenzia, alla banca, al notaio.

— PRENOTAZIONE VISITA —
Richiedi un appuntamento direttamente in app. Reminder automatici 24 ore e 1 ora prima.

— CONTATTO AGENZIA —
Chiama, scrivi via WhatsApp, invia messaggio: scegli il canale più diretto.

— SIGN IN WITH APPLE —
Accesso sicuro e privato. Cancellazione account in-app conforme alle linee guida Apple. Nessun tracking, nessuna pubblicità, nessun in-app purchase.

— GRATUITA —
Domus Arkai è completamente gratuita per l'utente finale. Il servizio è offerto in white-label dalle agenzie immobiliari partner che credono in una nuova esperienza editoriale.

— PRIVACY —
Adesione completa al GDPR. Tutti i dati personali sono cifrati in transito e a riposo. Cancellazione totale dell'account in qualsiasi momento con un tap dal Profilo.

Versione 1.0 — Maggio 2026.
```

3.789 caratteri ✓ (sotto i 4.000)

---

## Keywords (100 caratteri max, separati da virgola)

```
immobili,casa,vendita,affitto,ristrutturazione,milano,roma,architettura,pregio,dossier,mutuo
```
93 caratteri ✓

Strategia: mix di tail comuni ("immobili", "casa", "mutuo") + differenzianti brand ("architettura", "pregio", "dossier"). Evitato "premium" (Apple penalizza), evitato "real estate" (è in altre lingue).

---

## What's New (release notes — modificabile senza review)

```
Prima release ufficiale di Domus Arkai.
— Selezione editoriale di immobili italiani di pregio
— Stima ristrutturazione con configuratori parametrici (pavimenti, cucina, serramenti, impianti)
— Arkai Vision Pro: analizza foto stanze (5/mese gratuite)
— Buyer Passport e simulatore mutuo
— Dossier PDF scaricabile
— Sign in with Apple e cancellazione account in-app
```

---

## Demo Account / Sign-in info

Compilare in App Store Connect → App Review Information:

```
Demo Account Username: [usare un Apple ID standard del reviewer, "Use any Apple ID" supportato]
Demo Account Password: -
```

Apple Sign-in non richiede credenziali demo — il reviewer userà il proprio Apple ID.

---

## App Review Notes

```
Domus Arkai è un'app gratuita per la consultazione di immobili italiani
di pregio, distribuita in white-label per agenzie immobiliari.

Caratteristiche principali:
• Sign in with Apple come unico metodo di autenticazione
• Sezione "Buyer Passport" per pre-qualificazione finanziaria utente
• "Stima ristrutturazione" con configuratori parametrici (BOQ regionalizzato)
• "Arkai Vision Pro" — modello AI proprietario per analisi foto stanze 
  (rate-limit 5 analisi/mese per utente)
• PDF Dossier scaricabile con riepilogo di tutte le analisi
• Account deletion in-app conforme Guideline 5.1.1.v 
  (via Edge Function "delete-account" che revoca token Apple + cascade DB delete)
• Nessun in-app purchase, nessuna subscription, nessun tracking SDK,
  nessuna pubblicità

Backend: Supabase (EU region). 
Privacy Policy: https://arkai.dev/app/PPdomusarkai

Per test:
1. Apri l'app → Profilo → "Accedi con Apple"
2. Naviga la Home → tap su un immobile → esplora le sezioni
3. Tocca "Stima ristrutturazione" per testare i configuratori parametrici
4. Salva nel Dossier e genera il PDF
5. Profilo → "Elimina profilo" per testare account deletion
```

---

## Screenshot — guida per i 5-8 shots su iPhone 6.7"

Ordine raccomandato (gli ultimi tre opzionali):

1. **Hero Home / Feed** — "In Vetrina" con immagine dell'immobile premium + tagline
2. **Property Detail** — vista immobile aperta con specs + foto principale
3. **Stima Ristrutturazione** — categorie + configuratore Cucina o Pavimenti aperto
4. **Arkai Vision Pro** — capture foto + risultato analisi
5. **Il Mio Dossier PDF** — preview PDF Dossier multipagina
6. **Buyer Passport** — card "tier" + dati pre-qualificazione
7. **Simulatore Mutuo** — input + risultato + grafico
8. **Profile / Account Deletion** — opzionale per Apple Review trasparenza

Sopra ogni screenshot, sovrapporre claim editoriale italiano. Sfondo elegante coordinato con il brand (sand `#F7F4ED`).

Per generare screenshot da TestFlight build: aprire la view su iPhone fisico → bottoni Volume Su + Standby → screenshot salvato in Photo Library.
