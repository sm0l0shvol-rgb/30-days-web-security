# Lab: Client-side prototype pollution via browser APIs

## Overview

- **Category:** Client-Side Prototype Pollution / DOM XSS
- **Difficulty:** Practitioner
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab demonstrates how a developer's attempt to harden an object against prototype pollution using `Object.defineProperty()` can backfire when the property descriptor object omits the `value` attribute, turning a built-in browser API into a prototype pollution gadget.

---

## Attack Scenario & Mental Model

```text
ATTACKER GOAL
  Execute alert(1) in the browser via DOM XSS
      ↓
VICTIM / DELIVERY
  User visiting a malicious URL containing crafted query parameters
      ↓
SOURCE
  location.search (parsed into an object via deparam())
      ↓
POLLUTION
  ?__proto__[value]=data:,alert(1);
  (pollutes Object.prototype.value)
      ↓
GADGET (Browser API: Object.defineProperty)
  The application initializes `config = { ..., transport_url: false }` and calls:
  Object.defineProperty(config, 'transport_url', {configurable: false, writable: false})
  Because the descriptor object `{configurable: false, writable: false}` does not
  explicitly define a `value` property, `Object.defineProperty()` looks up `value`
  on the descriptor's prototype chain (`Object.prototype.value`) and overwrites
  `config.transport_url` with the polluted value.
      ↓
SINK
  script.src = config.transport_url
  document.body.appendChild(script)
      ↓
BROWSER BEHAVIOR
  The browser loads and executes the JavaScript payload from the `data:` URL.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1)`) in the victim's browser context.
```

---

## Vulnerable Code Analysis

In `searchLoggerConfigurable.js`:

```javascript
async function searchLogger() {
    let config = {params: deparam(new URL(location).searchParams.toString()), transport_url: false};
    Object.defineProperty(config, 'transport_url', {configurable: false, writable: false});
    if(config.transport_url) {
        let script = document.createElement('script');
        script.src = config.transport_url;
        document.body.appendChild(script);
    }
    if(config.params && config.params.search) {
        await logQuery('/logger', config.params);
    }
}
```

### Why Direct Pollution of `transport_url` Fails
Because `transport_url: false` is explicitly defined as an own property on `config`, polluting `Object.prototype.transport_url` has no effect—JavaScript resolves the own property `false` directly on `config`.

### How `Object.defineProperty()` Becomes the Gadget
The third argument to `Object.defineProperty(obj, prop, descriptor)` is a standard JavaScript object `{configurable: false, writable: false}` that inherits from `Object.prototype`. When the browser engine processes this descriptor, it checks whether `descriptor.value` is present. By polluting `Object.prototype.value`, the descriptor inherits `value`, causing `Object.defineProperty()` itself to overwrite `config.transport_url` with our attacker-controlled string.

---

## Step-by-Step Walkthrough

### 1. Identifying the Source and Gadget
1. Inspected `searchLoggerConfigurable.js` in Browser DevTools and noticed the `Object.defineProperty()` call without an explicit `value` key in its descriptor.
2. Confirmed using **DOM Invader** that `location.search` allows prototype pollution via `__proto__[property]=value`, and that scanning for gadgets identifies the **`value`** property flowing into a `<script>` `src` sink.

### 2. Testing the Gadget
Appended the following query string to the lab URL:

```text
?__proto__[value]=foo
```

Inspected the DOM in **DevTools → Elements** and confirmed that `<script src="foo"></script>` was dynamically appended to `<body>`.

### 3. Executing the DOM XSS Payload
Replaced the test value with a `data:` URL payload to execute `alert(1)`:

```text
https://LAB-HOST/?__proto__[value]=data:,alert(1);
```

The browser created `<script src="data:,alert(1);"></script>`, executed `alert(1)`, and solved the lab.

---

## Key Takeaways & Remediation

### Remediation
1. **Prevent Prototype Pollution at the Source:** Sanitize keys during query parsing (`deparam`) to block `__proto__`, `constructor`, and `prototype`, or store parsed parameters in a null-prototype object (`Object.create(null)`).
2. **Explicitly Define Descriptor Values:** When using `Object.defineProperty()`, always explicitly set `value` (e.g., `{value: false, configurable: false, writable: false}`) or use a null-prototype descriptor (`Object.assign(Object.create(null), {configurable: false, writable: false})`).
