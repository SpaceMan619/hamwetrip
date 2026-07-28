---
name: Equatorial Hearth
colors:
  surface: '#fcf9f8'
  surface-dim: '#dcd9d9'
  surface-bright: '#fcf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f2'
  surface-container: '#f0eded'
  surface-container-high: '#eae7e7'
  surface-container-highest: '#e4e2e1'
  on-surface: '#1b1c1c'
  on-surface-variant: '#42493e'
  inverse-surface: '#303030'
  inverse-on-surface: '#f3f0f0'
  outline: '#72796e'
  outline-variant: '#c2c9bb'
  surface-tint: '#3b6934'
  primary: '#154212'
  on-primary: '#ffffff'
  primary-container: '#2d5a27'
  on-primary-container: '#9dd090'
  inverse-primary: '#a1d494'
  secondary: '#944a00'
  on-secondary: '#ffffff'
  secondary-container: '#fc8f34'
  on-secondary-container: '#663100'
  tertiary: '#685e3e'
  on-tertiary: '#ffffff'
  tertiary-container: '#b7aa86'
  on-tertiary-container: '#483f22'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#bcf0ae'
  primary-fixed-dim: '#a1d494'
  on-primary-fixed: '#002201'
  on-primary-fixed-variant: '#23501e'
  secondary-fixed: '#ffdcc5'
  secondary-fixed-dim: '#ffb783'
  on-secondary-fixed: '#301400'
  on-secondary-fixed-variant: '#713700'
  tertiary-fixed: '#f0e2ba'
  tertiary-fixed-dim: '#d4c69f'
  on-tertiary-fixed: '#221b03'
  on-tertiary-fixed-variant: '#4f4629'
  background: '#fcf9f8'
  on-background: '#1b1c1c'
  surface-variant: '#e4e2e1'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  container-margin-mobile: 16px
  container-margin-desktop: auto
  gutter: 16px
---

## Brand & Style

This design system is built to facilitate seamless coordination and foster trust among group travelers. The brand personality is **Reliable, Warm, and Adventurous**. It draws from a "Modern Corporate" foundation—ensuring that financial transactions and logistics feel secure—but infuses it with a "Tactile" warmth inspired by East African landscapes.

The UI evokes an emotional response of organized excitement. It avoids the coldness of typical fintech by using organic color transitions and generous whitespace, making complex itineraries feel manageable even when accessed on the go. The aesthetic balance favors high legibility for outdoor use and clear visual cues for offline states, ensuring the product remains a functional tool in varied connectivity environments.

## Colors

The palette is rooted in the natural beauty of the region. 

- **Primary (Deep Forest Green):** Used for primary actions, navigation headers, and "Verified" states. It represents stability and the lush landscapes of the destination.
- **Secondary (Sunset Orange):** Reserved for high-energy interactions like "Book Now," notifications, and active group highlights. It provides a vibrant contrast that is easy to spot in bright sunlight.
- **Tertiary (Warm Sand):** Utilized for large surface backgrounds and card containers. This reduces eye strain compared to pure white and reinforces the earthy, approachable feel.
- **Neutral:** A deep charcoal is used for text to ensure maximum contrast against the sand-toned backgrounds.

Functional colors for success (Emerald), warning (Amber), and error (Crimson) are slightly desaturated to maintain the organic feel of the primary palette.

## Typography

The typography system relies exclusively on **Inter** for its exceptional legibility and systematic weight distribution. 

### Scale & Hierarchy
- **Headlines:** Use tight letter-spacing and bold weights to command attention on itinerary titles and destination names.
- **Body Text:** Standardized at 16px for optimal readability across various mobile screen densities.
- **Offline Indicators:** Small, uppercase labels (label-sm) are used to indicate cached data or "available offline" status.

To handle long names common in group travel (e.g., long surnames or specific MoMo provider names), the system prioritizes text wrapping over truncation.

## Layout & Spacing

This design system uses a **Fluid Grid** model optimized for mobile-first usage. 

### Grid Logic
- **Mobile (up to 599px):** 4-column grid with 16px margins and 16px gutters. Content is primarily stacked vertically to accommodate one-handed use during travel.
- **Tablet (600px - 1023px):** 8-column grid with 24px margins. This allows for a split-screen view (e.g., Map on the left, Itinerary list on the right).
- **Desktop (1024px+):** 12-column grid with a max-width of 1200px.

Spacing follows an 8px rhythm. For list items—like group members or expense logs—spacing is kept at 'md' (16px) to ensure touch targets are accessible while maintaining a compact enough view to see multiple items at once.

## Elevation & Depth

Visual hierarchy is established through **Ambient Shadows** and **Tonal Layers**.

1.  **Base Layer:** The "Warm Sand" surface acts as the canvas.
2.  **Surface Tiers:** Cards and input fields use a slightly lighter version of the sand color or pure white to "lift" them from the background.
3.  **Shadow Character:** Shadows are soft, using a hint of the Primary Deep Green in the shadow color (`rgba(45, 90, 39, 0.08)`) to avoid a "dirty" look and keep the palette integrated.
4.  **Interaction Depth:** Elements like primary buttons have a subtle 2px vertical offset shadow that "squishes" (removes the shadow) when pressed, providing tactile feedback common in physical tools.
5.  **Offline State:** Items that are not yet synced use a "Low-Contrast Outline" (dashed) and 0 elevation to visually indicate they are not "solidified" in the cloud.

## Shapes

The shape language is **Rounded**, strike a balance between friendly hospitality and professional logistics.

- **Buttons & Inputs:** Use the standard `rounded-md` (0.5rem) to ensure they look inviting but fit within a structured grid.
- **Image Containers:** Destination photos and profile avatars use `rounded-lg` (1rem) to soften the overall UI.
- **Chips & Status Badges:** Utilize "Pill-shaped" (rounded-full) geometry to differentiate them from interactive buttons.
- **MoMo Integration Cards:** Use a specific 1.5rem corner radius on the top-left and bottom-right only to create a unique, "ticket-like" aesthetic for financial vouchers or payment confirmations.

## Components

### Buttons
- **Primary:** Deep Forest Green background with White text. Uses a 0.5rem radius and a soft ambient shadow.
- **Secondary:** Transparent with a 2px Deep Forest Green border.
- **MoMo Action:** Sunset Orange background with White text, specifically for payment-related triggers.

### Input Fields
Inputs use the Tertiary Warm Sand as a background with a bottom-only 2px border in a muted green. This mimics the look of a travel ledger. On focus, the border transitions to a solid Primary Green.

### Cards
Travel cards (itineraries, expenses) use a white background with a soft `0.5rem` radius. They must include a clear "Sync Status" icon in the top right corner.

### List Items
Group member lists and expense logs use a high-density layout with 12px vertical padding. Use "Left-hand Avatars" for people and "Left-hand Icons" for categories (food, transport, etc.).

### MoMo Integration
Specific components for Mobile Money include a "Quick-Pay" drawer that slides from the bottom, using high-contrast typography for the transaction amount and a large, accessible "Confirm" button.

### Offline Indicators
A persistent, slim bar at the top of the screen in a muted Amber tone appears when the device is offline, using `label-md` typography to clearly state "Working Offline — Changes will sync later."