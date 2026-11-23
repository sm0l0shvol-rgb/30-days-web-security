# Lab: Reflected XSS into a template literal with angle brackets, single, double quotes, backslash and backticks Unicode-escaped

## Overview

- **Category:** Cross-Site Scripting (Reflected XSS / JavaScript Template Literal Context)
- **Difficulty:** Practitioner
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab reflects user search input inside a JavaScript template literal (delimited by backticks `` `...` ``) within an inline `<script>` block. Although the application Unicode-escapes angle brackets (`<`, `>`), single quotes (`'`), double quotes (`"`), backslashes (`\`), and backticks (`` ` ``)—completely preventing string or tag breakout—it fails to escape the dollar sign (`$`) or curly braces (`{`, `}`). By leveraging JavaScript template literal embedded expressions (`${...}`), we execute arbitrary JavaScript directly from within the string without breaking out of the backticks.

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
  Input is reflected inside an inline `<script>` block within a backtick-delimited
  JavaScript template literal:
  var message = `0 search results for 'USER_INPUT'`;
  - `'`, `"`, `\`, `` ` ``, `<`, `>` are all Unicode-escaped (`\u0027`, `\u0022`,
    `\u005c`, `\u0060`, `\u003c`, `\u003e`).
  - Breaking out of the template literal or closing `</script>` is impossible.
  - However, `$` and `{` `}` are NOT escaped!
      ↓
INJECTION (Template Literal Interpolation)
  In ES6 JavaScript, template literals (`...`) automatically evaluate any
  JavaScript expression placed inside `${expression}` placeholders.
  Payload: ${alert(1)}
      ↓
SINK
  The server renders:
  var message = `0 search results for '${alert(1)}'`;
      ↓
BROWSER BEHAVIOR
  While constructing the `message` template literal string, the JavaScript engine
  evaluates the embedded expression `${alert(1)}`.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1)`) in the victim's browser context.
```

---

## Step-by-Step Walkthrough

### 1. Probing the Reflection Context and Unicode Escaping
Submitted a test probe containing all standard delimiters in the search box:

```text
test'"\`<>
```

Inspected the HTML response in Burp Suite:

```html
<script>
    var message = `0 search results for 'test\u0027\u0022\u005c\u0060\u003c\u003e'`;
    document.getElementById('searchMessage').innerText = message;
</script>
```

Observation:
- All six characters (`'`, `"`, `\`, `` ` ``, `<`, `>`) were converted to their corresponding `\u00XX` Unicode escape sequences.
- Furthermore, the string is written to the DOM via `innerText`, preventing HTML parsing at the DOM assignment stage.
- However, the string itself is defined inside backticks (`` `...` ``), meaning it is a JavaScript **template literal**.

### 2. Exploiting Template Literal Expression Interpolation
Injected a template literal placeholder expression directly in the search box:

```javascript
${alert(1)}
```

The server returned:

```html
<script>
    var message = `0 search results for '${alert(1)}'`;
    document.getElementById('searchMessage').innerText = message;
</script>
```

When the browser's JavaScript engine evaluated the template literal, it immediately executed `alert(1)` inside `${...}`, solving the lab.

---

## Key Takeaways & Remediation

### Why Backtick Escaping Alone Does Not Secure Template Literals
Unlike single-quoted (`'...'`) or double-quoted (`"..."`) strings in JavaScript, backtick template literals (`` `...` ``) support string interpolation via `${...}`. Even if an attacker cannot close the backtick delimiter, any unescaped `${...}` sequence inside the literal is parsed and executed as active JavaScript code.

### Remediation
- **Avoid Server-Side Interpolation into JS Template Literals:** Use standard quoted strings with JSON serialization or read values from `data-*` attributes.
- **Escape `$` and `{` in Template Literals:** If user input must be embedded inside a JavaScript template literal, escape `$` (`\$` or `\u0024`) and `{` (`\u007b`) in addition to backticks, backslashes, quotes, and angle brackets.
