
require_relative 'artefact_engine.rb'

module Comfpile
    class Core
        attr_reader :processing_stack

        def initialize()
            @artefact_engines = []
            @artefact_prio_counter = 0

            # Artefacts are arranged in a double-hash.
            # First query is stage, second filename.
            @artefacts = {}

            # Stack-style processing queue for item processing
            @processing_stack = []
        end

        def find_artefact(stage, file = :none)
            @artefacts.dig(stage, file)
        end

        def craft_artefact(stage, file = :none)
            artefact = find_artefact(stage, file)

            return artefact unless artefact.nil?

            @artefact_engines.each do |engine|
                artefact = engine.craft stage, file
                
                if artefact
                    @artefacts[stage] ||= {}
                    @artefacts[stage][file] = artefact
                    
                    @processing_stack.push artefact

                    return artefact
                end
            end

            nil
        end

        def add_artefact(stage, file = :none, engine: nil, artefact_class:  Comfpile::Artefact)
            return unless find_artefact(stage, file).nil?

            a = Artefact.new(self, engine, stage, file);
            
            @artefacts[stage] ||= {}
            @artefacts[stage][file] = a

            yield(a) if block_given?

            nil
        end

        def add_artefact_engine(engine_class = Comfpile::ArtefactEngine, **options)
            new_engine = engine_class.new(self,
                subpriority: @artefact_prio_counter, **options)
            @artefact_prio_counter += 1

            yield(new_engine) if block_given?

            @artefact_engines << new_engine
            @artefact_engines.sort!

            new_engine
        end

        def processing_stack_prune()
            loop do
                return if @processing_stack.empty?

                if @processing_stack[-1].completed?
                    @processing_stack.pop
                else
                    break
                end
            end

            nil
        end

        def processing_stack_find_next()
            @processing_stack.reverse_each do |a|
                return a if a.waiting?
            end

            nil
        end

        def execute_step
            return if @processing_stack.empty?
            puts "Got #{@processing_stack.length} items..."

            processing_stack_prune
            
            artefact = processing_stack_find_next

            return nil if artefact.nil?

            puts "Processing artefact #{artefact.stage} #{artefact.target}"

            begin
                artefact.execute_step
            rescue ArtefactExecSkipError
            end

            nil
        end
    end
end