# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name         = 'ottogen'
  s.version      = '1.0.0'
  s.author       = 'Ian Johnson'
  s.email        = 'tacoda@hey.com'
  s.summary      = 'AsciiDoc static site generator'
  s.homepage     = 'https://www.tacoda.dev/otto/'
  s.licenses     = ['MIT']
  s.description  = File.read(File.join(File.dirname(__FILE__), 'README.md'))

  s.files       = Dir['{bin,lib,spec}/**/*'] + %w[LICENSE README.md]
  s.executables = ['otto']

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'asciidoctor', '~> 2.0', '>= 2.0.20'
  s.add_dependency 'listen', '~> 3.7'
  s.add_dependency 'logger', '~> 1.6'
  s.add_dependency 'thor', '~> 1.2'
  s.add_dependency 'webrick', '~> 1.7'

  s.add_development_dependency 'rspec', '~> 3.13'
  s.add_development_dependency 'rubocop', '~> 1.60'
  s.metadata['rubygems_mfa_required'] = 'true'
end
