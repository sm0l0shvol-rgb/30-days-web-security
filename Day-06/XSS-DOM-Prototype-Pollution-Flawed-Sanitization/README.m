Client-Side Prototype Pollution via Flawed Sanitization

Platform: PortSwigger Web Security Academy
Category: Client-Side Prototype Pollution / DOM XSS
Difficulty: Practitioner
Status: ✅ Solved
Challenge: 30 Days of Web Security — Day 05, Lab 07

Lab: Client-side prototype pollution via flawed sanitization

1. Objective

Bypass flawed property-key sanitization to exploit client-side prototype pollution and trigger DOM-based XSS.

The objective was to identify why the application's protection was ineffective, bypass the sanitization logic, and use a polluted property to control a dynamically created script element.

2. Attack Scenario

An attacker discovers that the application processes URL query parameters and uses them to construct JavaScript objects.

The developers have implemented a sanitization function intended to remove dangerous property names.

However, the function removes prohibited substrings without checking whether the resulting string is still dangerous.

The attacker can exploit this behavior by crafting a key that becomes __proto__ only after sanitization.

Once prototype pollution is achieved, the attacker controls an inherited configuration property called transport_url.

The application uses this property to dynamically create a <script> element.

By supplying a JavaScript data: URL, the attacker can trigger DOM XSS.

3. Testing the Initial Prototype Pollution Vector

I first tested a standard prototype pollution payload:

/?__proto__.foo=bar

Then I executed:

Object.prototype.foo

Result:

undefined

The standard payload failed.

This suggested that the application was blocking or modifying dangerous property paths.

Instead of assuming that the application was secure, I inspected its JavaScript code.

4. Analyzing the Sanitization Function

Using Developer Tools → Sources, I inspected the application's JavaScript files.

I found the following function:

function sanitizeKey(key) {
    let badProperties = ['constructor','__proto__','prototype'];
    for(let badProperty of badProperties) {
        key = key.replaceAll(badProperty, '');
    }
    return key;
}

The function attempts to remove three dangerous property names:

constructor
__proto__
prototype

It uses replaceAll(), which removes all current occurrences of a given substring.

However, it processes each blocked value only once.

If removing one occurrence creates a new dangerous substring, the function does not necessarily detect it.

This is the critical flaw.

5. Understanding the Sanitization Bypass

I used the following crafted property name:

__pro__proto__to__

This contains the blocked substring __proto__ inside another string.

The sanitization process works as follows:

Original input:
__pro__proto__to__

Remove the embedded "__proto__":
__pro + to__

Result:
__proto__

The dangerous property name is reconstructed after the relevant replacement operation.

The sanitization function does not recheck the final string.

Therefore:

sanitizeKey('__pro__proto__to__')

Returns:

__proto__

This bypasses the intended protection.

6. Confirming Prototype Pollution

I tested the bypass using:

/?__pro__proto__to__[foo]=bar

Then I executed:

Object.prototype.foo

Result:

'bar'

This confirmed that the crafted key bypassed the sanitization function and successfully polluted Object.prototype.

The important difference was:

Payload

Result

__proto__.foo=bar

Blocked

__pro__proto__to__[foo]=bar

Prototype pollution successful

7. Identifying the XSS Gadget

After confirming prototype pollution, I investigated the application code for a property that could lead to JavaScript execution.

The application used the transport_url configuration property to dynamically create a script element.

The relevant behavior can be represented as:

const config = {};

if (config.transport_url) {
    const script = document.createElement('script');
    script.src = config.transport_url;
    document.body.appendChild(script);
}

This is a simplified illustration of the gadget.

Because config.transport_url can inherit its value from Object.prototype, it can be influenced by prototype pollution.

8. Confirming Control Over the Script Element

I used the following URL parameter:

/?__pro__proto__to__[transport_url]=foo

After loading the page, I inspected the DOM using Developer Tools → Elements.

I observed:

<script src="foo"></script>

This confirmed that the application created a script element using the attacker-controlled inherited property.

At this point, both the sanitization bypass and the XSS gadget were verified.

9. Final Proof of Concept

I replaced the test value foo with a JavaScript data: URL.

Final payload:

/?__pro__proto__to__[transport_url]=data:,alert(1);

The application processed the input as follows:

The sanitization function converted __pro__proto__to__ into __proto__.

The query-string parser polluted Object.prototype.transport_url.

The configuration object inherited the polluted transport_url property.

The application used the inherited value to create a script element.

The browser executed the JavaScript supplied through the data: URL.

The dynamically generated element was equivalent to:

<script src="data:,alert(1);"></script>

Result: alert(1) executed successfully, and the laboratory was marked Solved.

10. Complete Attack Flow

Attacker-controlled URL
           |
           v
__pro__proto__to__[transport_url]
           |
           v
sanitizeKey()
           |
           v
Dangerous "__proto__" reconstructed
           |
           v
Object.prototype.transport_url polluted
           |
           v
config.transport_url inherits the value
           |
           v
Application creates a <script> element
           |
           v
script.src = "data:,alert(1);"
           |
           v
JavaScript executes
           |
           v
DOM XSS confirmed

11. Source, Gadget, and Sink

Component

Description

Source

URL query parameters

Vulnerable logic

sanitizeKey()

Bypass

__pro__proto__to__

Pollution target

Object.prototype

Gadget

Inherited config.transport_url

Sink

Dynamic script.src assignment

Final payload

data:,alert(1);

Result

DOM XSS

12. Root Cause

The main vulnerability was caused by incomplete sanitization of property names.

The application tried to make unsafe keys harmless by removing blocked substrings.

However, substring removal could reconstruct a dangerous key.

The protection also failed to enforce a security boundary between untrusted query parameters and JavaScript object prototypes.

Finally, the application trusted an inherited configuration property when dynamically loading a script.

Together, these issues allowed the attacker to bypass sanitization and execute JavaScript.

13. Remediation

Recommended improvements include:

Reject dangerous property paths instead of removing substrings from them.

Validate the complete property path before assigning values to objects.

Prevent untrusted input from modifying object prototypes.

Use safe query-string parsing and object-merging libraries.

Consider Object.create(null) for dictionaries that do not require prototype inheritance.

Use Object.hasOwn() when reading sensitive configuration properties.

Validate dynamically loaded script URLs against a strict allowlist.

Use a restrictive Content Security Policy as defense in depth.

The most important principle is that dangerous property names should be rejected, not transformed into supposedly safe values.

14. Key Takeaways

This laboratory demonstrated that:

A failed basic payload does not mean an application is secure.

Sanitization logic must be examined carefully.

replaceAll() does not automatically guarantee safe input.

Removing dangerous substrings can create new dangerous strings.

Prototype pollution becomes exploitable when application gadgets trust inherited properties.

DOM XSS may result from combining multiple individually flawed components.

Main lesson: Security filters should prevent unsafe operations, not merely try to remove suspicious text.

Scope: Authorized PortSwigger Web Security Academy laboratory.
