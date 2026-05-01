# frozen_string_literal: true

RSpec.describe Ottogen::Config do
  describe '.load' do
    it 'reads top-level keys from config.yml' do
      in_tmp_dir do
        File.write('config.yml', <<~YAML)
          title: My Site
          description: An Otto site
          url: https://example.com
          baseurl: /blog
        YAML

        config = described_class.load

        expect(config['title']).to eq('My Site')
        expect(config['description']).to eq('An Otto site')
        expect(config['url']).to eq('https://example.com')
        expect(config['baseurl']).to eq('/blog')
      end
    end

    it 'exposes arbitrary custom keys' do
      in_tmp_dir do
        File.write('config.yml', <<~YAML)
          author: Ada Lovelace
          twitter: ada
        YAML

        config = described_class.load

        expect(config['author']).to eq('Ada Lovelace')
        expect(config['twitter']).to eq('ada')
      end
    end

    it 'raises Ottogen::Config::Error when config.yml is missing' do
      in_tmp_dir do
        expect { described_class.load }.to raise_error(Ottogen::Config::Error)
      end
    end

    it 'raises Ottogen::Config::Error when config.yml is malformed YAML' do
      in_tmp_dir do
        File.write('config.yml', "title: 'unclosed\n")

        expect { described_class.load }.to raise_error(Ottogen::Config::Error)
      end
    end

    it 'treats an empty config.yml as an empty config' do
      in_tmp_dir do
        File.write('config.yml', '')

        config = described_class.load

        expect(config['title']).to be_nil
        expect(config.asciidoctor_attributes).to eq({})
      end
    end
  end

  describe '#asciidoctor_attributes' do
    it 'prefixes every key with site_' do
      in_tmp_dir do
        File.write('config.yml', <<~YAML)
          title: Otto
          author: Ada
        YAML

        attrs = described_class.load.asciidoctor_attributes

        expect(attrs).to eq('site_title' => 'Otto', 'site_author' => 'Ada')
      end
    end
  end

  describe '#data' do
    it 'reads .yml files from _data/ as data.<name>' do
      in_tmp_dir do
        File.write('config.yml', "title: T\n")
        FileUtils.mkdir_p('_data')
        File.write('_data/nav.yml', "- title: Home\n  url: /\n- title: About\n  url: /about\n")

        config = described_class.load

        expect(config.data.nav).to eq([{ 'title' => 'Home', 'url' => '/' },
                                       { 'title' => 'About', 'url' => '/about' }])
      end
    end

    it 'reads .json files from _data/ as data.<name>' do
      in_tmp_dir do
        File.write('config.yml', "title: T\n")
        FileUtils.mkdir_p('_data')
        File.write('_data/items.json', '[{"name":"one"},{"name":"two"}]')

        config = described_class.load

        expect(config.data.items).to eq([{ 'name' => 'one' }, { 'name' => 'two' }])
      end
    end

    it 'supports both .yml and .yaml extensions' do
      in_tmp_dir do
        File.write('config.yml', "title: T\n")
        FileUtils.mkdir_p('_data')
        File.write('_data/short.yml', "key: yml\n")
        File.write('_data/long.yaml', "key: yaml\n")

        config = described_class.load

        expect(config.data.short).to eq('key' => 'yml')
        expect(config.data.long).to eq('key' => 'yaml')
      end
    end

    it 'returns empty data when _data/ is missing or empty' do
      in_tmp_dir do
        File.write('config.yml', "title: T\n")

        config = described_class.load

        expect(config.data['nav']).to be_nil
      end
    end

    it 'raises Config::Error for a malformed data file (with file path in message)' do
      in_tmp_dir do
        File.write('config.yml', "title: T\n")
        FileUtils.mkdir_p('_data')
        File.write('_data/bad.yml', "title: 'unclosed\n")

        expect { described_class.load }
          .to raise_error(Ottogen::Config::Error, %r{_data/bad\.yml})
      end
    end

    it 'exposes entries via both [] and method_missing' do
      in_tmp_dir do
        File.write('config.yml', "title: T\n")
        FileUtils.mkdir_p('_data')
        File.write('_data/nav.yml', "- title: Home\n")

        data = described_class.load.data

        expect(data['nav']).to eq([{ 'title' => 'Home' }])
        expect(data.nav).to eq([{ 'title' => 'Home' }])
      end
    end
  end

  describe '#posts' do
    it 'exposes site.posts sorted by date descending' do
      in_tmp_dir do
        File.write('config.yml', "title: T\n")
        FileUtils.mkdir_p('_posts')
        File.write('_posts/2026-01-15-old.adoc', "= Old\n")
        File.write('_posts/2026-02-15-new.adoc', "= New\n")
        File.write('_posts/2026-01-30-mid.adoc', "= Mid\n")

        slugs = described_class.load.posts.map(&:slug)

        expect(slugs).to eq(%w[new mid old])
      end
    end

    it 'excludes drafts by default' do
      in_tmp_dir do
        File.write('config.yml', "title: T\n")
        FileUtils.mkdir_p('_posts')
        FileUtils.mkdir_p('_drafts')
        File.write('_posts/2026-01-15-real.adoc', "= R\n")
        File.write('_drafts/wip.adoc', "= D\n")

        slugs = described_class.load.posts.map(&:slug)

        expect(slugs).to eq(%w[real])
      end
    end

    it 'includes drafts when loaded with drafts: true' do
      in_tmp_dir do
        File.write('config.yml', "title: T\n")
        FileUtils.mkdir_p('_posts')
        FileUtils.mkdir_p('_drafts')
        File.write('_posts/2020-01-01-real.adoc', "= R\n")
        File.write('_drafts/wip.adoc', "= D\n")

        slugs = described_class.load(drafts: true).posts.map(&:slug)

        expect(slugs).to contain_exactly('real', 'wip')
      end
    end
  end

  describe '#collections' do
    it 'exposes site.<collection_name> as the items array' do
      in_tmp_dir do
        File.write('config.yml', <<~YAML)
          title: T
          collections:
            recipes:
              output: true
        YAML
        FileUtils.mkdir_p('_recipes')
        File.write('_recipes/pizza.adoc', "= Pizza\n")
        File.write('_recipes/bread.adoc', "= Bread\n")

        config = described_class.load

        expect(config.recipes.map(&:slug)).to contain_exactly('pizza', 'bread')
      end
    end
  end
end
