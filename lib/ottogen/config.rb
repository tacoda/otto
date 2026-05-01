# frozen_string_literal: true

require 'json'
require 'yaml'

require_relative 'collection'
require_relative 'post'

module Ottogen
  class Config
    class Error < StandardError; end

    DEFAULT_PATH = 'config.yml'
    DATA_DIR = '_data'
    DATA_EXTENSIONS = %w[.yml .yaml .json].freeze

    def self.load(path = DEFAULT_PATH, drafts: false)
      raise Error, "config.yml not found at #{path}" unless File.exist?(path)

      values = YAML.safe_load_file(path) || {}
      new(values, load_data_files, load_posts(drafts: drafts), load_collections(values['collections']))
    rescue Psych::SyntaxError => e
      raise Error, "malformed YAML in #{path}: #{e.message}"
    end

    def self.load_collections(config)
      return {} unless config.is_a?(Hash)

      config.to_h { |name, settings| [name, Collection.from_config(name, settings || {})] }
    end
    private_class_method :load_collections

    def self.load_posts(drafts: false)
      posts = Post.discover
      posts += Post.discover_drafts if drafts
      posts.sort_by(&:date).reverse
    rescue Post::Error => e
      raise Error, e.message
    end
    private_class_method :load_posts

    def self.load_data_files
      return {} unless Dir.exist?(DATA_DIR)

      Dir.glob(File.join(DATA_DIR, '*.{yml,yaml,json}')).to_h do |file|
        [File.basename(file, '.*'), parse_data_file(file)]
      end
    end

    def self.parse_data_file(file)
      if file.end_with?('.json')
        JSON.parse(File.read(file))
      else
        YAML.safe_load_file(file)
      end
    rescue Psych::SyntaxError, JSON::ParserError => e
      raise Error, "malformed data file at #{file}: #{e.message}"
    end
    private_class_method :load_data_files, :parse_data_file

    def initialize(values, data_files = {}, posts = [], collections = {})
      @values = values
      @data = Data.new(data_files)
      @posts = posts
      @collections = collections
    end

    attr_reader :data, :posts, :collections

    def tags
      group_posts_by(&:tags)
    end

    def categories
      group_posts_by(&:categories)
    end

    def group_posts_by(&block)
      @posts.each_with_object({}) do |post, acc|
        block.call(post).each { |key| (acc[key] ||= []) << post }
      end
    end
    private :group_posts_by

    def [](key)
      @values[key.to_s]
    end

    def asciidoctor_attributes
      @values.transform_keys { |key| "site_#{key}" }
    end

    def respond_to_missing?(name, include_private = false)
      key = name.to_s
      @values.key?(key) || @collections.key?(key) || super
    end

    def method_missing(name, *args)
      key = name.to_s
      return @collections[key].items if @collections.key?(key)
      return @values[key] if @values.key?(key)

      super
    end

    class Data
      def initialize(files)
        @files = files
      end

      def [](key)
        @files[key.to_s]
      end

      def respond_to_missing?(name, include_private = false)
        @files.key?(name.to_s) || super
      end

      def method_missing(name, *args)
        return @files[name.to_s] if @files.key?(name.to_s)

        super
      end
    end
  end
end
