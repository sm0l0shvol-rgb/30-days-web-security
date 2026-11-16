# Reflected DOM XSS

**Platform:** PortSwigger Web Security Academy  
**Category:** Cross-Site Scripting (Reflected DOM XSS)  
**Tools:** Burp Suite Community Edition, Browser Developer Tools  
**Status:** ✅ Solved  
**Challenge:** 30 Days of Web Security — Day 05, Lab 03

**Lab:** [Reflected DOM XSS](https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-dom-xss-reflected)

## 1. Objective

Identify and exploit a reflected DOM-based XSS vulnerability caused by insecure handling of JSON data and the use of JavaScript's `eval()` function.

The objective was to execute `alert(1)` in the browser.

## 2. Attack Scenario

The application provides a search feature that retrieves results from the server in JSON format.

An attacker discovers that the server reflects the search parameter into its JSON response without correctly escaping backslash characters.

The application's JavaScript then processes the response using `eval()`.

By manipulating the search parameter, the attacker can break out of the JSON string and inject executable JavaScript.

A victim who opens the crafted search URL triggers the vulnerable processing flow.

## 3. Initial Reconnaissance

I submitted a harmless test string:

```text
REFLECTEDDOM2026
```

Using **Burp Suite → Proxy → HTTP history**, I located the search results request.

The server returned a JSON response containing the submitted value.

This confirmed that user-controlled input was reflected in the response.

## 4. Identifying the Dangerous Sink

I inspected the application's JavaScript and found:

```javascript
eval('var searchResultsObj = ' + this.responseText);
```

The application takes the HTTP response as a string and executes it as JavaScript.

This is dangerous because attacker-controlled content may become part of the executed code.

**Source:** Server response containing the reflected search parameter.

**Sink:** JavaScript `eval()`.

## 5. Testing Character Escaping

I tested how the application handled a backslash followed by a double quote:

```text
\"
```

The server returned a value containing:

```text
"searchTerm":"\\"
```

This revealed that the application escaped double quotes but did not correctly handle existing backslashes.

The resulting sequence could cause the JavaScript parser to interpret a quote as the end of a string.

This created an opportunity to inject JavaScript into the code processed by `eval()`.

## 6. Proof of Concept

I submitted the following payload:

```javascript
\"-alert(1)}//
```

### Payload Breakdown

| Component | Purpose |
|---|---|
| `\` | Exploits incorrect escaping of backslashes |
| `"` | Terminates the JavaScript string |
| `-` | Continues the expression and evaluates the following function call |
| `alert(1)` | Demonstrates JavaScript execution |
| `}` | Closes the surrounding object |
| `//` | Comments out the remaining response content |

The vulnerable response can produce JavaScript resembling:

```javascript
var searchResultsObj = {
    "searchTerm": "\\" - alert(1)
}
// Remaining response content is commented out
```

When evaluated, the `alert(1)` function executes.

**Result:** The browser displayed an alert, and the laboratory was marked as **Solved**.

## 7. Attack Flow

```text
Attacker creates malicious search URL
                 |
                 v
Victim opens the URL
                 |
                 v
Browser requests search results
                 |
                 v
Server reflects attacker-controlled input
                 |
                 v
Incorrect escaping changes the code structure
                 |
                 v
Browser receives the response
                 |
                 v
Application passes responseText into eval()
                 |
                 v
Injected JavaScript executes
                 |
                 v
Lab Solved
```

## 8. Root Cause

The vulnerability results from two insecure behaviors:

**1. Incorrect JSON escaping**

The server fails to safely encode attacker-controlled input, allowing characters to interfere with the surrounding JavaScript string.

**2. Unsafe JavaScript execution**

The client-side application uses `eval()` to process a response that should be treated as structured data.

The vulnerable data flow is:

**User input → JSON response → `responseText` → `eval()` → JavaScript execution**

## 9. Security Impact

Depending on the application's security controls, successful exploitation could allow an attacker to:

- Execute JavaScript in the vulnerable website's origin.
- Access information available to JavaScript.
- Manipulate page content.
- Perform actions using an authenticated victim's browser.
- Display deceptive content.

**Confirmed impact:** JavaScript execution through `alert(1)`.

Session theft, credential theft, and account takeover were not demonstrated.

## 10. Remediation

- Replace `eval()` with `JSON.parse()` for processing JSON responses.
- Use a standard JSON serializer on the server instead of manually constructing JSON strings.
- Correctly escape special characters, including quotes and backslashes.
- Never construct executable JavaScript from untrusted HTTP responses.
- Apply a restrictive Content Security Policy as defense in depth.

### Safer JavaScript Example

Instead of:

```javascript
eval('var searchResultsObj = ' + this.responseText);
```

Use:

```javascript
const searchResultsObj = JSON.parse(this.responseText);
```

`JSON.parse()` parses structured data without executing arbitrary JavaScript statements.

## 11. Key Takeaways

This laboratory demonstrated that:

- Reflected XSS does not always involve injecting HTML tags.
- JSON responses can become attack vectors when processed unsafely.
- Incorrect escaping of backslashes can allow attackers to break out of strings.
- `eval()` is dangerous when used with untrusted input.
- Reflected DOM XSS can involve both server-side reflection and client-side execution.
- Understanding JavaScript string escaping is essential when testing injection vulnerabilities.

**Main lesson:** Data received from a server should be parsed as data, not executed as JavaScript code.

---

**Environment:** PortSwigger Web Security Academy  
**Scope:** Authorized educational laboratory only.
