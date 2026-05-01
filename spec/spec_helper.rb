# frozen_string_literal: true

require 'fileutils'
require 'stringio'
require 'tmpdir'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'ottogen/ottogen'
require 'ottogen/otto'

module Ottogen
  module SpecHelpers
    def in_tmp_dir
      Dir.mktmpdir('ottogen-spec') do |dir|
        Dir.chdir(dir) do
          yield dir
        end
      end
    end

    def capture_stdout
      original = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original
    end
  end
end

RSpec.configure do |config|
  config.include Ottogen::SpecHelpers
  config.disable_monkey_patching!
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
  config.order = :random
  Kernel.srand config.seed
end
