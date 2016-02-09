require_relative './config'

module Plugin
  include Enumerable

  class << self
    def plugins
      @plugins ||= []
    end
  end

  module Methods
    def init
      Config.providers.each do |name|
        next unless Object.const_get(name) rescue nil

        require_relative "../plugin/#{name}/#{name}"
        plugin = Object.const_get(name)
        plugin.init if plugin.respond_to?(:init)
        plugins << plugin
      end
    end

    def all
      plugins
    end

    def each &block
      plugins.each(&block)
    end
  end
  extend Methods
end
