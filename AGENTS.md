# AGENTS.md

This file guides agentic coding assistants working in this repository.
It summarizes how to build, lint, test, and follow the local code style.

## Project quick facts
- Name: h5ai (modern HTTP directory index)
- Main sources: `src/_h5ai/` (JS/CSS/PHP/Pug)
- Tests: `test/` (Node + jsdom + scar)
- Build system: `ghu.js` tasks (webpack/less/pug pipeline)

## Install
- `npm install`
- Node 10+ is required (per README)

## Build commands
- Full release build: `npm run build` (runs `node ghu release`)
- Clean + build: `node ghu clean build` (run tasks directly)
- Build tests bundle: `node ghu build:tests`
- Watch sources/tests: `node ghu watch build`

## Lint commands
- Lint all: `npm run lint` (eslint .)

## Test commands
- Run all tests: `npm test` (alias for `node test`)
- Browser test bundle: `node ghu build:tests` then open `build/test/index.html`

## Run a single test
There is no dedicated single-test script. Use a minimal runner that mirrors
`test/index.js` and requires only the test file you need.

Example (core.event test only):
```sh
node -e "const {JSDOM}=require('jsdom').JSDOM;global.window=new JSDOM('').window;const {test}=require('scar');require('./test/tests/unit/core/event');test.cli({sync:true});"
```

Notes:
- The tests depend on `jsdom` and the `scar` test runner.
- If the test file needs additional setup from `test/index.js`, copy it in.

## Code style (shared)
- Indent with 4 spaces; no tabs (see `.editorconfig`).
- Line endings: LF; add final newline.
- JSON/YAML files use 2 spaces.
- Keep existing file encodings; default to ASCII when editing.

## JavaScript style
- Language: ES2020 (no TypeScript).
- Module system: CommonJS (`require`, `module.exports`).
- Formatting is enforced by ESLint; follow these highlights:
  - 4-space indentation, 1tbs braces, spaces inside keywords.
  - Single quotes; semicolons required.
  - Trailing commas are not allowed.
  - Arrow parens only when needed (as-needed).
  - Object/array spacing: `{foo: bar}`, `[a, b]`.
  - Prefer `const`; `let` when reassignment is needed.
  - `func-style`: function declarations preferred; arrow functions allowed.
  - `space-before-function-paren`: named functions no space; anonymous space.
- Imports: group `require` calls at top; keep relative paths minimal.
- File layout: constants at top, helpers below, exports at end.
- Avoid `console.log` in `src/` (warned by `src/.eslintrc`).

## JavaScript naming conventions
- `camelCase` for variables/functions.
- `PascalCase` for constructors/class-like functions.
- Constants in `SCREAMING_SNAKE_CASE` when values are static.
- Keep function names explicit; avoid overly short names unless idiomatic.

## PHP style
- Files are plain PHP classes (no namespaces here).
- Use `snake_case` for methods (`get_options`, `is_admin`).
- Constants use `SCREAMING_SNAKE_CASE`.
- Prefer early returns for error conditions.
- Avoid raising new exceptions unless the surrounding code already does so.

## Pug/HTML/CSS style
- Pug templates live under `src/_h5ai/private/php/pages/`.
- Keep generated HTML comments/banners intact (build injects version info).
- LESS is used for styles; autoprefixer/minify runs in build.

## Error handling patterns
- JavaScript: prefer explicit guards and return `null` on invalid input
  (see `src/_h5ai/public/js/lib/model/item.js`).
- PHP: use `Util::json_fail`/`Util::json_exit` for API failures.
- Avoid throwing in hot paths unless build/test code already does so.

## Testing conventions
- Tests use `scar` with `test('name', () => { ... })`.
- Assertions come from `scar` (`assert`, `insp`).
- Tests often load library modules via `test/util/reqlib.js`.

## Build details (ghu)
- `ghu.js` defines tasks for `build`, `release`, `deploy`, and `watch`.
- `build` produces the browser-ready `_h5ai` assets under `build/`.
- Do not edit `build/` output manually; edit `src/` instead.

## Repository rules
- Cursor rules: none found (`.cursor/rules/` and `.cursorrules` absent).
- Copilot rules: none found (`.github/copilot-instructions.md` absent).

## Safe defaults for agents
- Always run `npm run lint` after JS changes when feasible.
- Prefer localized changes; do not regenerate build artifacts unless asked.
- Keep license headers and version banners intact during edits.

## Useful paths
- JS client source: `src/_h5ai/public/js/`
- PHP backend: `src/_h5ai/private/php/`
- Config JSON: `src/_h5ai/private/conf/`
- Tests: `test/tests/`
- Build output: `build/` (generated)

## When unsure
- Follow the established patterns in the file you are editing.
- Keep ESLint violations at zero; mirror formatting in nearby code.
- Ask only if an API contract or build behavior is unclear.
