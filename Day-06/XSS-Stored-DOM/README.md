# Stored DOM XSS

**Platform:** PortSwigger Web Security Academy  
**Category:** Cross-Site Scripting (Stored DOM XSS)  
**Tools:** Web Browser, Browser Developer Tools, JavaScript  
**Status:** ✅ Solved  
**Challenge:** 30 Days of Web Security — Day 05, Lab 04

**Lab:** [Stored DOM XSS](https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-dom-xss-stored)

## 1. Objective

Identify and exploit a stored DOM-based XSS vulnerability in the application's blog comment functionality.

The goal was to bypass an incorrectly implemented HTML escaping function and execute JavaScript in the browser.

## 2. Attack Scenario

An attacker discovers that the application allows users to submit comments on blog posts.

The server stores these comments, and client-side JavaScript later retrieves and displays them.

The application attempts to prevent XSS by replacing dangerous HTML characters. However, its escaping function only replaces the first occurrence of each character.

An attacker can exploit this weakness by submitting a specially crafted comment.

When another visitor opens the affected blog post, the application's JavaScript processes the stored comment and inserts active HTML into the page.

This allows attacker-controlled JavaScript to execute in the context of the vulnerable website.

## 3. Identifying the Vulnerability

I inspected the JavaScript responsible for displaying blog comments.

I found the following function:

```javascript
function escapeHTML(html) {
    return html.replace('<', '&lt;').replace('>', '&gt;');
}
```

The function attempts to encode angle brackets before displaying user-controlled content.

However, JavaScript's `replace()` method only replaces the first occurrence when its search argument is a string.

For example:

```javascript
"apple apple".replace("apple", "orange")
```

Result:

```text
orange apple
```

Therefore, additional `<` and `>` characters remain unescaped.

## 4. Testing the Escaping Function

Before attempting JavaScript execution, I tested whether I could bypass the filter and inject HTML.

I submitted the following comment:

```html
<><b>DOM-TEST-2026</b>
```

The escaping function transformed it into:

```html
&lt;&gt;<b>DOM-TEST-2026</b>
```

The initial angle brackets were encoded, but the `<b>` element remained intact.

**Observation:** The browser displayed `<>` followed by **DOM-TEST-2026** in bold.

This confirmed that the escaping function did not neutralize all HTML markup.

At this stage, I had demonstrated HTML injection but not JavaScript execution.

## 5. Proof of Concept

After confirming the escaping weakness, I submitted:

```html
<><img src=1 onerror=alert(1)>
```

### Payload Breakdown

| Component | Purpose |
|---|---|
| `<>` | Consumes the first `<` and `>` replacements |
| `<img>` | Creates an HTML image element |
| `src=1` | References an image that fails to load |
| `onerror` | Runs when the image loading fails |
| `alert(1)` | Demonstrates JavaScript execution |

After the vulnerable escaping function processes the comment, the resulting HTML resembles:

```html
&lt;&gt;<img src=1 onerror=alert(1)>
```

The initial angle brackets are displayed as text.

However, the remaining `<img>` element is interpreted as HTML.

When the image fails to load, its `onerror` handler executes.

**Result: The browser executed `alert(1)`, and the lab was marked as Solved.**

## 6. Attack Flow

```text
Attacker submits malicious comment
                 |
                 v
Server stores the comment
                 |
                 v
Victim opens the blog post
                 |
                 v
Client-side JavaScript loads comments
                 |
                 v
escapeHTML() processes the stored input
                 |
                 v
Only the first angle brackets are encoded
                 |
                 v
Remaining HTML is inserted into the DOM
                 |
                 v
Browser creates an image element
                 |
                 v
Image loading fails
                 |
                 v
onerror executes alert(1)
```

Unlike a reflected XSS attack, the attacker does not need to send each victim a specially crafted URL.

The malicious content remains stored in the application's comment system.

## 7. Root Cause

The application relies on an incomplete HTML escaping function.

The following code:

```javascript
html.replace('<', '&lt;').replace('>', '&gt;')
```

does not encode every occurrence of the dangerous characters.

As a result, attacker-controlled HTML can survive the escaping process and become active when inserted into the DOM.

The vulnerable data flow is:

**Stored user input → Incomplete escaping → DOM HTML insertion → JavaScript execution**

This demonstrates why custom escaping functions can be dangerous when they do not correctly handle all relevant characters and contexts.

## 8. Security Impact

Depending on the application's functionality and security controls, stored DOM XSS could allow an attacker to:

- Execute JavaScript in the vulnerable website's origin.
- Access information available to JavaScript.
- Modify content displayed to visitors.
- Perform actions through an authenticated user's browser.
- Display deceptive interface elements.

Because the payload is stored, multiple visitors may be affected when viewing the vulnerable page.

**Confirmed impact:** JavaScript execution through `alert(1)`.

Credential theft, session theft, and account takeover were not demonstrated.

## 9. Remediation

The application should avoid treating user comments as executable HTML.

Recommended improvements include:

- Use `textContent` to display plain-text comments.
- Avoid inserting untrusted content through HTML-parsing DOM APIs.
- If rich HTML is required, use a well-maintained HTML sanitizer.
- Avoid relying on custom escaping functions.
- Apply context-appropriate output encoding.
- Use a restrictive Content Security Policy (CSP) as defense in depth.

### Safer Rendering Example

Instead of generating HTML from untrusted content:

```javascript
commentElement.innerHTML = userComment;
```

Use:

```javascript
commentElement.textContent = userComment;
```

This displays the comment as text instead of interpreting it as HTML.

## 10. Key Takeaways

This laboratory demonstrated that:

- Stored DOM XSS combines persistent attacker-controlled data with unsafe client-side rendering.
- A security function can exist but still be incorrectly implemented.
- JavaScript `replace()` only replaces the first matching string occurrence unless a global replacement mechanism is used.
- Extra characters can sometimes bypass incomplete escaping.
- Testing harmless HTML injection is useful before attempting JavaScript execution.
- Understanding the exact behavior of defensive code is essential during vulnerability assessment.

**Main lesson:** Security controls must be tested for correctness, not simply assumed to work because they are present.

---

**Environment:** PortSwigger Web Security Academy  
**Scope:** Authorized educational laboratory only.
