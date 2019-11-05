%% Make GUI
try
    f = figure('name', Log.Logfile_name, 'position', [13    50   330   612]);
catch 
    f = figure('position', [ 13    50   330   266]);
end


% Stopbutton
Gui.StopButton = uicontrol('Style','pushbutton','Position',[240 235 75 20],'String','Stop','Callback',@stopfunction);

% Startbutton
Gui.StartButton = uicontrol('Style','pushbutton','Position',[150 235 75 20],'String','Start','Callback',@startfunction);


uicontrol('Style', 'text', 'Position', [50 50 200 100], 'String', 'If you have set the Laser to value 233 and have uploaded the correct Arduino script press start');