# frozen_string_literal: true

require_relative 'front_matter'

module Ottogen
  class CollectionItem
    class Error < StandardError; end

    def self.read(path, collection_name)
      raw = File.read(path)
      front_matter, body = FrontMatter.split(raw, path)
      new(path: path, collection_name: collection_name, front_matter: front_matter, body: body)
    rescue FrontMatter::Error => e
      raise Error, e.message
    end

    attr_reader :path, :collection_name, :front_matter, :body
    attr_accessor :permalink

    def initialize(path:, collection_name:, front_matter:, body:)
      @path = path
      @collection_name = collection_name
      @front_matter = front_matter
      @body = body
    end

    def slug
      File.basename(@path, '.adoc')
    end

    def url
      return @permalink.url if @permalink

      "/#{@collection_name}/#{slug}.html"
    end

    def output_path(build_dir)
      return @permalink.output_path(build_dir) if @permalink

      File.join(build_dir, @collection_name, "#{slug}.html")
    end

    def asciidoctor_attributes
      attrs = @front_matter.transform_keys { |key| "page_#{key}" }
      attrs['page_url'] = url
      attrs['page_slug'] = slug
      attrs
    end

    def respond_to_missing?(name, include_private = false)
      @front_matter.key?(name.to_s) || super
    end

    def method_missing(name, *args)
      key = name.to_s
      return @front_matter[key] if @front_matter.key?(key)

      super
    end
  end
end
