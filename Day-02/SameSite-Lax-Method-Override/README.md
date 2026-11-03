SameSite Lax Bypass via Method Override

Platform: PortSwigger Web Security Academy
Difficulty: Practitioner
Category: Cross-Site Request Forgery (CSRF)
Tools: Burp Suite, Burp Repeater, HTML, JavaScript, Exploit Server
Status: ✅ Solved
Challenge: 30 Days of Web Security — Day 02

1. Objective

The objective of this laboratory was to bypass SameSite Lax cookie restrictions using an HTTP method override mechanism.

The application allows users to update their email addresses through a POST request.

Although SameSite Lax restrictions prevent session cookies from being included in ordinary cross-site POST requests, the application supports a method override parameter that makes the operation accessible through a top-level GET navigation.

2. Attack Scenario

An attacker wants to change the email address of an authenticated victim.

The attacker does not know the victim's credentials or session cookie.

A normal cross-site POST request is restricted because the victim's browser applies SameSite Lax cookie rules.

However, the attacker discovers that the application accepts the _method=POST parameter in a GET request.

This allows the attacker to trigger the email change functionality through a top-level GET navigation, where the browser can include the victim's session cookie.

3. Initial Request Analysis

I logged into the laboratory as wiener and captured an email change request using Burp Suite.

The original request used the POST method:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>
Content-Type: application/x-www-form-urlencoded

email=test%40example.net

The application processed the request and updated the email address.

4. Testing the GET Method

I sent the request to Burp Repeater and changed the HTTP method from POST to GET.

GET /my-account/change-email?email=test%40example.net HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>

Result: The server returned Method Not Allowed.

This demonstrated that the application did not directly support GET requests for the email change operation.

5. Testing HTTP Method Override

I added the _method=POST parameter to the GET request.

GET /my-account/change-email?email=csrf-lab07%40example.net&_method=POST HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>

Result: The server accepted the request, and the account email address changed successfully.

This confirmed that the application supported HTTP method overriding.

The browser-facing HTTP method remained GET, while the application processed the request as a POST operation.

6. Exploitation

I created a proof of concept using PortSwigger Exploit Server.

<!DOCTYPE html>
<html>
<body>

<script>
    document.location =
        "https://<LAB-HOST>/my-account/change-email?email=csrf-lab07-victim%40example.net&_method=POST";
</script>

</body>
</html>
How the Attack Works
The victim is authenticated to the vulnerable application.
The victim opens the attacker-controlled page.
JavaScript initiates a top-level GET navigation to the vulnerable application.
SameSite Lax permits the session cookie to accompany this navigation.
The server interprets _method=POST as a method override.
The application processes the email change request.

The attacker does not need to know or steal the victim's session cookie.

7. Verification

I tested the method override behavior using Burp Repeater and confirmed that the email address changed.

I then hosted the HTML proof of concept on PortSwigger Exploit Server.

After delivering the exploit to the simulated victim, PortSwigger marked the laboratory as Solved.

This confirmed the complete attack flow in the authorized laboratory environment.

8. Root Cause

The application allowed a state-changing operation to be triggered through a GET request by accepting the _method=POST parameter.

The security design relied on SameSite Lax cookie restrictions to prevent cross-site POST-based CSRF attacks.

However, the method override mechanism enabled the attacker to use a GET navigation, which is permitted to carry cookies under SameSite Lax rules.

9. Security Impact

The confirmed impact was unauthorized modification of the victim's account email address.

Depending on the application's email verification and account recovery mechanisms, this could potentially contribute to further account compromise.

A complete account takeover was not demonstrated.

10. Remediation

Recommended defenses include:

Reject HTTP method overrides for sensitive state-changing operations.
Never allow account modifications through GET requests.
Implement robust server-side CSRF token validation.
Validate Origin and Referer headers where appropriate.
Use SameSite cookie restrictions as defense in depth rather than as the only CSRF protection.
Require additional verification for sensitive account changes.
11. Key Takeaways

This laboratory demonstrated that SameSite Lax does not prevent every CSRF attack.

The most important observation was the difference between the HTTP method used by the browser and the operation executed by the server.

I practiced:

Analyzing SameSite Lax restrictions.
Testing HTTP methods in Burp Repeater.
Identifying HTTP method override behavior.
Constructing an exploit using top-level navigation.
Demonstrating a complete CSRF attack against a simulated victim.
Documenting the vulnerability, impact, and remediation.

Environment: PortSwigger Web Security Academy
Testing scope: Authorized educational laboratory only.
