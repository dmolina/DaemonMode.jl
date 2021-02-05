using DaemonMode
using Documenter

makedocs(;
    modules=[DaemonMode],
    authors="Daniel Molina <dmolina@decsai.ugr.es>",
    repo="https://github.com/dmolina/MoodleQuestions.jl/blob/{commit}{path}#L{line}",
    sitename="DaemonMode.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://dmolina.github.io/DaemonMode.jl",
        assets=String[],
    ),
    pages=[
        "Quick Start" => "index.md",
        "Posibilities" => "posibilities.md",
        "User Guide" => "guide.md",
        "Public API" => "reference.md"
    ],
)

deploydocs(;
    repo="github.com/dmolina/DaemonMode.jl",
)
