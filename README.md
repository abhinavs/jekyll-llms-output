# jekyll-llms-output

A Jekyll plugin that generates two files agents and LLM crawlers expect:

- **`/llms.txt`** - an index of your content following the [llmstxt.org](https://llmstxt.org) format. Hand-curate it via `_data/llms.yml`, or let the plugin auto-generate from your collections.
- **`/llms-full.txt`** - a single concatenated dump of all your post bodies (Liquid rendered, source markdown). Useful for agents that want to ingest your whole site in one fetch.

Pairs nicely with [`jekyll-markdown-output`](https://github.com/abhinavs/jekyll-markdown-output), which writes per-page `.md` siblings.

## Install

```ruby
group :jekyll_plugins do
  gem "jekyll-llms-output"
end
```

```yaml
plugins:
  - jekyll-llms-output
```

## Configure

Defaults are sensible for a typical blog. Override via `_config.yml`:

```yaml
llms_output:
  enabled: true                  # global on/off

  index:
    enabled: true                # write /llms.txt
    output: /llms.txt
    data: llms                   # reads _data/llms.yml if it exists
    title: ~                     # default: site.title
    description: ~               # default: site.description
    collections: [posts]         # used in auto mode (no data file)

  full:
    enabled: true                # write /llms-full.txt
    output: /llms-full.txt
    collections: [posts]
    pages: false
    page_extensions: [.md, .markdown]
    separator: "\n\n---\n\n"
    include_url: true
    include_date: true
    respect_markdown_output: false  # if true, also honor jekyll-markdown-output's opt-out flag
```

## `/llms.txt` modes

### Curated (recommended)

Drop a `_data/llms.yml` in your site:

```yaml
title: Abhinav Saxena
description: |
  Personal website of Abhinav Saxena, a generalist with interests in
  entrepreneurship, software engineering, and engineering leadership.

sections:
  - heading: Agent Resources
    links:
      - title: agents.md
        url: https://www.abhinav.co/.well-known/agents.md
        description: Context and instructions for coding agents
      - title: skills.md
        url: https://www.abhinav.co/.well-known/skills.md
        description: Decision table mapping needs to specific posts

  - heading: Featured Writing
    links:
      - title: Terminal is having a second life
        url: https://www.abhinav.co/terminal-second-life
        description: Why agentic tooling has pulled the terminal back to the centre of the dev workflow
```

The plugin renders this exact structure to `/llms.txt`. Curation is preserved, you can section by topic, and you control which links appear.

### Auto

If `_data/llms.yml` is absent, the plugin generates from `index.collections` - one `## Section` per collection, one bullet per document, with the `summary` (or excerpt) as the description.

## `/llms-full.txt`

Concatenates the source body of every document in `full.collections` (and pages if `full.pages: true`), with a `# Title` header per item and a `---` separator between them.

```text
# Hello World

URL: https://example.com/2024/01/01/hello
Date: 2024-01-01T09:00:00+00:00

This is the body of the post.

---

# Another Post
...
```

### Per-document opt-out

Skip a single document from `llms-full.txt`:

```yaml
---
title: Draft thinking
llms_output: false
---
```

## Compatibility

- Jekyll 3.7+ and 4.x
- Ruby 2.7+

### GitHub Pages

GitHub Pages restricts plugins to a whitelist; this gem isn't on it. Build your site in CI (Actions, Netlify, Cloudflare Pages, Vercel) and deploy `_site/` to GH Pages.

## License

MIT. See `LICENSE`.
