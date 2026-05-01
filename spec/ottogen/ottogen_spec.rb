# frozen_string_literal: true

RSpec.describe Ottogen::Ottogen do
  it 'is loaded' do
    expect(defined?(Ottogen::Ottogen)).to eq('constant')
  end

  describe '.build' do
    it 'passes site_title as an Asciidoctor attribute, resolvable in pages' do
      in_otto_project(config: "title: My Otto Site\n") do
        File.write('pages/index.adoc', "= Index\n\nMy site is {site_title}.\n")

        capture_stdout { described_class.build }

        expect(File.read('_build/index.html')).to include('My site is My Otto Site.')
      end
    end

    it 'passes custom config keys as site_<key> attributes' do
      in_otto_project(config: "title: T\nauthor: Ada Lovelace\n") do
        File.write('pages/index.adoc', "= Index\n\nWritten by {site_author}.\n")

        capture_stdout { described_class.build }

        expect(File.read('_build/index.html')).to include('Written by Ada Lovelace.')
      end
    end

    it 'still succeeds when config.yml has only a title' do
      in_otto_project(config: "title: Minimal\n") do
        File.write('pages/index.adoc', "= Index\n\nHello.\n")

        capture_stdout { described_class.build }

        expect(File.exist?('_build/index.html')).to be true
      end
    end

    it 'resolves {page_title} from front matter in rendered HTML' do
      in_otto_project do
        File.write('pages/index.adoc', <<~ADOC)
          ---
          title: My Page
          ---
          = Index

          Welcome to {page_title}.
        ADOC

        capture_stdout { described_class.build }

        expect(File.read('_build/index.html')).to include('Welcome to My Page.')
      end
    end

    it 'resolves arbitrary front matter keys in rendered HTML' do
      in_otto_project do
        File.write('pages/index.adoc', <<~ADOC)
          ---
          author: Ada Lovelace
          ---
          = Index

          Written by {page_author}.
        ADOC

        capture_stdout { described_class.build }

        expect(File.read('_build/index.html')).to include('Written by Ada Lovelace.')
      end
    end

    it 'does not include front matter delimiters in rendered HTML' do
      in_otto_project do
        File.write('pages/index.adoc', <<~ADOC)
          ---
          title: My Page
          ---
          = Index

          Body.
        ADOC

        capture_stdout { described_class.build }

        html = File.read('_build/index.html')
        expect(html).not_to include('---')
        expect(html).not_to include('title: My Page')
      end
    end

    it 'still builds pages without front matter' do
      in_otto_project do
        File.write('pages/index.adoc', "= Plain\n\nNo front matter here.\n")

        capture_stdout { described_class.build }

        expect(File.read('_build/index.html')).to include('No front matter here.')
      end
    end

    it 'wraps a page in its declared layout' do
      in_otto_project do
        FileUtils.mkdir_p('_layouts')
        File.write('_layouts/default.html.erb', '<html><body><%= content %></body></html>')
        File.write('pages/index.adoc', "---\nlayout: default\n---\n= Hi\n\nHello.\n")

        capture_stdout { described_class.build }

        html = File.read('_build/index.html')
        expect(html).to start_with('<html><body>')
        expect(html).to include('Hello.')
        expect(html).to end_with('</body></html>')
      end
    end

    it 'renders collection items when output: true' do
      in_otto_project(config: <<~YAML) do
        title: T
        collections:
          recipes:
            output: true
      YAML
        FileUtils.mkdir_p('_recipes')
        File.write('_recipes/pizza.adoc', "= Pizza\n\nDough.\n")

        capture_stdout { described_class.build }

        expect(File.exist?('_build/recipes/pizza.html')).to be true
        expect(File.read('_build/recipes/pizza.html')).to include('Dough.')
      end
    end

    it 'does not render collection items when output: false' do
      in_otto_project(config: <<~YAML) do
        title: T
        collections:
          books:
            output: false
      YAML
        FileUtils.mkdir_p('_books')
        File.write('_books/midnight.adoc', "= Midnight\n")

        capture_stdout { described_class.build }

        expect(File.exist?('_build/books/midnight.html')).to be false
      end
    end

    it 'excludes drafts by default' do
      in_otto_project do
        FileUtils.mkdir_p('_drafts')
        File.write('_drafts/wip.adoc', "= WIP\n\nDraft body.\n")

        capture_stdout { described_class.build }

        expect(File.exist?('_build/wip.html')).to be false
      end
    end

    it 'renders drafts when build is called with drafts: true' do
      in_otto_project do
        FileUtils.mkdir_p('_drafts')
        File.write('_drafts/wip.adoc', "= WIP\n\nDraft body.\n")

        capture_stdout { described_class.build(drafts: true) }

        expect(File.exist?('_build/wip.html')).to be true
        expect(File.read('_build/wip.html')).to include('Draft body.')
      end
    end

    it 'honors a per-document permalink: in front matter' do
      in_otto_project do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hello.adoc', "---\npermalink: /custom/path.html\n---\nBody.\n")

        capture_stdout { described_class.build }

        expect(File.exist?('_build/custom/path.html')).to be true
        expect(File.exist?('_build/hello.html')).to be false
      end
    end

    it 'applies a global permalink: from config.yml to posts with date tokens' do
      in_otto_project(config: "title: T\npermalink: /:year/:month/:day/:slug/\n") do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hello.adoc', "= Hello\n\nBody.\n")

        capture_stdout { described_class.build }

        expect(File.exist?('_build/2026/01/15/hello/index.html')).to be true
        expect(File.read('_build/2026/01/15/hello/index.html')).to include('Body.')
      end
    end

    it 'does not apply the global permalink to pages' do
      in_otto_project(config: "title: T\npermalink: /:year/:month/:day/:slug/\n") do
        File.write('pages/about.adoc', "= About\n\nAbout body.\n")

        capture_stdout { described_class.build }

        expect(File.exist?('_build/about.html')).to be true
      end
    end

    it 'renders posts to _build/<slug>.html' do
      in_otto_project do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hello-world.adoc', "= Hello\n\nBody.\n")

        capture_stdout { described_class.build }

        expect(File.exist?('_build/hello-world.html')).to be true
        expect(File.read('_build/hello-world.html')).to include('Body.')
      end
    end

    it 'exposes site.posts to layouts' do
      in_otto_project do
        FileUtils.mkdir_p('_layouts')
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-only-post.adoc', "= Hi\n\nBody.\n")
        File.write('_layouts/default.html.erb', '<nav><%= site.posts.first.title %></nav><%= content %>')
        File.write('pages/index.adoc', "---\nlayout: default\n---\nIndex.\n")

        capture_stdout { described_class.build }

        html = File.read('_build/index.html')
        expect(html).to include('<nav>Only Post</nav>')
      end
    end

    it 'exposes site.data.<file> in layouts' do
      in_otto_project do
        FileUtils.mkdir_p('_layouts')
        FileUtils.mkdir_p('_data')
        File.write('_data/nav.yml', "- title: Home\n  url: /\n")
        File.write('_layouts/default.html.erb', "<%= site.data.nav.first['title'] %>|<%= content %>")
        File.write('pages/index.adoc', "---\nlayout: default\n---\nBody.\n")

        capture_stdout { described_class.build }

        html = File.read('_build/index.html')
        expect(html).to include('Home|')
        expect(html).to include('Body.')
      end
    end

    it 'embeds an include declared in the page layout' do
      in_otto_project do
        FileUtils.mkdir_p('_layouts')
        FileUtils.mkdir_p('_includes')
        File.write('_includes/header.html', '<header>Site Header</header>')
        File.write('_layouts/default.html.erb', "<html><%= partial 'header.html' %><body><%= content %></body></html>")
        File.write('pages/index.adoc', "---\nlayout: default\n---\n= Hi\n\nHello.\n")

        capture_stdout { described_class.build }

        html = File.read('_build/index.html')
        expect(html).to include('<header>Site Header</header>')
        expect(html).to include('Hello.')
      end
    end

    it 'chains layouts (post -> default)' do
      in_otto_project do
        FileUtils.mkdir_p('_layouts')
        File.write('_layouts/default.html.erb', '<html><body><%= content %></body></html>')
        File.write('_layouts/post.html.erb', "---\nlayout: default\n---\n<article><%= content %></article>")
        File.write('pages/index.adoc', "---\nlayout: post\n---\n= Hi\n\nHello.\n")

        capture_stdout { described_class.build }

        html = File.read('_build/index.html')
        expect(html).to include('<html><body><article>')
        expect(html).to include('Hello.')
        expect(html).to include('</article></body></html>')
      end
    end

    it 'still emits standalone HTML for pages without a layout' do
      in_otto_project do
        File.write('pages/index.adoc', "= Hi\n\nNo layout here.\n")

        capture_stdout { described_class.build }

        html = File.read('_build/index.html')
        expect(html).to include('<!DOCTYPE html>')
        expect(html).to include('No layout here.')
      end
    end

    it 'exits with a friendly error when a page references a missing layout' do
      in_otto_project do
        File.write('pages/index.adoc', "---\nlayout: missing\n---\n= Hi\n\nHello.\n")

        buffer = StringIO.new
        original = $stdout
        $stdout = buffer
        begin
          expect { described_class.build }.to raise_error(SystemExit)
        ensure
          $stdout = original
        end

        expect(buffer.string).to include('❌')
        expect(buffer.string).to include('missing')
      end
    end

    it 'exits with a friendly error when a page has malformed front matter' do
      in_otto_project do
        File.write('pages/index.adoc', "---\ntitle: 'unclosed\n---\nBody\n")

        buffer = StringIO.new
        original = $stdout
        $stdout = buffer
        begin
          expect { described_class.build }.to raise_error(SystemExit)
        ensure
          $stdout = original
        end

        expect(buffer.string).to include('❌')
        expect(buffer.string).to include('pages/index.adoc')
      end
    end
  end

  describe '.init' do
    it 'writes a config.yml with title, description, url, and baseurl keys' do
      in_tmp_dir do
        capture_stdout { described_class.init('site') }

        config = YAML.safe_load_file('site/config.yml')
        expect(config.keys).to include('title', 'description', 'url', 'baseurl')
      end
    end

    it 'scaffolds _layouts/default.html.erb with a starter template' do
      in_tmp_dir do
        capture_stdout { described_class.init('site') }

        path = 'site/_layouts/default.html.erb'
        expect(File.exist?(path)).to be true
        expect(File.read(path)).to include('<%= content %>')
      end
    end

    it 'scaffolds an _includes/ directory' do
      in_tmp_dir do
        capture_stdout { described_class.init('site') }

        expect(Dir.exist?('site/_includes')).to be true
      end
    end

    it 'scaffolds a _data/ directory' do
      in_tmp_dir do
        capture_stdout { described_class.init('site') }

        expect(Dir.exist?('site/_data')).to be true
      end
    end

    it 'scaffolds a _posts/ directory' do
      in_tmp_dir do
        capture_stdout { described_class.init('site') }

        expect(Dir.exist?('site/_posts')).to be true
      end
    end

    it 'scaffolds a _drafts/ directory' do
      in_tmp_dir do
        capture_stdout { described_class.init('site') }

        expect(Dir.exist?('site/_drafts')).to be true
      end
    end
  end
end
