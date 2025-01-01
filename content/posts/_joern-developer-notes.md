---
title: "Joern - Developer Notes"
date: 2024-12-29
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
Issues](https://github.com/joernio/joern/issues). I aim to refer to them
rather than repeat them.

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

**`joern-parse` outputs a different CPG than `pysrc2cpg`, which sometimes
crashes when loaded.** I believe that `joern-parse` constructs a full CPG,
while the language specific frontends like `pysrc2cpg` only construct an AST
(and so are missing some analysis information). However, the CPGs will
sometimes (non-deterministically) cause `joern` to crash when loaded for
analysis ; I recall that the crashes present as null references. When Joern
crashes, I always first attempt the same analysis with no changes, and only
triage further if the crash is repeatable. If you only need features from the
AST, then you are better off using the language-specific frontend since the
ASTs do not cause crashes when loaded.

**Out of Memory errors.** You can adjust the amount of system RAM
available to the JVM when Joern runs with the `-J-Xmx{X}g` option:

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

You can provide language-specific arguments to the Joern frontends, but it is
not always straightforward to know which arguments are available.
Joern provides some
[generic frontend documentation](https://docs.joern.io/frontends/) and some
language-specific documentation (e.g, for
[Python arguments](https://docs.joern.io/frontends/python/)), but not every
argument is documented.

Language-specific frontend arguments are registered in parsers in the `Main`
module for each frontend. They follow the directory structure convention of:
`joern-cli/frontends/<lang>2cpg/src/main/scala/io/joern/<lang>2cpg/Main.scala`.

For example, the Python frontend registers arguments in the file
`joern-cli/frontends/pysrc2cpg/src/main/scala/io/joern/pysrc2cpg/Main.scala`.
In the `OParser.sequence` call, the module explicitly registers some arguments,
and also includes the arguments defined in `XTypeRecovery.parserOptions`, which
change the behavior of the Type Recovery analysis pass.

Similarly, the PHP frontend registers arguments in the file
`joern-cli/frontends/php2cpg/src/main/scala/io/joern/php2cpg/Main.scala`.
This also explicitly registers arguments in the `OParser.sequence` call, but
also includes arguments defined in `XTypeRecovery.parserOptions`,
`XTypeStubsParser.parserOptions`, and `DependencyDownloadConfig.parserOptions`.

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

### Development (Code Organization)

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

The `PythonAstVisitor.scala` provides a lot of helpful commentary about the
structure of class and type definitions, particularly in the
`convert(classDef: ast.ClassDef)` method.

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

## Concluding Miscellanea

This post concludes with some miscellaneous notes.

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
    - [Developer guide](https://docs.joern.io/developer-guide/contribution-guidelines/):
      This is primarily for procedural, with steps for communicating with the
      Joern maintainers and creating a pull request.
    - [Frontends documentioatn](https://docs.joern.io/frontends/)
- Discord Server
- GitHub Issues
- Official [Scala 3 docs](https://docs.scala-lang.org/scala3/book/introduction.html)

### Contributing

Finally, Joern development moves fast, so commit changes back upstream sooner
rather than later. If you don't, you end up like me, maintaining a fork
multiple major releases out of date.

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
