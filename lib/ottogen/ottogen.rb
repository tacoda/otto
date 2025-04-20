require 'asciidoctor'
require 'fileutils'
require 'listen'
require 'webrick'

module Ottogen
  class Ottogen
    BUILD_DIR = '_build'.freeze
    CONFIG = <<~YAML
title: "Otto site"
YAML
    WELCOME = <<~ADOC
= Welcome to Otto!

Otto is a static site generator that uses AsciiDoc as a markup language.
ADOC

    def self.init(dir)
      puts "✨ Initializing..."
      if !dir.nil? and Dir.exist?(dir)
        puts "❌ Error: Directory already exists"
        exit(1)
      end

      if dir.nil?
        init_in_current_dir
      else
        init_with_dir(dir)
      end

      puts "✅"
    end

    def self.build
      puts "🔨 Building..."
      if !File.exist?(".otto")
        puts "❌ Error: Current directory is not an otto project"
        exit(1)
      end
      Dir.mkdir(BUILD_DIR) unless Dir.exist?(BUILD_DIR)
      Dir.glob('**/*.adoc').map do |name|
        name.split('.').first
      end.each do |doc|
        Asciidoctor.convert_file "#{doc}.adoc",
                                 safe: :safe,
                                 mkdirs: true,
                                 to_file: "#{BUILD_DIR}/#{doc}.html"
      end
      puts "✅"
    end

    def self.clean
      puts "🧽 Cleaning..."
      return unless Dir.exist?(BUILD_DIR)
      FileUtils.rmtree(BUILD_DIR)
      puts "✅"
    end

    def self.serve
      puts "🤖 Starting server..."
      if !File.exist?(".otto")
        puts "❌ Error: Current directory is not an otto project"
        exit(1)
      end
      root = File.expand_path("#{Dir.pwd}/#{Ottogen::BUILD_DIR}")
      server = WEBrick::HTTPServer.new :Port => 8778, :DocumentRoot => root
      trap 'INT' do server.shutdown end
      server.start
    end

    def self.watch
      puts "👀 Watching files..."
      if !File.exist?(".otto")
        puts "❌ Error: Current directory is not an otto project"
        exit(1)
      end
      listener = Listen.to(Dir.pwd, ignore: [/_build/]) do |modified, added, removed|
        puts(modified: modified, added: added, removed: removed)
        build
      end
      listener.start
      sleep
    end

    private

    def self.init_with_dir(dir)
      Dir.mkdir(dir)
      FileUtils.touch("#{dir}/.otto")
      File.write("#{dir}/config.yml", CONFIG)
      File.write("#{dir}/index.adoc", WELCOME)
    end

    def self.init_in_current_dir
      FileUtils.touch(".otto")
      File.write("config.yml", CONFIG)
      File.write("index.adoc", WELCOME)
    end
  end
end
