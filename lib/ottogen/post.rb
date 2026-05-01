# frozen_string_literal: true

require 'date'

require_relative 'front_matter'

module Ottogen
  class Post
    class Error < StandardError; end

    POSTS_DIR = '_posts'
    FILENAME_PATTERN = /\A(\d{4})-(\d{2})-(\d{2})-(.+)\.adoc\z/

    def self.read(path)
      date, slug = parse_filename(path)
      front_matter, body = FrontMatter.split(File.read(path), path)
      new(path: path, date: date, slug: slug, front_matter: front_matter, body: body)
    rescue FrontMatter::Error => e
      raise Error, e.message
    end

    def self.parse_filename(path)
      match = FILENAME_PATTERN.match(File.basename(path))
      raise Error, "post filename must match YYYY-MM-DD-slug.adoc: #{path}" unless match

      year, month, day, slug = match.captures
      [Date.new(year.to_i, month.to_i, day.to_i), slug]
    end
    private_class_method :parse_filename

    def self.discover(dir = POSTS_DIR)
      return [] unless Dir.exist?(dir)

      Dir.glob(File.join(dir, '*.adoc')).map { |path| read(path) }
    end

    attr_reader :path, :date, :slug, :front_matter, :body
    attr_accessor :permalink

    def initialize(path:, date:, slug:, front_matter:, body:)
      @path = path
      @date = date
      @slug = slug
      @front_matter = front_matter
      @body = body
    end

    def title
      @front_matter['title'] || slug.split('-').map(&:capitalize).join(' ')
    end

    def url
      return @permalink.url if @permalink

      "/#{slug}.html"
    end

    def output_path(build_dir)
      return @permalink.output_path(build_dir) if @permalink

      File.join(build_dir, "#{slug}.html")
    end

    def asciidoctor_attributes
      attrs = @front_matter.transform_keys { |key| "page_#{key}" }
      attrs['page_title'] ||= title
      attrs['page_date'] = date.iso8601
      attrs['page_slug'] = slug
      attrs['page_url'] = url
      attrs.delete('page_permalink')
      attrs
    end

    def respond_to_missing?(name, include_private = false)
      name == :title || name == :url || @front_matter.key?(name.to_s) || super
    end

    def method_missing(name, *args)
      key = name.to_s
      return @front_matter[key] if @front_matter.key?(key)

      super
    end
  end
end
