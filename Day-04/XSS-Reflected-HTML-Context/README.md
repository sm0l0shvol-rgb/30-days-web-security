Reflected XSS into HTML Context with Nothing Encoded

Platform: PortSwigger Web Security Academy
Difficulty: Apprentice
Category: Cross-Site Scripting (XSS)
Tools: Burp Suite Community Edition, Web Browser
Status: ✅ Solved
Challenge: 30 Days of Web Security — Day 04

1. Objective

Identify a reflected cross-site scripting vulnerability in the application's search functionality and demonstrate JavaScript execution in the browser.

Lab: Reflected XSS into HTML context with nothing encoded

2. Attack Scenario

An attacker discovers that the application reflects a user-controlled search query into its HTML response without proper output encoding.

The attacker can create a specially crafted URL containing JavaScript and convince a victim to visit it.

When the victim opens the link, the application reflects the malicious input into the returned HTML. The victim's browser interprets it as executable code within the vulnerable website's origin.

3. Reconnaissance

I started by submitting a harmless test string through the search functionality:

xss-test-2026

Using Burp Suite → Proxy → HTTP history, I inspected the search request and its response.

The input appeared in the HTML response, confirming that the application reflected user-controlled data.

Reflection alone does not prove XSS, so further testing was required.

4. Proof of Concept

I submitted the following payload through the search box:

<script>alert(1)</script>

The application returned the submitted input in an HTML context without safely encoding the script tag.

A simplified example of the vulnerable response is:

<h1>Search results for: <script>alert(1)</script></h1>

The browser interpreted the injected <script> element as JavaScript and executed alert(1).

Result: A JavaScript alert appeared, and the laboratory was marked as Solved.

5. Attack Delivery

Because this is a reflected XSS vulnerability, the payload can be delivered through a specially crafted URL.

For example:

https://<LAB-HOST>/?search=%3Cscript%3Ealert%281%29%3C%2Fscript%3E

The attacker could share this URL with a victim.

If the victim opens the link:

The browser sends a GET request containing the search parameter.

The server reflects the parameter into its HTML response.

The browser parses the injected HTML.

The attacker's JavaScript executes in the vulnerable application's origin.

In this lab, JavaScript execution was demonstrated using alert(1). Delivery to a separate victim was not required.

6. Root Cause

The application inserts untrusted user input directly into an HTML context without appropriate output encoding.

The browser therefore cannot distinguish the injected script markup from legitimate page markup.

This creates a reflected XSS vulnerability.

7. Security Impact

Depending on the application's functionality and security controls, reflected XSS could allow an attacker to:

Read information available to JavaScript on the affected page.

Perform actions within the victim's authenticated session.

Modify the page content.

Display deceptive forms or interface elements.

Confirmed impact in this lab: Arbitrary JavaScript execution demonstrated by alert(1).

Session theft or account takeover was not demonstrated.

8. Remediation

Apply context-appropriate output encoding to untrusted data.

Render plain user-controlled text using safe APIs such as textContent rather than unsafe HTML insertion.

Avoid constructing executable HTML or JavaScript from untrusted input.

Use a restrictive Content Security Policy (CSP) as an additional layer of protection.

Keep session cookies protected with HttpOnly where appropriate.

9. Key Takeaways

This lab taught me that:

Reflected input is not automatically an XSS vulnerability.

The HTML context determines how injected input is interpreted.

An unencoded <script> element can execute when reflected into a vulnerable HTML response.

Reflected XSS generally requires a delivery mechanism, such as a crafted link.

XSS differs from CSRF because the attacker's JavaScript executes within the vulnerable website's origin.

Environment: PortSwigger Web Security Academy
Scope: Authorized educational laboratory only.
