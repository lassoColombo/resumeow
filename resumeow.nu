let headers = {
  "profile": {
    "it": "profilo",
    "eng": "profile",
    "fr": "profil",
    "es": "perfil",
    "de": "profil"
  },
  "desiderata": {
    "it": "desiderata",
    "eng": "wishes",
    "fr": "souhaits",
    "es": "deseos",
    "de": "wünsche"
  },
  "languages": {
    "it": "lingue",
    "eng": "languages",
    "fr": "langues",
    "es": "idiomas",
    "de": "sprachen"
  },
  "contacts": {
    "it": "contatti",
    "eng": "contacts",
    "fr": "contacts",
    "es": "contactos",
    "de": "kontakte"
  },
  "key_competences": {
    "it": "competenze chiave",
    "eng": "key competences",
    "fr": "compétences clés",
    "es": "competencias clave",
    "de": "schlüsselkompetenzen"
  },
  "transversal_competences": {
    "it": "competenze trasversali",
    "eng": "transversal competences",
    "fr": "compétences transversales",
    "es": "competencias transversales",
    "de": "übergreifende kompetenzen"
  },
  "work_experiences": {
    "it": "esperienze lavorative",
    "eng": "work experiences",
    "fr": "expériences professionnelles",
    "es": "experiencias laborales",
    "de": "berufserfahrungen"
  },
  "education": {
    "it": "istruzione",
    "eng": "education",
    "fr": "éducation",
    "es": "educación",
    "de": "bildung"
  }
}

def main [--input: string, --output: string] {
  mut template = open --raw template.tex
  let data = open $input

  $template = $template | str replace "___profile_header___" ( $headers.profile | get $data.language )
  $template = $template | str replace "___desiderata_header___" ( $headers.desiderata | get $data.language )
  $template = $template | str replace "___languages_header___" ( $headers.languages | get $data.language )
  $template = $template | str replace "___contacts_header___" ( $headers.contacts | get $data.language )
  $template = $template | str replace "___key_competences_header___" ( $headers.key_competences | get $data.language )
  $template = $template | str replace "___transversal_competences_header___" ( $headers.transversal_competences | get $data.language )
  $template = $template | str replace "___work_experiences_header___" ( $headers.work_experiences | get $data.language )
  $template = $template | str replace "___education_header___" ( $headers.education | get $data.language )

  $template = $template | str replace "___name___" $data.name
  $template = $template | str replace "___img___" $data.img
  $template = $template | str replace "___color___" $data.color


  if (( $data.profile | describe ) == "list<string>") {
    mut profile = $"\\begin{itemize}\n"
    for item in $data.profile {
      $profile = $profile | str replace -r '$' $"\t\\item ($item)\n"
    }
    $profile = $profile | str replace -r '$' $"\\end{itemize}"
    $template = $template | str replace "___profile___" $profile
  } else if (( $data.profile | describe ) == "string")  {
    $template = $template | str replace "___profile___" $data.profile
  } else {
    print $"(ansi red)'profile' section must either be a string or a list of strings"
    exit 1
  }

  if (( $data.desiderata | describe ) == "string") {
    mut desiderata = $"\\begin{itemize}\n"
    for item in $data.desiderata {
      $desiderata = $desiderata | str replace -r '$' $"\t\\item ($item)\n"
    }
    $desiderata = $desiderata | str replace -r '$' $"\\end{itemize}"
    $template = $template | str replace "___desiderata___" $desiderata
  } else if (( $data.desiderata | describe ) == "string")  {
    $template = $template | str replace "___desiderata___" $data.desiderata
  } else {
    print $"(ansi red)'desiderata' section must either be a string or a list of strings"
    exit 1
  }

  mut languages = $"\\begin{itemize}\n"
  for item in $data.languages {
    $languages = $languages | str replace -r '$' $"\t\\item ($item)\n"
  }
  $languages = $languages | str replace -r '$' $"\\end{itemize}"
  $template = $template | str replace "___languages___" $languages

  $template = $template | str replace "___mail___" $data.contacts.mail

  $template = $template | str replace "___phone___" $data.contacts.phone

  if ( $data.contacts.links | is-not-empty ) {
    mut links = ""
    for link in $data.contacts.links {
      $links = $links | str replace -r '$' $"\\Mundus\\ \\href{($link.link)}{($link.display)} \\\\[0.4ex]\n"

    }
    $template = $template | str replace "___links___" $links
  } else {
    $template = $template | str replace "___links___" ""
  }

  mut key_comp = ""
  for comp in $data.key_competences {
    $key_comp = $key_comp | str replace -r '$' $"\t\\textsc{($comp.name)}\\\\\n"
    $key_comp = $key_comp | str replace -r '$' $"\t\\vspace{0.75em}\n"
    $key_comp = $key_comp | str replace -r '$' $"\t\\hspace*{2em}\\smaller{\\begin{minipage}[t]{\\dimexpr\\textwidth-2em\\relax}($comp.text)\\end{minipage}}\n"
  }
  $template = $template | str replace "___key_competences___" $key_comp

  if ($data.transversal_competences? | is-not-empty) {
    mut trans_comp = ""
    for comp in $data.transversal_competences {
      $trans_comp = $trans_comp | str replace -r '$' $"\t\\textsc{($comp.name)}\\\\\n"
      $trans_comp = $trans_comp | str replace -r '$' $"\t\\vspace{0.75em}\n"
      $trans_comp = $trans_comp | str replace -r '$' $"\t\\hspace*{2em}\\smaller{\\begin{minipage}[t]{\\dimexpr\\textwidth-2em\\relax}($comp.text)\\end{minipage}}\n"
    }
    $template = $template | str replace "___transversal_competences___" $trans_comp
  }

  mut work = ""
  for exp in $data.work_experiences {
    $work = $work | str replace -r '$' $"\\textsc{($exp.title)} \\textit{ - ($exp.company)}.\\\\ \\dates{($exp.dates)}\\vspace{0.5em}\\\\\n"
    $work = $work | str replace -r '$' $"\t\\hspace*{0.5em}\\begin{minipage}[t]{\\dimexpr\\textwidth-2em\\relax}($exp.description)\\end{minipage}\n"
    $work = $work | str replace -r '$' $"\\begin{itemize}\n"
    for item in $exp.items {
      $work = $work | str replace -r '$' $"\t\\item \\textit{($item.project)}: ($item.text)\n"
    }
    $work = $work | str replace -r '$' $"\\end{itemize}\n"
  }
  $template = $template | str replace "___work_experiences___" $work

  mut edu = ""
  $edu = $edu | str replace -r '$' $"\\begin{itemize}\n"
  for item in $data.education {
    $edu = $edu | str replace -r '$' $"\t\\item \\textsc{($item.title)} \\textit{ - ($item.institution)}\\\\ \\dates{Valutazione: ($item.grade)}\n"
  }
  $edu = $edu | str replace -r '$' $"\\end{itemize}\n"
  $template = $template | str replace "___education___" $edu


  $template | save --force $output
}
