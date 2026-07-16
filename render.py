# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "jinja2>=3.1",
#     "pyyaml>=6.0",
# ]
# ///
"""resumeow — a generic YAML -> LaTeX renderer.

The driver knows NOTHING about CVs. It:
  1. loads a YAML data file into a plain dict,
  2. optionally merges a locale file (chosen by the data's `language` field)
     under the `i18n` key,
  3. renders a Jinja2 template against that context using LaTeX-safe delimiters.

All *presentation* lives in the template, all *content* in the data, all
*translations* in the locale files. The only things the driver and the
template share are (C1) the data field names and (C2) the `latex_escape`
filter. Adding/removing/restyling a CV section never requires editing this
file.

Usage:
    uv run resumeow/render.py \
        --data inputs/simo.yaml \
        --template resumeow/templates/default.tex \
        --locales resumeow/locales \
        --output inputs/out.tex
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import jinja2
import yaml

# --- the one domain-neutral helper shared with templates -------------------

# Order matters: backslash is handled by the per-char map below, and each
# replacement is emitted verbatim (never re-scanned), so there is no double
# escaping.
_LATEX_SPECIALS = {
    "\\": r"\textbackslash{}",
    "&": r"\&",
    "%": r"\%",
    "$": r"\$",
    "#": r"\#",
    "_": r"\_",
    "{": r"\{",
    "}": r"\}",
    "~": r"\textasciitilde{}",
    "^": r"\textasciicircum{}",
}


def latex_escape(value: object) -> str:
    """Escape LaTeX special characters.

    Opt-in: apply in a template via ``\\VAR{ field | e_tex }``. Do NOT apply it
    to fields whose YAML intentionally contains LaTeX (e.g. ``ATT\\&CK`` or a
    ``\\,`` thin space) — those are already valid markup and would be mangled.
    """
    return "".join(_LATEX_SPECIALS.get(ch, ch) for ch in str(value))


# --- the generic render core -----------------------------------------------


class DataEnvironment(jinja2.Environment):
    """Jinja2 environment that resolves ``a.b`` as ``a['b']`` first.

    YAML data is full of mappings whose keys would otherwise be shadowed by
    dict methods (``items``, ``keys``, ``values`` ...). Preferring item access
    lets template authors write ``experience.title`` naturally. For an
    *optional* key that shares a name with a dict method, still guard with
    ``'key' in obj`` — a dict always has the method as a real attribute to
    fall back on, so a missing ``items`` key would otherwise resolve to the
    bound method.
    """

    def getattr(self, obj, attribute):  # noqa: A003 (Jinja hook name)
        try:
            return obj[attribute]
        except (TypeError, LookupError):
            pass
        try:
            return getattr(obj, attribute)
        except AttributeError:
            pass
        return self.undefined(obj=obj, name=attribute)


def make_env(template_dir: Path) -> jinja2.Environment:
    """A Jinja2 environment with LaTeX-safe delimiters.

    LaTeX uses ``{}`` everywhere and ``%`` for comments, so the default
    ``{{ }}`` / ``{% %}`` / ``{# #}`` would collide. We use ``\\VAR{ }`` for
    values, ``\\BLOCK{ }`` for statements and ``\\#{ }`` for comments, and we
    deliberately leave the line-statement / line-comment prefixes OFF so that
    LaTeX ``%`` comments and ``%%%%`` banners pass straight through.
    """
    env = DataEnvironment(
        loader=jinja2.FileSystemLoader(str(template_dir)),
        block_start_string=r"\BLOCK{",
        block_end_string="}",
        variable_start_string=r"\VAR{",
        variable_end_string="}",
        comment_start_string=r"\#{",
        comment_end_string="}",
        trim_blocks=True,
        lstrip_blocks=True,
        autoescape=False,
        keep_trailing_newline=True,
        undefined=jinja2.Undefined,
    )
    env.filters["e_tex"] = latex_escape
    env.filters["latex_escape"] = latex_escape
    return env


def load_yaml(path: Path) -> dict:
    try:
        with path.open(encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
    except FileNotFoundError:
        sys.exit(f"error: data file not found: {path}")
    except yaml.YAMLError as exc:
        sys.exit(f"error: could not parse YAML {path}: {exc}")
    if not isinstance(data, dict):
        kind = type(data).__name__
        sys.exit(f"error: {path} must contain a YAML mapping, got {kind}")
    return data


def build_context(
    data: dict, locales_dir: Path | None, lang_field: str, i18n_key: str
) -> dict:
    """Merge the data with its locale (if requested) into one render context.

    This is the only "convention" the driver imposes: when `--locales` is
    given, the data's `language` field names a `<language>.yaml` file whose
    contents become the `i18n` mapping. It is content-agnostic — it never
    looks at *which* keys the locale or data contain.
    """
    ctx = dict(data)
    if locales_dir is None:
        return ctx

    lang = data.get(lang_field)
    if not lang:
        sys.exit(f"error: --locales given but data has no '{lang_field}' field")
    locale_path = locales_dir / f"{lang}.yaml"
    if not locale_path.exists():
        available = ", ".join(sorted(p.stem for p in locales_dir.glob("*.yaml")))
        sys.exit(
            f"error: no locale '{locale_path.name}' in {locales_dir} "
            f"(available: {available or 'none'})"
        )
    ctx[i18n_key] = load_yaml(locale_path)
    return ctx


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        prog="resumeow", description="Generic YAML -> LaTeX renderer."
    )
    p.add_argument("-d", "--data", required=True, type=Path, help="YAML data file")
    p.add_argument(
        "-t", "--template", required=True, type=Path, help="Jinja2/LaTeX template"
    )
    p.add_argument(
        "-l",
        "--locales",
        type=Path,
        default=None,
        help="directory of <language>.yaml files, merged under `i18n`",
    )
    p.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="output file (default: stdout)",
    )
    p.add_argument(
        "--lang-field",
        default="language",
        help="data key that names the locale (default: language)",
    )
    p.add_argument(
        "--i18n-key",
        default="i18n",
        help="context key for the locale mapping (default: i18n)",
    )
    args = p.parse_args(argv)

    data = load_yaml(args.data)
    ctx = build_context(data, args.locales, args.lang_field, args.i18n_key)

    env = make_env(args.template.parent)
    try:
        template = env.get_template(args.template.name)
        rendered = template.render(ctx)
    except jinja2.TemplateNotFound:
        sys.exit(f"error: template not found: {args.template}")
    except jinja2.TemplateError as exc:
        sys.exit(f"error: template rendering failed: {exc}")

    if args.output is None:
        sys.stdout.write(rendered)
    else:
        args.output.write_text(rendered, encoding="utf-8")
        print(f"wrote {args.output}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
