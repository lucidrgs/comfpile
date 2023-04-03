
require_relative 'artefact.rb'

module Comfpile
    class ArtefactEngine

        attr_accessor :priority, :subpriority

        def initialize(core, **options)
            @core = core

            @priority = options[:priority] || 0
            @subpriority = options[:subpriority] || 0

            @recipes = []
        end

        def craft(stage, target)
            @recipes.each do |recipe|
                match = target

                if recipe[:stage]
                    next unless stage == recipe[:stage]
                end

                if r = recipe[:regex]
                    if r.is_a? String
                        next unless target == r
                    else
                        match = r.match target
                        next if match.nil?
                    end
                end

                new_artefact = Artefact.new(@core, self, stage, target)

                item = recipe[:block].call(match, new_artefact)

                return new_artefact if item
            end

            nil
        end

        def <=>(other)
            prio = other.priority <=> self.priority
            return prio unless prio == 0

            other.subpriority <=> self.subpriority
        end

        def add_recipe(stage = nil, target_regex, &block)
            @recipes << {
                regex: target_regex,
                stage: stage,
                block: block
            }
        end
    end
end