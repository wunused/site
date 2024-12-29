---
title: "Joern - Developer Notes"
date: 2024-09-29
---

Joern (TODO: link) is a great open-source static program analysis tool. I use
it as a foundation for past and ongoing projects, and I enjoy hacking on it
when I need to contribute new features and fixes for my work.

This post is to record some helpful reference notes for developing on Joern. It
is written for my future self and my future collaborators who want to help me
contribute to Joern for our work. If anyone else finds this post helpful,
great!

The Joern team maintains helpful official documentation (TODO: link), a Discord
community (TODO: link), and GitHub Issues (TODO: link). All are great
resources, and I will try to refer to them rather than repeat what they say.
Please use to the official documentation as authoritative sources.

These notes are (mostly) accurate for the (outdated) Joern version TODO, which
is the version that I forked and am working on. I may update this post in
the future for a more recent Joern version.

## Scala

Joern is implemented in Scala 3:

1. The official [Scala docs](https://docs.scala-lang.org/scala3/book/introduction.html)
   are a great reference for the language.
2. The Joern docs have a
   [section](https://docs.joern.io/developer-guide/learning-scala/) for
   Joern-specific Scala best practices.
3. The Metals language server improves the IDE experience (See
   [Environment Setup](#environment-setup)).

## Environment Setup

To configure your Joern development environment, the Joern docs provide
[IDE setup help](https://docs.joern.io/developer-guide/ide-setup/).

I choose to use VSCode as my editor, which makes the development environment
configuration for Joern very easy. Joern provides a containerized development
environment that starts when VSCode opens the Joern the repository. To use the
containerized environment, open the Joern repository in VSCode and click the
"`Reopen folder to develop in a container`" button when it appears in the
bottom right. This starts a Docker container with Joern dependencies installed,
and configures VSCode to use helpful plugins for Scala development, like the
Metals language server.

Unfortunately, I have had issues with the Dockerfile that defines the
containerized environment in the Joern repository, and have replaced it with my
own. See the [Appendix](#appendix-dockerfile) for my working version.

You can interact with Joern inside the development container to build, debug,
and run Joern from the command line. To access the development container, you
can open a terminal in the VSCode GUI (TODO). Otherwise, you can open a
terminal and use the `docker exec` command to access the running container by
name.

I might also modify the VSCode Joern Dockerfile (located at
`.devcontainer/Dockerfile`) to install dependencies and tools specific for the
language of the target programs that I intend to analyze. For example, the
default Dockerfile is missing some dependencies that are required for Joern to
analyze PHP projects, so I install them by adding install commands right into
the Dockerfile.

## Building Joern

Build Joern using the Scala Build Tools (`sbt`). This is already installed in
the containerized development environment. The `stage` command builds the Joern
components.

```
$ sbt clean
$ sbt stage
```

## Using Joern

I use Joern in two steps: I first parse the target code to construct a Code
Property Graph (CPG), and then query or analyze the CPG for my tasks.

1. Construct a CPG: `joern-parse` utility takes target code as input and
   outputs the CPG. Use optional flags to ignore portions of the target code
   (e.g., test code that may trip up the front-end parser - sometimes these
   contain syntactically invalid code, or add unecessary time to the parsing
   step). Note that the parser for the specific target language frontend can be
   invoked directly - this is useful for invoking
   [language-specific frontend arguments](#frontend-arguments).

```
TODO
```

2. Analyze the CPG: `joern` utility takes the CPG as input and starts a Scala
   REPL for querying the CPG. Conveniently, the Joern query language for
   interacting with the CPG is Scala statements, which makes it very
   expressive. `joern` can also be invoked to execute a script that interacts
   with the CPG programmatically.

```
TODO
```

### Frontend arguments

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

## Development Workflow

- **[Debug](#debugging)**: I use print-style debugging and graph visualizations
  to isolate issues and understand existing behavior.
- **Develop**: Implement feature of fix.
- **[Test](#testing)**: Add test cases for new functionality or fix.
- **[Format](#formatting)**: Always run the automatic formatter before
  contributing upstream.

I highly recommend contributing the change upstream as soon as it is ready, so
that you avoid (my mistake) having a fork that significantly lags behind the
upstream version. Joern development moves fast.

### Debugging

I primarily debug using print-style debugging and creating visualizations of
the CPG as dot files.

Joern docs provide advice for configuring an interactive debugger, but I have
not figured this out yet for VSCode and Metals. I may update this post if I
figure it out.

#### Logging messages

Joern uses Java's log4j for log message handling. I debug by adding debug log
messages to Joern source, and access the log on `stderr` by setting the
environment variable `SL_LOGGING_LEVEL=DEBUG` when running the `joern-parse`
utility.

```
$ SL_LOGGING_LEVEL=DEBUG ./joern-parse <path to target code> -o target.cpg 2> target.log
```

If you want to modify the log file configs directly, they are:
- Main config file: `joern-cli/src/universal/conf/log4j2.xml`
- Language-specific frontend config files: `joern-cli/src/frontends/<language>2cpg/src/main/resources/log4j2.xml`.

This provides fine-grained control over the message format, file output, and
log level, but the defaults have always been sufficient.

#### Visualizing the CPG

Joern allows you to write dot files for multiple graph representations in the
CPG, including the AST, CFG, CPG, and more.

I do this by first creating the dot file inside the Joern REPL, and then
converting the dot file into a PNG for viewing:

```
joern> cpg.method("foo").dotAst.l #> "foo.dot"
joern> exit (TODO)
$ dot -Tpng foo.dot > foo.png
```

Joern docs provide [more examples](https://docs.joern.io/export/) for
visualizing and exporting the CPG.

### Testing

The Joern GitHub repository automatically runs a suite of tests that must pass
before any PR can be accepted.

To locally run the full test suite:

```
$ sbt test (I think)
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

## Code Organization

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

## Common Issues

### Large codebases - OOM

```
/joern/joern-cli/target/universal/stage/pysrc2cpg -J-Xmx100g /frameworks/flair/ -o /frameworks/flair.cpg --venvDirs=venv --ignoreVenvDir=False --ignore-paths="/frameworks/flair/tests/,/frameworks/flair/examples/,/frameworks/flair/flair/datasets/"

/joern/joern -J-Xmx100g /frameworks/flair.cpg
```

### Non-determinism

Occasionally, Joern crashes during a run but succeeds on a following run. I am
under the impression that these crashes often present as null references. When
Joern crashes, I always first attempt the run with no changes, and only triage
further if the crash is repeatable. I have not identified the root cause of
this non-determinism.

### Building inheritance trees

Future issue:

Given some typeDecl that inherits from other classes, I want to be able to
query for all members of the typeDecl, including the inherited members.
This may require semantic analysis of the initialization function, but it
should be doable in many common cases.

## Language-Specific Notes

### PHP

You must install additional dependencies for Joern to parse PHP code. This is
because Joern uses the TODO PHP utility to first construct an AST from the PHP
code before constructing the Joern-internal CPG. This parsing code is in the
file TODO.

### Python

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

## Pronunciation

I believe that the Joern name has German origins and is pronounced to sound
like the English word "yearn". This is how I hear it when speaking with Joern
developers.

Unaffiliated English speakers tend to pronounce Joern like the first syllable
of "journey".

I tend to switch my pronounciation depending on whom I am speaking to, to avoid
confusion.

## Helpful resources

- Official documentation
- Discord Server
- GitHub Issues
- CPG Schema documentation
- Developer guide: https://docs.joern.io/developer-guide/contribution-guidelines/
- Frontends developer guide: TODO

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
