# Design System: YOM Acid Variant

## Overview
YOM in this variant is an acid graphics mobile app for location-aware memory retrieval. The interface should feel nocturnal, electric, synthetic, slightly dangerous, and digitally urban, like a rave flyer, corrupted archive terminal, and geospatial instrument fused into one product. It should still remain legible and operational: this is not a poster pretending to be an app, but an app borrowing acid energy at the moments where orientation, discovery, and atmosphere matter most.

The best fit for YOM is **controlled acid**, not full anti-design chaos. Use the style to make the app feel like a live urban signal system: route states glow, pins puncture the map, year markers feel charged, archive items feel like transmissions, and onboarding has strong visual voltage. Retrieval reading, settings, and helper text stay more stable so the user can still navigate, read, and decide quickly.

Avoid turning every screen into a maximal collage. Acid here should mean bold contrast, surprising accent, experimental display moments, and a dark digital field, while preserving hierarchy and map usability.

## Colors
- **Primary** (#C6FF00): Primary CTAs, active route lines, focused states, selected filters, and the strongest directional signal on a screen
- **Secondary** (#151515): Main dark surfaces, sheets, toolbars, search overlays, grouped panels, and map chrome
- **Tertiary** (#FF4FD8): Active pins, temporal highlights, badges, destructive accents, and rare high-energy emphasis
- **Neutral** (#F2F3EA): Primary text on dark surfaces, key icons, dividers with high contrast, and non-chromatic UI structure

Supporting neutrals and state colors:
- **Canvas Dark** (#090A09): App background, deep containers, and dark-theme map framing
- **Muted Neutral** (#A6AA9A): Secondary text, timestamps, helper copy, and subdued metadata
- **Outline Neutral** (#3B3F38): Borders, separators, input outlines, and structural rules
- **Signal Cyan** (#31D7FF): Optional secondary signal for informational wayfinding or selected map detail when tertiary would feel too aggressive
- **Warning Amber** (#FFB000): Permissions, caution prompts, and limited-state warnings
- **Error Red** (#FF5A36): Critical errors and high-risk destructive actions

Use Primary as the route-and-action anchor. Use Tertiary as a puncture color, not a blanket UI tone. Keep the base of most screens dark and controlled, with acid colors concentrated on one or two critical interaction layers. Do not let cyan, lime, magenta, and amber all shout at once.

## Typography
- **Headline Font**: Space Grotesk
- **Body Font**: Inter
- **Label Font**: Space Grotesk

Headlines use bold or semibold weight with compact rhythm and strong contrast against dark surfaces. Display moments can use tighter tracking, occasional uppercase bursts, and selective stylistic alternates, but only in hero statements, year markers, archive labels, and high-energy transition moments. Body text must remain clean and functional at 16-17px with a 1.45-1.6 line height. Labels can use medium or semibold weight at 12-13px with uppercase and expanded tracking.

This is where the app should differ from pure poster-style acid graphics: experimental type belongs in display moments only. Navigation labels, route instructions, summaries, metadata, and settings copy must stay readable and stable. Do not use warped, reversed, mirrored, or illegible lettering for operational content.

## Elevation
This design uses contrast, outlines, and selective glow instead of soft material depth. Surfaces should feel hard, dark, and electronic.

Cards, sheets, and overlays should primarily use Secondary (#151515), Canvas Dark (#090A09), Outline Neutral (#3B3F38), and Neutral (#F2F3EA) to establish hierarchy. Primary (#C6FF00) or Tertiary (#FF4FD8) glow can appear on key controls, active pins, or highlighted modules, but only as a controlled edge treatment or subtle aura. Do not use blurry ambient depth, stacked shadows, or frosted glass.

## Components
- **Buttons**: 6-8px corner radius, compact rectangular silhouettes, bold contrast. Primary uses Primary (#C6FF00) fill with Canvas Dark (#090A09) text. Secondary uses Secondary (#151515) fill with a 1px Outline Neutral (#3B3F38) or Primary (#C6FF00) outline. Destructive or urgent actions can use Tertiary (#FF4FD8) or Error Red (#FF5A36) depending on severity.
- **Chips**: Tight, utility-driven chips for year, distance, or filters. Use dark fill with crisp outline by default; selected state can switch to Primary (#C6FF00) fill or Tertiary (#FF4FD8) accent. Keep them compact and instrumental, not cute.
- **Inputs**: Dark field surfaces, 1px outline, clean label hierarchy, and Primary (#C6FF00) focus ring or underline. Search should feel like a live query console rather than a soft search bubble.
- **Cards**: Flat terminal-like panels with 8-12px corner radius, outline-first separation, and occasional acid edge highlight for selected state. Archive cards can carry stronger acid accents than settings or long-form reading cards.
- **Lists**: Scannable rows with strong left-edge alignment, thin separators, visible metadata, and charged year markers or index tags. Rows should feel like catalog entries or intercepted signals.
- **Navigation**: Quiet but sharp. Tabs and top bars should use high-contrast labels, slim underlines, thin borders, or active glow on the selected item. Avoid floating pill navigation unless it is made darker, flatter, and more instrument-like.
- **Map Modules**: Use a dark or desaturated map base when possible. Primary (#C6FF00) should own route lines and navigation guidance. Tertiary (#FF4FD8) can mark the active memory pin or temporal anomaly. Search overlays, navigation pills, and preview sheets should feel like scanning equipment rather than default mobile cards.
- **Sheets**: Bottom sheets should read like dark signal panels or archive drawers: exact, bordered, high-contrast, and lightly energized at the edge rather than fully glowing.

Recommended screen-specific patterns:
- **Onboarding**: Strong acid headline, charged typography, and one unmistakable primary action over a dark field
- **Map Home**: Dark map, lime route emphasis, magenta active pin, compact signal-like overlays
- **Archive**: Charged year markers, sharp list rhythm, darker catalog panels, selective acid accents on favorites or selected states
- **Retrieval Detail**: Editorial dark reading layout with acid used on section markers and media framing rather than long passages of text
- **Settings**: Mostly quiet dark utility UI with almost no acid except for active toggles or critical actions

## Do's and Don'ts
- Do use acid styling as an orientation and energy layer, not as full-screen noise
- Do keep the map, route, and active pin as the most visually charged elements in the main flow
- Do reserve experimental typography for hero labels, year markers, and high-energy headings
- Do keep reading text, metadata, and settings copy stable and highly legible
- Do use dark surfaces with crisp borders before adding glow
- Don't distort or stylize operational text such as route actions, map summaries, settings labels, or permission messages
- Don't let Primary, Tertiary, Signal Cyan, and Warning Amber compete on the same screen
- Don't use liquid-metal effects, 3D blobs, or trippy textures behind core tasks unless they are purely decorative and isolated
- Don't apply the same visual intensity to Settings and long-form Retrieval that you use in Onboarding or active map states
- Don't mistake illegibility for attitude; the app still has to guide someone through search, navigation, archive, and retrieval
