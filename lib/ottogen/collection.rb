# frozen_string_literal: true

require_relative 'collection_item'

module Ottogen
  class Collection
    DIR_PREFIX = '_'

    def self.from_config(name, settings)
      output = settings.is_a?(Hash) && settings['output'] == true
      new(name: name, output: output)
    end

    attr_reader :name, :items

    def initialize(name:, output:)
      @name = name
      @output = output
      @items = discover_items
    end

    def output?
      @output
    end

    private

    def discover_items
      dir = "#{DIR_PREFIX}#{@name}"
      return [] unless Dir.exist?(dir)

      Dir.glob(File.join(dir, '*.adoc')).map { |path| CollectionItem.read(path, @name) }
    end
  end
end
