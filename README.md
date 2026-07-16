# ResuMeow

An automatic CV generator: render a YAML data file through a template to produce
LaTeX (or anything else). The renderer is a small, **CV-agnostic** Python script;
all presentation lives in the template.

<h1 align="center">
  <img src="docs/imgs/mascot.jpg" alt="Local Image">
</h1>
<h3 align="center">
  <a href="docs/imgs/example_cv.pdf">View an example</a>
</h3>

## Design: script and template are decoupled

The renderer (`render.py`) knows **nothing** about CVs. It only:

1. loads a YAML **data** file into a plain mapping,
2. optionally merges a **locale** file (chosen by the data's `language` field)
   under the `i18n` key,
3. renders a Jinja2 **template** against that context.

```
data.yaml ─────┐
locales/it.yaml ┼──►  render.py  ──►  out.tex   (or .md, .html, .txt … whatever the template emits)
template.tex ──┘      (generic)
```

Everything CV-specific — which sections exist, their order, layout, fonts,
colours, optional sections, how each item is formatted — lives in the
**template**. Translations live in the **locales**. Content lives in the
**data**. The only things the script and a template share are:

- **C1.** the data field names (e.g. `work_experiences[].title`), and
- **C2.** the `latex_escape` filter (exposed as `e_tex`).

Consequence: you can write a brand-new template — a different layout, a section
the original never had, even a different output format (see `out.md`-style
templates) — **without editing `render.py`**. Symmetrically, one template runs
against any conforming data file.

## Usage

Dependencies are declared inline in `render.py` (PEP 723) and resolved by
[uv](https://docs.astral.sh/uv/) — nothing to install manually.

```bash
uv run resumeow/render.py \
  --data     inputs/simo.yaml \
  --template resumeow/templates/default.tex \
  --locales  resumeow/locales \
  --output   inputs/out.tex
```

Then compile the `.tex` with any LaTeX engine, e.g. `pdflatex inputs/out.tex`
(ResuMeow only generates the source; it does not compile a PDF).

| Flag | Meaning |
| --- | --- |
| `-d, --data` | YAML data file (required) |
| `-t, --template` | Jinja2 template file (required) |
| `-l, --locales` | directory of `<language>.yaml` files; merged under `i18n` (optional) |
| `-o, --output` | output file; defaults to stdout |
| `--lang-field` | data key naming the locale (default `language`) |
| `--i18n-key` | context key for the locale mapping (default `i18n`) |

Omit `--output` to preview on stdout; omit `--locales` for templates that don't
use translated headers.

## Bundled templates

All of these consume the **same** data and locales — only the template differs,
and `render.py` is never touched.

| Template | Output | Notes |
| --- | --- | --- |
| `templates/default.tex` | LaTeX (PDF) | Two-column LuxSleek layout. |
| `templates/modern.tex` | LaTeX (PDF) | Single-column minimalist; accent rules. |
| `templates/cv.md` | Markdown | Portable; good for GitHub / plain text. |
| `templates/cv.html` | HTML | Self-contained styled page; open in a browser. |

```bash
# same data, different artifacts — only -t changes
uv run resumeow/render.py -d inputs/simo.yaml -l resumeow/locales -t resumeow/templates/modern.tex -o out.tex
uv run resumeow/render.py -d inputs/simo.yaml -l resumeow/locales -t resumeow/templates/cv.md      -o cv.md
uv run resumeow/render.py -d inputs/simo.yaml -l resumeow/locales -t resumeow/templates/cv.html    -o cv.html
```

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

The bundled data intentionally contains LaTeX (`ATT\&CK`, `\,` thin spaces,
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
| `language` | string | selects `locales/<language>.yaml` (e.g. `it`, `en`, `fr`, `es`, `de`) |
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

See `inputs/simo.yaml` and `inputs/sara.yaml` for complete examples.

## Layout limitations (default template)

- The `default.tex` layout is fixed-height: key competences must fit one
  column and work experience + education must fit the page.
- A single customizable colour; fixed image size/placement.

These are properties of `default.tex`, not the renderer — change them by editing
the template or writing your own.

---

> The previous Nushell renderer (`mod.nu`) is superseded by `render.py` and can
> be removed.
