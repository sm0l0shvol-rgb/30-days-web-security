# DOM XSS in AngularJS Expression with HTML Encoding

**Platform:** PortSwigger Web Security Academy  
**Category:** Cross-Site Scripting (DOM-based XSS)  
**Tools:** Web Browser, Browser Developer Tools, Burp Suite Community Edition  
**Status:** ✅ Solved  
**Challenge:** 30 Days of Web Security — Day 05, Lab 02

**Lab:** [DOM XSS in AngularJS expression with angle brackets and double quotes HTML-encoded](https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-angularjs-expression)

## 1. Objective

Identify and exploit a DOM-based XSS vulnerability in an AngularJS application.

The application HTML-encodes angle brackets and double quotes, preventing straightforward HTML injection.

The objective was to execute JavaScript through an AngularJS expression despite these restrictions.

## 2. Attack Scenario

An attacker discovers that the application's search functionality reflects user-controlled input within a section of the page processed by AngularJS.

Although the application encodes certain HTML characters, it does not prevent user input from being interpreted as an AngularJS expression.

The attacker can construct a malicious search URL containing an AngularJS payload.

When a victim opens the URL, AngularJS evaluates the injected expression, potentially executing attacker-controlled JavaScript in the context of the vulnerable website.

## 3. Initial Testing

I started by testing whether AngularJS evaluated expressions within the search results.

I submitted:

```javascript
{{7*7}}
```

The application displayed:

```text
49
```

**Observation:** AngularJS evaluated the mathematical expression instead of displaying it as ordinary text.

This confirmed that user-controlled input was being interpreted within an AngularJS expression context.

However, expression evaluation alone did not prove arbitrary JavaScript execution.

## 4. Vulnerability Analysis

The application uses AngularJS to process part of its HTML document.

AngularJS recognizes expressions enclosed in double curly braces:

```javascript
{{ expression }}
```

The presence of an `ng-app` directive causes AngularJS to process expressions within the relevant section of the document.

The vulnerable behavior can be summarized as:

```text
Attacker-controlled search parameter
                |
                v
Application reflects input into HTML
                |
                v
AngularJS processes the page
                |
                v
Injected {{ ... }} expression is evaluated
                |
                v
Potential JavaScript execution
```

The key issue is that untrusted data enters a template-expression context.

## 5. Proof of Concept

After confirming expression evaluation, I submitted:

```javascript
{{$on.constructor('alert(1)')()}}
```

### Payload Breakdown

**`{{ ... }}`**

Defines an AngularJS expression.

**`$on`**

References a function available in the AngularJS scope.

**`.constructor`**

Accesses the JavaScript `Function` constructor through that function.

**`('alert(1)')`**

Creates a function containing the JavaScript statement `alert(1)`.

**`()`**

Immediately invokes the created function.

### Result

The browser executed `alert(1)`.

**The laboratory was marked as Solved.**

This confirmed that attacker-controlled input could cause JavaScript execution through AngularJS expression evaluation.

## 6. Why HTML Encoding Was Insufficient

The application encodes characters such as:

```text
<  → &lt;
>  → &gt;
"  → &quot;
```

This helps prevent straightforward HTML tag injection.

For example, the following markup cannot create an executable script element if the angle brackets are correctly encoded:

```html
<script>alert(1)</script>
```

However, AngularJS expressions do not require HTML tags.

The successful payload used:

```javascript
{{$on.constructor('alert(1)')()}}
```

It did not require angle brackets or double quotes.

**The vulnerability existed because the application allowed untrusted content to be evaluated as an AngularJS expression.**

HTML encoding alone does not prevent template-expression injection.

## 7. Attack Flow

```text
Attacker creates a malicious search URL
                 |
                 v
Victim opens the URL
                 |
                 v
Website reflects the search parameter
                 |
                 v
AngularJS processes the reflected content
                 |
                 v
Injected expression accesses Function
                 |
                 v
Function creates and executes JavaScript
                 |
                 v
alert(1) executes
```

The attacker does not need to modify the application's JavaScript files.

Instead, the attack exploits the way AngularJS interprets user-controlled content.

## 8. Root Cause

The application places untrusted input in a context where AngularJS can interpret it as a template expression.

The vulnerable data flow is:

**User-controlled input → AngularJS template evaluation → JavaScript execution**

The application relies on HTML encoding without adequately separating untrusted content from executable template expressions.

## 9. Security Impact

Depending on the application's security controls, successful exploitation may allow an attacker to:

- Execute JavaScript in the vulnerable website's origin.
- Access page information available to JavaScript.
- Manipulate page content.
- Perform actions using an authenticated victim's browser.
- Display deceptive interface elements.

**Confirmed impact:** JavaScript execution through an AngularJS expression.

Credential theft, session theft, and account takeover were not demonstrated.

## 10. Remediation

- Never insert untrusted input into AngularJS templates where it can be evaluated as an expression.
- Display user-controlled values as plain text instead of compiling them as template content.
- Avoid dynamically compiling templates containing untrusted data.
- Use appropriate context-specific output encoding and safe rendering practices.
- Migrate applications away from unsupported AngularJS versions.
- Implement a restrictive Content Security Policy as defense in depth.

## 11. Key Takeaways

This lab demonstrated that:

- HTML encoding does not protect against every type of injection.
- AngularJS evaluates expressions enclosed in `{{ ... }}`.
- A mathematical expression such as `{{7*7}}` can help identify template evaluation.
- Expression evaluation does not automatically mean arbitrary JavaScript execution.
- Access to dangerous JavaScript functionality through an expression can lead to XSS.
- Understanding the framework's behavior is essential when testing client-side applications.

**Main lesson:** An application may safely encode HTML characters but remain vulnerable if user-controlled input is interpreted as executable template expressions.

---

**Environment:** PortSwigger Web Security Academy  
**Scope:** Authorized educational laboratory only.
