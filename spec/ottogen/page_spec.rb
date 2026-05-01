# frozen_string_literal: true

RSpec.describe Ottogen::Page do
  describe '.read' do
    it 'parses YAML front matter delimited by ---' do
      in_tmp_dir do
        File.write('post.adoc', <<~ADOC)
          ---
          title: Hello
          author: Ada
          ---
          = Hello

          Body.
        ADOC

        page = described_class.read('post.adoc')

        expect(page.front_matter).to eq('title' => 'Hello', 'author' => 'Ada')
      end
    end

    it 'strips the front matter block from the body' do
      in_tmp_dir do
        File.write('post.adoc', <<~ADOC)
          ---
          title: Hello
          ---
          = Hello

          Body.
        ADOC

        page = described_class.read('post.adoc')

        expect(page.body).to eq("= Hello\n\nBody.\n")
      end
    end

    it 'returns empty front matter when the file has no --- block' do
      in_tmp_dir do
        File.write('post.adoc', "= Plain\n\nBody.\n")

        page = described_class.read('post.adoc')

        expect(page.front_matter).to eq({})
      end
    end

    it 'returns the full file as body when there is no front matter' do
      in_tmp_dir do
        File.write('post.adoc', "= Plain\n\nBody.\n")

        page = described_class.read('post.adoc')

        expect(page.body).to eq("= Plain\n\nBody.\n")
      end
    end

    it 'raises Page::Error for unclosed front matter' do
      in_tmp_dir do
        File.write('post.adoc', "---\ntitle: Hello\n\n= Body without close\n")

        expect { described_class.read('post.adoc') }
          .to raise_error(Ottogen::Page::Error)
      end
    end

    it 'raises Page::Error for malformed YAML in front matter' do
      in_tmp_dir do
        File.write('post.adoc', "---\ntitle: 'unclosed\n---\nBody\n")

        expect { described_class.read('post.adoc') }
          .to raise_error(Ottogen::Page::Error)
      end
    end
  end

  describe '#asciidoctor_attributes' do
    it 'prefixes every front matter key with page_' do
      in_tmp_dir do
        File.write('post.adoc', "---\ntitle: Hi\nauthor: Ada\n---\nBody.\n")

        attrs = described_class.read('post.adoc').asciidoctor_attributes

        expect(attrs).to eq('page_title' => 'Hi', 'page_author' => 'Ada')
      end
    end
  end
end
