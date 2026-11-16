# DOM XSS in jQuery Selector Sink Using a Hashchange Event

**Platform:** PortSwigger Web Security Academy  
**Category:** Cross-Site Scripting (DOM-based XSS)  
**Tools:** Browser Developer Tools, JavaScript, PortSwigger Exploit Server  
**Status:** ✅ Solved  
**Challenge:** 30 Days of Web Security — Day 05, Lab 01

**Lab:** [DOM XSS in jQuery selector sink using a hashchange event](https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-jquery-selector-hash-change-event)

## 1. Objective

Identify and exploit a DOM-based XSS vulnerability involving the jQuery selector function and the `hashchange` event.

The objective was to deliver an exploit that executes `print()` in the victim's browser.

## 2. Attack Scenario

The application uses JavaScript and jQuery to automatically scroll to a blog post based on the URL fragment.

An attacker discovers that user-controlled data from `location.hash` reaches a vulnerable jQuery selector.

The attacker creates a malicious page containing an iframe that loads the target website.

After the iframe loads, the attacker-controlled page modifies its URL fragment, triggering the `hashchange` event.

The vulnerable JavaScript processes the malicious fragment, allowing JavaScript execution in the target website's context.

## 3. Source, Sink, and Trigger

**Source:** `location.hash`

The attacker controls the URL fragment after the `#` character.

**Sink:** jQuery `$()` selector function

The application passes the URL fragment to a vulnerable jQuery selector.

**Trigger:** `hashchange` event

The vulnerable code executes when the URL fragment changes.

A simplified example of the vulnerable pattern:

```javascript
$(window).on('hashchange', function () {
    const element = $(location.hash);

    if (element.length) {
        element[0].scrollIntoView();
    }
});
```

This example illustrates the vulnerable data flow rather than reproducing the application's complete source code.

## 4. Exploit Construction

I used PortSwigger Exploit Server to host the following HTML payload:

```html
<!DOCTYPE html>
<html>
<body>

<iframe
    src="https://<LAB-HOST>/#"
    onload="this.src+='<img src=x onerror=print()>'">
</iframe>

</body>
</html>
```

The `<LAB-HOST>` placeholder represents the hostname of the authorized laboratory.

### Payload Breakdown

**`<iframe>`**

Loads the vulnerable application inside the attacker's page.

**`onload`**

Executes JavaScript after the iframe finishes loading.

**`this.src += ...`**

Appends the malicious payload to the iframe URL after the `#` character.

**`hashchange`**

The change to the URL fragment triggers the application's event handler.

**`<img src=x onerror=print()>`**

Creates an image element with an invalid source. When the image fails to load, its error handler executes `print()`.

## 5. Exploitation Steps

1. Opened the laboratory's Exploit Server.
2. Inserted the malicious iframe into the exploit's HTML body.
3. Replaced the placeholder with the laboratory hostname.
4. Stored the exploit.
5. Tested it using **View exploit**.
6. Delivered the exploit using **Deliver to victim**.

**Result: ✅ Lab Solved**

The exploit successfully triggered the required JavaScript execution in the simulated victim's browser.

## 6. Attack Flow

```text
Attacker creates malicious HTML
              |
              v
Victim opens attacker's page
              |
              v
Iframe loads vulnerable website
              |
              v
Iframe onload handler changes URL fragment
              |
              v
Browser triggers hashchange
              |
              v
Application reads location.hash
              |
              v
Vulnerable jQuery selector processes input
              |
              v
Injected HTML creates an image element
              |
              v
Image loading fails
              |
              v
onerror executes print()
              |
              v
Lab Solved
```

## 7. Root Cause

The application passes attacker-controlled URL fragment data into a vulnerable jQuery selector without safely restricting how the input is interpreted.

In the affected jQuery behavior, certain inputs can be treated as HTML rather than selectors.

The security issue can be summarized as:

**Untrusted URL fragment → Vulnerable jQuery selector → HTML interpretation → JavaScript execution**

An important detail is that the exploit requires the `hashchange` event to trigger the vulnerable code.

The URL fragment is handled by the browser and is not normally included in HTTP requests to the server.

## 8. Security Impact

Depending on the application's security controls, successful exploitation could allow an attacker to:

- Execute JavaScript in the vulnerable website's origin.
- Access information available to JavaScript.
- Modify page content.
- Perform actions through an authenticated victim's browser.
- Display deceptive content.

**Confirmed impact:** Execution of `print()` through DOM-based XSS.

Session theft and account takeover were not demonstrated.

## 9. Remediation

- Update jQuery to a maintained version that does not exhibit the vulnerable selector behavior.
- Avoid passing untrusted URL fragments directly into jQuery selectors.
- Validate expected post identifiers before using them.
- Use safe DOM APIs to locate elements.
- Apply a restrictive Content Security Policy as defense in depth.

## 10. Key Takeaways

This laboratory demonstrated that:

- `location.hash` can be an attacker-controlled DOM XSS source.
- URL fragments are normally processed in the browser rather than sent to the server.
- The jQuery selector function can become a dangerous sink in vulnerable implementations.
- Browser events can determine whether an XSS vulnerability is exploitable.
- An iframe can be used to trigger a fragment change automatically.
- Understanding the complete execution flow is essential when testing DOM-based vulnerabilities.

**Main lesson:** Finding a source and sink is not enough. An attacker must also identify how to trigger the vulnerable code.

---

**Environment:** PortSwigger Web Security Academy  
**Scope:** Authorized educational laboratory only.
