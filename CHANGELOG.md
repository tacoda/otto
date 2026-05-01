# Changelog

## 1.0.0 — 2026-05-01

First stable release. Otto now ships with Jekyll-style conventions on top of AsciiDoc.

### Added
- **Layouts** (`_layouts/*.html.erb`) — ERB templates with `content`, `site`, `page` locals; layouts can chain via the `layout:` front matter key.
- **Includes** (`_includes/`) — partials embedded with `<%= partial 'name.html' %>`; partials may include other partials and share the layout's locals.
- **Data files** (`_data/`) — YAML and JSON files exposed as `site.data.<name>`.
- **Posts** (`_posts/YYYY-MM-DD-slug.adoc`) — date and slug parsed from filename; sorted descending in `site.posts`.
- **Drafts** (`_drafts/`) — excluded by default; `otto build --drafts` and `otto watch --drafts` include them with today's date.
- **Permalinks** — per-document `permalink:` front matter or a global `permalink:` for posts in `config.yml`. Tokens: `:year`, `:month`, `:day`, `:slug`, `:title`. Trailing-slash templates produce pretty URLs.
- **Custom collections** — declare under `collections:` in `config.yml`; items in `_<name>/` are exposed as `site.<name>`. `output: true` renders them to `/<collection>/<slug>.html`.
- **Tags & categories** — `site.tags` and `site.categories` are hashes of label → posts.
- **Front matter** — YAML `---` blocks at the top of any `.adoc` file are parsed and exposed as `{page_*}` Asciidoctor attributes plus `<%= page.* %>` in templates.
- **Site config** — `config.yml` keys are exposed as `{site_*}` attributes and `<%= site.* %>` in templates.
- **`otto post "Title"`** — scaffold a new post.
- **`otto doctor`** — sanity-check project layout.
- `GUIDE.md` quickstart and AsciiDoc primer.

### Changed
- Ruby requirement bumped to `>= 3.0`.
- Runtime dependencies declared in the gemspec (previously only in the Gemfile); `logger` added as an explicit dep for Ruby 3.5+.
- `init` scaffolds the full Jekyll-style directory structure.

## 0.1.0

Initial pre-release. AsciiDoc → HTML conversion with `init`, `build`, `serve`, `watch`, `clean`, and `generate` commands.
