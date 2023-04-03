
module Comfpile
    class Sourcefile
        attr_reader :full_path, :local_path, :resource_location

        def initialize(resource_location, full_path, local_path)
            @resource_location = resource_location
            @full_path = full_path
            @local_path = local_path
        end

        def to_s
            @full_path
        end
    end
end