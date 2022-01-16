---
date: "2022-01-15"
author: "Andreas"
---

Much of what I have learned about computer security is contained in accessible
resources. I frequently refer back to these materials, and frequently recommend
them to others. This page is my attempt at indexing some of the resources to
make references and recommendations easier. I intend for this collection to
grow as I learn and discover more.

<!-- vim-markdown-toc GitLab -->

* [CTF](#ctf)
    * [Getting Started](#getting-started)
    * [Binary Reverse Engineering and Exploitation](#binary-reverse-engineering-and-exploitation)
    * [Cryptography](#cryptography)
    * [Misc](#misc)
* [News](#news)
* [Books](#books)
    * [Programming Best Practices](#programming-best-practices)
    * [Computer Systems](#computer-systems)
    * [Computer Theory](#computer-theory)
    * [Exploitation and Reverse Engineering](#exploitation-and-reverse-engineering)
    * [Hardware and Embedded Systems](#hardware-and-embedded-systems)
    * [Writing](#writing)

<!-- vim-markdown-toc -->

# CTF

To practice, I participate in Capture the Flag competitions.

## Getting Started

CTF can feel daunting at the beginning. This section lists some early learning
materials to help get started:

[Blog post by Jaime Lightfoot](https://jaimelightfoot.com/blog/so-you-want-to-ctf-a-beginners-guide/)
: Describes what CTFs are, how to get involved, and points to many more
resource recommendations.

[PicoCTF](https://play.picoctf.org/)
: An annual CTF for high school students (but available to anyone) that
maintains all previous challenges which can be used to learn and practice new
skills.

[CTFtime](https://ctftime.org/)
: A database of past and future scheduled CTF competitions. I learn from
reviewing the write-ups of solutions from past competitions that are hosted
here.

## Binary Reverse Engineering and Exploitation

Binary reverse engineering and binary exploitation are two fundamental skills
tested by CTF competitions.

[*Hacking: The Art of Exploitation*, by Jon Erickson](https://www.amazon.com/Hacking-Art-Exploitation-Jon-Erickson/dp/1593271441)
: An introductory book with practical (but dated) examples for learning binary
exploitation.

[begin.re](https://begin.re)
: Reverse engineering course with slides and exercises for complete beginners,
created by Ophir Harpaz.

[pwn.college](https://pwn.college)
: Free content and lectures developed for ASU's Computer Systems Security
course, created by Zardus and kanak of the shellphish CTF team.

[RPISEC Modern Binary Exploitation](https://github.com/RPISEC/MBE)
: Free content and lectures developed by RPISEC CTF team and taught as a full
course at RPI.

[pwnable.kr](https://pwnable.kr)
: Set of binary exploitation CTF challenges that range from introductory to
expert.

## Cryptography

[cryptopals](https://cryptopals.com/) (sometimes referred to as the Matasano crypto challenges)
: A set of applied cryptography challenges that build on fundamental concepts,
created by
[Thomas Ptacek](https://twitter.com/tqbf),
[Sean Devlin](https://twitter.com/spdevlin),
[Alex Balducci](https://twitter.com/iamalexalright), and
[Marcin Wielgoszewski](https://twitter.com/marcinw).

## Misc

Reddit AMAs
: Multiple DEF CON CTF winners and organizers have posted Reddit AMAs
(Ask-me-anythings) describing their experiences, including
[PPP](https://www.reddit.com/r/netsec/comments/1k1oh4/we_are_the_plaid_parliament_of_pwning_ask_us/),
[Samurai](https://www.reddit.com/r/netsec/comments/y0nnu/we_are_samurai_ctf_and_we_won_defcon_ctf_this/), and
[LegitBS](https://www.reddit.com/r/Defcon/comments/q8bq31/we_are_legitimate_business_syndicate_def_con_ctf/).

[CTF Radiooo](https://ctfradi.ooo/)
: Podcast series run by [zardus](https://twitter.com/zardus) and
[adamd](https://twitter.com/adamdoupe) that covers the history of CTF, among
other things, by interviewing many of folks who were involved in the major
teams as they got started.

# News

To stay relevant, I try to keep up with computer security news.

[Risky Business](https://risky.biz/)
: Podcast hosted by Patrick Gray covering computer security current affairs and
often has insightful sponsor interviews.

[r/netsec](https://www.reddit.com/r/netsec/)
: Reddit security community.

[Twitter](https://www.twitter.com/__huckfinn__)
: Lots of noise, but also occasional quality insights from people I respect.

# Books

To learn, I read.

## Programming Best Practices

* [*The Pragmatic Programmer: From Journeyman to Master*](https://www.amazon.com/Pragmatic-Programmer-Journeyman-Master/dp/020161622X), by Andy Hunt and Dave Thomas

* [*A Philosophy of Software Design*](https://www.amazon.com/Philosophy-Software-Design-John-Ousterhout/dp/1732102201), by John Ousterhout

* [*Engineering Software as a Service: An Agile Approach to Using Cloud Computing*](http://www.saasbook.info/), by Armando Fox and David Patterson

## Computer Systems

* [*Operating Systems: Three Easy Pieces*](https://pages.cs.wisc.edu/~remzi/OSTEP/), by Andrea & Remzi Arpaci-Dusseau

* [*Linkers and Loaders*](https://www.amazon.com/Linkers-Kaufmann-Software-Engineering-Programming/dp/1558604960), by John R. Levine

* [*Linux Device Drivers*](https://lwn.net/Kernel/LDD3/), by Jonathan Corbet, Alessandro Rubini, and Greg Kroah-Hartman

* [*Container Security*](https://www.amazon.com/Container-Security-Fundamental-Containerized-Applications/dp/1492056707), by Liz Rice

## Computer Theory

* [*Introduction to the Theory of Computation*](https://www.amazon.com/Introduction-Theory-Computation-Michael-Sipser/dp/113318779X), by Michael Sipser

* [*The Formal Semantics of Programming Languages*](https://www.amazon.com/Formal-Semantics-Programming-Languages-Winskel/dp/0262731037), by Glynn Winskel

## Exploitation and Reverse Engineering

* [*Hacking: The Art of Exploitation*](https://www.amazon.com/Hacking-Art-Exploitation-Jon-Erickson/dp/1593271441), by Jon Erickson

* [*The Shellcoder's Handbook*](https://www.amazon.com/Shellcoders-Handbook-Discovering-Exploiting-Security/dp/047008023X), by Chris Anley, John Heasman, Felix Lindner,
and Gerardo Richarte

* [*Learning Linux Binary Analysis*](https://www.amazon.com/Learning-Binary-Analysis-elfmaster-ONeill/dp/1782167102), by Ryan "Elfmaster" O'Neill

* [*Practical Reverse Engineering*: x86, x64, ARM, Windows Kernel, Reversing Tools, and Obfuscation](https://www.amazon.com/Practical-Reverse-Engineering-Reversing-Obfuscation/dp/1118787315), by Bruce Dang, Alexandre Gazet, Elias Bachaalany, Sebastien Josse

* [*Practical Binary Analysis: Build Your Own Linux Tools for Binary Instrumentation, Analysis, and Disassembly*](https://www.amazon.com/Practical-Binary-Analysis-Instrumentation-Disassembly/dp/1593279124), by Dennis Andriesse

* [*A Guide to Kernel Exploitation: Attacking the Core*](https://www.amazon.com/Guide-Kernel-Exploitation-Attacking-Core/dp/1597494860), by Enrico Perla and Massimiliano Oldani


* [*The Tangled Web*: A Guide to Securing Modern Web Applications](https://www.amazon.com/Tangled-Web-Securing-Modern-Applications/dp/1593273886), by Michal Zalewski (lcamtuf)

## Hardware and Embedded Systems

* [*An Embedded Software Primer*](https://www.amazon.com/Embedded-Software-Primer-David-Simon/dp/020161569X), by David E. Simon]

* [*Designing Embedded Hardware*](https://www.amazon.com/Designing-Embedded-Hardware-Computers-Devices/dp/0596007558), by John Catsoulis

* [*The Hardware Hacker*: Adventures in Making and Breaking Hardware](https://www.amazon.com/Hardware-Hacker-Adventures-Making-Breaking/dp/159327758X), by Andrew "bunnie" Huang

* [*Inside the Machine: An Illustrated Introduction to Microprocessors and
Computer Architecture*](https://www.amazon.com/Inside-Machine-Introduction-Microprocessors-Architecture/dp/1593276680), by John Stokes

## Writing

* [*The Elements of Style*](https://www.amazon.com/Elements-Style-Fourth-William-Strunk/dp/020530902X), by William Strunk, Jr. and E.B. White

* [*On Writing Well: The Classic Guide to Writing Nonfiction*](https://www.amazon.com/Writing-Well-Classic-Guide-Nonfiction/dp/0060891548), by William Zinsser

* [*BUGS in Writing*](https://www.amazon.com/BUGS-Writing-Revised-Guide-Debugging/dp/020137921X), by Lyn Dupre
