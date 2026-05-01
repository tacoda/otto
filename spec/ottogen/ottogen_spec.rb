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
  end

  describe '.init' do
    it 'writes a config.yml with title, description, url, and baseurl keys' do
      in_tmp_dir do
        capture_stdout { described_class.init('site') }

        config = YAML.safe_load_file('site/config.yml')
        expect(config.keys).to include('title', 'description', 'url', 'baseurl')
      end
    end
  end
end
