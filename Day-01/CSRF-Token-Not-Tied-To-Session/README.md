CSRF — Token Is Not Tied to User Session

Platform: PortSwigger Web Security Academy
Difficulty: Practitioner
Category: Cross-Site Request Forgery (CSRF)
Tools: Burp Suite, Burp Repeater, HTML, PortSwigger Exploit Server
Status: ✅ Solved
Challenge: 30 Days of Web Security — Day 01

1. Objective

The objective of this lab was to identify and exploit a CSRF vulnerability caused by improper association between CSRF tokens and user sessions.

The application generates CSRF tokens but accepts a valid token issued to a different user.

This makes it possible for an attacker to obtain a token from their own account and use it in a CSRF attack against another authenticated user.

2. Attack Scenario

An attacker wants to change the email address associated with a victim's account.

The attacker has access to their own account on the vulnerable application.

The attacker does not know the victim's password, session cookie, or CSRF token.

However, the attacker discovers that the server validates whether a CSRF token is valid without verifying that it belongs to the current user's session.

The attacker can therefore:

Log in to their own account.
Obtain a valid CSRF token.
Create a malicious HTML page containing that token.
Convince an authenticated victim to open the page.
Cause the victim's browser to submit an email change request.

If the browser sends the victim's session cookie and the request is accepted, the application may change the victim's email address without their consent.

3. Testing Environment

The laboratory provided two test accounts:

Account	Role
wiener	First authenticated user
carlos	Second authenticated user

I used these accounts to test whether the application's CSRF tokens were bound to their respective sessions.

4. Initial Request Analysis

I logged in as wiener and inspected the email change functionality using Burp Suite.

The request had the following structure:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<WIENER_SESSION>
Content-Type: application/x-www-form-urlencoded

email=test%40example.net&csrf=<WIENER_CSRF_TOKEN>

I then opened a separate private browsing session and logged in as carlos.

The second account had a different session cookie and CSRF token.

This provided two independent authenticated sessions for testing.

5. Testing Token-to-Session Binding

The next step was to determine whether the server would accept a CSRF token from a different account.

I constructed a request containing:

The session cookie belonging to wiener.
A CSRF token obtained from carlos.
A new test email address.

The modified request had the following structure:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<WIENER_SESSION>
Content-Type: application/x-www-form-urlencoded

email=csrf-lab04%40example.net&csrf=<CARLOS_CSRF_TOKEN>
Initial Result

My first attempt returned:

Invalid CSRF token

The laboratory uses single-use CSRF tokens, so the result required further investigation.

I obtained a fresh CSRF token from the HTML response of the carlos account page without submitting the email change form.

Successful Result

I repeated the test using the fresh token.

The server accepted the request, and the email address of wiener changed successfully.

This confirmed that the server did not enforce proper binding between the CSRF token and the authenticated user's session.

6. Cross-Site Exploitation

After confirming the server-side vulnerability, I created an HTML proof of concept using the PortSwigger Exploit Server.

The proof of concept included a fresh CSRF token obtained from the attacker's test account.

Proof of Concept
<!DOCTYPE html>
<html>
<body>

<form action="https://<LAB-HOST>/my-account/change-email"
      method="POST">

    <input type="hidden"
           name="email"
           value="csrf-lab04-victim@example.net">

    <input type="hidden"
           name="csrf"
           value="<FRESH_ATTACKER_CSRF_TOKEN>">

</form>

<script>
    document.forms[0].submit();
</script>

</body>
</html>

The HTML page automatically submits the form when opened.

The attacker supplies their own valid CSRF token.

The victim's browser supplies the victim's session cookie when permitted by the browser's cookie policies.

Why the Attack Works

The vulnerable application checks whether the submitted CSRF token is valid but fails to verify that the token belongs to the authenticated user making the request.

As a result, the application can accept a request containing:

Victim's session cookie
+
Attacker's valid CSRF token

The attacker does not need to steal the victim's session cookie.

7. Exploit Delivery and Verification

I hosted the proof of concept on the PortSwigger Exploit Server.

During testing, I encountered a DNS resolution error caused by an incomplete laboratory hostname.

After correcting the full laboratory domain, I stored the exploit and used the Deliver to victim feature.

Result: PortSwigger marked the laboratory as Solved.

This confirmed that the vulnerability was exploitable through the simulated victim's browser.

8. Root Cause

The root cause was insufficient server-side validation of CSRF tokens.

Although the application generated tokens and validated their values, it did not ensure that each token belonged to the session performing the sensitive operation.

A CSRF token must not be treated as sufficient proof of authorization merely because it is valid.

9. Security Impact

An attacker who has their own account could obtain a valid CSRF token and use it to construct a cross-site request targeting another authenticated user.

In this laboratory, the confirmed impact was unauthorized modification of the victim's email address.

Depending on the application's email verification and password recovery processes, this type of vulnerability could contribute to account compromise.

A complete account takeover was not independently demonstrated.

10. Remediation

Recommended defenses include:

Generate unpredictable CSRF tokens using a cryptographically secure random number generator.
Bind CSRF tokens securely to the user's authenticated session.
Reject CSRF tokens that belong to another session.
Enforce CSRF validation on all relevant state-changing requests.
Use appropriate SameSite cookie settings as defense in depth.
Validate request origins where appropriate.
Require additional verification for sensitive account changes.

Key principle: A valid CSRF token is not sufficient if the application does not verify that the token belongs to the current user's session.

11. Evidence

Recommended evidence for this write-up:

Original email change request from wiener.
CSRF token obtained from carlos.
Modified request combining the wiener session and carlos token.
Confirmation that the email address changed.
HTML proof of concept hosted on the Exploit Server.
PortSwigger laboratory completion screen.

All session identifiers and CSRF token values should be redacted from published screenshots.

12. Key Takeaways

This laboratory taught me that implementing CSRF tokens is not enough. The application must also validate them correctly.

I practiced:

Working with two independent authenticated sessions.
Inspecting CSRF tokens in HTML responses.
Testing token-to-session binding.
Identifying the effect of single-use CSRF tokens.
Constructing a cross-site HTML proof of concept.
Troubleshooting DNS errors during exploitation.
Verifying the complete attack flow.
Documenting the vulnerability and its security impact.

Environment: PortSwigger Web Security Academy
Testing scope: Authorized educational laboratory only.
