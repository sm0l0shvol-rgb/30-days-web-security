# Stored XSS into HTML Context with Nothing Encoded

**Platform:** PortSwigger Web Security Academy  
**Difficulty:** Apprentice  
**Category:** Cross-Site Scripting (XSS)  
**Tools:** Web Browser, Burp Suite Community Edition  
**Status:** ✅ Solved  
**Challenge:** 30 Days of Web Security — Day 04

## 1. Objective

Identify and exploit a stored cross-site scripting vulnerability in the application's blog comment functionality.

The goal was to demonstrate that user-supplied JavaScript could be stored by the application and executed when a visitor opened the affected blog post.

**Lab:** [Stored XSS into HTML context with nothing encoded](https://portswigger.net/web-security/cross-site-scripting/stored/lab-html-context-nothing-encoded)

## 2. Attack Scenario

An attacker discovers that the application allows visitors to submit comments on blog posts.

The application stores these comments and later displays them without properly encoding the user-controlled HTML content.

The attacker submits a malicious comment containing JavaScript.

When another user opens the affected blog post, the browser interprets the stored script as part of the website's HTML and executes it in the vulnerable application's origin.

Unlike reflected XSS, this attack does not require the victim to open a specially crafted URL containing the payload.

## 3. Initial Testing

I opened a blog post and submitted a harmless test comment:

```text
stored-xss-test-2026
```

After submitting the comment, I reopened the blog post.

**Observation:** The comment remained visible after the page was reloaded.

This confirmed that the application stored user-controlled input.

However, storing a comment alone does not prove an XSS vulnerability.

## 4. Proof of Concept

I submitted a second comment containing:

```html
<script>alert(1)</script>
```

After returning to the blog post, the browser displayed a JavaScript alert containing the number `1`.

The laboratory was marked as **Solved**.

This confirmed that the application stored the payload and subsequently rendered it in an executable HTML context.

A simplified example of the vulnerable output is:

```html
<div class="comment">
    <script>alert(1)</script>
</div>
```

## 5. Attack Flow

1. The attacker opens a blog post and submits a comment containing JavaScript.
2. The application stores the malicious comment.
3. The victim later visits the same blog post.
4. The server includes the stored comment in the HTML response without appropriate output encoding.
5. The victim's browser parses the injected script element and executes it in the vulnerable website's origin.

**Confirmed result:** JavaScript execution through a stored blog comment.

## 6. Root Cause

The application fails to apply context-appropriate output encoding when displaying user-generated comments.

As a result, attacker-controlled HTML is interpreted as active page content rather than displayed as harmless text.

The core vulnerability is a failure to separate untrusted user content from executable HTML.

## 7. Security Impact

Depending on the application's security controls, stored XSS could allow an attacker to:

- Execute JavaScript in the context of the vulnerable website.
- Read information accessible to JavaScript on affected pages.
- Modify the content displayed to visitors.
- Perform actions through an authenticated victim's browser.
- Present misleading forms or interface elements.

**Scope of this proof of concept:** Execution of `alert(1)` only. Cookie theft, credential theft, and account takeover were not demonstrated.

## 8. Remediation

- Apply context-appropriate output encoding before rendering user-generated content.
- Display plain-text comments as text rather than interpreting them as HTML.
- Use safe rendering APIs such as `textContent` when working with the DOM.
- If rich HTML comments are required, sanitize them using a well-maintained HTML sanitizer.
- Implement a restrictive Content Security Policy (CSP) as defense in depth.
- Protect sensitive session cookies using `HttpOnly` where appropriate.

## 9. Key Takeaways

This laboratory demonstrated the difference between reflected and stored XSS.

I learned that:

- Stored user input is not automatically an XSS vulnerability.
- A vulnerability occurs when stored input is rendered in an unsafe executable context.
- Stored XSS can affect users who simply visit a page containing the malicious content.
- The attacker does not necessarily need to send each victim a specially crafted link.
- An alert popup can confirm JavaScript execution, but it does not demonstrate the full impact of a real-world attack.

---

**Environment:** PortSwigger Web Security Academy  
**Scope:** Authorized educational laboratory only.
