# frozen_string_literal: true

require 'asciidoctor'
require 'fileutils'
require 'listen'
require 'webrick'

module Ottogen
  class Ottogen
    BUILD_DIR = '_build'
    CONFIG = <<~YAML
      title: "Otto site"
    YAML
    WELCOME = <<~ADOC
      = Welcome to Otto!

      Otto is a static site generator that uses AsciiDoc as a markup language.
    ADOC

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
      FileUtils.mkdir_p(BUILD_DIR)
      FileUtils.cp_r 'assets/', "#{BUILD_DIR}/assets"
      docs = Dir.glob('pages/**/*.adoc').map { |name| name.split('.').first }
      docs.each do |doc|
        page = doc.sub(%r{^pages/}, '')
        Asciidoctor.convert_file "#{doc}.adoc",
                                 safe: :safe,
                                 mkdirs: true,
                                 to_file: "#{BUILD_DIR}/#{page}.html"
      end
      puts '✅'
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
      FileUtils.touch("#{dir}/.otto")
      File.write("#{dir}/config.yml", CONFIG)
      FileUtils.mkdir_p("#{dir}/assets")
      FileUtils.mkdir_p("#{dir}/pages")
      File.write("#{dir}/pages/index.adoc", WELCOME)
    end

    def self.init_in_current_dir
      FileUtils.touch('.otto')
      File.write('config.yml', CONFIG)
      FileUtils.mkdir_p('assets')
      FileUtils.mkdir_p('pages')
      File.write('pages/index.adoc', WELCOME)
    end

    def self.error_if_not_otto_project
      return if File.exist?('.otto')

      puts '❌ Error: Current directory is not an otto project'
      exit(1)
    end
  end
end
