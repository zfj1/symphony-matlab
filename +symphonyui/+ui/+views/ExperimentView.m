classdef ExperimentView < symphonyui.ui.View

    events
        AddSource
        BeginEpochGroup
        EndEpochGroup
        AddNote
        SelectedNode
        AddSourceProperty
        RemoveSourceProperty
        ViewEpochGroupSource
    end

    properties (Access = private)
        toolbar
        addSourceTool
        beginEpochGroupTool
        endEpochGroupTool
        addNoteTool
        nodeTree
        cardPanel
        experimentCard
        epochGroupCard
        epochCard
        sourceCard
        notesTable
        noteField
        idMap
    end

    methods

        function createUi(obj)
            import symphonyui.ui.util.*;

            set(obj.figureHandle, 'Name', 'Experiment');
            set(obj.figureHandle, 'Position', symphonyui.util.screenCenter(500, 500));

            % Toolbar.
            obj.toolbar = uitoolbar( ...
                'Parent', obj.figureHandle);
            obj.addSourceTool = uipushtool( ...
                'Parent', obj.toolbar, ...
                'TooltipString', 'Add Source...', ...
                'ClickedCallback', @(h,d)notify(obj, 'AddSource'));
            obj.beginEpochGroupTool = uipushtool( ...
                'Parent', obj.toolbar, ...
                'Separator', 'on', ...
                'TooltipString', 'Begin Epoch Group', ...
                'ClickedCallback', @(h,d)notify(obj, 'BeginEpochGroup'));
            setIconImage(obj.beginEpochGroupTool, fullfile(symphonyui.app.App.getIconsPath(), 'group_begin.png'));
            obj.endEpochGroupTool = uipushtool( ...
                'Parent', obj.toolbar, ...
                'TooltipString', 'End Epoch Group', ...
                'ClickedCallback', @(h,d)notify(obj, 'EndEpochGroup'));
            setIconImage(obj.endEpochGroupTool, fullfile(symphonyui.app.App.getIconsPath(), 'group_end.png'));
            setIconImage(obj.addSourceTool, fullfile(symphonyui.app.App.getIconsPath(), 'source_add.png'));
            obj.addNoteTool = uipushtool( ...
                'Parent', obj.toolbar, ...
                'Separator', 'on', ...
                'TooltipString', 'Add Note...', ...
                'ClickedCallback', @(h,d)notify(obj, 'AddNote'));
            setIconImage(obj.addNoteTool, fullfile(symphonyui.app.App.getIconsPath(), 'note_add.png'));

            mainLayout = uiextras.VBoxFlex( ...
                'Parent', obj.figureHandle, ...
                'Padding', 11, ...
                'Spacing', 7);

            topLayout = uiextras.HBoxFlex( ...
                'Parent', mainLayout, ...
                'Spacing', 7);

            obj.nodeTree = uiextras.jTree.Tree( ...
                'Parent', topLayout, ...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'), ...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'), ...
                'SelectionChangeFcn', @(h,d)notify(obj, 'SelectedNode'));

            obj.cardPanel = uix.CardPanel( ...
                'Parent', topLayout);

            % Experiment card.
            experimentLayout = uiextras.VBox( ...
                'Parent', obj.cardPanel, ...
                'Spacing', 7);
            experimentLabelSize = 60;
            obj.experimentCard.nameField = createLabeledTextField(experimentLayout, 'Name:', [experimentLabelSize -1]);
            set(obj.experimentCard.nameField, 'Enable', 'off');
            obj.experimentCard.locationField = createLabeledTextField(experimentLayout, 'Location:', [experimentLabelSize -1]);
            set(obj.experimentCard.locationField, 'Enable', 'off');
            obj.experimentCard.purposeField = createLabeledTextField(experimentLayout, 'Purpose:', [experimentLabelSize -1]);
            set(obj.experimentCard.purposeField, 'Enable', 'off');
            obj.experimentCard.startTimeField = createLabeledTextField(experimentLayout, 'Start time:', [experimentLabelSize -1]);
            set(obj.experimentCard.startTimeField, 'Enable', 'off');
            set(experimentLayout, 'Sizes', [25 25 25 25]);

            % Source card.
            sourceLayout = uiextras.VBox( ...
                'Parent', obj.cardPanel, ...
                'Spacing', 7);
            sourceLabelSize = 60;
            obj.sourceCard.labelField = createLabeledTextField(sourceLayout, 'Label:', [sourceLabelSize -1]);
            set(obj.sourceCard.labelField, 'Enable', 'off');
            [obj.sourceCard.propertyGrid, obj.sourceCard.addSourcePropertyButton, obj.sourceCard.removeSourcePropertyButton] = ...
                createLabeledPropertyGrid(sourceLayout, 'Properties:', [sourceLabelSize -1]);
            set(obj.sourceCard.addSourcePropertyButton, 'Callback', @(h,d)notify(obj, 'AddSourceProperty'));
            set(obj.sourceCard.removeSourcePropertyButton, 'Callback', @(h,d)notify(obj, 'RemoveSourceProperty'));

            set(sourceLayout, 'Sizes', [25 120]);

            % Epoch group card.
            epochGroupLayout = uiextras.VBox( ...
                'Parent', obj.cardPanel, ...
                'Spacing', 7);
            epochGroupLabelSize = 60;
            obj.epochGroupCard.labelField = createLabeledTextField(epochGroupLayout, 'Label:', [epochGroupLabelSize -1]);
            set(obj.epochGroupCard.labelField, 'Enable', 'off');
            obj.epochGroupCard.startTimeField = createLabeledTextField(epochGroupLayout, 'Start time:', [epochGroupLabelSize -1]);
            set(obj.epochGroupCard.startTimeField, 'Enable', 'off');
            [obj.epochGroupCard.sourceField, l] = createLabeledTextField(epochGroupLayout, 'Source:', [epochGroupLabelSize -1]);
            set(obj.epochGroupCard.sourceField, 'Enable', 'off');
            obj.epochGroupCard.viewSourceButton = uicontrol( ...
                'Parent', l, ...
                'Style', 'pushbutton', ...
                'String', '...', ...
                'TooltipString', 'View Source', ...
                'Callback', @(h,d)notify(obj, 'ViewEpochGroupSource'));
            set(l, 'Sizes', [epochGroupLabelSize -1 30]);

            set(epochGroupLayout, 'Sizes', [25 25 25]);

            % Epoch card.
            epochLayout = uiextras.VBox( ...
                'Parent', obj.cardPanel, ...
                'Spacing', 7);
            epochLabelSize = 60;
            obj.epochCard.labelField = createLabeledTextField(epochLayout, 'Label:', [epochLabelSize -1]);
            set(obj.epochCard.labelField, 'Enable', 'off');
            set(epochLayout, 'Sizes', [25]);

            set(obj.cardPanel, 'UserData', {'Experiment', 'Source', 'Epoch Group', 'Epoch'});
            set(obj.cardPanel, 'Selection', 1);

            set(topLayout, 'Sizes', [140 -1]);

            % Notes controls.
            notesLayout = uiextras.VBox( ...
                'Parent', mainLayout, ...
                'Spacing', 7);

            obj.notesTable = createTable( ...
                'Parent', notesLayout, ...
                'Container', notesLayout, ...
                'Headers', {'Time', 'Text'}, ...
                'Editable', false, ...
                'Name', 'Notes', ...
                'Buttons', 'off');
            obj.notesTable.getTableScrollPane.getRowHeader.setVisible(0);
            obj.notesTable.getTable.getColumnModel.getColumn(0).setMaxWidth(80);

            obj.idMap = containers.Map();

            set(mainLayout, 'Sizes', [-1 110]);
        end

        function setExperimentNode(obj, name, id)
            root = obj.nodeTree.Root;
            set(root, ...
                'Name', name, ...
                'Value', id);
            root.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'experiment.png'));
            obj.idMap(id) = root;
        end

        function addSourceNode(obj, parentId, name, id)
            parent = obj.idMap(parentId);
            node = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', id);
            node.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'source.png'));
            obj.idMap(id) = node;
        end

        function enableBeginEpochGroup(obj, tf)
            set(obj.beginEpochGroupTool, 'Enable', symphonyui.util.onOff(tf));
        end

        function enableEndEpochGroup(obj, tf)
            set(obj.endEpochGroupTool, 'Enable', symphonyui.util.onOff(tf));
        end

        function addEpochGroupNode(obj, parentId, name, id)
            parent = obj.idMap(parentId);
            node = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', id);
            node.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'group.png'));
            obj.idMap(id) = node;
        end

        function setEpochGroupNodeCurrent(obj, id)
            node = obj.idMap(id);
            node.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'group_current.png'));
        end

        function setEpochGroupNodeNormal(obj, id)
            node = obj.idMap(id);
            node.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'group.png'));
        end

        function addEpochNode(obj, parentId, name, id)
            parent = obj.idMap(parentId);
            node = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', id);
            node.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'epoch.png'));
            obj.idMap(id) = node;
        end

        function collapseNode(obj, id)
            node = obj.idMap(id);
            node.collapse();
        end

        function expandNode(obj, id)
            node = obj.idMap(id);
            node.expand();
        end

        function id = getSelectedNode(obj)
            node = obj.nodeTree.SelectedNodes;
            id = get(node, 'Value');
        end

        function setSelectedNode(obj, id)
            node = obj.idMap(id);
            obj.nodeTree.SelectedNodes = node;
        end

        function l = getCardList(obj)
            l = get(obj.cardPanel, 'UserData');
        end

        function setSelectedCard(obj, index)
            set(obj.cardPanel, 'Selection', index);
        end

        function addNote(obj, id, date, text)
            jtable = obj.notesTable.getTable();
            jtable.getModel().addRow({datestr(date, 14), text});
            jtable.clearSelection();
            jtable.scrollRectToVisible(jtable.getCellRect(jtable.getRowCount()-1, 0, true));
            obj.idMap(id) = jtable.getModel.getRowCount() - 1;
        end

        function enableExperimentName(obj, tf)
            set(obj.experimentCard.nameField, 'Enable', symphonyui.util.onOff(tf));
        end

        function setExperimentName(obj, n)
            set(obj.experimentCard.nameField, 'String', n);
        end

        function enableExperimentLocation(obj, tf)
            set(obj.experimentCard.locationField, 'Enable', symphonyui.util.onOff(tf));
        end

        function setExperimentLocation(obj, l)
            set(obj.experimentCard.locationField, 'String', l);
        end

        function enableExperimentPurpose(obj, tf)
            set(obj.experimentCard.purposeField, 'Enable', symphonyui.util.onOff(tf));
        end

        function setExperimentPurpose(obj, p)
            set(obj.experimentCard.purposeField, 'String', p);
        end

        function enableExperimentStartTime(obj, tf)
            set(obj.experimentCard.startTimeField, 'Enable', symphonyui.util.onOff(tf));
        end

        function setExperimentStartTime(obj, t)
            set(obj.experimentCard.startTimeField, 'String', datestr(t, 14));
        end

        function enableEpochGroupLabel(obj, tf)
            set(obj.epochGroupCard.labelField, 'Enable', symphonyui.util.onOff(tf));
        end

        function setEpochGroupLabel(obj, l)
            set(obj.epochGroupCard.labelField, 'String', l);
        end

        function enableEpochGroupStartTime(obj, tf)
            set(obj.epochGroupCard.startTimeField, 'Enable', symphonyui.util.onOff(tf));
        end

        function setEpochGroupStartTime(obj, t)
            set(obj.epochGroupCard.startTimeField, 'String', datestr(t, 14));
        end

        function enableEpochGroupSource(obj, tf)
            set(obj.epochGroupCard.sourceField, 'Enable', symphonyui.util.onOff(tf));
        end

        function s = getEpochGroupSource(obj)
            s = get(obj.epochGroupCard.sourceField, 'String');
        end

        function setEpochGroupSource(obj, s)
            set(obj.epochGroupCard.sourceField, 'String', s);
        end

        function enableEpochLabel(obj, tf)
            set(obj.epochCard.labelField, 'Enable', symphonyui.util.onOff(tf));
        end

        function setEpochLabel(obj, l)
            set(obj.epochCard.labelField, 'String', l);
        end

        function enableSourceLabel(obj, tf)
            set(obj.sourceCard.labelField, 'Enable', symphonyui.util.onOff(tf));
        end

        function setSourceLabel(obj, l)
            set(obj.sourceCard.labelField, 'String', l);
        end

        function setSourceProperties(obj, propertyMap)
            properties = mapToFields(propertyMap);
            set(obj.sourceCard.propertyGrid, 'Properties', properties);
        end

        function p = getSelectedSourceProperty(obj)
            p = obj.sourceCard.propertyGrid.GetSelectedProperty();
        end

    end

end

function fields = mapToFields(map)
    fields = uiextras.jide.PropertyGridField.empty(0, 1);
    keys = map.keys;
    if isempty(keys)
        return;
    end

    for i = 1:numel(keys)
        k = keys{i};

        f = uiextras.jide.PropertyGridField(k, map(k));
        fields(end + 1) = f; %#ok<AGROW>
    end
end