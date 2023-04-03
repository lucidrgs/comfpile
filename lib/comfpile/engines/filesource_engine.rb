

module Comfpile
    class FilesourceEngine < ArtefactEngine
        def initialize(core, **options)
            super(core, **options)

            @root_path = options[:root_path]
        end

        def craft(stage, target)
            return nil unless stage == :sourcefile

            full_path = File.join(@root_path, target)
            
            return nil unless File.exists? full_path

            a = Artefact.new(@core, self, stage, target);
            a[:file] = full_path
            a[:filepath] = full_path

            a 
        end
    end
end