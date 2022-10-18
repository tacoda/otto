require 'asciidoctor'

module Ottogen
  class Ottogen
    def self.hello(name)
      puts "Hello #{name}"
      # Asciidoctor.convert_file 'document.adoc', safe: :safe
    end
  end
end
