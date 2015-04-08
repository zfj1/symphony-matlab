function [c, b, layout] = createLabeledDropDownMenuWithButton(parent, label, labelSize, callback)
    import symphonyui.ui.util.*;
    layout = uiextras.HBox( ...
        'Parent', parent, ...
        'Spacing', 7);
    createLabel(layout, label);
    c = createDropDownMenu(layout, {' '});
    b = uicontrol( ...
        'Parent', layout, ...
        'Style', 'pushbutton', ...
        'String', '...', ...
        'Callback', callback);
    set(layout, 'Sizes', [labelSize -1 30]);
end