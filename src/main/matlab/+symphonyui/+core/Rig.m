classdef Rig < handle
    
    properties
        sampleRate
    end
    
    properties (SetAccess = private)
        daqController
        devices
    end
    
    methods
        
        function obj = Rig(description)
            obj.daqController = description.daqController;
            obj.devices = description.devices;
            obj.sampleRate = description.sampleRate;
            
            for i = 1:numel(obj.devices)
                obj.devices{i}.cobj.Clock = obj.daqController.cobj.Clock;
            end
        end
        
        function set.sampleRate(obj, r)
            if isnumeric(r)
                r = symphonyui.core.Measurement(r, 'Hz');
            end
            daq = obj.daqController; %#ok<MCSUP>
            if isprop(daq, 'sampleRate')
                daq.sampleRate = r;
            end
            devs = obj.devices; %#ok<MCSUP>
            for i = 1:numel(devs)
                devs{i}.sampleRate = r;
            end
            obj.sampleRate = r;
        end
        
        function d = getDevice(obj, name)
            for i = 1:numel(obj.devices)
                if strcmp(obj.devices{i}.name, name)
                    d = obj.devices{i};
                    return;
                end
            end
            error(['A device named ''' name ''' does not exist']);
        end
        
    end
    
end

