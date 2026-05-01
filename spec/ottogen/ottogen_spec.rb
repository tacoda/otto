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
  end
end
