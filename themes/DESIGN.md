# Theme Engine Homepage Design System

## 1. Atmosphere & Identity

A matte, quiet desktop command center that lets the wallpaper breathe. Its signature is a single raised media surface centered between two low-contrast information rails; lavender, blue, and pink only mark attention, selection, and state.

## 2. Color

The homepage uses only the generated semantic roles: `bg` (canvas), `bg_alt` (recessed surface), `text`, `text_dim`, `accent` (lavender), `accent2` (blue), and `border_normal`. Status colours are derived from these roles; an error state uses the theme's existing destructive red when available.

## 3. Typography

Use the existing sans stack for display and body, and `JetBrainsMono Nerd Font` for data, icons, and compact labels. Display clock: 46px/800; hero title: 22px/800; card title: 13px/700; metadata: 11–13px/500, with tabular figures for metrics.

## 4. Spacing & Layout

Base unit: 4px. Cards use 12–18px internal padding; rail groups use 12px gaps; the responsive shell reserves 5vw outer padding. The desktop shell is a 340px rail, flexible 650–900px center, and 360px rail. At constrained widths, rails tighten and lower-priority right content disappears before overlap.

## 5. Components

### Card
- **Structure**: matte raised surface with semantic border.
- **Variants**: standard, hero, active/privacy, empty.
- **States**: default, hover lift, focused accent edge, empty/error content.

### Icon button and status pill
- **States**: default, hover brighten, pressed, disabled; status uses accent or dim role.

### Progress meter
- **States**: known progress, unavailable duration, paused; it never implies seekability when duration is absent.

### Dock
- **Structure**: compact wrapped action cluster centered at the bottom; unavailable actions are dimmed.

## 6. Motion & Interaction

Micro interactions use 150ms ease-out; cards and media art use a 200ms ease-in-out transform/opacity transition. Dock behavior is adapted from the beui dock pattern: a compact grouped action rail with a coherent active surface, without importing a new runtime. Reduced-motion users receive static state changes.

## 7. Depth & Surface

Mixed tonal-shift and a single tinted shadow: wallpaper/tint is background, cards are translucent generated `bg`, and the hero uses a slightly stronger border and shadow. No glossy blur layers.

## 8. Accessibility Constraints & Accepted Debt

Maintain readable generated-role contrast, tooltips for icon controls, visible button hover/focus states, and reduced motion. Eww 0.5 accessibility is constrained by GTK widget semantics; no additional accepted debt.
