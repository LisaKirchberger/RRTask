%%
clear all
clc

%% Structure of this task:
% Mouse is head fixed and sits or runs (running is not relevant for task) on a treadmill
% The start of a trial is marked by a flashing of the masking light (light
% source can be LED or even screen), combined with occasional optogenetic stimulation
% In trials with optogenetic stimulation mouse has to lick to get a reward,
% in other trials there is no reward

%% Laser Powers

% Green GL532T3 SLOC
% with Lisa's single fiber
% 0.5 mW    3.10  
% 1.0 mW    3.20  
% 1.5 mW    3.35  
% 2.0 mW    3.55
% 2.5 mW    3.85
% 3.0 mW    4.62
% 5.0 mW    4.80
% 7.5 mW    4.92
% 10  mW    5.00

% Experiment Parameters
prompt = {'Mouse Name', 'Exp Nr', 'Date', 'Laser power', 'Task Name'};
def = {'Name', '1', datestr(datenum(date), 'yyyymmdd'), '5', 'EasyOptoDetection', '1'};
answer = inputdlg(prompt,'Please enter parameters',1,def);
Log.Mouse = answer{1};
Log.Expnum = answer{2};
Log.Date = answer{3};
Log.Laserpower = answer{4};
Log.Task = answer{5};
Log.Logfile_name = [Log.Mouse, '_', Log.Date, '_B', Log.Expnum];

% Saving location
username = getenv('username');
%Par.Save_Location = fullfile('C:','Users',username,'Dropbox','MouseOutput',Log.Task);
Par.Save_Location = fullfile('Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs',Log.Task);
if ~exist(Par.Save_Location, 'dir')
    mkdir(Par.Save_Location)
end

% Task Parameters
Par.ITI = 3;                        % in seconds
Par.FA_Timeout = 2;                 % in seconds
Par.random_ITI = 5;                 % in seconds
Par.Stim_duration = 1.5;            % in seconds, is also time to lick!
Par.Opto_duration = 1;              % in seconds
Par.Grace_duration = 0.2;           % in seconds

% Setup Parameters
gammaconversion = 'gammaconOpto';
Par.Screenx = 1920;
Par.Screeny = 1200;
Par.Refresh = 60;
Par.ScreenDistance = 11;  % distance of screen, in cm
Par.ScreenWidth = 51;     % width of screen, in cm
Par.ScreenHeight = 31;    % height of screen, in cm
Par.zdistBottom = 11.8;   % distance of mouse eyes to bottom in cm
Par.ScreenAngle = 90;
Par.black = 0;
Par.maxlum = 1;
Par.minlum = eval([gammaconversion '(Par.black,''rgb2lum'')']);
Par.greylum = (Par.minlum+Par.maxlum)./2;
Par.white = eval([gammaconversion '(Par.maxlum,''lum2rgb'')']);
Par.greylum = eval([gammaconversion '(Par.greylum,''lum2rgb'')']);
Par.grey = [0.5 0.5 0.5];
Par.color = [0,1,0.5];
Par.optoport = 0;

% initialize the DAS card
dasinit(23);
for i = 0:7
    dasbit(i, 0)
end

%% open Cogent
addpath(genpath('Dependencies'))
addpath(genpath('Analysis'))
cgloadlib
cgshut
%cgopen(Par.Screenx, Par.Screeny, 32,Par.Refresh , 0) %debug
cgopen(Par.Screenx, Par.Screeny, 32,Par.Refresh , 1) %real
cogstd('sPriority','high')
for i = 1:20
    cgflip(Par.grey)
end



%% start the Arduino connection

sport = serial('com3');
set(sport,'InputBufferSize', 10240)
if strcmp(get(sport, 'status'), 'closed')
    fopen(sport)
end
set(sport, 'baudrate', 250000);
set(sport, 'timeout', 0.1);
sendtoard(sport, 'ID');
    
%% make the GUI
run makeGUI
global stopaftertrial
stopaftertrial = 0;
TrialMatrix = [];
Trial = 0;
HitCounter = 0;
MissCounter = 0;
FACounter = 0;
CRCounter = 0;


fprintf('make changes to settings in GUI then press enter \n')
pause


while ~stopaftertrial
    
    Trial = Trial + 1;
    fprintf('Trial %d \n', Trial)
    LickVec = [];
    Reaction = [];
    ValveOpenTime = 0;
    
    %% Read in Parameters from the GUI
    Log.RewardDur(Trial) = str2double(get(Gui.RewardDur, 'string'));
    Log.Threshold(Trial) = str2double(get(Gui.Threshold, 'string'));
    Log.Brightness(Trial) = str2double(get(Gui.Brightness, 'string'))/100;
    Log.FlickerFrames(Trial) = str2double(get(Gui.FlickerFrames, 'string'));
    
    if get(Gui.CleanBaselineBox,'value')
        Log.CleanBaseline(Trial) = str2double(get(Gui.CleanBaseline, 'string'));
    else
        Log.CleanBaseline(Trial) = NaN;
    end
    Log.OptoProportion(Trial) = str2double(get(Gui.OptoProportion, 'string'));
    
    % Color for this trial
    Log.FlashColor(Trial,:) = getcolor(Par.grey, Par.color, Log.Brightness(Trial));
    
    
    %% Make a Trial Matrix with miniblocks if TrialMatrix is empty
    if isempty(TrialMatrix)
        MiniLength = 4;
        Miniblock = zeros(MiniLength,1);
        Miniblock(1:round(Log.OptoProportion(Trial)/(100/MiniLength)))= 1;
        TrialMatrix = Miniblock(randperm(MiniLength));
    end
    
    %% Set the Currtrial
    if strcmp(get(Gui.Nexttrial, 'string'), 'Default')
        Log.Trialtype(Trial) = TrialMatrix(1);
        TrialMatrix(1) = [];
    elseif strcmp(get(Gui.Nexttrial, 'string'), 'Go')
        Log.Trialtype(Trial) = 1;
        set(Gui.Nexttrial, 'String', 'Default')
    else
        Log.Trialtype(Trial) = 0;
        set(Gui.Nexttrial, 'String', 'Default')
    end
    
    if Log.Trialtype(Trial) == 1
        set(Gui.Currtrial, 'String', 'Go')
        
    else
        set(Gui.Currtrial, 'String', 'No Go')
    end
    
    %% Passive
    Log.Passivedelay(Trial) = str2double(get(Gui.Passivedelay, 'string'))/1000;
    Log.PassPerc(Trial) = str2double(get(Gui.PassPerc, 'string'));
    Pick = rand;
    if Pick < Log.PassPerc(Trial)/100
        if str2double(get(Gui.Passives, 'string')) 
            Log.Passives(Trial) = 1;
            set(Gui.Passives, 'String', str2double(get(Gui.Passives, 'string'))-1)
        else 
            Log.Passives(Trial) = 0;
        end
    else
        Log.Passives(Trial) = 0;
    end
    
    if Log.Passives(Trial) == 1 && Log.Trialtype(Trial) == 1
        gavepassive = 0;  
    else
        gavepassive = 1;
    end
    
    
    
    %% Show the Masking Stimulus with/without Opto
    
    
    % check for communication from the serial port
    checkforLicks %only using 'right' port
    
    % send Rewardtime and Threshold to Arduino
    sendtoard(sport, ['IL ' get(Gui.RewardDur, 'String')])
    sendtoard(sport, ['IF ' get(Gui.Threshold, 'String')])
    sendtoard(sport, ['IT ' get(Gui.Passivedelay, 'String')]);
    
    
    % Turn on Stimulus
    cgflip(Log.FlashColor(Trial,:))
    cgflip('V')
    cgflip(Par.grey)% !!!  The stimulus is on the screen, but it isn't???
    cgflip('V')%only if I add this it will actually be at 0
    onset = tic;
    
    % Send Start signal to Arduino
    fprintf(sport, 'IS');   % starts the trial
    
    if Log.Trialtype(Trial) == 1 % Optotrial
        sendtoard(sport, 'IE 1')
        dasbit(Par.optoport,1);   % turns on Laser\
        fprintf('OPTOTRIAL \n')
    else
        sendtoard(sport, 'IE 2')
    end
    optoonset = tic;
    
    counter = 0;
    while toc(onset) < Par.Stim_duration
        
        counter = counter + 1;
        % Keep flipping the screen in Frequency of Flicker time
        for i = 1 : Log.FlickerFrames(Trial)
            cgflip('V')
        end
        % flip up grey screen and put green in buffer
        cgflip(Log.FlashColor(Trial,:))
        for i = 1 : Log.FlickerFrames(Trial)
            cgflip('V')
        end
        % flip up green screen and put grey in buffer
        cgflip(Par.grey)
        
        % check for licks
        if floor(counter/5) == counter/5
            checkforLicks
        end
        
        % check if should turn off opto
        if toc(optoonset) > Par.Opto_duration
            dasbit(Par.optoport,0);   % turns off Laser
        end
        
        % check if should give a passive
        if Log.Passives(Trial) && toc(onset) > Log.Passivedelay(Trial) && ~gavepassive
            % give passive
            sendtoard(sport, 'IP')
            gavepassive = 1;
        end
        
        
    end
    cgflip(Par.grey)
    
    % Trial is over, disable the reward
    sendtoard(sport, 'ID'); % disable the lick reward
    % Wait until Optotime is over (if necessary), then turn off opto
    while toc(optoonset) < Par.Opto_duration
       % do nothing 
    end
    dasbit(Par.optoport,0);   % turns off Laser
    
    
    checkforLicks
    
    % get the trialtime from the arduino
    fprintf(sport, 'IA');
    
    I = '';
    to = tic;
    while ~strcmp(I, 'R') && toc(to) < 0.2
        I = fscanf(sport, '%s'); % break test
        if strcmp(I, 'R')
            break
        end
    end
    trialtime = str2num(fscanf(sport, '%s'));
    
    try
        Log.LickVec{Trial} = LickVec - trialtime;
    catch
        disp('no trialtime?')
    end
    
    
    
    
    %% Process response
    
    if strcmp(Reaction, '1') 
        Log.Reaction{Trial} = 'Hit';
        HitCounter = HitCounter + 1;
        set(Gui.Hittext, 'string', num2str(HitCounter));
    elseif strcmp(Reaction, '0')
        Log.Reaction{Trial} = 'False Alarm';
        FACounter = FACounter + 1;
        set(Gui.FAtext, 'string', num2str(FACounter))
        % and give the timeout punishment for FA
        pause(Par.FA_Timeout)
    else
        if Log.Trialtype(Trial) == 1
            Log.Reaction{Trial} = 'Miss';
            Log.RT(Trial) = NaN;
            MissCounter = MissCounter + 1;
            set(Gui.Misstext, 'string', num2str(MissCounter))
        elseif Log.Trialtype(Trial) == 0
            Log.Reaction{Trial} = 'Correct Rejection';
            Log.RT(Trial) = NaN;
            CRCounter = CRCounter + 1;
            set(Gui.CRtext, 'string', num2str(CRCounter))
        end
    end
    
    
    %% update the d prime plot
    Hitrate = HitCounter / (HitCounter + MissCounter);
    FArate = FACounter / (FACounter + CRCounter);
    Log.dprime(Trial) = norminv(Hitrate) - norminv(FArate);
    Log.criterion(Trial) = -0.5*(norminv(Hitrate)+ norminv(FArate));
    
    plot(Log.dprime)
    hold on
    plot(1:Trial,zeros(Trial,1),'r')
    plot(1:Trial,repmat(1.5,Trial,1),'g')
    title('performance')
    ylabel('d prime')
    xlabel('trials')
    axis([1 inf -0.5 2])
    hold off
    
    
    %% save
    save([Par.Save_Location '\' Log.Logfile_name] , 'Log', 'Par')
    
    
    
    %% ITI and Cleanbaseline
    
    
    if get(Gui.CleanBaselineBox,'value')
         % pause the ITI time without the cleanbaseline time
        pause((Par.ITI + Par.random_ITI * rand) - Log.CleanBaseline(Trial))
        LickVec = [];
        cleanBaseTimer = tic;
        % then the cleanbaseline
        while toc(cleanBaseTimer) < Log.CleanBaseline(Trial)
            checkforLicks
            if ~isempty(LickVec)
                cleanBaseTimer = tic;
                LickVec = [];
            end
        end
       
    else
        % otherwise just pause the full time
        pause(Par.ITI + Par.random_ITI * rand)
    end
    
    

    
    
    
   
    
    
    %% check for stopaftertrial
    
    
    if stopaftertrial == 1
        dlgTitle    = 'User Question';
        dlgQuestion = 'Do you want to Pause or Exit?';
        choicePauseExit = questdlg(dlgQuestion,dlgTitle,'Pause','Exit', 'Pause'); %Pause = default
        switch choicePauseExit
            case 'Pause'
                Continue = 0;
                while Continue == 0
                    dlgTitle    = 'User Question';
                    dlgQuestion = 'Do you want to Continue?';
                    choiceContinue = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes'); %Pause = default
                    switch choiceContinue
                        case 'Yes'
                            Continue = 1;
                        case 'No'
                            Continue = 0;
                    end
                end
                stopaftertrial = 0;
            case 'Exit'
                stopaftertrial = 1;
        end
    end
end


if strcmp(get(sport, 'status'), 'open')
    fclose(sport);
end
cogstd('sPriority','normal')
cgshut





%% Arduino commands

% start Arduino
% sport = serial('com3');
% set(sport,'InputBufferSize', 10240)
% if strcmp(get(sport, 'status'), 'closed')
%     fopen(sport)
% end
% set(sport, 'baudrate', 250000);
% set(sport, 'timeout', 0.1);
% sendtoard(sport, 'ID');



% Reward 1 is pin 10 digitalWrite(10, LOW) closes it and digitalWrite(10,HIGH) opens it
% Reward 2 is pin 11 same as above

%fprintf(sport, 'IF');   % returns 'D' and sets the treshold to the value you send
%fprintf(sport, 'IM');   % returns 'D' and sets easymode to the value you send
%fprintf(sport, 'IL');   % returns 'D' and sets Rewardtime1 to the value you send, is the right port
%fprintf(sport, 'IR');   % returns 'D' and sets Rewardtime2 to the value you send, is the left port
%fprintf(sport, 'IO');   % Motor
%fprintf(sport, 'IT');   % returns 'D' and sets Timeout to the value you send? what is timeout, I think it's the Graceperiod or the passive delay

%fprintf(sport, 'IS');   % starts the trial, Trialtime, passive and wentthrough, nothing gets returned
%fprintf(sport, 'IE 1'): % returns 'D' and sets Enable to 1 (right)
%fprintf(sport, 'IE 2'); % returns 'D' and sets Enable to 2 (left)
%fprintf(sport, 'IA');   % returns 'R' and returns the Trialtime, so basically the RT
%fprintf(sport, 'IC');   % returns 'D' followed by the values of the two thresholds (first 1 then 2)
%fprintf(sport, 'IP');   % returns 'D' and gives a passive if the time is greater than timeout
%fprintf(sport, 'ID');   % returns 'D', sets Enable to 0 and closes both valves

% if sport.BytesAvailable
%     while ~strcmp(I, 'O') && sport.BytesAvailable
%         I = fscanf(sport, '%s');
%         if strcmp(I, 'O')
%             break
%         end
%     end
% end
% 