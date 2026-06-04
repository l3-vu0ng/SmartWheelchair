# Design System: SmartWheel — Ocean Mist · Light · Liquid Glass

## 1. Visual Theme & Atmosphere

A luminous, breathable medical-tech interface bathed in warm natural light. The atmosphere evokes the clarity of a contemporary rehabilitation clinic — open windows, soft linen surfaces, and precise teal instrumentation. Density sits at 5 (Daily App Balanced), Variance at 6 (Offset Asymmetric), Motion at 5 (Fluid CSS). The defining visual technique is **Liquid Glass** (Apple-style glassmorphism): frosted translucent panels that reveal gentle color shifts beneath, creating layered depth without heavy shadows. Every surface feels like looking through a rain-washed window — clean, alive, trustworthy.

Light mode is primary. The teal accent conveys vitality, health, and calm confidence without clinical sterility.

## 2. Color Palette & Roles

### Canvas & Surfaces
- **Canvas Warm** (#FAFAF9) — Primary scaffold background. Warm off-white, never stark #FFFFFF.
- **Pure Surface** (#FFFFFF) — Opaque card fills when glass effect is not applied.
- **Glass Surface** (rgba(255,255,255,0.55)) — Glassmorphism card/container fill. Semi-transparent white with 12–20px backdrop-blur.
- **Glass Border** (rgba(255,255,255,0.65)) — 1px structural border on glass panels. Catches light.
- **Mist Overlay** (rgba(250,250,249,0.75)) — Frosted overlay for bottom nav, floating elements.

### Text
- **Charcoal Ink** (#18181B) — Primary text, headlines, values. Zinc-950 depth, never pure black.
- **Muted Steel** (#71717A) — Secondary text, descriptions, metadata, captions.
- **Text On Accent** (#FFFFFF) — Text on teal-filled surfaces (buttons, hero gradient variant).

### Accent (Single — Teal Signal)
- **Teal Signal** (#14B8A6) — The singular accent. CTAs, active states, focus rings, connection-online indicators. Saturation ~72%.
- **Teal Deep** (#0D9488) — Darker teal for gradient endpoints, pressed states.
- **Teal Whisper** (rgba(20,184,166,0.08)) — Tinted background for selected states, icon containers, badge highlights on light surfaces.
- **Teal Glow** (rgba(20,184,166,0.15)) — Subtle shadow tint for active glass elements.

### Semantic Status
- **Vital Emerald** (#10B981) — Positive: connected, heart rate stable, system normal.
- **Alert Amber** (#F59E0B) — Warning: low battery, abnormal speed detection.
- **Danger Coral** (#EF4444) — Critical: fall detection, emergency call, disconnect.

### Borders & Dividers
- **Whisper Border** (rgba(0,0,0,0.06)) — Standard card borders on non-glass cards, dividers.
- **Frost Line** (rgba(255,255,255,0.5)) — Inner highlight lines on glass surfaces (top/left edge).

> No purple. No neon. No outer glows. No oversaturated gradients. Single teal accent at saturation ~72%. The palette communicates calm medical trust.

## 3. Typography Rules

- **Display/Headlines:** Outfit — Track-tight (-0.025em), weight-driven hierarchy (700 for primary, 600 for secondary). Controlled scale: 28px max for mobile. Hierarchy through weight and color, not screaming sizes.
- **Body:** Outfit — Relaxed leading (1.6), max 65 characters per line. 15px standard body, 13px for captions and metadata. Muted Steel (#71717A) for descriptions.
- **Mono:** JetBrains Mono — For sensor values, speed readings, battery percentages, coordinates, and all numerical data. Ensures tabular alignment and scanability in data-heavy contexts.
- **Banned:** Inter (too generic for premium contexts per directive). No generic serif fonts (Times, Georgia, Garamond). No system defaults.

## 4. Component Stylings

### Buttons
- **Primary:** Flat Teal Signal (#14B8A6) fill, white text, pill-shaped (border-radius: 100px). Tactile -1px translateY on active. No outer glow. Min 44px touch target.
- **Secondary/Ghost:** Transparent fill, teal text, 1px teal border. Used for secondary actions.
- **Danger:** Flat Danger Coral fill for emergency actions.

### Cards — Standard
- Pure Surface (#FFFFFF) fill with Whisper Border (1px). Generous rounded corners (16px). Subtle diffused shadow: `0 2px 12px rgba(0,0,0,0.04)`.
- Used ONLY when elevation communicates hierarchy. For high-density data sections, prefer border-top dividers or negative space.

### Cards — Liquid Glass (Applied to: Hero Card, Connection Status, Bottom Nav, Dialogs)
- Glass Surface (rgba(255,255,255,0.55)) fill.
- Backdrop blur: `blur(16px) saturate(1.5)`.
- Glass Border: 1px rgba(255,255,255,0.65) — catches light.
- Frost Line: Optional inner 1px highlight on top/left edge.
- Shadow: `0 4px 24px rgba(0,0,0,0.06)` — diffused, never harsh.
- Background requirement: Glass cards must sit above a colored or gradient surface to show the frosted effect (e.g., Canvas Warm + subtle gradient mesh or hero zone).

### Hero Card (Dashboard — Liquid Glass variant)
- Glass Surface fill over a gentle teal-tinted background zone.
- Content uses Charcoal Ink for labels, Teal Signal for accent values.
- Speed and battery displayed as large mono figures.
- Two chip badges at bottom with Teal Whisper fill.
- No opaque gradient. The glass effect IS the visual distinction.

### Inputs/Forms
- Label positioned above input, never floating.
- Fill: Canvas Warm (#FAFAF9). Focus ring: 2px Teal Signal.
- Error text below in Danger Coral. Helper text in Muted Steel.
- Border: 1px Whisper Border, rounding 12px.

### Navigation Bar — Floating Pill Glass
- Position: Floating above content, 24px margin from screen edges.
- Fill: Mist Overlay (rgba(250,250,249,0.75)) with backdrop blur(16px).
- Shape: Pill (border-radius: 20px).
- Glass Border: 1px rgba(255,255,255,0.65).
- Shadow: `0 4px 20px rgba(0,0,0,0.06)`.
- Selected item: Teal Signal background pill with white icon/text.
- Unselected: Muted Steel icons + labels.
- 5 items: Trang chủ, Điều khiển, Sức khỏe, Điều hướng, Cài đặt.

### D-Pad Controls
- Circular buttons with Canvas Warm fill and Whisper Border.
- Active state: Teal Whisper fill, Teal Signal border (2px), subtle Teal Glow shadow.
- Central stop button: Danger Coral fill when stopped, muted when moving.
- Size: 64px buttons.

### Status Banners
- Full-width horizontal bars with Teal Whisper (8% tint) or status-color tinted backgrounds.
- Left dot indicator (8px circle) + descriptive text.
- 1px border in matching status color at 20% opacity.

### Loaders
- Skeletal shimmer matching exact layout dimensions. Shimmer transitions between Canvas Warm and Pure Surface. No circular spinners.

### Empty States
- Composed icon + text compositions. Instructive copy explaining how to connect or populate data.

### Dialogs / Bottom Sheets — Liquid Glass
- Glass Surface fill with rounded top corners (20px).
- Backdrop blur(20px).
- Frosted handle bar (40px × 4px, Whisper Border color).
- Clean list of options with icon + label + chevron.

## 5. Layout Principles

- Grid-first responsive architecture. CSS Grid for card arrangements.
- Asymmetric splits for Hero section: speed left-aligned, battery right-aligned.
- Single-column layout on mobile with 24px horizontal padding.
- Max-width containment at 428px for mobile screens.
- Bottom nav floats 24px from screen edges.
- Content scrolls freely beneath header and above floating nav.
- Section spacing: consistent 16px / 24px rhythm. No arbitrary gaps.
- No overlapping elements. Every component has its own clear spatial zone.
- 3-column equal card grid is banned. Stat cards use 2-column layout.
- Glass cards require a visually interesting zone behind them — use a subtle teal→white gradient mesh or colored illustration behind the Hero area to give the glass something to frost over.

## 6. Responsive Rules

- **Mobile-First Collapse (< 768px):** All multi-column layouts collapse to single column.
- **No Horizontal Scroll:** Overflow on mobile is a critical failure.
- **Typography Scaling:** Headlines via clamp(). Body min 14px.
- **Touch Targets:** All interactive elements minimum 44px.
- **Navigation:** Floating pill nav collapses gracefully.
- **Spacing:** Vertical gaps reduce proportionally.

## 7. Motion & Interaction

- **Spring Physics:** All transitions use Curves.easeOutQuart, 300ms duration. Premium, weighty feel. No linear easing.
- **Micro-Interactions:** Connection status pill pulsates gently when connecting. D-pad buttons scale 98% on press. Nav items smooth color/background transitions (200ms).
- **Staggered Reveals:** Dashboard loads with Hero card first, stat cards cascade 100ms apart, quick access items waterfall 50ms intervals.
- **Glass Shimmer:** Glass surfaces have a subtle specular highlight that shifts with scroll position — the glass feels alive.
- **Hardware-Accelerated Only:** Animate exclusively via transform (scale, translate) and opacity. Never animate width, height, top, left.
- **Haptic Feedback:** D-pad presses → light impact. Stop → medium. Emergency → heavy.

## 8. Anti-Patterns (Banned)

- No emojis anywhere (remove the "👋" greeting)
- No Inter font
- No generic serif fonts (Times New Roman, Georgia, Garamond)
- No pure black (#000000) — use Charcoal Ink (#18181B)
- No neon glow shadows or outer glow effects
- No oversaturated accents (saturation < 80%)
- No excessive gradient text on large headers
- No custom mouse cursors
- No overlapping elements — clean spatial separation always
- No 3-column equal card layouts
- No generic placeholder names ("John Doe", "Acme")
- No fake round numbers (99.99%, 50%)
- No AI copywriting clichés ("Elevate", "Seamless", "Unleash")
- No filler UI text: "Scroll to explore", scroll arrows, bouncing chevrons
- No broken Unsplash links — use picsum.photos or SVG avatars
- No centered hero sections — force left-aligned or asymmetric layouts
- No CircularProgressIndicator for loading — use skeletal shimmers
- No heavy drop shadows on glass surfaces — keep shadows diffused and subtle
- No opaque cards on top of gradient hero zones — glass cards only in those areas
