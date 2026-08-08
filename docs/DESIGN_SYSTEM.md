# DESIGN SYSTEM — CHUST ONE ACADEMY

## 1. Color Palette

### Brand Colors
- `primaryLime`: `#D7FF00` (Vibrant Lime Accent)
- `primaryLimeDark`: `#B9DD00` (Lime Hover/Pressed State)
- `navy900`: `#041426` (Deep Dark Navy Main Background)
- `navy800`: `#082039` (Navy Card & Container Background)
- `navy700`: `#10304F` (Elevated Card Surface)
- `navy600`: `#194164` (Border & Divider Dark)

### Light Theme Surfaces
- `backgroundLight`: `#F5F7FA` (Clean Light Grayish Blue Background)
- `surfaceLight`: `#FFFFFF` (Pure White Card Container)
- `borderLight`: `#E7EAF0` (Soft Light Divider Border)

### Typography Colors
- `textPrimaryLight`: `#071426` (Dark Navy Text on Light Surface)
- `textSecondaryLight`: `#667085` (Muted Secondary Text on Light Surface)
- `textPrimaryDark`: `#FFFFFF` (White Text on Dark Navy Surface)
- `textSecondaryDark`: `#B2C0CE` (Soft Ice Blue Secondary Text on Dark Surface)

### Status Indicators
- `success`: `#16C784` (Emerald Green)
- `warning`: `#F9A826` (Amber Yellow)
- `error`: `#FF4D67` (Coral Red)
- `info`: `#3E8BFF` (Electric Blue)

---

## 2. Typography
Font Family: **Inter** / **Manrope** (Google Fonts)

| Token | Size | Weight | Line Height |
|---|---|---|---|
| Display Large | 32px | Bold (700) | 40px |
| Display Medium | 28px | Bold (700) | 36px |
| Headline Large | 24px | SemiBold (600) | 32px |
| Headline Medium | 20px | SemiBold (600) | 28px |
| Title Large | 18px | SemiBold (600) | 24px |
| Title Medium | 16px | Medium (500) | 22px |
| Body Large | 16px | Regular (400) | 24px |
| Body Medium | 14px | Regular (400) | 20px |
| Body Small | 12px | Regular (400) | 16px |
| Label Large | 14px | SemiBold (600) | 18px |
| Label Medium | 12px | Medium (500) | 16px |

---

## 3. Border Radius System
- `small`: 10px (Badges, Chips, Small inputs)
- `medium`: 16px (Cards, Dialogs, Input fields)
- `large`: 22px (Hero Cards, Banners, Bottom Sheets)
- `extraLarge`: 28px (Modal containers, Large promo cards)
- `pill`: 999px (Circular Buttons, Floating Tags)

---

## 4. Spacing System (4px Grid)
`4px`, `8px`, `12px`, `16px`, `20px`, `24px`, `28px`, `32px`, `40px`, `48px`, `64px`

---

## 5. UI Component Specifications

### Primary CTA Button
- Background: `primaryLime` (`#D7FF00`)
- Text: `navy900` (`#041426`), Bold, 16px
- Height: 54px
- Radius: `medium` (16px) or `pill` (999px)
- Icon: Right arrow icon
- Interaction: Scale 0.98 on press, soft glow effect

### Course Card
- Dark Mode: Surface `navy800` (`#082039`) with `borderDark` (`#23415D`) 1px border.
- Light Mode: Surface `surfaceLight` (`#FFFFFF`) with subtle soft shadow `rgba(0,0,0,0.06)`.
- Icon Box: 56x56px rounded container with dark or light backdrop.
- Content: Course title, lesson count, price tag, discount badge, arrow navigation icon.
