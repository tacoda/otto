# frozen_string_literal: true

require 'erb'

require_relative 'front_matter'

module Ottogen
  class Layout
    class Error < StandardError; end

    LAYOUTS_DIR = '_layouts'
    EXTENSION = '.html.erb'

    def self.find(name)
      path = File.join(LAYOUTS_DIR, "#{name}#{EXTENSION}")
      raise Error, "layout '#{name}' not found at #{path}" unless File.exist?(path)

      raw = File.read(path)
      front_matter, body = FrontMatter.split(raw, path)
      new(name: name, front_matter: front_matter, body: body)
    rescue FrontMatter::Error => e
      raise Error, e.message
    end

    attr_reader :name, :front_matter, :body

    def initialize(name:, front_matter:, body:)
      @name = name
      @front_matter = front_matter
      @body = body
    end

    def render(content:, site:, page:)
      context = Context.new(content: content, site: site, page: page)
      result = ERB.new(@body, trim_mode: '-').result(context.binding_for_erb)
      parent_name = @front_matter['layout']
      return result unless parent_name

      Layout.find(parent_name).render(content: result, site: site, page: page)
    end

    class Context
      attr_reader :content, :site, :page

      def initialize(content:, site:, page:)
        @content = content
        @site = site
        @page = page
      end

      def binding_for_erb
        binding
      end
    end
  end
end
