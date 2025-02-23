const self_path = path self 

def _headers [] {
  {
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
}

export def main [
  --spec(-s): string
  --template(-t): string
  --output(-o): string
] {
  let input = $in
  let s = if $spec != "" {
    open -r $spec | from yaml
  } else {
    $input | from yaml
  }
  mut t = open --raw $template

  let headers = _headers
  $t = $t | str replace "___profile_header___" ( $headers.profile | get $s.language )
  $t = $t | str replace "___desiderata_header___" ( $headers.desiderata | get $s.language )
  $t = $t | str replace "___languages_header___" ( $headers.languages | get $s.language )
  $t = $t | str replace "___contacts_header___" ( $headers.contacts | get $s.language )
  $t = $t | str replace "___key_competences_header___" ( $headers.key_competences | get $s.language )
  $t = $t | str replace "___transversal_competences_header___" ( $headers.transversal_competences | get $s.language )
  $t = $t | str replace "___work_experiences_header___" ( $headers.work_experiences | get $s.language )
  $t = $t | str replace "___education_header___" ( $headers.education | get $s.language )

  $t = $t | str replace "___name___" $s.name
  $t = $t | str replace "___img___" $s.img
  $t = $t | str replace "___color___" $s.color


  if (( $s.profile | describe ) == "list<string>") {
    mut profile = $"\\begin{itemize}\n"
    for item in $s.profile {
      $profile = $profile | str replace -r '$' $"\t\\item ($item)\n"
    }
    $profile = $profile | str replace -r '$' $"\\end{itemize}"
    $t = $t | str replace "___profile___" $profile
  } else if (( $s.profile | describe ) == "string")  {
    $t = $t | str replace "___profile___" $s.profile
  } else {
    print $"(ansi red)'profile' section must either be a string or a list of strings(ansi reset)"
    return
  }

  if (( $s.desiderata | describe ) == "list<string>") {
    mut desiderata = $"\\begin{itemize}\n"
    for item in $s.desiderata {
      $desiderata = $desiderata | str replace -r '$' $"\t\\item ($item)\n"
    }
    $desiderata = $desiderata | str replace -r '$' $"\\end{itemize}"
    $t = $t | str replace "___desiderata___" $desiderata
  } else if (( $s.desiderata | describe ) == "string")  {
    $t = $t | str replace "___desiderata___" $s.desiderata
  } else {
    print $"(ansi red)'desiderata' section must either be a string or a list of strings(ansi reset)"
    return
  }

  mut languages = $"\\begin{itemize}\n"
  for item in $s.languages {
    $languages = $languages | str replace -r '$' $"\t\\item ($item)\n"
  }
  $languages = $languages | str replace -r '$' $"\\end{itemize}"
  $t = $t | str replace "___languages___" $languages

  $t = $t | str replace "___mail___" $s.contacts.mail

  $t = $t | str replace "___phone___" $s.contacts.phone

  if ( $s.contacts.links | is-not-empty ) {
    mut links = ""
    for link in $s.contacts.links {
      $links = $links | str replace -r '$' $"\\Mundus\\ \\href{($link.link)}{($link.display)} \\\\[0.4ex]\n"

    }
    $t = $t | str replace "___links___" $links
  } else {
    $t = $t | str replace "___links___" ""
  }

  mut key_comp = ""
  for comp in $s.key_competences {
    $key_comp = $key_comp | str replace -r '$' $"\t\\textsc{($comp.name)}\\\\\n"
    $key_comp = $key_comp | str replace -r '$' $"\t\\vspace{0.75em}\n"
    $key_comp = $key_comp | str replace -r '$' $"\t\\hspace*{2em}\\smaller{\\begin{minipage}[t]{\\dimexpr\\textwidth-2em\\relax}($comp.text)\\end{minipage}}\n"
  }
  $t = $t | str replace "___key_competences___" $key_comp

  if ($s.transversal_competences? | is-not-empty) {
    mut trans_comp = ""
    for comp in $s.transversal_competences {
      $trans_comp = $trans_comp | str replace -r '$' $"\t\\textsc{($comp.name)}\\\\\n"
      $trans_comp = $trans_comp | str replace -r '$' $"\t\\vspace{0.75em}\n"
      $trans_comp = $trans_comp | str replace -r '$' $"\t\\hspace*{2em}\\smaller{\\begin{minipage}[t]{\\dimexpr\\textwidth-2em\\relax}($comp.text)\\end{minipage}}\n"
    }
    $t = $t | str replace "___transversal_competences___" $trans_comp
  }

  mut work = ""
  for exp in $s.work_experiences {
    $work = $work | str replace -r '$' $"\\textsc{($exp.title)} \\textit{ - ($exp.company)}.\\\\ \\dates{($exp.dates)}\\vspace{0.5em}\\\\\n"
    $work = $work | str replace -r '$' $"\t\\hspace*{0.5em}\\begin{minipage}[t]{\\dimexpr\\textwidth-2em\\relax}($exp.description)\\end{minipage}\n"
    $work = $work | str replace -r '$' $"\\begin{itemize}\n"
    for item in ($exp.items? | default []) {
      $work = $work | str replace -r '$' $"\t\\item \\textit{($item.project)}: ($item.text)\n"
    }
    $work = $work | str replace -r '$' $"\\end{itemize}\n"
  }
  $t = $t | str replace "___work_experiences___" $work

  mut edu = ""
  $edu = $edu | str replace -r '$' $"\\begin{itemize}\n"
  for item in $s.education {
    $edu = $edu | str replace -r '$' $"\t\\item \\textsc{($item.title)} \\textit{ - ($item.institution)}\\\\ \\dates{Valutazione: ($item.grade)}\n"
  }
  $edu = $edu | str replace -r '$' $"\\end{itemize}\n"
  $t = $t | str replace "___education___" $edu

  $t 
}
