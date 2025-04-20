require 'asciidoctor'
require 'fileutils'
require 'listen'

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

    def self.watch
      puts "👀 Watching files..."
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
      File.write("#{dir}/config.yml", CONFIG)
      File.write("#{dir}/index.adoc", WELCOME)
    end

    def self.init_in_current_dir
      File.write("config.yml", CONFIG)
      File.write("index.adoc", WELCOME)
    end
  end
end
