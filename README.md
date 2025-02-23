# ResuMeow
Welcome to Reslumeow! An automaic CV generator written in nu.

This brutal script allows you to create a beautifully formatted CV in LaTeX from a simple YAML input file and command-line parameters.

<h1 align="center">
  <img src="docs/imgs/mascot.jpg" alt="Local Image">
</h1>
<h3 align="center">
  <a href="docs/imgs/example_cv.pdf">View an example</a>
</h3>

## Usage

### Command Line

To generate a CV, use the following command:

```bash
nu template.nu --input <path_to_input.yaml> --template <path_to_template.tex> --output <path_to_output.tex>
```

- `--input`: Path to the YAML file containing the CV data.
- `--template`: The input to the template file to use. The only template supported as of now is [template.tex](template.tex)
- `--output`: Path where the generated .tex will be saved.

### YAML Input File

The input YAML file should be structured as follows:

- `name`: The name of the individual.
- `language`: The language in which to generate the headers - supported languages are:
  - eng
  - es
  - fr
  - it
  - de
- `img`: the path to the image to insert in the CV
- `color`: the hex code of the color of the CV
- `profile`: A list of profile descriptions.
- `desiderata`: A list of job desires or requirements.
- `languages`: A list of languages known.
- `contacts`: Contact information including `mail`, `phone`, and `links`.
- `key_competences`: A list of key competences with `name` and `text`.
- `transversal_competences`: A list of transversal competences with `name` and `text`.
- `work_experiences`: A list of work experiences with `title`, `company`, `dates`, `description`, and optional `items`.
- `education`: A list of educational qualifications with `title`, `institution`, and `grade`.

You can find an example one [here](input.yaml)

## Limitations of the Graphics

- ResuMeow will not compile the latex into a pdf; it will only generate a valid .tex file.
- The template uses a fixed layout, which may not accommodate all content if the input data is too extensive.
  - The `Competences` section must fit in one page.
  - The `Experiences` section must fit in one page.
- The color scheme is limited to a single customizable color, which may not suit all branding needs.
- The image size and placement are fixed, which might not be ideal for all types of images.

Feel free to contribute!

