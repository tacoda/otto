# frozen_string_literal: true

RSpec.describe Ottogen::Layout do
  describe '.find' do
    it 'loads a layout from _layouts/<name>.html.erb' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')
        File.write('_layouts/default.html.erb', '<html><%= content %></html>')

        layout = described_class.find('default')

        expect(layout.name).to eq('default')
      end
    end

    it 'raises Layout::Error when the layout file is missing' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')

        expect { described_class.find('missing') }.to raise_error(Ottogen::Layout::Error)
      end
    end

    it 'parses YAML front matter on layout files' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')
        File.write('_layouts/post.html.erb', "---\nlayout: default\n---\n<article><%= content %></article>")

        layout = described_class.find('post')

        expect(layout.front_matter).to eq('layout' => 'default')
      end
    end
  end

  describe '#render' do
    let(:site) { Ottogen::Config.new('title' => 'My Site') }
    let(:page) { Ottogen::Page.new(front_matter: { 'title' => 'My Page' }, body: '') }

    it 'substitutes <%= content %> with the given content' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')
        File.write('_layouts/default.html.erb', '<html><body><%= content %></body></html>')

        layout = described_class.find('default')
        result = layout.render(content: '<p>Hi</p>', site: site, page: page)

        expect(result).to eq('<html><body><p>Hi</p></body></html>')
      end
    end

    it 'exposes site.<key> from the config' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')
        File.write('_layouts/default.html.erb', '<title><%= site.title %></title>')

        result = described_class.find('default').render(content: '', site: site, page: page)

        expect(result).to eq('<title>My Site</title>')
      end
    end

    it 'exposes page.<key> from page front matter' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')
        File.write('_layouts/default.html.erb', '<h1><%= page.title %></h1>')

        result = described_class.find('default').render(content: '', site: site, page: page)

        expect(result).to eq('<h1>My Page</h1>')
      end
    end

    it 'chains parent layouts via front matter layout: key' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')
        File.write('_layouts/default.html.erb', '<html><body><%= content %></body></html>')
        File.write('_layouts/post.html.erb', "---\nlayout: default\n---\n<article><%= content %></article>")

        result = described_class.find('post').render(content: '<p>Hi</p>', site: site, page: page)

        expect(result).to eq('<html><body><article><p>Hi</p></article></body></html>')
      end
    end

    it 'embeds an _includes/<name> partial via partial(...)' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')
        FileUtils.mkdir_p('_includes')
        File.write('_includes/header.html', '<header>Top</header>')
        File.write('_layouts/default.html.erb', "<%= partial 'header.html' %><%= content %>")

        result = described_class.find('default').render(content: '<p>Hi</p>', site: site, page: page)

        expect(result).to eq('<header>Top</header><p>Hi</p>')
      end
    end

    it 'allows partials to reference site.<key>' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')
        FileUtils.mkdir_p('_includes')
        File.write('_includes/header.html', '<title><%= site.title %></title>')
        File.write('_layouts/default.html.erb', "<%= partial 'header.html' %>")

        result = described_class.find('default').render(content: '', site: site, page: page)

        expect(result).to eq('<title>My Site</title>')
      end
    end

    it 'allows partials to reference page.<key>' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')
        FileUtils.mkdir_p('_includes')
        File.write('_includes/header.html', '<h1><%= page.title %></h1>')
        File.write('_layouts/default.html.erb', "<%= partial 'header.html' %>")

        result = described_class.find('default').render(content: '', site: site, page: page)

        expect(result).to eq('<h1>My Page</h1>')
      end
    end

    it 'allows partials to include other partials' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')
        FileUtils.mkdir_p('_includes')
        File.write('_includes/inner.html', '<span>inner</span>')
        File.write('_includes/outer.html', "<div><%= partial 'inner.html' %></div>")
        File.write('_layouts/default.html.erb', "<%= partial 'outer.html' %>")

        result = described_class.find('default').render(content: '', site: site, page: page)

        expect(result).to eq('<div><span>inner</span></div>')
      end
    end

    it 'raises Layout::Error when an include is missing' do
      in_tmp_dir do
        FileUtils.mkdir_p('_layouts')
        File.write('_layouts/default.html.erb', "<%= partial 'missing.html' %>")

        expect do
          described_class.find('default').render(content: '', site: site, page: page)
        end.to raise_error(Ottogen::Layout::Error)
      end
    end
  end
end
