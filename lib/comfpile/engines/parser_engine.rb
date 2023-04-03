
module Compfile
    class ParserArtefact < Artefact
        attr_reader :included_files
        attr_reader :required_files

        def initialize(*args)
            super(*args)

            @included_files = []
            @required_files = []

            parent_artefact :sourcefile, @target

            add_step do

            end
        end
    end

    class ParserEngine < ArtefactEngine
        def initialize(core, **options)
            super(core, **options)

            @input_file_regex = options[:allowed_files]

            @require_regex = options[:require_reg]
            @include_regex = options[:include_reg]
        end

        def generate_parser_artefact(stage, target)
            match = @input_file_regex.match target
            return nil if match.nil?

            a = Artefact.new(@core, self, stage, target)

            a.parent_artefact(:sourcefile, target)

            a.add_step do

                @parameters[:included_files] = []
                @parameters[:required_files] = []

                File.readlines(@parent_artefact[:file]) do |l|
                    case l
                    when @require_regex
                        filename = $~[:file]

                        own_dir = File.dirname(@target)
                        relative_file = File.join(own_dir, filename)

                        unless craft_artefact(:sourcefile, relative_file).nil?
                            @parameters[:required_files] << require_artefact(:parsed, relative_file)
                        else
                            @parameters[:required_files] << require_artefact(:parsed, filename)
                        end

                    when @include_regex
                        filename = $~[:file]

                        own_dir = File.dirname(@target)
                        relative_file = File.join(own_dir, filename)

                        unless craft_artefact(:sourcefile, relative_file).nil?
                            @parameters[:included_files] << craft_artefact(:parsed, relative_file)
                        else
                            @parameters[:included_files] << craft_artefact(:parsed, filename)
                        end
                    end
                end
            end
        end

        def generate_dependency_artefact(stage, target)

        end

        def craft(stage, target)
            case stage
            when :parsed
                generate_parser_artefact(stage, target)
            when :dependency_list
            
            else 
                nil
            end
        end
    end