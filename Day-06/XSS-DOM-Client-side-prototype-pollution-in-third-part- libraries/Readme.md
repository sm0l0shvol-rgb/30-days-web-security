# Lab: Client-side prototype pollution in third-party libraries

## Overview

- **Category:** Client-Side Prototype Pollution / DOM XSS
- **Difficulty:** Practitioner
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab demonstrates how a client-side prototype pollution vulnerability in the application's own URL-parsing logic can be chained with a gadget inside a minified third-party library (Google Analytics tracking script) to achieve DOM-based XSS.

---

## Attack Scenario & Mental Model

```text
ATTACKER GOAL
  Execute alert(document.cookie) in the victim's browser session
      ↓
VICTIM
  Authenticated user visiting an attacker-controlled page
      ↓
DELIVERY
  Exploit Server performing a top-level navigation to the vulnerable URL
      ↓
SOURCE
  location.hash (URL fragment parsed into a JavaScript object)
      ↓
POLLUTION
  #__proto__[hitCallback]=alert(document.cookie)
  (or #constructor[prototype][hitCallback]=...)
      ↓
GADGET (Third-Party Library)
  A third-party analytics script reads the `hitCallback` property from its
  configuration object. Since `hitCallback` is not explicitly defined on the
  object, JavaScript resolves it via the prototype chain from `Object.prototype`.
      ↓
SINK
  setTimeout(hitCallback, ...)
      ↓
BROWSER BEHAVIOR
  setTimeout() accepts a string as its first argument and evaluates it as
  JavaScript code (similar to eval()).
      ↓
IMPACT
  Arbitrary JavaScript execution (DOM XSS) in the victim's browser context.
```

---

## Step-by-Step Walkthrough

### 1. Identifying the Prototype Pollution Source

Using Burp Suite's built-in browser with **DOM Invader** enabled (and **Prototype pollution** switched ON):

1. Loaded the lab page and opened **DevTools → DOM Invader**.
2. DOM Invader automatically identified two prototype pollution vectors originating from `location.hash`:
   - `__proto__[property]=value` in `hash`
   - `constructor[prototype][property]=value` in `hash`

### 2. Discovering the Third-Party Gadget

Because the gadget resides inside a large, minified third-party script, manual code review is impractical.

1. Clicked **Scan for gadgets** in DOM Invader next to the discovered hash vector.
2. DOM Invader opened a test tab and traced property lookups reaching dangerous sinks.
3. The scan revealed that the **`hitCallback`** property flows directly into the **`setTimeout()`** sink.

### 3. Verifying the Exploit Locally

Appended the prototype pollution payload to the lab URL in the browser:

```text
https://LAB-HOST/#__proto__[hitCallback]=alert(document.cookie)
```

*(Alternatively, using the constructor vector produced by DOM Invader):*

```text
https://LAB-HOST/#constructor[prototype][hitCallback]=alert%28document.cookie%29
```

Upon loading the page, the analytics script inherited `hitCallback` from `Object.prototype` and passed the string to `setTimeout()`, triggering `alert(document.cookie)`.

### 4. Delivering the Exploit to the Victim

1. Disabled DOM Invader to ensure clean browser behavior.
2. Opened the **Exploit Server** and placed the following payload in the **Body** section:

```html
<script>
    location = "https://LAB-HOST/#__proto__[hitCallback]=alert%28document.cookie%29";
</script>
```

3. Clicked **Store** and then **Deliver exploit to victim** to solve the lab.

---

## Key Takeaways & Remediation

### Why It Happened
1. **Unsafe Object Merging / Parsing:** The application parsed `location.hash` key-value pairs into a JavaScript object without filtering special prototype keys (`__proto__`, `constructor`, `prototype`).
2. **Implicit Trust in Inherited Properties:** The third-party library checked for an optional configuration property (`hitCallback`) without verifying whether it was an own property (`Object.hasOwn()`) or validating that its type was a `Function` before passing it to `setTimeout()`.

### Remediation
- **Freeze or Null-Prototype Objects:** Use `Object.create(null)` for configuration maps/dictionaries that store user-derived keys, or freeze `Object.prototype` (`Object.freeze(Object.prototype)`).
- **Filter Prototype Keys:** Explicitly block `__proto__`, `constructor`, and `prototype` during recursive merges or query/hash parsing.
- **Defensive Coding in Sinks:** Ensure callbacks passed to `setTimeout()` or `setInterval()` are strictly of type `function` (`typeof cb === 'function'`), never raw strings.
