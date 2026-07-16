\#{ resumeow — Markdown CV. Same data + render.py; a portable plain-text format. The data carries a few LaTeX-isms (\& , \,); we neutralize them HERE via the built-in `replace` filter, so the driver stays format-agnostic. }
\BLOCK{ macro tx(s) }\VAR{ s | string | replace('\\,', ' ') | replace('\\&', '&') | replace('\\_', '_') | replace('\\%', '%') }\BLOCK{ endmacro }
# \VAR{ name }

\VAR{ tx(contacts.mail) } · \VAR{ tx(contacts.phone) }\BLOCK{ for l in contacts.links or [] } · [\VAR{ l.display }](\VAR{ l.link })\BLOCK{ endfor }

\BLOCK{ if profile is string }\VAR{ tx(profile) }\BLOCK{ else }\VAR{ tx(profile | join(' ')) }\BLOCK{ endif }

## \VAR{ i18n.desiderata | capitalize }
\BLOCK{ if desiderata is string }
\VAR{ tx(desiderata) }
\BLOCK{ else }
\BLOCK{ for item in desiderata }
- \VAR{ tx(item) }
\BLOCK{ endfor }
\BLOCK{ endif }

## \VAR{ i18n.languages | capitalize }
\BLOCK{ for lang in languages }
- \VAR{ tx(lang) }
\BLOCK{ endfor }

## \VAR{ i18n.key_competences | capitalize }
\BLOCK{ for c in key_competences }
- **\VAR{ c.name }** — \VAR{ tx(c.text) }
\BLOCK{ endfor }
\BLOCK{ if transversal_competences }
## \VAR{ i18n.transversal_competences | capitalize }
\BLOCK{ for c in transversal_competences }
- **\VAR{ c.name }** — \VAR{ tx(c.text) }
\BLOCK{ endfor }
\BLOCK{ endif }
## \VAR{ i18n.work_experiences | capitalize }
\BLOCK{ for e in work_experiences }
### \VAR{ e.title } — \VAR{ e.company }
*\VAR{ e.dates }*

\VAR{ tx(e.description | trim) }
\BLOCK{ if 'items' in e }
\BLOCK{ for it in e['items'] }
- **\VAR{ it.project }**: \VAR{ tx(it.text) }
\BLOCK{ endfor }
\BLOCK{ endif }

\BLOCK{ endfor }
## \VAR{ i18n.education | capitalize }
\BLOCK{ for ed in education }
- **\VAR{ ed.title }** — \VAR{ ed.institution } (\VAR{ ed.grade })
\BLOCK{ endfor }
