%%
clear all %#ok<CLALL>
clc

try
    %% Structure of this task:
    % Mouse is head fixed and sits in a tube setup or runs (running is not relevant for task) on a treadmill
    % On Go Trials the mouse is presented with a figure ground stimulus with certain orientations for figure and ground (needs to be set for
    % each mouse in MouseParams before start of training. On NoGo Trials a figure-ground stimulus with different orientations appears that is
    % not rewarded
    % On Go Trials mouse has to lick to get a reward
    % On No Go Trials there is no reward, but a 5s timeout if the mouse licks
           
    addpath(genpath(fullfile(pwd,'Dependencies')))
    addpath(genpath(fullfile(pwd,'Analysis')))
    
    global Par Log %#ok<TLEV>
    
    %% Experiment Parameters
    prompt = {'Mouse Name', 'Exp Nr', 'Date'};
    def = {'Name', '1', datestr(datenum(date), 'yyyymmdd')};
    answer = inputdlg(prompt,'Please enter parameters',1,def);
    
    Log.Task = 'RRTask';
    Log.Mouse = answer{1};
    run checkMouse
    
    Log.Expnum = answer{2};
    Log.Date = answer{3};
    Log.Logfile_name = [Log.Mouse, '_', Log.Date, '_B', Log.Expnum];

    % Select the Setup
    Setups = {'Optosetup', 'WFsetup', 'Box1', 'Box2', 'Box3', 'Box4', 'Box5', 'Box6'};
    Setupchoice = menu('Choose the Setup',Setups);
    Log.Setup = Setups{Setupchoice};
    
    if strcmp(Log.Setup, 'WFsetup')
        Log.Exposure = '50';
        Par.Save_Location2 = fullfile('\\NIN518\Imaging\',[Log.Mouse Log.Date], '\', [Log.Mouse Log.Expnum]);
        if ~exist(Par.Save_Location2, 'dir')
            keyboard
        end
    end

    
    %% Saving location of Logfile 
    
    % Saving Location
    Matlabpath = pwd;
    if strcmp(Log.Setup(1:3), 'Box')
        pathend = strfind(Matlabpath, 'RRTask')-1;
        Par.Save_Location = [Matlabpath(1:pathend) 'Logfiles'];
    else
       Par.Save_Location = fullfile('Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs', Log.Task); 
    end
    if ~exist(Par.Save_Location, 'dir')
        keyboard
    end

    % Check if Logfile with identical name already exists
    cd(Par.Save_Location)
    lognames = dir([Log.Logfile_name, '*']);
    if ~isempty(lognames)
        dlgTitle    = 'User Question';
        dlgQuestion = sprintf('CAREFUL YOU ARE ABOUT TO OVERWRITE A LOGFILE, do you want to change the session of exit?');
        choiceLOG = questdlg(dlgQuestion,dlgTitle,'Change','Exit', 'Change'); %Change= default
        switch choiceLOG
            case 'Change'
                answerSess = inputdlg('Session','Please enter proper session',1);
                Log.Expnum = answerSess{1};
                Log.Logfile_name = [Log.Mouse, '_', Log.Date, '_B', Log.Expnum];
            case 'Exit'
                keyboard
        end
    end
    cd(Matlabpath)
   
    
    %% Read in Setup specific parameter file
    
    if strcmp(Log.Setup(1:3), 'Box')
        run Params_Boxes
    elseif strcmp(Log.Setup, 'WFsetup')
        run Params_WFsetup
    elseif strcmp(Log.Setup, 'Optosetup')
        run Params_Optosetup
    end
    
    
    %% open Cogent

    cgloadlib
    cgshut
    %Screen
    cgopen(Par.Screenx, Par.Screeny, 32,Par.Refresh , Par.ScreenID) 
    cogstd('sPriority','high')
    for i = 1:120
        cgflip(Par.grey)
    end
    %Sound
    cgsound('open',Par.Aud_nchannels,Par.Aud_nbits,Par.Aud_sampfrequency,-50,1) % -50db volume attenuation, sound device 0 (default sound device)
    
    %% initialize the DAS card in Opto and WF setup
    
    if strcmp(Log.Setup, 'WFsetup')
        dasinit(22);
        dasbit(Par.Camport, 0)      % Campera port 0
        dasbit(Par.Shutterport, 0)  % Shutter port 1
        dasbit(Par.Recport, 0)      % Recording port 2
        dasbit(Par.Stimbitport, 0)  % Stimbit port 3
        dasbit(Par.Optoport, 0)     % Opto port 4
    elseif strcmp(Log.Setup, 'Optosetup')
        dasinit(23);
        for i = 0:7
            dasbit(i, 0)
        end
    end

    %% start the Arduino connection
    
    % start the connection to the Lick Detection Arduino
    set(Par.sport,'InputBufferSize', 10240)
    if strcmp(get(Par.sport, 'status'), 'closed')
        fopen(Par.sport); 
    end
    set(Par.sport, 'baudrate', 250000);
    set(Par.sport, 'timeout', 0.1);
    sendtoard(Par.sport, 'ID');             % disable reward, just to be safe
    
    % start the connection to the Running Encoder Arduino if there is a running wheel
    try
        if strcmp(get(Par.running_port, 'status'), 'closed') 
            fopen(Par.running_port); 
        end
        set(Par.running_port, 'baudrate', 57600);
        set(Par.running_port, 'timeout', 0.1);
        fwrite(Par.running_port, 1, 'int16');   % Reset the encoder value to 0
        Par.RecordRunning = 1;
    catch
        Par.RecordRunning = 0;
    end

    %% make the GUI & initialize variables
    run makeGUI_active
    global stopaftertrial %#ok<TLEV>
    global StartSession %#ok<TLEV>
    stopaftertrial = 0;
    StartSession = 0;
    TrialMatrix = [];
    TestMatrix = [];
    Trial = 0;
    HitCounter = 0;
    MissCounter = 0;
    FACounter = 0;
    CRCounter = 0;

    
    %% Main Script
    while ~StartSession
        pause(0.1)
    end
    delete(Gui.StartButton)
    
    if strcmp(Log.Setup, 'WFsetup')
        dasbit(Par.Shutterport, 1)     % opens the shutter
        disp('Shutter open')
    end
    
    
    while ~stopaftertrial
        
        %% Initialize some variables
        
        Trial = Trial + 1;
        fprintf('Trial %d \n', Trial)
        LickVec = [];
        RunningVec = [];
        RunningTiming = [];
        BlinkVec = [];
        Reaction = [];
        ValveOpenTime = 0;
        
        % Initialization time timer (subtract from ITI):
        InitializeTimer = tic;
        
        %% Read in Parameters from the GUI
        
        Log.RewardDur(Trial) = str2double(get(Gui.RewardDur, 'string'));
        Log.Threshold(Trial) = str2double(get(Gui.Threshold, 'string'));
        Log.GoTrialProportion(Trial) = str2double(get(Gui.GoTrialProportion, 'string'));
        Log.Trial(Trial) = Trial;
        Log.TimeToLick(Trial) = str2double(get(Gui.TimeToLick, 'string'));
        Log.VisDuration(Trial) = str2double(get(Gui.VisDuration, 'string'));
        Log.GraceDuration(Trial) = str2double(get(Gui.GraceDuration, 'string'));
        Log.Passivedelay(Trial) = str2double(get(Gui.Passivedelay, 'string'));
        Log.TaskPhase(Trial) = str2double(get(Gui.TaskPhase, 'string'));
        
        % send Rewardtime, Threshold and Passvie Delay to Arduino
        fprintf(Par.sport, ['IL ' get(Gui.RewardDur, 'String')]);
        fprintf(Par.sport, ['IF ' get(Gui.Threshold, 'String')]);
        fprintf(Par.sport, ['IT ' num2str(Log.Passivedelay(Trial)*1000)]);
        

        %% Make a Trial Matrix with miniblocks if TrialMatrix is empty
        
        if isempty(TrialMatrix)
            MiniLength = 4;
            Miniblock = zeros(MiniLength,1);
            Miniblock(1:round(Log.GoTrialProportion(Trial)/(100/MiniLength)))= 1;
            TrialMatrix = Miniblock(randperm(MiniLength));
        end

        if isempty(TestMatrix) && Log.TaskPhase(Trial) >= 3
            if Log.TaskPhase(Trial) == 3
                TestStim = 1:4;
                TestStim = TestStim(randperm(length(TestStim)));
                for t = 1:length(TestStim)
                    Stims = [NaN(1,3) TestStim(t)]; % 75% Normal Trials, 25% Test Trials
                    Stims = Stims(randperm(length(Stims)));
                    TestMatrix = [TestMatrix Stims]; %#ok<AGROW>
                end
            elseif Log.TaskPhase(Trial) == 4
                TestStim = 5:6;
                TestStim = TestStim(randperm(length(TestStim)));
                for t = 1:length(TestStim)
                    Stims = [NaN(1,3) TestStim(t)]; % 75% Normal Trials, 25% Test Trials
                    Stims = Stims(randperm(length(Stims)));
                    TestMatrix = [TestMatrix Stims]; %#ok<AGROW>
                end
            end
        end

        
        %% Set the Currtrial
        
        if Log.TaskPhase(Trial) < 3
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
            Log.TestStim(Trial) = NaN;
            
        else                                                                % Testphase
            Log.TestStim(Trial) = TestMatrix(1);                            % There are 4 test stimuli (for now) which are:
            TestMatrix(1) = [];                                             
            if Log.TestStim(Trial) == 1 || Log.TestStim(Trial) == 2         % 1 Go      Figure grating, Background grey                  
                Log.Trialtype(Trial) = 1;                                   % 2 Go      Figure grey, Background grating    
            elseif Log.TestStim(Trial) == 3 || Log.TestStim(Trial) == 4     % 3 NoGo    Figure grating, Background grey
                Log.Trialtype(Trial) = 0;                                   % 4 NoGo    Figure grey, Background grating
            elseif Log.TestStim(Trial) == 5 || Log.TestStim(Trial) == 6     % 5 random reward Go Fig + NoGo Bg 
                Log.Trialtype(Trial) = randi([0 1], 1);                     % 6 random reward NoGo Fig + Go Bg
            else
                Log.Trialtype(Trial) = TrialMatrix(1);                      % NaN       is a normal trial, just leave Trialtype as it is
                TrialMatrix(1) = [];
            end
       
        end
        
        
            
        
        %% check for communication from the serial port

        RunningTimer = tic; %use this later to subtract difference to stimulus onset
        checkRunning
        checkforLicks      % only using 'right' port
        
        
        %% make the Visual Stimulus
        
            
        if Log.TaskPhase(Trial) == 1      % Black/White Figure and Black/White Background
            
            if Log.Trialtype(Trial) == 1
                Log.BgColor(Trial) = Par.blacklum;
                Log.FgColor(Trial) = Par.whitelum;
            else
                Log.BgColor(Trial) = Par.whitelum;
                Log.FgColor(Trial) = Par.blacklum;
                Log.Trialtype(Trial) = 1;
            end
            BGcogentGrating = makeUniformFullScreen(Log.BgColor(Trial),1,gammaconversion); % 1 with circle, 0 without
            FGcogentGrating = makeUniformFullScreen(Log.FgColor(Trial),0,gammaconversion); % 1 with circle, 0 without
            Log.FgPhase(Trial) = NaN;
            Log.BgPhase(Trial) = NaN;
            Log.BgOri(Trial) = NaN;
            Log.FgOri(Trial) = NaN;
            
            
        elseif Log.TaskPhase(Trial) == 2 || isnan(Log.TestStim(Trial))  % Go and NoGo Figure-Ground stimuli
            
            if Log.Trialtype(Trial) == 1
                Log.FgOri(Trial) = Par.GoFigOrient;
                Log.BgOri(Trial) = Par.GoBgOrient;
            else
                Log.FgOri(Trial) = Par.NoGoFigOrient;
                Log.BgOri(Trial) = Par.NoGoBgOrient;
            end
            
            Log.FgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
            Log.BgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
            BGcogentGrating = makeFullScreenGrating(Log.BgOri(Trial),Log.BgPhase(Trial),1,gammaconversion); % 1 with circle, 0 without
            FGcogentGrating = makeFullScreenGrating(Log.FgOri(Trial),Log.FgPhase(Trial),0,gammaconversion); % 1 with circle, 0 without
            Log.BgColor(Trial) = NaN;
            Log.FgColor(Trial) = NaN;
            Log.TestStim(Trial) = NaN;
            
        else     % Go or NoGo isolated or mixed
            
            switch Log.TestStim(Trial)
                case 1
                    % Figure with GO grating
                    Log.FgOri(Trial) = Par.GoFigOrient;
                    Log.FgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                    FGcogentGrating = makeFullScreenGrating(Log.FgOri(Trial),Log.FgPhase(Trial),0,gammaconversion); % 1 with circle, 0 without
                    % Grey Background
                    Log.BgColor(Trial) = Par.greylum;
                    BGcogentGrating = makeUniformFullScreen(Log.BgColor(Trial),1,gammaconversion); % 1 with circle, 0 without
                    Log.BgPhase(Trial) = NaN;
                    Log.BgOri(Trial) = NaN;
                    Log.FgColor(Trial) = NaN;
                    
                case 2
                    % Grey Figure
                    Log.FgColor(Trial) = Par.greylum;
                    FGcogentGrating = makeUniformFullScreen(Log.FgColor(Trial),0,gammaconversion); % 1 with circle, 0 without
                    % Background with GO grating
                    Log.BgOri(Trial) = Par.GoBgOrient;
                    Log.BgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                    BGcogentGrating = makeFullScreenGrating(Log.BgOri(Trial),Log.BgPhase(Trial),1,gammaconversion); % 1 with circle, 0 without
                    Log.FgPhase(Trial) = NaN;
                    Log.FgOri(Trial) = NaN;
                    Log.BgColor(Trial) = NaN;
                    
                case 3
                    % Figure with NOGO grating
                    Log.FgOri(Trial) = Par.NoGoFigOrient;
                    Log.FgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                    FGcogentGrating = makeFullScreenGrating(Log.FgOri(Trial),Log.FgPhase(Trial),0,gammaconversion); % 1 with circle, 0 without
                    % Grey Background
                    Log.BgColor(Trial) = Par.greylum;
                    BGcogentGrating = makeUniformFullScreen(Log.BgColor(Trial),1,gammaconversion); % 1 with circle, 0 without
                    Log.BgPhase(Trial) = NaN;
                    Log.BgOri(Trial) = NaN;
                    Log.FgColor(Trial) = NaN;
                    
                case 4
                    % Grey Figure
                    Log.FgColor(Trial) = Par.greylum;
                    FGcogentGrating = makeUniformFullScreen(Log.FgColor(Trial),0,gammaconversion); % 1 with circle, 0 without
                    % Background with NOGO grating
                    Log.BgOri(Trial) = Par.NoGoBgOrient;
                    Log.BgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                    BGcogentGrating = makeFullScreenGrating(Log.BgOri(Trial),Log.BgPhase(Trial),1,gammaconversion); % 1 with circle, 0 without
                    Log.FgPhase(Trial) = NaN;
                    Log.FgOri(Trial) = NaN;
                    Log.BgColor(Trial) = NaN;
                    
                case 5
                    % Figure with GO grating
                    Log.FgOri(Trial) = Par.GoFigOrient;
                    Log.FgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                    FGcogentGrating = makeFullScreenGrating(Log.FgOri(Trial),Log.FgPhase(Trial),0,gammaconversion); % 1 with circle, 0 without
                    % Background with NOGO grating
                    Log.BgOri(Trial) = Par.NoGoBgOrient;
                    Log.BgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                    BGcogentGrating = makeFullScreenGrating(Log.BgOri(Trial),Log.BgPhase(Trial),1,gammaconversion); % 1 with circle, 0 without
                    Log.BgColor(Trial) = NaN;
                    Log.FgColor(Trial) = NaN;
                    
                case 6
                    % Figure with NOGO grating
                    Log.FgOri(Trial) = Par.NoGoFigOrient;
                    Log.FgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                    FGcogentGrating = makeFullScreenGrating(Log.FgOri(Trial),Log.FgPhase(Trial),0,gammaconversion); % 1 with circle, 0 without
                    % Background with GO grating
                    Log.BgOri(Trial) = Par.GoBgOrient;
                    Log.BgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                    BGcogentGrating = makeFullScreenGrating(Log.BgOri(Trial),Log.BgPhase(Trial),1,gammaconversion); % 1 with circle, 0 without
                    Log.BgColor(Trial) = NaN;
                    Log.FgColor(Trial) = NaN;
                    
            end
            
        end
        
        % put into sprite 1
        cgmakesprite(1,Par.Screenx,Par.Screeny,Par.grey)
        cgsetsprite(1)
        cgloadarray(12,Par.Screenx,Par.Screeny,BGcogentGrating)
        cgtrncol(12,'r')
        cgloadarray(11,Par.Screenx,Par.Screeny,FGcogentGrating)
        cgdrawsprite(11,0,0)
        cgdrawsprite(12,0,0)
        cgsetsprite(0)

        
        %% set the Trialtype in the Gui 
        
        if Log.Trialtype(Trial) == 1
            set(Gui.Currtrial, 'String', 'Go')
            Log.Trialword{Trial} = 'Go';
        else
            set(Gui.Currtrial, 'String', 'No Go')
            Log.Trialword{Trial} = 'No Go';
        end
        

        %% Passive Rewards
        
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
        
        
        %% look at how long initialization took and subtract from ITI
        subtract_Timer = toc(InitializeTimer); clear InitializeTimer
        
        
        %% ITI and Cleanbaseline 
        
        Log.randITI(Trial) = Par.random_ITI * rand;
        Log.ITI(Trial) = Par.ITI;

        % pause for the fixed ITI minus the time that has passed during stimulus making
        fixedITITimer = tic;
        checkedOnce = 0;
        while toc(fixedITITimer) < (Log.ITI(Trial)-subtract_Timer) || ~checkedOnce
            checkforLicks
            checkRunning
            checkedOnce = 1;
        end
        clear fixedITITimer
        
        % Cleanbaseline
        CleanBaselineMin = str2double(get(Gui.CleanBaselineMin, 'string'));
        CleanBaselineMax = str2double(get(Gui.CleanBaselineMax, 'string'));
        Log.CleanBaseline(Trial) = CleanBaselineMin + rand(1) * (CleanBaselineMax - CleanBaselineMin);
        if Log.CleanBaseline(Trial) % Pause for Cleanbaselinetime until the mouse stops licking
            tempLickVec = LickVec;
            cleanBaseTimer = tic;
            while toc(cleanBaseTimer) < Log.CleanBaseline(Trial)            
                checkforLicks
                checkRunning
                if ~isequal(LickVec, tempLickVec)
                    cleanBaseTimer = tic;
                    tempLickVec = LickVec;
                end
            end
        end
        clear cleanBaseTimer
        
        
        % initialize camera if experiment is in the WF setup
        if strcmp(Log.Setup, 'WFsetup')
            dasbit(Par.Camport, 1) % initializes camera
        end
        
        % Random ITI minus once the CleanBaseline Time
        checkedOnce = 0;
        randITITimer = tic;
        while toc(randITITimer) <  (Log.randITI(Trial) - Log.CleanBaseline(Trial)) || ~checkedOnce 
            checkforLicks
            checkRunning
            checkedOnce = 1;
        end
        clear randITITimer
        
        % Start Baseline imaging if in WF setup
        if strcmp(Log.Setup, 'WFsetup')
            dasbit(Par.Recport, 1) % starts recording
            pause(Par.PreStimTime) % pauses baseline time
        end
        
        
        %% Display the Visual Go or NoGo Stimulus

        checkforLicks
        
        % Send Start signal to Arduino and start the Trial
        fprintf(Par.sport, 'IS');   % starts the trial
        RunningDiff = toc(RunningTimer);
        
        % Show the Visual Stimulus
        cgdrawsprite(1,0,0)
        VisStatus = 1;
        cgflip('V')
        cgflip(Par.grey)
        cgflip('V')
        
        % Stimulus is there
        if strcmp(Log.Setup, 'WFsetup')
            dasbit(Par.Stimbitport, 1)  % sends a stimbit that stimulus is present
        end
        StimOnset = tic;
        
        % Colour the GUI field in the appropriate colour
        if Log.Trialtype(Trial) == 1
            set(Gui.Currtrial,'Background',[0 1 0])
        else
            set(Gui.Currtrial,'Background',[1 1 0])
        end
        
        EnableGrace = 1;
        LickEnabled = 0;

        while toc(StimOnset) < max([Log.TimeToLick(Trial) Log.VisDuration(Trial)])

            checkforLicks
            checkRunning
            
            % Enable the Lick spout for this trial
            if toc(StimOnset) > Log.GraceDuration(Trial) && EnableGrace
                if Log.Trialtype(Trial) == 1    % Go Trial
                    fprintf(Par.sport, 'IE 1');
                else                            % No Go Trial
                    fprintf(Par.sport, 'IE 2');
                end
                EnableGrace = 0;
                LickEnabled = 1;
            end

            % check if should give a passive
            if Log.Passives(Trial) && toc(StimOnset) > Log.Passivedelay(Trial) && ~gavepassive
                sendtoard(Par.sport, 'IP')          % give passive
                gavepassive = 1;
                cprintf([0.2 0.2 0.2], 'passive trial \n')
            end
            
            % check if Time to Lick is over and should disable Lickspout
            if toc(StimOnset) > Log.TimeToLick(Trial) && LickEnabled == 1
                sendtoard(Par.sport, 'ID');
                LickEnabled = 0;
            end

            
            % check if should turn off visual stimulus
            if toc(StimOnset) > Log.VisDuration(Trial) && VisStatus == 1
                cgflip(Par.grey)
                VisStatus = 0;
                if strcmp(Log.Setup, 'WFsetup')
                    dasbit(Par.Stimbitport, 0)  % sets stimbit to 0 to mark that stimulus is gone
                end
            end

        end
        
        set(Gui.Currtrial,'Background',[.95 .95 .95])
        
        % end of trial
        Log.Stimdur(Trial) = toc(StimOnset);
        if strcmp(Log.Setup, 'WFsetup')
            dasbit(Par.Stimbitport, 0)      % sets stimbit to 0 to mark that stimulus is gone
        end
        
        % Check that everything is off
        if VisStatus == 1 || LickEnabled == 1
            cgflip(Par.grey)                % flips up a grey screen         
            sendtoard(Par.sport, 'ID');     % disable the lick reward
        end
        
        % Stop recording and turn camera off if this is in the WF setup
        if strcmp(Log.Setup, 'WFsetup')
            pause(Par.PostStimTime)
            dasbit(Par.Recport, 0)  % stops recording
            dasbit(Par.Camport, 0)  % stops camera
        end

        checkforLicks
        checkRunning

        % get the trialtime from the arduino
        fprintf(Par.sport, 'IA');
        
        I = '';
        to = tic;
        while ~strcmp(I, 'R') && toc(to) < 0.2
            I = fscanf(Par.sport, '%s'); % break test
            if strcmp(I, 'R')
                break
            end
        end
        trialtime = str2num(fscanf(Par.sport, '%s')); %#ok<ST2NM>

        % save the Lick Data in the Log file
        try
            Log.LickVec{Trial} = LickVec - trialtime;
        catch
            Log.LickVec{Trial} = NaN;
            disp('no trialtime?')
        end
        
        % save the Running Data in the Log file
        Log.RunningVec{Trial} = RunningVec;
        Log.RunningTiming{Trial} = RunningTiming - RunningDiff;
        
        
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
            FATimer = tic;
            while toc(FATimer) < Par.FA_Timeout
                checkforLicks
                checkRunning
            end
            clear FATimer
        else
            if Log.Trialtype(Trial) == 1
                Log.Reaction{Trial} = 'Miss';
                Log.RT(Trial) = NaN;
                Log.Reactionidx(Trial) = 0;
                MissCounter = MissCounter + 1;
                set(Gui.Misstext, 'string', num2str(MissCounter))
                cprintf([1 0.5 0.3], 'Miss \n')
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
        Par.d_prime_windowsize = 20;
        if Trial <= Par.d_prime_windowsize
            Log.dprime(Trial) = Calcdprime(Log.Reactionidx);
            Log.criterion(Trial) = CalcCriterion(Log.Reactionidx);
        else
            Log.dprime(Trial) = Calcdprime(Log.Reactionidx(Trial-Par.d_prime_windowsize:Trial));
            Log.criterion(Trial) = CalcCriterion(Log.Reactionidx(Trial-Par.d_prime_windowsize:Trial));
        end
        
        plot(perfplot, Log.dprime)
        hold(perfplot, 'on')
        plot(perfplot, 1:Trial,zeros(Trial,1),'r')
        plot(perfplot, 1:Trial,repmat(1.5,Trial,1),'g')
        title(perfplot, 'Performance')
        ylabel(perfplot, 'd prime')
        xlabel(perfplot, 'Trials')
        axis(perfplot, [1 inf min([min(Log.dprime) -0.5]) max([max(Log.dprime) 2])])
        box(perfplot, 'off')
        drawnow
        hold(perfplot, 'off')
        
        %% Plot the running 
        
        plotRunning
        
        %% save
        
        save([Par.Save_Location '\' Log.Logfile_name] , 'Log', 'Par', 'RunningTimecourseAVG')
        % save in imaging folder in the format Enny uses if in the WF setup
        if strcmp(Log.Setup, 'WFsetup')
            save([Par.Save_Location2 '\' Log.Mouse Log.Expnum] , 'Log', 'Par', 'RunningTimecourseAVG')
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
    
    % Session has finished, turn the Log file into a Table and save it with the rest
    
    Log_table = table;
    Log_fieldnames = fieldnames(Log);
    for f = 1:length(Log_fieldnames)
        FieldData = getfield(Log, char(Log_fieldnames(f))); %#ok<GFLD>
        if ischar(FieldData)
            FieldData = repmat(FieldData,Trial,1);
        else
            FieldData = FieldData';
        end
        eval([ 'Log_table.' char(Log_fieldnames(f)), '=', 'FieldData', ';'])
    end
    
    %% save

    save([Par.Save_Location '\' Log.Logfile_name] , 'Log', 'Par', 'Log_table', 'RunningTimecourseAVG')
    % save in imaging folder in the format Enny uses if in the WF setup
    if strcmp(Log.Setup, 'WFsetup')
        save([Par.Save_Location2 '\' Log.Mouse Log.Expnum] , 'Log', 'Par', 'Log_table', 'RunningTimecourseAVG')
    end
    
catch ME
    
    disp(ME)
    
end



cogstd('sPriority','normal')
cgshut

if strcmp(get(Par.sport, 'status'), 'open')
    fclose(Par.sport);
end
if Par.RecordRunning
    fclose(Par.running_port);
end



%% Arduino commands

% start Arduino
% Par.sport = serial('com3');
% set(Par.sport,'InputBufferSize', 10240)
% if strcmp(get(Par.sport, 'status'), 'closed')
%     fopen(Par.sport)
% end
% set(Par.sport, 'baudrate', 250000);
% set(Par.sport, 'timeout', 0.1);
% sendtoard(Par.sport, 'ID');



% Reward 1 is pin 10 digitalWrite(10, LOW) closes it and digitalWrite(10,HIGH) opens it
% Reward 2 is pin 11 same as above

%fprintf(Par.sport, 'IF');   % returns 'D' and sets the treshold to the value you send
%fprintf(Par.sport, 'IM');   % returns 'D' and sets easymode to the value you send
%fprintf(Par.sport, 'IL');   % returns 'D' and sets Rewardtime1 to the value you send, is the right port
%fprintf(Par.sport, 'IR');   % returns 'D' and sets Rewardtime2 to the value you send, is the left port
%fprintf(Par.sport, 'IO');   % Motor
%fprintf(Par.sport, 'IT');   % returns 'D' and sets Timeout to the value you send? what is timeout, I think it's the Graceperiod or the passive delay

%fprintf(Par.sport, 'IS');   % starts the trial, Trialtime, passive and wentthrough, nothing gets returned
%fprintf(Par.sport, 'IE 1'): % returns 'D' and sets Enable to 1 (right)
%fprintf(Par.sport, 'IE 2'); % returns 'D' and sets Enable to 2 (left)
%fprintf(Par.sport, 'IA');   % returns 'R' and returns the Trialtime, so basically the RT
%fprintf(Par.sport, 'IC');   % returns 'D' followed by the values of the two thresholds (first 1 then 2)
%fprintf(Par.sport, 'IP');   % returns 'D' and gives a passive if the time is greater than timeout
%fprintf(Par.sport, 'ID');   % returns 'D', sets Enable to 0 and closes both valves

% if Par.sport.BytesAvailable
%     while ~strcmp(I, 'O') && Par.sport.BytesAvailable
%         I = fscanf(Par.sport, '%s');
%         if strcmp(I, 'O')
%             break
%         end
%     end
% end
%