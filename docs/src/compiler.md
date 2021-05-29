# DaemonMode and PackageCompiler

DaemonMode and
[PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl) can be
seen as complementary:

- **PackageCompiler** allows users to compile the packages in an image system, so
  they will not take time to load them by setting the image (with -J parameter).
  
- **DaemonMode** allows users to load the packages only once, so in next
  scripts/runs they are already loaded, reducing time in new runs (not the first
  one).
  
Each one of them has their own advantages and drawbacks:

- **PackageCompiler** is able to reduce the loading time of the compiled
  packages, but it takes some time (minutes) to compile them, and it should be
  done when packages are updated to use the newest versions. Also, reduce
  greatly the loading time, but for many packages the first execution of
  functions is not reduced, mainly the loading time.

- **DaemonMode** only can reduce the loading time of one package after that
package was previously used since the Daemon run. It can applies the newest
version without delay. It cannot reduce first time, but it can reduce time
compiling all functions previously run since last Daemon run (in any program
and/or script).

The good news is that both approach can be together applied:

# DaemonMode with PackageCompiler

It is simple, you can create a simple compile script like:

```julia
# compile.jl
using PackageCompiler
using Pkg

# List of packages to compile (you can custom it)
pkgs = [:StatsBase, :CSV, :DataFrames, :LinearAlgebra, :TimerOutputs, :LoopVectorization, :FLoops, :Tullio, :DataPipes, :Chain]
# Add them
Pkg.add(string.(pkgs))
# Update to last version
Pkg.update()
# Compile to a system file
PackageCompiler.create_sysimage(pkgs; sysimage_path="./ds.jsys")
```

Then, after compiling: ```julia compile.jl``` you will have the packages compiled in an external file `ds.jsys`. You 
can decide how frequently you want to update it (I personally use it once every two weeks).

Then, my daemon script for everyday (in bash, for Linux) is `javaDSserver` (in the same directory as `compile.jl`):

```sh
#!/usr/bin/env bash
# Remove previous daemon
pkill -9 julia
# Run daemon with compiled version, using async and disabling checkbounds
julia -J/mnt/home/daniel/bin/ds.jsys --check-bounds=no -e 'using DaemonMode; serve(async=true)' &
```

Running the daemon is simple: 

```sh
$ juliaDSserver

```

And running a script is:

```sh
$ jclient script.jl
```

In that way, DaemonMode can run faster the script even first time (loading the
compiled packages). Also, all packages (compiled or non-compiled) and functions
will be run faster after first run.
