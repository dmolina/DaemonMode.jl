# CHANGELOG

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a
Changelog](http://keepachangelog.com/).


## Unreleased
---

### New

### Changes

### Fixes

### Breaks


## 0.1.6 - (2021-03-15)
---

### Changes
* Improve documentation in relation with async and threads.


### Fixes
* Using @spawn instead of @async in async mode.


## 0.1.5 - (2021-05-14)

### Fixes

* Fix error with ARGS.

### News

* Multi-task version.

## 0.1.4 - (2021-02-06)

* Disable Debug Logging by default.

## 0.1.3 - (2021-02-06)

* Return the error code in runargs() when an exception occurs.

## 0.1.2 - (2021-02-05)

* Problem when the client did not run a println, but only a print.

* Fix backtrace with colors, and including the line of the file.

## 0.1.1 - (2020-10-28)

* Add parameter *print_stack* to server, that allows serve to indicate the
  complete stack when there is an error.


* By default it shares the environment in expr, and not in files. It can be
  changed as a parameter in server.


* Better behaviour when the client close the communication

* Fix error with include in the script.

## 0.1.0 - (2020-08-11)
---

- Performance, because packages are maintained in memory. This is especially interesting with common external packages like CSV.jl, DataFrames.jl, ...

- The code is run using the current directory as working directory.

- Robust, if the file has an error, the server continues working (for other scripts, stops for your current one).

- It accepts parameters without problems.

- Run complete file and also specific code.

- Run in multiple modules to avoid conflicts of names.

