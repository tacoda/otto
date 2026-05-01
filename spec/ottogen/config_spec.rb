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
end
