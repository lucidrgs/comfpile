# frozen_string_literal: true

require_relative "comfpile/version"

require_relative 'comfpile/core.rb'

require_relative 'comfpile/engines/filesource_engine.rb'

module Comfpile
  class Error < StandardError; end
  # Your code goes here...
end
