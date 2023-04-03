
require_relative 'sourcefile.rb'

module Comfpile
    class ResourceLocation
        attr_reader :base_path
        attr_reader :files

        attr_reader :priority, :subpriority

        def initialize(core, base_path, **options)
            raise ArgumentError, "Resource path must be a string!" unless base_path.is_a? String
            raise ArgumentError, "Resource path must be a valid file or directory" unless File.exists?(base_path)
            @base_path = File.expand_path(base_path)
            
            @name = options[:name] || @location
            @core = core

            @priority = options[:priority] || 0;
            @subpriority = options[:subpriority] || 0;

            @settings_map = Hash.new()

            @known_files = Hash.new()
        end

        def find_sourcefile(item_key)
            return @known_files[item_key] if @known_files.include? item_key

            item_path = File.join(@base_path, item_key)
            new_item = nil

            if File.exists? item_path
                new_item = Sourcefile.new(self, item_path, item_key)

                @known_files[item_key] = new_item
            end

            new_item
        end

        def <=>(other)
            prio = other.priority <=> self.priority
            return prio unless prio == 0

            other.subpriority <=> self.subpriority
        end
    end
end