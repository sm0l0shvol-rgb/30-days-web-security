# DOM XSS in jQuery Anchor `href` Attribute Using `location.search`

**Platform:** PortSwigger Web Security Academy  
**Category:** Cross-Site Scripting (DOM-based XSS)  
**Tools:** Web Browser, Browser Developer Tools, jQuery  
**Status:** ✅ Solved  
**Challenge:** 30 Days of Web Security — Day 04

**Lab:** [DOM XSS in jQuery anchor href attribute sink using location.search source](https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-jquery-href-attribute-sink)

## 1. Objective

Identify and exploit a DOM-based XSS vulnerability caused by assigning attacker-controlled URL data to an anchor element's `href` attribute.

The lab requires triggering `alert(document.cookie)` by clicking the **Back** link.

## 2. Attack Scenario

An attacker discovers that the website's Submit feedback page contains a Back link.

The page uses jQuery to update this link based on the `returnPath` parameter in the current URL.

Because the parameter is not properly validated, the attacker can supply a `javascript:` URL instead of a legitimate navigation path.

The attacker creates a crafted link and convinces a victim to open it.

When the victim clicks Back, the browser executes JavaScript within the vulnerable website's context.

## 3. Initial Testing

I opened the Submit feedback page and changed the `returnPath` parameter to:

```text
/TESTBACK2026
```

Using **Developer Tools → Elements**, I inspected the Back link.

I confirmed that its `href` attribute contained the supplied value:

```html
<a href="/TESTBACK2026">Back</a>
```

This demonstrated that the URL parameter controlled the link destination.

At this stage, I had confirmed the data flow, but not JavaScript execution.

## 4. Source and Sink

**Source:** `location.search`

The application reads the `returnPath` parameter from the URL query string.

**Sink:** jQuery `.attr('href', ...)`

The application assigns the parameter value to an existing anchor element.

A simplified example of the vulnerable behavior:

```javascript
const returnPath = new URLSearchParams(location.search).get('returnPath');

$('#backLink').attr('href', returnPath);
```

This is an illustrative example, not a complete copy of the application's source code.

The application fails to restrict the destination to safe URLs.

## 5. Proof of Concept

I changed the `returnPath` parameter to:

```javascript
javascript:alert(document.cookie)
```

The Back link's `href` attribute was updated to contain the JavaScript URL.

Example:

```html
<a href="javascript:alert(document.cookie)">Back</a>
```

I then clicked **Back**.

**Result:** The browser executed JavaScript, displayed an alert, and the laboratory was marked as **Solved**.

No cookie values were recorded or published.

## 6. Attack Flow

1. The attacker creates a crafted URL to the Submit feedback page.
2. The victim opens the URL.
3. The page's JavaScript reads the `returnPath` parameter.
4. jQuery assigns the value to the Back link's `href` attribute.
5. The victim clicks Back.
6. The browser executes the `javascript:` URL.
7. Attacker-controlled JavaScript runs in the context of the vulnerable website.

**Confirmed impact:** JavaScript execution through an attacker-controlled anchor destination.

## 7. Root Cause

The application trusts data from `location.search` when constructing a navigation link.

It does not ensure that the supplied destination uses an allowed URL scheme or points to an approved location.

The vulnerable data flow is:

**`location.search` → jQuery `.attr('href', ...)` → `javascript:` URL → JavaScript execution**

Unlike HTML injection through `innerHTML` or `document.write()`, this exploit does not require inserting a new HTML element.

The attacker changes the behavior of an existing link.

## 8. Security Impact

Depending on the application's security controls, successful exploitation may allow an attacker to:

- Execute JavaScript in the vulnerable website's origin.
- Access information available to JavaScript.
- Modify page content.
- Perform actions through an authenticated user's browser.
- Present deceptive interface elements.

The demonstrated payload uses `document.cookie`, which can read cookies accessible to JavaScript. Cookies marked `HttpOnly` are not accessible through this property.

**Scope of this proof of concept:** Browser-side JavaScript execution. Cookie exfiltration and account takeover were not demonstrated.

## 9. Remediation

- Never assign untrusted URL parameters directly to sensitive navigation destinations.
- Reject dangerous schemes such as `javascript:`.
- Prefer an allowlist of legitimate internal routes.
- Parse and validate URLs before using them as link destinations.
- Use Content Security Policy (CSP) as an additional protection layer.

## 10. Key Takeaways

This lab demonstrated that:

- DOM XSS does not always require injecting HTML tags.
- URL parameters can control existing DOM attributes.
- The `href` attribute can become dangerous when arbitrary URL schemes are permitted.
- `javascript:` URLs can execute code when activated.
- Some DOM XSS attacks require user interaction rather than executing automatically.
- Understanding the source, sink, and browser behavior is essential for identifying vulnerabilities.

**Main lesson:** Even a simple navigation link can become an XSS sink when the application accepts attacker-controlled destinations without validation.

---

**Environment:** PortSwigger Web Security Academy  
**Scope:** Authorized educational laboratory only.

*Sensitive session values have not been included.*
