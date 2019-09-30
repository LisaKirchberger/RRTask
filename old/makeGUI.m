%% Make GUI
f = figure('name', Log.Logfile_name, 'position', [12    42   330   534]);

% Rewardtime
uicontrol('Style', 'text', 'Position', [5 10 60 20], 'String', 'RewDur');
Gui.RewardDur = uicontrol('Style', 'edit' , 'Position', [75 10 40 20], 'String', '200');

% Lick Detection Threshold
Gui.LickValue = uicontrol('Style', 'text', 'Position', [10 40 60 20], 'String', '0');
Gui.Threshold = uicontrol('Style', 'edit' , 'Position', [75 40 60 20], 'String', '8000', 'Callback', 'sendardwm(sport, [''IF '' get(Gui.threshold, ''string'')])');

% Responses
% Hit
uicontrol('Style', 'text', 'Position', [160 50 40 30], 'String', 'Hit');
Gui.Hittext = uicontrol('Style', 'text', 'Position', [200 50 40 30], 'String', '0');
% Miss
uicontrol('Style', 'text', 'Position', [240 50 40 30], 'String', 'Miss');
Gui.Misstext = uicontrol('Style', 'text', 'Position', [280 50 40 30], 'String', '0');
% False Alarm 
uicontrol('Style', 'text', 'Position', [160 10 40 30], 'String', 'False Alarm');
Gui.FAtext = uicontrol('Style', 'text', 'Position', [200 10 40 30], 'String', '0');
% Correct Rejection
uicontrol('Style', 'text', 'Position', [240 10 40 30], 'String', 'Corr Rejec');
Gui.CRtext = uicontrol('Style', 'text', 'Position', [280 10 40 30], 'String', '0');

% Brightness
uicontrol('Style','text','Position',[10 70 90 20],'String','Brightness');
Gui.Brightness = uicontrol('Style', 'edit' , 'Position', [100 70 40 20], 'String', '0');

% Flicker speed
uicontrol('Style','text','Position',[10 90 90 20],'String','Flicker  Frames');
Gui.FlickerFrames = uicontrol('Style', 'edit' , 'Position', [100 90 40 20], 'String', '1');

% CleanBaseLine
uicontrol('Style','text','Position',[150 90 90 20],'String','CleanBaseline');
Gui.CleanBaselineBox = uicontrol('Style', 'checkbox' , 'Position', [250 90 40 20], 'value', 1);
Gui.CleanBaseline = uicontrol('Style', 'edit' , 'Position', [270 90 40 20], 'String', '2');

% Passives
uicontrol('Style','text','Position',[150 160 90 20],'String','PassPerc');
Gui.PassPerc = uicontrol('Style', 'edit' , 'Position', [270 160 40 20], 'String', '50');
uicontrol('Style','text','Position',[150 140 90 20],'String','Passives');
Gui.Passives = uicontrol('Style', 'edit' , 'Position', [270 140 40 20], 'String', '0');
uicontrol('Style','text','Position',[150 120 90 20],'String','Delay');
Gui.Passivedelay = uicontrol('Style', 'edit' , 'Position', [270 120 40 20], 'String', '500');

% Optoproportion
uicontrol('Style','text','Position',[10 120 90 20],'String','Optoproportion');
Gui.OptoProportion = uicontrol('Style', 'edit' , 'Position', [100 120 40 20], 'String', '50');

% Currtrial
uicontrol('Style','text','Position',[10 190 50 20],'String','Currtrial');
Gui.Currtrial= uicontrol('Style','text','Position',[60 190 70 20],'String','Default');

% Nexttrial
uicontrol('Style','text','Position',[10 160 50 20],'String','Nexttrial');
Gui.Nexttrial= uicontrol('Style','text','Position',[60 160 70 20],'String','Default');

% Change Next Trial
NextGo = uicontrol('Style','pushbutton','Position',[150 195 75 30],'String','Next Go', 'Callback', {@changenexttrial,Gui.Nexttrial,1});
NextNoGo = uicontrol('Style','pushbutton','Position',[240 195 75 30],'String','Next No Go','Callback',{@changenexttrial,Gui.Nexttrial,2});

% Licks
uicontrol('Style','text','Position',[10 220 50 20],'String','Licks');
Gui.Lickbox = uicontrol('Style','text','Position',[80 220 20 20],'String','x');

% Stopbutton
Gui.StopButton = uicontrol('Style','pushbutton','Position',[205 235 50 20],'String','Stop','Callback',@stopfunction);


% performance plot
perfplot = subplot(2,1,1);
title('performance')
ylabel('d prime')
xlabel('trials')
axis([1 inf 0 3])
box off
drawnow
