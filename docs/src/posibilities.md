# Posibilities

This package allow users to run its source code a lot faster. However, you could
have doubts about the limitations of running a script through DaemonMode. 

This section is to prove you that you can do more than expected.

## Parameter Options

## Error Stack

Current version of Daemon can show the Error Stack in a very similar way than
using directly julia. 

- Colors: The message error is remarked using
  [Crayons.jl](https://github.com/KristofferC/Crayons.jl). 

- Number of calls: The calls due to DaemonMode are hidden, to improve  the readibility.

For instance, with the following file bad.jl:

```sh
function fun2(a)
    println(a+b)
end

function fun1()
    fun2(4)
end

fun1()
``` 
Directly with julia:
```sh
$ julia bad.jl
ERROR: LoadError: UndefVarError: b not defined
Stacktrace:
 [1] fun2(::Int64) at /mnt/home/daniel/working/DaemonMode/test/bad.jl:2
 [2] fun1() at /mnt/home/daniel/working/DaemonMode/test/bad.jl:6
 [3] top-level scope at /mnt/home/daniel/working/DaemonMode/test/bad.jl:9
 [4] include(::Function, ::Module, ::String) at ./Base.jl:380
 [5] include(::Module, ::String) at ./Base.jl:368
 [6] exec_options(::Base.JLOptions) at ./client.jl:296
 [7] _start() at ./client.jl:506
in expression starting at /mnt/home/daniel/working/DaemonMode/test/bad.jl:9
```
or in color:
![Results with julia](assets/julia_bad.png)

with DaemonMode it gaves:
```
$ julia -e 'using DaemonMode; runargs()' bad.jl
ERROR: LoadError: UndefVarError: b not defined
Stacktrace:
 [1] fun2 at /mnt/home/daniel/working/DaemonMode/test/bad.jl:2
 [2] fun1 at /mnt/home/daniel/working/DaemonMode/test/bad.jl:6
 [3] top-level scope at /mnt/home/daniel/working/DaemonMode/test/bad.jl:9
```

or in color:

![Results with jclient](assets/jclient_bad.png)

## Logging


## Error Stack
