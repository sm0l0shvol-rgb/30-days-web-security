# DOM XSS in `innerHTML` Sink Using `location.search`

**Platform:** PortSwigger Web Security Academy  
**Difficulty:** Apprentice  
**Category:** Cross-Site Scripting (DOM-based XSS)  
**Tools:** Web Browser, Browser Developer Tools  
**Status:** ✅ Solved  
**Challenge:** 30 Days of Web Security — Day 04

## 1. Objective

Identify and exploit a DOM-based XSS vulnerability caused by inserting user-controlled URL data into an unsafe `innerHTML` sink.

**Lab:** [DOM XSS in `innerHTML` sink using source `location.search`](https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-innerhtml-sink)

## 2. Attack Scenario

An attacker discovers that the application's search functionality uses client-side JavaScript to process a search parameter from the URL.

The application inserts the search value into the page using `innerHTML` without safely handling untrusted content.

An attacker can construct a malicious search URL and convince a victim to open it.

When the page loads, its JavaScript processes the malicious input and creates an HTML element containing an executable event handler.

The attacker's JavaScript then executes in the context of the vulnerable website.

## 3. Initial Testing

I submitted the following HTML markup through the search field:

```html
<b>DOM-TEST-2026</b>
```

**Observation:** The search text appeared in bold.

This indicated that the application interpreted the submitted input as HTML markup rather than rendering it as plain text.

However, this observation alone did not confirm JavaScript execution.

## 4. Source and Sink

The vulnerable data flow involved:

**Source:** `location.search`

This allows client-side JavaScript to access the current page's URL query string.

**Sink:** `innerHTML`

This property parses a string as HTML and inserts the resulting elements into the DOM.

A simplified example of the unsafe pattern:

```javascript
const searchTerm = new URLSearchParams(location.search).get('search');

document.getElementById('searchResults').innerHTML = searchTerm;
```

When untrusted input reaches `innerHTML` without appropriate protection, it may create executable HTML elements or event handlers.

## 5. Proof of Concept

I submitted the following payload through the search field:

```html
<img src=x onerror=alert(1)>
```

### Payload Breakdown

- `<img>` creates an HTML image element.
- `src=x` points to an image resource that fails to load.
- `onerror` is an event handler triggered when the image cannot be loaded.
- `alert(1)` is the JavaScript executed by the event handler.

When the application inserted the payload through `innerHTML`, the browser created an image element.

The image failed to load, triggering the `onerror` event and executing the injected JavaScript.

**Result:** The browser displayed `alert(1)`, and the laboratory was marked as **Solved**.

## 6. Attack Flow

1. The attacker creates a crafted search URL containing the HTML payload.
2. The victim opens the URL.
3. The page's JavaScript reads the search parameter from `location.search`.
4. The application inserts the value into the DOM through `innerHTML`.
5. The browser creates an `<img>` element with an `onerror` event handler.
6. The image fails to load.
7. The event handler executes the attacker's JavaScript.

**Confirmed impact:** JavaScript execution in the vulnerable website's browser context.

## 7. Why Not Simply Use `<script>`?

A key characteristic of `innerHTML` is that `<script>` elements inserted through this property generally do not execute.

However, `innerHTML` is still dangerous when used with untrusted input because event handlers in dynamically created elements can execute.

This is why the following payload was effective:

```html
<img src=x onerror=alert(1)>
```

The attack relied on an HTML event handler instead of an injected `<script>` element.

## 8. Root Cause

The application passes attacker-controlled data from `location.search` into an HTML-parsing sink without adequate protection.

The vulnerable data flow is:

**Untrusted URL parameter → `innerHTML` → HTML element creation → JavaScript execution**

The application fails to distinguish between user-provided text and trusted HTML markup.

## 9. Security Impact

Depending on application permissions and security controls, DOM-based XSS can potentially allow an attacker to:

- Execute JavaScript within the affected website's origin.
- Read page data accessible to JavaScript.
- Manipulate displayed content.
- Perform actions through an authenticated victim's browser.
- Display deceptive interface elements.

**Scope of this proof of concept:** Execution of `alert(1)` only. Credential theft, session theft, and account takeover were not demonstrated.

## 10. Remediation

- Avoid using `innerHTML` with untrusted data.
- Use `textContent` when displaying plain-text input.
- Prefer safe DOM APIs for creating elements and assigning attributes.
- If HTML input is necessary, use a well-maintained HTML sanitizer.
- Apply context-appropriate output encoding where relevant.
- Use a restrictive Content Security Policy (CSP) as defense in depth.

### Example of Safer Rendering

```javascript
const searchTerm = new URLSearchParams(location.search).get('search');

document.getElementById('searchResults').textContent = searchTerm;
```

Unlike `innerHTML`, `textContent` displays the provided value as text rather than interpreting it as HTML.

## 11. Key Takeaways

This lab demonstrated that:

- User-controlled URL parameters can become DOM XSS sources.
- `innerHTML` is an unsafe sink when used with untrusted input.
- Rendering HTML successfully does not automatically prove JavaScript execution.
- Injected `<script>` tags generally do not execute through `innerHTML`.
- HTML event handlers can still execute JavaScript.
- The correct payload depends on the sink and the context in which the input is inserted.

**Main lesson:** A browser can execute attacker-controlled JavaScript when an application's own client-side code converts untrusted input into active HTML.

---

**Environment:** PortSwigger Web Security Academy  
**Scope:** Authorized educational laboratory only.
