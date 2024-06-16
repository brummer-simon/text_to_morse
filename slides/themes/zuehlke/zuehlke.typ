#import "@preview/polylux:0.3.1": *

#let zuehlke-theme(
    aspect-ratio: "16-9",
    foreground-color: rgb("4d4d4d"),
    background-color: white,
    background-img: none,
    font: "AA Zuehlke OTPS",
    body
) = {
    // Set common page properties
    set page(
        paper: "presentation-" + aspect-ratio,
        margin: 2em,
        fill: background-color,
    )

    // Set custom background image if given
    set page(
        background: {
            set image(fit: "stretch", width: 100%, height: 100%)
            background-img
        },
        margin: 1em,
    ) if background-img != none

    // Set common text properties
    set text(fill: foreground-color, size: 25pt)

    // Set custom font if given
    set text(font: font) if font != none

    // Set heading formats
    set heading(outlined: false)
    body
}

#let slide(background: none, body) = {
    show heading: it => [
        #it.body
        #v(1em)
    ]

    set page(
        background: {
            set image(fit: "stretch", width: 100%, height: 100%)
            background
        },
    ) if background != none

  logic.polylux-slide(body)
}

#let title-slide(body) = {
    slide(background: image("assets/title_background.png"), body)
}

#let last-slide(body) = {
    slide(background: image("assets/end_background.png"), body)
}
