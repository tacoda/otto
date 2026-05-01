# frozen_string_literal: true

require 'yaml'

module Ottogen
  class Page
    class Error < StandardError; end

    FRONT_MATTER_OPENERS = ["---\n", "---\r\n"].freeze

    def self.read(path)
      raw = File.read(path)
      front_matter, body = split(raw, path)
      new(front_matter: front_matter, body: body)
    end

    def self.split(raw, path)
      return [{}, raw] unless FRONT_MATTER_OPENERS.any? { |opener| raw.start_with?(opener) }

      lines = raw.lines
      closing = lines[1..].index { |line| line.chomp == '---' }
      raise Error, "unclosed front matter in #{path}" if closing.nil?

      yaml_text = lines[1..closing].join
      body = (lines[(closing + 2)..] || []).join
      [parse_yaml(yaml_text, path), body]
    end

    def self.parse_yaml(text, path)
      YAML.safe_load(text) || {}
    rescue Psych::SyntaxError => e
      raise Error, "malformed YAML front matter in #{path}: #{e.message}"
    end
    private_class_method :split, :parse_yaml

    attr_reader :front_matter, :body

    def initialize(front_matter:, body:)
      @front_matter = front_matter
      @body = body
    end

    def asciidoctor_attributes
      @front_matter.transform_keys { |key| "page_#{key}" }
    end
  end
end
