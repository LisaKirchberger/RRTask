%% Make GUI
try
    f = figure('name', Log.Logfile_name, 'position', [13    50   330   612]);
catch 
    f = figure('position', [ 13    50   330   266]);
end


% Visual Stimulus
% Aperture
uicontrol('Style','text','Position',[10 65 90 20],'String','Vis Aperture');
uicontrol('Style','text','Position',[90 69 15 15],'String','L');
uicontrol('Style','text','Position',[120 69 15 15],'String','R');
Gui.ApertureL = uicontrol('Style', 'checkbox' , 'Position', [102 69 15 15], 'value', 1);
Gui.ApertureR = uicontrol('Style', 'checkbox' , 'Position', [132 69 15 15], 'value', 0);
% Contrast
uicontrol('Style','text','Position',[10 45 90 20],'String','Vis Contrast');
Gui.Contrast = uicontrol('Style', 'edit' , 'Position', [100 45 40 20], 'String', '80');

% Auditory Stimulus
% Intensity
uicontrol('Style','text','Position',[10 90 90 20],'String','Aud Intensity');
Gui.AudIntensity = uicontrol('Style', 'edit' , 'Position', [100 90 40 20], 'String', '30');
% Frequency
uicontrol('Style','text','Position',[10 110 90 20],'String','Aud Freq');
Gui.AudFreq = uicontrol('Style', 'edit' , 'Position', [80 110 60 20], 'String', '13000');




% Stopbutton
Gui.StopButton = uicontrol('Style','pushbutton','Position',[240 235 75 20],'String','Stop','Callback',@stopfunction);

% Startbutton
Gui.StartButton = uicontrol('Style','pushbutton','Position',[150 235 75 20],'String','Start','Callback',@startfunction);


