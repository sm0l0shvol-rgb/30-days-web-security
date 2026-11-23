# Lab: Reflected XSS into HTML context with all tags blocked except custom ones

## Overview

- **Category:** Cross-Site Scripting (Reflected XSS / WAF Bypass)
- **Difficulty:** Practitioner
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab contains a reflected XSS vulnerability in the search functionality where the WAF blocks all standard HTML tags (`<script>`, `<img>`, `<body>`, `<svg>`, etc.) but permits non-standard custom tags (e.g., `<xss>`). By combining a custom HTML element with `tabindex=1`, an `id` attribute, an `onfocus` event handler, and a URL hash fragment (`#x`), we achieve zero-click JavaScript execution when the victim is redirected to the crafted URL.

---

## Attack Scenario & Mental Model

```text
ATTACKER GOAL
  Execute alert(document.cookie) in the victim's browser session
      ↓
VICTIM
  Authenticated user visiting an attacker-controlled page on the Exploit Server
      ↓
DELIVERY
  Top-level redirect via JavaScript (`location = "..."`) from the Exploit Server
  (Note: `X-Frame-Options: SAMEORIGIN` prevents framing via `<iframe>`)
      ↓
SOURCE
  URL query parameter: GET /?search=...
      ↓
WAF BYPASS
  All standard HTML tags return `400 Bad Request ("Tag is not allowed")`.
  Custom tags such as `<xss>` bypass the blocklist and return `200 OK`.
      ↓
SINK
  The server reflects `<xss id=x onfocus=alert(document.cookie) tabindex=1>`
  directly into the `<h1>` search results element in the HTML response.
      ↓
BROWSER BEHAVIOR
  1. `tabindex=1` makes the custom `<xss>` element focusable.
  2. `id=x` assigns an anchor target to the custom element.
  3. The trailing `#x` fragment in the URL instructs the browser to automatically
     scroll to and focus the element with `id="x"` upon page load.
  4. Focusing the element fires the `onfocus` event handler without user clicks.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(document.cookie)`) in the victim's browser.
```

---

## Step-by-Step Walkthrough

### 1. Analyzing the WAF Restrictions
Testing standard tags (including `<body>` from the previous lab) in the `search` parameter returned `HTTP/2 400 Bad Request` (`"Tag is not allowed"`). However, testing a custom tag such as `<xss>` returned `HTTP/2 200 OK`.

Notice also that the server response includes:

```http
X-Frame-Options: SAMEORIGIN
```

This header prevents embedding the vulnerable page inside a cross-origin `<iframe>`, meaning the exploit must be delivered via a top-level navigation (`location = "..."`).

### 2. Crafting a Zero-Click Payload for a Custom Tag
Because custom HTML tags do not load external resources, events like `onload` or `onerror` will never fire on `<xss>`. To trigger an event automatically without requiring the victim to click or move their mouse:

1. Added `tabindex=1` so the browser allows the custom `<xss>` element to receive focus.
2. Added `id=x` so the element can be targeted by a URL hash fragment.
3. Added `onfocus=alert(document.cookie)` to execute when focused.
4. Appended `#x` to the end of the URL so the browser automatically focuses the `#x` element on page load.

Full reflected HTML in the DOM:

```html
<h1>0 search results for '<xss id="x" onfocus="alert(document.cookie)" tabindex="1">'</xss></h1>
```

> **Debugging Tip:** When testing `onfocus` locally in the browser, ensure that Browser DevTools does not hold window focus; if focus is inside the DevTools panel, the page viewport will not trigger `onfocus` until clicked or reloaded with DevTools unfocused.

### 3. Delivering the Exploit via Exploit Server
Placed the following redirect script into the **Body** of the Exploit Server:

```html
<script>
    location = "https://LAB-HOST/?search=%3Cxss+id%3Dx+onfocus%3Dalert(document.cookie)+tabindex%3D1%3E#x";
</script>
```

Clicked **Store** and **Deliver exploit to victim** to solve the lab.

---

## Key Takeaways & Remediation

### Why Custom Tag Bypass Works
Blacklist-based WAFs that enumerate standard HTML specifications cannot anticipate arbitrary custom tag names (`<xss>`, `<a-b>`, etc.), which browsers still parse into valid DOM nodes capable of handling standard DOM events like `onfocus`.

### Remediation
- **HTML Output Encoding:** Encode `<` and `>` as `&lt;` and `&gt;` before rendering user input in an HTML context so no tags (standard or custom) can be interpreted by the browser parser.
- **Strict Allowlist Sanitization:** If HTML markup must be accepted, validate against an explicit allowlist of permitted tags and attributes rather than a blocklist.
