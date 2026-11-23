# Lab: Reflected XSS into HTML context with most tags and attributes blocked

## Overview

- **Category:** Cross-Site Scripting (Reflected XSS / WAF Bypass)
- **Difficulty:** Practitioner
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab contains a reflected XSS vulnerability in the search functionality, protected by a Web Application Firewall (WAF) that blocks most standard HTML tags and event handler attributes. By systematically fuzzing allowed tags and attributes, we discover that `<body>` and the `onresize` event handler bypass the filter, and we trigger it automatically without user interaction using an `<iframe>` on the Exploit Server.

---

## Attack Scenario & Mental Model

```text
ATTACKER GOAL
  Execute print() in the victim's browser without requiring user interaction
      ↓
VICTIM
  User visiting an attacker-controlled page on the Exploit Server
      ↓
DELIVERY
  An <iframe> embedding the vulnerable search URL that dynamically resizes
  itself upon loading (`onload="this.style.width='100px'"`)
      ↓
SOURCE
  URL query parameter: GET /?search=...
      ↓
WAF BYPASS
  Tag fuzzing reveals `<body>` is allowed (HTTP 200).
  Attribute fuzzing reveals `onresize` is allowed (HTTP 200).
  Payload: <body onresize=print()>
      ↓
SINK
  The server reflects the unescaped `<body onresize=print()>` tag directly
  into the HTML response body.
      ↓
BROWSER BEHAVIOR
  1. The browser merges the `onresize` attribute from the injected `<body>` tag
     onto the document's body.
  2. Once the `<iframe>` finishes loading, its `onload` handler changes the
     iframe's width to `100px`.
  3. The viewport change inside the iframe fires the `onresize` event automatically.
      ↓
IMPACT
  Arbitrary JavaScript execution (`print()`) in the victim's browser context.
```

---

## Step-by-Step Walkthrough

### 1. Probing the WAF
Submitting a standard XSS payload such as `<script>alert(1)</script>` or `<img>` in the search box resulted in a blocked response:

```http
HTTP/2 400 Bad Request
Content-Type: application/json; charset=utf-8

"Tag is not allowed"
```

### 2. Fuzzing for Allowed HTML Tags
1. Sent the `GET /?search=test` request to **Burp Intruder**.
2. Configured the payload position inside angle brackets:
   ```http
   GET /?search=%3C§test§%3E HTTP/2
   ```
3. Pasted the full list of HTML tags from the PortSwigger XSS Cheat Sheet and ran the attack.
4. Filtered responses by HTTP status code `200 OK`, discovering that the **`<body>`** tag was not blocked.

### 3. Fuzzing for Allowed Event Handlers
1. Updated the Burp Intruder payload position to fuzz event handler attributes on the `<body>` tag:
   ```http
   GET /?search=%3Cbody%20§onload§=1%3E HTTP/2
   ```
2. Pasted the list of HTML event attributes from the PortSwigger XSS Cheat Sheet.
3. Identified that **`onresize`** returned `HTTP/2 200 OK`.

### 4. Verifying Locally
Navigated to:

```text
https://LAB-HOST/?search=%3Cbody%20onresize=print()%3E
```

Manually resizing the browser window triggered the `print()` dialog.

### 5. Automating Delivery via Exploit Server
To trigger `onresize` automatically in the victim's browser without manual interaction, crafted an `<iframe>` on the **Exploit Server** that modifies its own width as soon as it finishes loading:

```html
<iframe src="https://LAB-HOST/?search=%3Cbody%20onresize=print()%3E" onload="this.style.width='100px'"></iframe>
```

Clicked **Store** and **Deliver exploit to victim** to solve the lab.

---

## Key Takeaways & Remediation

### Why Blacklist Filtering Fails
Relying on a blocklist of known dangerous HTML tags and event handlers is fragile. HTML specifications include dozens of tags and event handlers (such as `onresize`, `onpageshow`, `ontoggle`, or custom elements) that can be combined with external triggers like iframes to achieve zero-click XSS.

### Remediation
- **Context-Aware Output Encoding:** Always HTML-encode user-supplied input before reflecting it into an HTML context (`<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`, etc.).
- **Use Whitelists Instead of Blacklists:** If rich HTML input is strictly required, use a robust, actively maintained sanitizer (such as DOMPurify) configured with a strict allowlist of safe tags and attributes.
