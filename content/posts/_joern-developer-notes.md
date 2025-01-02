---
title: "Joern - Developer Notes"
date: 2024-12-31
---

[Joern](https://github.com/joernio/joern) is a great open-source static program
analysis tool. I use it as a foundation for multiple projects, and I enjoy
hacking on it when I need to enhance its existing features.

This post contains my reference notes from hacking on Joern (disclaimer: I am
not a Joern maintainer). The post is written for my future self and
collaborators to reference as we work. If anyone else finds this helpful,
great!

Official Joern resources are the authoritative sources of information. The
Joern team maintains [official documentation](https://docs.joern.io/), a
[Discord community](https://discord.com/invite/vv4MH284Hc), and [GitHub
Issues](https://github.com/joernio/joern/issues). I aim to refer to and
supplement them rather than repeat their contents.

These notes are (mostly) accurate for the (outdated) Joern version 2.0.385,
which is the version I forked from. I may update this post in the future
for a more recent Joern version.

I primarily use Joern to analyze Python and PHP code, so these notes focus on
Joern's language frontends for those two languages.

This post contains my notes on:
1. [Setting up Joern](#joern-setup);
2. [Using Joern to analyze programs](#analyzing-programs); and
3. [Developing Joern](#developing-joern).


## Joern Setup

This section describes setting up Joern by:

1. [Configuring my development environment](#development-environment-setup); and
2. [Building Joern from source code](#building-joern-from-source).

### Development Environment Setup

The Joern docs provide an
[IDE setup guide](https://docs.joern.io/developer-guide/ide-setup/) to help you
configure your Joern development environment.

I use VSCode as my code editor, so I benefit from the provided
[VSCode dev container](https://code.visualstudio.com/docs/devcontainers/create-dev-container).
The Joern repository provides a `.devcontainer` directory that contains a
Dockerfile to install Joern dependencies, and a configuration file that sets up
VSCode plugins for Scala development, like the Metals language server.

Unfortunately, using the provided Dockerfile image results in errors for me, so
I replace it with my own (see the [Appendix](#appendix-dockerfile)). I also add
tools for my development tasks; for example, Joern depends on a PHP utility to
parse PHP source code, so I add these dependencies to the Dockerfile.

To use the containerized environment, open the Joern repository in VSCode and
click the "`Reopen folder to develop in a container`" button when it appears in
the bottom right. You can now open a terminal in VSCode from within the
development container.

All shell commands in this post are assumed to be executed from within the
development container.

### Building Joern from Source

In the development container, use the Scala Build Tools (`sbt`) utility to
build Joern. `sbt` is already installed in the containerized development
environment.

The `stage` command builds the Joern components.

```
# sbt clean
# sbt stage
```

## Analyzing Programs

This section describes the steps I use to analyze target programs:

1. **[Parse](#parsing)** the target code into a Code Property Graph (CPG) saved on disk; and
2. **[Query](#querying)** the CPG for my analysis tasks.

I also document some "[gotchas](#analysis-gotchas)" that have tripped me up,
and tips for [finding undocumented analysis options](#finding-frontend-arguments)
from within the source code.

### Parsing

The `joern-parse` utility constructs a CPG from the target source code:

```
TODO
```

You can optionally invoke the language-specific frontend parsers directly
(TODO):

```

```

Joern has generic optional parameters, as well as language-specific optional
parameters:

```

```

Not all the language-specific optional flags are documented (TODO),
or printed by the CLI help message. Source code files can help identify all
optional flags (see [Finding Frontend Arguments](#frontend-arguments)).

### Querying

The `joern` utility loads the CPG to query. By default it starts a Scala REPL
to interact with the CPG.

```

```

Usually, I automate my analyses with the `--script` option.

```
TODO
```

### Analysis Gotchas

**The target repository contains test files.** The target code may
contain test files that are syntactically invalid (e.g., if the target code is
a parser or interpreter), which can trip up Joern's parsing. Even when
well-formatted, test files slow down analysis unnecessarily. It is best to
exclude all test code from analysis whenever it is encountered.

**`joern-parse` outputs a different CPG than `pysrc2cpg` (or other frontends).
The `joern-parse` utility runs all analysis passes to construct the full CPG.
However, invoking the language-specific frontends directly results in ONLY
constructing an AST; I believe frontends would be more aptly named `pysrc2ast`.
See the [Development](development-code-organization) section for determining
what passes are omitted when constructing an AST.

**`joern` crashes when loading CPGs**. Sometimes (non-deterministically) Joern
crashes with an error that presents as a null reference when loading CPGs. I do
not know the origin of the bug, but I always first retry the analysis with no
changes. If the crash is repeatable, then I triage further. Note that this does
not occur when loading ASTs generated by the language frontends, so I recommend
preferring AST generation if you only need features from the AST.

**Nodes in the CPG have mangled names**. I have observed bugs that result from
non-composing analysis passes executing twice; for example, a pass that takes
short names of inherited classes and expands them to fully qualified names can
only be run once, because running it twice results in doubly-expanded names
(implementation specific). If you run `joern-parse` to generate a CPG, and then
run `joern` to load the CPG, that pass may end up running twice. The name
mangling is possibly a bug that can be fixed, perhaps by implementing the
analysis to no-op if run a second time. This class of bugs can be frustrating
to track down, because the test suite of unit tests will report different
(correct results) due to only running the analysis once.

**Out of Memory errors.** You can adjust the amount of system RAM
available to the JVM when Joern runs with the `-J-Xmx{X}g` option. See the
[Joern docs](https://docs.joern.io/installation/#configuring-the-jvm-for-handling-large-codebases).

```
# ./joern-cli/target/universal/stage/pysrc2cpg -J-Xmx128g <target-repo> -o <cpg-path>.cpg
# ./joern -J-Xmx128g <cpg-path>.cpg
```

**Joern seems unable to parse PHP code.** To parse PHP code, Joern
uses the [PHP-Parser](https://github.com/nikic/PHP-Parser) utility (see
[Environment Setup](#environment-setup)).

**Python type declaration inheritance information is in both
`inheritsFromTypeFullName` field and the `baseType` field, and sometimes they
conflict.** The `inheritsFromTypeFullName` field contains string names of the
type declaration's parent classes, but the `baseType` field contains references
to `typ` nodes. The `typ` nodes are only constructed (I believe) from local
information (as opposed to references in external libraries), while the
`inheritsFromTypeFullName` fields can contain class names from external
libraries. I generally query both fields when trying to determine parent types
of a type declaration.

### Finding Frontend Arguments

You may provide language-specific arguments to the Joern frontends, but knowing
which are available is not always straightforward.
Joern provides some
[generic frontend documentation](https://docs.joern.io/frontends/) and some
language-specific documentation (e.g, for
[Python arguments](https://docs.joern.io/frontends/python/)), but not every
argument for every frontend is documented.

Language-specific frontend arguments are registered in parsers in the `Main`
module for each frontend, in the `Frontend.cmdLineParser` method, located in
files:

```
joern-cli/frontends/<lang>2cpg/src/main/scala/io/joern/<lang>2cpg/Main.scala

# Python frontend Main module
joern-cli/frontends/pysrc2cpg/src/main/scala/io/joern/pysrc2cpg/Main.scala

# PHP frontend Main module
joern-cli/frontends/php2cpg/src/main/scala/io/joern/php2cpg/Main.scala
```

For example, in the Python frontend the `Frontend.cmdLineParse` method returns
an `OParser` object containing all of the registered arguments. Some arguments
are explicitly registered in the method, and others are referred to from the
`XTypeRecovery.parserOptions` (so you need to follow that definition to
determine those arguments).

Similarly, the PHP frontend also explicitly registers arguments in the
`cmdLineParser` method, but also includes arguments defined in
`XTypeRecovery.parserOptions`, `XTypeStubsParser.parserOptions`, and
`DependencyDownloadConfig.parserOptions`.

## Developing Joern

This section contains notes for modifying Joern, organized roughly according to
my development workflow.

- **[Debugging](#debugging)**: Use print-style debugging and graph
  visualizations.
- **[Development](#development-code-organization)**: Understand Joern's code
  organization to implement feature or fix.
- **[Testing](#testing)**: Add test cases for new functionality or fix, and
  ensure all pass.
- **[Formatting](#formatting)**: Run the automatic formatter.

### Debugging

I debug issues by printing log messages, and by exporting visualizations of
generated CPGs to confirm that they match my expectations.

You can configure the log level printed to stdout with the `SL_LOGGING_LEVEL`
environment variable:

```
$ SL_LOGGING_LEVEL=DEBUG ./joern-parse <path to target code> -o target.cpg 2> target.log
```

You can export visualizations of portions of the CPG. For example, to visualize
the AST of a single method named `foo`:

```
joern> cpg.method("foo").dotAst.l #> "foo.dot"
joern> exit (TODO)
$ dot -Tpng foo.dot > foo.png
```

The Joern docs provide [more examples](https://docs.joern.io/export/) for
visualizing and exporting.

I have not used interactive Scala debugging with VSCode and Metals, but I will
update this post if I do incorporate it into my workflow.

### Development (Code Organization)

The Joern code is very modular, with significant class inheritance. This
section provides some brief notes on how some language frontends tend to be
organized. Generally, common analysis passes are implemented in a generic
(non-language specific) abstract class, and then specialized and registered for
each language front-end that uses them.

The generic passes are implemented in the directory:

Generic passes are in the `joern-cli/frontends/x2cpg/` directory and generally
named with the preceding `X` to indicate
* `joern-cli/frontends/x2cpg/src/main/scala/io/joern/x2cpg/passes/`

The language-specialized passes are implemented in the directories:
* `joern-cli/frontents/<lang>2cpg/src/main/scala/io/joern/<lang>2cpg/`

For example, the type recovery analysis passes:

```
# Generic (abstract class) type recovery pass
joern-cli/frontends/x2cpg/src/main/scala/io/joern/x2cpg/passes/frontend/XTypeRecovery.scala

# Python type recovery pass
joern-cli/frontends/pysrc2cpg/src/main/scala/io/joern/pysrc2cpg/PythonTypeRecovery.scala
```

The `joern-parse` utility registers the analyses run for each language frontend
in the `applyPostProcessingPasses` method in a `CpgGenerator` class. For
example, the Python class `PythonSrcCpgGenerator` extends `CpgGenerator`,
overrides the `applyPostProcessingPasses`, and instantiates all Python frontend
analysis passes. This class is in the file
`console/src/main/scala/io/joern/console/cpgcreation/PythonSrcCpgGenerator.scala`,
alongside files containing the `CpgGenerator` classes for the other frontends.

When the language-specific frontend is invoked outside of `joern-parse`, it
only constructs an AST (discussed in [Analysis Gotchas](#analysis-gotchas)).
The analyses used to construct the AST are typically registered in the
`buildCpg` method in the `<lang>2Cpg` class. For example, the Python frontend
defines a `Py2Cpg` class that invokes `CodeToCpg`, `ConfigFileCreationPass`,
and `DependenciesFromRequirementsTxtPass`. The `CodeToCpg` pass performs the
construction of the Joern CPG AST.

### Testing

The Joern GitHub repository automatically runs a suite of tests that must pass
before any PR can be accepted.

To locally run the full test suite:

```
# sbt test
```

To run a language-specific frontend test suite:

```
# sbt "pysrc2cpg / Test / testOnly"
# sbt "php2cpg / Test / testOnly"
```

To run a specific test suite:

```
# sbt "pysrc2cpg / Test / testOnly / *TypeRecoveryPassTests"
# sbt "php2cpg / Test / testOnly / *CfgCreationPassTests"
```

To add a test case or suite for a language frontend, find the appropriate suite
file or directory in: `joern-cli/frontends/<language>2cpg/src/test/scala/io/joern/`.

Test fixtures may not always faithfully represent the analysis passes that
execute when `joern-parse` is invoked. Test fixtures have their own set of
registered passes to test; ideally, the list of tested passes is kept in sync
with the passes registered by the utility, sometimes they are not. **When you
create a new analysis pass, be sure to register it with the analysis frontend
AND the test fixture.**

For example, the passes tested by the Python frontend test suite are registered
in the file:

```
joern-cli/frontends/pysrc2cpg/src/test/scala/io/joern/pysrc2cpg/PySrc2CpgFixture.scala
```

### Formatting

Code that is not formatted according to the project style guide will be
rejected by the test suite and cannot be contributed upstream. Use the provided
automatic formatter:

```
# sbt scalafmt
```

## Concluding Miscellanea

This post concludes with some miscellaneous notes.

### Contributing

Finally, Joern development moves fast, so commit changes back upstream sooner
rather than later. If you don't, you end up like me, maintaining a fork
multiple major releases out of date. See the
[official contribution guidelines](https://docs.joern.io/developer-guide/contribution-guidelines/).

### Pronunciation

I believe that the Joern name has German origins and is pronounced
like the English word "yearn". This is how it sounds to me when Joern
developers say it.

Unaffiliated English speakers tend to pronounce Joern like the first syllable
of "journey".

I tend to switch my pronounciation of Joern depending on whom I am speaking to,
to avoid confusion.

## Appendix: Dockerfile

As mentioned in
[Development Environmnet Setup](#development-environment-setup), the provided
Joern Dockerfile does not work for me. I replaced the
`.devcontainer/Dockerfile` file with the following:

```
FROM debian:12

# install git git-lfs
RUN apt update \
    && apt install -y zlib1g-dev curl gcc expect make wget gettext zip unzip \
                    git python3 python3-pip

# install jdk19 sbt
RUN mkdir -p /data/App \
    && cd /data/App \
    && wget https://github.com/sbt/sbt/releases/download/v1.9.8/sbt-1.9.8.zip \
    && unzip *.zip \
    && rm *.zip \
    && mv sbt/ sbt-1.9.8/ \
    && wget https://download.oracle.com/java/19/archive/jdk-19.0.2_linux-x64_bin.tar.gz \
    && tar zxvf *.tar.gz \
    && rm *.tar.gz

# install PHP 7.4 for joern-parse to work on PHP files
RUN apt install -y software-properties-common ca-certificates lsb-release apt-transport-https gnupg
RUN sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
RUN wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add -
RUN apt update && apt install -y php7.4

# JDK configuration
ENV LANG=en_US.UTF-8 \
    JAVA_HOME=/data/App/jdk-19.0.2 \
    PATH=/data/App/sbt-1.9.8/bin:/data/App/jdk-19.0.2/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

I use a Debian 12 environment in place of the original CentOS 7.9 one. I
vaguely remember encountering a problem between VSCode server and CentOS,
but I have not debugged the problem with the original Dockerfile.

Note that I also installed PHP dependencies in order to use the Joern PHP
frontend. These are only necessary if you intend to analyze PHP code.
