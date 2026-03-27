# Design System: YOM

## Overview
YOM is a Swiss International Style mobile app for location-aware memory retrieval. The interface should feel objective, grid-based, editorial, cartographic, and anchored to place. It should read like a field guide, transit system, museum label set, and modernist poster language translated into a calm iOS product.

The personality is restrained rather than expressive, factual rather than sentimental, and spacious rather than dense. Visual order must be obvious: strong alignment, flush-left typography, disciplined spacing, and clear hierarchy. White space is functional. Color is used sparingly to orient the user toward location, action, and state.

Avoid playful consumer-app aesthetics, soft lifestyle minimalism, glassmorphism, decorative gradients, bubbly navigation, and ornamental illustration. The result should feel precise, stable, and institutional in a good way.

## Colors
- **Primary** (#1D4D7A): Primary CTAs, active navigation states, route emphasis, focused states, and the single most important interaction on a screen
- **Secondary** (#E7E2D8): Secondary surfaces, inset cards, grouped list backgrounds, sheets, and quiet supporting containers
- **Tertiary** (#D84C2F): Active map pins, current-location pulse, urgent highlights, destructive actions, and rare moments needing immediate anchoring
- **Neutral** (#111111): Primary text, icons, outlines with strong contrast, and non-chromatic UI structure

Supporting neutrals and state colors:
- **Canvas Neutral** (#F4F1EA): Primary page background and large base surfaces
- **Muted Neutral** (#5E5952): Secondary text, helper text, timestamps, and subdued metadata
- **Outline Neutral** (#BEB6A8): Hairline borders, dividers, grid cues, and structural separators
- **Success** (#2F6B4F): Saved states, completed retrieval actions, archival confirmations
- **Warning** (#A7701F): Permission prompts, cautions, and partial availability
- **Error** (#B3261E): Critical errors when stronger emphasis than tertiary is required

Use the primary color for one dominant action per screen. Keep most screens mostly neutral, with the palette led by Canvas Neutral, Secondary, Neutral, and Muted Neutral. Do not place multiple accent families in equal competition.

## Typography
- **Headline Font**: Helvetica Neue or Neue Haas Grotesk, with Inter as fallback
- **Body Font**: Helvetica Neue or Inter
- **Label Font**: Helvetica Neue or Inter

Headlines use semibold to bold weight with tight leading and compact rhythm. Body text uses regular weight at 16-17px with a 1.45-1.6 line height. Labels use medium weight at 12-13px, and uppercase is acceptable for tabs, year markers, filters, and section labels when paired with increased tracking.

Typography should always feel like signage, editorial labeling, and institutional navigation rather than lifestyle branding. Default to flush-left, ragged-right text. Avoid centered multi-line paragraphs, decorative display type, rounded fonts, or mixing too many weights on the same screen.

## Elevation
This design uses almost no shadows. Depth is conveyed through border contrast, surface variation, and strict layout separation rather than floating layers.

Cards, sheets, and overlay panels should primarily use Canvas Neutral (#F4F1EA), Secondary (#E7E2D8), and Outline Neutral (#BEB6A8) to establish hierarchy. If elevation is needed for a modal or sheet, use only a faint single shadow for separation. Do not use stacked shadows, soft ambient glows, or glass blur treatments.

## Components
- **Buttons**: Squared-off or subtly eased corners (6-8px). Primary uses Primary (#1D4D7A) fill with Canvas Neutral (#F4F1EA) text. Secondary uses transparent or Secondary (#E7E2D8) fill with a 1px Outline Neutral (#BEB6A8) border. Destructive uses Tertiary (#D84C2F) sparingly.
- **Inputs**: Straight edges or subtle 6-8px easing, 1px border, Canvas Neutral (#F4F1EA) or Secondary (#E7E2D8) fill, visible labels, and Primary (#1D4D7A) focus state. Search should feel like an indexed tool, not a decorative hero control.
- **Cards**: Flat panels with 10-12px corner easing, no default elevation, 1px outline border, and disciplined 16px / 24px / 32px padding increments.
- **Lists**: Indexed-entry styling with thin separators or flat grouped panels, aligned metadata stacks, optional thumbnail or year marker, and clear leading/trailing actions.
- **Navigation**: Quiet tab bars and top navigation, slim active indicators, no bubbly capsules, and active-state emphasis driven by Primary (#1D4D7A) or a precise underline/bar.
- **Map Modules**: Full-bleed map canvas with exact overlay alignment. Active pin and urgent spatial anchor can use Tertiary (#D84C2F), while route and persistent orientation states use Primary (#1D4D7A).
- **Sheets**: Bottom sheets should feel like archival trays or filed drawers: flat, exact, factual, and aligned to the same inset system as the rest of the interface.

Recommended screen-specific patterns:
- **Onboarding**: One strong statement, one concise paragraph, one primary action, understated progress markers
- **Archive**: Institutional catalog rhythm, documentary thumbnails, year markers, rule-based filters
- **Retrieval Detail**: Editorial reading layout with strong hierarchy, year-title-summary-body sequence, restrained imagery
- **Settings**: Utility-first grouped list with no decorative surfaces

## Do's and Don'ts
- Do use a 4-column mobile grid with an 8px spacing rhythm and 16px outer gutters
- Do keep typography flush-left and visibly aligned to repeated vertical spines
- Do let one element carry emphasis: a year marker, a route CTA, a heading, or a map state
- Do use documentary, monochrome, or desaturated imagery when imagery is needed
- Do keep touch targets at or above 44x44px
- Don't mix pill-shaped controls with squared-off Swiss-style panels in the same screen
- Don't use more than one dominant accent family per view
- Don't use loud gradients, glassmorphism, floating chrome, or playful illustration
- Don't center long paragraphs or treat the app like a marketing landing page
- Don't rely on shadows when borders, spacing, and surface variation can do the job
