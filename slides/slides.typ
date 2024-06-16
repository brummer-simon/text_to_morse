#import "@preview/polylux:0.3.1": *
#import "themes/zuehlke/zuehlke.typ": *

#show: zuehlke-theme.with()

// Part 1: Introduction
#title-slide[
    #align(center + horizon)[
        #v(4em)

        = How to build a Linux Kernel Module in Rust? \ A brief introduction.

        by Simon Brummer

        RustFest 2024
    ]

    #pdfpc.speaker-note(
        ```md
        - Working as an embedded Software Engineer for Zühlke Engineering
        - Until now I earn my money mostly C/C++ and Python.
        - First experiments with Rust in 2015.
        - After failing to outsmart the borrow checker, I became convinced that
          there is something behind the core ideas.
        - Since then I write most of private projects in Rust and published a few small crates.

        How did I end up here?

        - The announced Rust support in the Linux Kernel peaked my curiosity. So I wanted to try it out.
        - I implemented a kernel module task from my university in Rust.
        - The RustFest CFP was announced and I though this could be a topic for a talk.
        - Now I am standing in here to show you what I've built.

        T: Now that you know a little bit about me. Being an introduction talk, I want
           to know a little bit more about the audience.
        ```
    )
]

#slide[
    #align(center)[
        == Lets start with a few questions:
    ]

    #line-by-line()[
        - Who uses Linux (VM/WSL installations count)?
        - Who configured a Linux Kernel manually?
        - Who worked with Linux Kernel code written in C?
        - Who worked with Linux Kernel code written in Rust?
        - Who is familiar with morse code?
    ]

    #pdfpc.speaker-note(
        ```md
        T: The morse code question will be important later. So lets start
        with the task we want to solve.
        ```
    )
]

// Part 2: Background
#slide[
    #align(center + horizon)[
        = The Task:\ Write a character device to convert \ text to morse code!
    ]

    #pdfpc.speaker-note(
        ```md
        - What is a character device? Well it's a file.
        - Its a device that communicates by processing byte sequences.
          These byte sequences are exchanged via file operations like
          open, close, read, write.
        ```
    )
]

#slide[
    #align(center)[
        == Write a character device to convert text to morse code!
    ]

    Requirements:

    #line-by-line()[
        - Device files are created/removed on kernel module loading/unloading.
        - The number of managed devices is configurable.
        - Device access is synchronized.
        - A Device implements basic file operations.
        - Errors sources are handled properly (OOM, encoding, signals...).
    ]

    #pdfpc.speaker-note(
        ```md
        T: Now that we have a task to work towards, lets take
           a look at the tools we are working with.
        ```
    )
]

#slide[
    #align(center)[
        == What are our available tools?

        #image("assets/kernel_space_drawio.png", width: 60%, height: 80%, fit: "stretch")
    ]

    #pdfpc.speaker-note(
        ```md
        T: The most limiting factor are missing kernel abstractions.
        Lets take a look at the current state of Rust support in the Linux kernel.
        ```
    )
]

#slide[
    #align(center)[
        == What is available in the current mainline Kernel (v6.8)?
    ]

    #only("1-4")[
        #line-by-line()[
            - Build system integration. Requires LLVM.
            - Basic tooling support (rust-analyzer & documentation generation).
            - Wrapper over network driver interfaces.
            - A network driver implementation for Asix PHYs.
        ]
    ]

    #only(5)[
        #align(center + horizon)[
            = Not much :(
        ]
    ]

    #pdfpc.speaker-note(
        ```md
        T: In other words: Not much.
        ```
    )
]

#slide[
    #align(center)[
        == Reasons for slow adaptation of Rust in Linux
    ]

    #line-by-line()[
        - Gradual change instead of "move fast and break things".
        - Maintainers need to become Rust developers.
        - Contribution rules are not made to add new languages.
    ]

    #pdfpc.speaker-note(
        ```md
        - Why? Multiple reasons:
            - "Move fast and break thing isn't a thing in the kernel"
            - Kernel maintainers need to become rust developers.
            - Linux contribution rules are not made to add languages.
            Problematic rules are:
                - No duplicate drivers.
                - No code without in-tree usage.
            - Kernel abstractions are mostly added with new drivers and a lot are
              in the making:
                - Android Binder Driver (android sandboxing)
                - Apple AGX GPU driver (Apple GPU)
                - Nova GPU driver (AI craze Nvidia GPU)

        T: If no character device was merged yet and therefore
        no abstractions are available: What are we using instead?
        ```
    )
]

#slide[
    #align(center)[
        == What Linux version are we using then?
    ]

    #align(horizon + center)[
        #image("assets/linux_repos_drawio.png", width: 100%, height: 80%, fit: "stretch")
    ]

    #pdfpc.speaker-note(
        ```md
        - The rust branch offers a glimpse into a potential future.

        T: Now that we have an overview of our tools lets take a look at
        our virtual kernel development environment.
        ```
    )
]

#slide[
    #align(center)[
        == Virtual Kernel development environment
    ]

    #only(1)[
        #align(center + horizon)[
            = Why do we want a virtual environment?
        ]
    ]

    #only(2)[
        #align(center + horizon)[
            #image("assets/saw.jpg", width: 90%, height: 75%, fit: "stretch")
        ]
    ]

    #only(3)[
        #side-by-side[
            #align(center + horizon)[
                #image("assets/buildroot_logo.png", fit: "cover")
            ]
        ][
            #align(center + horizon)[
                #image("assets/linux_logo.jpg", fit: "cover")
            ]
        ][
            #align(center + horizon)[
                #image("assets/qemu_logo.png", fit: "cover")
            ]
        ]
    ]

    #pdfpc.speaker-note(
        ```md
        - Why are we using a virtual environment?
            - Linux is a monolithic kernel -> Modules are plugins -> Panics are mapped to kernel panics.
            - The kernel needs to support various architectures. These can be simulated to an extent.
            - Debuggers would not work as they need to stop the debugged process.

        - For our purposes we use buildroot to build a tiny linux userland (bash, ssh, vim)
        - Qemu is used as the hardware emulator.
        - Starting Qemu with a linux kernel and a preconfigured rootfs, creates a test environment
          accessable via SSH.
        - I automated all these steps with bash and make.
        - All resources are available on github with a length README explaining everything
          in detail. Building from scratch takes roughly 45m.

        T: Lets play around with the morse code module and take a look at the code afterwards.
        ```
    )
]

// Part 3: Demo & Walk through
#slide[
    #align(horizon + center)[
        = Demo time!
    ]

    #pdfpc.speaker-note(
        ```md
        Show in Demo:

        - Enable Rust support in Linux.
        - Build and deploy module.
        - Load module show devices
        - Reload module with a custom devices / errors. Show sysfs maybe.
        - Use cat to show the content. Blocked IO.
        - Use echo to write SOS. Cat something really large.

        Show in dev env:

        - Linux configuration
        - Rust support and sample code
        - Build and login

        Show in code:

        - Entry point: Module Macro + init function
        - Fileoperations:
            - open
            - release
            - write
            - read

        T: This was the short demo, leading to question: 
           Should I write my kernel modules in Rust?
        ```
    )
]

// Part 4: Closing
#slide[
    #align(center)[
        == Summary: Should I write my kernel modules in Rust?
    ]

    #only(2)[
        #align(center + horizon)[
            = It depends.
        ]
    ]

    #only(3)[
        #side-by-side()[
            #v(1em)

            == In-tree Modules

            - Your module might improve the ecosystem.
            - Talk to the Rust-For-Linux Developers. They help with
              abstraction development.
        ][
            #v(1em)

            == Out-tree Modules

            Its to early for most use cases. Wait a few releases.
        ]
    ]

    #pdfpc.speaker-note(
        ```md
        - In-tree modules: Talk to the Rust-For-Linux Developers.
          Your module might be a valid use-case to merge more Rust code into
          the mainline kernel improving the overall ecosystem.

        - Out-of-tree modules. Wait a few releases until more is available.
        ```
    )
]

#slide[
    #align(center)[
        == Lessions learned
    ]

    - Rust plays well together with plain C.
    - Fearless concurrency is a thing, especially in the kernel space.
    - Proper tooling without cargo can be hard to setup.
    - Abstractions are currently limited.

    #pdfpc.speaker-note(
        ```md
        - Rust language mechanisms map well to C, although the Kernels
          interface design shows in the abstraction.
        ```
    )
]

#slide[
    #align(center)[
        == Resources

        #align(center + horizon)[
            #figure(
                image("assets/qr_code.png", width: 70%, height: 70%, fit: "contain"),
                caption: [
                    https://github.com/brummer-simon/text_to_morse
                ],
                supplement: none,
                numbering: none,
            )
        ]
    ]
]

#slide[
    #align(center)[
        == Thank you for your attention.
    ]

    #table(columns: (1fr, 3fr), stroke: none, [
        #image("assets/profile_simon_brummer.jpg", fit: "cover")
    ], [
        #table(columns: (auto), stroke: none,
            [Simon Brummer],
            [Software Developer],
        )
        #v(1em)
        #table(columns: (1fr, 3fr), stroke: none,
            [E-Mail:],    [simon.brummer\@zuehlke.com],
            [Fediverse:], [\@GrandmasterBash\@chaos.social],
            [Github:],    [https://github.com/brummer-simon],
        )
      ],
    )

    #pdfpc.speaker-note(
        ```md
        - I stay during the impl days. Feel free approach me.
        - Let's take the remaining time for a Q&A session.

        T: Thanks for your attention and see you on the impl days.
        ```
    )
]

#last-slide[
]

