%%
clear all
clc

%% Structure of this task:
% Mouse is head fixed and sits or runs (running is not relevant for task) on a treadmill
% On Go Trials the mouse is presented with an auditory stimulus (frequency of the tone can be varied) and/or an optogenetic stimulus The start of a trial is marked by a full screen checkerboard stimulus combined with 
% optogenetic stimulation on go trials and nothing appears on no go trials
% In trials with optogenetic stimulation mouse has to lick to get a reward,
% in other trials there is no reward

%% Laser Powers

% Green GL532T3 SLOC
% with Lisa's single fiber
% 0.02mW    2.90
% 0.2 mW    3.00
% 0.5 mW    3.10  
% 1.0 mW    3.20  
% 1.5 mW    3.35  
% 2.0 mW    3.55
% 2.5 mW    3.85
% 3.0 mW    4.62
% 5.0 mW    4.80
% 7.5 mW    4.92
% 10  mW    5.00
% 25  mW    5.50
% 75  mW    6.50
% 100 mW    7.00
% 150 mW    7.50

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
Par.Save_Location = fullfile('Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs',Log.Task);
if ~exist(Par.Save_Location, 'dir')
    mkdir(Par.Save_Location)
end

% Check if Logfile with identical name already exists
Matlabpath = pwd;
cd(Par.Save_Location)
lognames = dir([Log.Logfile_name, '*']);
if ~isempty(lognames)
    disp('CAREFUL YOU ARE ABOUT TO OVERWRITE A LOGFILE')
    keyboard
end
cd(Matlabpath)

% Task Parameters
Par.ITI = 2;                        % in seconds
Par.FA_Timeout = 5;                 % in seconds
Par.random_ITI = 8;                 % in seconds
Par.Trial_duration = 1.5;            % in seconds, is also time to lick!
Par.Opto_duration = 1;              % in seconds
Par.Grace_duration = 0.2;           % in seconds
Par.AudDuration = 1;                % in seconds
    
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
Par.minlum = eval([gammaconversion '(0,''rgb2lum'')']);
Par.maxlum = eval([gammaconversion '(1,''rgb2lum'')']);
Par.greylum = (Par.minlum+Par.maxlum)./2;
Par.lumrange = Par.maxlum - Par.minlum;
Par.grey = eval([gammaconversion '(Par.greylum,''lum2rgb'')']);
Par.grey = [Par.grey Par.grey Par.grey]; %[0.5 0.5 0.5];
Par.optoport = 0;
Par.PixPerDeg = (Par.Screenx/2)/atand((0.5*Par.ScreenWidth)/Par.ScreenDistance);
Par.CheckSzDeg = 8;
Par.CheckSz = ceil(Par.CheckSzDeg.*Par.PixPerDeg);
Par.Aud_nchannels = 1;      % nuymber of channels, 1=mono, 2=stereo;
Par.Aud_nbits = 8;          % Number of bits per sample, 8 or 16
Par.Aud_sampfrequency = 11025;  % number of samples per second, e.g. 8000, 11025, 22050 and 44100
Par.Aud_nbuffers = 2;       % number of sound buffers

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
for i = 1:120
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
run makeGUI_AudStim
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
    Log.CleanBaseline(Trial) = str2double(get(Gui.CleanBaseline, 'string'));
    Log.GoTrialProportion(Trial) = str2double(get(Gui.GoTrialProportion, 'string'));
    Log.OptoStim(Trial) = get(Gui.OptoStim, 'value');
    
    %% make the Auditory Stimulus
    Log.AudFreq(Trial) = str2double(get(Gui.AudFreq, 'string'));
    Log.AudIntensity(Trial) = str2double(get(Gui.AudIntensity, 'string'))/100;
    
    if Log.AudStim(Trial)
        cgsound('open',Par.Aud_nchannels,Par.Aud_nbits,Par.Aud_sampfrequency,-50,1) % -50db volume attenuation, sound device 0 (default sound device)
        soundwav = sin((1:Par.AudDuration*Par.Aud_sampfrequency)*2*pi*Log.AudFreq(Trial)/Par.Aud_sampfrequency);
        cgsound('MatrixSND',1,soundwav,Par.Aud_sampfrequency)
        cgsound('vol',1,Log.AudIntensity(Trial))
    end
    
    
    
    %% Make a Trial Matrix with miniblocks if TrialMatrix is empty
    if isempty(TrialMatrix)
        MiniLength = 4;
        Miniblock = zeros(MiniLength,1);
        Miniblock(1:round(Log.GoTrialProportion(Trial)/(100/MiniLength)))= 1;
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
        Log.Passives(Trial) = 1;
    else
        Log.Passives(Trial) = 0;
    end
    if Log.Passives(Trial) == 1 && Log.Trialtype(Trial) == 1
        gavepassive = 0;  
    else
        gavepassive = 1;
    end
    
    
    %% Auditory / Optogenetic Stimulation
    
    % check for communication from the serial port
    checkforLicks %only using 'right' port
    
    % send Rewardtime, Threshold and Passvie Delay to Arduino
    sendtoard(sport, ['IL ' get(Gui.RewardDur, 'String')])
    sendtoard(sport, ['IF ' get(Gui.Threshold, 'String')])
    sendtoard(sport, ['IT ' get(Gui.Passivedelay, 'String')]);
      
    % Send Start signal to Arduino and start the Trial
    fprintf(sport, 'IS');   % starts the trial
    TrialOnset = tic;
    if Log.Trialtype(Trial) == 1    % Go Trial
        sendtoard(sport, 'IE 1')      
    else                            % No Go Trial 
        sendtoard(sport, 'IE 2')
    end
    
    % Play Auditory tone if wanted and this is a Go Trial
    if Log.AudIntensity(Trial) && Log.Trialtype(Trial) == 1
        cgsound('play', 1)
    end
    
    % Start Optogenetic Stimulation if wanted and this is a Go Trial
    if Log.OptoStim(Trial) && Log.Trialtype(Trial) == 1
        dasbit(Par.optoport,1);   % turns on Laser
        Optostatus = 1;           
        OptoOnset = tic;
        fprintf('OPTOTRIAL \n')
    else
        Optostatus = 0;
    end
    
    counter = 0;
    
    while toc(TrialOnset) < Par.Trial_duration || toc(OptoOnset) < Par.Opto_duration
        
        counter = counter + 1;
        
        % check for licks
        if floor(counter/5) == counter/5
            checkforLicks
        end
        
        % check if should turn off opto
        if toc(OptoOnset) > Par.Opto_duration && Optostatus == 1
            dasbit(Par.optoport,0);   % turns off Laser
            Optostatus = 0;
        end
        
        % check if should give a passive
        if Log.Passives(Trial) && toc(TrialOnset) > Log.Passivedelay(Trial) && ~gavepassive
            % give passive
            sendtoard(sport, 'IP')
            gavepassive = 1;
        end
        
    end
    
    % end of trial
    
    % flip up a grey screen
    cgflip(Par.grey)
    
    % disable the reward
    dasbit(Par.optoport,0);     % turns off Laser again, just in case
    sendtoard(sport, 'ID');     % disable the lick reward
    Log.Trialdur(Trial) = toc(TrialOnset);

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
        Log.Reactionidx(Trial) = 1;
        HitCounter = HitCounter + 1;
        set(Gui.Hittext, 'string', num2str(HitCounter));
        Log.RT(Trial) = str2double(RT);
        cprintf([0 1 0], 'Hit \n')
    elseif strcmp(Reaction, '0')
        Log.Reaction{Trial} = 'False Alarm';
        FACounter = FACounter + 1;
        Log.Reactionidx(Trial) = -1;
        set(Gui.FAtext, 'string', num2str(FACounter))
        Log.RT(Trial) = str2double(RT);
        cprintf([1 0 0], 'False Alarm \n')
        % and give the timeout punishment for FA
        pause(Par.FA_Timeout)
    else
        if Log.Trialtype(Trial) == 1
            Log.Reaction{Trial} = 'Miss';
            Log.RT(Trial) = NaN;
            Log.Reactionidx(Trial) = 0;
            MissCounter = MissCounter + 1;
            set(Gui.Misstext, 'string', num2str(MissCounter))
            cprintf([0.5 0.5 0.5], 'Miss \n')
        elseif Log.Trialtype(Trial) == 0
            Log.Reaction{Trial} = 'Correct Rejection';
            Log.RT(Trial) = NaN;
            CRCounter = CRCounter + 1;
            Log.Reactionidx(Trial) = 2;
            set(Gui.CRtext, 'string', num2str(CRCounter))
            cprintf([0 1 0.5], 'Correct Rejection \n')
        end
    end
    
    
    %% update the d prime plot
    Log.d_prime_windowsize = 20;
    if Trial <= Log.d_prime_windowsize
        Log.dprime(Trial) = Calcdprime(Log.Reactionidx);
        Log.criterion(Trial) = CalcCriterion(Log.Reactionidx);
    else
        Log.dprime(Trial) = Calcdprime(Log.Reactionidx(Trial-Log.d_prime_windowsize:Trial));
        Log.criterion(Trial) = CalcCriterion(Log.Reactionidx(Trial-Log.d_prime_windowsize:Trial));
    end
    
    plot(Log.dprime)
    hold on
    plot(1:Trial,zeros(Trial,1),'r')
    plot(1:Trial,repmat(1.5,Trial,1),'g')
    title('performance')
    ylabel('d prime')
    xlabel('trials')
    axis([1 inf min([min(Log.dprime) -0.5]) max([max(Log.dprime) 2])])
    hold off
    
    
    %% save
    save([Par.Save_Location '\' Log.Logfile_name] , 'Log', 'Par')
    
    
    
    %% ITI and Cleanbaseline
    
    
    if Log.CleanBaseline(Trial)
        % First pause fixed ITI
        pause(Par.ITI)
        % Pause for Cleanbaselinetime until the mouse stops licking
        LickVec = [];
        cleanBaseTimer = tic;
        while toc(cleanBaseTimer) < Log.CleanBaseline(Trial)
            checkforLicks
            if ~isempty(LickVec)
                cleanBaseTimer = tic;
                LickVec = [];
            end
        end
        % pause the random ITI time without the cleanbaseline time
        pause((Par.random_ITI * rand) - Log.CleanBaseline(Trial))
        
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