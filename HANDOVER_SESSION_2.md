# Arkai Domus — Handover Sessione 22 Maggio 2026

Riepilogo operativo per iniziare una nuova chat senza perdere contesto.
La memoria persistente (`~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/projects/-Users-cesare-Documents-PROJECTS-Domus-Arkai/memory/`) contiene già regole, feedback, brand tokens e contesto progetto: questo file è solo lo snapshot operativo dello stato attuale.

---

## 1. STATO ATTUALE (cosa è già fatto)

### Build status
- ✅ Build verde stabile
- iOS deployment target 26.5, Bundle ID `com.arkitecna.selftape.Domus-Arkai`, Team `ZVGX4HFZC3`
- Package SPM installato: `supabase-swift` (umbrella `Supabase` include Auth + Functions)

### Architettura
```
Models/
  Agency, Property (1:1 schema), PropertyMedia, Lead, VisitRequest,
  MortgageEstimate, RenovationItem (+ RenovationCategory + RenovationLevel),
  SearchFilters, HubMessage, BuyerPassport (+ Draft),
  MarketPrice (Zone + ConditionMultiplier + PropertyValuation),
  BOQ (RegionalCoefficient + DifficultyFactor + BasePrice + VisualBOQWork/Response/Record)

Services/
  FavoritesStore, HubService, MockDataService (residuale per gallery/3D fallback),
  SubscriptionService (FREE/PRO con @AppStorage backing, sostituiremo con StoreKit 2)

Core/Supabase/
  SupabaseClient (singleton SupabaseManager.shared)
  Services/
    PropertyService    (fetchPublishedProperties + enrich cover via property_media)
    AgencyService      (fetchPrimaryAgency)
    MediaService       (gallery, floorplan 2D, 3D)
    LeadService        (insert)
    VisitRequestService (insert)
    AuthService        (Sign in with Apple via Supabase Auth — diretto, NO broker)
    BuyerPassportService (fetch + upsert)
    MarketPriceService (RPC find_nearest_market_price + formula clamping OMI)
    BOQService         (regional + difficulty + base_prices + items + categories, cache in-memory)
    VisualBOQService   (chiamata Edge Function analyze-room-photos via supabase.functions.invoke)

ViewModels/
  HomeViewModel, PropertyDetailViewModel, MortgageViewModel, RenovationViewModel,
  FavoritesViewModel, VisitBookingViewModel,
  PropertyValuationViewModel (AVM), VisualBOQViewModel (Arkai Vision Pro)

Views/
  Splash, Home, Search, PropertyDetail, Gallery, Floorplan(2D+3D),
  Mortgage(Form+Result), Renovation(Selection+Chart), VisitBooking, Contact,
  Favorites, Profile, Valuation (PropertyValuationView nuovo)
  HubInboxView (DEBUG tab)

Components/
  ADButtonStyles, ADEmptyState, ActionEntryCard, FilterPill,
  PropertyCard, PropertyCardSkeleton, SpecCard

Core/Theme/
  ADColor, ADRadius, ADSpacing, ADTypography, Color+Hex
```

### Switch a Supabase reale completati
- HomeView → PropertyService + AgencyService (filtri client-side temporanei)
- PropertyDetailView → MediaService (gallery, floorplan, 3D)
- RenovationView → BOQService con k_final + K_difficolta (mai mostrati come %)
- Detail action card → PropertyValuationView (AVM con OMI clamping)

### Features premium implementate
- **AVM "Valuta questo immobile"**: card protagonista sage sul Detail → sheet con valore stimato, zona OMI, range di mercato, comparison vs prezzo richiesto, disclaimer istituzionale brand-safe
- **BOQ regionale**: calcolatore ristrutturazione applica k_final (città) × K_difficolta (multi-toggle factor) — UI mostra solo label brand-safe ("Centro Storico", "ZTL", ecc.) + messaggio istituzionale di integrazione
- **VisualBOQService**: pronto, chiama Edge Function via `supabase.functions.invoke("analyze-room-photos", ...)`. Manca solo VisualBOQ Capture/Result views.

---

## 2. COSA RESTA DA FARE

### Sprint in corso (Visual BOQ — interrotto a metà)
- [ ] **ArkaiProPaywallView** — sheet quando utente FREE tap su feature PRO
- [ ] **VisualBOQCaptureView** — picker foto (max 3), tipo locale, città auto, multi-toggle difficulty, CTA "Analizza"
- [ ] **VisualBOQResultView** — lista works rilevati + costo per intervento + totale + "Salva stima" + retake
- [ ] Integrazione PropertyDetailView: nuova action card "Analizza una stanza · Arkai Vision Pro" → gate isPro → sheet capture
- [ ] Permesso `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` in Info.plist

### Sprint futuri (in ordine)
- [ ] **A.3** — VisitBookingViewModel switch a LeadService + VisitRequestService reali (rimuovi MockDataService.createVisitRequest)
- [ ] **C.1/C.2** — Refactor ProfileView con AuthService (Sign in with Apple button) + BuyerPassportEditView (form completo con rank tiers Diamond Elite/Platinum/Gold/Standard + parametro di eccellenza)
- [ ] **C.3** — Capability "Sign in with Apple" in Xcode + Supabase Auth provider Apple lato dashboard (intervento utente)
- [ ] **E** — Home redesign per matchare JSON UI `02_ios_home_property_feed`: hero featured carousel + Nuovi Arrivi orizzontale + glass_badge "In Vetrina"
- [ ] **F** — RoomPlan LiDAR (sub-feature PRO, fallback Visual BOQ per device non Pro)

### Cleanup tecnico
- [ ] PropertyCardSkeleton: width fisse 120/160/200/220 → da rendere proporzionali con GeometryReader (regola adaptive)
- [ ] MockDataService: rimuovere fetchProperty(byID:) ancora usato da FavoritesViewModel (switch a PropertyService.fetchProperty)

---

## 3. DECISIONI CEMENTATE (DA RISPETTARE SEMPRE)

### Scope iOS
- App **SOLO B2C pubblica**. NIENTE sezione admin lato iOS (eventuale PWA agenti separata in futuro).
- Tab bar: Casa / Ricerca / Preferiti / Contatti / Profilo. La TabBar nativa resta SEMPRE visibile (no `.toolbar(.hidden, for: .tabBar)`).

### Tier system FREE / PRO
- FREE: browsing immobili, mortgage base, BOQ parametrico, AVM, Buyer Passport, Sign in with Apple
- PRO: Visual BOQ via foto (Arkai Vision Pro), RoomPlan LiDAR
- Gating tramite `SubscriptionService.shared.isPro` (MVP backing @AppStorage, StoreKit 2 in fase successiva)
- Paywall come sheet quando utente FREE tap su feature PRO

### Brand safety (REGOLA AZIENDALE GLOBALE)
- Modello AI = **"Arkai Vision Pro"** — MAI scrivere "Gemini", "Gemini Flash", "GPT" in UI/log/errori/testi
- Fattori cantiere: solo label descrittive — MAI mostrare percentuali / k=X
  - `centro_storico` → "Centro Storico"
  - `ztl_access` → "ZTL"
  - `piano_alto_no_ascensore` → "Piano Alto senza Ascensore"
  - `appartamento_occupato` → "Appartamento Occupato"
  - `micro_cantiere_lt40mq` → "Micro-cantiere (<40 mq)"
  - `urgenza` → "Urgenza / Fast-Track"
  - `venezia_insulare` → "Venezia Laguna / Insulare"
- Messaggio integrazione: *"Le complessità logistiche selezionate sono state integrate nella pianificazione dei costi di cantiere."*
- Report AVM: linguaggio istituzionale, MAI "algoritmo proprietario AVM"
- Buyer Score = **"parametro di eccellenza"** — MAI "punteggio calcolato"

### Auth strategy
- **Sign in with Apple DIRETTO** via Supabase Auth (`signInWithIdToken(provider: .apple, idToken: ...)`)
- AuthService già pronto in `Core/Supabase/Services/AuthService.swift`
- Centralized Auth Broker (URL scheme `arkaidomus://`) **POSTICIPATO** a fase successiva — Cesare ha deciso di non implementarlo nel MVP

### Linee guida UI/UX FONDAMENTALI (memoria persistente: feedback_*.md)
1. **Design system rigoroso**: solo token AD* (`ADColor/ADSpacing/ADRadius/ADShadow/ADTypography`) — ZERO hex hardcoded, zero magic numbers
2. **Layout adaptive**: mai `frame(width: N)` fisso sui figli HStack/VStack — sempre `maxWidth: .infinity`. Width fisse OK solo su icone (24-32pt) o button height (44-50pt)
3. **Zero horizontal overflow**: pattern testato `LazyVStack { figli }.padding(.horizontal, 20)` + `.containerRelativeFrame(.horizontal)` su hero edge-to-edge. MAI `scrollClipDisabled()`. MAI `.frame(maxWidth: .infinity).padding(.horizontal, X)` (espande oltre lo screen)
4. **Glassmorphism MISURATO**: `.regularMaterial`/`.thickMaterial` solo su CTA sticky, header overlay su hero, modali. NON su card lista/form/dashboard (warm-editorial opaco)
5. **Italiano premium**: tono editoriale come magazine di architettura italiana — mai SaaS generico
6. **Detail view pattern**: `ZStack { bg; ScrollView { LazyVStack(.leading) { hero.containerRelativeFrame(.horizontal); content }.padding(.horizontal, 20) } }` + sticky CTA come secondo figlio dello ZStack (mai safeAreaInset)
7. **TabBar visibile sempre**, anche nel Detail
8. **Screenshot device sempre prima di dichiarare done** — Canvas Preview NON riproduce affidabilmente il runtime su iPhone reale

---

## 4. INFRASTRUTTURA BACKEND (frontend_ai)

### Supabase
- URL: `https://fviomnrtswsuoqfxcbki.supabase.co`
- Anon key: `sb_publishable_zhcObBd9xMAzo-nTzoXhlw_LHlId9xh` (in `Config/SupabaseConfig.swift`)
- RLS aperta in lettura/scrittura per MVP (pubblico)

### Tabelle in produzione
- 13 base: `agencies, agency_users, properties, property_media, property_floorplans, property_3d_assets, property_documents, renovation_categories, renovation_items, leads, visit_requests, mortgage_estimates, favorites`
- Buyer Passport: `buyer_passports` (RLS legata a auth.users)
- AVM: `property_market_prices` (140 zone), `market_adjustment_factors` (con `default` fallback)
- BOQ: `boq_regional_coefficients`, `boq_difficulty_factors`, `boq_base_prices` (11 work_code pre-caricati), `visual_boq_estimates`

### Seed dati eseguito (Studio Casa Milano)
- 1 agenzia "Studio Casa Milano"
- 10 properties Milano premium (4 featured, 1 affitto, 1 da ristrutturare)
- 1 cover + 4 gallery per ognuna (Unsplash pubbliche)
- 5 planimetrie 2D, 3 asset 3D
- 6 renovation_categories + 10 renovation_items

### Storage buckets
- Public: `property-media`, `property-floorplans`, `property-3d`, `agency-branding`
- Private: `property-documents`

### RPC e Edge Functions
- RPC `find_nearest_market_price(user_lat, user_lon)` — Haversine + auto-join multipliers città
- Edge Function `analyze-room-photos` — ONLINE su `/functions/v1/analyze-room-photos`
  - Sandbox Demo Mode automatico se `GEMINI_API_KEY` non configurata server-side (utile per dev iOS)
  - Payload: `{ photos: ["data:image/jpeg;base64,..."], room_type, city, difficulty_factors, property_id }`
  - Response: `VisualBOQResponse` con `estimate_id, detected_room_type, detected_conditions[], estimated_works[], total_estimated_cost`

---

## 5. HUB DI COORDINAMENTO

### Endpoint
- Supabase URL stesso del progetto
- Tabella: `ai_coordination_messages`
- `sender`: `ios_ai` (noi), `frontend_ai` (Antigravity)

### Stato pending al momento
Tutti i messaggi importanti sono `read`. Frontend ha confermato seed completato e tutto online.

### Esempio chiamata cURL per leggere pending
```bash
curl -s "https://fviomnrtswsuoqfxcbki.supabase.co/rest/v1/ai_coordination_messages?sender=eq.frontend_ai&status=eq.pending&order=created_at.desc&limit=10" \
  -H "apikey: sb_publishable_zhcObBd9xMAzo-nTzoXhlw_LHlId9xh" \
  -H "Authorization: Bearer sb_publishable_zhcObBd9xMAzo-nTzoXhlw_LHlId9xh"
```

### Esempio cURL per inviare messaggio
```bash
curl -s -X POST "https://fviomnrtswsuoqfxcbki.supabase.co/rest/v1/ai_coordination_messages" \
  -H "apikey: ..." -H "Authorization: Bearer ..." \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d @/tmp/messaggio.json
```

---

## 6. PROSSIMA SESSIONE — DA DOVE RIPARTIRE

### Step immediato bloccato in mezzo
**VisualBOQ Capture/Result/Paywall views** — il VisualBOQService e il VisualBOQViewModel sono già creati (`Core/Supabase/Services/VisualBOQService.swift`, `ViewModels/VisualBOQViewModel.swift`). Manca:
1. `Views/VisualBOQ/ArkaiProPaywallView.swift` (sheet paywall)
2. `Views/VisualBOQ/VisualBOQCaptureView.swift` (PhotosPicker max 3 foto, room type, city pre-fill, multi-toggle difficulty, CTA "Analizza")
3. `Views/VisualBOQ/VisualBOQResultView.swift` (lista works + totale + "Salva" + retake)
4. Integrazione PropertyDetailView (nuova action card "Analizza una stanza · Arkai Vision Pro" con icon SF Symbols, brand sage scuro, badge PRO)
5. Info.plist: aggiungere `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` (Cesare deve farlo lato Xcode UI in Target Properties)

### Comando di partenza nuova sessione
"Ciao, continuiamo da dove eravamo. Leggi `HANDOVER_SESSION_2.md` nel repo, poi controlla HUB e procedi con VisualBOQ Capture/Result/Paywall views che erano l'ultimo task in corso. Memoria persistente già caricata."

---

## 7. RIFERIMENTI CHIAVE

### Documenti briefing nel repo
- `ARKAI_DOMUS_BRIEFING_CODER_APP_IOS_FRONTEND_ADMIN.md` — briefing completo struttura cartelle, DB schema, RLS
- `ARKAI_DOMUS_BRAND_IDENTITY_UI_COLOR_SYSTEM.md` — palette, typography, spacing, regole UI
- `BRIEFING OPERATIVO 2.md` — visione prodotto, roadmap
- `JSON UI/` — 14 file JSON specifiche UI iOS (cartella locale dal PC Windows)

### Memoria persistente (caricata automaticamente)
Path: `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/projects/-Users-cesare-Documents-PROJECTS-Domus-Arkai/memory/`
- `MEMORY.md` (indice)
- `hub_coordination.md`
- `project_context.md`
- `brand_design_tokens.md`
- `feedback_xcode_pbxproj.md`
- `feedback_supabase_orchestrator.md`
- `feedback_source_of_truth.md`
- `feedback_no_horizontal_overflow.md`
- `feedback_always_adaptive.md`
- `feedback_chiedi_screenshot_subito.md`
- `feedback_detail_view_pattern.md`

### Convenzioni comunicazione con Cesare
- Niente output markdown pesante in chat (tabelle/heading multipli) — testo plain o leggermente formattato
- Cesare è la source of truth: io sono orchestrator lato Supabase + iOS, decido fermamente quando emergono contraddizioni con frontend_ai
- Sempre chiedere screenshot device al primo bug UI — Canvas NON riproduce runtime
- Lavorare iterativamente con build verify dopo ogni service/view
