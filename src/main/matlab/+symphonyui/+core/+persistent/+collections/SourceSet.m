classdef SourceSet < symphonyui.core.persistent.collections.EntitySet

    properties
        label
    end

    methods

        function obj = SourceSet(sources)
            obj@symphonyui.core.persistent.collections.EntitySet(sources);
        end

        function p = createPreset(obj, name)
            p = symphonyui.core.persistent.SourcePreset(name, obj.getEntityType(), obj.getDescriptionType(), obj.getProperties(), obj.label);
        end

        function l = get.label(obj)
            l = '';
            if ~isempty(obj.objects) && all(cellfun(@(s)isequal(s.label, obj.objects{1}.label), obj.objects))
                l = obj.objects{1}.label;
            end
        end

        function set.label(obj, l)
            for i = 1:obj.size
                obj.get(i).label = l;
            end
        end

    end

end
