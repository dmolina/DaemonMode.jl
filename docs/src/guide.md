# User Guide

This package has been developed taking in account the usage easily.

# Usage

- The server is the responsible of running all julia scripts.
 
  ```sh
  julia -e 'using DaemonMode; serve()'
```

- A client, that send to the server the file to run, and return the output
  obtained.
  
```@sh
  julia -e 'using DaemonMode; runargs()' program.jl <arguments>
```

  you can use an alias 
  ```sh
  alias juliaclient='julia -e "using DaemonMode; runargs()"'
```
  
then, instead of `julia program.jl` you can do `juliaclient program.jl`. The
output should be the same, but with a lot less time.

# Running specific code


Although the function `runargs()` is the simpler way to run the client, it is not
the only function.

```@docs
```

# Typical errors

```sh
Error, cannot connect with server. Is it running?
```

It could not be connected with the server, you should check it is running, and
that the port used in both is the same one.

```sh
ERROR: could not open file '<file>'
```

the file cannot be found by the server. Remember that the file is going to be
searched using as current directory the directory in which the julia client is
run.

# Changing the port

By default the DaemonMode work in the port 3000, but in many contexts that port
can be unavailable, or been busy for another application.

it is simple to change the port, but it must be done both in the server and the client.

- In the server:

```julia
   using DaemonMode: serve

   serve(port=9000)
```

- In the client:

```julia
   using DaemonMode: runargs

   runargs(port=9000)
```

- or using the alias:

```sh
  alias juliaclient='julia -e "using DaemonMode; runargs(port=9000)"'
```

That port keyword can be add to any other parameter.

# Different contexts

In order to avoid conflict of different versions of the same library, sometimes
it is needed to run programs using different contexts  or environments.

This can be achieve with DaemonMode run different servers, each one using a
different port.

```julia
# server1.jl
using Pkg
Pkg.activate("<env_dir1>")
using DaemonMode: serve
serve(3001)
```

```julia
# server2.jl
using Pkg
Pkg.activate("<env_dir2>")
using DaemonMode: serve
serve(3002)
```

First, we run the two servers:

```sh
> julia server1.jl &
> julia server2.jl &
```

Then, to run *file1.jl* in the first context and run *file2.jl* in second
environment.

```sh
julia -e 'using DaemonMode; runargs(3001)' file1.jl
```

```sh
julia -e 'using DaemonMode; runargs(3002)' file1.jl
```

# Shared code and Conflict of names

By default each file/expression is run in a new Module to avoid any conflict of
names. This implies that each run is completely independently. 

It is possible to run the different files/expressions in the same Module, using
the parameter shared to *true* in the function `serve()`. This implies that the
variables are shared between the different clients. It could be useful to avoid
repeating evaluations, but it could produce conflict of names.
