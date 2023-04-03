
require 'debug'

module Comfpile
    class ArtefactExecSkipError < StandardError
    end

    class Artefact
        attr_reader :core, :engine

        attr_reader :exit_state
        attr_reader :stage, :target

        attr_reader :linked_artefacts

        # ARTEFACT STATES
        # 
        # The following states are known to the system:
        # - blocked:    The Artefact is blocked and waiting on other artefacts
        # - waiting:    The Artefact is idle and ready to be queued
        # - running:    The Artefact is currently being run
        #     Note that this is not a state, but is determined by the
        #     @running flag
        # - succeeded:  it has finished its work without issue
        # - skipped:    it didn't run/won't run because of failed dependencies
        # - failed:     it has failed due to a requirement not being met
        #
        # Meta-States exist:
        # - in_progress/completed: Anything but/Only succeeded, skipped, failed

        def initialize(core, engine, stage, target)
            @core = core
            @engine = engine

            @stage = stage
            @target = target

            @age = Time.at(0)

            @parent_artefact = nil

            @required_artefacts = nil
            @linked_artefacts = nil

            @steps = []
            @step_additions = nil

            @waitlist = []

            @steps_done_ctr = 0

            @parameters = {}

            @exit_state = nil
            @running = false
        end

        def [](key)
            v = @parameters[key]
            return v unless v.nil?

            if @parent_artefact
                return @parent_artefact[key]
            end
        end
        def []=(key, value)
            @parameters[key] = value
        end

        private def add_step_data(data)
            @step_additions ||= []

            @step_additions << data
        end
        private def process_additional_step_data
            unless @step_additions.nil?
                @steps.insert(@steps_done_ctr, @step_additions)
                @steps.flatten!
                @step_additions = nil
            end
        end

        def add_step(&block)
            add_step_data({
                type: :block,
                executed: false,
                block: block
            })
        end

        def parent_artefact(stage, target)
            @parent_artefact = require_artefact(stage, target)
        end

        def require_artefact(stage, target)
            artefact = @core.craft_artefact(stage, target)

            if(artefact.nil?)
                fail! "Missing artefact dependency for #{stage} #{target}!"
            else
                @waitlist << {
                    artefact: artefact,
                    required: true
                }
            end

            @required_artefacts ||= {}
            @required_artefacts[stage] ||= {}
            @required_artefacts[stage][target] = artefact

            artefact
        end

        def craft_artefact(stage, target)
            artefact = @core.craft_artefact(stage, target)

            artefact
        end

        def waitlist_empty?
            return true if completed?

            loop do
                return true if @waitlist.empty?

                item = @waitlist[-1]

                return false if item[:artefact].in_progress?

                if not item[:required]
                    @waitlist.pop
                elsif item[:artefact].succeeded?
                    @waitlist.pop
                else
                    skip! skip! "Failed artefact dependency: #{item[:artefact]}"
                    
                    return true
                end
            end
        end

        def state
            return :blocked unless waitlist_empty?
            return @exit_state unless @exit_state.nil?
            
            return :running if @running

            return :waiting
        end

        def completed?
            not @exit_state.nil?
        end

        def succeeded?
            @exit_state == :succeeded
        end

        def in_progress?
            not completed?
        end

        def waiting?
            self.state == :waiting
        end

        private def mark_state_change(state, reason, abort: false)
            puts "#{@stage} #{target}: Reached state #{state}: #{reason}"
            @exit_state = state
            @reason = reason

            abort_step! if abort
        end

        def skip!(reason, **opts)
            mark_state_change(:skipped, reason, **opts)
        end
        def fail!(reason, **opts)
            mark_state_change(:failed, reason, **opts)
        end
        def succeed!(reason, **opts)
            mark_state_change(:succeeded, reason, **opts)
        end
        
        def abort_step!
            raise ArtefactExecSkipError
        end

        def execute_step
            return unless waiting?
            @running = true
            
            process_additional_step_data

            next_step = @steps[@steps_done_ctr]
            succeed! "All done", abort: true if next_step.nil?

            case next_step[:type]
            when :block
                instance_exec &next_step[:block]
            else
                fail! "Unknown artefact step taken!", abort: true
            end

            @steps_done_ctr += 1
            succeed! "All done", abort: true if @steps_done_ctr >= @steps.length
            
        ensure
            @running = false
        end

        def to_s
            "#<Compfile::Artefact #{@stage} #{@target}>"
        end
    end
end