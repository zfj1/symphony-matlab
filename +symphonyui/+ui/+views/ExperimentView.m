classdef ExperimentView < symphonyui.ui.View

    events
        BeginEpochGroup
        EndEpochGroup
        AddSource
        SelectedNode
        AddProperty
        RemoveProperty
        AddKeyword
        RemoveKeyword
        AddNote
        RemoveNote
    end

    properties (Access = private)
        beginEpochGroupTool
        endEpochGroupTool
        addSourceTool
        experimentTree
        cardPanel
        emptyCard
        experimentCard
        epochGroupCard
        epochCard
        sourceCard
        tabGroup
        propertiesTable
        keywordsTable
        notesTable
        idToNode
    end

    properties (Constant)
        SOURCES_NODE_ID         = 'SOURCES_NODE_ID'
        EPOCH_GROUPS_NODE_ID    = 'EPOCH_GROUPS_NODE_ID'
        
        EMPTY_CARD          = 1
        EXPERIMENT_CARD     = 2
        SOURCE_CARD         = 3
        EPOCH_GROUP_CARD    = 4
        EPOCH_CARD          = 5
    end

    methods
        
        function createUi(obj)
            import symphonyui.ui.util.*;
            
            obj.idToNode = containers.Map();
            
            set(obj.figureHandle, 'Name', 'Experiment');
            set(obj.figureHandle, 'Position', screenCenter(500, 410));
            
            % Toolbar.
            toolbar = uitoolbar( ...
                'Parent', obj.figureHandle);
            obj.beginEpochGroupTool = uipushtool( ...
                'Parent', toolbar, ...
                'TooltipString', 'Begin Epoch Group...', ...
                'ClickedCallback', @(h,d)notify(obj, 'BeginEpochGroup'));
            setIconImage(obj.beginEpochGroupTool, fullfile(symphonyui.app.App.getIconsPath(), 'group_begin.png'));
            obj.endEpochGroupTool = uipushtool( ...
                'Parent', toolbar, ...
                'TooltipString', 'End Epoch Group', ...
                'ClickedCallback', @(h,d)notify(obj, 'EndEpochGroup'));
            setIconImage(obj.endEpochGroupTool, fullfile(symphonyui.app.App.getIconsPath(), 'group_end.png'));
            obj.addSourceTool = uipushtool( ...
                'Parent', toolbar, ...
                'TooltipString', 'Add Source...', ...
                'Separator', 'on', ...
                'ClickedCallback', @(h,d)notify(obj, 'AddSource'));
            setIconImage(obj.addSourceTool, fullfile(symphonyui.app.App.getIconsPath(), 'source_add.png'));
            
            mainLayout = uiextras.HBoxFlex( ...
                'Parent', obj.figureHandle, ...
                'Padding', 11, ...
                'Spacing', 7);

            masterLayout = uiextras.VBoxFlex( ...
                'Parent', mainLayout, ...
                'Spacing', 7);

            obj.experimentTree = uiextras.jTree.Tree( ...
                'Parent', masterLayout, ...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'), ...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'), ...
                'SelectionChangeFcn', @(h,d)notify(obj, 'SelectedNode'));
            root = obj.experimentTree.Root;
            root.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'experiment.png'));
            
            sources = uiextras.jTree.TreeNode( ...
                'Parent', root, ...
                'Name', 'Sources', ...
                'Value', obj.SOURCES_NODE_ID);
            sources.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'folder.png'));
            obj.idToNode(obj.SOURCES_NODE_ID) = sources;
            
            groups = uiextras.jTree.TreeNode( ...
                'Parent', root, ...
                'Name', 'Epoch Groups', ...
                'Value', obj.EPOCH_GROUPS_NODE_ID);
            groups.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'folder.png'));
            obj.idToNode(obj.EPOCH_GROUPS_NODE_ID) = groups;

            detailLayout = uiextras.VBox( ...
                'Parent', mainLayout);

            obj.cardPanel = uix.CardPanel( ...
                'Parent', detailLayout);
            
            % Empty card.
            emptyLayout = uiextras.VBox('Parent', obj.cardPanel); %#ok<NASGU>
            
            % Experiment card.
            experimentLayout = uiextras.VBox( ...
                'Parent', obj.cardPanel, ...
                'Spacing', 7);
            experimentLabelSize = 60;
            obj.experimentCard.nameField = createLabeledTextField(experimentLayout, 'Name:', experimentLabelSize, 'Enable', 'off');
            obj.experimentCard.locationField = createLabeledTextField(experimentLayout, 'Location:', experimentLabelSize, 'Enable', 'off');
            obj.experimentCard.startTimeField = createLabeledTextField(experimentLayout, 'Start time:', experimentLabelSize, 'Enable', 'off');
            obj.experimentCard.purposeField = createLabeledTextField(experimentLayout, 'Purpose:', experimentLabelSize, 'Enable', 'off');
            obj.experimentCard.tabGroupParent = uix.Panel('Parent', experimentLayout, 'BorderType', 'none');
            set(experimentLayout, 'Sizes', [25 25 25 25 -1]);
            
            % Source card.
            sourceLayout = uiextras.VBox( ...
                'Parent', obj.cardPanel, ...
                'Spacing', 7);
            sourceLabelSize = 60;
            obj.sourceCard.labelField = createLabeledTextField(sourceLayout, 'Label:', sourceLabelSize, 'Enable', 'off');
            obj.sourceCard.tabGroupParent = uix.Panel('Parent', sourceLayout, 'BorderType', 'none');
            set(sourceLayout, 'Sizes', [25 -1]);

            % Epoch group card.
            epochGroupLayout = uiextras.VBox( ...
                'Parent', obj.cardPanel, ...
                'Spacing', 7);
            epochGroupLabelSize = 60;
            obj.epochGroupCard.labelField = createLabeledTextField(epochGroupLayout, 'Label:', epochGroupLabelSize, 'Enable', 'off');
            obj.epochGroupCard.startTimeField = createLabeledTextField(epochGroupLayout, 'Start time:', epochGroupLabelSize, 'Enable', 'off');
            obj.epochGroupCard.endTimeField = createLabeledTextField(epochGroupLayout, 'End time:', epochGroupLabelSize, 'Enable', 'off');
            obj.epochGroupCard.sourceField = createLabeledTextField(epochGroupLayout, 'Source:', epochGroupLabelSize, 'Enable', 'off');
            obj.epochGroupCard.tabGroupParent = uix.Panel('Parent', epochGroupLayout, 'BorderType', 'none');
            set(epochGroupLayout, 'Sizes', [25 25 25 25 -1]);
            
            % Epoch card.
            epochLayout = uiextras.VBox( ...
                'Parent', obj.cardPanel, ...
                'Spacing', 7);
            obj.epochCard.tabGroupParent = uix.Panel('Parent', epochLayout, 'BorderType', 'none');
            set(epochLayout, 'Sizes', [-1]);
            
            % Tab panel.
            obj.tabGroup = uitabgroup( ...
                'Parent', obj.experimentCard.tabGroupParent);
            
            % Properties tab.
            propertiesTab = uitab( ...
                'Parent', obj.tabGroup, ...
                'Title', 'Properties');
            propertiesLayout = uiextras.VBox( ...
                'Parent', propertiesTab);
            obj.propertiesTable = createTable( ...
                'Parent', propertiesLayout, ...
                'Container', propertiesLayout, ...
                'Headers', {'Key', 'Value'}, ...
                'Editable', false, ...
                'SelectionMode', javax.swing.ListSelectionModel.SINGLE_SELECTION, ...
                'Buttons', 'off');
            obj.propertiesTable.getTableScrollPane.getRowHeader.setVisible(0);
            obj.propertiesTable.getTableScrollPane.setBorder(javax.swing.BorderFactory.createEmptyBorder());
            obj.createAddRemoveButtons(propertiesLayout, @(h,d)notify(obj, 'AddProperty'), @(h,d)notify(obj, 'RemoveProperty'));
            set(propertiesLayout, 'Sizes', [-1 25]);
            
            % Keywords tab.
            keywordsTab = uitab( ...
                'Parent', obj.tabGroup, ...
                'Title', 'Keywords');
            keywordsLayout = uiextras.VBox( ...
                'Parent', keywordsTab);
            obj.keywordsTable = createTable( ...
                'Parent', keywordsLayout, ...
                'Container', keywordsLayout, ...
                'Headers', {'Keywords'}, ...
                'Editable', false, ...
                'SelectionMode', javax.swing.ListSelectionModel.SINGLE_SELECTION, ...
                'Buttons', 'off');
            obj.keywordsTable.getTableScrollPane.getRowHeader.setVisible(0);
            obj.keywordsTable.getTableScrollPane.setBorder(javax.swing.BorderFactory.createEmptyBorder());
            obj.createAddRemoveButtons(keywordsLayout, @(h,d)notify(obj, 'AddKeyword'), @(h,d)notify(obj, 'RemoveKeyword'));
            set(keywordsLayout, 'Sizes', [-1 25]);
            
            % Notes tab.
            notesTab = uitab( ...
                'Parent', obj.tabGroup, ...
                'Title', 'Notes');
            notesLayout = uiextras.VBox( ...
                'Parent', notesTab);
            obj.notesTable = createTable( ...
                'Parent', notesLayout, ...
                'Container', notesLayout, ...
                'Headers', {'Time', 'Text'}, ...
                'Editable', false, ...
                'SelectionMode', javax.swing.ListSelectionModel.SINGLE_SELECTION, ...
                'Buttons', 'off');
            obj.notesTable.getTableScrollPane.getRowHeader.setVisible(0);
            obj.notesTable.getTableScrollPane.setBorder(javax.swing.BorderFactory.createEmptyBorder());
            obj.notesTable.getTable.getColumnModel.getColumn(0).setMaxWidth(80);
            [~, removeButton] = obj.createAddRemoveButtons(notesLayout, @(h,d)notify(obj, 'AddNote'), @(h,d)notify(obj, 'RemoveNote'));
            set(removeButton, 'Enable', 'off');
            set(notesLayout, 'Sizes', [-1 25]);
            
            set(obj.cardPanel, 'Selection', 1);

            set(mainLayout, 'Sizes', [-1 -2]);
        end
        
        function enableBeginEpochGroup(obj, tf)
            set(obj.beginEpochGroupTool, 'Enable', symphonyui.ui.util.onOff(tf));
        end

        function enableEndEpochGroup(obj, tf)
            set(obj.endEpochGroupTool, 'Enable', symphonyui.ui.util.onOff(tf));
        end
        
        function setSelectedCard(obj, index)
            set(obj.cardPanel, 'Selection', index);
            
            switch index
                case obj.EMPTY_CARD
                    return;
                case obj.EXPERIMENT_CARD
                    parent = obj.experimentCard.tabGroupParent;
                case obj.SOURCE_CARD
                    parent = obj.sourceCard.tabGroupParent;
                case obj.EPOCH_GROUP_CARD
                    parent = obj.epochGroupCard.tabGroupParent;
                case obj.EPOCH_CARD
                    parent = obj.epochCard.tabGroupParent;
            end
            set(obj.tabGroup, 'Parent', parent);
        end

        function setExperimentTreeRootNode(obj, name, id)
            root = obj.experimentTree.Root;
            set(root, ...
                'Name', name, ...
                'Value', id);
            obj.idToNode(id) = root;
        end
        
        function setExperimentName(obj, n)
            set(obj.experimentCard.nameField, 'String', n);
        end
        
        function setExperimentLocation(obj, l)
            set(obj.experimentCard.locationField, 'String', l);
        end
        
        function setExperimentStartTime(obj, t)
            set(obj.experimentCard.startTimeField, 'String', datestr(t, 14));
        end
        
        function setExperimentPurpose(obj, p)
            set(obj.experimentCard.purposeField, 'String', p);
        end
        
        function addSourceNode(obj, parentId, name, id)
            parent = obj.idToNode(parentId);
            node = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', id);
            node.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'source.png'));
            obj.idToNode(id) = node;
        end
        
        function setSourceLabel(obj, l)
            set(obj.sourceCard.labelField, 'String', l);
        end
        
        function addEpochGroupNode(obj, parentId, name, id)
            parent = obj.idToNode(parentId);
            node = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', id);
            node.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'group.png'));
            obj.idToNode(id) = node;
        end
        
        function setEpochGroupLabel(obj, l)
            set(obj.epochGroupCard.labelField, 'String', l);
        end
        
        function setEpochGroupStartTime(obj, t)
            set(obj.epochGroupCard.startTimeField, 'String', datestr(t, 14));
        end
        
        function setEpochGroupEndTime(obj, t)
            set(obj.epochGroupCard.endTimeField, 'String', datestr(t, 14));
        end
        
        function setEpochGroupSource(obj, s)
            set(obj.epochGroupCard.sourceField, 'String', s);
        end

        function setEpochGroupNodeCurrent(obj, id)
            node = obj.idToNode(id);
            node.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'group_current.png'));
        end

        function setEpochGroupNodeNormal(obj, id)
            node = obj.idToNode(id);
            node.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'group.png'));
        end

        function addEpochNode(obj, parentId, name, id)
            parent = obj.idToNode(parentId);
            node = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', id);
            node.setIcon(fullfile(symphonyui.app.App.getIconsPath(), 'epoch.png'));
            obj.idToNode(id) = node;
        end

        function collapseNode(obj, id)
            node = obj.idToNode(id);
            node.collapse();
        end

        function expandNode(obj, id)
            node = obj.idToNode(id);
            node.expand();
        end

        function id = getSelectedNode(obj)
            node = obj.experimentTree.SelectedNodes;
            id = get(node, 'Value');
        end

        function setSelectedNode(obj, id)
            node = obj.idToNode(id);
            obj.experimentTree.SelectedNodes = node;
        end
        
        function setProperties(obj, values)
            symphonyui.ui.util.setRowValues(obj.propertiesTable, values);
        end
        
        function addProperty(obj, key, value)
            symphonyui.ui.util.addRowValue(obj.propertiesTable, {key, value});
        end
        
        function removeProperty(obj, property)
            symphonyui.ui.util.removeRow(obj.propertiesTable, property);
        end
        
        function p = getSelectedProperty(obj)
            p = symphonyui.ui.util.getSelectedRowKey(obj.propertiesTable);
        end
        
        function setKeywords(obj, keywords)
            symphonyui.ui.util.setRowValues(obj.keywordsTable, keywords);
        end
        
        function addKeyword(obj, keyword)
            symphonyui.ui.util.addRowValue(obj.keywordsTable, keyword);
        end
        
        function removeKeyword(obj, keyword)
            symphonyui.ui.util.removeRow(obj.keywordsTable, keyword);
        end
        
        function k = getSelectedKeyword(obj)
            k = symphonyui.ui.util.getSelectedRowKey(obj.keywordsTable);
        end
        
        function setNotes(obj, values)
            for i = 1:numel(values)
                values{i}{1} = datestr(values{i}{1}, 14);
            end
            symphonyui.ui.util.setRowValues(obj.notesTable, values);
        end
        
        function addNote(obj, date, text)
            symphonyui.ui.util.addRowValue(obj.notesTable, {datestr(date, 14), text});
        end

    end
    
    methods (Access = private)
        
        function [addButton, removeButton] = createAddRemoveButtons(obj, parent, addCallback, removeCallback)
            layout = uiextras.HBox( ...
                'Parent', parent, ...
                'Spacing', 0);
            uiextras.Empty('Parent', layout);
            addButton = uicontrol( ...
                'Parent', layout, ...
                'Style', 'pushbutton', ...
                'String', '+', ...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize') + 1, ...
                'Callback', addCallback);
            removeButton = uicontrol( ...
                'Parent', layout, ...
                'Style', 'pushbutton', ...
                'String', '-', ...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize') + 1, ...
                'Callback', removeCallback);
            set(layout, 'Sizes', [-1 25 25]);
        end
        
    end

end
