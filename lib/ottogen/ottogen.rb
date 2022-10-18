require 'asciidoctor'
require 'fileutils'
require 'listen'

module Ottogen
  class Ottogen
    BUILD_DIR = '_build'.freeze
    WELCOME = <<~ADOC
= Welcome to Otto!

Otto is a static site generator that uses AsciiDoc as a markup language.
ADOC

    def self.init
      puts "✨ ..."
      File.write("index.adoc", WELCOME)
      puts "✅"
    end

    def self.build
      puts "🔨 ..."
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
      puts "🧽 ..."
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
  end
end
