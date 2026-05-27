# ARKAI DOMUS — Brand Identity & UI Color System

## 1. Brand Overview

**Arkai Domus** is a premium real estate intelligence platform for modern agencies.

The product includes:

- iOS public app for property browsing
- Desktop reserved area for agencies
- Property listing management
- Mortgage simulation
- Renovation cost estimation
- 2D floorplans and elegant 3D floorplan previews
- Lead and visit request management
- White-label configuration for agencies

The visual identity must communicate:

- Italian elegance
- architectural clarity
- trust
- calm premium design
- simplicity
- real estate professionalism
- high readability
- warm minimalism

The product must not look like:

- a generic SaaS dashboard
- a cheap real estate portal
- an overloaded admin system
- a tech demo
- a colorful consumer app
- a fake luxury interface

---

## 2. Brand Name

### Main Product Name

**Arkai Domus**

### Suggested Payoff

**La nuova esperienza immobiliare intelligente**

### Alternative Payoff

**Piattaforma immobiliare intelligente per agenzie moderne**

### White-label Usage

For agency-branded apps:

```text
Studio Casa Milano
powered by Arkai Domus
```

or:

```text
Rossi Immobiliare
powered by Arkai Domus
```

Arkai Domus should remain visible as the technology platform, while the agency brand can be presented as the client-facing identity.

---

## 3. Brand Personality

Arkai Domus should feel:

```text
premium
Italian
architectural
calm
elegant
precise
professional
warm
intelligent
minimal
trustworthy
```

It should avoid:

```text
loud colors
heavy gradients
neon effects
overloaded dashboards
tiny unreadable tables
generic startup style
fake luxury gold
overdecorated UI
excessive icons
```

---

## 4. Core Visual Direction

The UI must follow a **warm architectural editorial style**.

Reference mood:

- Italian architecture magazine
- premium real estate dossier
- boutique agency presentation
- clean iOS app
- soft beige workspace
- sage green accents
- large cards
- readable data
- refined typography
- restrained iconography

The interface should always privilege:

1. clarity
2. legibility
3. breathing space
4. hierarchy
5. realistic UI proportions
6. functional elegance

---

## 5. Primary Color Palette

### Background Warm Ivory

```css
--color-background: #F7F4ED;
```

Use for:

- main page background
- presentation boards
- large empty areas
- soft neutral surfaces

Role:

```text
Main warm background.
Creates calm, premium and architectural feeling.
```

---

### Surface White

```css
--color-surface: #FFFFFF;
```

Use for:

- cards
- forms
- panels
- modal surfaces
- input containers
- dashboard widgets

Role:

```text
Clean content surface.
Keeps interface readable and professional.
```

---

### Soft Beige Surface

```css
--color-surface-soft: #F1EDE4;
```

Use for:

- secondary cards
- inactive states
- subtle background panels
- form sections
- pricing cards
- floorplan data cards

Role:

```text
Adds warmth without reducing readability.
```

---

### Deep Green

```css
--color-primary: #243526;
```

Use for:

- main titles
- dark sidebar
- main navigation
- primary brand text
- important headers
- strong UI accents

Role:

```text
Main brand color.
Elegant, architectural, serious and premium.
```

---

### Sage Green

```css
--color-primary-soft: #556B45;
```

Use for:

- primary buttons
- selected states
- active icons
- progress steps
- charts
- toggles
- badges

Role:

```text
Main interactive color.
Calm and premium, not aggressive.
```

---

### Light Sage

```css
--color-primary-light: #DDE5D3;
```

Use for:

- selected light backgrounds
- active tab backgrounds
- subtle highlight areas
- chart backgrounds
- pill filters

Role:

```text
Soft confirmation and selection color.
```

---

### Warm Border

```css
--color-border: #D8D2C4;
```

Use for:

- card borders
- input borders
- dividers
- tables
- dashboard grid lines

Role:

```text
Subtle warm separator.
Never use hard grey borders.
```

---

### Graphite Text

```css
--color-text: #1E1E1E;
```

Use for:

- main body text
- form labels
- data values
- table text

Role:

```text
Primary readable text.
```

---

### Muted Text

```css
--color-text-muted: #6E6A61;
```

Use for:

- helper text
- secondary descriptions
- captions
- metadata
- placeholder labels

Role:

```text
Secondary information.
```

---

### Warm Accent

```css
--color-accent-warm: #A48768;
```

Use sparingly for:

- special highlights
- premium notes
- elegant accent lines
- secondary visual warmth

Role:

```text
Warm architectural accent.
Use rarely.
```

---

### Error / Warning Soft Terracotta

```css
--color-warning: #B8795D;
```

Use for:

- warnings
- validation messages
- attention labels
- non-critical alerts

Role:

```text
Human and warm warning color.
Avoid bright red unless absolutely necessary.
```

---

## 6. Complete CSS Variables

```css
:root {
  --color-background: #F7F4ED;
  --color-surface: #FFFFFF;
  --color-surface-soft: #F1EDE4;

  --color-primary: #243526;
  --color-primary-soft: #556B45;
  --color-primary-light: #DDE5D3;

  --color-border: #D8D2C4;

  --color-text: #1E1E1E;
  --color-text-muted: #6E6A61;
  --color-text-light: #8C867A;

  --color-accent-warm: #A48768;
  --color-warning: #B8795D;
  --color-success: #556B45;

  --radius-sm: 8px;
  --radius-md: 14px;
  --radius-lg: 20px;
  --radius-xl: 28px;

  --shadow-card: 0 12px 30px rgba(36, 53, 38, 0.08);
  --shadow-soft: 0 8px 20px rgba(36, 53, 38, 0.06);
}
```

---

## 7. Color Usage Rules

### Primary Buttons

```css
background: #556B45;
color: #FFFFFF;
border-radius: 14px;
```

Hover:

```css
background: #243526;
```

Disabled:

```css
background: #D8D2C4;
color: #8C867A;
```

---

### Secondary Buttons

```css
background: #FFFFFF;
color: #243526;
border: 1px solid #D8D2C4;
```

Hover:

```css
background: #F1EDE4;
border-color: #556B45;
```

---

### Selected State

```css
background: #DDE5D3;
color: #243526;
border-color: #556B45;
```

---

### Sidebar

Desktop dashboard sidebar:

```css
background: #243526;
color: #FFFFFF;
```

Active navigation item:

```css
background: rgba(255, 255, 255, 0.12);
color: #FFFFFF;
```

Inactive navigation item:

```css
color: rgba(255, 255, 255, 0.72);
```

---

### Charts

Use a very restrained chart palette.

Primary chart color:

```css
#556B45
```

Secondary chart fill:

```css
#DDE5D3
```

Grid lines:

```css
#E6E1D7
```

Text:

```css
#6E6A61
```

Do not use multiple saturated colors.

Avoid:

```text
red
blue
purple
orange
neon green
rainbow charts
```

Charts must feel like architectural diagrams, not financial trading screens.

---

## 8. Typography System

### Brand / Editorial Titles

Recommended font:

```text
Cormorant Garamond
```

or:

```text
Playfair Display
```

Use for:

- presentation titles
- large marketing headings
- board titles
- premium section titles

Style:

```css
font-family: "Cormorant Garamond", serif;
font-weight: 400;
letter-spacing: -0.02em;
color: #243526;
```

---

### UI Font

Recommended font:

```text
Inter
```

Alternative:

```text
Helvetica Neue
System Font
SF Pro
```

Use for:

- dashboard UI
- forms
- tables
- app text
- buttons
- labels
- data

Style:

```css
font-family: "Inter", system-ui, sans-serif;
color: #1E1E1E;
```

---

## 9. Typography Scale — Desktop

```css
--text-display: 64px;
--text-h1: 48px;
--text-h2: 36px;
--text-h3: 28px;
--text-h4: 22px;
--text-body-lg: 18px;
--text-body: 16px;
--text-small: 14px;
--text-xs: 12px;
```

Usage:

```text
Display: presentation page title
H1: dashboard page title
H2: section title
H3: card title
Body: normal content
Small: helper text
XS: metadata only
```

---

## 10. Typography Scale — iOS

Use native Dynamic Type where possible.

Suggested approximate sizes:

```text
Large title: 34 pt
Page title: 28 pt
Section title: 22 pt
Card title: 18 pt
Body: 16 pt
Small body: 14 pt
Metadata: 12 pt minimum
```

Rules:

```text
Never use text below 12 pt.
Never compress important data.
Use fewer data points rather than smaller text.
```

---

## 11. Spacing System

Use an 8-point spacing system.

```css
--space-1: 4px;
--space-2: 8px;
--space-3: 12px;
--space-4: 16px;
--space-5: 24px;
--space-6: 32px;
--space-7: 40px;
--space-8: 48px;
--space-9: 64px;
```

Recommended component spacing:

```text
Small card internal padding: 16px
Large card internal padding: 24px
Dashboard section gap: 24px to 32px
Page margin desktop: 32px to 48px
iOS horizontal padding: 16px to 20px
```

---

## 12. Border Radius

```css
--radius-input: 12px;
--radius-card: 20px;
--radius-panel: 24px;
--radius-large: 28px;
```

Rules:

```text
Cards should feel soft but not playful.
Avoid fully round large cards.
Use circular radius only for icons and avatars.
```

---

## 13. Shadows

Use soft shadows only.

```css
.card {
  box-shadow: 0 12px 30px rgba(36, 53, 38, 0.08);
}
```

Light shadow:

```css
box-shadow: 0 8px 20px rgba(36, 53, 38, 0.06);
```

Avoid:

```text
black heavy shadows
floating glassmorphism
strong neumorphism
bright glow
```

---

## 14. Icon Style

Use:

```text
thin line icons
rounded stroke
minimal architectural style
```

Recommended:

```text
Lucide Icons
SF Symbols for iOS
```

Stroke:

```css
stroke-width: 1.5px;
```

Icon colors:

```css
default: #556B45;
muted: #8C867A;
active: #243526;
```

Rules:

```text
Icons must support meaning, not decorate.
Do not overuse icons.
Do not mix filled and outline icon styles.
```

---

## 15. iOS App UI Rules

### General

The iOS app must be:

```text
clean
realistic
readable
premium
not overcrowded
```

Every screen should have one primary goal.

---

### iOS Background

```swift
Color(hex: "#F7F4ED")
```

Main cards:

```swift
Color.white
```

Soft cards:

```swift
Color(hex: "#F1EDE4")
```

Primary CTA:

```swift
Color(hex: "#556B45")
```

---

### iOS Button Style

Primary button:

```text
Height: 50 pt
Radius: 14 pt
Background: #556B45
Text: white
Font: 16 pt semibold
```

Secondary button:

```text
Height: 48 pt
Radius: 14 pt
Background: white
Border: #D8D2C4
Text: #243526
```

---

### iOS Property Card

Property card structure:

```text
Image
Badge
Favorite icon
Price
Title
Zone
Metadata row
```

Minimum height:

```text
260–320 pt depending on image ratio
```

Image ratio:

```text
16:10 or 4:3
```

Do not use:

```text
tiny property cards
too much metadata
more than 4 visible specs per card
```

---

### iOS Property Detail

Top hierarchy:

```text
Hero image
Price
Title
Zone
Main specs
CTA row
Content sections
```

Main specs:

```text
mq
locali
bagni
terrazza / giardino / box
```

Only show the most important data first.

---

### iOS Forms

Rules:

```text
One column only.
Large fields.
Clear labels.
Enough vertical spacing.
No dense table layout.
```

Field height:

```text
48–54 pt
```

Field radius:

```text
12–14 pt
```

Field border:

```text
#D8D2C4
```

---

## 16. Desktop Dashboard UI Rules

The dashboard must be:

```text
minimal
spacious
readable
useful
agency-oriented
```

It must not show too much data at once.

---

### Dashboard Layout

Recommended:

```text
Left sidebar
Top header
Main KPI cards
One large chart
One funnel / summary chart
Recent activity
Top properties
```

Do not include:

```text
too many small tables
too many charts
more than 4 KPI cards in the first row
small unreadable numbers
dense admin panels
```

---

### Dashboard KPI Cards

Each KPI card should include:

```text
Label
Large number
Small trend
Minimal icon
```

Example:

```text
Immobili pubblicati
57
+12% vs periodo precedente
```

Card style:

```css
background: #FFFFFF;
border: 1px solid #D8D2C4;
border-radius: 20px;
padding: 24px;
```

Number style:

```css
font-size: 32px;
font-weight: 500;
color: #243526;
```

---

### Dashboard Charts

Use:

```text
large line chart
horizontal bar chart
simple funnel
```

Avoid:

```text
pie charts
3D charts
rainbow charts
tiny legends
overloaded financial dashboards
```

---

### Dashboard Sidebar

Sidebar width:

```css
width: 260px;
```

Background:

```css
#243526
```

Navigation items:

```text
Dashboard
Immobili
Richieste visita
Lead
Clienti
Report
Impostazioni
```

---

## 17. Floorplan 3D Visual Rules

The 3D floorplan must be:

```text
light
elegant
architectural
realistic
minimal
warm
without captions inside the floorplan
without colored labels
without numbered markers
```

Use:

```text
light walls
soft beige floors
natural wood
white / ivory furniture
minimal greenery
neutral shadows
soft daylight
```

Avoid:

```text
colored rooms
text inside rooms
icons on rooms
numbered pins
bright furniture colors
oversaturated materials
cartoon style
CGI plastic look
```

The floorplan UI can show data outside the image:

```text
95 mq
3 locali
2 bagni
Classe A2
```

But the floorplan image itself must remain clean.

---

## 18. Renovation Cost UI Rules

The renovation screen must show:

```text
selectable works
cost summary
horizontal bar chart
total estimate
range: essential / medium / premium
```

Use only:

```text
green sage bars
light beige background
black / green text
```

Do not use:

```text
pie charts
complex tables
many colors
small numbers
technical estimating language
```

Recommended renovation categories:

```text
Tinteggiature
Pavimenti
Rifacimento bagno
Serramenti
Impianto elettrico
Cucina
```

Chart style:

```text
horizontal bars
one color only
percentage optional
large readable values
```

---

## 19. Property Listing UI Rules

Property cards must be elegant and image-led.

Card data:

```text
Price
Title
Zone
Surface
Rooms
Bathrooms
One extra feature
```

Example:

```text
€ 780.000
Attico in Brera
Brera, Milano
120 mq · 3 locali · 2 bagni · Terrazza
```

Do not show:

```text
catastal data
full address
long descriptions
too many badges
technical fields
```

---

## 20. Property Detail UI Rules

Property detail must feel like a premium dossier.

Recommended sections:

```text
Hero image
Main details
Description
Gallery
Planimetria
Vista 3D
Dati tecnici
Calcola mutuo
Stima ristrutturazione
Contatta agenzia
Prenota visita
```

Each section must be visually separated.

Use:

```text
large section titles
cards
icons only when useful
short blocks of text
```

---

## 21. Admin Property Insert Wizard

Wizard steps:

```text
1. Dati immobile
2. Media e planimetrie
3. Dettagli tecnici
4. Documenti
5. Pubblicazione
```

Visual rule:

```text
Only one main task per screen.
Do not display all fields at once.
Show a clean preview on the side.
```

Step 1 must show:

```text
Tipologia
Contratto
Titolo
Prezzo
Comune
Zona
Indirizzo
Mq
Camere
Bagni
Classe energetica
Preview card
```

Step 2 must show:

```text
Gallery photos
2D floorplan
3D floorplan preview
Documents summary
```

---

## 22. White-label Branding Rules

Agency brand can customize:

```text
logo
agency name
primary accent color
contact details
website
app title
domain
```

Arkai Domus must remain visible as:

```text
powered by Arkai Domus
```

Recommended placement:

```text
footer
settings page
splash small line
admin login page
```

Avoid making Arkai Domus too dominant in white-label customer-facing screens.

---

## 23. Presentation Board Rules

For A4 horizontal client boards:

```text
Use realistic device proportions.
Do not make iPhone or tablet oversized.
Use readable UI.
Use large titles.
Do not fill screens with meaningless text.
Use fewer elements but meaningful ones.
Keep light colors.
Keep floorplans clean.
No captions inside 3D floorplans.
```

Each board should communicate one concept only.

Examples:

```text
Scheda 1: Search and property detail
Scheda 2: Mortgage and renovation estimate
Scheda 3: Contact and visit request
Scheda 4: Agency reserved dashboard
Scheda 5A: Property data insert
Scheda 5B: Media and publishing
Scheda 6: White-label brand system
Scheda 7: 3D floorplan
Scheda 8: Renovation cost selection
```

---

## 24. Accessibility Rules

Minimum contrast must be respected.

Do not rely only on color for:

```text
status
errors
selection
charts
```

Use also:

```text
labels
icons
clear text
spacing
```

Minimum touch target:

```text
44 x 44 pt on iOS
```

Recommended button height:

```text
48–54 pt
```

---

## 25. Responsive Rules

### Desktop

```text
Max content width: 1440px
Sidebar fixed
Cards responsive grid
Charts large and readable
```

### Tablet

```text
Sidebar can collapse
Two-column layout becomes one-column where needed
```

### iPhone

```text
One-column layout only
No tables
No dense chart legends
Use cards and vertical sections
```

---

## 26. Do / Don’t Summary

### Do

```text
Use warm light backgrounds.
Use large readable cards.
Use sage green for actions and selections.
Use deep green for brand hierarchy.
Use simple charts.
Use realistic device proportions.
Keep UI calm and premium.
Show only meaningful data.
```

### Don’t

```text
Do not overload screens.
Do not create tiny dashboards.
Do not use fake dense text.
Do not use too many colors.
Do not place captions inside floorplans.
Do not use cartoon 3D.
Do not make devices unrealistic.
Do not use generic SaaS blue.
Do not use neon effects.
```

---

## 27. Final UI Principle

Every Arkai Domus screen must answer one clear question:

```text
What does the user need to understand or do here?
```

If a screen does not answer that clearly, it must be simplified.

The product should feel like:

```text
a premium real estate dossier
+
a modern agency dashboard
+
an elegant Italian architectural interface
```

Not like:

```text
a crowded property portal
or
a generic admin template
```
