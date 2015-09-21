classdef ConfigurationService < handle
    
    events (NotifyAccess = private)
        InitializedRig
    end
    
    properties (Access = private)
        session
        classRepository
    end
    
    methods
        
        function obj = ConfigurationService(session, classRepository)
            obj.session = session;
            obj.classRepository = classRepository;
        end
        
        function cn = getAvailableRigDescriptions(obj)
            cn = obj.classRepository.get('symphonyui.core.descriptions.RigDescription');
        end
        
        function initializeRig(obj, description)
            if obj.session.hasRig()
                delete(obj.session.getRig());
            end
            try
                constructor = str2func(description);
                rig = symphonyui.core.Rig(constructor());
                obj.session.controller.setRig(rig);
                obj.session.rig = rig;
            catch x
                obj.session.rig = [];
                rethrow(x);
            end
            notify(obj, 'InitializedRig');
        end
        
        function tf = hasRig(obj)
            tf = obj.session.hasRig();
        end
        
        function d = getDevice(obj, name)
            if ~obj.session.hasRig()
                d = [];
                return;
            end
            d = obj.session.getRig().getDevice(name);
        end
        
        function d = getDevices(obj, name)
            if ~obj.session.hasRig()
                d = {};
                return;
            end
            if nargin < 2
                name = '.';
            end
            d = obj.session.getRig().getDevices(name);
        end
        
    end

end
