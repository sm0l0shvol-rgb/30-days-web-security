# DOM XSS via an Alternative Prototype Pollution Vector

**Platform:** PortSwigger Web Security Academy  
**Category:** Client-Side Prototype Pollution / DOM XSS  
**Difficulty:** Practitioner  
**Status:** ✅ Solved  
**Challenge:** 30 Days of Web Security — Day 05, Lab 06

**Lab:** [DOM XSS via an alternative prototype pollution vector](https://portswigger.net/web-security/prototype-pollution/client-side/lab-prototype-pollution-dom-xss-via-an-alternative-prototype-pollution-vector)

## 1. Objective

Exploit a client-side prototype pollution vulnerability using an alternative query-string syntax.

The goal was to identify a pollution source, find a JavaScript gadget, and execute `alert(1)` through an `eval()` sink.

## 2. Attack Scenario

An attacker creates a malicious URL containing specially crafted query parameters.

When a victim opens the URL, the application's JavaScript processes the parameters and unintentionally modifies `Object.prototype`.

Another component of the application accesses an inherited property named `sequence`.

The value of this property is inserted into a JavaScript expression executed by `eval()`.

By controlling the inherited property, the attacker can execute JavaScript in the victim's browser.

## 3. Finding the Prototype Pollution Source

I initially tested the bracket notation:

```text
/?__proto__[foo]=bar
```

This did not successfully pollute `Object.prototype`.

I then tested an alternative syntax using dot notation:

```text
/?__proto__.foo=bar
```

In the browser's Developer Tools console, I executed:

```javascript
Object.prototype.foo
```

**Result:**

```javascript
'bar'
```

This confirmed that the application was vulnerable to prototype pollution through dot-notation query parameters.

The important lesson was that different query-string parsers may support different property-path syntaxes.

A failed test with one syntax does not prove that prototype pollution is impossible.

## 4. Identifying the Gadget

I inspected the application's JavaScript files using **Developer Tools → Sources**.

In `searchLoggerAlternative.js`, I found:

```javascript
eval('if(manager && manager.sequence){ manager.macro('+manager.sequence+') }');
```

This code constructs a JavaScript expression by concatenating the value of `manager.sequence`.

The `sequence` property is not explicitly defined on the relevant object.

Therefore, it can inherit a polluted value from `Object.prototype`.

The dangerous behavior is the combination of:

- An inherited configuration property.
- String concatenation.
- Execution through `eval()`.

## 5. Initial XSS Attempt

I tested the following payload:

```text
/?__proto__.sequence=alert(1)
```

The payload reached the vulnerable code, but JavaScript execution failed with a syntax error.

Further analysis showed that an additional `1` character was appended to the value of `manager.sequence`.

The resulting value was:

```javascript
"alert(1)1"
```

The generated JavaScript was effectively:

```javascript
if (manager && manager.sequence) {
    manager.macro(alert(1)1);
}
```

This is invalid JavaScript syntax.

The failure was not caused by an unsuccessful prototype pollution attempt.

Instead, the injected expression needed to be adapted to the surrounding JavaScript context.

## 6. Adapting the Payload

To correct the syntax, I added a trailing minus operator:

```text
/?__proto__.sequence=alert(1)-
```

After the application appended the additional `1`, the expression became:

```javascript
alert(1)-1
```

The generated statement was effectively:

```javascript
manager.macro(alert(1)-1);
```

This is syntactically valid.

JavaScript evaluates the function call before evaluating the subtraction.

Therefore, `alert(1)` executes.

**Result:** The browser executed the XSS proof of concept, and the lab was marked **Solved**.

## 7. Attack Flow

```text
Attacker-controlled URL
          |
          v
?__proto__.sequence=alert(1)-
          |
          v
Unsafe query-string processing
          |
          v
Object.prototype.sequence polluted
          |
          v
manager.sequence inherits the payload
          |
          v
Application appends "1"
          |
          v
alert(1)-1
          |
          v
eval() executes the expression
          |
          v
DOM XSS
```

## 8. Source, Gadget, and Sink

| Component | Description |
|---|---|
| Source | URL query parameters |
| Pollution vector | `__proto__.sequence` |
| Pollution target | `Object.prototype` |
| Gadget | Inherited `manager.sequence` |
| Sink | `eval()` |
| Payload | `alert(1)-` |
| Confirmed impact | Execution of `alert(1)` |

## 9. Root Cause

The vulnerability was caused by two insecure behaviors.

**Unsafe property assignment:** The application allowed user-controlled query parameters to modify the JavaScript prototype chain.

**Unsafe dynamic code execution:** The application incorporated an inherited property into a string executed using `eval()`.

The combination allowed attacker-controlled input to become executable JavaScript.

## 10. Remediation

Recommended improvements include:

- Reject dangerous property paths such as `__proto__`, `constructor`, and `prototype`.
- Use safe query-string parsing and object-merging implementations.
- Avoid `eval()` and other dynamic code execution functions.
- Treat inherited properties as untrusted when reading configuration values.
- Check whether a sensitive configuration property is explicitly defined using `Object.hasOwn()`.
- Apply strict input validation and a restrictive Content Security Policy as additional protections.

## 11. Key Takeaways

This laboratory demonstrated that prototype pollution can lead to DOM XSS through an `eval()` gadget.

It also highlighted the importance of understanding the exact JavaScript context of an injection.

A payload may successfully reach a dangerous sink but still fail because the generated code is syntactically invalid.

**Main lesson:** Exploitation requires understanding not only where attacker-controlled data reaches, but also how the application transforms it before execution.

---

**Scope:** Authorized PortSwigger Web Security Academy laboratory.
