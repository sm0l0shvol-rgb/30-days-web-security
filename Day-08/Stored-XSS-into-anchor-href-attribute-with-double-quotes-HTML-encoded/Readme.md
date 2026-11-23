# Lab: Stored XSS into anchor href attribute with double quotes HTML-encoded

## Overview

- **Category:** Cross-Site Scripting (Stored XSS / URL Attribute Context)
- **Difficulty:** Apprentice
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab contains a stored XSS vulnerability in the blog comment functionality. Although the application properly HTML-encodes angle brackets (`<`, `>`) and double quotes (`"`) across all comment fields—preventing both tag injection and attribute breakout—it reflects the user-supplied `website` field directly as the `href` attribute of an anchor tag (`<a>`) without validating the URL scheme. By supplying a `javascript:` pseudo-protocol URL, we achieve stored XSS that executes whenever a victim clicks the comment author's name.

---

## Attack Scenario & Mental Model

```text
ATTACKER GOAL
  Execute alert(1) in the victim's browser when they click the comment author link
      ↓
VICTIM
  Any user viewing the blog post and clicking the author's name link
      ↓
SOURCE
  The `website` parameter in the comment submission form (`POST /post/comment`)
      ↓
STORAGE
  The server stores the comment and `website` value in the backend database
      ↓
CONTEXT & FILTER ANALYSIS
  Server HTML-encodes `"`, `<`, and `>` (`&quot;`, `&lt;`, `&gt;`):
  <a id="author" href="USER_INPUT">Author</a>
  Breaking out of the double-quoted `href` attribute is impossible.
  However, the `href` attribute itself is a URL execution context!
      ↓
INJECTION / SINK
  Supplying `javascript:alert(1)` as the `website` value renders:
  <a id="author" href="javascript:alert(1)">Author</a>
      ↓
BROWSER BEHAVIOR
  When the victim clicks the `<a href="javascript:alert(1)">` link, the browser
  evaluates the `javascript:` scheme and executes the code following the colon
  in the context of the current page.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1)`) in the victim's browser session.
```

---

## Step-by-Step Walkthrough

### 1. Probing the Comment Fields and Reflection Contexts
Submitted a test comment containing special characters (`"<>`) in each field:
- **Comment:** `test_comment"<>`
- **Name:** `test_name"<>`
- **Email:** `test@test.com`
- **Website:** `http://test_site"<>`

Inspected the HTML response for the blog post (`GET /post?postId=...`) in Burp Suite:

```html
<a id="author" href="http://test_site&quot;&lt;&gt;">test_name&quot;&lt;&gt;</a>
<p>test_comment&quot;&lt;&gt;</p>
```

### 2. Analyzing the Security Controls
- In both `<p>` (HTML body context) and `<a href="...">` (attribute context), `<`, `>`, and `"` are properly encoded as `&lt;`, `&gt;`, and `&quot;`.
- Consequently, we cannot open new tags or break out of the `href="..."` attribute quotes.
- However, because our input starts at the very beginning of the `href` attribute, we control the **URL protocol/scheme**.

### 3. Exploiting the `href` URL Context
Submitted a new comment with the following value in the **Website** field:

```text
javascript:alert(1)
```

The application stored the comment and rendered:

```html
<a id="author" href="javascript:alert(1)">test_name</a>
```

When the victim (or user) clicked the author link, the browser executed `alert(1)`, solving the lab.

---

## Key Takeaways & Remediation

### Why HTML Entity Encoding Alone Does Not Protect `href`
HTML-encoding quotes and angle brackets prevents an attacker from modifying the DOM structure around the attribute, but the browser decodes and interprets the attribute's value as a URL when the link is clicked. A `javascript:` URL requires neither quotes nor angle brackets to execute code.

### Remediation
- **Strict URL Scheme Allowlisting:** Parse user-supplied URLs and strictly enforce an allowlist of safe protocols (only `http:` and `https:`). Reject or sanitize any URL using `javascript:`, `data:`, or `vbscript:` schemes.
- **Defense-in-Depth:** Combine URL protocol validation with standard HTML attribute encoding (`"` → `&quot;`, `<` → `&lt;`, `>` → `&gt;`).
