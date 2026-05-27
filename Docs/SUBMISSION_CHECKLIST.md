# Arkai Domus — App Store Submission Checklist

Ultimo aggiornamento: 2026-05-25 — Build 3 (Marketing 1.0)

---

## ✅ Stato attuale (già fatto)

### Repo lato iOS
- [x] `aps-environment = production` in `Domus Arkai.entitlements`
- [x] `MARKETING_VERSION = 1.0`
- [x] `CURRENT_PROJECT_VERSION = 3` (bumped per archive fresh)
- [x] `DEVELOPMENT_TEAM = ZVGX4HFZC3`
- [x] `CODE_SIGN_STYLE = Automatic`
- [x] `PRODUCT_BUNDLE_IDENTIFIER = com.arkitecna.domusarkai`
- [x] `IPHONEOS_DEPLOYMENT_TARGET = 18.6` (target livello — compatibilità ampia)
- [x] `INFOPLIST_KEY_NSCameraUsageDescription` configurato
- [x] `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` configurato
- [x] AppIcon 1024×1024 no alpha (3 varianti: standard / dark / tinted)
- [x] `PrivacyInfo.xcprivacy` con NSPrivacyCollectedDataTypes + Reasons APIs
- [x] Account deletion (5.1.1.v) implementata via `delete-account` Edge Function
- [x] Custom User-Agent iOS deterministico `ArkaiDomus/...`
- [x] Pre-flight test su device fisico: 8/8 verde

### Backend (Marco / Supabase)
- [x] Edge Functions `send-push`, `delete-account`, `analyze-room-photos` online
- [x] Schema completo (auth, properties, leads, dossiers, push, access_logs, renovation_items, configuration_schema)
- [x] RLS policies attive
- [x] pg_cron `access_logs_purge_90d` schedulato (3:00 UTC ogni giorno)
- [ ] **Switch `APNS_ENVIRONMENT` da `development` a `production`** ← da fare quando Cesare ha TestFlight installato

---

## 🚀 Da fare prima dell'Archive

### Cesare (manuale)
- [ ] Privacy policy live su `https://arkai.dev/app/PPdomusarkai` (URL pubblica)
- [ ] Eseguire Build & Run finale per verifica regressione (5 min, usa la checklist pre-flight)

---

## 📦 Archive + Upload (Cesare)

1. Xcode → seleziona scheme `Domus Arkai`
2. Target device "**Any iOS Device (arm64)**"
3. Product → **Archive** (5-10 min)
4. Organizer si apre automaticamente alla fine
5. Click **Distribute App** → **App Store Connect** → **Upload**
6. Wizard: lascia defaults, "Automatically manage signing", "Strip Swift symbols", "Upload your app's symbols"
7. Verifica firma distribution, then Upload
8. Validazione Apple ~10-30 min — la build apparirà su App Store Connect

---

## 🌐 App Store Connect (web)

URL: https://appstoreconnect.apple.com

### App Information (una volta sola, prima dell'iOS App record)
- [ ] **Name**: `Domus Arkai`
- [ ] **Subtitle**: `Immobili di pregio italiani`
- [ ] **Bundle ID**: `com.arkitecna.domusarkai` (collegato all'identifier creato in Apple Developer)
- [ ] **Primary Category**: Lifestyle (o `Business` se preferisci professional)
- [ ] **Secondary Category**: Productivity
- [ ] **Privacy Policy URL**: `https://arkai.dev/app/PPdomusarkai`
- [ ] **Marketing URL**: opzionale, `https://arkai.dev`
- [ ] **Support URL**: `https://arkai.dev` o email mailto

### iOS App Version 1.0
- [ ] Selezionare la build uploadata (3)
- [ ] **What's New**: "Prima release ufficiale di Arkai Domus — selezione editoriale di immobili italiani di pregio."
- [ ] **Promotional Text** (170 char, da `APP_STORE_COPY.md`)
- [ ] **Description** (4000 char, da `APP_STORE_COPY.md`)
- [ ] **Keywords** (100 char, da `APP_STORE_COPY.md`)
- [ ] **Screenshot iPhone 6.7"** (1290×2796) — 3-10 immagini
- [ ] **Screenshot iPhone 6.1"** (1179×2556) — 3-10 immagini
- [ ] **Screenshot iPad** se supporti iPad universal — opzionale

### App Review Information
- [ ] Contact Info: nome, email, telefono
- [ ] Demo Account: per Sign in with Apple basta "Use any Apple ID" — niente credenziali da fornire
- [ ] **Notes**: 
  ```
  Arkai Domus è un'app gratuita per la consultazione di immobili italiani 
  di pregio, distribuita in white-label per agenzie immobiliari.
  - Sign in with Apple per pre-qualificazione (Buyer Passport) e salvataggio dossier
  - Stima ristrutturazione parametrica con configuratori (BOQ regionalizzato OMI)
  - Analisi foto stanze tramite "Arkai Vision Pro" (modello AI proprietario, 
    5 analisi/mese gratuite)
  - PDF Dossier scaricabile con tutte le analisi
  - Account deletion in-app conforme guideline 5.1.1.v
  - Nessun in-app purchase, nessun tracking, nessuna pubblicità
  ```

### App Privacy (sezione separata)
Il `PrivacyInfo.xcprivacy` già configurato copre:
- [ ] Email Address (Linked, no tracking, App Functionality)
- [ ] Name (Linked, no tracking, App Functionality)
- [ ] User ID (Linked, App Functionality + Authentication)
- [ ] Photos or Videos (Linked, App Functionality + Analytics)
- [ ] Other Financial Info (Linked, App Functionality)

### Age Rating
- [ ] Compila questionario standard. Risposta `None` per tutte le categorie sensibili.
- Esito atteso: **4+**

### Pricing and Availability
- [ ] **Price**: Free
- [ ] **Territories**: All (o almeno Italia + EU + USA + UK + CH)

### Compliance
- [ ] **Export Compliance**: usa solo standard encryption (HTTPS) → seleziona "Yes, exempt" → no CCATS richiesto

### Submit
- [ ] Click **Add for Review** → **Submit to App Review**
- [ ] Stato passa a "Waiting for Review" (24-48h primo turno)

---

## 🔁 Post-submit (quando TestFlight è installato su iPhone di Cesare)

- [ ] Cesare segnala "TestFlight installato e funzionante"
- [ ] io segnalo a Marco di switchare il secret `APNS_ENVIRONMENT` da `development` a `production`
- [ ] Cesare fa test push round-trip prod (chiede a Marco di mandare una push test → verifica arrivo su build TestFlight)
- [ ] Se OK: tutto pronto per il submit finale review

---

## ⚠️ Rejection comuni Apple — preparazione preventiva

- **Privacy Policy URL non raggiungibile**: già nel checklist
- **Account deletion non testabile**: già implementata + documentata nelle Notes
- **Screenshot mismatched col contenuto reale**: catturare screenshot dalla build TestFlight, non da mockup
- **Sign in with Apple obbligatorio se ci sono altri social sign-in**: noi abbiamo SOLO Apple — OK
- **Copy ambigua "premium"**: tono editoriale italiano OK, evitare "esclusivo" senza giustificazione
- **App troppo simile al sito web**: l'app aggiunge feature native (PDF generation, Visual BOQ AI, Buyer Passport) — OK
- **App fatta solo per un'agenzia**: l'app è white-label multi-agenzia (SaaS pattern) — OK

---

## 📞 Contact info / link utili

- Apple Developer Portal: https://developer.apple.com/account
- App Store Connect: https://appstoreconnect.apple.com
- Supabase Dashboard: https://supabase.com/dashboard/project/fviomnrtswsuoqfxcbki
- Mapbox Account: https://account.mapbox.com (per token publishable già configurato)
- Team ID: `ZVGX4HFZC3`
- Bundle ID: `com.arkitecna.domusarkai`
- APNs Key ID: `BM286CY46H`
