# Claude Settings

```bash
(computer)% make install
```

This {re,}creates `~/.claude/settings.json` from this directory's
[settings](settings/), a collection of TOML fragments (I prefer using TOML for
configuration over JSON/YAML, because I'm not a computer).


## SessionStartup hook

One of the settings is a hook to run `context.sh` on session startup,
which does three things:

1.  Pull the repo and update `settings.json`.

2.  Ensure `~/.claude/settings.json` is up-to-date.

    Obviously Claude will always be one step behind when I make changes
    elsewhere, but it will catch up eventually.

3.  Provide Claude with my preferred hints.

    I keep a collection of small [instruction files](instructions) in Markdown
    to feed to Claude on startup with hints about how I like code to work.

    But more importantly, if a directory contains a script, it is run and the
    output sent to Claude. This allows me to have dynamic context, something
    per-project, per-machine, or version-dependent.

    One example is to run `whatnext --guide` to include the usage guide of
    [whatnext][wn] so Claude knows how to use my task files, and I don't have
    to manually update my CLAUDE.md every time it gains a new feature.

    [wn]: https://github.com/norm/whatnext
