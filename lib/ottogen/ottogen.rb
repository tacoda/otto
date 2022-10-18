require 'asciidoctor'

module Ottogen
  class Ottogen
    WELCOME = <<~ADOC
= Welcome to Otto!

Otto is a static site generator that uses AsciiDoc as a markup language.
ADOC

    def self.init
      File.write("index.adoc", WELCOME)
    end

    def self.build
      puts Dir.glob('*')
      # Asciidoctor.convert_file 'document.adoc', safe: :safe
    end

    def self.clean
      puts Dir.pwd
    end
  end
end
