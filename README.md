Model Runner
============

Model Runner is a simple utility for running [CBMC][cbmc-link] model checks on C
programs.  What makes this tool better than using makefiles or shell scripts is
that it provides the ability to define modules that can be re-used between
scenarios.  This allows for the easy substitution for real implementations of
software and shadow implementations.  A shadow implementation is one that
provides the same interface, but simulates the implementation from a model check
perspective in order to verify that the software under model behaves under any
possible input or output through the shadow implementation.

[cbmc-link]: https://www.cprover.org/cbmc/

Scenarios
---------

A scenario, aptly given the `.scenario` extension, includes a sequence of
optionss to be passed to CBMC, and a list of modules and files that make up the
scenario under test.  Options are provided via the `set` command.  These can be
defined in both modules and scenarios. The latest definition -- that is the last
set to occur in the last module defined or in the scenario file itself -- is the
definition used by set.  If the user wishes to remove a definition, then `unset`
can be used.  `set` takes one argument, which is the command-line option to be
set, as well as an optional value.  A special form of `set`, called `set+` can
be used when multiple command-line options of the same kind are to be provided.
For instance, when adding include paths, the following sequence would be the
same as requesting `-I include -I /sys/include -I /usr/include` from the CBMC
command-line:

    set+ -I include
    set+ -I /sys/include
    set+ -I /usr/include

If an equal sign is used in a `set`, then the key for override is left of the
equal sign, and the argument is to the right of the equal sign. When this
definition is emitted to CBMC, it will be emitted with the equal sign.  For
instance:

    set -DFOO=BAR
    set -DFOO=BAZ

In this example, the `-D` option is passed to CBMC, setting `FOO` to `BAR`. The
second set overrides this first set, setting `FOO` to `BAZ`.  _Technically_, the
whole left-hand side, `-DFOO` is the key, but in practice, this works just fine.

The `sourcedir` command can be used to set one or more source directories for
reading source files.  Files can be defined in the scenario relative to one of
these source directories.

A `sourcefiles` block is used to start a list of source files to be used in this
secenario.  For example:

    sourcefiles {
        frobulator.c
        frobulator_model_main.c
    }

The `require` command is used to require a module.  For instance:

    require shadow/memcpy_normal

This will cause the utility to search the shadow subdirectory for a module
named `memcpy_normal.module`  All source files and definitions from that file
will be pulled into the scenario file.

By default, the model runner will run a single model check using all of the
values and files defined by the scenario file.  However, it is also possible to
have a scenario file cover multiple scenarios under model check.  In this case,
the `scenario` keyword allows for multiple scenarios to run.  For example:

    rootdir ..
    set+ -I include
    set -DSCENARIO=GENERIC
    
    sourcefiles {
        common.c
        scenario_model_main.c
    }
    
    scenario one {
        set -DSCENARIO=ONE
        sourcefiles {
            scennario_one.c
        }
    }
    
    scenario two {
        set -DSCENARIO=TWO
        sourcefiles {
            scennario_two.c
        }
    }

In this scenario file, two scenarios, named `one` and `two` are defined.  Each
inherit the global settings and source files.  Each override a setting and
include an additional source file.  The model runner runs both scenarios, one
right after the other.

Modules
-------

A module, given the `.module` extension, works just like a scenario, except that
it is not executed.

Startup
-------

To run this utility, either start it from the model check directory or give it a
single command-line argument, which is the model check directory from which to
run.  The utility will perform a recursive scan of all files in the directory.
All `.scenario` files are

Hashing
-------

Model check scenarios can take many hours to run.  In order to save time, when
there are many model checks to run, the model runner can be configured to cache
previous runs by passing the `-C` command-line option.  With this option, a hash
will be computed by loading each source file through a dependency check from the
compiler, (whatever `CC` is set to in the environment), and caching the
filename, contents of each file provided, and computed evaluation tree of each
scenario.  When a scenario passes, this hash will be recorded in the `.cache`
subdirectory in the current working directory (which in this case **MUST** be in
a different tree than the model directory).  For any cached result, the model
check will be skipped.  In this way, model checks will only have to be rerun if
something changes, either in the scenario, or in the source tree.  Additionally,
the contents of the model runner binary, the `cbmc` binary, and the `CC`
binary will be included in this hash, so that if the model runner, the version
of CBMC, or the version of `CC` change, then the model checks are each rerun.

The `.cache` directory can be deleted to start model checking from scratch.
Otherwise, with `-C` enabled, model checking will become incremental.
