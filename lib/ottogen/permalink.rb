# frozen_string_literal: true

module Ottogen
  class Permalink
    TOKEN_PATTERN = /:(year|month|day|slug|title)/

    TOKEN_RESOLVERS = {
      ':year' => ->(doc) { doc.respond_to?(:date) && doc.date ? doc.date.strftime('%Y') : '' },
      ':month' => ->(doc) { doc.respond_to?(:date) && doc.date ? doc.date.strftime('%m') : '' },
      ':day' => ->(doc) { doc.respond_to?(:date) && doc.date ? doc.date.strftime('%d') : '' },
      ':slug' => ->(doc) { doc.respond_to?(:slug) ? doc.slug.to_s : '' },
      ':title' => ->(doc) { doc.respond_to?(:title) ? slugify(doc.title) : '' }
    }.freeze

    def self.expand(template, doc)
      expanded = template.gsub(TOKEN_PATTERN) { |token| TOKEN_RESOLVERS.fetch(token).call(doc) }
      new(expanded)
    end

    def self.slugify(str)
      str.to_s.downcase.gsub(/[^a-z0-9]+/, '-').sub(/\A-/, '').sub(/-\z/, '')
    end

    attr_reader :path
    alias url path

    def initialize(path)
      @path = path
    end

    def output_path(build_dir)
      File.join(build_dir, @path.end_with?('/') ? "#{@path}index.html" : @path)
    end
  end
end
