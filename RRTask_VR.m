%%
clear all %#ok<CLALL>
clc

try
    %% Structure of this task:
    % Mouse is head fixed and runs on a treadmill
    % to get to the next trial the mouse has to run a certain distance on the treadmill
    % On Go Trials the mouse is presented with a figure ground stimulus with certain orientations for figure and ground (needs to be set for
    % each mouse in MouseParams before start of training. If the mouse licks it gets a reward
    % On NoGo Trials a figure-ground stimulus with different orientation(s) appears that is not rewarded, if the mice lick on No-Go trials a white
    % screen will appear and only disappears after a certain running distance
    
    % need Arduino script: GoNoGoLick (!!!)
    correctArduino = questdlg('Did you upload the Arduino Script called GoNoGoLick?','Attention','Yes','No', 'Yes');
    if strcmp(correctArduino, 'No')
        disp('upload correct Arduino Script and then press any key on keyboard to continue')
        pause
    end
    
    addpath(genpath(fullfile(pwd,'Dependencies')))
    addpath(genpath(fullfile(pwd,'Analysis')))
    
    addpath('Dependencies')
    global Par Log %#ok<TLEV>
    
    %% Experiment Parameters
    
    prompt = {'Mouse Name', 'Exp Nr', 'Date'};
    def = {'Name', '1', datestr(datenum(date), 'yyyymmdd')};
    answer = inputdlg(prompt,'Please enter parameters',1,def);
    
    Log.Task = 'RRTask';
    Log.TaskCondition = 'VR';
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
    cgopen(Par.Screenx, Par.Screeny, 32,Par.Refresh , Par.ScreenID) 
    cogstd('sPriority','high')
    for i = 1:120
        cgflip(Par.grey)
    end
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
    
    % start the connection to the Running Encoder Arduino
    if strcmp(get(Par.running_port, 'status'), 'closed')
        fopen(Par.running_port);
    end
    set(Par.running_port, 'baudrate', 57600);
    set(Par.running_port, 'timeout', 0.1);
    fwrite(Par.running_port, 1, 'int16');   % Reset the encoder value to 0
    Par.RecordRunning = 1;
   
    
    %% make sprites of VR and all visual stimuli
    
    run makeVisStimsprites
    run makeVRsprites
    
    
    %% make the GUI & initialize variables
    run makeGUI_VR
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

        
        %% initialize camera if experiment is in the WF setup
        
        if strcmp(Log.Setup, 'WFsetup')
            dasbit(Par.Camport, 1) % initializes camera
        end
        
        
        %% Read in Parameters from the GUI
                
        Log.Trial(Trial) = Trial;
        Log.TaskPhase(Trial) = str2double(get(Gui.TaskPhase, 'string'));
        Log.RewardDur(Trial) = str2double(get(Gui.RewardDur, 'string'));
        Log.Threshold(Trial) = str2double(get(Gui.Threshold, 'string'));
        Log.GoTrialProportion(Trial) = str2double(get(Gui.GoTrialProportion, 'string'));
        Log.PassPerc(Trial) = str2double(get(Gui.PassPerc, 'string'));
        Log.Passivedelay(Trial) = str2double(get(Gui.Passivedelay, 'string'));
        Log.VRDist(Trial) = str2double(get(Gui.VRDist, 'string'));
        Log.VisStimDist(Trial) = str2double(get(Gui.VisStimDist, 'string'));
        Log.FADist(Trial) = str2double(get(Gui.FADist, 'string'));
        Log.ConversionFactor(Trial) = str2double(get(Gui.ConversionFactor, 'string'));
        
        
        %% Write Parameters to Arduino
        
        fprintf(Par.sport, ['IR ' get(Gui.RewardDur, 'String')]);
        fprintf(Par.sport, ['IF ' get(Gui.Threshold, 'String')]);        

        %% Make a Trial Matrix with miniblocks if TrialMatrix is empty
        
        if isempty(TrialMatrix)
            MiniLength = 4;
            Miniblock = zeros(MiniLength,1);
            Miniblock(1:round(Log.GoTrialProportion(Trial)/(100/MiniLength)))= 1;
            TrialMatrix = Miniblock(randperm(MiniLength));
        end

        if isempty(TestMatrix)
            TestMatrix = 1:4;
            TestMatrix = TestMatrix(randperm(length(TestMatrix)));
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
            
        else 
            Log.TestStim(Trial) = TestMatrix(1);
            TestMatrix(1) = [];
        end
        

        
        %% pick the correct sprites for the visual stimulus
        
        switch Log.TaskPhase(Trial)
            
            case 1      % Black/White Figure and Black/White Background
                if Log.Trialtype(Trial) == 1
                    Log.Fgsprite(Trial) = 3; % White Figure
                    Log.Bgsprite(Trial) = 2; % Black Background
                else
                    Log.Fgsprite(Trial) = 1; % Black Figure
                    Log.Bgsprite(Trial) = 4; % White Background
                    Log.Trialtype(Trial) = 1;
                end
                Log.TestStim(Trial) = NaN;

            case 2    % Go and NoGo Figure-Ground stimuli
                if Log.Trialtype(Trial) == 1
                    Log.Fgsprite(Trial) = 6+randi(4,1);      % GoFigOri in 1 of 4 Phases (7-10)
                    Log.Bgsprite(Trial) = 10+randi(4,1);     % GoBgOri in 1 of 4 Phases (11-14)
                else
                    Log.Fgsprite(Trial) = 14+randi(4,1);     % NoGoFigOri in 1 of 4 Phases (15-18)
                    Log.Bgsprite(Trial) = 19+randi(4,1);     % NoGoBgOri in 1 of 4 Phases (19-22)
                end
                Log.TestStim(Trial) = NaN;

            case 3    % Test Stimuli
                switch Log.TestStim(Trial)
                    case 1
                        Log.Fgsprite(Trial) = 6+randi(4,1);      % GoFigOri in 1 of 4 Phases (7-10)
                        Log.Bgsprite(Trial) = 6;                 % Grey background
                        Log.Trialtype(Trial) = 1;
                    case 2
                        Log.Fgsprite(Trial) = 5;                 % Grey Figure
                        Log.Bgsprite(Trial) = 10+randi(4,1);     % GoBgOri in 1 of 4 Phases (11-14)
                        Log.Trialtype(Trial) = 1;
                    case 3
                        Log.Fgsprite(Trial) = 14+randi(4,1);     % NoGoFigOri in 1 of 4 Phases (15-18)
                        Log.Bgsprite(Trial) = 6;                 % Grey background
                        Log.Trialtype(Trial) = 0;
                    case 4
                        Log.Fgsprite(Trial) = 5;                 % Grey Figure
                        Log.Bgsprite(Trial) = 19+randi(4,1);     % NoGoBgOri in 1 of 4 Phases (19-22)
                        Log.Trialtype(Trial) = 0;
                end                           
        end
        
        if Log.Trialtype(Trial) == 1
            set(Gui.Currtrial, 'String', 'Go')
            Log.Trialword{Trial} = 'Go';
        else
            set(Gui.Currtrial, 'String', 'No Go')
            Log.Trialword{Trial} = 'No Go';
        end

        %% Passive Rewards
        if rand < Log.PassPerc(Trial)/100
            Log.Passives(Trial) = 1;
        else
            Log.Passives(Trial) = 0;
        end
        
        if Log.Passives(Trial) == 1 && Log.Trialtype(Trial) == 1
            gavepassive = 0;
        else
            gavepassive = 1;
        end
        
        
        %% Prep over, trial starts now
        
        % Flush any remaining Licks
        if Par.sport.BytesAvailable
            flushinput(Par.sport); % delete everything that was in the buffer
        end
        RunningTimer = tic; % use this later to subtract difference to stimulus onset
        
        
        %% Display the treadmill until mouse has run appropriate distance
        
        TotalSpriteCounter = 1;
        CurrSprite = SpriteOffset + 1;
        CurrDistance = 0;
        
        while TotalSpriteCounter <= Log.VRDist(Trial)
            
            % at each refresh of the Screen read out the speed of the mouse
            % and determine the distance it ran in this time
            cgflip('V')

            % Check the running speed
            checkRunning
            CurrDistance = CurrDistance + Speed.*1/Par.Refresh;
            
            % Check if should move on to next Sprite
            if CurrDistance > Par.DistanceThres
                TotalSpriteCounter = TotalSpriteCounter + 1;
                CurrSprite = CurrSprite + 1;
                if CurrSprite == SpriteOffset + StepSize
                    CurrSprite = SpriteOffset + 1;
                end
                cgdrawsprite(CurrSprite,0,0)
                cgflip(Par.grey)
                CurrDistance = 0;
            end
            
            % Check the licks
            checkLicks
            
        end

        %% Start Baseline imaging if in WF setup
        
        if strcmp(Log.Setup, 'WFsetup')
            dasbit(Par.Recport, 1) % starts recording
            WFtimer = tic;
            while toc(WFtimer) < Par.PreStimTime
                checkLicks
                checkRunning
                pause(0.002)
            end
            clear WFtimer
        end
        
        
        %% Display the Visual Go or NoGo Stimulus

        % Send Start signal to Arduino and start the Trial
        fprintf(Par.sport, 'IS');   % starts the trial
        RunningDiff = toc(RunningTimer);
        
        % Show the Visual Stimulus   
        cgdrawsprite(Log.Fgsprite(Trial),0,0)
        cgdrawsprite(Log.Bgsprite(Trial),0,0)
        cgflip(Par.grey)
        
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
        
        Enable = 1;
        LickEnabled = 0;
        TotalSpriteCounter = 1;
        CurrDistance = 0;
        
        % Mouse runs through Stimulus corridor 
        while TotalSpriteCounter <= Log.VisStimDist(Trial) && ~strcmp(Reaction, 'F')
            
            % at each refresh of the Screen read out the speed of the mouse
            % and determine the distance it ran in this time
            cgflip('V')
            
            % Check the running speed
            checkRunning
            CurrDistance = CurrDistance + Speed.*1/Par.Refresh;
            
            % Check if crossed distance Threshold to next sprite
            if CurrDistance > Par.DistanceThres
                TotalSpriteCounter = TotalSpriteCounter + 1;
                CurrDistance = 0;
            end
            
            % Check the Licks/Response
            checkLicks
            
            % Enable the Lick Spout (once)
            if toc(StimOnset) > Log.GraceDuration && Enable
                if Log.Trialtype(Trial) == 1    % Go Trial
                    fprintf(Par.sport, 'IE 1');
                else                            % No Go Trial
                    fprintf(Par.sport, 'IE 2');
                end
                Enable = 0;
                LickEnabled = 1;
            end
            
            % Give a passive if wanted (once)
            if Log.Passives(Trial) && toc(StimOnset) > Log.Passivedelay(Trial) && ~gavepassive
                fprintf(Par.sport, 'IP');          % give passive
                gavepassive = 1;
                Enable = 0;
                LickEnabled = 1;
                cprintf([0.2 0.2 0.2], 'passive trial \n')
            end
            
        end
        
        % End of Trial
        cgflip(Par.grey)
        Log.Stimdur(Trial) = toc(StimOnset);
        sendtoard(Par.sport, 'ID');     % disable the lick reward
        if strcmp(Log.Setup, 'WFsetup')
            dasbit(Par.Stimbitport, 0)  % sets stimbit to 0 to mark that stimulus is gone
        end
        set(Gui.Currtrial,'Background',[.95 .95 .95])

        % Stop recording and turn camera off if this is in the WF setup
        if strcmp(Log.Setup, 'WFsetup')
            while toc(WFtimer) < Par.PostStimTime
                checkLicks
                checkRunning
                pause(0.002)
            end
            dasbit(Par.Recport, 0)  % stops recording
            dasbit(Par.Camport, 0)  % stops camera
        end
        
        
        % If the Mouse made a False Alarm it has to run through white zone
        if strcmp(Reaction, 'F') 
            TotalSpriteCounter = 1;
            CurrDistance = 0;
            cgflip(Par.white)
            while TotalSpriteCounter <= Log.FADist(Trial)
                cgflip('V')
                checkRunning
                CurrDistance = CurrDistance + Speed.*1/Par.Refresh;
                if CurrDistance > Par.DistanceThres
                    TotalSpriteCounter = TotalSpriteCounter + 1;
                    CurrDistance = 0;
                end
                checkLicks
            end
            cgflip(Par.grey)
        end

        % save the Lick Data in the Log file
        Log.LickVec{Trial} = LickVec - RunningDiff;
        
        % save the Running Data in the Log file
        Log.RunningVec{Trial} = RunningVec;
        Log.RunningTiming{Trial} = RunningTiming - RunningDiff;
        
        
        %% Process response
        
        if strcmp(Reaction, 'H')
            Log.Reaction{Trial} = 'Hit';
            Log.Reactionidx(Trial) = 1;
            HitCounter = HitCounter + 1;
            set(Gui.Hittext, 'string', num2str(HitCounter));
            Log.RT(Trial) = str2double(RT);
            cprintf([0 1 0], 'Hit \n')
        elseif strcmp(Reaction, 'F')
            Log.Reaction{Trial} = 'False Alarm';
            FACounter = FACounter + 1;
            Log.Reactionidx(Trial) = -1;
            set(Gui.FAtext, 'string', num2str(FACounter))
            Log.RT(Trial) = str2double(RT);
            cprintf([1 0 0], 'False Alarm \n')
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
if strcmp(get(Par.running_port, 'status'), 'open')
    fclose(Par.running_port);
end

