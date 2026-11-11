# DOM XSS in `document.write()` Inside a Select Element

**Platform:** PortSwigger Web Security Academy  
**Difficulty:** Practitioner  
**Category:** Cross-Site Scripting (DOM-based XSS)  
**Tools:** Web Browser, Browser Developer Tools  
**Status:** ✅ Solved  
**Challenge:** 30 Days of Web Security — Day 04

## 1. Objective

Identify and exploit a DOM-based XSS vulnerability in a product stock checker.

The application uses `document.write()` to insert user-controlled URL data into a `<select>` element.

**Lab:** [DOM XSS in document.write sink using source location.search inside a select element](https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-document-write-sink-inside-select-element)

## 2. Attack Scenario

An attacker discovers that a product page accepts a `storeId` query parameter.

The page's JavaScript reads this parameter and uses it to dynamically generate an option in a stock checker dropdown.

Because the application does not safely handle the input before inserting it into HTML, an attacker can craft a URL that breaks out of the `<select>` element.

If a victim visits the crafted URL, the browser executes attacker-controlled JavaScript within the vulnerable website's origin.

## 3. Initial Testing

I opened a product page and added a test parameter to its URL:

```text
/product?productId=1&storeId=TESTSTORE2026
```

After loading the page, `TESTSTORE2026` appeared as a new option in the stock checker dropdown.

I inspected the page using **Browser Developer Tools → Elements** and confirmed that the value was inserted inside the `<select>` element.

This demonstrated that the `storeId` URL parameter influenced the page's DOM.

## 4. Source and Sink

**Source:** `location.search`

The application retrieves the `storeId` parameter from the page URL.

**Sink:** `document.write()`

JavaScript uses the retrieved value when generating HTML for the stock checker.

The vulnerable behavior can be represented by the following simplified example:

```javascript
const storeId = new URLSearchParams(location.search).get('storeId');

document.write('<select name="storeId">');
document.write('<option>' + storeId + '</option>');
document.write('</select>');
```

This example illustrates the unsafe data flow rather than reproducing the complete application source.

The security problem is that attacker-controlled data is interpreted as HTML markup.

## 5. Proof of Concept

I changed the `storeId` parameter to the following payload:

```html
"></select><img src=1 onerror=alert(1)>
```

Example request URL:

```text
/product?productId=1&storeId="></select><img%20src=1%20onerror=alert(1)>
```

### Payload Breakdown

- `">` — attempts to terminate the surrounding HTML fragment or attribute context.
- `</select>` — closes the dropdown element.
- `<img src=1>` — creates an image element with an invalid image source.
- `onerror=alert(1)` — executes JavaScript when the image fails to load.

The critical step is escaping the `<select>` context so that the browser can interpret the injected `<img>` element as active HTML outside the dropdown.

**Result:** The browser displayed `alert(1)`, and the laboratory was marked as **Solved**.

## 6. Attack Flow

1. The attacker creates a crafted product URL containing the malicious `storeId` value.
2. The victim opens the URL.
3. The product page loads its JavaScript.
4. JavaScript reads the `storeId` parameter through `location.search`.
5. The application passes this value into `document.write()`.
6. The payload closes the `<select>` element and injects an `<img>` element.
7. The image fails to load, triggering the `onerror` handler.
8. The attacker's JavaScript executes in the vulnerable website's origin.

**Confirmed impact:** JavaScript execution through a DOM-based XSS vulnerability.

## 7. Root Cause

The application constructs HTML using unsanitized, attacker-controlled data from a URL parameter.

The vulnerable data flow is:

**`location.search` → `document.write()` → HTML injection → JavaScript execution**

The HTML parser context is important because the injected data is initially placed inside a `<select>` element.

The attacker must escape this context before injecting an executable HTML element.

## 8. Security Impact

Depending on the application's permissions and security controls, this vulnerability could allow an attacker to:

- Execute JavaScript in the vulnerable website's origin.
- Read information available to JavaScript on the page.
- Modify the displayed content.
- Perform actions using the victim's authenticated browser.
- Display deceptive forms or interface elements.

**Scope of this proof of concept:** Execution of `alert(1)` only.

Credential theft, session theft, and account takeover were not demonstrated.

## 9. Remediation

- Avoid using `document.write()` with untrusted data.
- Create dropdown options using safe DOM APIs.
- Assign user-controlled values using `textContent` and DOM properties.
- Validate `storeId` against a list of legitimate store identifiers.
- Apply a restrictive Content Security Policy (CSP) as defense in depth.

### Example of Safer DOM Manipulation

```javascript
const storeId = new URLSearchParams(location.search).get('storeId');

const select = document.querySelector('select[name="storeId"]');

const option = document.createElement('option');
option.value = storeId;
option.textContent = storeId;

select.appendChild(option);
```

Using `textContent` prevents the supplied value from being interpreted as HTML markup.

## 10. Key Takeaways

This lab demonstrated that:

- URL query parameters can be sources of DOM-based XSS.
- `document.write()` becomes dangerous when it processes untrusted input.
- HTML parser context affects exploit construction.
- Escaping a `<select>` element can allow injection of active HTML.
- An image's `onerror` event can demonstrate JavaScript execution.
- Understanding the source, sink, and HTML context is more valuable than memorizing individual payloads.

**Main lesson:** The same vulnerable JavaScript sink can require different payloads depending on where the input appears in the document.

---

**Environment:** PortSwigger Web Security Academy  
**Scope:** Authorized educational laboratory only.
