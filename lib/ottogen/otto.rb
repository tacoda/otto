require 'thor'
require_relative './ottogen'

module Ottogen
  class Otto < Thor
    desc "hello NAME", "say hello to NAME"
    def hello(name)
      Ottogen.hello(name)
    end
  end
end
