---
name: Public Infrastructure UI
colors:
  surface: '#f9f9ff'
  surface-dim: '#d0daef'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff3ff'
  surface-container: '#e6eeff'
  surface-container-high: '#dee9fd'
  surface-container-highest: '#d9e3f7'
  on-surface: '#121c2a'
  on-surface-variant: '#44474e'
  inverse-surface: '#273140'
  inverse-on-surface: '#ebf1ff'
  outline: '#75777f'
  outline-variant: '#c5c6cf'
  surface-tint: '#4e5e81'
  primary: '#031635'
  on-primary: '#ffffff'
  primary-container: '#1a2b4b'
  on-primary-container: '#8293b8'
  inverse-primary: '#b6c6ef'
  secondary: '#0058be'
  on-secondary: '#ffffff'
  secondary-container: '#2170e4'
  on-secondary-container: '#fefcff'
  tertiary: '#231400'
  on-tertiary: '#ffffff'
  tertiary-container: '#3e2700'
  on-tertiary-container: '#b08d5b'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#b6c6ef'
  on-primary-fixed: '#081b3a'
  on-primary-fixed-variant: '#364768'
  secondary-fixed: '#d8e2ff'
  secondary-fixed-dim: '#adc6ff'
  on-secondary-fixed: '#001a42'
  on-secondary-fixed-variant: '#004395'
  tertiary-fixed: '#ffddb1'
  tertiary-fixed-dim: '#e8c08a'
  on-tertiary-fixed: '#291800'
  on-tertiary-fixed-variant: '#5d4217'
  background: '#f9f9ff'
  on-background: '#121c2a'
  surface-variant: '#d9e3f7'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: Plus Jakarta Sans
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
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
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
  sm: 12px
  md: 24px
  lg: 48px
  xl: 80px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 64px
---

## Brand & Style

This design system is built on the principles of **Reliability, Authority, and Accessibility**. It is designed specifically for a public utility service, prioritizing clarity and trust over trend-driven aesthetics. The style is **Modern Corporate**, drawing inspiration from physical infrastructure and institutional stability. 

The visual language avoids "tech startup" tropes like aggressive gradients or glassmorphism. Instead, it utilizes structured layouts, substantial UI elements, and a high-contrast palette to communicate a sense of permanence and civic duty. The emotional response should be one of confidence: the user should feel that the service is dependable, grounded, and essential to daily life.

## Colors

The color palette is anchored in **Deep Electricity Blue (#1A2B4B)**, providing an authoritative and professional foundation. **Clean Medium Blue (#3B82F6)** is used for primary interactive elements and focus states to ensure high visibility.

**Electricity Yellow (#FBBF24)** is used strictly as a functional accent for status indicators, energy-related highlights, or critical warnings. The background strategy relies on a combination of pure white and a light neutral gray to create a clear "surface vs. background" hierarchy without relying on heavy borders.

## Typography

This design system uses a dual-font strategy. **Plus Jakarta Sans** is used for headlines to provide a modern, approachable, and slightly soft institutional feel. **Inter** is used for body text and labels to maximize legibility, particularly in data-heavy views like billing history or energy consumption charts.

Weights are used purposefully: bold for clear structural headers and medium/regular for utilitarian content. Line heights are generous to ensure readability for a wide demographic of users.

## Layout & Spacing

The layout follows a **Fluid Grid** system based on an 8px rhythm. Content is organized into a 12-column grid for desktop and a 4-column grid for mobile devices.

- **Desktop:** 64px outer margins with 24px gutters.
- **Mobile:** 16px outer margins with 16px gutters.
- **Sectioning:** Use large vertical spacing (48px to 80px) to separate distinct functional areas (e.g., separating "Current Balance" from "Usage Charts").

Whitespace is used as a functional tool to prevent the UI from feeling cluttered, reinforcing the professional and calm nature of the service.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** and restrained shadows. 
- **Level 0 (Background):** Light neutral gray (#F9FAFB) for the main application canvas.
- **Level 1 (Surfaces):** Pure white (#FFFFFF) for cards and containers, featuring a subtle 1px border (#E5E7EB).
- **Shadows:** Only used on primary interactive elements or "floating" notifications. Shadows should be low-blur and high-spread to feel more like a physical object than a digital glow (e.g., `0px 4px 6px rgba(0,0,0,0.05)`).
- **Outlines:** Use soft charcoal outlines for input fields and secondary buttons to maintain a "printed" or "physical" aesthetic.

## Shapes

The shape language is defined by **Medium Roundedness**. 
- Standard components (Buttons, Inputs) use an 8px (0.5rem) radius.
- Large containers (Cards, Modals) use a 16px (1rem) radius.

These rounded corners soften the authoritative blue palette, making the utility service feel more human-centered and accessible without appearing "playful" or juvenile.

## Components

### Buttons
Buttons are substantial and high-contrast. 
- **Primary:** Deep Blue background, white text, 8px radius. Minimum height of 48px to ensure a "physical" presence.
- **Secondary:** White background with a Subtle Charcoal border.
- **States:** Hover states should involve a slight darkening of the background color, not a change in elevation.

### Input Fields
Inputs should look dependable. Use a 1px border (#D1D5DB) and a 16px horizontal padding. On focus, the border shifts to Medium Blue (#3B82F6) with a 2px stroke. Label typography must always be visible (never floating labels that disappear).

### Cards
Cards are the primary container for data. They should have a white background, an 8px radius, and a very subtle 1px border. No shadows should be applied to cards unless they are being actively dragged or are part of a modal overlay.

### Status Chips
Used for billing status (Paid, Overdue) or connection status (Active, Outage). These use the Accent Yellow for warnings and a standard green/red for success/error, but always with high-contrast text to ensure accessibility.

### Iconography
Icons must be simple, consistent line weights (2px). Avoid filled icons unless used for active navigation states. The iconography should represent physical utility concepts (plugs, meters, lightning bolts, paper bills) clearly.