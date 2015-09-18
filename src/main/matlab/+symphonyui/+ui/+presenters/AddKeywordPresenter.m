classdef AddKeywordPresenter < symphonyui.ui.Presenter

    properties (Access = private)
        log
        entitySet
    end

    methods

        function obj = AddKeywordPresenter(entitySet, view)
            if nargin < 2
                view = symphonyui.ui.views.AddKeywordView();
            end
            obj = obj@symphonyui.ui.Presenter(view);
            obj.view.setWindowStyle('modal');
            
            obj.log = log4m.LogManager.getLogger(class(obj));
            obj.entitySet = entitySet;
        end

    end

    methods (Access = protected)

        function onGoing(obj)
            obj.populateTextCompletionList();
        end
        
        function onGo(obj)
            obj.view.requestTextFocus();
        end

        function onBind(obj)
            v = obj.view;
            obj.addListener(v, 'KeyPress', @obj.onViewKeyPress);
            obj.addListener(v, 'Add', @obj.onViewSelectedAdd);
            obj.addListener(v, 'Cancel', @obj.onViewSelectedCancel);
        end
    end
    
    methods (Access = private)
        
        function populateTextCompletionList(obj)
            list = symphonyui.app.Options.getDefault().keywordList;
            try
                obj.view.setTextCompletionList(list());
            catch x
                obj.log.debug(['Unable to populate text completion list: ' x.message], x);
            end
        end

        function onViewKeyPress(obj, ~, event)
            switch event.data.Key
                case 'return'
                    obj.onViewSelectedAdd();
                case 'escape'
                    obj.onViewSelectedCancel();
            end
        end

        function onViewSelectedAdd(obj, ~, ~)
            obj.view.update();
            
            keyword = obj.view.getText();
            try
                tf = obj.entitySet.addKeyword(keyword);
            catch x
                obj.log.debug(x.message, x);
                obj.view.showError(x.message);
                return;
            end
            
            if tf
                obj.result = keyword;
            end
            
            obj.close();
        end

        function onViewSelectedCancel(obj, ~, ~)
            obj.close();
        end

    end

end
