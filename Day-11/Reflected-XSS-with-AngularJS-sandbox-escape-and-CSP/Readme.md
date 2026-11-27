# Lab: Reflected XSS with AngularJS sandbox escape and CSP

## Overview

- **Category:** Cross-Site Scripting (AngularJS Sandbox Escape / CSP Bypass)
- **Difficulty:** Expert
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This Expert-level lab combines a reflected HTML injection vulnerability in the search parameter with an AngularJS 1.4.4 sandbox and a strict Content Security Policy (`script-src 'self'`). Because CSP blocks standard inline scripts, `eval()`, and the `Function` constructor, traditional XSS payloads and `Function()`-based AngularJS sandbox escapes fail. However, since `angular.js` itself is loaded from `'self'`, AngularJS operates in its CSP-compatible parser mode. By injecting an `<input>` element with an `ng-focus` directive, triggering autofocus via a URL fragment (`#x`), and piping `$event.composedPath()` into the `orderBy` filter, we expose the `window` object and execute `alert(document.cookie)`.

---

## Scenario & Mental Model

```text
GOAL
  Bypass both the Content Security Policy and the AngularJS 1.4.4 sandbox to
  execute alert(document.cookie) in the user's browser
      ↓
WHY STANDARD XSS & EVAL-BASED ESCAPES FAIL
  1. CSP (`script-src 'self'`) blocks `<script>`, HTML `on*` attributes (`onfocus`),
     and dynamic code evaluation (`eval()`, `new Function()`).
  2. However, `angular.js` is hosted on `'self'`, so the browser permits AngularJS
     to execute and parse its own `ng-*` attributes using its internal CSP AST parser.
      ↓
STEP 1: Zero-Click Trigger via AngularJS `ng-focus`
  Injecting `<input id=x ng-focus=...>` and appending `#x` to the URL causes the
  browser to automatically focus the input on load, firing AngularJS's `ng-focus`
  handler without triggering a CSP violation.
      ↓
STEP 2: Reaching `window` via `$event.composedPath()`
  Inside `ng-focus`, AngularJS exposes the native DOM event object as `$event`.
  Calling `$event.composedPath()` returns the array of ancestor event targets:
  `[input#x, ..., document, Window]`, where the final element is the real `window` object!
      ↓
STEP 3: Executing `alert(document.cookie)` via `orderBy`
  Piping the `$event.composedPath()` array into `| orderBy: '(z=alert)(document.cookie)'`
  evaluates the filter expression against each element in the path array as the context scope.
  When `orderBy` evaluates the expression against the `Window` element, `alert` resolves
  to `window.alert` and invokes `alert(document.cookie)` without using `eval()`.
      ↓
OUTCOME
  Arbitrary JavaScript execution (`alert(document.cookie)`) under strict CSP → Solved!
```

---

## Step-by-Step Walkthrough

### 1. Analyzing the CSP and AngularJS Context
Inspected the search response (`GET /?search=test`) in Burp Suite:
- The body tag belongs to an AngularJS application (`ng-app`).
- The response enforces a strict Content Security Policy allowing scripts only from `'self'` (blocking inline event handlers and `unsafe-eval`).

### 2. Constructing the CSP-Compatible Sandbox Escape
1. Used `<input id=x ng-focus="...">` combined with `#x` in the URL hash to trigger focus automatically upon page load.
2. In modern Chromium browsers (where legacy `event.path` has been removed), used `$event.composedPath()` to retrieve the DOM propagation path array containing `window`.
3. Passed the array into AngularJS's `orderBy` filter to evaluate `(z=alert)(document.cookie)` against the `window` object:

```html
<input id=x ng-focus=$event.composedPath()|orderBy:'(z=alert)(document.cookie)'>#x
```

### 3. Delivering the Redirect
Configured the testing server **Body** with a top-level navigation to the crafted URL:

```html
<script>
location = "https://LAB-HOST/?search=%3Cinput%20id=x%20ng-focus=$event.composedPath()|orderBy:%27(z=alert)(document.cookie)%27%3E#x";
</script>
```

Saved and delivered the page to the simulated user, triggering `alert(document.cookie)` and solving the lab.

---

## Key Takeaways & Remediation

### Why Hosting AngularJS on `'self'` Weakens `script-src 'self'`
A Content Security Policy that restricts `script-src` to `'self'` assumes that only trusted static JavaScript files hosted on the origin can execute. However, client-side template engines like AngularJS include their own expression parser capable of interpreting arbitrary HTML attributes (`ng-focus`, `ng-init`, `{{...}}`) as executable logic without calling `eval()`.

### Remediation
- **HTML Output Encoding:** Always HTML-encode user input (`<` → `&lt;`, `>` → `&gt;`) before reflecting it inside the document so attackers cannot inject new DOM elements or `ng-*` directives.
- **Isolate `ng-app` Scope / Use `ng-non-bindable`:** Never render untrusted user content inside an active `ng-app` container without marking the container with `ng-non-bindable`.
