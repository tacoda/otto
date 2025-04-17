Gem::Specification.new do |s| 
    s.name         = "ottogen"
    s.version      = "0.1.0"
    s.author       = "Ian Johnson"
    s.email        = "tacoda@hey.com"
    s.summary      = "AsciiDoc static site generator"
    s.homepage     = "https://www.tacoda.dev/otto/"
    s.licenses     = ['MIT']
    s.description  = File.read(File.join(File.dirname(__FILE__), 'README.md'))
    
    s.files         = Dir["{bin,lib,spec}/**/*"] + %w(LICENSE README.md)
    s.test_files    = Dir["spec/**/*"]
    s.executables   = [ 'otto' ]
    
    s.required_ruby_version = '>=1.9'
    s.add_development_dependency 'rspec'
  end
