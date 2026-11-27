GOAL
  Execute alert(1) in the browser by overriding the script policy via header injection
      ↓
TWO REFLECTION POINTS IN ONE REQUEST
  1. HTML Body Reflection:
     `GET /?search=...` is reflected unescaped into the HTML page body.
  2. Response Header Reflection:
     `GET /?token=...` is reflected unescaped into the HTTP response header:
     Content-Security-Policy: ...; script-src 'self'; style-src 'self'; report-uri /csp-report?token=USER_INPUT
      ↓
WHY DUPLICATE `script-src` FAILS vs. WHY `script-src-elem` SUCCEEDS
  - According to the CSP specification, if a duplicate `script-src` directive is
    appended later in the same header, the browser ignores the second occurrence.
  - However, CSP Level 3 introduced **`script-src-elem`**, which specifically governs
    `<script>` elements and takes precedence over the fallback `script-src` directive!
      ↓
COMBINED REQUEST
  /?search=<script>alert(1)</script>&token=;script-src-elem+'unsafe-inline'
      ↓
OUTCOME
  The browser parses `; script-src-elem 'unsafe-inline'` from the policy header
  and permits the inline `<script>alert(1)</script>` in the HTML body to run → Solved!
