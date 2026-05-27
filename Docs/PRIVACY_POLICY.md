# Informativa sulla Privacy — Domus Arkai

**Ultimo aggiornamento: 25 maggio 2026**

La presente informativa descrive come **Domus Arkai** (di seguito "l'App") raccoglie, utilizza e protegge i tuoi dati personali quando utilizzi l'applicazione iOS distribuita tramite Apple App Store.

L'informativa è redatta in conformità al **Regolamento (UE) 2016/679 ("GDPR")**, al **D.Lgs. 196/2003 ("Codice Privacy") come modificato dal D.Lgs. 101/2018**, e alle linee guida del **Garante per la Protezione dei Dati Personali**.

---

## 1. Titolare del Trattamento

**Ragione sociale**: [DA COMPLETARE: es. Arkitecna S.r.l.]  
**Sede legale**: [DA COMPLETARE: indirizzo completo]  
**Partita IVA / Codice Fiscale**: [DA COMPLETARE]  
**Email di contatto privacy**: [DA COMPLETARE: es. privacy@arkai.dev]  
**Responsabile della Protezione dei Dati (DPO)**: [DA COMPLETARE se nominato, altrimenti rimuovere riga]

Per qualunque richiesta relativa al trattamento dei tuoi dati personali puoi scrivere all'indirizzo email indicato sopra. Ti risponderemo entro 30 giorni come previsto dall'art. 12 GDPR.

---

## 2. Categorie di dati raccolti

### 2.1 Dati di registrazione (Sign in with Apple)

Quando accedi all'app per la prima volta tramite Sign in with Apple, raccogliamo:

- **Identificativo Apple** (Apple User ID, stringa anonimizzata da Apple)
- **Nome e cognome** (solo se ce li condividi al primo accesso — Apple non li ritrasmette dopo)
- **Indirizzo email** (reale o relay anonimizzato `xxx@privaterelay.appleid.com`)

### 2.2 Dati di profilo e pre-qualificazione finanziaria ("Buyer Passport")

Se compili volontariamente il tuo Buyer Passport, raccogliamo:

- **Budget massimo** di acquisto
- **Liquidità disponibile**
- **Percentuale di mutuo richiesta**
- **Zone geografiche preferite**
- **Tipologia di immobile preferita**
- **Numero minimo di stanze e bagni**

Questi dati ti permettono di ricevere selezioni di immobili coerenti col tuo profilo e di generare un "parametro di eccellenza" che ti distingue come acquirente serio presso le agenzie.

### 2.3 Dati di interesse e contatto con le agenzie

Quando contatti un'agenzia o prenoti una visita tramite l'app, raccogliamo:

- **Nome**, **email**, **telefono**, **messaggio** di richiesta
- **Identificativo dell'immobile** di interesse
- **Data e ora** della prenotazione di visita

Questi dati sono **condivisi con l'agenzia immobiliare** titolare dell'immobile per consentirti di ricevere il servizio richiesto (vedi §5).

### 2.4 Contenuti utente — foto stanze

Se utilizzi la funzione **"Arkai Vision Pro"** (analisi visiva ristrutturazione), carichi volontariamente fotografie di stanze tramite la fotocamera o la libreria foto del tuo dispositivo. Le immagini sono inviate ai nostri server per l'analisi automatizzata, **non vengono usate per addestrare modelli AI generici**, e sono eliminate dopo l'elaborazione (retention dettagliata in §6).

### 2.5 Dati di utilizzo e log di accesso

Per garantire la sicurezza del servizio raccogliamo log degli accessi riusciti:

| Dato | Esempio | Scopo |
|---|---|---|
| Identificativo utente | UUID interno | Associare l'accesso al tuo account |
| Email | mario@esempio.it | Identificazione in caso di anomalia |
| Tipo di client | `ios_app` / `admin_web` / `public_web` | Distinguere da quale interfaccia accedi |
| Indirizzo IP **anonimizzato** | `192.168.1.0` (ultimo ottetto azzerato) | Rilevazione anomalie geografiche |
| User Agent | `ArkaiDomus/1.0 iOS 26.5 iPhone` | Identificare dispositivo/browser |
| Data e ora | `2026-05-25 09:15 UTC` | Tracciabilità cronologica |

**Non registriamo l'indirizzo IP completo**: applichiamo il mascheramento `/24` per IPv4 e `/48` per IPv6 prima della scrittura, come misura di minimizzazione richiesta dal GDPR.

**Non registriamo i tentativi di login falliti** né le tue attività in-app dopo il login (no tracking comportamentale).

### 2.6 Dossier salvati e calcoli

Quando salvi un "Dossier" sull'immobile, persistiamo le tue analisi: simulatore mutuo, valutazione di mercato, stima ristrutturazione, configurazioni materiali. Questi dati ti consentono di ritrovare e condividere i tuoi dossier come PDF.

### 2.7 Token di notifica push

Se concedi l'autorizzazione alle notifiche push, raccogliamo il **device token APNs** (stringa esadecimale univoca per dispositivo + app) e il tipo di dispositivo (`ios`). Serve esclusivamente per recapitarti notifiche relative a visite confermate, nuovi immobili coerenti col tuo profilo, e comunicazioni dell'agenzia.

### 2.8 Cosa NON raccogliamo

- **Nessun tracker di terze parti** (no Facebook SDK, Google Analytics, Firebase, AppsFlyer, Adjust, ecc.)
- **Nessuna pubblicità** e nessun SDK pubblicitario
- **Nessuna geolocalizzazione del dispositivo** (non chiediamo permesso CoreLocation)
- **Nessun dato biometrico**
- **Nessun acquisto in-app**: l'app è gratuita

---

## 3. Finalità e base giuridica del trattamento

| Finalità | Base giuridica (art. 6 GDPR) |
|---|---|
| Erogazione del servizio (browsing immobili, ricerca, dossier) | Esecuzione di un contratto (art. 6.1.b) |
| Sign in with Apple e autenticazione | Esecuzione di un contratto (art. 6.1.b) |
| Buyer Passport e pre-qualificazione | Consenso (art. 6.1.a) — revocabile in qualsiasi momento eliminando i dati dal profilo |
| Contatto con agenzie e prenotazione visite | Esecuzione di un contratto / misure precontrattuali (art. 6.1.b) |
| Visual BOQ (analisi foto stanze) | Consenso esplicito (art. 6.1.a) — si attiva solo quando carichi una foto |
| Log di accesso per sicurezza | Legittimo interesse (art. 6.1.f) — sicurezza dei sistemi informativi e prevenzione di accessi non autorizzati |
| Invio notifiche push (visite, immobili) | Consenso (art. 6.1.a) — revocabile dalle Impostazioni iOS |

---

## 4. Modalità di trattamento

I tuoi dati sono trattati con **modalità informatiche** ad alta sicurezza:

- **Crittografia in transito**: tutte le comunicazioni con i nostri server usano TLS 1.3 (HTTPS)
- **Crittografia a riposo**: i dati persistiti sul database sono cifrati at-rest (AES-256)
- **Controllo accessi**: Row-Level Security (RLS) attive sul database — ogni utente può accedere solo ai propri dati
- **Pseudonimizzazione**: dove possibile usiamo identificatori UUID al posto di dati identificativi diretti
- **Misure organizzative**: accesso ai dati limitato al personale strettamente necessario, log degli accessi amministrativi

---

## 5. Destinatari dei dati

I tuoi dati personali possono essere comunicati a:

### 5.1 Agenzie immobiliari partner

Quando contatti un'agenzia, prenoti una visita o esprimi interesse per un suo immobile, i tuoi dati di contatto (nome, email, telefono, messaggio) sono **trasmessi all'agenzia titolare dell'immobile**, che opera come **autonomo Titolare del trattamento** per le proprie finalità commerciali.

Ogni agenzia è tenuta a fornirti una propria informativa al primo contatto. Per esercitare i tuoi diritti GDPR nei confronti dell'agenzia, contattala direttamente.

### 5.2 Fornitori tecnologici (Responsabili del trattamento — art. 28 GDPR)

| Fornitore | Servizio | Ubicazione server |
|---|---|---|
| **Supabase Inc.** | Database, autenticazione, archiviazione, edge functions | EU (Frankfurt, AWS eu-central-1) |
| **Apple Inc.** | Sign in with Apple, Apple Push Notification Service (APNs) | USA — adeguatezza garantita da Data Privacy Framework |
| **Mapbox Inc.** | Mappe statiche per il PDF Dossier (riceve solo coordinate immobili, mai dati utente) | USA — adeguatezza garantita da Data Privacy Framework |

Tutti i fornitori sono vincolati da specifici accordi di trattamento dati (DPA) che impongono livelli di sicurezza adeguati al GDPR.

### 5.3 Trasferimenti extra-UE

I dati possono essere trasferiti a server localizzati fuori dall'Unione Europea (principalmente Apple Push Notification Service e Mapbox negli USA). Tali trasferimenti avvengono nel rispetto degli artt. 44-49 GDPR, basandosi su:

- **Decisione di adeguatezza** (EU-US Data Privacy Framework per gli USA)
- **Clausole Contrattuali Standard** (Standard Contractual Clauses approvate dalla Commissione UE) come misura aggiuntiva

---

## 6. Periodo di conservazione

| Dato | Retention |
|---|---|
| Account utente e dati di profilo | Fino alla **cancellazione dell'account** da parte tua |
| Buyer Passport | Fino alla cancellazione dell'account o eliminazione esplicita dal Profilo |
| Dossier salvati | Fino alla cancellazione dell'account o eliminazione esplicita |
| Lead / richieste di visita | 24 mesi dalla creazione (poi anonimizzati) |
| **Log di accesso** | **90 giorni** — auto-eliminazione schedulata sul database |
| Foto stanze inviate per analisi | Eliminate al termine dell'elaborazione (max 24h) — i risultati testuali dell'analisi sono conservati nel dossier |
| Device token APNs | Fino a invalidazione da parte di Apple (es. disinstallazione dell'app) o cancellazione account |
| Notifiche push storiche (inbox in-app) | Fino alla cancellazione manuale o cancellazione account |

---

## 7. Diritti dell'interessato (artt. 15-22 GDPR)

In qualsiasi momento puoi esercitare i seguenti diritti:

### 7.1 Diritto di accesso (art. 15)
Ottenere conferma del trattamento e una copia dei tuoi dati personali.

### 7.2 Diritto di rettifica (art. 16)
Aggiornare i dati inesatti direttamente dal Profilo o richiedendolo via email.

### 7.3 Diritto alla cancellazione "diritto all'oblio" (art. 17)
**Implementato direttamente in-app**: vai su **Profilo → Elimina profilo** e conferma. La cancellazione è **completa e immediata**:

- Tutti i tuoi dati personali sono cancellati dal nostro database (cascade su Buyer Passport, dossier, lead, notifiche, device token, log di accesso)
- Il token Apple ID viene revocato presso Apple
- L'operazione è **irreversibile**

### 7.4 Diritto di portabilità (art. 20)
Ricevere i tuoi dati in formato strutturato e leggibile (JSON). Per richiederlo, scrivi all'email privacy.

### 7.5 Diritto di limitazione (art. 18)
Richiedere la sospensione temporanea del trattamento mentre verifichiamo una tua contestazione.

### 7.6 Diritto di opposizione (art. 21)
Opporti al trattamento basato sul legittimo interesse (es. log di accesso). In tal caso valuteremo se la nostra base giuridica prevale sui tuoi diritti.

### 7.7 Diritto di reclamo
Se ritieni che il trattamento dei tuoi dati violi il GDPR, puoi presentare reclamo al **Garante per la Protezione dei Dati Personali**:

- Sito web: [www.garanteprivacy.it](https://www.garanteprivacy.it)
- Email: protocollo@gpdp.it
- Indirizzo: Piazza Venezia 11 — 00187 Roma

---

## 8. Sicurezza dei dati

Adottiamo misure tecniche e organizzative adeguate al rischio del trattamento, tra cui:

- Cifratura in transito (TLS 1.3) e a riposo (AES-256)
- Row-Level Security sul database (ogni utente isolato)
- Autenticazione Sign in with Apple con token JWT firmati
- Indirizzo IP anonimizzato per i log
- Auto-eliminazione log di accesso dopo 90 giorni
- Audit periodici delle policy di sicurezza
- Backup giornalieri cifrati

**Notifica di data breach**: in caso di violazione di dati personali che presenti un rischio elevato per i tuoi diritti, ti informeremo entro 72 ore come previsto dall'art. 34 GDPR.

---

## 9. Minori

L'app **non è destinata a minori di 16 anni**. Non raccogliamo intenzionalmente dati personali di minori. Se ritieni che un minore ci abbia fornito dati, contattaci e provvederemo alla cancellazione immediata.

---

## 10. Cookie e tracker

L'app **non utilizza cookie** né tecnologie di tracciamento equivalenti. Memorizziamo localmente sul tuo dispositivo (UserDefaults iOS) solo:

- Preferenze interfaccia (tema chiaro/scuro/sistema, lingua)
- Lista preferiti di immobili
- Contatore di utilizzo mensile di Arkai Vision Pro (anti-abuso)
- Cache temporanea del nome/email Apple al primo accesso

Questi dati restano esclusivamente sul tuo dispositivo e vengono cancellati all'eliminazione dell'app.

---

## 11. Permessi iOS richiesti

L'app può richiedere i seguenti permessi al sistema operativo iOS:

- **Fotocamera** (`NSCameraUsageDescription`): per scattare foto degli ambienti da analizzare con Arkai Vision Pro
- **Libreria Foto** (`NSPhotoLibraryUsageDescription`): per selezionare foto esistenti da analizzare
- **Notifiche** (UserNotifications): per ricevere aggiornamenti su visite, immobili, comunicazioni delle agenzie

Tutti i permessi sono **opt-in**: puoi rifiutarli e l'app continua a funzionare con le funzionalità base. Puoi revocarli in qualsiasi momento dalle **Impostazioni iOS → Domus Arkai**.

---

## 12. Privacy Manifest (Apple)

L'app dichiara nel proprio `PrivacyInfo.xcprivacy` (come richiesto da Apple) le categorie di dati raccolti e gli API reasons utilizzati. Il manifest è ispezionabile da Apple e dagli utenti tramite il "Privacy Report" disponibile su App Store.

---

## 13. Modifiche all'informativa

Possiamo aggiornare questa informativa per riflettere modifiche al servizio, requisiti normativi o miglioramenti delle pratiche di sicurezza. Ti notificheremo le modifiche sostanziali:

- Tramite notifica in-app
- Aggiornando la data "Ultimo aggiornamento" in cima a questo documento

Continuando a utilizzare l'app dopo le modifiche, ne accetti i nuovi termini.

---

## 14. Foro competente

Per qualsiasi controversia relativa al trattamento dei tuoi dati personali è competente il **Foro del consumatore** (luogo di residenza o domicilio del consumatore) ai sensi dell'art. 66-bis del Codice del Consumo.

---

## Contatti

Per esercitare i tuoi diritti o per qualunque richiesta sulla privacy:

📧 **Email**: [DA COMPLETARE: privacy@arkai.dev]  
🏢 **Titolare**: [DA COMPLETARE: ragione sociale + indirizzo]

Risponderemo entro **30 giorni** dalla ricezione della richiesta.

---

*Documento redatto in conformità al GDPR (Regolamento UE 2016/679), al Codice Privacy italiano (D.Lgs. 196/2003 modificato dal D.Lgs. 101/2018), e alle linee guida del Garante Privacy.*
