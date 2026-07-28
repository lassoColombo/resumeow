# ResuMeow

**Your CV as data.**

Write your CV once, as YAML. Render it through any of the bundled templates — or your own — into LaTeX, Markdown or HTML, in five languages, without ever touching the renderer.

<h1 align="center">
  <img src="docs/imgs/mascot.jpg" alt="ResuMeow mascot">
</h1>
<h3 align="center">
  <a href="docs/imgs/example_cv.pdf">View an example</a>
</h3>

---

- [ResuMeow](#resumeow)
  - [Why?](#why?)
  - [Installation](#installation)
    - [Dependencies](#dependencies)
  - [Quick start](#quick-start)
  - [Design - script and template are decoupled](#design---script-and-template-are-decoupled)
  - [Usage](#usage)
  - [Bundled templates](#bundled-templates)
  - [Writing a template](#writing-a-template)
    - [Add a section without touching the script](#add-a-section-without-touching-the-script)
    - [Escaping](#escaping)
  - [Data schema](#data-schema)
  - [Mentions](#mentions)

## Why?

Because maintaining a CV is more painful than it should be:
- `the Italian and English versions drifted apart again`
- `this recruiter wants a sober single-column PDF, that one wants plain text for their ATS`
- `I just want to add a certifications section without fighting a LaTeX layout`

ResuMeow separates the three things a CV is made of — **content** (YAML data), **translations** (locale files), **presentation** (templates) — so each concern is edited in exactly one place:

```bash
# same data, different artifacts — only -t changes
uv run render.py -d cv.yaml -l locales -t templates/sleek.tex -o out.tex
uv run render.py -d cv.yaml -l locales -t templates/ats.tex   -o ats.tex
uv run render.py -d cv.yaml -l locales -t templates/cv.md     -o cv.md
```

Switching language is a one-line change in the data (`language: it`); switching look is a different `-t`.

## Installation

```bash
git clone git@github.com:lassoColombo/resumeow.git
cd resumeow
```

### Dependencies

- [uv](https://docs.astral.sh/uv/) — Python dependencies (`jinja2`, `pyyaml`) are declared inline in `render.py` (PEP 723) and resolved by uv on first run; nothing to install manually.
- a LaTeX distribution (e.g. TeX Live) to compile the `.tex` templates — ResuMeow only generates the source, it does not compile a PDF.

## Quick start

```bash
# render the bundled example through the default template
uv run render.py \
  --data     docs/spec.yaml \
  --template templates/default.tex \
  --locales  locales \
  --output   out.tex

# compile with any LaTeX engine
pdflatex out.tex
```

Omit `--output` to preview on stdout; omit `--locales` for templates that don't use translated headers. `docs/spec.yaml` is a complete example data file — copy it and replace Friedrich Mice's existential competences with your own.

## Design - script and template are decoupled

The renderer (`render.py`) knows **nothing** about CVs. It only:

1. loads a YAML **data** file into a plain mapping,
2. optionally merges a **locale** file (chosen by the data's `language` field)
   under the `i18n` key,
3. renders a Jinja2 **template** against that context.

```
data.yaml ──────┐
locales/it.yaml ┼──►  render.py  ──►  out.tex   (or .md, .html, .txt … whatever the template emits)
template.tex ───┘     (generic)
```

Everything CV-specific — which sections exist, their order, layout, fonts,
colours, optional sections, how each item is formatted — lives in the
**template**. Translations live in the **locales**. Content lives in the
**data**. The only things the script and a template share are:

- **C1.** the data field names (e.g. `work_experiences[].title`), and
- **C2.** the `latex_escape` filter (exposed as `e_tex`).

Consequence: you can write a brand-new template — a different layout, a section
the original never had, even a different output format (see the `cv.md` /
`cv.html` templates) — **without editing `render.py`**. Symmetrically, one
template runs against any conforming data file.

## Usage

```bash
uv run render.py -d <data.yaml> -t <template> [-l <locales-dir>] [-o <output>]
```

| Flag | Meaning |
| --- | --- |
| `-d, --data` | YAML data file (required) |
| `-t, --template` | Jinja2 template file (required) |
| `-l, --locales` | directory of `<language>.yaml` files; merged under `i18n` (optional) |
| `-o, --output` | output file; defaults to stdout |
| `--lang-field` | data key naming the locale (default `language`) |
| `--i18n-key` | context key for the locale mapping (default `i18n`) |

## Bundled templates

All of these consume the **same** data and locales — only the template differs,
and `render.py` is never touched.

| Template | Output | Notes |
| --- | --- | --- |
| `templates/default.tex` | LaTeX (PDF) | Two-column LuxSleek layout; filled accent sidebar. |
| `templates/sleek.tex` | LaTeX (PDF) | Refined two-column sidebar; accent small-caps headers. |
| `templates/sleek-dark.tex` | LaTeX (PDF) | Dark theme; full-page background tinted from `color`. |
| `templates/sleek-rosepine.tex` | LaTeX (PDF) | sleek-dark recoloured to the Rosé Pine Ember palette (hardcoded; ignores `color`). |
| `templates/modern.tex` | LaTeX (PDF) | Single-column minimalist; accent rules. |
| `templates/swiss.tex` | LaTeX (PDF) | Minimal; grayscale, section labels in a left gutter. |
| `templates/editorial.tex` | LaTeX (PDF) | Minimal; centered, circular photo, lots of whitespace. |
| `templates/hairline.tex` | LaTeX (PDF) | Minimal; light two-column split by a hairline (`paracol`). |
| `templates/ats.tex` | LaTeX (PDF) | ATS-safe & convention-following: single column, experience-first, no photo/colour, keywords stay extractable. |
| `templates/cv.md` | Markdown | Portable; good for GitHub / plain text. |
| `templates/cv.html` | HTML | Self-contained styled page; open in a browser. |

The three minimal templates (`swiss`, `editorial`, `hairline`) use **one photo
and no accent hue** — the YAML `color` is reused only as a near-black ink for
titles and rules, so leaving it dark keeps them grayscale while a vivid `color`
still tints them. `editorial` needs `tikz`; `hairline` needs `paracol` (both in
a standard TeX Live).

The Markdown and HTML templates show that *format-specific* concerns live in the
template, not the driver: the data carries a few LaTeX-isms (`\&`, `\,`), so
those templates define a one-line `tx()` macro that neutralises them with the
built-in `replace` filter, and the HTML template adds `| escape` for HTML safety.

## Writing a template

Templates are [Jinja2](https://jinja.palletsprojects.com/) with **LaTeX-safe
delimiters**, so the engine's syntax never collides with LaTeX `{}` or `%`:

| Purpose | Delimiter | Example |
| --- | --- | --- |
| value | `\VAR{ … }` | `\VAR{ name }`, `\VAR{ contacts.mail }` |
| logic | `\BLOCK{ … }` | `\BLOCK{ for e in work_experiences }` … `\BLOCK{ endfor }` |
| comment | `\#{ … }` | `\#{ this is dropped }` |

LaTeX `%` comments and `%%%%` banners pass through untouched (Jinja line
statements/comments are disabled on purpose).

Field access prefers mapping keys, so `experience.title` means
`experience['title']`. **Exception:** a key that shares a name with a Python
dict method (most relevantly `items`) must be accessed as `e['items']` and
guarded with `\BLOCK{ if 'items' in e }`, otherwise it resolves to the method.

### Add a section without touching the script

Say you want a `certifications` list:

1. Add it to the data:
   ```yaml
   certifications:
     - CKAD — CNCF, 2025
     - CKA — CNCF, 2026
   ```
2. Add a header to each locale you use, e.g. `locales/it.yaml`:
   ```yaml
   certifications: certificazioni
   ```
3. Render it in the template:
   ```latex
   \headright{\VAR{ i18n.certifications }}
   \begin{itemize}
   \BLOCK{ for c in certifications }
   \item \VAR{ c }
   \BLOCK{ endfor }
   \end{itemize}
   ```

`render.py` is never edited.

### Escaping

The example data intentionally contains LaTeX (`ATT\&CK`, `\,` thin spaces,
`\href{…}`), so the default template does **not** auto-escape. If your data is
plain prose and you want LaTeX specials escaped, apply the filter explicitly:

```latex
\VAR{ profile | e_tex }
```

Do not apply `e_tex` to fields that already contain intentional LaTeX.

## Data schema

| Field | Type | Notes |
| --- | --- | --- |
| `name` | string | |
| `language` | string | selects `locales/<language>.yaml` (bundled: `de`, `en`, `es`, `fr`, `it`) |
| `img` | string | path to the picture |
| `color` | string | hex colour, no `#` (e.g. `1B1F2F`) |
| `profile` | string \| list | rendered as text or a bullet list |
| `desiderata` | string \| list | rendered as text or a bullet list |
| `languages` | list | |
| `contacts` | map | `mail`, `phone`, `links` (list of `{link, display}`; may be empty/absent) |
| `key_competences` | list | items of `{name, text}` |
| `transversal_competences` | list | optional; items of `{name, text}` |
| `work_experiences` | list | items of `{title, company, dates, description}` + optional `items` (list of `{project, text}`) |
| `education` | list | items of `{title, institution, grade}` |

See `docs/spec.yaml` for a complete example.

## Mentions

- The default template's layout is derived from the LuxSleek-CV LaTeX template.
- Dependency management is handled entirely by [uv](https://docs.astral.sh/uv/) via PEP 723 inline metadata.
