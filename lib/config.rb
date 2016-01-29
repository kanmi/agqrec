require 'json'

module Config
  class << self
    def config
      config ||= {
        save_path: "./record/%{title}/%{time} - %{title}",
        schedule_file: "./schedule.json",
        time_format: '%Y-%m-%d'
      }
    end

    def config=(config)
      if @config
        @config.each do |key, value|
          remove_field(key)
        end
      end
      
      config.each do |key, value|
        add_field(key, value)
      end

      @config = config.to_a.map { |c|
        [ c[0].to_sym, c[1] ]
      }.to_h
    end
  end

  module Methods
    def load(config_file = 'config.json')
      Config.config = JSON.parse(File.read(config_file)) rescue Config.config
    end
    
    def save(config_file = 'config.json')
      File.write(config_file, JSON.pretty_generate(to_h))
    end

    def add_field(key, value)
      unless instance_variable_get('@key'.to_sym)
        self.class.class_eval { attr_accessor key.to_sym }
        instance_variable_set("@#{key}".to_sym, value)
      end
    end

    def remove_field(key)
      if instance_variable_get('@key'.to_sym)
        key = key.to_s
        self.class.class_eval {
          undef_method key
          undef_method key+'='
        }
      end
    end

    def to_h
      Config.config
    end
  end

  extend Methods
end
