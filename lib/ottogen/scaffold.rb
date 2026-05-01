# frozen_string_literal: true

require 'fileutils'

module Ottogen
  module Scaffold
    CONFIG = <<~YAML
      title: "Otto site"
      description: ""
      url: ""
      baseurl: ""
    YAML

    WELCOME = <<~ADOC
      ---
      layout: default
      title: Welcome
      ---
      = Welcome to Otto!

      Otto is a static site generator that uses AsciiDoc as a markup language.
    ADOC

    DEFAULT_LAYOUT = <<~ERB
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <title><%= page.respond_to?(:title) ? page.title : site.title %></title>
        </head>
        <body>
          <%= content %>
        </body>
      </html>
    ERB

    DIRS = %w[assets pages _layouts _includes _data _posts].freeze
    FILES = {
      'config.yml' => CONFIG,
      'pages/index.adoc' => WELCOME,
      '_layouts/default.html.erb' => DEFAULT_LAYOUT
    }.freeze

    def self.write(root)
      FileUtils.touch(File.join(root, '.otto'))
      DIRS.each { |dir| FileUtils.mkdir_p(File.join(root, dir)) }
      FILES.each { |path, content| File.write(File.join(root, path), content) }
    end
  end
end
