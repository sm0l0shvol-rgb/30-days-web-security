# Lab: Reflected XSS with event handlers and href attributes blocked

## Overview

- **Category:** Cross-Site Scripting (Reflected XSS / WAF Bypass / SVG Animation)
- **Difficulty:** Expert
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This Expert-level lab contains a reflected XSS vulnerability protected by a strict WAF that blocks all HTML/SVG event handler attributes (`onload`, `onerror`, `onbegin`, `onclick`, etc.) as well as the `href` attribute itself. However, the filter allows a subset of SVG tags: `<svg>`, `<a>`, `<animate>`, and `<text>`. By nesting an SVG `<animate>` element inside an SVG `<a>` element, we instruct the browser's SMIL animation engine to dynamically populate the `href` attribute of the parent `<a>` tag with `javascript:alert(1)` at runtime—completely bypassing the WAF's static attribute check.

---

## Attack Scenario & Mental Model

```text
ATTACKER GOAL
  Execute alert(1) when the victim clicks a rendered link on the page
      ↓
VICTIM / TRIGGER
  The simulated victim visits the crafted search URL and clicks any clickable
  element labeled "Click me"
      ↓
SOURCE
  URL query parameter: GET /?search=...
      ↓
WAF ANALYSIS
  - All event handler attributes (`on*`) -> Blocked (HTTP 400).
  - The `href` attribute (`<a href=...>`) -> Blocked (HTTP 400 - "Attribute is not allowed").
  - Allowed tags (HTTP 200): `<svg>`, `<a>`, `<animate>`, `<text>`.
      ↓
INJECTION (SVG SMIL Attribute Animation Bypass)
  Instead of writing `href="..."` directly on the `<a>` tag, we use a child
  `<animate>` element with:
  - `attributeName=href` (targets the `href` attribute of the parent `<a>` tag)
  - `values=javascript:alert(1)` (sets the animated value of `href`)
  And we add `<text x=20 y=20>Click me</text>` inside `<a>` so the link has
  a visible, clickable label.
      ↓
SINK
  The server reflects:
  <svg><a><animate attributeName=href values=javascript:alert(1) /><text x=20 y=20>Click me</text></a>
      ↓
BROWSER BEHAVIOR
  1. The browser renders the `<svg>` canvas and its child `<a>` and `<text>` nodes.
  2. The `<animate>` element starts immediately and dynamically binds the
     `href` property of the parent `<a>` element to `javascript:alert(1)`.
  3. When the victim clicks "Click me", the browser follows the animated `href`
     link and executes `alert(1)`.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1)`) in the victim's browser context.
```

---

## Step-by-Step Walkthrough

### 1. Enumerating Allowed Tags in Burp Intruder
Fuzzing `GET /?search=%3C§tag§%3E` against the HTML/SVG tag list revealed that only a few tags returned `HTTP/2 200 OK`:
- `<svg>`
- `<a>`
- `<animate>`
- `<text>`
- `<title>`

### 2. Testing Attributes
- Attempting to use any event handler (including SVG `onbegin`) or `<a href="...">` directly returned `HTTP/2 400 Bad Request` (`"Attribute is not allowed"`).
- However, SVG SMIL animation attributes `attributeName` and `values` on `<animate>` were permitted (`200 OK`).

### 3. Constructing the SVG `<animate>` Payload
In SVG, an `<animate>` tag placed inside an `<a>` tag can dynamically animate attributes of its parent element. By setting `attributeName=href` and `values=javascript:alert(1)`, the browser assigns the `javascript:` URL to the parent `<a>` tag without the literal `href=` attribute ever appearing in the HTTP request.

Submitted the following payload in the search parameter:

```html
<svg><a><animate attributeName=href values=javascript:alert(1) /><text x=20 y=20>Click me</text></a>
```

URL:
```text
https://LAB-HOST/?search=%3Csvg%3E%3Ca%3E%3Canimate+attributeName%3Dhref+values%3Djavascript%3Aalert(1)+%2F%3E%3Ctext+x%3D20+y%3D20%3EClick+me%3C%2Ftext%3E%3C%2Fa%3E
```

When rendered, the SVG displayed the clickable text **"Click me"**, and the lab's simulated victim clicked it, executing `alert(1)` and solving the lab.

---

## Key Takeaways & Remediation

### Why Blocking `href` Statically Fails When SVG `<animate>` Is Allowed
SVG SMIL animation elements (`<animate>`, `<set>`) allow indirect modification of parent element attributes via `attributeName="..."` and `values="..."` / `to="..."`. Blocking dangerous attributes like `href` or `xlink:href` at the WAF level is ineffective if `<animate>` or `<set>` tags are allowed to mutate those attributes dynamically in the browser DOM.

### Remediation
- **HTML Entity Encode Untrusted Output:** Encode `<` and `>` as `&lt;` and `&gt;` so arbitrary HTML/SVG tags cannot be injected.
- **Forbid `<animate>` and `<set>` in SVG Sanitizers:** Any HTML/SVG sanitization allowlist must strip SMIL animation tags (`<animate>`, `<set>`, `<animatetransform>`) or validate `attributeName` and `values`/`to`/`from` against URL scheme injection (`javascript:`, `data:`).
