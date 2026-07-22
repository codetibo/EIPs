# Features Overview — codetibo/EIPs

This document provides a detailed overview of all features implemented on the [Ethereum Improvement Proposals (EIPs)](https://eips.ethereum.org/) site fork, available at [https://codetibo.github.io/EIPs/](https://codetibo.github.io/EIPs/).

---

## Table of Contents

- [1. Full-Text Search](#1-full-text-search)
- [2. Design System](#2-design-system)
- [3. Dark / Light Theme Toggle](#3-dark--light-theme-toggle)
- [4. Keyboard Shortcuts](#4-keyboard-shortcuts)
- [5. Infinite Scroll on Listing Pages](#5-infinite-scroll-on-listing-pages)
- [6. Scroll-to-Top Button](#6-scroll-to-top-button)
- [7. Back-to-Top Links on EIP Detail Pages](#7-back-to-top-links-on-eip-detail-pages)
- [8. Sticky Table of Contents](#8-sticky-table-of-contents)
- [9. Scroll Reveal Animations](#9-scroll-reveal-animations)
- [10. Mobile Navigation Overlay](#10-mobile-navigation-overlay)
- [11. Responsive Layout](#11-responsive-layout)
- [12. ERC Metadata Population](#12-erc-metadata-population)
- [13. Hero Section with Statistics](#13-hero-section-with-statistics)
- [14. Developer Utilities](#14-developer-utilities)

---

## 1. Full-Text Search

A complete search engine that indexes all EIP content at build time and provides instant client-side search results.

### Search Page (`/search/`)

The dedicated search page at `/search/?q=<query>` provides:

- **Full-text search** across EIP number, title, description, content, status, type, category, and author fields
- **Scoring algorithm** that ranks results by relevance — EIP number matches get the highest score (50), followed by title matches (25), description (8), content frequency (4–10), status (6), type/category (5), and author (4). Multi-word queries and phrase matches receive additional scoring bonuses.
- **Pagination** — Results are paginated at 25 per page with Prev/Next controls, page number buttons, and ellipsis for large result sets
- **Context snippets** — Each result shows a text excerpt surrounding the first match, with highlighting
- **Filter controls**:
  - **Status** — Filter by Living, Final, Last Call, Review, Draft, Stagnant, or Withdrawn
  - **Type/Category** — Filter by Core, Networking, Interface, ERC, Meta, or Informational
  - **Author** — Free-text input to filter by author name
- **URL state** — All filters and query parameters are persisted in the URL (`?q=`, `?status=`, `?type=`, `?author=`) and survive page reloads
- **Clear all filters** — Single button to reset all active filters at once
- **Result badges** — Colored status badges (green for Final/Living, blue for Last Call, yellow for Review, etc.)

### Header Search Dropdown

The search input in the site header provides:

- **Live dropdown** — Shows top 5 results as you type, with a debounced input (200ms)
- **Keyboard navigation** — Arrow Up/Down to navigate results, Enter to go to the full search page, Escape to close
- **"View all N results" link** — Navigates to the full search page with the current query
- **"No EIPs found" message** — Shown when there are no matching results
- **Enter to search** — Pressing Enter in the header input navigates directly to the search page

### Build-Time Search Index

The file `search.json` generates a complete search index at build time containing every EIP's: EIP number, title, description, status, type, category, author, URL, and full text content. This index is fetched client-side by the JavaScript search engine.

### Key files
- `search.html` — Search page template
- `search.json` — Build-time search index generator (Jekyll Liquid)
- `assets/js/search.js` — Client-side search engine, scoring, pagination, filters, and rendering

---

## 2. Design System

A comprehensive design system built with CSS custom properties (design tokens).

### Design Tokens

The `:root` pseudo-class defines a complete set of CSS variables organized into categories:

| Token Group | Variables |
|---|---|
| **Typography** | `--font-display` (Space Grotesk), `--font-body` (Inter), `--font-mono` (JetBrains Mono) |
| **Colors** | `--color-bg`, `--color-surface`, `--color-surface-elevated`, `--color-accent`, `--color-accent-hover`, `--color-accent-soft`, `--color-accent-light`, `--color-accent-alt`, `--color-text`, `--color-text-secondary`, `--color-text-tertiary`, `--color-border`, `--color-border-light` |
| **Semantic colors** | `--color-success`, `--color-success-bg`, `--color-warning`, `--color-warning-bg`, `--color-danger`, `--color-danger-bg`, `--color-info`, `--color-info-bg` |
| **Shadows** | `--shadow-sm`, `--shadow-md`, `--shadow-lg`, `--shadow-xl` |
| **Radii** | `--radius-sm` (6px), `--radius-md` (10px), `--radius-lg` (14px), `--radius-xl` (20px) |
| **Transitions** | `--transition-fast` (150ms), `--transition-base` (250ms), `--transition-slow` (400ms cubic-bezier) |

### Component Styles

- **Site header** — Sticky header with frosted glass effect (`backdrop-filter: blur(16px)`), shadow on scroll, flexbox layout for logo + nav + theme toggle
- **Search input** — Rounded input with icon, focus ring, and dropdown results
- **Homepage hero** — Centered layout with gradient background, responsive typography, and call-to-action button
- **Category cards** — Grid layout with colored accent icons per category, hover lift effect
- **EIP listing tables** — Clean typography, uppercase headers, alternating row colors, hover highlighting
- **Status badges** — Pill-shaped badges with colors: green (Final/Living), blue (Last Call with pulse animation), yellow (Review), gray (Draft), red (Stagnant/Withdrawn)
- **EIP detail page** — Flexbox layout with sidebar TOC, content area, responsive preamble table
- **Load-more sentinel** — Centered spinner, load button with hover effects, completion checkmark
- **Footer** — Border-top separator, responsive flex layout
- **Scroll-to-top button** — Circular accent button with smooth show/hide animation

### Animation Utilities

- `pulse-dot` — Subtle pulsing animation for the site title dot indicator
- `dropdown-in` — Entry animation for search results dropdown
- `eip-spin` — Spinning animation for loading spinners
- `badge-pulse` — Ring pulse animation for Last Call status badges
- `scroll-reveal` — Fade-in + translate-up animation for elements as they scroll into view

### Google Fonts

Three font families loaded from Google Fonts:
- **Space Grotesk** — Display font for headings and hero text
- **Inter** — Body font for general text
- **JetBrains Mono** — Monospace font for code blocks

### Key files
- `assets/css/override.css` — Complete design system (all tokens and component styles)

---

## 3. Dark / Light Theme Toggle

A user-controlled theme switcher that overrides the default system-preference-based approach.

### How it works

1. **Blocking script in `<head>`** — A synchronous script at the top of `head.html` reads the theme preference from `localStorage` and sets `data-theme` on the `<html>` element before the page renders, preventing flash of unstyled content (FOUC)
2. **Default fallback** — If no saved preference exists, the script checks `prefers-color-scheme: dark` media query and defaults to dark mode if the user's system preference is dark
3. **Toggle button** — A sun/moon icon button in the site header toggles between light and dark modes with a click
4. **LocalStorage persistence** — The chosen theme is saved as `eip-theme` in `localStorage` and persists across page loads and browser sessions
5. **CSS architecture** — All dark mode styles are nested under `html[data-theme="dark"]` selectors, overriding design tokens and component styles

### Dark mode overrides

- Background colors are inverted (`#0d0d15` for page, `#14141f` for surfaces)
- Text colors become lighter (`#e8e8ed` primary, `#8888a0` secondary)
- Accent colors shift to a brighter blue (`#6b8aff`)
- Borders, shadows, code blocks, tables, badges, and all components are adjusted
- Syntax highlighting colors are inverted for readability

### Key files
- `_includes/head.html` — Theme initialization script and toggle logic
- `_includes/header.html` — Theme toggle button with sun/moon SVGs
- `assets/css/override.css` — `html[data-theme="dark"]` rules

---

## 4. Keyboard Shortcuts

Keyboard shortcuts for power users to quickly access site features from anywhere on the page.

| Shortcut | Action |
|---|---|
| **`/`** | Focus the search input (only when not already typing in a text field) |
| **`Cmd+K`** (Mac) / **`Ctrl+K`** (Win/Linux) | Focus and select the search input |
| **`Escape`** | Close the search dropdown / blur the search input (built-in) |

The `/` shortcut is guarded to prevent triggering when the user is actively typing in an `<input>`, `<textarea>`, or `contentEditable` element. On the dedicated `/search/` page, the shortcut focuses the search page's own search input since the header search is hidden there.

### Key files
- `_includes/head.html` — Keyboard shortcut event listener

---

## 5. Infinite Scroll on Listing Pages

All EIP listing pages (All, Core, Networking, Interface, ERC, Meta, Informational) use progressive loading instead of rendering the full list at once.

### How it works

1. **Initial render** — The first 25 EIPs per status section are shown immediately on page load
2. **IntersectionObserver** — A sentinel element at the bottom of the page is watched by an `IntersectionObserver` with a 200px root margin. When the sentinel becomes visible, the next batch is loaded
3. **Batch loading** — Each batch loads 25 rows at a time with an 80ms delay for smooth animation
4. **"Load more" button** — A fallback button in the sentinel area shows the remaining count (e.g., "Load more (340 more)") as an alternative to scrolling
5. **Progress counter** — A "Showing X of Y" counter updates in real-time as batches load
6. **Completion state** — When all EIPs are visible, a checkmark message ("✓ All N EIPs loaded") replaces the load button
7. **Section header hiding** — Status section headers (Final, Draft, etc.) auto-hide when all rows in that section are hidden, and reappear when rows become visible
8. **Scroll fallback** — A passive scroll event listener also triggers batch loading if the observer misses

### CSS class approach

Table rows are hidden/shown using the CSS class `.eip-tr-hidden { display: none !important; }` rather than inline `style.display`, preventing layout issues with table row rendering.

### Key files
- `_includes/infinite-scroll-table.html` — JavaScript implementation (self-contained, no dependencies)
- `assets/css/override.css` — Sentinel, spinner, button, and counter styles

---

## 6. Scroll-to-Top Button

A floating button that appears when the user scrolls down, providing a quick way to return to the top of the page.

- **Appears at 300px scroll** — Becomes visible after scrolling past 300px
- **Smooth scroll** — Scrolls to the top with `behavior: 'smooth'`
- **Animated entry/exit** — Fades in with a translate-up animation, fades out when near the top
- **Hover effect** — Arrow icon moves up slightly on hover
- **Throttled scroll listener** — Scroll event is throttled to 100ms for performance
- **Accessible** — Has `aria-label="Scroll to top"` and visible focus ring
- **Mobile friendly** — Larger tap target on mobile (48px vs 44px)
- **Dark mode** — Adjusted shadow for dark backgrounds

### Key files
- `_includes/head.html` — Button creation and scroll listener
- `assets/css/override.css` — `.eip-scroll-top` and `.eip-scroll-top--visible` styles

---

## 7. Back-to-Top Links on EIP Detail Pages

Subtle "↑ back to top" links appear next to `h2` and `h3` headings on EIP detail pages, providing quick navigation within long documents.

- **Hover reveal** — Links are hidden by default and appear on heading hover or focus-within
- **Touch devices** — Always visible at 50% opacity on touch devices (where hover isn't available)
- **Click behavior** — Smooth scrolls to the top of the page
- **Event delegation** — Click handler uses event delegation to handle dynamically created links

### Key files
- `_includes/head.html` — Link creation and click handling
- `assets/css/override.css` — `.eip-back-to-top` styles and hover behavior

---

## 8. Sticky Table of Contents

On EIP detail pages, a sidebar table of contents tracks the user's reading position and highlights the current section.

- **Active heading detection** — Uses `scrollY` and `offsetTop` comparisons to determine which heading is currently in view
- **Visual highlight** — The active TOC link gets a blue left border accent and bold text via the `.eip-toc--active` class
- **Throttled scroll listener** — Updates at 80ms intervals for performance
- **Sticky positioning** — The TOC sidebar is `position: sticky` and stays visible while scrolling, with `max-height: calc(100vh - 6.5rem)` and `overflow-y: auto`
- **Large screens only** — The sidebar TOC is hidden below 1024px; an inline TOC is shown instead on smaller screens

### Key files
- `_includes/head.html` — TOC tracking JavaScript
- `assets/css/override.css` — `.eip-layout__sidebar`, `.eip-layout__toc`, `.eip-toc--active` styles

---

## 9. Scroll Reveal Animations

Elements with the `.reveal` class fade in as the user scrolls, creating a polished page-load experience.

- **IntersectionObserver** — Uses browser-native intersection detection with a 0.08 threshold
- **Graceful fallback** — If `IntersectionObserver` is not supported, all elements are revealed immediately on page load
- **JS detection** — The `.js-reveal` class is added via JavaScript to distinguish between JS-enabled and JS-disabled environments
- **Transition** — Elements transition from `translateY(20px)` + `opacity: 0` to their natural position with full opacity over 600ms
- **Stagger delays** — Optional delay classes (`reveal-delay-1` through `reveal-delay-6`) enable cascading reveals at 50ms intervals
- **Reduced motion** — The `prefers-reduced-motion: reduce` media query disables all reveal animations

### Key files
- `_includes/head.html` — IntersectionObserver setup
- `assets/css/override.css` — `.reveal`, `.js-reveal`, `.is-visible` styles

---

## 10. Mobile Navigation Overlay

On small screens (below 768px), the navigation menu transforms into a full-screen overlay with smooth transitions.

- **Hamburger icon** — A three-line hamburger menu icon replaces the horizontal nav links
- **Full-screen overlay** — Clicking the hamburger opens a fixed-position overlay covering the entire screen
- **Close behavior** — Clicking a navigation link automatically closes the overlay; clicking the hamburger again toggles it
- **Animation** — The overlay slides in from the top with a 250ms ease animation
- **Backdrop** — A semi-transparent dark backdrop appears behind the overlay
- **Accessible** — Checkbox-based toggle with accessible labels
- **Z-index management** — The hamburger has a higher z-index than the overlay, keeping it clickable

### Key files
- `_includes/head.html` — Mobile nav toggle JavaScript
- `_includes/header.html` — Nav structure with checkbox trigger
- `assets/css/override.css` — Mobile navigation styles at `@media (max-width: 768px)`

---

## 11. Responsive Layout

The entire site is fully responsive across three breakpoints: default (desktop), 768px (tablet), and 480px (mobile).

### 768px breakpoint
- Typography scales down (h1: 1.5rem, h2: 1.2rem)
- Tables become horizontally scrollable with a gradient fade hint on the right edge
- EIP detail preamble table converts to stacked block layout
- Navigation switches to full-screen overlay
- Search results switch to fixed positioning within viewport

### 480px breakpoint
- Further spacing reductions
- Smaller hero stats
- Tighter code blocks
- Compact search results

### General
- `box-sizing: border-box` for all elements
- `scroll-behavior: smooth` for anchor navigation
- `-webkit-font-smoothing: antialiased` for better text rendering
- `img { max-width: 100% }` for responsive images
- `overflow-x: auto` with `-webkit-overflow-scrolling: touch` for scrollable containers

### Key files
- `assets/css/override.css` — Media queries and responsive overrides

---

## 12. ERC Metadata Population

A Python utility script that fetches real ERC metadata from the official [`ethereum/ercs`](https://github.com/ethereum/ercs) repository and updates the local stub files.

### Background

The `ethereum/EIPs` repository contains only stub files for ERCs (marked with `status: Moved`) — they only have `eip` and `category` fields. The actual content (titles, authors, proper statuses) lives in the separate `ethereum/ercs` repository.

### The script

`scripts/fetch-erc-metadata.py`:

1. Scans the `EIPS/` directory for all files with `category: ERC`
2. Extracts the EIP number from each stub file
3. Fetches the corresponding file from `https://raw.githubusercontent.com/ethereum/ercs/master/ERCS/erc-{NUMBER}.md`
4. Parses the YAML front matter to extract `title`, `author`, `type`, and `status`
5. Updates the local stub file with the real metadata, replacing `status: Moved` with the actual status (e.g., `Final`, `Draft`)

### Usage

```sh
python3 scripts/fetch-erc-metadata.py
```

The script processes all 365 ERC files and reports how many were updated, skipped (not found in the ercs repo), or failed.

### Key files
- `scripts/fetch-erc-metadata.py` — Python utility script

---

## 13. Hero Section with Statistics

The homepage features a redesigned hero section with prominent statistics and a clear call to action.

### Hero content
- **Title** — "Ethereum Improvement Proposals" with responsive font sizing via `clamp()`
- **Subtitle** — Brief description of what EIPs are
- **Statistics** — Three stat counters showing Total EIPs, Final, and Living counts (generated at build time via Liquid filters)
- **Call-to-action** — "Search all EIPs →" button linking to the search page

### Visual design
- **Radial gradient** — A subtle blue gradient overlay in the background creates depth without distracting from content
- **Responsive typography** — Title uses `clamp(2rem, 5vw, 3.25rem)` for fluid scaling
- **Button hover** — CTA button lifts slightly with a shadow and the arrow moves right

### Key files
- `index.html` — Hero section HTML with Liquid stat counters
- `assets/css/override.css` — `.eip-hero` and related styles

---

## 14. Developer Utilities

### Build and development

The site uses **Jekyll** with the **Minima** theme and **Bootstrap 5.3** for layout utilities.

```sh
# Install dependencies
bundle install

# Local development server
bundle exec jekyll serve

# Build site
bundle exec jekyll build
```

### Run the ERC metadata fetcher

```sh
python3 scripts/fetch-erc-metadata.py
```

### Key config
- `_config.yml` — Site configuration with Jekyll settings, header pages (including search), URL, and permalink structure

---

## Branch Structure

The repository has been organized into multiple branches for upstream contribution:

| Branch | Purpose | Status |
|---|---|---|
| `personal-site` | Your personal site with all features | ✅ Active, deployed |
| `pr-search` | Search functionality PR | ✅ Ready for upstream |
| `pr-ux` | UX improvements PR | ✅ Ready for upstream |
| `pr-infinite-scroll` | Infinite scroll PR | ✅ Ready for upstream |
| `pr-design` | Design system PR | ✅ Ready for upstream |

---

*Documentation generated for the codetibo/EIPs project.*
