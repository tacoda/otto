# frozen_string_literal: true

require 'date'

RSpec.describe Ottogen::Post do
  describe '.read' do
    it 'parses YYYY-MM-DD-slug from the filename' do
      in_tmp_dir do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hello-world.adoc', "= Hello\n\nBody.\n")

        post = described_class.read('_posts/2026-01-15-hello-world.adoc')

        expect(post.date).to eq(Date.new(2026, 1, 15))
        expect(post.slug).to eq('hello-world')
      end
    end

    it 'parses front matter via the shared FrontMatter parser' do
      in_tmp_dir do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hi.adoc', "---\ntitle: Greetings\n---\n= Hi\n\nBody.\n")

        post = described_class.read('_posts/2026-01-15-hi.adoc')

        expect(post.front_matter).to eq('title' => 'Greetings')
        expect(post.body).to eq("= Hi\n\nBody.\n")
      end
    end

    it 'raises Post::Error when the filename does not match YYYY-MM-DD-slug.adoc' do
      in_tmp_dir do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/not-a-post.adoc', "= Hi\n")

        expect { described_class.read('_posts/not-a-post.adoc') }
          .to raise_error(Ottogen::Post::Error)
      end
    end
  end

  describe '#title' do
    it 'falls back to a titleized slug when not in front matter' do
      in_tmp_dir do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hello-world.adoc', "= Hi\n")

        post = described_class.read('_posts/2026-01-15-hello-world.adoc')

        expect(post.title).to eq('Hello World')
      end
    end

    it 'uses the front matter title when present' do
      in_tmp_dir do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hi.adoc', "---\ntitle: Greetings\n---\nBody.\n")

        post = described_class.read('_posts/2026-01-15-hi.adoc')

        expect(post.title).to eq('Greetings')
      end
    end
  end

  describe '#url' do
    it 'is /<slug>.html' do
      in_tmp_dir do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hello-world.adoc', "= Hi\n")

        post = described_class.read('_posts/2026-01-15-hello-world.adoc')

        expect(post.url).to eq('/hello-world.html')
      end
    end
  end

  describe '.discover' do
    it 'returns all posts from _posts/' do
      in_tmp_dir do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-a.adoc', "= A\n")
        File.write('_posts/2026-02-15-b.adoc', "= B\n")

        slugs = described_class.discover.map(&:slug)

        expect(slugs).to contain_exactly('a', 'b')
      end
    end

    it 'returns an empty array when _posts/ is missing' do
      in_tmp_dir do
        expect(described_class.discover).to eq([])
      end
    end
  end

  describe '.read_draft' do
    it 'parses a draft filename and uses today as the date' do
      in_tmp_dir do
        FileUtils.mkdir_p('_drafts')
        File.write('_drafts/in-progress.adoc', "= WIP\n\nBody.\n")

        draft = described_class.read_draft('_drafts/in-progress.adoc')

        expect(draft.slug).to eq('in-progress')
        expect(draft.date).to eq(Date.today)
      end
    end
  end

  describe '#tags' do
    it 'returns front matter tags as an array (list form)' do
      in_tmp_dir do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hi.adoc', "---\ntags:\n  - ruby\n  - cli\n---\nBody.\n")

        expect(described_class.read('_posts/2026-01-15-hi.adoc').tags).to eq(%w[ruby cli])
      end
    end

    it 'returns empty array when not present' do
      in_tmp_dir do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hi.adoc', "= Hi\n")

        expect(described_class.read('_posts/2026-01-15-hi.adoc').tags).to eq([])
      end
    end

    it 'wraps a single-string tag value into a one-element array' do
      in_tmp_dir do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hi.adoc', "---\ntags: ruby\n---\nBody.\n")

        expect(described_class.read('_posts/2026-01-15-hi.adoc').tags).to eq(%w[ruby])
      end
    end
  end

  describe '#categories' do
    it 'returns front matter categories as an array' do
      in_tmp_dir do
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-hi.adoc', "---\ncategories:\n  - dev\n  - ruby\n---\nBody.\n")

        expect(described_class.read('_posts/2026-01-15-hi.adoc').categories).to eq(%w[dev ruby])
      end
    end
  end

  describe '.discover_drafts' do
    it 'returns drafts from _drafts/' do
      in_tmp_dir do
        FileUtils.mkdir_p('_drafts')
        File.write('_drafts/a.adoc', "= A\n")
        File.write('_drafts/b.adoc', "= B\n")

        slugs = described_class.discover_drafts.map(&:slug)

        expect(slugs).to contain_exactly('a', 'b')
      end
    end

    it 'returns an empty array when _drafts/ is missing' do
      in_tmp_dir do
        expect(described_class.discover_drafts).to eq([])
      end
    end
  end
end
