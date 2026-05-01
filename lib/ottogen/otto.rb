# frozen_string_literal: true

require 'thor'
require_relative 'ottogen'

module Ottogen
  class Otto < Thor
    desc 'init [DIR]', 'Initialize a new otto static site in DIR (defaults to the current directory)'
    def init(dir = nil)
      Ottogen.init(dir)
    end

    desc 'build', 'Build the static site'
    option :drafts, type: :boolean, default: false, desc: 'Include drafts from _drafts/'
    def build
      Ottogen.build(drafts: options[:drafts])
    end

    map 'b' => :build

    desc 'generate PAGE', 'Generate a new page'
    def generate(page)
      Ottogen.generate(page)
    end

    map 'g' => :generate

    desc 'clean', 'Clean the static site'
    def clean
      Ottogen.clean
    end

    desc 'watch', 'Watch changes to static site'
    option :drafts, type: :boolean, default: false, desc: 'Include drafts from _drafts/'
    def watch
      Ottogen.watch(drafts: options[:drafts])
    end

    desc 'serve', 'Serve the static site'
    def serve
      Ottogen.serve
    end

    map 's' => :serve

    desc 'post TITLE', "Generate a new post in _posts/ with today's date"
    def post(title)
      Ottogen.new_post(title)
    end

    desc 'doctor', 'Check the project for common configuration problems'
    def doctor
      Ottogen.doctor
    end
  end
end
