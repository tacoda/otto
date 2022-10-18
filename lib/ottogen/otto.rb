require 'thor'
require 'webrick'
require_relative './ottogen'

module Ottogen
  class Otto < Thor
    desc "init", "Initialize static site"
    def init
      Ottogen.init
    end

    desc "build", "Build the static site"
    def build
      Ottogen.build
    end

    desc "clean", "Clean the static site"
    def clean
      Ottogen.clean
    end

    desc "serve", "Serve the static site"
    def serve
      root = File.expand_path Dir.pwd
      server = WEBrick::HTTPServer.new :Port => 8778, :DocumentRoot => root
      trap 'INT' do server.shutdown end
      server.start
    end
  end
end
