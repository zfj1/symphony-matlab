classdef LedPulse < symphonyui.core.Protocol
    
    properties
        led = 'Red LED'                 % Output LED
        preTime = 10                    % Pulse leading duration (ms)
        stimTime = 100                  % Pulse duration (ms)
        tailTime = 400                  % Pulse trailing duration (ms)
        lightAmplitude = 1              % Pulse amplitude (V)
        lightMean = 0
        amp = 'Amp1'                    % Input amplifier
        numberOfAverages = uint16(5)    % Number of epochs
        interpulseInterval = 0          % Duration between pulses (s)
    end
    
    properties (Hidden)
        ledType = symphonyui.core.PropertyType('char', 'row', {'Red LED', 'Green LED', 'Blue LED'});
        ampType = symphonyui.core.PropertyType('char', 'row', {'Amp1', 'Amp2'});
    end
    
    methods
        
        function p = getPreview(obj, panel)
            p = symphonyui.builtin.previews.StimuliPreview(panel, @()createPreviewStimuli(obj));
            function s = createPreviewStimuli(obj)
                s = {obj.ledStimulus()};
            end
        end
        
        function prepareRun(obj)
            prepareRun@symphonyui.core.Protocol(obj);
            
            obj.openFigure(symphonyui.builtin.figures.ResponseFigure(obj.rig.getDevice(obj.amp)));
        end
        
        function stim = ledStimulus(obj)
            p = symphonyui.builtin.stimuli.PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.amplitude = obj.lightAmplitude;
            p.mean = obj.lightMean;
            p.sampleRate = obj.sampleRate;
            p.units = obj.rig.getDevice(obj.led).background.displayUnits;
            
            stim = p.generate();
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@symphonyui.core.Protocol(obj, epoch);
            
            epoch.addStimulus(obj.rig.getDevice(obj.led), obj.ledStimulus());
            epoch.addResponse(obj.rig.getDevice(obj.amp));
        end
        
        function tf = continuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = continueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
    end
    
end
