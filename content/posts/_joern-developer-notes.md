---
title: "Joern - Developer Notes"
date: 2024-12-29
---

[Joern](https://github.com/joernio/joern) is a great open-source static program
analysis tool. I use it as a foundation for multiple projects, and I enjoy
hacking on it when I need to enhance its existing features.

This post contains my reference notes from hacking on Joern (disclaimer: I am
not a Joern maintainer). It is written for my future self and collaborators who
want to help me contribute to Joern for our work. If anyone else finds this
post helpful, great!

Official Joern resources are the authoritative sources of information. The
Joern team maintains [official documentation](https://docs.joern.io/), a
[Discord community](https://discord.com/invite/vv4MH284Hc), and [GitHub
Issues](https://github.com/joernio/joern/issues). I aim to refer to them
rather than repeat them.

These notes are (mostly) accurate for the (outdated) Joern version TODO, which
is the version that I forked from. I may update this post in the future for a
more recent Joern version.

My notes cover:
* Setting up Joern;
* Using Joern to analyze programs; and
* Developing Joern.

I primarily use Joern to analyze Python and PHP code, so these notes focus on
those two language frontends in Joern.

## Joern Setup

### Environment Setup

The Joern docs provide an
[IDE setup guide](https://docs.joern.io/developer-guide/ide-setup/) to help you
configure your Joern development environment.

I use VSCode as my code editor, so I benefit from
the provided containerized environment. The Joern repository has a
`.devcontainer` directory that describes a Docker image with installed Joern
dependencies, and a configuration file that sets up VSCode plugins for Scala
development, like the Metals language server.

Unfortunately, I am unable to directly use the provided Docker image, so I
replace it with my own (see the [Appendix](#appendix-dockerfile)). I also add
additional tools for my development tasks; for example, Joern requires PHP to
be installed on the system in order to analyze PHP projects, so I add these
directories to the Dockerfile.

To use the containerized environment, open the Joern repository in VSCode and
click the "`Reopen folder to develop in a container`" button when it appears in
the bottom right.

All shell commands in this post are assumed to be executed from within the
development container.

### Building Joern

Use the Scala Build Tools (`sbt`) utility to build Joern. `sbt` is already
installed in the containerized development environment. The `stage` command
builds the Joern components.

```
$ sbt clean
$ sbt stage
```

## Analyzing Programs

Typically, I run Joern in two steps: 1) parse the target code to construct a
Code Property Graph (CPG) saved on disk; and 2) query the CPG for my analysis
tasks.

### Parsing

Construct a CPG with `joern-parse` utility.

```
TODO
```

`joern-parse` takes target source code as input and produces a CPG as output.
You can optionally invoke the language-specific frontend parsers directly
(TODO).

```

```

`joern-parse` has generic optional flags, and also language-specific optional
flags. Not all the language-specific optional flags are documented (TODO),
or printed by the CLI help message. Source code files can help identify all
optional flags (see [Finding Frontend Arguments](#frontend-arguments)).

Use optional flags to make the parser ignore portions of the target code.

### Analyzing

Analyze the CPG with the `joern` utility.

Notes about that.


2. Analyze the CPG: `joern` utility takes the CPG as input and starts a Scala
   REPL for querying the CPG. Conveniently, the Joern query language for
   interacting with the CPG is Scala statements, which makes it very
   expressive. `joern` can also be invoked to execute a script that interacts
   with the CPG programmatically.

```
TODO
```

### Finding Frontend Arguments

Joern docs

How to find language-specific command line arguments

Python: `joern-cli/frontends/pysrc2cpg/src/main/scala/io/joern/pysrc2cpg/Main.scala`
- Explicitly lists some options
- Also adds `XTypeRecovery.parserOptions`

PHP: `joern-cli/frontends/php2cpg/src/main/scala/io/joern/php2cpg/Main.scala`
- Explicitly lists some options
- Also adds:
    `XTypeRecovery.parserOptions`,
    `XTypeStubsParser.parserOptions`,
    `DependencyDownloadConfig.parserOptions`

How to pass language-specific command line arguments

```
--language PYTHON --frontend-args <args>
```

This is also documented in TODO.

### Analysis Gotchas

**The target repository contains test files.** The target code may
contain test files that are syntactically invalid (e.g., if the target code is
a parser or interpreter), which can trip up Joern's parsing. Even when
well-formatted, test files slow down analysis unnecessarily. It is best to
exclude all test code from analysis whenever it is encountered.

**`joern-parse` outputs a different CPG than `pysrc2cpg`, which
produce 1) different analysis results and 2) non-deterministic crashes when
loaded.** I believe that `joern-parse` includes more steps in its analysis than
`pysrc2cpg`. However, a CPG produced by `joern-parse` will sometimes
(non-deterministically) cause `joern` to crash when it loads the CPG for
analysis, I am recall that the crashes often present as null references. When
Joern crashes, I always first attempt the same analysis with no changes, and
only triage further if the crash is repeatable. I do not know why this happens,
or if this happens for other frontends.

**Out of Memory errors.** You can adjust the amount of system RAM
available to the JVM when Joern runs with the `-J-Xmx{X}g` option:

```
/joern/joern-cli/target/universal/stage/pysrc2cpg -J-Xmx128g <target-repo> -o <cpg-path>.cpg
/joern/joern -J-Xmx128g <cpg-path>.cpg
```

**Joern seems unable to parse PHP code.** To parse PHP code, Joern
uses the [PHP-Parser](https://github.com/nikic/PHP-Parser) utility (see
[Environment Setup](#environment-setup)).

### Language-Specific Notes

#### Python

Class inheritance can be determined by checking either the
`inheritsFromTypeFullName` field or the `baseType` field of a `typeDecl` node.
The `baseType` field seems undocumented (as far as I can tell). The
`inheritsFromTypeFullName` field is populated with String names of the parent
classes, but the `baseType` field is populated with references to `typ` nodes.
I believe that `typ` nodes are only populated with local information. I
occasionally notice nodes that have one field populated but not the other, but
I have not noticed patterns for when this occurs.

All this to say, when I try determining parent classes of a class, I query both
the `inheritsFromTypeFullName` and `baseType` fields and take a union of the
information in each.

The `PythonAstVisitor.scala` provides a lot of helpful commentary about the
structure of class and type definitions, particularly in the
`convert(classDef: ast.ClassDef)` method.

## Developing Joern

This section contains notes for modifying Joern, organized roughly according to
my development workflow.

- **Debug**: Use print-style debugging and graph visualizations.
- **Develop**: Understand Joern's code organization to implement feature or
  fix.
- **Test**: Add test cases for new functionality or fix, and ensure all pass.
- **Format**: Run the automatic formatter.

### Debugging

I primarily use print-style debugging by add log messages in the code.

Configure the log level printed to stdout with the `SL_LOGGING_LEVEL`
environment variable:

```
$ SL_LOGGING_LEVEL=DEBUG ./joern-parse <path to target code> -o target.cpg 2> target.log
```

You can also visualize portions of the CPG. For example, to visualize the AST
of a single method named `foo`:

```
joern> cpg.method("foo").dotAst.l #> "foo.dot"
joern> exit (TODO)
$ dot -Tpng foo.dot > foo.png
```

Joern docs provide [more examples](https://docs.joern.io/export/) for
visualizing and exporting the CPG.

Joern docs provide advice for configuring an interactive Scala debugger, but I
have not figured this out yet for VSCode and Metals. I will update this post
when I do.

### Development - Code Organization

The Joern code is very modular, with significant class inheritance. Generally,
common analysis passes are implemented in a generic (non-language specific)
module, and then specialized and registered for each language front-end.

The generic passes are in the `joern-cli/frontends/x2cpg/src/main/scala/io/joern/x2cpg/passes/`
directory, while the specialized passes are in:

TODO

For example, the generic `InheritanceFullNamePass` is implemented in:
`joern-cli/frontends/x2cpg/src/main/scala/io/joern/x2cpg/passes/frontend/XInheritanceFullNamePass.scala`.

The Python specialization of



Registered passes for language specific CPG generation:
`console/src/main/scala/io/joern/console/cpgcreation/PythonSrcCpgGenerator.scala`

Language specific front end passes:
`joern-cli/frontends/pysrc2cpg/src/main/scala/io/joern/pysrc2cpg/PythonInheritanceNamePass.scala`

Generic front end passes:
`joern-cli/frontends/x2cpg/src/main/scala/io/joern/x2cpg/passes/frontend/XInheritanceFullNamePass.scala`

Analysis entry:
`joern-cli/frontends/pysrc2cpg/src/main/scala/io/joern/pysrc2cpg/CodeToCpg.scala`
- replaces carriage returns with line breaks.
- parses the code into Python AST nodes
- visits each Python AST node and converts it into a Joern CPG AST node

Invocation path:
- PythonSrcCpgGenerator -> pysrc2cpg.Main -> Py2CpgOnFileSystem

### Testing

The Joern GitHub repository automatically runs a suite of tests that must pass
before any PR can be accepted.

To locally run the full test suite:

```
$ sbt test
```

To run a language-specific frontend test suite:

```
$ sbt "pysrc2cpg / Test / testOnly"
$ sbt "php2cpg / Test / testOnly"
```

To run a specific test suite:

```
$ sbt "php2cpg / Test / testOnly / *CfgCreationPassTests"
$ sbt "pysrc2cpg / Test / testOnly / *TypeRecoveryPassTests"
```

To add a test case or suite for a language frontend, find the appropriate suite
file or directory in: `joern-cli/frontends/<language>2cpg/src/test/scala/io/joern/`.

Test fixtures are configured by registering the passes used to create the test
CPG. This is important to know if you create a new pass, or if test behavior
does not match actual Joern behavior: different passes may be registered for
the Joern build than for the test fixture. Examples of the fixture files are:
TODO.

`joern-cli/frontends/pysrc2cpg/src/test/scala/io/joern/pysrc2cpg/PySrc2CpgFixture.scala`

### Formatting

Always format code using the automatic formatter:

```
$ sbt fmt (TODO)
```

A formatting test pass is included in the test suite, and if your code is not
formatted, the tests will fail. Ensure all tests pass before contributing code
upstream, because the failed tests will prevent the contribution from being
accepted.

## Miscellanea

### Pronunciation

I believe that the Joern name has German origins and is pronounced
like the English word "yearn". This is how it sounds to me when Joern
developers say it.

Unaffiliated English speakers tend to pronounce Joern like the first syllable
of "journey".

I tend to switch my pronounciation of Joern depending on whom I am speaking to,
to avoid confusion.

### References

- Official documentation
    - [Scala specific recommendations related to Joern](https://docs.joern.io/developer-guide/learning-scala/)
    - CPG Schema documentation
    - Developer guide: https://docs.joern.io/developer-guide/contribution-guidelines/
    - Frontends developer guide: TODO
- Discord Server
- GitHub Issues
- Official [Scala 3 docs](https://docs.scala-lang.org/scala3/book/introduction.html)

### Contributing

Finally, Joern development moves fast, so commit changes back upstream sooner
rather than later. If you don't, you end up like me, maintaining a fork
multiple major releases out of date.

## Appendix: Dockerfile

As mentioned in [Development Environmnet Setup](#development-environment-setup),
the Joern Dockerfile provided in the repository does not work for me. I
replaced the `.devcontainer/Dockerfile` file with the following contents:

```
TODO
```

The original Dockerfile uses a Centos 7.9 environment, which I have replaced
with Debian 12. I vaguely remember a problem between VSCode server and Centos,
but I have not debugged the problem with the original Dockerfile. I may in the
future.

Note that I also installed libraries for using the Joern PHP frontend in the
container. You may wish to remove these if you don't intend to use it.
