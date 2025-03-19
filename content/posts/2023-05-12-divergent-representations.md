---
title: "SQLite CVE-2022-35737 and Divergent Representations"
date: 2023-05-12
draft: false
summary: A summary of publications around my discovery of CVE-2022-35737 and the compiler optimizations that enabled its exploitation.
---

Last summer, I discovered and disclosed SQLite CVE-2022-35737 while working
with Trail of Bits. I've written about different aspects of the vulnerability
in a few different places, and received feedback from online communities. This
post collects the different pieces of the story into one place.

I first described the vulnerability in a
[blog post](https://blog.trailofbits.com/2022/10/25/sqlite-vulnerability-july-2022-library-api/)
hosted by Trail of Bits. The disclosure was well received, and I was very
grateful for the kind words about the blog post in the
[Hacker News discussion](https://news.ycombinator.com/item?id=33329184) and
the
[Reddit r/programming post](https://www.reddit.com/r/programming/comments/ydb4uk/stranger_strings_an_exploitable_flaw_in_sqlite/).
Even though the vulnerability is non-trivial to exploit, the security community
took notice. Credit is due to the SQLite developers who took quick action to
patch the vulnerability, and to the CERT/CC team for helping us disclose it.

While trying to exploit the vulnerability, I discovered that a compiler
optimization created a "divergent representation" in the version of SQLite that
I was analyzing. The divergent representation enabled me to overwrite the saved
return address on the stack and reach the vulnerable function return statement,
which I would not otherwise be able to do. I wrote a separate
[blog post about divergent representations](https://blog.trailofbits.com/2022/11/10/divergent-representations-variable-overflows-c-compiler/). The
[Hacker News discussion](https://news.ycombinator.com/item?id=33546491) about
divergent representations was less enthusiastic than the one about the SQLite
vulnerability.

I followed this line of work on divergent representations by submitting a
[paper](/publications/divergent-reps.pdf)
to the Workshop on Offensive Security (WOOT) '23, co-located with the IEEE
Symposium on Security and Privacy (Oakland). In the paper, we describe
divergent representations, show how a divergent representation enables the
exploitation of SQLite CVE-2022-35737, and show that divergent representations
occur with regular frequency. The paper was accepted, and I will present the
work later this month.
