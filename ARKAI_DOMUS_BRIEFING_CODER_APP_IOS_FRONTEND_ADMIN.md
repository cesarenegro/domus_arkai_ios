# ARKAI DOMUS — BRIEFING COMPLETO PER CODER  
## App iOS + Frontend Admin Next.js

---

# 0. FILE DA INGESTARE PRIMA DI INIZIARE

Prima di scrivere codice, il coder deve leggere integralmente questi file/cartelle e considerarli come riferimento operativo vincolante.

## Cartella JSON UI

```text
E:\AI Brain Coder\ARKAI DOMUS\JSON UI
```

Contiene i file JSON specifici per ogni schermata/view.  
Ogni file descrive:

- funzione della view;
- piattaforma;
- layout;
- componenti;
- colori;
- typography;
- spacing;
- elementi da mostrare;
- elementi da evitare;
- regole UI specifiche.

Questi JSON sono la base visiva e funzionale delle schermate.

---

## Brand Identity / UI Color System

```text
E:\AI Brain Coder\ARKAI DOMUS\ARKAI_DOMUS_BRAND_IDENTITY_UI_COLOR_SYSTEM.md
```

Contiene:

- brand identity Arkai Domus;
- palette colori;
- typography;
- spacing system;
- radius;
- shadow;
- regole UI;
- regole dashboard;
- regole app iOS;
- regole per floorplan 3D;
- regole per schermate ristrutturazione;
- regole white-label.

Questo file deve essere usato come fonte principale per look & feel.

---

## Briefing Operativo

```text
E:\AI Brain Coder\ARKAI DOMUS\BRIEFING OPERATIVO 2.md
```

Contiene il briefing generale di prodotto, architettura, funzionalità e roadmap.

---

## Manifest JSON

```text
E:\AI Brain Coder\ARKAI DOMUS\README_MANIFEST.json
```

Contiene l’elenco dei file JSON e la logica di naming.

---

# 1. OBIETTIVO GENERALE DEL PROGETTO

Arkai Domus è una piattaforma immobiliare composta da:

1. **App iOS nativa in SwiftUI** per utenti finali.
2. **Frontend Admin in Next.js** per agenzie immobiliari.
3. **Backend Supabase** per database, autenticazione, storage, sicurezza e API dati.

L’obiettivo non è creare un semplice catalogo annunci, ma una piattaforma premium per agenzie immobiliari dove ogni immobile diventa una **scheda intelligente** con:

- foto;
- dati principali;
- planimetria 2D;
- floorplan 3D statico;
- calcolo mutuo indicativo;
- selezione lavori di ristrutturazione;
- grafico costi;
- preferiti;
- richiesta visita;
- contatto agenzia;
- gestione lead;
- gestione annunci da area riservata.

Il prodotto deve essere:

```text
premium
italiano
minimal
molto leggibile
realistico
non sovraccarico
adatto a vendita commerciale ad agenzie immobiliari
```

---

# 2. PRINCIPI UI OBBLIGATORI

Questi principi valgono sia per iOS che per Admin.

## Regola principale

Ogni schermata deve avere **una sola funzione principale**.

Esempio:

- Home = vedere immobili.
- Scheda immobile = capire l’immobile.
- Mutuo = stimare sostenibilità.
- Ristrutturazione = selezionare lavori e vedere costi.
- Admin Dashboard = capire andamento agenzia.
- Inserimento immobile = completare dati in modo guidato.

---

## Leggibilità

È obbligatorio evitare:

```text
testi piccoli
grafici inutili
schermate piene
tabelle troppo dense
contenuto finto
layout da SaaS generico
device con proporzioni irreali
```

Ogni dato mostrato deve avere un significato reale.

---

## Colori

Usare il sistema definito nel file:

```text
ARKAI_DOMUS_BRAND_IDENTITY_UI_COLOR_SYSTEM.md
```

Colori principali:

```css
background: #F7F4ED;
surface: #FFFFFF;
surfaceSoft: #F1EDE4;
primary: #243526;
primarySoft: #556B45;
primaryLight: #DDE5D3;
border: #D8D2C4;
text: #1E1E1E;
textMuted: #6E6A61;
accentWarm: #A48768;
warning: #B8795D;
```

Non usare colori casuali.

Evitare:

```text
blu SaaS generico
neon
troppi colori nei grafici
gradienti forti
rosseggianti aggressivi
oro finto lusso
```

---

## Charts

I grafici devono essere:

```text
grandi
leggibili
pochi
con un solo colore dominante
```

Usare principalmente:

```text
line chart
horizontal bar chart
simple funnel
```

Evitare:

```text
pie chart
grafici 3D
grafici multicolore
legende piccole
grafici decorativi senza funzione
```

---

## Floorplan 3D

La vista 3D deve essere:

```text
chiara
elegante
luminosa
architettonica
con colori chiari
senza caption dentro il floorplan
senza numeri dentro il floorplan
senza marker colorati
senza stanze colorate
```

Il floorplan 3D, nel primo MVP, è una **immagine statica caricata da Admin**, non un viewer 3D interattivo.

---

# 3. ARCHITETTURA GENERALE

## Stack

```text
iOS App:
- Swift
- SwiftUI
- MVVM
- Supabase Swift SDK
- Async/Await
- MapKit
- native image caching or controlled remote image loader

Frontend Admin:
- Next.js
- TypeScript
- Tailwind CSS
- Supabase JS Client
- React Hook Form
- Zod
- Recharts or similar lightweight chart library

Backend:
- Supabase
- PostgreSQL
- Supabase Auth
- Supabase Storage
- Row Level Security
- Supabase Edge Functions where useful
```

---

## Flusso dati principale

```text
Admin crea immobile
↓
Dati salvati in Supabase PostgreSQL
↓
Foto / planimetrie / documenti salvati in Supabase Storage
↓
Admin pubblica immobile
↓
App iOS mostra solo immobili online
↓
Utente finale consulta, salva, calcola mutuo/ristrutturazione, richiede visita
↓
Lead e richieste vengono salvati in Supabase
↓
Admin visualizza lead e richieste visita
```

---

# 4. DATABASE SUPABASE — STRUTTURA BASE

Il coder deve preparare lo schema database con queste tabelle principali.

```text
agencies
agency_users
profiles
properties
property_media
property_floorplans
property_3d_assets
property_documents
renovation_categories
renovation_items
renovation_estimates
renovation_estimate_items
mortgage_estimates
leads
visit_requests
favorites
property_views
agency_branding
app_settings
```

---

## 4.1 agencies

```sql
id uuid primary key
name text not null
slug text unique not null
logo_url text
phone text
email text
whatsapp text
address text
city text
website text
created_at timestamptz default now()
updated_at timestamptz default now()
```

---

## 4.2 agency_users

```sql
id uuid primary key
agency_id uuid references agencies(id)
user_id uuid references auth.users(id)
role text not null
created_at timestamptz default now()
```

Ruoli:

```text
super_admin
agency_admin
agency_editor
agency_viewer
```

---

## 4.3 properties

```sql
id uuid primary key
agency_id uuid references agencies(id)
title text not null
slug text
description_short text
description_long text
property_type text
contract_type text
price numeric
city text
area text
address text
address_public text
latitude numeric
longitude numeric
surface_commercial numeric
surface_internal numeric
rooms int
bedrooms int
bathrooms int
floor text
total_floors int
has_elevator boolean default false
has_balcony boolean default false
has_terrace boolean default false
has_garden boolean default false
has_garage boolean default false
has_parking boolean default false
has_cellar boolean default false
condition_status text
energy_class text
published_status text default 'draft'
is_featured boolean default false
created_at timestamptz default now()
updated_at timestamptz default now()
```

Stati:

```text
draft
ready
online
reserved
sold
rented
archived
```

---

## 4.4 property_media

```sql
id uuid primary key
agency_id uuid references agencies(id)
property_id uuid references properties(id)
file_url text
file_path text
media_type text
order_index int
is_cover boolean default false
created_at timestamptz default now()
```

Media type:

```text
cover
gallery
photo
```

---

## 4.5 property_floorplans

```sql
id uuid primary key
agency_id uuid references agencies(id)
property_id uuid references properties(id)
file_url text
file_path text
type text
created_at timestamptz default now()
```

Types:

```text
2d_plan
optimized_plan
pdf_plan
```

---

## 4.6 property_3d_assets

```sql
id uuid primary key
agency_id uuid references agencies(id)
property_id uuid references properties(id)
preview_image_url text
preview_image_path text
asset_url text
asset_path text
asset_type text default 'static_image'
created_at timestamptz default now()
```

MVP:

```text
asset_type = static_image
```

---

## 4.7 property_documents

```sql
id uuid primary key
agency_id uuid references agencies(id)
property_id uuid references properties(id)
document_type text
file_url text
file_path text
visibility text default 'private'
created_at timestamptz default now()
```

Document types:

```text
ape
visura_catastale
planimetria_catastale
atto_provenienza
regolamento_condominiale
other
```

Visibility:

```text
private
on_request
public
```

Nel MVP i documenti devono restare privati di default.

---

## 4.8 renovation_categories

```sql
id uuid primary key
agency_id uuid references agencies(id)
name text not null
description text
order_index int
is_active boolean default true
created_at timestamptz default now()
```

---

## 4.9 renovation_items

```sql
id uuid primary key
agency_id uuid references agencies(id)
category_id uuid references renovation_categories(id)
name text not null
description text
unit_type text
base_price numeric
medium_price numeric
premium_price numeric
default_quantity numeric
is_active boolean default true
order_index int
created_at timestamptz default now()
updated_at timestamptz default now()
```

Unit types:

```text
sqm
unit
fixed
```

---

## 4.10 leads

```sql
id uuid primary key
agency_id uuid references agencies(id)
property_id uuid references properties(id)
name text
email text
phone text
message text
source text
status text default 'new'
created_at timestamptz default now()
updated_at timestamptz default now()
```

Sources:

```text
visit_request
mortgage_calculator
renovation_estimate
contact_form
whatsapp_click
phone_click
favorite
```

Statuses:

```text
new
contacted
visit_scheduled
qualified
lost
converted
```

---

## 4.11 visit_requests

```sql
id uuid primary key
agency_id uuid references agencies(id)
property_id uuid references properties(id)
lead_id uuid references leads(id)
preferred_date date
preferred_time_slot text
notes text
status text default 'new'
created_at timestamptz default now()
```

Statuses:

```text
new
confirmed
rescheduled
cancelled
completed
```

---

## 4.12 mortgage_estimates

```sql
id uuid primary key
agency_id uuid references agencies(id)
property_id uuid references properties(id)
lead_id uuid references leads(id)
monthly_income numeric
second_income numeric
available_deposit numeric
mortgage_years int
existing_monthly_debts numeric
interest_rate numeric
estimated_loan_amount numeric
estimated_monthly_payment numeric
income_ratio numeric
sustainability_status text
created_at timestamptz default now()
```

---

## 4.13 favorites

```sql
id uuid primary key
user_id uuid references auth.users(id)
property_id uuid references properties(id)
created_at timestamptz default now()
```

Nel primo MVP i preferiti possono essere locali su iOS se non si vuole login utente.

---

# 5. SUPABASE STORAGE

Creare bucket:

```text
property-media
property-floorplans
property-3d
property-documents
agency-branding
```

Struttura path:

```text
/agencies/{agency_id}/properties/{property_id}/media/
/agencies/{agency_id}/properties/{property_id}/floorplans/
/agencies/{agency_id}/properties/{property_id}/3d/
/agencies/{agency_id}/properties/{property_id}/documents/
/agencies/{agency_id}/branding/
```

Regole:

```text
Foto pubbliche solo per immobili pubblicati.
Documenti privati mai pubblici di default.
Ogni agenzia vede solo i propri file.
Super admin vede tutto.
```

---

# 6. ROW LEVEL SECURITY

RLS obbligatoria.

## Regola pubblica

La app pubblica può leggere solo:

```text
properties.published_status = 'online'
```

e solo asset pubblici associati.

---

## Regola agenzia

Un utente agenzia può leggere/modificare solo record con:

```text
agency_id = agency_id associato al suo user_id in agency_users
```

---

## Regola super admin

Super admin può leggere/modificare tutto.

---

# 7. SEZIONE APP iOS

---

# APP IOS

## 7.1 Obiettivo App iOS

L’app iOS è destinata al pubblico finale.

Funzioni MVP:

```text
Splash
Home / lista immobili
Ricerca e filtri
Scheda immobile
Gallery foto
Planimetria 2D
Floorplan 3D statico
Calcolo mutuo
Risultato mutuo
Selezione lavori ristrutturazione
Grafico costi ristrutturazione
Preferiti
Prenota visita
Contatta agenzia
Profilo leggero
```

---

## 7.2 File JSON da usare per iOS

Leggere dalla cartella:

```text
E:\AI Brain Coder\ARKAI DOMUS\JSON UI
```

File rilevanti per App iOS:

```text
01_ios_splash_brand_intro.json
02_ios_home_property_feed.json
03_ios_search_filters.json
04_ios_property_detail.json
05_ios_gallery.json
06_ios_2d_floorplan.json
07_ios_3d_floorplan.json
08_ios_mortgage_form.json
09_ios_mortgage_result.json
10_ios_renovation_selection_costs.json
11_ios_renovation_cost_chart.json
12_ios_visit_booking.json
13_ios_agency_contact.json
14_ios_favorites.json
```

Ogni view SwiftUI deve seguire la specifica JSON corrispondente.

---

## 7.3 Architettura iOS richiesta

Usare architettura:

```text
SwiftUI
MVVM
Services
Models
Reusable Components
Design Tokens
```

Struttura cartelle suggerita:

```text
ArkaiDomus/
  App/
    ArkaiDomusApp.swift
    AppRouter.swift

  Core/
    Config/
    Supabase/
    Theme/
    Extensions/
    Utilities/

  Models/
    Agency.swift
    Property.swift
    PropertyMedia.swift
    PropertyFloorplan.swift
    Property3DAsset.swift
    RenovationItem.swift
    RenovationEstimate.swift
    MortgageEstimate.swift
    Lead.swift
    VisitRequest.swift

  Services/
    PropertyService.swift
    MediaService.swift
    FavoriteService.swift
    MortgageService.swift
    RenovationService.swift
    LeadService.swift
    VisitRequestService.swift
    AgencyService.swift

  ViewModels/
    HomeViewModel.swift
    SearchFilterViewModel.swift
    PropertyDetailViewModel.swift
    MortgageViewModel.swift
    RenovationViewModel.swift
    FavoritesViewModel.swift
    VisitBookingViewModel.swift
    AgencyContactViewModel.swift

  Views/
    Splash/
    Home/
    Search/
    PropertyDetail/
    Gallery/
    Floorplan2D/
    Floorplan3D/
    Mortgage/
    Renovation/
    Favorites/
    VisitBooking/
    AgencyContact/
    Profile/

  Components/
    PropertyCard.swift
    PrimaryButton.swift
    SecondaryButton.swift
    InfoCard.swift
    SpecPill.swift
    BottomTabBar.swift
    LoadingView.swift
    EmptyStateView.swift
    ErrorStateView.swift
```

---

## 7.4 Regole SwiftUI obbligatorie

Il coder deve rispettare queste regole per evitare layout instabili.

```text
Non usare Spacer() in modo incontrollato.
Non annidare padding multipli senza logica.
Non usare .frame(maxWidth: .infinity, maxHeight: .infinity) ovunque.
Non creare VStack/HStack ambigui.
Non usare testi sotto 12 pt.
Non usare card senza altezza o ratio controllato.
Non usare immagini senza aspect ratio.
Non usare tabelle su iPhone.
```

Ogni screen deve essere testato almeno su:

```text
iPhone 15
iPhone 15 Pro
iPhone 15 Pro Max
iPhone SE, se supportato
```

---

## 7.5 Theme iOS

Creare un file theme centrale.

Esempio:

```swift
enum ADColor {
    static let background = Color(hex: "#F7F4ED")
    static let surface = Color(hex: "#FFFFFF")
    static let surfaceSoft = Color(hex: "#F1EDE4")
    static let primary = Color(hex: "#243526")
    static let primarySoft = Color(hex: "#556B45")
    static let primaryLight = Color(hex: "#DDE5D3")
    static let border = Color(hex: "#D8D2C4")
    static let text = Color(hex: "#1E1E1E")
    static let textMuted = Color(hex: "#6E6A61")
}
```

Creare anche:

```swift
enum ADSpacing
enum ADRadius
enum ADTypography
```

Nessuna view deve usare colori hardcoded sparsi.

---

## 7.6 Tab Bar iOS

Tab principali:

```text
Casa
Ricerca
Preferiti
Contatti
Profilo
```

La tab bar deve essere:

```text
minimal
leggibile
con icone sottili
active color verde salvia
inactive color grigio caldo
```

---

## 7.7 Home / Property Feed

View:

```text
02_ios_home_property_feed.json
```

Funzione:

```text
Mostrare immobili disponibili con cards grandi e leggibili.
```

Contenuti:

```text
Header agenzia
Search bar
Filtri rapidi
Lista property cards
```

Ogni property card mostra:

```text
Foto cover
Badge opzionale
Cuore preferiti
Prezzo
Titolo
Zona
Mq
Camere/locali
Bagni
Feature principale
```

Non mostrare:

```text
dati catastali
descrizione lunga
troppi badge
troppi metadata
```

---

## 7.8 Scheda immobile

View:

```text
04_ios_property_detail.json
```

Funzione:

```text
Mostrare l’immobile come dossier premium.
```

Sezioni obbligatorie:

```text
Hero image
Prezzo
Titolo
Zona
Main specs
Descrizione breve
Gallery
Planimetria
Vista 3D
Calcola mutuo
Stima ristrutturazione
Prenota visita
Contatta agenzia
```

CTA principali:

```text
Calcola mutuo
Stima ristrutturazione
Prenota visita
```

CTA secondarie:

```text
Chiama
WhatsApp
Email
Salva
Condividi
```

---

## 7.9 Planimetria 2D

View:

```text
06_ios_2d_floorplan.json
```

MVP:

```text
Visualizzare immagine 2D caricata da Admin.
Supportare zoom/pinch.
Mostrare dati rapidi fuori dall’immagine.
```

Regola:

```text
La planimetria deve restare pulita.
Nessuna colorazione eccessiva.
Nessun testo minuscolo inutile.
```

---

## 7.10 Floorplan 3D

View:

```text
07_ios_3d_floorplan.json
```

MVP:

```text
Visualizzare immagine statica del floorplan 3D.
```

Regole obbligatorie:

```text
colori chiari
no caption dentro il floorplan
no marker numerici
no stanze colorate
no arredi saturi
no effetto cartoon
```

Dati mostrati fuori immagine:

```text
95 mq
3 locali
2 bagni
Classe A2
```

---

## 7.11 Calcolo mutuo

Views:

```text
08_ios_mortgage_form.json
09_ios_mortgage_result.json
```

Campi form:

```text
Reddito mensile netto
Secondo reddito familiare
Anticipo disponibile
Durata mutuo
Altri impegni mensili
Età
Prima casa sì/no
```

Output:

```text
Rata mensile stimata
Importo mutuo indicativo
Incidenza sul reddito
Sostenibilità
```

Formula base:

```text
loan_amount = property_price - available_deposit

monthly_rate = annual_interest_rate / 12
number_of_payments = years * 12

monthly_payment =
loan_amount * monthly_rate * (1 + monthly_rate)^number_of_payments
/
((1 + monthly_rate)^number_of_payments - 1)

income_ratio = monthly_payment / total_monthly_income
```

Soglie indicative:

```text
<= 30% = buona
31% - 40% = da verificare
> 40% = critica
```

Disclaimer obbligatorio:

```text
La simulazione è indicativa e non costituisce approvazione bancaria.
```

---

## 7.12 Ristrutturazione

Views:

```text
10_ios_renovation_selection_costs.json
11_ios_renovation_cost_chart.json
```

L’utente può selezionare:

```text
Tinteggiature
Pavimenti
Rifacimento bagno
Serramenti
Impianto elettrico
Impianto idraulico
Cucina
Climatizzazione
Porte interne
Demolizioni leggere
```

Output:

```text
lista lavori selezionati
costo per intervento
grafico barre orizzontali
totale indicativo
range Essenziale / Medio / Premium
```

Regole UI:

```text
no pie chart
no tabelle dense
no troppi colori
barre solo verde salvia
valori grandi e leggibili
```

---

## 7.13 Prenota visita

View:

```text
12_ios_visit_booking.json
```

Campi:

```text
Data visita
Fascia oraria
Nome e cognome
Telefono
Email
Note
```

Alla submission:

1. creare lead;
2. creare visit_request;
3. mostrare conferma.

Messaggio conferma:

```text
Richiesta ricevuta.
L’agenzia ti contatterà per confermare la visita.
```

---

## 7.14 Contatta agenzia

View:

```text
13_ios_agency_contact.json
```

Mostrare:

```text
logo agenzia
nome agenzia
telefono
WhatsApp
email
indirizzo
orari
mini mappa
```

Azioni:

```text
Chiama
Apri WhatsApp
Invia Email
Apri Mappa
```

---

## 7.15 Preferiti

View:

```text
14_ios_favorites.json
```

MVP:

```text
Preferiti salvati localmente.
```

Fase successiva:

```text
Preferiti su Supabase con utente autenticato.
```

---

## 7.16 App iOS — Deliverable richiesti

Il coder deve consegnare:

```text
Progetto Xcode funzionante
Connessione Supabase
Theme centralizzato
Models completi
Services completi
ViewModels principali
Tutte le view MVP
Gestione loading/error/empty states
Test su simulatori principali
```

---

# 8. SEZIONE FRONTEND ADMIN

---

# FRONTEND ADMIN

## 8.1 Obiettivo Frontend Admin

Il Frontend Admin è l’area riservata per l’agenzia.

Deve permettere di:

```text
fare login
vedere dashboard
creare immobili
modificare immobili
caricare foto
caricare planimetrie
caricare floorplan 3D statico
caricare documenti
gestire pubblicazione
gestire lead
gestire richieste visita
gestire tabelle costi ristrutturazione
gestire branding agenzia
```

---

## 8.2 File JSON da usare per Frontend Admin

Leggere dalla cartella:

```text
E:\AI Brain Coder\ARKAI DOMUS\JSON UI
```

File rilevanti:

```text
15_web_admin_login.json
16_web_agency_dashboard_minimal.json
17_web_properties_list.json
18_web_property_insert_step_1_data.json
19_web_property_insert_step_2_media.json
20_web_property_insert_step_3_technical.json
21_web_property_documents.json
22_web_publishing_control.json
23_web_renovation_price_table.json
24_web_leads_management.json
25_web_visit_requests.json
26_web_agency_branding_white_label.json
27_web_settings_users_roles.json
```

Ogni pagina Next.js deve seguire il JSON corrispondente.

---

## 8.3 Architettura Next.js richiesta

Struttura suggerita:

```text
arkai-domus-admin/
  app/
    login/
      page.tsx

    dashboard/
      page.tsx

    properties/
      page.tsx
      new/
        page.tsx
      [id]/
        edit/
          page.tsx

    leads/
      page.tsx

    visits/
      page.tsx

    renovation/
      page.tsx

    branding/
      page.tsx

    settings/
      users/
        page.tsx

  components/
    layout/
      AdminShell.tsx
      Sidebar.tsx
      Topbar.tsx

    ui/
      Button.tsx
      Card.tsx
      Input.tsx
      Select.tsx
      Badge.tsx
      Tabs.tsx
      Modal.tsx
      EmptyState.tsx

    dashboard/
      KpiCard.tsx
      LineChartCard.tsx
      FunnelCard.tsx
      RecentActivity.tsx

    properties/
      PropertyTable.tsx
      PropertyFormStepData.tsx
      PropertyMediaUpload.tsx
      PropertyTechnicalForm.tsx
      PropertyDocuments.tsx
      PropertyPublishing.tsx
      PropertyPreviewCard.tsx

    renovation/
      RenovationPriceTable.tsx
      RenovationItemDrawer.tsx

    leads/
      LeadCard.tsx
      LeadDetailPanel.tsx

  lib/
    supabase/
      client.ts
      server.ts
    auth/
    validators/
    storage/
    utils/

  actions/
    properties.ts
    media.ts
    documents.ts
    leads.ts
    visits.ts
    renovation.ts
    branding.ts

  styles/
    globals.css
    theme.css
```

---

## 8.4 Theme Next.js / Tailwind

Creare tokens in Tailwind o CSS variables.

CSS variables obbligatorie:

```css
:root {
  --background: #F7F4ED;
  --surface: #FFFFFF;
  --surface-soft: #F1EDE4;
  --primary: #243526;
  --primary-soft: #556B45;
  --primary-light: #DDE5D3;
  --border: #D8D2C4;
  --text: #1E1E1E;
  --text-muted: #6E6A61;
  --accent-warm: #A48768;
  --warning: #B8795D;
}
```

---

## 8.5 Admin Login

View:

```text
15_web_admin_login.json
```

Funzione:

```text
Accesso sicuro all’area riservata.
```

Layout:

```text
sfondo caldo
card login centrale
logo Arkai Domus
email
password
login button
nota sicurezza
```

---

## 8.6 Admin Dashboard

View:

```text
16_web_agency_dashboard_minimal.json
```

La dashboard deve essere minimal.

Mostrare solo:

```text
Immobili pubblicati
Richieste visita
Lead ricevuti
Conversione
```

Grafici:

```text
Andamento richieste visita
Funnel conversione
```

Liste:

```text
Attività recenti
Top immobili
```

Regole:

```text
massimo 4 KPI cards
grafici grandi
nessuna tabella densa
nessun dato finto senza senso
```

---

## 8.7 Properties List

View:

```text
17_web_properties_list.json
```

Tabella:

```text
Foto
Titolo
Zona
Prezzo
Stato
Lead
Aggiornato
Azioni
```

Azioni:

```text
Modifica
Anteprima
Duplica
Archivia
Elimina, solo admin
```

Stati:

```text
Bozza
Online
Riservato
Venduto
Affittato
Archiviato
```

---

## 8.8 Inserimento immobile — Wizard

Il wizard è centrale.

Step:

```text
1. Dati immobile
2. Media e planimetrie
3. Dettagli tecnici
4. Documenti
5. Pubblicazione
```

Il wizard deve permettere:

```text
salva bozza
continua
torna indietro
anteprima annuncio
pubblica solo quando dati obbligatori sono validi
```

---

## 8.9 Step 1 — Dati immobile

View:

```text
18_web_property_insert_step_1_data.json
```

Campi:

```text
Tipologia
Contratto
Titolo annuncio
Prezzo
Comune
Zona
Indirizzo
Mq
Camere
Bagni
Classe energetica
```

Layout:

```text
form a sinistra
preview card a destra
```

Non mostrare troppi dati tecnici in questo step.

---

## 8.10 Step 2 — Media e planimetrie

View:

```text
19_web_property_insert_step_2_media.json
```

Sezioni:

```text
Gallery foto
Planimetria 2D
Floorplan 3D statico
Documenti principali
```

Funzioni:

```text
upload
drag & drop
riordino foto
scelta cover
upload planimetria
upload preview 3D
```

Obbligatorio:

```text
foto cover prima della pubblicazione
```

---

## 8.11 Step 3 — Dettagli tecnici

View:

```text
20_web_property_insert_step_3_technical.json
```

Gruppi:

```text
Superfici
Locali
Edificio
Caratteristiche
Energia
```

Campi:

```text
superficie commerciale
superficie calpestabile
locali
camere
bagni
piano
ascensore
balcone
terrazza
giardino
box
posto auto
cantina
anno costruzione
stato immobile
riscaldamento
climatizzazione
spese condominiali
classe energetica
EPgl
```

---

## 8.12 Documenti

View:

```text
21_web_property_documents.json
```

Documenti:

```text
APE
Visura catastale
Planimetria catastale
Atto di provenienza
Regolamento condominiale
Altro
```

Ogni documento deve avere:

```text
tipo documento
file
visibilità
azioni
```

Visibilità:

```text
privato agenzia
visibile su richiesta
pubblico
```

Default:

```text
privato agenzia
```

---

## 8.13 Pubblicazione

View:

```text
22_web_publishing_control.json
```

Stati:

```text
Bozza
Pronto per pubblicazione
Online
Riservato
Venduto
Archiviato
```

Regole:

```text
Non pubblicare senza titolo.
Non pubblicare senza prezzo.
Non pubblicare senza cover.
Non pubblicare senza città/zona.
```

---

## 8.14 Tabelle costi ristrutturazione

View:

```text
23_web_renovation_price_table.json
```

Categorie consigliate:

```text
Bagno
Pittura
Pavimenti
Serramenti
Impianti
Cucina
```

Colonne:

```text
Intervento
Unità
Base
Medio
Premium
Attivo
```

La tabella deve essere chiara, non stile Excel complesso.

---

## 8.15 Lead Management

View:

```text
24_web_leads_management.json
```

Mostrare:

```text
nome lead
immobile interessato
fonte
data
stato
azioni
```

Fonti:

```text
richiesta visita
calcolo mutuo
stima ristrutturazione
form contatto
WhatsApp click
phone click
```

Stati:

```text
Nuovo
Contattato
Visita fissata
Qualificato
Perso
Convertito
```

---

## 8.16 Visit Requests

View:

```text
25_web_visit_requests.json
```

Mostrare:

```text
data richiesta
fascia oraria
cliente
immobile
stato
azioni
```

Azioni:

```text
Conferma
Riprogramma
Chiama
Archivia
```

---

## 8.17 Branding / White Label

View:

```text
26_web_agency_branding_white_label.json
```

Configurazioni:

```text
logo agenzia
nome agenzia
colore primario
telefono
WhatsApp
email
sito
dominio
preview desktop
preview mobile
```

Regola:

```text
Arkai Domus deve restare visibile come powered-by.
```

---

## 8.18 Settings / Users & Roles

View:

```text
27_web_settings_users_roles.json
```

Gestire:

```text
lista utenti
invito utente
ruolo utente
disattivazione utente
```

Ruoli:

```text
agency_admin
agency_editor
agency_viewer
```

---

## 8.19 Frontend Admin — Deliverable richiesti

Il coder deve consegnare:

```text
Progetto Next.js funzionante
Login Supabase
Theme completo
Layout admin
Dashboard minimal
Lista immobili
Wizard inserimento immobile
Upload foto
Upload planimetrie
Upload 3D statico
Upload documenti
Gestione pubblicazione
Gestione lead
Gestione richieste visita
Gestione costi ristrutturazione
Gestione branding agenzia
Gestione utenti/ruoli
```

---

# 9. VALIDAZIONE DATI

Usare validazione Zod per Admin.

Campi obbligatori per pubblicare immobile:

```text
agency_id
title
price
city
area
property_type
contract_type
cover image
surface_commercial
published_status
```

Campi consigliati:

```text
description_short
rooms
bedrooms
bathrooms
energy_class
floorplan 2D
```

---

# 10. CALCOLI

## 10.1 Mutuo

Il calcolo può stare:

```text
client-side per MVP
server-side Edge Function per maggiore controllo
```

Formula:

```text
monthly_payment =
loan_amount * monthly_rate * (1 + monthly_rate)^n
/
((1 + monthly_rate)^n - 1)
```

Sostenibilità:

```text
<= 30% = buona
31-40% = da verificare
> 40% = critica
```

---

## 10.2 Ristrutturazione

Formula MVP:

```text
if unit_type == sqm:
  cost = property_surface * unit_price

if unit_type == unit:
  cost = quantity * unit_price

if unit_type == fixed:
  cost = fixed_price
```

Fasce:

```text
base
medium
premium
```

UI deve mostrare soprattutto:

```text
totale indicativo
range essenziale / medio / premium
grafico costi per categoria
```

---

# 11. ERROR, LOADING, EMPTY STATES

Ogni view deve gestire:

```text
loading
error
empty state
no connection
upload failed
permission denied
```

Esempi:

```text
Nessun immobile disponibile.
Errore nel caricamento delle immagini.
Documento non disponibile.
Impossibile inviare la richiesta, riprova.
```

Non lasciare schermate bianche.

---

# 12. TESTING

## Test Supabase

```text
Creazione agenzia
Creazione utente agenzia
Creazione immobile
Upload media
Upload documenti
Pubblicazione immobile
RLS tra agenzie diverse
Lettura pubblica solo immobili online
```

---

## Test iOS

```text
Home carica immobili
Filtri funzionano
Scheda immobile apre correttamente
Gallery funziona
Planimetria visibile
Floorplan 3D statico visibile
Calcolo mutuo corretto
Stima ristrutturazione corretta
Preferiti funzionano
Richiesta visita crea lead
Contatta agenzia apre azioni corrette
```

---

## Test Admin

```text
Login funzionante
Dashboard mostra dati reali
Lista immobili corretta
Wizard salva bozza
Upload foto funziona
Upload planimetria funziona
Upload 3D funziona
Documenti privati restano privati
Pubblicazione valida obbligatori
Lead visibili
Richieste visita gestibili
Costi ristrutturazione modificabili
Branding modificabile
```

---

# 13. ROADMAP OPERATIVA

## Fase 1 — Setup base

```text
Supabase project
Schema database
RLS
Storage buckets
Seed data
Next.js setup
Xcode setup
Theme condiviso
```

---

## Fase 2 — Frontend Admin base

```text
Login
Dashboard
Lista immobili
Wizard step 1
Wizard step 2
Upload media
Pubblicazione base
```

---

## Fase 3 — App iOS base

```text
Home
Lista immobili
Scheda immobile
Gallery
Planimetria
Floorplan 3D statico
Preferiti
Contatto agenzia
```

---

## Fase 4 — Moduli intelligenti

```text
Calcolo mutuo
Risultato mutuo
Selezione lavori
Grafico costi
Lead da simulazioni
```

---

## Fase 5 — Lead e agenzia

```text
Richieste visita
Lead management
Dashboard analytics
Top immobili
Conversione
```

---

## Fase 6 — White label

```text
Logo agenzia
Colori agenzia
Preview
Powered by Arkai Domus
Dominio / sito, se previsto
```

---

# 14. FUNZIONI DA NON IMPLEMENTARE NEL PRIMO MVP

Non implementare subito:

```text
viewer 3D interattivo reale
AI generativa planimetrie
integrazione automatica portali immobiliari
CRM complesso
chat interna
notifiche push complesse
comparatore mutui bancari reale
firma documenti
app Android
multi-lingua
```

Il primo MVP deve essere stabile, bello, leggibile e vendibile.

---

# 15. PRIORITÀ ASSOLUTE

## Priorità 1

```text
Database corretto
RLS corretta
Upload file stabile
CRUD immobili funzionante
```

## Priorità 2

```text
UI coerente con JSON
App iOS fluida
Dashboard minimal
Schermate leggibili
```

## Priorità 3

```text
Mutuo
Ristrutturazione
Lead
Richieste visita
```

## Priorità 4

```text
Branding white-label
Analytics
Ottimizzazioni
```

---

# 16. REGOLA FINALE PER IL CODER

Prima di implementare ogni schermata:

1. aprire il JSON corrispondente;
2. leggere il Brand Identity file;
3. verificare la funzione principale della view;
4. implementare solo ciò che serve alla funzione;
5. evitare contenuti finti e sovraccarico;
6. testare leggibilità su device reali/simulatori;
7. verificare sicurezza Supabase/RLS.

Ogni schermata deve essere:

```text
leggibile
realistica
coerente
pulita
utile
premium
```

Il risultato finale deve sembrare una piattaforma reale per agenzie immobiliari italiane, non un mockup generico.
