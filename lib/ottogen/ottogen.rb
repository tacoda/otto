# frozen_string_literal: true

require 'asciidoctor'
require 'date'
require 'fileutils'
require 'listen'
require 'webrick'

require_relative 'collection_item'
require_relative 'config'
require_relative 'layout'
require_relative 'page'
require_relative 'permalink'
require_relative 'post'
require_relative 'scaffold'

module Ottogen
  class Ottogen
    BUILD_DIR = '_build'

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

    def self.build(drafts: false)
      puts '🔨 Building static site...'
      error_if_not_otto_project
      config = load_config(drafts: drafts)
      FileUtils.mkdir_p(BUILD_DIR)
      FileUtils.cp_r 'assets/', "#{BUILD_DIR}/assets"
      documents_for(config).each { |doc| convert_document(doc, config) }
      puts '✅'
    end

    def self.documents_for(config)
      collection_items = config.collections.values.flat_map { |c| c.output? ? c.items : [] }
      load_pages + config.posts + collection_items
    end

    def self.load_pages
      Dir.glob('pages/**/*.adoc').map { |path| Page.read(path) }
    rescue Page::Error => e
      puts "❌ Error: #{e.message}"
      exit(1)
    end

    def self.convert_document(doc, config)
      apply_permalink(doc, config)
      html = render_document(doc, config)
      write_output(doc.output_path(BUILD_DIR), html)
    rescue Layout::Error => e
      puts "❌ Error in #{doc.path}: #{e.message}"
      exit(1)
    end

    def self.apply_permalink(doc, config)
      template = doc.front_matter['permalink']
      template ||= config['permalink'] if doc.is_a?(Post)
      return if template.nil?

      doc.permalink = Permalink.expand(template, doc)
    end

    def self.render_document(doc, config)
      layout_name = doc.front_matter['layout']
      attributes = config.asciidoctor_attributes.merge(doc.asciidoctor_attributes)
      body = Asciidoctor.convert(doc.body,
                                 safe: :safe,
                                 standalone: layout_name.nil?,
                                 attributes: attributes)
      return body unless layout_name

      Layout.find(layout_name).render(content: body, site: config, page: doc)
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

    def self.new_post(title)
      error_if_not_otto_project
      FileUtils.mkdir_p('_posts')
      slug = Permalink.slugify(title)
      date = Date.today
      path = "_posts/#{date.iso8601}-#{slug}.adoc"
      File.write(path, "---\ntitle: #{title}\ndate: #{date.iso8601}\n---\n\n")
      puts "📝 Created #{path}"
    end

    def self.doctor
      problems = collect_problems
      if problems.empty?
        puts '✅ All checks passed'
      else
        puts '❌ Problems:'
        problems.each { |p| puts "  - #{p}" }
        exit(1)
      end
    end

    def self.collect_problems
      problems = []
      problems << '.otto marker missing (run `otto init` first)' unless File.exist?('.otto')
      problems << 'config.yml missing' unless File.exist?('config.yml')
      problems << 'pages/ directory missing' unless Dir.exist?('pages')
      problems
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

    def self.watch(drafts: false)
      puts '👀 Watching files...'
      error_if_not_otto_project
      listener = Listen.to(Dir.pwd, ignore: [/_build/]) do |modified, added, removed|
        puts(modified: modified, added: added, removed: removed)
        build(drafts: drafts)
      end
      listener.start
      sleep
    end

    def self.init_with_dir(dir)
      Dir.mkdir(dir)
      Scaffold.write(dir)
    end

    def self.init_in_current_dir
      Scaffold.write('.')
    end

    def self.error_if_not_otto_project
      return if File.exist?('.otto')

      puts '❌ Error: Current directory is not an otto project'
      exit(1)
    end

    def self.load_config(drafts: false)
      Config.load(drafts: drafts)
    rescue Config::Error => e
      puts "❌ Error: #{e.message}"
      exit(1)
    end
  end
end
