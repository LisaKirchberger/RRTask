%% Make GUI
try
    f = figure('name', Log.Logfile_name, 'position', [13    50   330   612]);
catch 
    f = figure('position', [13    50   330   612]);
end

% Licks
uicontrol('Style','text','Position',[10 230 50 15],'String','Licks');
Gui.Lickbox = uicontrol('Style','text','Position',[80 230 20 15],'String','x');

% Currtrial
uicontrol('Style','text','Position',[10 210 50 15],'String','Currtrial');
Gui.Currtrial= uicontrol('Style','text','Position',[60 210 70 15],'String','Default');

% Nexttrial
uicontrol('Style','text','Position',[10 190 50 15],'String','Nexttrial');
Gui.Nexttrial= uicontrol('Style','text','Position',[60 190 70 15],'String','Default');

% Task Phase
uicontrol('Style','text','Position',[10 165 90 15],'String','TaskPhase');
Gui.TaskPhase = uicontrol('Style', 'edit' , 'Position',[100 165 40 15] , 'String', '1');

% GoTrialProportion
uicontrol('Style','text','Position',[10 140 90 15],'String','GoTrialProportion');
Gui.GoTrialProportion = uicontrol('Style', 'edit' , 'Position', [100 140 40 15], 'String', '50');

% Passives
uicontrol('Style','text','Position',[10 120 90 15],'String','Passive Perc');
Gui.PassPerc = uicontrol('Style', 'edit' , 'Position', [100 120 40 15], 'String', '0');
uicontrol('Style','text','Position',[10 105 90 15],'String','Passive Delay');
Gui.Passivedelay = uicontrol('Style', 'edit' , 'Position', [100 105 40 15], 'String', '0');

% Lick Detection Threshold
Gui.LickValue = uicontrol('Style', 'text', 'Position', [10 20 60 15], 'String', '0');
Gui.Threshold = uicontrol('Style', 'edit' , 'Position', [75 20 60 15], 'String', '8000', 'Callback', 'sendardwm(sport, [''IF '' get(Gui.threshold, ''string'')])');

% Rewardtime
uicontrol('Style', 'text', 'Position', [10 0 60 15], 'String', 'Reward');
Gui.RewardDur = uicontrol('Style', 'edit' , 'Position', [75 0 40 15], 'String', '200');

% Startbutton
Gui.StartButton = uicontrol('Style','pushbutton','Position',[150 235 75 15],'String','Start','Callback',@startfunction);

% Stopbutton
Gui.StopButton = uicontrol('Style','pushbutton','Position',[240 235 75 15],'String','Stop','Callback',@stopfunction);

% Change Next Trial
NextGo = uicontrol('Style','pushbutton','Position',[150 195 75 30],'String','Next Go', 'Callback', {@changenexttrial,Gui.Nexttrial,1});
NextNoGo = uicontrol('Style','pushbutton','Position',[240 195 75 30],'String','Next No Go','Callback',{@changenexttrial,Gui.Nexttrial,2});

% Virtual Reality
uicontrol('Style','text','Position',[175 160 90 15],'String','VR Dist');
Gui.VRDist = uicontrol('Style', 'edit' , 'Position', [270 160 40 15], 'String', '200');
uicontrol('Style','text','Position',[175 145 90 15],'String','Visual Stim Dist');
Gui.VisualStimDist = uicontrol('Style', 'edit' , 'Position', [270 145 40 15], 'String', '50');
uicontrol('Style','text','Position',[175 130 90 15],'String','FA Dist');
Gui.FADist = uicontrol('Style', 'edit' , 'Position', [270 130 40 15], 'String', '50');
uicontrol('Style','text','Position',[160 115 130 15],'String','Conversion Factor');
Gui.ConversionFactor = uicontrol('Style', 'edit' , 'Position', [270 115 40 15], 'String', '3');


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




% performance plot
perfplot = subplot(2,1,1);
set(perfplot, 'Position', [0.15 0.72 0.8 0.25])
title('Performance')
ylabel('d prime')
xlabel('Trials')
axis([1 inf 0 3])
box off
drawnow

runningplot = subplot(2,1,2);
set(runningplot, 'Position', [0.15 0.46 0.8 0.16])
title('Running')
ylabel('Speed')
axis([-2 1.5 -10 100])
box off
hold(runningplot, 'on')
drawnow
