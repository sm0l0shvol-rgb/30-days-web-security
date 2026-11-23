ATTACKER GOAL
  Execute alert(1) in the browser via Reflected XSS
      ↓
VICTIM / DELIVERY
  User visiting a crafted search URL (`/?search=...`)
      ↓
SOURCE
  URL query parameter: GET /?search=...
      ↓
CONTEXT & ESCAPE ANALYSIS
  Input is reflected inside an inline `<script>` block:
  var searchTerms = 'USER_INPUT';
  - Angle brackets (`<` and `>`) are HTML-encoded as `&lt;` and `&gt;`
    (closing `</script>` is impossible).
  - Single quotes (`'`) are NOT escaped!
      ↓
INJECTION (JavaScript String Breakout)
  To execute code inside an existing `<script>` block, the entire block must
  remain syntactically valid JavaScript (otherwise a SyntaxError aborts execution).
  We break out of the single quote and repair the trailing quote using arithmetic
  operators (`'-alert(1)-'`) or a statement separator and comment (`';alert(1)//`).
      ↓
SINK
  The server renders inside `<script>`:
  var searchTerms = ''-alert(1)-'';
      ↓
BROWSER BEHAVIOR
  The JavaScript engine evaluates the expression `'' - alert(1) - ''`, which
  invokes `alert(1)` during expression evaluation.
      ↓
IMPACT
  Arbitrary JavaScript execution (`alert(1)`) in the victim's browser context.
