```@meta
CurrentModule = DaemonMode
```

# Introduction

Julia is a great language, but the Just-in-Time compiler implies that loading a
package could takes a considerable time, this is called the _first plot
problem_. 

It is true that this time is only required for the first time (and there are
options, like using and the package
[Revise](https://github.com/timholy/Revise.jl)). However, it is a great
disadvantage when we want to use Julia to create small scripts.

This package solve that problem. Inspired in the daemon-mode of Emacs, this
package create a server/client model. This allow julia to run scripts a lot
quickly scripts in Julia, because the package is maintained in memory between
the run of several scripts (or run the same script several times).

!!! note

    This package has been mentioned in JuliaCon 2020!
    
    [![DaemonMode in JuliaCon](/assets/juliacon.png)](https://www.youtube.com/watch?v=IuwxE3m0_QQ)

# Usage

- The server is the responsible of running all julia scripts.
 
  ```julia
  julia -e 'using DaemonMode; serve()'
```

- A client, that send to the server the file to run, and return the output
  obtained.
  
```julia
  julia -e 'using DaemonMode; runargs()' program.jl <arguments>
```

  you can use an alias 
  ```sh
  alias juliaclient='julia -e "using DaemonMode; runargs()"'
```
  
then, instead of `julia program.jl` you can do `juliaclient program.jl`. The
output should be the same, but with a lot less time.
  
# Process

The process is the following:

1. The client process sends the program *program.jl* with the required arguments
   to the server.
   
2. The server receives the program name, and run it, returning the output to the
   client process. 

3. The client process receives the output and show it to the console.

# Example

Supose that we have the script *test.jl*

```julia
using CSV, DataFrames

fname = only(ARGS)
df = CSV.File(fname) |> DataFrame
println(first(df, 3))
```

The normal method is:

```sh
$ time julia test.jl tsp_50.csv
...
3×2 DataFrame
│ Row │ x        │ y          │
│     │ Float64  │ Float64    │
├─────┼──────────┼────────────┤
│ 1   │ 0.420169 │ 0.628786   │
│ 2   │ 0.892219 │ 0.673288   │
│ 3   │ 0.530688 │ 0.00151249 │

real	0m18.831s
user	0m18.670s
sys     0m0.476s
```

Only loading the CSV, DataFrames, and reading a simple file takes 18 seconds in
my computer (I accept donnations :-)). Every time that you run the program is
going to take these 18 seconds. 

using DaemonMode:

```sh
$ julia -e 'using DaemonMode; serve()' &
$ time juliaclient test.jl tsp_50.csv
3×2 DataFrames.DataFrame
│ Row │ x        │ y          │
│     │ Float64  │ Float64    │
├─────┼──────────┼────────────┤
│ 1   │ 0.420169 │ 0.628786   │
│ 2   │ 0.892219 │ 0.673288   │
│ 3   │ 0.530688 │ 0.00151249 │

real	0m18.596s
user	0m0.329s
sys	0m0.318s
```

But next times, it only use:

```sh
$ time juliaclient test.jl tsp_50.csv
3×2 DataFrames.DataFrame
│ Row │ x        │ y          │
│     │ Float64  │ Float64    │
├─────┼──────────┼────────────┤
│ 1   │ 0.420169 │ 0.628786   │
│ 2   │ 0.892219 │ 0.673288   │
│ 3   │ 0.530688 │ 0.00151249 │

real	0m0.355s
user	0m0.336s
sys	0m0.317s
```

A reduction from 18s to 0.3s, the next runs only time a 2% of the original time. 

Then you can change the file:

```julia
using CSV, DataFrames

fname = only(ARGS)
df = CSV.File(fname) |> DataFrame
println(last(df, 10))
```

Then, 
```sh
$ time juliaclient test2.jl tsp_50.csv
10×2 DataFrames.DataFrame
│ Row │ x        │ y        │
│     │ Float64  │ Float64  │
├─────┼──────────┼──────────┤
│ 1   │ 0.25666  │ 0.405932 │
│ 2   │ 0.266308 │ 0.426364 │
│ 3   │ 0.865423 │ 0.232437 │
│ 4   │ 0.462485 │ 0.049489 │
│ 5   │ 0.994926 │ 0.887222 │
│ 6   │ 0.867568 │ 0.302558 │
│ 7   │ 0.475654 │ 0.607708 │
│ 8   │ 0.18198  │ 0.592476 │
│ 9   │ 0.327458 │ 0.354397 │
│ 10  │ 0.765927 │ 0.806685 │

real	0m0.372s
user	0m0.369s
sys	0m0.300s
```

# Features

- [X] Performance, because packages are maintained in memory. This is especially interesting with common external packages like CSV.jl, DataFrames.jl, ...

- [X] The code is run using the current directory as working directory.

- [X] Robust, if the file has an error, the server continues working (for other scripts, stops for your current one).

- [X] It accepts parameters without problems.

- [X] Run complete file and also specific code.

- [X] Run in multiple modules to avoid conflicts of names.

# TODO (features in the roadmap)

- [ ] Update isinteractive() to show that the run is run in a interactive way.

- [ ] Automatic installation of required packages.

- [ ] Multi-threading version.

- [ ] Remote version (in which the Server would be in a different computer of the client).
