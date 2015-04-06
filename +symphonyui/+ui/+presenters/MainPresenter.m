classdef MainPresenter < symphonyui.ui.Presenter
    
    properties (Access = private)
        acquisitionService
        experimentPresenter
        protocolIntrospector
        eventManagers
    end
    
    methods
        
        function obj = MainPresenter(acquisitionService, app, view)            
            if nargin < 3
                view = symphonyui.ui.views.MainView();
            end
            obj = obj@symphonyui.ui.Presenter(app, view); 
            obj.acquisitionService = acquisitionService;
            obj.eventManagers = struct( ...
                'experiment', symphonyui.infra.EventManager(), ...
                'rig', symphonyui.infra.EventManager(), ...
                'protocol', symphonyui.infra.EventManager());
        end
        
    end
    
    methods (Access = protected)
        
        function onGoing(obj)
            obj.populateProtocolList();
            obj.selectCurrentProtocol();
        end
        
        function onBind(obj)
            v = obj.view;
            obj.addListener(v, 'NewExperiment', @obj.onViewSelectedNewExperiment);
            obj.addListener(v, 'OpenExperiment', @obj.onViewSelectedOpenExperiment);
            obj.addListener(v, 'CloseExperiment', @obj.onViewSelectedCloseExperiment);
            obj.addListener(v, 'AddSource', @obj.onViewSelectedAddSource);
            obj.addListener(v, 'BeginEpochGroup', @obj.onViewSelectedBeginEpochGroup);
            obj.addListener(v, 'EndEpochGroup', @obj.onViewSelectedEndEpochGroup);
            obj.addListener(v, 'AddNote', @obj.onViewSelectedAddNote);
            obj.addListener(v, 'ViewExperiment', @obj.onViewSelectedViewExperiment);
            obj.addListener(v, 'SelectedProtocol', @obj.onViewSelectedProtocol);
            obj.addListener(v, 'SetProtocolProperty', @obj.onViewSetProtocolProperty);
            obj.addListener(v, 'Record', @obj.onViewSelectedRecord);
            obj.addListener(v, 'Preview', @obj.onViewSelectedPreview);
            obj.addListener(v, 'Pause', @obj.onViewSelectedPause);
            obj.addListener(v, 'Stop', @obj.onViewSelectedStop);
            obj.addListener(v, 'SelectRig', @obj.onViewSelectedSelectRig);
            obj.addListener(v, 'Settings', @obj.onViewSelectedSettings);
            obj.addListener(v, 'Documentation', @obj.onViewSelectedDocumentation);
            obj.addListener(v, 'UserGroup', @obj.onViewSelectedUserGroup);
            obj.addListener(v, 'AboutSymphony', @obj.onViewSelectedAboutSymphony);
            obj.addListener(v, 'Exit', @obj.onViewSelectedExit);
            
            s = obj.acquisitionService;
            obj.addListener(s, 'OpenedExperiment', @obj.onServiceOpenedExperiment);
            obj.addListener(s, 'ClosedExperiment', @obj.onServiceClosedExperiment);
            obj.addListener(s, 'SelectedRig', @obj.onServiceSelectedRig);
            obj.addListener(s, 'SelectedProtocol', @obj.onServiceSelectedProtocol);
            
            obj.addRigListeners();
            obj.addProtocolListeners();
            if obj.acquisitionService.hasCurrentExperiment()
                obj.addExperimentListeners();
            end
        end
        
        function onViewSelectedClose(obj, ~, ~)
            obj.exit();
        end
        
    end
    
    methods (Access = private)
        
        function onViewSelectedNewExperiment(obj, ~, ~)
            presenter = symphonyui.ui.presenters.NewExperimentPresenter(obj.acquisitionService, obj.app);
            presenter.goWaitStop();
        end
        
        function onViewSelectedOpenExperiment(obj, ~, ~)
            disp('View Selected Open Experiment');
        end
        
        function onServiceOpenedExperiment(obj, ~, ~)   
            obj.addExperimentListeners();
            obj.updateViewState();
            
            experiment = obj.acquisitionService.getCurrentExperiment();
            obj.experimentPresenter = symphonyui.ui.presenters.ExperimentPresenter(experiment, obj.app);
            obj.experimentPresenter.go();
        end
        
        function onViewSelectedCloseExperiment(obj, ~, ~)
            obj.acquisitionService.closeExperiment();
        end
        
        function onServiceClosedExperiment(obj, ~, ~)
            obj.removeExperimentListeners();
            obj.updateViewState();
            
            obj.experimentPresenter.stop();
            obj.experimentPresenter = [];
        end
        
        function addExperimentListeners(obj)
            experiment = obj.acquisitionService.getCurrentExperiment();
            manager = obj.eventManagers.experiment;
            manager.addListener(experiment, 'AddedSource', @obj.onExperimentAddedSource);
            manager.addListener(experiment, 'BeganEpochGroup', @obj.onExperimentBeganEpochGroup);
            manager.addListener(experiment, 'EndedEpochGroup', @obj.onExperimentEndedEpochGroup);
        end
        
        function removeExperimentListeners(obj)
            obj.eventManagers.experiment.removeAllListeners();
        end
        
        function onViewSelectedAddSource(obj, ~, ~)
            experiment = obj.acquisitionService.getCurrentExperiment();
            presenter = symphonyui.ui.presenters.AddSourcePresenter(experiment, obj.app);
            presenter.goWaitStop();
        end
        
        function onExperimentAddedSource(obj, ~, ~)
            obj.updateViewState();
        end
        
        function onViewSelectedBeginEpochGroup(obj, ~, ~)
            experiment = obj.acquisitionService.getCurrentExperiment();
            presenter = symphonyui.ui.presenters.BeginEpochGroupPresenter(experiment, obj.app);
            presenter.goWaitStop();
        end
        
        function onExperimentBeganEpochGroup(obj, ~, ~)
            obj.updateViewState();
        end
        
        function onViewSelectedEndEpochGroup(obj, ~, ~)
            experiment = obj.acquisitionService.getCurrentExperiment();
            experiment.endEpochGroup();
        end
        
        function onExperimentEndedEpochGroup(obj, ~, ~)
            obj.updateViewState();
        end
        
        function onViewSelectedAddNote(obj, ~, ~)
            experiment = obj.acquisitionService.getCurrentExperiment();
            presenter = symphonyui.ui.presenters.AddNotePresenter(experiment, obj.app);
            presenter.goWaitStop();
        end
        
        function onViewSelectedViewExperiment(obj, ~, ~)
            obj.experimentPresenter.show();
        end
        
        function onViewSelectedSelectRig(obj, ~, ~)
            presenter = symphonyui.ui.presenters.SelectRigPresenter(obj.acquisitionService, obj.app);
            presenter.goWaitStop();
        end
        
        function onServiceSelectedRig(obj, ~, ~)
            obj.removeRigListeners();
            obj.addRigListeners();
            obj.updateViewState();
        end
        
        function addRigListeners(obj)
            rig = obj.acquisitionService.getCurrentRig();
            manager = obj.eventManagers.rig;
            manager.addListener(rig, 'Initialized', @obj.onRigInitialized);
            manager.addListener(rig, 'Closed', @obj.onRigClosed);
            manager.addListener(rig, 'state', 'PostSet', @obj.onRigSetState);
        end
        
        function removeRigListeners(obj)
            obj.eventManagers.rig.removeAllListeners();
        end
        
        function onRigInitialized(obj, ~, ~)
            obj.updateViewState();
        end
        
        function onRigClosed(obj, ~, ~)
            obj.updateViewState();
        end
        
        function onRigSetState(obj, ~, ~)
            obj.updateViewState();
        end
        
        function populateProtocolList(obj)
            obj.view.setProtocolList(obj.acquisitionService.getAvailableProtocolIds());
        end
        
        function onViewSelectedProtocol(obj, ~, ~)
            try
                obj.acquisitionService.selectProtocol(obj.view.getSelectedProtocol());
            catch x
                obj.log.debug(x.message, x);
                obj.view.showError(x.message);
                return;
            end
        end
        
        function onServiceSelectedProtocol(obj, ~, ~)
            obj.removeProtocolListeners();
            obj.addProtocolListeners();
            obj.selectCurrentProtocol();
        end
        
        function selectCurrentProtocol(obj)
            obj.view.setSelectedProtocol(obj.acquisitionService.getCurrentProtocolId());
            protocol = obj.acquisitionService.getCurrentProtocol();
            obj.protocolIntrospector = uiextras.jide.Introspector(class(protocol));
            obj.populateProtocolProperties();
            obj.updateViewState();
        end
        
        function addProtocolListeners(obj)
            protocol = obj.acquisitionService.getCurrentProtocol();
            manager = obj.eventManagers.protocol;
            manager.addListener(protocol, 'SetProperty', @obj.onProtocolSetProperty);
        end
        
        function removeProtocolListeners(obj)
            obj.eventManagers.protocol.removeAllListeners();
        end
        
        function onViewSetProtocolProperty(obj, ~, data)
            property = data.Property;
            protocol = obj.acquisitionService.getCurrentProtocol();
            protocol.(property.Name) = property.Value;
        end
        
        function onProtocolSetProperty(obj, ~, ~)
            obj.populateProtocolProperties(true);
            obj.updateViewState();
        end
        
        function onViewSelectedRecord(obj, ~, ~)
            try
                obj.acquisitionService.record();
            catch x
                obj.log.debug(x.message, x);
                obj.view.showError(x.message);
                return;
            end
        end
        
        function onViewSelectedPreview(obj, ~, ~)
            try
                obj.acquisitionService.preview();
            catch x
                obj.log.debug(x.message, x);
                obj.view.showError(x.message);
                return;
            end
        end
        
        function onViewSelectedPause(obj, ~, ~)
            try
                obj.acquisitionService.pause();
            catch x
                obj.log.debug(x.message, x);
                obj.view.showError(x.message);
                return;
            end
        end
        
        function onViewSelectedStop(obj, ~, ~)
            try
                obj.acquisitionService.stop();
            catch x
                obj.log.debug(x.message, x);
                obj.view.showError(x.message);
                return;
            end
        end
        
        function populateProtocolProperties(obj, update)
            if nargin < 2
                update = false;
            end
            protocol = obj.acquisitionService.getCurrentProtocol();
            try
                properties = obj.protocolIntrospector.CreatePropertyList(protocol);
            catch x
                properties = uiextras.jide.PropertyGridField.empty(0, 1);
                obj.log.debug(x.message, x);
                obj.view.showError(x.message);
            end
            if update
                obj.view.updateProtocolProperties(properties);
            else
                obj.view.setProtocolProperties(properties);
            end
        end
        
        function updateViewState(obj)
            import symphonyui.core.RigState;
            
            hasExperiment = obj.acquisitionService.hasCurrentExperiment();
            canEndEpochGroup = hasExperiment && obj.acquisitionService.getCurrentExperiment().canEndEpochGroup();
            canRecordEpochs = hasExperiment && obj.acquisitionService.getCurrentExperiment().canRecordEpochs();
            isRigValid = obj.acquisitionService.getCurrentRig().isValid();
            isStopped = obj.acquisitionService.getCurrentRig().state == RigState.STOPPED;
            
            enableNewExperiment = ~hasExperiment && isStopped && isRigValid;
            enableOpenExperiment = enableNewExperiment;
            enableCloseExperiment = hasExperiment && isStopped;
            enableAddSource = hasExperiment;
            enableBeginEpochGroup = hasExperiment;
            enableEndEpochGroup = canEndEpochGroup;
            enableAddNote = hasExperiment;
            enableViewExperiment = hasExperiment;
            enableSelectRig = ~hasExperiment && isStopped;
            enableSettings = ~hasExperiment && isStopped;
            enableSelectProtocol = isStopped;
            enableProtocolProperties = isStopped;
            enableRecord = false;
            enablePreview = false;
            enablePause = false;
            enableStop = false;
            enableProgressIndicator = false;
            enableWarning = false;
            warning = '';
            status = '';
            
            switch obj.acquisitionService.getCurrentRig().state
                case RigState.STOPPED
                    enableRecord = canRecordEpochs;
                    enablePreview = true;
                case RigState.STOPPING
                    enableProgressIndicator = true;
                    status = 'Stopping...';
                case RigState.PAUSED
                    enableRecord = canRecordEpochs;
                    enablePreview = true;
                    enableStop = true;
                    status = 'Paused';
                case RigState.PAUSING
                    enableStop = true;
                    enableProgressIndicator = true;
                    status = 'Pausing...';
                case RigState.PREVIEWING
                    enablePause = true;
                    enableStop = true;
                    enableProgressIndicator = true;
                    status = 'Previewing...';
                case RigState.RECORDING
                    enablePause = true;
                    enableStop = true;
                    enableProgressIndicator = true;
                    status = 'Recording...';
            end
            
            [valid, msg] = obj.acquisitionService.validate();
            if ~valid
                enableRecord = false;
                enablePreview = false;
                enablePause = false;
                enableStop = false;
                enableWarning = true;
                warning = msg;
            end
            
            obj.view.enableNewExperiment(enableNewExperiment);
            obj.view.enableOpenExperiment(enableOpenExperiment);
            obj.view.enableAddSource(enableAddSource);
            obj.view.enableCloseExperiment(enableCloseExperiment);
            obj.view.enableBeginEpochGroup(enableBeginEpochGroup);
            obj.view.enableEndEpochGroup(enableEndEpochGroup);
            obj.view.enableAddNote(enableAddNote);
            obj.view.enableViewExperiment(enableViewExperiment);
            obj.view.enableSelectRig(enableSelectRig);
            obj.view.enableSettings(enableSettings);
            obj.view.enableSelectProtocol(enableSelectProtocol);
            obj.view.enableProtocolProperties(enableProtocolProperties);
            obj.view.enableRecord(enableRecord);
            obj.view.enablePreview(enablePreview);
            obj.view.enablePause(enablePause);
            obj.view.enableStop(enableStop);
            obj.view.enableProgressIndicator(enableProgressIndicator);
            obj.view.enableWarning(enableWarning);
            obj.view.setWarning(warning);
            obj.view.setStatus(status);
        end
        
        function onViewSelectedSettings(obj, ~, ~)
            presenter = symphonyui.ui.presenters.SettingsPresenter(obj.app);
            presenter.goWaitStop();
        end
        
        function onViewSelectedDocumentation(obj, ~, ~)
            obj.view.showWeb(obj.app.getDocumentationUrl);
        end
        
        function onViewSelectedUserGroup(obj, ~, ~)
            obj.view.showWeb(obj.app.getUserGroupUrl);
        end
        
        function onViewSelectedAboutSymphony(obj, ~, ~)
            message = { ...
                sprintf('Symphony Data Acquisition System'), ...
                sprintf('Version %s', obj.app.getVersion()), ...
                sprintf('%c %s Symphony-DAS', 169, datestr(now, 'YYYY'))};
            obj.view.showMessage(message, 'About Symphony');
        end
        
        function onViewSelectedExit(obj, ~, ~)
            obj.exit();
        end
        
        function exit(obj)
            delete(obj.acquisitionService);
            obj.stop();
        end
        
    end
    
end
