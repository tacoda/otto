# frozen_string_literal: true

require 'yaml'

module Ottogen
  module FrontMatter
    class Error < StandardError; end

    OPENERS = ["---\n", "---\r\n"].freeze

    def self.split(raw, path)
      return [{}, raw] unless OPENERS.any? { |opener| raw.start_with?(opener) }

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
    private_class_method :parse_yaml
  end
end
