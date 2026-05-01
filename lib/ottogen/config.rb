# frozen_string_literal: true

require 'yaml'

module Ottogen
  class Config
    class Error < StandardError; end

    DEFAULT_PATH = 'config.yml'

    def self.load(path = DEFAULT_PATH)
      raise Error, "config.yml not found at #{path}" unless File.exist?(path)

      data = YAML.safe_load_file(path) || {}
      new(data)
    rescue Psych::SyntaxError => e
      raise Error, "malformed YAML in #{path}: #{e.message}"
    end

    def initialize(data)
      @data = data
    end

    def [](key)
      @data[key.to_s]
    end

    def asciidoctor_attributes
      @data.transform_keys { |key| "site_#{key}" }
    end
  end
end
