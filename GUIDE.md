# Otto Guide

This guide gets you from zero to a published Otto site, then introduces the AsciiDoc syntax you'll use day to day.

## Quickstart

```sh
gem install ottogen
mkdir mysite && cd mysite
otto init
otto build
otto serve
```

Open http://127.0.0.1:8778/. You should see the welcome page wrapped in the default layout.

## Authoring a page

Pages live under `pages/`. The output path mirrors the source path, so `pages/about.adoc` becomes `/about.html`.

```adoc
---
layout: default
title: About
---
= About

This is the about page.
```

The `---` block is YAML front matter. Front matter values are exposed two ways:

- In your AsciiDoc body: `{page_title}`, `{page_url}`, `{site_title}`, etc.
- In your ERB layouts: `<%= page.title %>`, `<%= site.title %>`.

## Authoring a post

Use `otto post "My First Post"` to scaffold a new post. It creates `_posts/YYYY-MM-DD-my-first-post.adoc` with front matter pre-filled.

Posts share the same front matter and rendering pipeline as pages, with these extras:

- The date and slug are derived from the filename.
- All posts appear in `site.posts`, sorted by date descending.
- `tags:` and `categories:` in front matter feed `site.tags` and `site.categories` (hashes keyed by tag/category).

## Layouts

Layouts live in `_layouts/`. The default scaffold gives you `_layouts/default.html.erb`:

```erb
<!DOCTYPE html>
<html>
  <head><title><%= page.title %></title></head>
  <body><%= content %></body>
</html>
```

Layouts are ERB templates with three locals:

- `content` — the rendered AsciiDoc body of the page or post
- `page` — the page/post object (front matter, url, etc.)
- `site` — the site config and data (title, posts, collections, etc.)

Layouts can chain by declaring their own front matter:

```erb
---
layout: default
---
<article><%= content %></article>
```

A page using `layout: post` will be wrapped in `_layouts/post.html.erb`, which is itself wrapped in `_layouts/default.html.erb`.

## Includes (partials)

Drop reusable HTML/ERB into `_includes/`, then call `<%= partial 'name.html' %>` from any layout or other partial:

```
_includes/
  header.html
  footer.html
```

Partials see the same `site`, `page`, and `content` as the calling layout.

## Data files

Anything in `_data/` is exposed as `site.data.<filename>`:

```yaml
# _data/nav.yml
- title: Home
  url: /
- title: About
  url: /about
```

```erb
<nav>
  <% site.data.nav.each do |item| %>
    <a href="<%= item['url'] %>"><%= item['title'] %></a>
  <% end %>
</nav>
```

YAML and JSON are both supported.

## Collections

Declare a collection in `config.yml` and create a matching `_<name>/` directory:

```yaml
collections:
  recipes:
    output: true
```

Files in `_recipes/*.adoc` become `site.recipes` (an array of items). With `output: true` they render to `/recipes/<slug>.html`. With `output: false` they're available to layouts but not written to disk.

## Permalinks

Customize URLs per-document:

```adoc
---
permalink: /custom/path.html
---
```

Or set a global default for posts in `config.yml`:

```yaml
permalink: /:year/:month/:day/:slug/
```

Templates ending with `/` produce pretty URLs by writing `<path>/index.html`.

Available tokens: `:year`, `:month`, `:day`, `:slug`, `:title`.

## Drafts

Drafts live in `_drafts/<slug>.adoc` (no date prefix). They're excluded by default. Include them with the `--drafts` flag:

```sh
otto build --drafts
otto watch --drafts
```

When included, drafts use today's date and sort to the top of `site.posts`.

## Health checks

`otto doctor` verifies the project layout and reports any missing files.

---

# AsciiDoc primer

A working subset of AsciiDoc to get you productive. Full reference: https://docs.asciidoctor.org/asciidoc/latest/

## Document structure

```adoc
= Document title
:author: Ada Lovelace
:revdate: 2026-05-01

== Section 1

A paragraph.

== Section 2

Another paragraph.
```

`= Title` is the document title. `==`, `===`, etc. are subsections. Attributes (`:key: value`) below the title set document-wide variables.

## Paragraphs and text formatting

```adoc
A normal paragraph. *Bold*, _italic_, `monospace`, ~subscript~, ^superscript^.

A second paragraph separated by a blank line.
```

## Links

```adoc
https://example.com[Example]
link:about.html[About this site]
```

## Lists

```adoc
* unordered
* bullet
** nested

. ordered
. one
. two

term:: definition
another term:: another definition
```

## Code blocks

```adoc
[source,ruby]
----
def hello
  puts "world"
end
----
```

## Admonitions

```adoc
NOTE: A short note in line.

[WARNING]
====
A longer warning block
that spans multiple lines.
====
```

Available levels: `NOTE`, `TIP`, `IMPORTANT`, `WARNING`, `CAUTION`.

## Tables

```adoc
|===
| Column 1 | Column 2

| cell A1  | cell A2
| cell B1  | cell B2
|===
```

## Images

```adoc
image::pictures/cat.jpg[A cat, 400, 300]
```

The first argument is alt text; numbers are width and height.

## Includes

```adoc
include::shared/disclaimer.adoc[]
```

AsciiDoc includes pull file content in at conversion time. Paths are relative to the including file.

## Attributes in content

Reference site and page metadata anywhere in your body:

```adoc
This is {site_title}, written by {site_author}.
You're reading "{page_title}" — see all posts at {site_url}/blog.
```

Front matter keys are prefixed with `site_` (from `config.yml`) or `page_` (from the document's own front matter).

## IDs and roles

```adoc
[#main-section,role="lead"]
== Hello
```

Adds `id="main-section"` and `class="lead"` to the rendered section.
