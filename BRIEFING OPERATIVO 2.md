---
title: "ChatGPT - APP IMMOBILIARE"
source: "https://chatgpt.com/c/6a0efed6-3b5c-83ec-8d4c-d4a1e1330f1a"
author:
published:
created: 2026-05-21
description: "ChatGPT conversation with 42 messages"
tags:
  - "clippings"
---
## App iOS + Area Riservata Desktop per Agenzie Immobiliari

---

# 1\. Visione generale del prodotto

**Arkai Domus** è una piattaforma immobiliare composta da:

1. **App iOS pubblica per iPhone**, destinata agli utenti finali che cercano immobili.
2. **Area riservata desktop in Next.js**, destinata alle agenzie immobiliari per gestire immobili, foto, planimetrie, documenti, lead e tabelle di ristrutturazione.
3. **Backend Supabase**, usato per database, autenticazione, storage file, regole di accesso e API dati.

L’obiettivo non è creare un semplice catalogo immobiliare, ma una **scheda immobile intelligente**, elegante e molto chiara, che permetta all’utente finale di capire:

- quali immobili sono disponibili;
- come sono distribuiti gli spazi;
- quanto può costare il mutuo;
- quanto può costare una ristrutturazione;
- quali lavori può selezionare;
- quali documenti o dettagli tecnici sono disponibili;
- come contattare rapidamente l’agenzia;
- come prenotare una visita.

Per l’agenzia, invece, Arkai Domus deve essere uno strumento semplice per:

- caricare immobili;
- gestire immagini e planimetrie;
- pubblicare annunci;
- ricevere lead;
- vedere statistiche principali;
- controllare richieste visita;
- configurare costi di ristrutturazione;
- gestire l’app come prodotto white-label.

---

# 2\. Stack tecnico consigliato

## App iOS

Tecnologia:

```
SwiftSwiftUIMVVMSupabase Swift SDKAsync/AwaitURLSession where neededKingfisher or native AsyncImage with caching strategyMapKitCharts framework if needed
```

L’app iOS deve essere **nativa SwiftUI**, non una webview.

Target minimo consigliato:

```
iOS 17+
```

Motivo: permette UI più moderna, uso migliore di SwiftUI, animazioni fluide, navigation stack più pulito e layout più stabile.

---

## Area riservata desktop

Tecnologia:

```
Next.jsTypeScriptTailwind CSSSupabase JS ClientServer Actions / API routesReact Hook FormZod validationRecharts or Tremor-style charts
```

L’area riservata deve essere principalmente desktop-first, ma responsive anche su tablet e mobile.

---

## Backend

Tecnologia:

```
SupabasePostgreSQLSupabase AuthSupabase StorageRow Level SecuritySupabase Edge Functions
```

Supabase è la scelta principale perché il sistema è molto relazionale:

- agenzie;
- utenti agenzia;
- immobili;
- foto;
- planimetrie;
- documenti;
- lead;
- richieste visita;
- stime mutuo;
- stime ristrutturazione;
- tabelle prezzi;
- analytics.

Firebase non è consigliato come database principale per questo progetto. Può essere eventualmente usato solo per notifiche push in una fase successiva.

---

# 3\. Architettura generale

```
ARKAI DOMUS PLATFORM1. iOS App pubblica   ↓2. Supabase API / Database / Storage   ↑3. Next.js Area Riservata Agenzia
```

Flusso dati:

```
Agenzia inserisce immobile da dashboard desktop↓Dati salvati in Supabase↓Foto, planimetrie e documenti salvati in Supabase Storage↓App iOS legge solo immobili pubblicati↓Utente visualizza immobile, calcola mutuo, calcola ristrutturazione↓L’app crea lead o richiesta visita↓Agenzia vede tutto nella dashboard
```

---

# 4\. Moduli principali del sistema

## Modulo 1 — App pubblica iOS

L’app iOS deve contenere:

1. Home / Lista immobili
2. Ricerca e filtri
3. Scheda immobile
4. Gallery fotografica
5. Planimetria 2D
6. Vista floorplan 3D
7. Calcolo mutuo indicativo
8. Selezione lavori ristrutturazione
9. Grafico costi ristrutturazione
10. Preferiti
11. Prenota visita
12. Contatta agenzia
13. Profilo utente leggero
14. Notifiche base, opzionale in fase 2

---

## Modulo 2 — Area riservata agenzia desktop

La dashboard desktop deve contenere:

1. Login agenzia
2. Dashboard generale
3. Lista immobili
4. Inserimento nuovo immobile
5. Modifica immobile
6. Upload foto
7. Upload planimetrie
8. Upload documenti
9. Dati tecnici e catastali
10. Classe energetica
11. Stato pubblicazione
12. Lead ricevuti
13. Richieste visita
14. Tabelle costi ristrutturazione
15. Statistiche annunci
16. Impostazioni agenzia
17. White-label branding

---

# 5\. UX e stile grafico generale

## Direzione estetica

Arkai Domus deve avere un’identità:

```
premiumitalianachiaraarchitettonicacaldaminimalmolto leggibile
```

Non deve sembrare:

```
portale immobiliare economicodashboard SaaS genericaapp troppo pienainterfaccia troppo tecnica
```

---

## Palette consigliata

```
Background principale: bianco caldo / avorioCard background: beige chiarissimoTesto principale: verde scuro / grafiteAccento: verde salviaBordi: grigio caldo chiaroCTA principale: verde profondoCTA secondaria: bordo verde / sfondo biancoAlert: terracotta molto soft
```

Esempio palette:

```
#F7F4ED  background caldo#FFFFFF  card principali#243526  verde scuro testo#556B45  verde salvia CTA#D8D2C4  bordi soft#A48768  accento caldo#1E1E1E  testo forte
```

---

## Tipografia

Per l’app iOS usare San Francisco, ma con gerarchia elegante.

Per dashboard web:

```
Titoli grandi: serif elegante oppure font tipo Cormorant/PlayfairTesti UI: Inter / Helvetica / system sans
```

Per il coder: non usare troppi font. Massimo due famiglie.

---

# 6\. Regole UI obbligatorie per Xcode / SwiftUI

Il coder deve evitare problemi classici di layout SwiftUI.

## Regole fondamentali

1. Non usare `Spacer()` in modo incontrollato.
2. Non annidare troppi `VStack` con padding diversi.
3. Non mettere padding multipli su card e container senza controllo.
4. Ogni card deve avere dimensioni, spacing e alignment chiari.
5. Le schermate devono rispettare Safe Area.
6. Bottom tab bar sempre stabile.
7. Header e contenuto devono essere separati.
8. Le immagini devono avere aspect ratio fisso.
9. Le card immobili devono avere altezza coerente.
10. I bottoni CTA devono avere altezza minima 48 px.
11. I form devono avere campi leggibili, non compressi.
12. Evitare testi piccoli sotto 12 pt.
13. Ogni screen deve essere testato su:
	- iPhone 15
		- iPhone 15 Pro
		- iPhone 15 Pro Max
		- iPhone SE, se supportato

---

## Layout consigliato SwiftUI

Ogni schermata principale:

```
NavigationStack  ZStack background    VStack spacing controlled      Header      ScrollView        Content sections      Bottom area if needed
```

Per cards:

```
VStack(alignment: .leading, spacing: 12).padding(16).background(...).cornerRadius(20)
```

Per evitare errori:

```
No random .frame(maxWidth: .infinity, maxHeight: .infinity) everywhereNo conflicting .padding on parent and childNo absolute positioning unless strictly neededNo fixed height for scroll content unless necessary
```

---

# 7\. Struttura App iOS

## Tab bar principale

La tab bar pubblica deve avere:

```
CasaRicercaPreferitiMessaggi / ContattiProfilo
```

Oppure versione più semplice MVP:

```
CasaRicercaPreferitiContattiProfilo
```

---

# 8\. Schermate iOS dettagliate

---

## 8.1 Splash Screen

Scopo: apertura app brandizzata.

Contenuti:

```
Arkai DomusLa nuova esperienza immobiliare intelligenteLogo agenzia / powered by Arkai Domus
```

Durata breve, massimo 1 secondo.

---

## 8.2 Home / Lista immobili

Schermata principale pubblica.

Contenuti:

```
Header:- nome agenzia- icona notifiche- eventuale logo piccoloSearch:- Cerca per zona, indirizzo, tipologiaFiltri rapidi:- Città- Vendita / Affitto- Prezzo- Mq- LocaliLista cards immobili:- foto grande- prezzo- zona- titolo- mq- camere- bagni- terrazza / giardino / box- badge stato- cuore preferiti
```

Card esempio:

```
€ 780.000Attico in Brera120 mq · 3 camere · 2 bagni · TerrazzaBadge: Nuovo
```

Azioni:

```
Tap card → apre scheda immobileTap cuore → salva preferitoTap filtro → aggiorna lista
```

---

## 8.3 Ricerca avanzata

Filtri:

```
Tipo contratto:- vendita- affittoTipologia:- appartamento- villa- attico- loft- ufficio- terreno- locale commercialePrezzo:- minimo- massimoSuperficie:- minimo mq- massimo mqLocali:- 1- 2- 3- 4+  Camere:- 1- 2- 3+Extra:- terrazza- giardino- box- ascensore- ristrutturato- nuova costruzione
```

MVP: filtri base.  
Fase 2: filtri avanzati.

---

## 8.4 Scheda immobile

Questa è la schermata più importante.

Struttura:

```
1. Hero image2. Prezzo3. Titolo4. Zona5. Caratteristiche principali6. Descrizione breve7. Gallery8. Planimetria9. Vista 3D10. Dati tecnici11. Classe energetica12. Calcola mutuo13. Calcola ristrutturazione14. Prenota visita15. Contatta agenzia
```

Layout sezione top:

```
€ 780.000Attico in BreraBrera, Milano120 mq · 3 camere · 2 bagni · Terrazza
```

CTA principali:

```
Calcola mutuoStima ristrutturazionePrenota visita
```

CTA secondarie:

```
ChiamaWhatsAppEmailSalvaCondividi
```

---

## 8.5 Gallery fotografica

Contenuti:

```
Foto immobile fullscreenSwipe lateraleIndicator dotsPossibilità zoom
```

Dati necessari:

```
property_media- image_url- order_index- caption opzionale, non visibile nel primo MVP
```

---

## 8.6 Planimetria 2D

Schermata dedicata alla planimetria.

Contenuti:

```
Titolo: PlanimetriaImmagine planimetria grandeZoom / pinchDati rapidi:- superficie- locali- bagni- terrazzo
```

Importante:

```
La planimetria deve essere pulita.Non deve avere troppi colori.Non deve avere testi piccoli inutili.Non deve sembrare una scansione vecchia.
```

MVP:

```
Upload immagine planimetria da dashboardVisualizzazione zoomabile in iOS
```

Fase successiva:

```
Generazione planimetria ottimizzataPulizia grafica automatica
```

---

## 8.7 Floorplan 3D

Schermata dedicata alla vista 3D.

Deve essere elegante e chiara.

Contenuti:

```
Titolo: Vista 3DFloorplan 3D grandeNessuna caption dentro il floorplanColori chiariMateriali neutriPareti chiarePavimento legno chiaro / gres chiaroArredi minimiNessun colore saturo
```

Contenuti laterali o sotto:

```
95 mq3 locali2 bagniClasse A2
```

Azioni:

```
Ruota vistaZoomEsplora spazi
```

MVP reale:

```
Caricare immagine renderizzata 3D come asset statico
```

Fase 2:

```
Viewer 3D interattivoSupporto USDZ / GLB
```

Nota per coder:

```
Nel primo MVP non implementare vero rendering 3D realtime.Usare immagine statica ottimizzata.Preparare però il database per gestire asset 3D futuri.
```

---

## 8.8 Calcolo mutuo

Schermata form.

Campi:

```
Reddito mensile nettoSecondo reddito familiareAnticipo disponibileDurata mutuoAltri impegni mensiliEtàPrima casa sì/no
```

Output:

```
Rata stimataImporto mutuo indicativoIncidenza sul redditoLivello sostenibilità
```

Stati:

```
BuonaDa verificareCritica
```

Disclaimer:

```
La simulazione è indicativa e non costituisce approvazione bancaria.
```

Formula base MVP:

```
property_price = prezzo immobiledeposit = anticipo disponibileloan_amount = property_price - depositmonthly_rate = annual_interest_rate / 12number_of_payments = years * 12monthly_payment =loan_amount * monthly_rate * (1 + monthly_rate)^number_of_payments/((1 + monthly_rate)^number_of_payments - 1)income_ratio =monthly_payment / monthly_income
```

Soglie sostenibilità indicative:

```
<= 30% reddito netto: buona31% - 40%: da verificare> 40%: critica
```

Tasso mutuo:

```
Gestito da tabella adminDefault configurabileEsempio: 3.5%
```

---

## 8.9 Ristrutturazione — selezione lavori

Schermata chiave.

L’utente seleziona i lavori da includere.

Lista lavori MVP:

```
TinteggiaturePavimentiRifacimento bagnoSerramentiImpianto elettricoImpianto idraulicoCucinaClimatizzazionePorte interneDemolizioni leggere
```

Ogni item:

```
IconaNome interventoDescrizione breveCheckboxCosto stimato
```

Esempio:

```
TinteggiaturePareti e soffitti€ 2.300
```

---

## 8.10 Ristrutturazione — grafico costi

Schermata o sezione nella stessa schermata.

Contenuti:

```
Lista interventi selezionatiCosto per interventoGrafico a barre orizzontaliTotale indicativoRange di riferimento:- Essenziale- Medio- Premium
```

Esempio:

```
Rifacimento bagno     € 10.500Pavimenti             € 9.000Serramenti            € 7.500Impianto elettrico    € 4.700Tinteggiature         € 2.300Totale indicativo     € 34.000
```

Grafico:

```
Bar chart orizzontale semplice.No troppi colori.Solo verde salvia.No grafici complessi.No pie chart.
```

---

## 8.11 Prenota visita

Form semplice.

Campi:

```
Data visitaFascia orariaNome e cognomeTelefonoEmailNote
```

CTA:

```
Invia richiesta
```

Dopo invio:

```
Richiesta ricevuta.L’agenzia ti contatterà per confermare la visita.
```

Crea record in:

```
visit_requestsleads
```

---

## 8.12 Contatta agenzia

Schermata contatto.

Contenuti:

```
Nome agenziaLogo agenziaRecensione / rating opzionaleTelefonoWhatsAppEmailIndirizzoOrari ufficioMini mappa
```

Azioni:

```
ChiamaApri WhatsAppInvia EmailApri mappa
```

---

## 8.13 Preferiti

Contenuti:

```
Lista immobili salvatiFotoPrezzoTitoloZonaStatoBottoni:- Rivedi- Contatta- Confronta, fase 2
```

Salvataggio:

```
Se utente anonimo:- local storage / local persistenceSe utente autenticato:- tabella favorites
```

MVP:

```
Preferiti locali senza obbligo login
```

---

# 9\. Area Riservata Desktop Next.js

---

## 9.1 Login

Utenti agenzia:

```
Admin agenziaOperatore agenziaCommercialeSuper admin Arkai
```

Ruoli:

```
super_adminagency_adminagency_editoragency_viewer
```

---

## 9.2 Dashboard agenzia

Deve essere minimal, non piena di dati inutili.

KPI principali:

```
Immobili pubblicatiRichieste visitaLead ricevutiConversione
```

Grafici:

```
Andamento richieste visitaFunnel conversione
```

Liste:

```
Attività recentiTop immobili
```

Esempio dashboard:

```
57 immobili pubblicati38 richieste visita124 lead ricevuti3.2% conversione
```

Grafico principale:

```
Richieste visita ultimi 30 giorni
```

Funnel:

```
Lead ricevutiContatti qualificatiVisite effettuateProposte inviateConversione
```

Regola UI:

```
Pochi dati.Card grandi.Grafici leggibili.Tabelle solo dove servono.
```

---

## 9.3 Lista immobili

Tabella semplice.

Colonne:

```
FotoTitoloZonaPrezzoStatoVisualizzazioniLeadUltimo aggiornamentoAzioni
```

Stati:

```
BozzaOnlineRiservatoVendutoAffittatoArchiviato
```

Azioni:

```
ModificaAnteprimaDuplicaArchiviaElimina, solo admin
```

---

## 9.4 Inserimento immobile — Wizard

Il caricamento immobile deve essere guidato in step.

Step:

```
1. Dati immobile2. Media e planimetrie3. Dettagli tecnici4. Documenti5. Pubblicazione
```

---

## 9.5 Step 1 — Dati immobile

Campi:

```
TipologiaContrattoTitolo annuncioPrezzoComuneZonaIndirizzoMqCamereBagniClasse energeticaDescrizione breve
```

Layout:

```
Form a sinistraAnteprima card a destra
```

Mobile admin:

```
Form verticale ottimizzato
```

---

## 9.6 Step 2 — Media e planimetrie

Sezioni:

```
Galleria fotoPlanimetria 2DFloorplan 3D
```

Funzioni:

```
Upload immaginiDrag & dropRiordino galleryScelta foto coverUpload planimetriaUpload immagine floorplan 3D
```

Tipi file accettati:

```
JPGPNGWEBPPDF per planimetrie/documenti
```

Regole:

```
Foto cover obbligatoriaMassimo file configurabileCompressione lato client o serverThumbnail automatiche
```

---

## 9.7 Step 3 — Dettagli tecnici

Campi:

```
Superficie commercialeSuperficie calpestabileLocaliCamereBagniPianoNumero piani edificioAscensoreBalconeTerrazzaGiardinoBoxPosto autoCantinaAnno costruzioneStato immobileRiscaldamentoClimatizzazioneSpese condominialiClasse energeticaEPgl
```

---

## 9.8 Step 4 — Documenti

Documenti caricabili:

```
APEVisura catastalePlanimetria catastaleAtto di provenienzaRegolamento condominialeAltri documenti
```

Nota importante:

```
Non tutti i documenti devono essere pubblici.Ogni documento deve avere un flag di visibilità.
```

Visibilità:

```
Privato agenziaVisibile su richiestaPubblico
```

MVP:

```
I documenti restano privati nel gestionale.Nell’app pubblica si mostra solo “Documentazione disponibile su richiesta”.
```

---

## 9.9 Step 5 — Pubblicazione

Contenuti:

```
Stato annuncioAnteprima pubblicaCanali pubblicazione
```

Stati pubblicazione:

```
BozzaPronto per pubblicazioneOnlineRiservatoVendutoArchiviato
```

Canali MVP:

```
App Arkai DomusSito agenzia, se previsto
```

Canali fase 2:

```
Portali esterniSocialNewsletter
```

---

# 10\. Tabelle costi ristrutturazione

Modulo admin dedicato.

## Struttura

Ogni costo deve essere configurabile da dashboard.

Campi:

```
CategoriaNome interventoDescrizione breveUnità di misuraCosto baseCosto medioCosto premiumFormulaAttivo sì/noOrdinamento
```

Esempio:

```
Categoria: BagnoNome: Rifacimento bagnoUnità: cadaunoBase: € 6.000Medio: € 10.500Premium: € 18.000
```

---

## Metodo di calcolo MVP

Per ogni intervento:

```
if unit_type == "sqm":    cost = property_surface * unit_priceif unit_type == "unit":    cost = quantity * unit_priceif unit_type == "fixed":    cost = fixed_price
```

Ogni intervento può avere:

```
base_pricemedium_pricepremium_price
```

L’utente seleziona fascia:

```
EssenzialeMedioPremium
```

Oppure MVP ancora più semplice:

```
Usare sempre prezzo medio.Mostrare range sotto.
```

---

# 11\. Database Supabase

## Tabelle principali

```
agenciesagency_usersprofilespropertiesproperty_mediaproperty_floorplansproperty_3d_assetsproperty_documentsproperty_energyproperty_cadastralrenovation_categoriesrenovation_itemsrenovation_estimatesrenovation_estimate_itemsmortgage_estimatesleadsvisit_requestsfavoritesproperty_viewsapp_settingsagency_branding
```

---

## agencies

```
id uuid primary keyname textslug text uniquelogo_url textphone textemail textwhatsapp textaddress textcity textwebsite textcreated_at timestamptzupdated_at timestamptz
```

---

## agency\_users

```
id uuid primary keyagency_id uuid references agencies(id)user_id uuid references auth.users(id)role textcreated_at timestamptz
```

Roles:

```
agency_adminagency_editoragency_viewer
```

---

## properties

```
id uuid primary keyagency_id uuid references agencies(id)title textslug textdescription_short textdescription_long textproperty_type textcontract_type textprice numericcity textarea textaddress textaddress_public textlatitude numericlongitude numericsurface_commercial numericsurface_internal numericrooms intbedrooms intbathrooms intfloor texttotal_floors inthas_elevator booleanhas_balcony booleanhas_terrace booleanhas_garden booleanhas_garage booleanhas_parking booleanhas_cellar booleancondition_status textenergy_class textpublished_status textis_featured booleancreated_at timestamptzupdated_at timestamptz
```

---

## property\_media

```
id uuid primary keyproperty_id uuid references properties(id)agency_id uuid references agencies(id)file_url textfile_path textmedia_type textorder_index intis_cover booleancreated_at timestamptz
```

Media type:

```
photogallerycover
```

---

## property\_floorplans

```
id uuid primary keyproperty_id uuid references properties(id)agency_id uuid references agencies(id)file_url textfile_path texttype textcreated_at timestamptz
```

Types:

```
2d_planoptimized_planpdf_plan
```

---

## property\_3d\_assets

```
id uuid primary keyproperty_id uuid references properties(id)agency_id uuid references agencies(id)preview_image_url textasset_url textasset_type textcreated_at timestamptz
```

Asset type:

```
static_imageusdzglb
```

MVP:

```
static_image
```

---

## property\_documents

```
id uuid primary keyproperty_id uuid references properties(id)agency_id uuid references agencies(id)document_type textfile_url textfile_path textvisibility textcreated_at timestamptz
```

Visibility:

```
privateon_requestpublic
```

Document types:

```
apevisura_catastaleplanimetria_catastaleatto_provenienzaother
```

---

## renovation\_categories

```
id uuid primary keyagency_id uuid references agencies(id)name textdescription textorder_index intis_active booleancreated_at timestamptz
```

---

## renovation\_items

```
id uuid primary keycategory_id uuid references renovation_categories(id)agency_id uuid references agencies(id)name textdescription textunit_type textbase_price numericmedium_price numericpremium_price numericdefault_quantity numericis_active booleanorder_index intcreated_at timestamptzupdated_at timestamptz
```

Unit types:

```
sqmunitfixed
```

---

## renovation\_estimates

```
id uuid primary keyproperty_id uuid references properties(id)agency_id uuid references agencies(id)lead_id uuid references leads(id)quality_level texttotal_min numerictotal_medium numerictotal_premium numericselected_total numericcreated_at timestamptz
```

---

## renovation\_estimate\_items

```
id uuid primary keyestimate_id uuid references renovation_estimates(id)renovation_item_id uuid references renovation_items(id)name textquantity numericunit_type textunit_price numerictotal_price numericcreated_at timestamptz
```

---

## mortgage\_estimates

```
id uuid primary keyproperty_id uuid references properties(id)agency_id uuid references agencies(id)lead_id uuid references leads(id)monthly_income numericsecond_income numericavailable_deposit numericmortgage_years intexisting_monthly_debts numericinterest_rate numericestimated_loan_amount numericestimated_monthly_payment numericincome_ratio numericsustainability_status textcreated_at timestamptz
```

---

## leads

```
id uuid primary keyagency_id uuid references agencies(id)property_id uuid references properties(id)name textemail textphone textmessage textsource textstatus textcreated_at timestamptzupdated_at timestamptz
```

Source:

```
visit_requestmortgage_calculatorrenovation_estimatecontact_formwhatsapp_clickphone_click
```

Status:

```
newcontactedvisit_scheduledqualifiedlostconverted
```

---

## visit\_requests

```
id uuid primary keyagency_id uuid references agencies(id)property_id uuid references properties(id)lead_id uuid references leads(id)preferred_date datepreferred_time_slot textnotes textstatus textcreated_at timestamptz
```

Status:

```
newconfirmedrescheduledcancelledcompleted
```

---

## favorites

```
id uuid primary keyuser_id uuid references auth.users(id)property_id uuid references properties(id)created_at timestamptz
```

---

## property\_views

```
id uuid primary keyproperty_id uuid references properties(id)agency_id uuid references agencies(id)user_id uuid nullsession_id textsource textcreated_at timestamptz
```

---

## agency\_branding

```
id uuid primary keyagency_id uuid references agencies(id)primary_color textsecondary_color textlogo_url textapp_name textpayoff textcustom_domain textcreated_at timestamptzupdated_at timestamptz
```

---

# 12\. Storage Supabase

Bucket consigliati:

```
property-mediaproperty-floorplansproperty-3dproperty-documentsagency-branding
```

Struttura path:

```
/agencies/{agency_id}/properties/{property_id}/media//agencies/{agency_id}/properties/{property_id}/floorplans//agencies/{agency_id}/properties/{property_id}/3d//agencies/{agency_id}/properties/{property_id}/documents//agencies/{agency_id}/branding/
```

Regole:

```
Foto pubbliche solo per immobili pubblicati.Documenti privati non accessibili pubblicamente.Ogni agenzia vede solo i propri file.Super admin vede tutto.
```

---

# 13\. Row Level Security

Regola base:

```
Gli utenti agenzia possono leggere e modificare solo i dati della propria agency_id.Gli utenti pubblici possono leggere solo properties pubblicate.Gli utenti pubblici non possono leggere documenti privati.
```

Policy esempio concettuale:

```
Public app:read properties where published_status = 'online'Agency admin:read/write properties where agency_id belongs to current userSuper admin:read/write all
```

---

# 14\. API / Service Layer

## iOS deve avere servizi separati

```
PropertyServiceMediaServiceFavoriteServiceMortgageServiceRenovationServiceLeadServiceVisitRequestServiceAgencyService
```

---

## Next.js deve avere moduli separati

```
/lib/supabase/lib/auth/lib/validators/actions/properties/actions/media/actions/documents/actions/leads/actions/renovation/actions/dashboard
```

---

# 15\. Roadmap di sviluppo

---

## Fase 0 — Setup tecnico

Obiettivo: preparare base comune.

Attività:

```
Creare progetto SupabaseCreare schema databaseCreare bucket storageConfigurare RLSCreare utenti testCreare agenzia testCreare progetto iOS SwiftUICreare progetto Next.jsConfigurare environment variablesConfigurare design tokens
```

Output:

```
Backend funzionanteLogin agenzia funzionanteApp iOS collegata a SupabaseDashboard collegata a Supabase
```

---

## Fase 1 — Dashboard admin MVP

Obiettivo: permettere all’agenzia di inserire immobili.

Funzioni:

```
LoginDashboard minimalLista immobiliCrea immobileModifica immobileUpload fotoUpload planimetriaUpload immagine 3D staticaPubblica / bozza
```

Output:

```
L’agenzia può creare e pubblicare un immobile.
```

---

## Fase 2 — App iOS MVP

Obiettivo: mostrare immobili pubblicati.

Funzioni:

```
HomeLista immobiliFiltri baseScheda immobileGalleryPlanimetria 2DVista 3D staticaPreferiti localiContatta agenziaPrenota visita
```

Output:

```
Utente finale può consultare immobili e inviare richiesta.
```

---

## Fase 3 — Mutuo e ristrutturazione

Obiettivo: aggiungere funzioni intelligenti.

Funzioni:

```
Calcolo mutuoRisultato sostenibilitàSelezione lavoriGrafico costiTotale ristrutturazioneCreazione lead da simulazione
```

Output:

```
Utente può stimare acquisto e lavori.Agenzia riceve lead più qualificati.
```

---

## Fase 4 — Lead e dashboard analytics

Obiettivo: rendere utile la piattaforma all’agenzia.

Funzioni:

```
Lead ricevutiRichieste visitaStato leadNote leadTop immobiliVisite per immobileConversione
```

Output:

```
Agenzia può seguire i clienti interessati.
```

---

## Fase 5 — White label / personalizzazione

Obiettivo: rendere il prodotto vendibile a più agenzie.

Funzioni:

```
Logo agenziaColori agenziaNome app personalizzatoDominio sitoPowered by Arkai DomusImpostazioni contatto
```

Output:

```
Ogni agenzia può avere la propria identità.
```

---

# 16\. MVP finale consigliato

Il primo MVP vendibile deve includere:

## iOS

```
HomeLista immobiliScheda immobileGalleryPlanimetriaVista 3D staticaCalcolo mutuoRistrutturazionePrenota visitaContatta agenziaPreferiti
```

## Desktop

```
LoginDashboardLista immobiliInserimento immobileUpload fotoUpload planimetrieUpload 3D staticoGestione documenti privatiGestione costi ristrutturazioneLeadRichieste visita
```

## Backend

```
Supabase AuthPostgresStorageRLSCalcoli lato server o client validati
```

---

# 17\. Funzioni da NON fare nel primo MVP

Non implementare subito:

```
3D interattivo realtimeAI generativa planimetrieIntegrazione automatica portali immobiliariChat internaPush notifications complesseComparatore reale mutui bancariFirma documentiCRM completoMulti-agenzia marketplace pubblicoApp Android
```

Queste funzioni si possono aggiungere dopo.

---

# 18\. Priorità assolute per il coder

## Priorità 1

```
Database correttoSupabase RLS correttaUpload file stabileCRUD immobili funzionante
```

## Priorità 2

```
App iOS fluida e bellaScheda immobile leggibileFoto ottimizzatePlanimetria visibile bene
```

## Priorità 3

```
Calcolo mutuoCalcolo ristrutturazioneCreazione lead
```

## Priorità 4

```
Dashboard analyticsWhite-labelMiglioramenti UI
```

---

# 19\. Regole di qualità

Il coder deve rispettare queste regole:

```
Nessuna schermata sovraccarica.Nessuna tabella minuscola su iPhone.Nessun testo illeggibile.Nessuna dashboard piena di dati inutili.Ogni schermata deve avere un solo obiettivo principale.Ogni CTA deve essere chiara.Ogni form deve essere breve e guidato.Ogni errore upload deve essere gestito.Ogni immobile deve poter essere salvato come bozza.Nessun documento privato deve finire pubblico.
```

---

# 20\. Deliverable richiesti al coder

## Deliverable 1 — Supabase

```
Schema databaseRLS policiesStorage bucketsSeed data demoAgency demoProperties demoRenovation price table demo
```

---

## Deliverable 2 — Next.js Dashboard

```
LoginDashboardLista immobiliWizard inserimento immobileUpload mediaGestione documentiGestione costi ristrutturazioneLeadRichieste visitaImpostazioni agenzia
```

---

## Deliverable 3 — iOS App

```
SplashHomeLista immobiliScheda immobileGalleryPlanimetriaVista 3D staticaMutuoRistrutturazionePreferitiPrenota visitaContattiProfilo base
```

---

## Deliverable 4 — Testing

```
Test loginTest CRUD immobileTest upload fotoTest pubblicazione immobileTest lettura app iOSTest creazione leadTest richiesta visitaTest calcolo mutuoTest calcolo ristrutturazioneTest RLS tra agenzie diverse
```

---

# 21\. Sintesi prodotto

**Arkai Domus** deve essere una piattaforma immobiliare premium per agenzie, composta da:

```
App iOS pubblica+Area riservata desktop+Backend Supabase
```

Il valore principale è trasformare ogni immobile in una scheda intelligente, con:

```
fotoplanimetriafloorplan 3Ddati tecnicicalcolo mutuostima ristrutturazionelead qualificatiprenotazione visita
```

La dashboard dell’agenzia deve essere:

```
sempliceleggibilevelocenon sovraccarica
```

L’app iPhone deve essere:

```
eleganteitalianapremiummolto chiarafacile da usare
```

Il primo MVP deve essere concreto e vendibile, senza complicarsi con funzioni avanzate non necessarie.