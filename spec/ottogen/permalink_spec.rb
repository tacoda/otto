# frozen_string_literal: true

require 'date'

RSpec.describe Ottogen::Permalink do
  let(:post) do
    Ottogen::Post.new(
      path: '_posts/2026-01-15-hello-world.adoc',
      date: Date.new(2026, 1, 15),
      slug: 'hello-world',
      front_matter: { 'title' => 'Hello World!' },
      body: ''
    )
  end

  describe '.expand' do
    it 'replaces :year, :month, :day from the date' do
      expanded = described_class.expand('/:year/:month/:day/', post)

      expect(expanded.path).to eq('/2026/01/15/')
    end

    it 'replaces :slug' do
      expanded = described_class.expand('/:slug.html', post)

      expect(expanded.path).to eq('/hello-world.html')
    end

    it 'replaces :title with a slugified version' do
      expanded = described_class.expand('/:title/', post)

      expect(expanded.path).to eq('/hello-world/')
    end
  end

  describe '#output_path' do
    it 'appends index.html when the path ends with /' do
      permalink = described_class.new('/2026/01/15/hello/')

      expect(permalink.output_path('_build')).to eq('_build/2026/01/15/hello/index.html')
    end

    it 'uses the path as-is otherwise' do
      permalink = described_class.new('/2026/01/15/hello.html')

      expect(permalink.output_path('_build')).to eq('_build/2026/01/15/hello.html')
    end
  end
end
