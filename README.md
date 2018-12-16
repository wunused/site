# `wunused.com`

A simple site for information about my posts, presentations, and projects.

This site is generated with the Hugo static site generator, hosted on AWS S3,
and deployed automatically using Github Actions.

## Run locally from container

Ensure that submodules have been initialized and updated.

With docker installed, run:

```bash
$ docker build -t site:latest .
$ docker run --rm -it -p 1313:1313 site:latest
```

Browse to localhost:1313.
