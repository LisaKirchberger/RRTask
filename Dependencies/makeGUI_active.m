%% Make GUI
try
    f = figure('name', Log.Logfile_name, 'position', [13    50   330   612]);
catch 
    f = figure('position', [13    50   330   612]);
end

% Rewardtime
uicontrol('Style', 'text', 'Position', [10 0 60 15], 'String', 'Reward');
Gui.RewardDur = uicontrol('Style', 'edit' , 'Position', [75 0 40 15], 'String', '200');

% Lick Detection Threshold
Gui.LickValue = uicontrol('Style', 'text', 'Position', [10 20 60 15], 'String', '0');
Gui.Threshold = uicontrol('Style', 'edit' , 'Position', [75 20 60 15], 'String', '8000', 'Callback', 'sendardwm(sport, [''IF '' get(Gui.threshold, ''string'')])');

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


% GoTrialProportion
uicontrol('Style','text','Position',[10 165 90 15],'String','GoTrialProportion');
Gui.GoTrialProportion = uicontrol('Style', 'edit' , 'Position', [100 165 40 15], 'String', '50');

% Visual Stimulus Duration
uicontrol('Style','text','Position',[10 135 90 15],'String','VisDuration');
Gui.VisDuration = uicontrol('Style', 'edit' , 'Position', [100 135 40 15], 'String', '1');

% Grace Period
uicontrol('Style','text','Position',[10 105 90 15],'String','GraceDuration');
Gui.GraceDuration = uicontrol('Style', 'edit' , 'Position', [100 105 40 15], 'String', '0.2');


% Task Phase
uicontrol('Style','text','Position',[10 75 90 15],'String','TaskPhase');
Gui.TaskPhase = uicontrol('Style', 'edit' , 'Position', [100 75 40 15], 'String', '1');

% Currtrial
uicontrol('Style','text','Position',[10 210 50 15],'String','Currtrial');
Gui.Currtrial= uicontrol('Style','text','Position',[60 210 70 15],'String','Default');

% Nexttrial
uicontrol('Style','text','Position',[10 190 50 15],'String','Nexttrial');
Gui.Nexttrial= uicontrol('Style','text','Position',[60 190 70 15],'String','Default');

% Change Next Trial
NextGo = uicontrol('Style','pushbutton','Position',[150 195 75 30],'String','Next Go', 'Callback', {@changenexttrial,Gui.Nexttrial,1});
NextNoGo = uicontrol('Style','pushbutton','Position',[240 195 75 30],'String','Next No Go','Callback',{@changenexttrial,Gui.Nexttrial,2});

% Licks
uicontrol('Style','text','Position',[10 230 50 15],'String','Licks');
Gui.Lickbox = uicontrol('Style','text','Position',[80 230 20 15],'String','x');

% Stopbutton
Gui.StopButton = uicontrol('Style','pushbutton','Position',[240 235 75 15],'String','Stop','Callback',@stopfunction);

% Startbutton
Gui.StartButton = uicontrol('Style','pushbutton','Position',[150 235 75 15],'String','Start','Callback',@startfunction);

% CleanBaseLine
uicontrol('Style','text','Position',[150 87 90 15],'String','CleanBaseline');
Gui.CleanBaselineMin = uicontrol('Style', 'edit' , 'Position', [240 90 30 15], 'String', '0');
Gui.CleanBaselineMax = uicontrol('Style', 'edit' , 'Position', [280 90 30 15], 'String', '2');


% Passives
uicontrol('Style','text','Position',[185 140 90 15],'String','Passive Perc');
Gui.PassPerc = uicontrol('Style', 'edit' , 'Position', [270 140 40 15], 'String', '0');
uicontrol('Style','text','Position',[185 120 90 15],'String','Passive Delay');
Gui.Passivedelay = uicontrol('Style', 'edit' , 'Position', [270 120 40 15], 'String', '0.5');


% TimeToLick
uicontrol('Style','text','Position',[185 160 90 15],'String','TimeToLick');
Gui.TimeToLick = uicontrol('Style', 'edit' , 'Position', [270 160 40 15], 'String', '1');

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
