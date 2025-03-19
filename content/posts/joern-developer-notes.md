---
title: "Joern - Developer Notes"
date: 2024-12-31
draft: false
toc: true
summary: A collection of reference notes for contributing to the Joern project.
---

[Joern](https://github.com/joernio/joern) is a great open-source static program
analysis tool. I use it as a foundation for multiple projects, and I enjoy
hacking on it when I need to enhance its existing features.

This post is a collection of notes from working on Joern (DISCLAIMER: I am not
a Joern maintainer). It is written primarily for collaborators and myself to
reference.

Official Joern resources are the authoritative sources of information. The
Joern team maintains [official documentation](https://docs.joern.io/), a
[Discord community](https://discord.com/invite/vv4MH284Hc), and [GitHub
Issues](https://github.com/joernio/joern/issues). I aim to refer to and
supplement them rather than repeat their contents.

These notes aim to be accurate for the (outdated) Joern version 2.0.385,
which is the version I forked from. I may update this post in the future
for a more recent Joern version.

I primarily use Joern to analyze Python and PHP code, so these notes focus on
Joern's language frontends for those two languages.

This post contains my notes on:
1. [Setting up Joern](#joern-setup);
2. [Using Joern to analyze programs](#analyzing-programs); and
3. [Developing Joern](#developing-joern).


## Joern Setup

This section describes Joern setup for:

1. [Configuring the development environment](#development-environment); and
2. [Building Joern from source](#building-from-source).

### Development Environment

The Joern docs provide an
[IDE setup guide](https://docs.joern.io/developer-guide/ide-setup/) to help
configure the Joern development environment.

I use VSCode as my code editor, so I benefit from the provided [VSCode dev
container](https://code.visualstudio.com/docs/devcontainers/create-dev-container).
The Joern repository provides a `.devcontainer` directory with a Dockerfile to
install Joern dependencies, and a configuration file for VSCode
plugins for Scala development, like the Metals language server.

Unfortunately, the provided Dockerfile results in errors for
me[^dockerfile-issues], so I replace it with my own (see the
[Appendix](#appendix-dockerfile)). I also add tools for my development tasks:
for example, Joern depends on a PHP utility
([PHP-Parser](https://github.com/nikic/PHP-Parser)) to parse PHP source code,
so I add these dependencies to the Dockerfile.

To use the containerized environment, open the Joern repository in VSCode and
click the "`Reopen folder to develop in a container`" button when it appears in
the bottom right. Now, when you open a terminal in VSCode it will execute from
within the container environment.

All shell commands in this post are assumed to be executed from within the
development container.

[^dockerfile-issues]: I don't know if these are me-issues or actual issues.

### Building from Source

In the development container, use the Scala Build Tools (`sbt`) utility to
build Joern. `sbt` is already installed in the containerized development
environment.

The `stage` command builds the Joern components.

```shell
$ sbt clean
$ sbt stage
```

## Analyzing Programs

This section describes the steps I use to analyze target programs:

1. **[Parse](#parsing)** the target code into a Code Property Graph (CPG) saved on disk; and
2. **[Query](#querying)** the CPG for my analysis tasks.

I also document some "[gotchas](#analysis-gotchas)" that I have stumbled on,
and tips for [finding undocumented analysis options](#finding-frontend-arguments)
from within the source code.

### Parsing

The `joern-parse` utility constructs a CPG from the target source code:

```shell
$ ./joern-parse <path-to-target-code> -o <output>.cpg
```

You can optionally invoke the language-specific frontend parsers directly, but
note that these construct an AST, not the full CPG. See [Analysis
Gotchas](#analysis-gotchas) for more.

```shell
$ ./joern-cli/target/universal/stage/pysrc2cpg <path-to-target-code> -o <output>.cpg
```

Joern has generic optional parameters, as well as language-specific optional
parameters:

```shell
$ ./joern-parse --language PYTHONSRC <path-to-target-code> -o <output>.cpg --frontend-args --venvDirs=venv --type-prop-iterations=3

$ ./joern-cli/target/universal/stage/pysrc2cpg <path-to-target-code> -o <output>.cpg --venvDirs=venv --type-prop-iterations=3
```

Some, but not all, language specific arguments are
[documented](https://docs.joern.io/frontends/). The best way to identify the
arguments available is to read the source code (see [Finding Frontend
Arguments](#frontend-arguments)).

### Querying

The `joern` utility takes either 1) the path to the target source code or 2)
the path to a CPG. I prefer to run `joern` with the CPG as input.

`joern` loads the CPG and begins an interactive session (this is really a
Scala REPL, which gives you a lot of power and flexibility).

```shell
$ ./joern <path-to-cpg>.cpg
<snip>
     ??? ??????? ??????????????? ????   ???
     ?????????????????????????????????  ???
     ??????   ?????????  ?????????????? ???
??   ??????   ?????????  ??????????????????
????????????????????????????  ?????? ??????
 ??????  ??????? ???????????  ??????  ?????
Version: 2.0.385+8-c3afaf32+20241004-1956
Type `help` to begin


joern>
```

Usually, I automate my analyses with the `--script` option.

```shell
$ ./joern --script <path-to-script>.sc --param inputPath="<path-to-cpg>.cpg"
```

Note that the example above assumes that the script receives the path to the
CPG through a parameter named "inputPath"; this is particular to the
script.

### Analysis Gotchas

This section documents some **issues** I have stumbled on, and some
*remediation* advice.

**Analysis takes a long time or is producing error messages.** The target code
may contain test files that are syntactically invalid (e.g., if the target code
is a parser or interpreter), which Joern is unable to parse. Even when
well-formatted, test files slow down analysis unnecessarily. *I recommend
excluding all test code from analysis with the `--ignore-paths` frontend
parameter.*

**`joern-parse` outputs a different CPG than `pysrc2cpg` (or other
frontends).** The `joern-parse` utility runs all analysis passes to construct
the full CPG. However, invoking the language-specific frontends directly
results in ONLY constructing an AST; I believe the frontends would be more aptly
named e.g., `pysrc2ast`. *See the [Development](#development-code-organization)
section for determining which passes are omitted when constructing an AST.*

**`joern` crashes when loading CPGs**. Sometimes (non-deterministically) Joern
crashes due to a null reference when loading CPGs. I do not know the root cause
of the bug, but I always first retry the analysis with no changes. If the crash
is repeatable, then I triage further. Note that this does not occur when
loading ASTs generated by the language frontends; *I recommend generating an
AST if you don't need the full CPG analyses. Otherwise, retry the analysis
after a crash.*

**Nodes in the CPG have mangled names**. I have encountered bugs resulting from
analysis passes executing twice; for example, a pass that takes short names of
inherited classes and expands them to fully qualified names should only be run
once, because running it twice could result in doubly-expanded names. When you
run `joern-parse` to generate a CPG and then run `joern` to load the CPG, that
pass may end up running twice. This (hypothetical) name mangling could be a bug
fixed by causing the analysis to no-op when run a second time. *When tracking
down these bugs, keep in mind that the unit test suite may report different
(correct results) if the test fixture only runs the analysis once.*

**Out of Memory errors.** Joern permits specifying the maximum heap memory
available to the JVM. *Use the `-J-Xmx{X}g` flag, and see the
[Joern docs](https://docs.joern.io/installation/#configuring-the-jvm-for-handling-large-codebases).*

```shell
$ ./joern-cli/target/universal/stage/pysrc2cpg -J-Xmx128g <path-to-target-code> -o <output>.cpg
$ ./joern -J-Xmx128g <output>.cpg
```

**Python type declaration inheritance information is in both
`inheritsFromTypeFullName` field and the `baseType` field, and sometimes they
disagree.** The `inheritsFromTypeFullName` field contains string names of the
type declaration's parent classes, but the `baseType` field contains references
to `typ` nodes. The `typ` nodes are only constructed (I believe) from local
information (as opposed to references in external libraries), while the
`inheritsFromTypeFullName` fields can contain class names from external
libraries. *I recommend querying both fields to determine a type declaration's
parent types.*

### Finding Frontend Arguments

You can provide language-specific arguments to the Joern frontends, but knowing
which are available is not always straightforward.
Joern provides some
[generic frontend documentation](https://docs.joern.io/frontends/) and some
language-specific documentation (e.g, for
[Python arguments](https://docs.joern.io/frontends/python/)), but not every
argument is documented.

Language-specific frontend arguments are registered in parsers in the `Main`
module for each frontend, in the `Frontend.cmdLineParser` method, located in
files:

```bash
joern-cli/frontends/<lang>2cpg/src/main/scala/io/joern/<lang>2cpg/Main.scala

# Python frontend Main module
joern-cli/frontends/pysrc2cpg/src/main/scala/io/joern/pysrc2cpg/Main.scala

# PHP frontend Main module
joern-cli/frontends/php2cpg/src/main/scala/io/joern/php2cpg/Main.scala
```

For example, in the Python frontend the `Frontend.cmdLineParse` method (below)
returns an `OParser` object containing all registered arguments. Some
arguments (e.g., `"venvDir"`) are explicitly registered in the method, but
others are included from the `XTypeRecovery.parserOptions` definition, so
follow that definition to determine the other available arguments.

```scala
val cmdLineParser: OParser[Unit, Py2CpgOnFileSystemConfig] = {
    val builder = OParser.builder[Py2CpgOnFileSystemConfig]
    import builder._
    // Defaults for all command line options are specified in Py2CpgOFileSystemConfig
    // because Scopt is a shit library.
    OParser.sequence(
      programName("pysrc2cpg"),
      opt[String]("venvDir")
        .hidden() // deprecated; use venvDirs instead. Left this here to not break existing scripts.
        .text("Virtual environment directory. If not absolute it is interpreted relative to input-dir.")
        .action((dir, config) => config.withVenvDir(Paths.get(dir))),
      opt[Seq[String]]("venvDirs")
        .text("Virtual environment directories. If not absolute they are interpreted relative to input-dir.")
        .action((value, config) => config.withVenvDirs(value.map(Paths.get(_)))),
      opt[Boolean]("ignoreVenvDir")
        .text("Specifies whether venv-dir is ignored. Default to true.")
        .action((value, config) => config.withIgnoreVenvDir(value)),
      opt[Seq[String]]("ignore-paths")
        .text("Ignores the specified path from analysis. If not absolute it is interpreted relative to input-dir.")
        .action((value, config) => config.withIgnorePaths(value.map(Paths.get(_)))),
      opt[Seq[String]]("ignore-dir-names")
        .text(
          "Excludes all files where the relative path from input-dir contains at least one of names specified here."
        )
        .action((value, config) => config.withIgnoreDirNames(value)),
      XTypeRecovery.parserOptions
    )
  }
```

## Developing Joern

This section contains notes for modifying Joern, organized roughly according to
my development workflow:

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

Configure the log level to stdout with the `SL_LOGGING_LEVEL` environment
variable:

```shell
$ SL_LOGGING_LEVEL=DEBUG ./joern-parse <path-to-target-code> -o target.cpg 2> target.log
```

You can export visualizations of portions of the CPG. For example, to visualize
the AST of a single method named `foo`:

```shell
joern> cpg.method("foo").dotAst.l #> "foo.dot"
joern> exit
$ dot -Tpng foo.dot > foo.png
```

The Joern docs provide [more examples](https://docs.joern.io/export/) for
visualizing and exporting.

I don't know how to use interactive Scala debugging with VSCode and Metals, but
I will update this post if I learn.

### Development (Code Organization)

This section provides some brief notes on how some language frontends tend to
be organized. Generally, common analysis passes are implemented in a generic
(non-language specific) abstract class, and then specialized in a concrete
class and registered for a specific language frontend to use.

Generic passes are in the `joern-cli/frontends/x2cpg/` directory and generally
named with a preceding `X`.

The language-specialized passes are implemented in the `<lang>2cpg` directories.

For example, the type recovery analysis passes:

```bash
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

When the language-specific frontend (e.g., `pysrc2cpg`) is invoked outside of
`joern-parse`, it only constructs an AST (discussed in [Analysis
Gotchas](#analysis-gotchas)). The analyses used to construct the AST are
registered in the `buildCpg` method in the `<lang>2Cpg` class. For
example, the Python frontend defines a `Py2Cpg` class that invokes `CodeToCpg`,
`ConfigFileCreationPass`, and `DependenciesFromRequirementsTxtPass`. The
`CodeToCpg` pass performs the construction of the AST in Joern.

### Testing

The Joern GitHub repository automatically runs a suite of tests that must pass
before any PR can be accepted.

To locally run the full test suite:

```shell
$ sbt test
```

To run a language-specific frontend test suite:

```shell
$ sbt "pysrc2cpg / Test / testOnly"
$ sbt "php2cpg / Test / testOnly"
```

To run a specific test suite:

```shell
$ sbt "pysrc2cpg / Test / testOnly / *TypeRecoveryPassTests"
$ sbt "php2cpg / Test / testOnly / *CfgCreationPassTests"
```

To add a test case or suite for a language frontend, find the appropriate suite
file or directory in: `joern-cli/frontends/<lang>2cpg/src/test/scala/io/joern/`.

Test fixtures may not always faithfully represent the analysis passes that
execute when `joern-parse` is invoked. Test fixtures have their own set of
registered passes to test; ideally, the list of tested passes is kept in sync
with the passes registered by the utility, but sometimes they are not. *When
you create a new analysis pass, be sure to register it with the analysis
frontend AND the test fixture.*

The passes tested by the Python frontend test suite are registered
in the file:

```bash
joern-cli/frontends/pysrc2cpg/src/test/scala/io/joern/pysrc2cpg/PySrc2CpgFixture.scala
```

```scala
class PySrcTestCpg extends DefaultTestCpg with PythonFrontend with SemanticTestCpg {

  <snip>

  override def applyPostProcessingPasses(): Unit = {
    new ImportsPass(this).createAndApply()
    new PythonImportResolverPass(this).createAndApply()
    new DynamicTypeHintFullNamePass(this).createAndApply()
    new PythonInheritanceNamePass(this).createAndApply()
    new PythonTypeRecoveryPassGenerator(this).generate().foreach(_.createAndApply())
    new PythonTypeHintCallLinker(this).createAndApply()
    new NaiveCallLinker(this).createAndApply()

    // Some of passes above create new methods, so, we
    // need to run the ASTLinkerPass one more time
    new AstLinkerPass(this).createAndApply()
    applyOssDataFlow()
  }

}
```

### Formatting

Code that is not formatted according to the project style guide will be
rejected by the test suite and cannot be contributed upstream. Use the provided
automatic formatter:

```shell
$ sbt scalafmt
```

## Concluding Miscellanea

### Contributing

Joern development moves fast, so commit changes back upstream sooner
rather than later. If you don't, you end up like me, maintaining a fork
multiple major releases out of date. See the
[official contribution guidelines](https://docs.joern.io/developer-guide/contribution-guidelines/).

### Pronunciation

I believe that the Joern name is German and is pronounced like the
English word "yearn". This is what I think it sounds like when Joern developers
say it.

Unaffiliated English speakers tend to pronounce it like the first syllable
of "journey".

I just tend to switch my pronunciation Joern depending on whom I am speaking
to.

## Appendix: Dockerfile

As mentioned in the
[Development Environmnet Setup Section](#development-environment), the provided
Joern Dockerfile does not work for me. I replaced the
`.devcontainer/Dockerfile` with the following:

```dockerfile
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

Note that I also install PHP dependencies to use the Joern PHP frontend. These
are only necessary if you intend to analyze PHP code.
