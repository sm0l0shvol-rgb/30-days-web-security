# Lab: Reflected XSS with some SVG markup allowed

## Overview

- **Category:** Cross-Site Scripting (Reflected XSS / WAF Bypass / SVG)
- **Difficulty:** Practitioner
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab contains a reflected XSS vulnerability in the search functionality protected by a WAF that blocks common HTML tags and event handlers, but allows specific SVG elements. By fuzzing for permitted tags and event attributes, we identify that `<svg>`, `<animatetransform>`, and the SVG animation event `onbegin` are allowed, leading to immediate zero-click JavaScript execution.

---

## Attack Scenario & Mental Model

```text
ATTACKER GOAL
  Execute alert(1) in the browser via Reflected XSS
      ↓
VICTIM / DELIVERY
  User visiting the crafted search URL (`/?search=...`)
      ↓
SOURCE
  URL query parameter: GET /?search=...
      ↓
WAF BYPASS
  1. Tag fuzzing (`<%3C§tag§%3E`) reveals 4 allowed tags returning HTTP 200:
     - <svg>
     - <animatetransform>
     - <title>
     - <image>
  2. Event attribute fuzzing inside `<svg><animatetransform §event§=1>`
     reveals that `onbegin` returns HTTP 200.
      ↓
SINK
  The server reflects `<svg><animatetransform onbegin=alert(1)>` directly
  into the HTML response body without output encoding.
      ↓
BROWSER BEHAVIOR
  1. The browser parses the `<svg>` container and its child `<animatetransform>` element.
  2. By default, SVG SMIL animations begin immediately upon rendering (`begin="0s"`).
  3. When the animation timeline starts, the `onbegin` event fires automatically.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1)`) upon page load.
```

---

## Step-by-Step Walkthrough

### 1. Fuzzing Allowed Tags
1. Captured the `GET /?search=test` request in Burp Proxy and sent it to **Burp Intruder**.
2. Set the payload marker inside angle brackets:
   ```http
   GET /?search=%3C§test§%3E HTTP/2
   ```
3. Used the HTML tags list from the PortSwigger XSS Cheat Sheet and started the attack.
4. Observed that only `<svg>`, `<animatetransform>`, `<title>`, and `<image>` returned `HTTP/2 200 OK` (while other tags returned `400 Bad Request - "Tag is not allowed"`).

### 2. Fuzzing Allowed Event Handlers on `<animatetransform>`
1. Updated the Intruder position to test event attributes on `<animatetransform>` nested inside `<svg>`:
   ```http
   GET /?search=%3Csvg%3E%3Canimatetransform%20§onload§=1%3E HTTP/2
   ```
2. Loaded the event handlers list from the PortSwigger XSS Cheat Sheet.
3. Identified that **`onbegin`** returned `HTTP/2 200 OK`.

### 3. Executing the Payload
Submitted the following payload in the search box (or directly via the `search` URL parameter):

```html
<svg><animatetransform onbegin=alert(1)>
```

URL:
```text
https://LAB-HOST/?search=%3Csvg%3E%3Canimatetransform+onbegin%3Dalert(1)%3E
```

The browser rendered the SVG animation element, immediately fired the `onbegin` event, executed `alert(1)`, and solved the lab.

---

## Key Takeaways & Remediation

### Why SVG Elements Are Dangerous in Allowlists / Blocklists
Developers often permit `<svg>` tags to allow inline vector icons without realizing that SVG supports rich sub-elements (such as `<script>`, `<foreignObject>`, `<animate>`, `<animatetransform>`, `<set>`) and SMIL animation lifecycle events (`onbegin`, `onend`, `onrepeat`) that execute JavaScript automatically without user interaction.

### Remediation
- **Context-Aware HTML Encoding:** Encode all user-controlled input before reflecting it into HTML (`<` → `&lt;`, `>` → `&gt;`).
- **Sanitize SVG Markup Strictly:** If inline SVG must be supported, use a dedicated sanitizer like DOMPurify, which strips dangerous SVG animation tags (`<animate>`, `<animatetransform>`, `<set>`) and event attributes (`onbegin`, etc.) by default. 
