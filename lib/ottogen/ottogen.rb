# frozen_string_literal: true

require 'asciidoctor'
require 'fileutils'
require 'listen'
require 'webrick'

require_relative 'config'
require_relative 'layout'
require_relative 'page'

module Ottogen
  class Ottogen
    BUILD_DIR = '_build'
    CONFIG = <<~YAML
      title: "Otto site"
      description: ""
      url: ""
      baseurl: ""
    YAML
    WELCOME = <<~ADOC
      ---
      layout: default
      title: Welcome
      ---
      = Welcome to Otto!

      Otto is a static site generator that uses AsciiDoc as a markup language.
    ADOC

    DEFAULT_LAYOUT = <<~ERB
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <title><%= page.respond_to?(:title) ? page.title : site.title %></title>
        </head>
        <body>
          <%= content %>
        </body>
      </html>
    ERB

    def self.init(dir)
      puts '✨ Initializing static site...'
      if !dir.nil? && Dir.exist?(dir)
        puts '❌ Error: Directory already exists'
        exit(1)
      end

      if dir.nil?
        files_in_current_dir = Dir.glob('**/*')
        unless files_in_current_dir.empty?
          puts '❌ Error: Directory must be empty'
          exit(1)
        end
        init_in_current_dir
      else
        init_with_dir(dir)
      end

      puts '✅'
    end

    def self.build
      puts '🔨 Building static site...'
      error_if_not_otto_project
      config = load_config
      FileUtils.mkdir_p(BUILD_DIR)
      FileUtils.cp_r 'assets/', "#{BUILD_DIR}/assets"
      Dir.glob('pages/**/*.adoc').each { |path| convert_page(path, config) }
      puts '✅'
    end

    def self.convert_page(path, config)
      page = Page.read(path)
      html = render_page(page, config)
      write_output(output_path_for(path), html)
    rescue Page::Error, Layout::Error => e
      puts "❌ Error in #{path}: #{e.message}"
      exit(1)
    end

    def self.render_page(page, config)
      layout_name = page.front_matter['layout']
      attributes = config.asciidoctor_attributes.merge(page.asciidoctor_attributes)
      body = Asciidoctor.convert(page.body,
                                 safe: :safe,
                                 standalone: layout_name.nil?,
                                 attributes: attributes)
      return body unless layout_name

      Layout.find(layout_name).render(content: body, site: config, page: page)
    end

    def self.output_path_for(source_path)
      "#{BUILD_DIR}/#{source_path.sub(%r{^pages/}, '').sub(/\.adoc\z/, '.html')}"
    end

    def self.write_output(path, html)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, html)
    end

    def self.generate(page)
      puts '📝 Generating a new page...'
      error_if_not_otto_project
      page_title = page.split('-').map(&:capitalize).join(' ')
      File.write("pages/#{page}.adoc", "= #{page_title}\n")
    end

    def self.clean
      puts '🧽 Cleaning build directory...'
      error_if_not_otto_project
      return unless Dir.exist?(BUILD_DIR)

      FileUtils.rmtree(BUILD_DIR)
      puts '✅'
    end

    def self.serve
      puts '🤖 Starting server...'
      error_if_not_otto_project
      root = File.expand_path("#{Dir.pwd}/#{Ottogen::BUILD_DIR}")
      server = WEBrick::HTTPServer.new Port: 8778, DocumentRoot: root
      trap 'INT' do
        server.shutdown
      end
      server.start
    rescue Errno::EADDRINUSE
      puts '❌ Server port already in use'
      exit(1)
    end

    def self.watch
      puts '👀 Watching files...'
      error_if_not_otto_project
      listener = Listen.to(Dir.pwd, ignore: [/_build/]) do |modified, added, removed|
        puts(modified: modified, added: added, removed: removed)
        build
      end
      listener.start
      sleep
    end

    def self.init_with_dir(dir)
      Dir.mkdir(dir)
      scaffold(dir)
    end

    def self.init_in_current_dir
      scaffold('.')
    end

    def self.scaffold(root)
      FileUtils.touch(File.join(root, '.otto'))
      File.write(File.join(root, 'config.yml'), CONFIG)
      FileUtils.mkdir_p(File.join(root, 'assets'))
      FileUtils.mkdir_p(File.join(root, 'pages'))
      FileUtils.mkdir_p(File.join(root, '_layouts'))
      FileUtils.mkdir_p(File.join(root, '_includes'))
      File.write(File.join(root, 'pages', 'index.adoc'), WELCOME)
      File.write(File.join(root, '_layouts', 'default.html.erb'), DEFAULT_LAYOUT)
    end

    def self.error_if_not_otto_project
      return if File.exist?('.otto')

      puts '❌ Error: Current directory is not an otto project'
      exit(1)
    end

    def self.load_config
      Config.load
    rescue Config::Error => e
      puts "❌ Error: #{e.message}"
      exit(1)
    end
  end
end
