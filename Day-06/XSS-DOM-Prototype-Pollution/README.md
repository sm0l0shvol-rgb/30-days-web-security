# DOM XSS via Client-Side Prototype Pollution

**Platform:** PortSwigger Web Security Academy  
**Category:** Prototype Pollution / DOM-Based XSS  
**Difficulty:** Practitioner  
**Tools:** Web Browser, Browser Developer Tools, JavaScript  
**Status:** ✅ Solved  
**Challenge:** 30 Days of Web Security — Day 05, Lab 05

**Lab:** [DOM XSS via client-side prototype pollution](https://portswigger.net/web-security/prototype-pollution/client-side/lab-prototype-pollution-dom-xss-via-client-side-prototype-pollution)

## 1. Objective

Identify and exploit a client-side prototype pollution vulnerability that leads to DOM-based cross-site scripting.

The objective was to find a prototype pollution source, identify an exploitable gadget, and use both to execute `alert(1)`.

## 2. Attack Scenario

An attacker discovers that the application processes URL query parameters in an unsafe way.

By supplying a specially crafted parameter containing `__proto__`, the attacker can add arbitrary properties to the global `Object.prototype`.

Other JavaScript objects may inherit these properties.

The application also contains JavaScript that uses a configuration object's `transport_url` property when dynamically creating a `<script>` element.

The attacker can exploit this behavior by polluting `Object.prototype.transport_url` with a malicious script URL.

When a victim opens the crafted link, the application creates a script element using the attacker-controlled value, resulting in JavaScript execution.

## 3. Identifying the Prototype Pollution Source

I started by testing whether URL parameters could modify `Object.prototype`.

I opened the application with:

```text
/?__proto__[foo]=bar
```

Then I opened the browser's Developer Tools and executed:

```javascript
Object.prototype.foo
```

**Result:**

```javascript
'bar'
```

This demonstrated that the URL parameter successfully added a property to the global object prototype.

To confirm inheritance, I created a new object:

```javascript
const test = {};
console.log(test.foo);
```

**Result:**

```javascript
bar
```

Although the `test` object did not define a `foo` property, it inherited the polluted value.

This confirmed the prototype pollution vulnerability.

## 4. Identifying the Gadget

Prototype pollution alone does not necessarily lead to XSS.

To achieve code execution, I needed to identify a gadget: application code that uses an attacker-controlled inherited property in a dangerous operation.

I investigated the application's JavaScript, focusing on `searchLogger.js`.

The relevant functionality uses the `transport_url` configuration property when dynamically creating a script element.

A simplified representation of the behavior is:

```javascript
const config = {};

if (config.transport_url) {
    const script = document.createElement('script');
    script.src = config.transport_url;
    document.body.appendChild(script);
}
```

This is an illustrative example of the vulnerable behavior.

Because `config` does not define its own `transport_url` property, JavaScript may retrieve an inherited value from `Object.prototype`.

This creates an exploitable gadget.

## 5. Confirming Control Over the Script Source

I changed the URL parameter to:

```text
/?__proto__[transport_url]=foo
```

Then I checked the polluted property:

```javascript
Object.prototype.transport_url
```

**Result:**

```javascript
'foo'
```

Next, I inspected the page using **Developer Tools → Elements**.

I found the following element:

```html
<script src="foo"></script>
```

**Observation:** The application dynamically created a script element using the value injected through prototype pollution.

This confirmed that the polluted property reached the `script.src` sink.

At this stage, I had identified an exploitable path from the prototype pollution source to a dangerous DOM sink.

## 6. Proof of Concept

After confirming control over the script URL, I replaced `foo` with a JavaScript `data:` URL.

**Payload:**

```text
/?__proto__[transport_url]=data:,alert(1);
```

The injected value was assigned to the `transport_url` property on `Object.prototype`.

When the application's JavaScript accessed `config.transport_url`, it inherited the attacker-controlled value.

The application then created a script element equivalent to:

```html
<script src="data:,alert(1);"></script>
```

The browser executed the JavaScript supplied through the `data:` URL.

**Result: The browser displayed `alert(1)`, and the laboratory was marked as Solved.**

## 7. Complete Attack Flow

```text
Attacker creates a malicious URL
                 |
                 v
Victim opens the URL
                 |
                 v
Application processes query parameters
                 |
                 v
Object.prototype.transport_url is polluted
                 |
                 v
Configuration object inherits transport_url
                 |
                 v
searchLogger.js accesses the inherited value
                 |
                 v
Application creates a script element
                 |
                 v
script.src receives a malicious data: URL
                 |
                 v
Browser executes alert(1)
                 |
                 v
DOM XSS confirmed
```

This attack illustrates how a vulnerability in one part of an application can influence seemingly unrelated JavaScript functionality.

## 8. Source, Gadget, and Sink

| Component | Description |
|---|---|
| Source | URL query parameters containing `__proto__` |
| Pollution target | `Object.prototype` |
| Gadget | Inherited `config.transport_url` property |
| Sink | Dynamic assignment to `script.src` |
| Payload | `data:,alert(1);` |
| Result | DOM-based JavaScript execution |

The vulnerable execution path is:

**URL input → Prototype Pollution → Inherited property → Gadget → Script source → DOM XSS**

## 9. Root Cause

The vulnerability results from two insecure behaviors.

### Unsafe Object Property Handling

The application allows untrusted URL parameters to modify properties on `Object.prototype`.

This affects the prototype chain used by ordinary JavaScript objects.

### Unsafe Use of Inherited Configuration Properties

The application accesses `config.transport_url` without ensuring that the property is explicitly defined and trusted.

Because the property can be inherited, a polluted prototype can influence its value.

The application then uses that value as the source of a dynamically created script element.

Together, these weaknesses allow an attacker to turn prototype pollution into DOM XSS.

## 10. Security Impact

Depending on the application's security controls, successful exploitation could allow an attacker to:

- Execute JavaScript within the vulnerable website's origin.
- Access page information available to JavaScript.
- Manipulate page content.
- Perform actions through an authenticated victim's browser.
- Influence application behavior through inherited properties.

The broader impact of prototype pollution depends on the available gadgets.

**Confirmed impact:** JavaScript execution through `alert(1)`.

Credential theft, session theft, and account takeover were not demonstrated.

## 11. Remediation

Recommended improvements include:

- Reject dangerous object property names such as `__proto__`, `constructor`, and `prototype` when processing untrusted input.
- Use safe libraries for parsing query parameters and merging objects.
- Avoid using inherited properties as trusted configuration values.
- Use `Object.hasOwn()` when checking whether a configuration property is explicitly defined.
- Consider `Object.create(null)` for dictionaries that do not need a prototype.
- Restrict which URLs may be used as dynamically loaded script sources.
- Apply a restrictive Content Security Policy (CSP) as defense in depth.

### Safer Property Checking

Instead of:

```javascript
if (config.transport_url) {
    // Load a script
}
```

Prefer checking whether the configuration explicitly defines the property:

```javascript
if (Object.hasOwn(config, 'transport_url')) {
    // Validate the value before using it
}
```

This helps prevent the application from trusting a property inherited through a polluted prototype.

However, property ownership checks do not replace the need to prevent prototype pollution at its source.

## 12. Key Takeaways

This laboratory demonstrated that:

- Prototype pollution can be introduced through unsafe URL parameter processing.
- JavaScript objects can inherit attacker-controlled properties from `Object.prototype`.
- Prototype pollution alone does not guarantee code execution.
- A gadget is needed to turn polluted properties into dangerous behavior.
- Dynamic script creation becomes dangerous when the script URL is attacker-controlled.
- DOM XSS can occur without directly injecting HTML markup into the page.
- Understanding JavaScript's prototype chain is essential when investigating these vulnerabilities.

**Main lesson:** Untrusted data can become dangerous indirectly when applications rely on inherited object properties for sensitive operations.

---

**Environment:** PortSwigger Web Security Academy  
**Scope:** Authorized educational laboratory only.

*All examples use non-sensitive test values from the authorized lab environment.*
