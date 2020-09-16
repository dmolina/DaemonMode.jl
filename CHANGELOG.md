# CHANGELOG

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a
Changelog](http://keepachangelog.com/).


### Changes
* By default it shares the environment in expr, and not in files. It can be changed as a parameter in server.

### Fixes

* Better behaviour when the client close the communication


## 0.1.0 - (2020-08-11)
---

### New

- Performance, because packages are maintained in memory. This is especially interesting with common external packages like CSV.jl, DataFrames.jl, ...

- The code is run using the current directory as working directory.

- Robust, if the file has an error, the server continues working (for other scripts, stops for your current one).

- It accepts parameters without problems.

- Run complete file and also specific code.

- Run in multiple modules to avoid conflicts of names.



