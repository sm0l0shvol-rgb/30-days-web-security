# DOM-Based XSS in `document.write()` Using `location.search`

**Platform:** PortSwigger Web Security Academy  
**Difficulty:** Apprentice  
**Category:** Cross-Site Scripting (DOM-based XSS)  
**Tools:** Browser Developer Tools, Burp Suite Community Edition  
**Status:** ✅ Solved  
**Challenge:** 30 Days of Web Security — Day 04

## 1. Objective

Identify and exploit a DOM-based XSS vulnerability caused by passing user-controlled URL data into an unsafe JavaScript sink.

**Lab:** [DOM XSS in `document.write` sink using source `location.search`](https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-document-write-sink)

## 2. Attack Scenario

An attacker discovers that the application's search page uses JavaScript to read data from the URL and dynamically generate HTML.

The JavaScript does not safely handle the search parameter before passing it into `document.write()`.

The attacker can construct a malicious search URL and send it to a victim.

When the victim opens the URL, the page's JavaScript processes the attacker-controlled input and generates executable HTML in the browser.

## 3. Initial Reconnaissance

I opened the search page and submitted a harmless test value:

```text
dom-test-2026
```

Using **Browser Developer Tools → Elements**, I inspected where the value appeared in the DOM.

I first found it inside an `<h1>` element.

After searching for additional occurrences, I discovered that the same value was also inserted into the `src` attribute of an `<img>` element.

A simplified example:

```html
<img src="/resources/images/tracker.gif?searchTerms=dom-test-2026">
```

This indicated that user-controlled data was being used to construct an HTML attribute.

## 4. Source and Sink

The relevant DOM XSS components were:

**Source:** `location.search`

This provides access to the query string in the current page URL.

**Sink:** `document.write()`

This writes HTML into the document.

The vulnerable behavior can be represented conceptually as:

```javascript
document.write(
    '<img src="/resources/images/tracker.gif?searchTerms='
    + searchTerm + '">'
);
```

If attacker-controlled input is inserted into this string without appropriate protection, it can break out of the HTML attribute.

## 5. Proof of Concept

I submitted the following payload through the search functionality:

```html
"><svg onload=alert(1)>
```

The payload works by:

1. Closing the existing `src` attribute with `"`.
2. Closing the `<img>` tag with `>`.
3. Creating an SVG element.
4. Using the `onload` event handler to execute `alert(1)`.

The resulting HTML can be illustrated as:

```html
<img src="/resources/images/tracker.gif?searchTerms=">
<svg onload=alert(1)>
```

**Result:** The browser displayed a JavaScript alert, and the laboratory was marked as **Solved**.

This confirmed that user-controlled data reached an unsafe DOM sink and caused JavaScript execution.

## 6. Attack Flow

```text
Attacker creates a malicious search URL
                  |
                  v
Victim opens the URL
                  |
                  v
Page JavaScript reads location.search
                  |
                  v
User input reaches document.write()
                  |
                  v
Input breaks out of the img src attribute
                  |
                  v
Browser creates an SVG element
                  |
                  v
onload executes attacker-controlled JavaScript
```

The attacker does not need to directly modify the application's JavaScript files.

Instead, the attacker manipulates data that the existing JavaScript processes insecurely.

## 7. Root Cause

The application passes untrusted data from `location.search` into `document.write()` without safely handling the HTML attribute context.

This allows attacker-controlled text to be interpreted as HTML markup.

The vulnerability results from an unsafe data flow:

**Untrusted source → Unsafe sink → JavaScript execution**

## 8. Security Impact

Depending on the website's functionality and security controls, DOM-based XSS can allow an attacker to:

- Execute JavaScript within the vulnerable website's origin.
- Access page information available to JavaScript.
- Modify displayed content.
- Perform actions using the victim's authenticated browser.
- Display deceptive interface elements.

**Confirmed impact:** JavaScript execution through `alert(1)`.

Cookie theft and account takeover were not demonstrated.

## 9. Remediation

- Avoid passing untrusted input directly into `document.write()`.
- Use safe DOM APIs, such as `textContent`, for plain-text content.
- Set attributes through appropriate DOM APIs instead of building HTML strings.
- Validate inputs and use context-appropriate encoding when constructing HTML.
- Apply a restrictive Content Security Policy (CSP) as defense in depth.

## 10. Key Takeaways

This laboratory taught me how to identify DOM-based XSS by tracing data from a source to a sink.

I learned that:

- `location.search` can contain attacker-controlled input.
- `document.write()` can be dangerous when used with untrusted data.
- The HTML context determines which payload is required.
- Breaking out of an attribute can allow injection of a new HTML element.
- The live DOM in Browser Developer Tools can reveal changes made by JavaScript.
- DOM XSS can occur in client-side JavaScript without requiring the server to embed the payload directly into its initial HTML response.

**Main lesson:** User-controlled data must never be treated as trusted HTML merely because it is processed by the application's own JavaScript.

---

**Environment:** PortSwigger Web Security Academy  
**Scope:** Authorized educational laboratory only.
