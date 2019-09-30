%% Make GUI
try
    f = figure('name', Log.Logfile_name, 'position', [13    50   330   612]);
catch 
    f = figure('position', [13    50   330   612]);
end

% Rewardtime
uicontrol('Style', 'text', 'Position', [10 0 60 20], 'String', 'Reward');
Gui.RewardDur = uicontrol('Style', 'edit' , 'Position', [75 0 40 20], 'String', '200');

% Lick Detection Threshold
Gui.LickValue = uicontrol('Style', 'text', 'Position', [10 20 60 20], 'String', '0');
Gui.Threshold = uicontrol('Style', 'edit' , 'Position', [75 20 60 20], 'String', '8000', 'Callback', 'sendardwm(sport, [''IF '' get(Gui.threshold, ''string'')])');

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
uicontrol('Style','text','Position',[10 150 90 20],'String','GoTrialProportion');
Gui.GoTrialProportion = uicontrol('Style', 'edit' , 'Position', [100 150 40 20], 'String', '50');

% Currtrial
uicontrol('Style','text','Position',[10 210 50 20],'String','Currtrial');
Gui.Currtrial= uicontrol('Style','text','Position',[60 210 70 20],'String','Default');

% Nexttrial
uicontrol('Style','text','Position',[10 190 50 20],'String','Nexttrial');
Gui.Nexttrial= uicontrol('Style','text','Position',[60 190 70 20],'String','Default');

% Change Next Trial
NextGo = uicontrol('Style','pushbutton','Position',[150 195 75 30],'String','Next Go', 'Callback', {@changenexttrial,Gui.Nexttrial,1});
NextNoGo = uicontrol('Style','pushbutton','Position',[240 195 75 30],'String','Next No Go','Callback',{@changenexttrial,Gui.Nexttrial,2});

% Licks
uicontrol('Style','text','Position',[10 230 50 20],'String','Licks');
Gui.Lickbox = uicontrol('Style','text','Position',[80 230 20 20],'String','x');

% Stopbutton
Gui.StopButton = uicontrol('Style','pushbutton','Position',[240 235 75 20],'String','Stop','Callback',@stopfunction);

% Startbutton
Gui.StartButton = uicontrol('Style','pushbutton','Position',[150 235 75 20],'String','Start','Callback',@startfunction);

% CleanBaseLine
uicontrol('Style','text','Position',[185 87 90 20],'String','CleanBaseline');
Gui.CleanBaseline = uicontrol('Style', 'edit' , 'Position', [270 90 40 20], 'String', '2');

% Passives
uicontrol('Style','text','Position',[185 137 90 20],'String','Passive Perc');
Gui.PassPerc = uicontrol('Style', 'edit' , 'Position', [270 140 40 20], 'String', '0');
uicontrol('Style','text','Position',[185 117 90 20],'String','Passive Delay');
Gui.Passivedelay = uicontrol('Style', 'edit' , 'Position', [270 120 40 20], 'String', '0.5');

% TimeToLick
uicontrol('Style','text','Position',[185 157 90 20],'String','TimeToLick');
Gui.TimeToLick = uicontrol('Style', 'edit' , 'Position', [270 160 40 20], 'String', '1.5');


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
