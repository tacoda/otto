# frozen_string_literal: true

require_relative 'front_matter'

module Ottogen
  class Page
    class Error < StandardError; end

    def self.read(path)
      raw = File.read(path)
      front_matter, body = FrontMatter.split(raw, path)
      new(front_matter: front_matter, body: body)
    rescue FrontMatter::Error => e
      raise Error, e.message
    end

    attr_reader :front_matter, :body

    def initialize(front_matter:, body:)
      @front_matter = front_matter
      @body = body
    end

    def asciidoctor_attributes
      @front_matter.transform_keys { |key| "page_#{key}" }
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
