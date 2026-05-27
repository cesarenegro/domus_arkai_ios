# TO DO V2.0 — Arkai Vision Pro Experience + Spatial Staging Pipeline

> **Fonte**: HUB `ai_coordination_messages` — msg `0738dbf0-d098-4498-8d79-14ca8bb8cf64`
> **Sender**: MARCO (frontend_ai)
> **Data ricezione**: 2026-05-27 00:51 UTC
> **Stato**: pianificazione approvata da Cesare, in attesa di kickoff implementazione lato iOS.

---

## Visione strategica

Implementare nella **release v2.0** della app iOS una pipeline completa di **spatial staging**:
agente immobiliare scansiona il cantiere grezzo → backend Arkai genera arredo procedurale in formato USDZ → cliente finale vede l'immobile "vestito" in scala 1:1 tramite AR Quick Look (iPhone / iPad).

> **Apple Vision Pro escluso** dal target v2.0 (decisione Cesare 2026-05-27). Focus solo iPhone / iPad con LiDAR.

Tre macro-fasi tecniche, sequenziali in produzione ma parallelizzabili in sviluppo.

---

## Decisioni finalizzate (2026-05-27)

| Tema | Scelta | Note |
|---|---|---|
| **Posizionamento UI agente** | **A** — voce "Modalità professionale" dentro `ProfileView` | Stessa app, gating via ruolo Supabase (es. `is_agency_member`). Niente app dedicata |
| **Tier feature** | **A** — tutto FREE | Scan free per agency partner, AR cliente free (è il colpo di teatro che vende). Niente paywall AR su v2.0 |
| **Switch materiali in-AR** | **B** — rimandato a v2.1 con `RealityKit` scene custom | v2.0 mostra UN solo USDZ default per immobile (variante "Minimal Premium" lato server). Switch fluido tra varianti = killer feature v2.1 |

**Implicazione**: v2.0 più snella, ~12 giorni di iOS focused (rispetto ai ~18 con materiali in v2.0). Apre la porta a una v2.1 "premium" come secondo round di marketing.

---

## 1. INTEGRAZIONE APPLE ROOMPLAN — Scansione strutturale LiDAR

**Framework**: `RoomPlan` (Apple)
**Owner iOS**: ios_ai
**Vincoli HW**: iPhone Pro / iPad Pro con sensore LiDAR (iOS 17+).

### Task iOS
- [ ] Aggiungere capability `RoomPlan` al target (entitlements + Info.plist `NSCameraUsageDescription` aggiornato per descrivere scanning 3D)
- [ ] Nuova View `RoomScanCaptureView` che hosta `RoomCaptureView` (UIViewControllerRepresentable)
- [ ] Capture session management: start / pause / resume / stop / restart on user request
- [ ] Estrazione del modello strutturale `CapturedRoom` al termine della sessione
- [ ] **Serializzazione**: convertire `CapturedRoom` in JSON strutturato (pareti, porte, finestre, aperture con coordinate x/y/z + dimensioni)
- [ ] Validation client-side: room area > 0, almeno 4 pareti riconosciute, log avvisi se geometria incompleta
- [ ] UI feedback: indicatore progress scansione, hint "muovi più lento", riepilogo metrico finale

### Task backend (Marco — dipendenza nostra)
- [ ] Schema nuova tabella `property_scans` su Supabase: `id, property_id, scan_json jsonb, scanned_at, scanner_user_id, room_count, total_area_m2, status`
- [ ] RLS: scansione visibile solo a agente proprietario + admin
- [ ] Endpoint upload (POST `/property-scans`) con validazione schema JSON
- [ ] Linking 1-N: 1 property può avere N scansioni (versioning)

---

## 2. PIPELINE PROCEDURALE → USDZ — Generazione asset 3D

**Framework**: Reality Composer Pro / RealityKit asset pipeline (server-side, Apple toolchain o equivalente)
**Owner backend**: Marco
**Output**: file `.usdz` per ogni layout, varianti materiali (gres / rovere / calacatta / etc.)

### Task backend (Marco — NO iOS)
- [ ] Service che accetta `property_scans.scan_json` + preset stilistici (es. "Minimal Premium", "Classico Italiano")
- [ ] Associazione arredi geometrici → modelli USDZ catalogati (libreria interna Arkai)
- [ ] Generazione `.usdz` con texture multi-material e PBR
- [ ] Upload su Supabase Storage bucket `property-staging`
- [ ] Linking DB: nuova colonna `property_scans.staging_usdz_url` o tabella `staging_variants(scan_id, variant_name, usdz_url)`

### Task iOS (light)
- [ ] Polling / realtime subscription per ricevere notifica quando l'USDZ è pronto
- [ ] Cache locale dei file USDZ scaricati (per AR Quick Look offline su cantiere senza rete)

---

## 3. SPATIAL STAGING VIEWPORT — AR Quick Look 1:1

**Framework**: `QuickLook` + `ARQuickLookPreviewController` (Apple)
**Owner iOS**: ios_ai

### Task iOS (v2.0)
- [ ] Nel `PropertyDetailView`, nuova sezione **"Vista Spatial Staging"** visibile quando esiste almeno un USDZ associato all'immobile
- [ ] CTA principale **"Proietta nello Spazio 1:1"** (icona `arkit` o `cube.transparent.fill`)
- [ ] Tap → presenta `ARQuickLookPreviewController` configurato col file USDZ default dell'immobile
- [ ] Walkthrough 1:1 nativo: il cliente inquadra il locale grezzo, vede arredi sovrapposti a scala reale
- [ ] Caching locale USDZ (uso offline in cantiere senza rete)

### Rimandato a v2.1
- ~~Selettore materiali in-AR~~ → richiede `RealityKit` scene custom con multi-mesh + material swap live. Verrà sviluppato come "killer feature" della v2.1 dopo lancio v2.0.
- ~~Sync DB preferenze variante~~ → segue v2.1 quando ci sarà il selettore.

### Esperienza utente target (v2.0)
- Cliente apre PropertyDetail → vede card "Spatial Staging"
- Tap "Proietta nello Spazio 1:1" → cantiere grezzo + iPhone → arredo USDZ default sovrapposto a scala reale
- Walkthrough fisico nel locale, gestures pinch/rotate/move nativi di AR Quick Look

---

## Dipendenze critiche

| Cosa | Owner | Stato | Blocca |
|---|---|---|---|
| Schema `property_scans` | Marco | da fare | step 1 |
| Pipeline server USDZ | Marco | da progettare | step 2 e 3 |
| Libreria modelli arredo USDZ | Marco | da costruire | step 2 |
| RoomPlan entitlements iOS | ios_ai | da fare | step 1 |
| AR Quick Look integration iOS | ios_ai | da fare | step 3 |

---

## Hardware / requisiti

- **iOS minimo**: 17.0 (RoomPlan API moderne)
- **Device target scan**: iPhone Pro / iPad Pro con LiDAR (modelli senza LiDAR → mostrare disclaimer e nascondere CTA scan)
- **Device target AR Quick Look**: tutti gli iPhone e iPad recenti (no LiDAR richiesto per la sola visualizzazione, solo per la scansione)
- ~~Apple Vision Pro: target visionOS~~ — escluso da v2.0 (decisione Cesare)

---

## Prossimi passi suggeriti

> v1.0 è **già live in App Store, approvata e operativa**, con download in corso. Si può iniziare la v2.0 senza attendere altre milestone.

1. Definire timeline v2.0 con Cesare + Marco (sprint planning)
2. POC RoomPlan stand-alone: una nuova schermata di test che apre `RoomCaptureView` e stampa JSON in console — niente DB ancora
3. Parallelo: Marco progetta lo schema `property_scans` + bucket Storage + pipeline server USDZ
4. Una volta validato il POC scansione, integrare upload + linking property → scan
5. POC AR Quick Look stand-alone: caricare un USDZ di test e mostrarlo con `ARQuickLookPreviewController` — verificare scala 1:1, gestures, performance su device reale
6. Integrazione finale: scan → pipeline server → USDZ → AR Quick Look end-to-end

---

## Riferimenti

- HUB messaggio originale: id `0738dbf0-d098-4498-8d79-14ca8bb8cf64` su `ai_coordination_messages`
- Apple RoomPlan: https://developer.apple.com/documentation/roomplan
- AR Quick Look: https://developer.apple.com/documentation/arkit/previewing_a_model_with_ar_quick_look
- USDZ format spec: https://developer.apple.com/documentation/realitykit/converting-and-delivering-materials-for-augmented-reality

---

*Ultimo aggiornamento: 2026-05-27*
