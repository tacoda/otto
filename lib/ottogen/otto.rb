require 'thor'
require_relative './ottogen'

module Ottogen
  class Otto < Thor
    desc "init [DIR]", "Initialize a new otto static site in DIR (defaults to the current directory)"
    def init(dir=nil)
      Ottogen.init(dir)
    end

    desc "build", "Build the static site"
    def build
      Ottogen.build
    end

    map "b" => :build

    desc "generate PAGE", "Generate a new page"
    def generate(page)
      Ottogen.generate(page)
    end

    map "g" => :generate

    desc "clean", "Clean the static site"
    def clean
      Ottogen.clean
    end

    desc "watch", "Watch changes to static site"
    def watch
      Ottogen.watch
    end

    desc "serve", "Serve the static site"
    def serve
      Ottogen.serve
    end

    map "s" => :serve
  end
end
