# Design System Document: The Numismatic Editorial

## 1. Overview & Creative North Star
**Creative North Star: "The Digital Archivist"**
This design system moves away from "e-commerce template" tropes and toward the aesthetic of a high-end auction house or a private museum gallery. The goal is to treat every rare banknote not as a product, but as a historical artifact. 

To achieve "The Digital Archivist" look, the system relies on **intentional asymmetry** and **editorial pacing**. Instead of a standard 4-column grid, we use wide gutters and offset layouts where text and imagery overlap slightly. This breaks the "boxed-in" feel of traditional storefronts, creating a signature experience that feels bespoke, curated, and authoritative.

---

## 2. Colors & Surface Logic
The palette is rooted in the "Deep Navy" and "Slate" of global currency, accented by the "Gold" of intrinsic value.

### The "No-Line" Rule
**Strict Mandate:** Prohibit the use of 1px solid borders for sectioning or containment. 
Structure must be defined through **Background Color Shifts**. For example, a featured collection section in `surface-container-low` should sit directly against a `surface` background. The transition between these two shades is the boundary.

### Surface Hierarchy & Nesting
Treat the UI as a series of stacked, premium papers. Use the Material tiers to define "Importance through Depth":
*   **Base Layer:** `surface` (#f8f9fa) – The canvas.
*   **Structural Sections:** `surface-container-low` (#f3f4f5) – For secondary content blocks.
*   **Interactive Elements:** `surface-container-lowest` (#ffffff) – For cards and high-priority inputs to make them "pop" against the darker background.

### The "Glass & Signature Texture" Rule
To elevate the "Modern Storefront" feel:
*   **Navigation & Overlays:** Use Glassmorphism. Apply `surface` with 80% opacity and a `20px` backdrop-blur. This allows the intricate patterns of the banknotes to bleed through the UI, maintaining a sense of place.
*   **CTAs:** Apply a subtle linear gradient to `primary` (#000000) buttons, transitioning from `primary` to `primary-container` (#101b30). This adds a "weighted" metallic feel that flat black cannot achieve.

---

## 3. Typography
The typography is a dialogue between the "History" (Serif) and the "Value" (Sans-Serif).

*   **Display & Headlines (Newsreader):** Use this sharp serif for all storytelling elements. It conveys the authority of a central bank and the heritage of the items. Use `display-lg` for hero statements to command immediate respect.
*   **Title & Body (Inter):** Use this high-legibility sans-serif for functional data: serial numbers, denominations, and grading scales. 
*   **The Contrast Rule:** Always pair a `headline-md` (Serif) with a `label-md` (Sans-Serif) in uppercase with 10% letter spacing to create an "archival tag" aesthetic.

---

## 4. Elevation & Depth
We reject traditional shadows in favor of **Tonal Layering**.

*   **The Layering Principle:** Depth is achieved by placing `surface-container-lowest` elements on a `surface-container` background. This creates a "soft lift" that feels architectural rather than digital.
*   **Ambient Shadows:** If a floating effect is required (e.g., a high-value currency zoom), use an extra-diffused shadow: `box-shadow: 0 20px 40px rgba(25, 28, 29, 0.06)`. Note the low opacity; it should be felt, not seen.
*   **The "Ghost Border" Fallback:** If accessibility requires a stroke, use the `outline-variant` token at **15% opacity**. Never use 100% opaque lines.
*   **Glassmorphism:** Use for floating headers and filtering drawers to keep the user grounded in the "Gallery" space.

---

## 5. Components

### Buttons
*   **Primary:** `primary` background, `on-primary` text. **Corner radius: 0px**. Padding: `spacing-4` vertical, `spacing-8` horizontal. 
*   **Secondary:** `surface-container-highest` background. No border. Use for "Add to Watchlist" or "View Grading Report."

### Cards & Lists
*   **The "No-Divider" Rule:** Forbid 1px dividers between list items. Use `spacing-6` of vertical white space to separate items. 
*   **Banknote Cards:** Use `surface-container-lowest` (#ffffff). Imagery should be large, utilizing `spacing-px` as a thin "inner frame" if the banknote has a white border.

### Chips (Grading & Rarity)
*   **Status Chips:** Use `tertiary-fixed` (#ffdea5) for "Rare" or "Unique" status. This gold-tone suggests value without the garishness of standard "sale" red.

### Input Fields
*   **Text Inputs:** Use a "Bottom-Line Only" approach or a very faint `surface-variant` fill. Ensure `0px` rounding. Error states must use `error` (#ba1a1a) text but maintain the clean, sharp geometry of the system.

### Additional Signature Component: "The Provenance Drawer"
A slide-out glass panel (`backdrop-blur`) that contains the historical narrative of a specific note. It uses `display-sm` (Newsreader) for the title and `body-lg` (Inter) for the history, emphasizing the editorial nature of the storefront.

---

## 6. Do’s and Don'ts

### Do
*   **Use generous whitespace:** Use `spacing-16` and `spacing-20` to separate major sections. "Clean seriousness" requires breathing room.
*   **Embrace Asymmetry:** Place a high-res banknote image slightly off-center to create a dynamic, high-end editorial feel.
*   **Use Tonal Shifts:** Define different areas of the page by switching between `surface` and `surface-container-low`.

### Don't
*   **No Rounded Corners:** `0px` is the standard. Any rounding (even 2px) breaks the "sharp, professional" mandate.
*   **No Heavy Borders:** Never use high-contrast lines to separate content. It makes the site look like a budget spreadsheet.
*   **No Standard Blue:** Avoid "Hyperlink Blue." Use `secondary` (#4a607a) or `tertiary` for all accents to maintain the sophisticated palette.

## 7. Inspiration
*   **Use Inspiration:** Use inspiration from `.claude/skills/ui-ux-pro-max/inspiration/`. There are 3 elements here:
- `home` is the home page for the webpage.
- `browse` is for the page to browse the different banknotes sold.
- `item-view` is the detailed item view for each bank note.
