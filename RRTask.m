%%
clear all %#ok<CLALL>
clc
try
    %% Structure of this task:
    % Mouse is head fixed and sits in a tube setup or runs (running is not relevant for task) on a treadmill
    % On Go Trials the mouse is presented with an auditory stimulus (frequency of the tone can be varied) and/or an
    % optogenetic stimulus The start of a trial is marked by a full screen checkerboard stimulus combined with
    % optogenetic stimulation on go trials and nothing appears on no go trials
    % On Go Trials mouse has to lick to get a reward,
    % On No Go Trials there is no reward, but a 5s timeout if the mouse licks
           
    addpath(genpath('Dependencies'))
    addpath(genpath('Analysis'))
    
    %% Experiment Parameters
    prompt = {'Mouse Name', 'Exp Nr', 'Date'};
    def = {'Name', '1', datestr(datenum(date), 'yyyymmdd')};
    answer = inputdlg(prompt,'Please enter parameters',1,def);
    
    Log.Task = 'RRTask';
    Log.Mouse = answer{1};
    run checkMouse
    run MouseParams
    
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
    
    if strcmp(Log.Setup, 'WFsetup') || strcmp(Log.Setup, 'Optosetup')
        run SetOptoOptions
    else
        Log.Laserpower = 'NaN';
        Log.LaserColor = 'Red';
        Par.MultiOpto = 0;
        Par.ModulatedArduino = 0;
    end
    
    
    %% Saving location of Logfile 
    
    % Saving Location
    Matlabpath = pwd;
    if strcmp(Log.Setup(1:3), 'Box')
        pathend = strfind(Matlabpath, 'MouseTraining')-1;
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
    
    % start the connection to the Blinking Mask Arduino if there is a blink mask
    try
        if strcmp(get(Par.mask_port, 'status'), 'closed') 
            fopen(Par.mask_port);
        end
        set(Par.mask_port, 'baudrate', 57600);
        set(Par.mask_port, 'timeout', 0.1);
        if Par.mask_port.BytesAvailable
            flushinput(Par.mask_port); % delete everything that was in the buffer
        end
        Par.RecordBlinkMask = 1;
    catch
        Par.RecordBlinkMask = 0;
    end
    
    
    % start the connection to the Laser Modulation Arduino if you're using MultiOpto
    if Par.ModulatedArduino == 1
        set(Par.Optoserial,'InputBufferSize', 10240)
        if strcmp(get(Par.Optoserial, 'status'), 'closed')
            fopen(Par.Optoserial);
        end
        set(Par.Optoserial, 'baudrate', 250000);
        set(Par.Optoserial, 'timeout', 0.1);
    end
    
    
    
    

    %% make the GUI & initialize variables
    run makeGUI_active
    global stopaftertrial %#ok<TLEV>
    global StartSession %#ok<TLEV>
    stopaftertrial = 0;
    StartSession = 0;
    TrialMatrix = [];
    Trial = 0;
    HitCounter = 0;
    MissCounter = 0;
    FACounter = 0;
    CRCounter = 0;
    OptoMatrix = [];
    
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
        
        
        %% Read in Parameters from the GUI
        
        Log.RewardDur(Trial) = str2double(get(Gui.RewardDur, 'string'));
        Log.Threshold(Trial) = str2double(get(Gui.Threshold, 'string'));
        Log.GoTrialProportion(Trial) = str2double(get(Gui.GoTrialProportion, 'string'));
        Log.OptoStim(Trial) = get(Gui.OptoStim, 'value');
        Log.Trial(Trial) = Trial;
        Log.TimeToLick(Trial) = str2double(get(Gui.TimeToLick, 'string'));
        Log.Passivedelay(Trial) = str2double(get(Gui.Passivedelay, 'string'));
        
        
        % send Rewardtime, Threshold and Passvie Delay to Arduino
        sendtoard(Par.sport, ['IL ' get(Gui.RewardDur, 'String')])
        sendtoard(Par.sport, ['IF ' get(Gui.Threshold, 'String')])
        sendtoard(Par.sport, ['IT ' num2str(Log.Passivedelay(Trial)*1000)])
        

        %% Make a Trial Matrix with miniblocks if TrialMatrix is empty
        
        if isempty(TrialMatrix)
            MiniLength = 4;
            Miniblock = zeros(MiniLength,1);
            Miniblock(1:round(Log.GoTrialProportion(Trial)/(100/MiniLength)))= 1;
            TrialMatrix = Miniblock(randperm(MiniLength));
        end
        
        if isempty(OptoMatrix) && Par.MultiOpto == 1
            OptoMatrix = 2:6;
            OptoMatrix = OptoMatrix(randperm(length(OptoMatrix)));
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
            Log.Trialword{Trial} = 'Go';
            Log.FgOri(Trial) = Par.GoFigOrient;
            Log.BgOri(Trial) = Par.GoBgOrient;          
        else
            set(Gui.Currtrial, 'String', 'No Go')
            Log.Trialword{Trial} = 'No Go';
            Log.FgOri(Trial) = Par.NoGoFigOrient;
            Log.BgOri(Trial) = Par.NoGoBgOrient;
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
        
        
        %% check for communication from the serial port
        
        % Sync the Mask to the Trial onset
        if Par.RecordBlinkMask
            fprintf(Par.mask_port, 'T');     % the beginning of a trial is marked by sending a 'T'
            if Par.mask_port.BytesAvailable
                flushinput(Par.mask_port);   % delete everything that was in the buffer
            end
        end
        RunningTimer = tic; %use this later to subtract difference to stimulus onset
        checkRunning
        checkforLicks      % only using 'right' port
        
        
        %% make the Visual Stimulus
        
        Log.Contrast(Trial) = str2double(get(Gui.Contrast, 'string'))/100;
        Log.FgPhase(Trial) = 
        Log.BgPhase(Trial) = 
        
        BGcogentGrating = makeFullScreenGrating(Log.BgOri(Trial),Phase,1); % 1 with circle, 0 without
        FGcogentGrating = makeFullScreenGrating(Log.FgOri(Trial),Phase,0); % 1 with circle, 0 without

        cgloadarray(1,Par.Screenx,Par.Screeny,cogentGrating)
        cgdrawsprite(1,0,0)
        cgsetsprite(0)
        cgflip(Par.grey)
   
            cgtrncol(2,'r')
            cgsetsprite(0)
           
        
        
        
        
        
        
        
        
        
        
        
        
        if Log.Contrast(Trial)
            Log.ApertureL(Trial) = get(Gui.ApertureL, 'value');
            Log.ApertureR(Trial) = get(Gui.ApertureR, 'value');
        else
            Log.ApertureL(Trial) = NaN;
            Log.ApertureR(Trial) = NaN;
        end
        
        if Log.Contrast(Trial)
            % Full Screen Checkerboard Stimulus
            cgmakesprite(1,Par.Screenx,Par.Screeny,Par.grey)
            cgsetsprite(1)
            whitelum = Par.greylum + Log.Contrast(Trial) * Par.lumrange/2;
            blacklum = Par.greylum - Log.Contrast(Trial) * Par.lumrange/2;
            white = eval([gammaconversion '(whitelum,''lum2rgb'')']);
            black = eval([gammaconversion '(blacklum,''lum2rgb'')']);
            xpix = -Par.Screenx/2 - Par.CheckSz : Par.CheckSz : Par.Screenx/2 + Par.CheckSz;
            ypix = -Par.Screeny/2  - Par.CheckSz : Par.CheckSz : Par.Screeny/2 + Par.CheckSz;
            alternate = 1;
            for x = 1:length(xpix)
                for y = 1:length(ypix)
                    alternate = 1 - alternate;
                    if alternate == 1
                        cgrect(xpix(x), ypix(y), Par.CheckSz, Par.CheckSz, [white, white, white])
                    else
                        cgrect(xpix(x), ypix(y), Par.CheckSz, Par.CheckSz, [black, black, black])
                    end
                end
            end
            cgsetsprite(0)
            
            
            % Create an Aperture
            cgmakesprite(2,Par.Screenx,Par.Screeny,Par.grey)
            cgsetsprite(2)
            cgpencol(1,0,0)
            if Log.ApertureL(Trial) || Log.ApertureR(Trial)
                if Log.ApertureL(Trial)
                    cgellipse(-Par.ApertureX,Par.ApertureY,Par.ApertureSz,Par.ApertureSz,'f');
                end
                if Log.ApertureR(Trial)
                    cgellipse(Par.ApertureX,Par.ApertureY,Par.ApertureSz,Par.ApertureSz,'f');
                end
            else
                cgrect(0,0,Par.Screenx, Par.Screeny)
            end
            cgtrncol(2,'r')
            cgsetsprite(0)
            
        end
        
        
        %% make the Auditory Stimulus
        
        Log.AudFreq(Trial) = str2double(get(Gui.AudFreq, 'string'));
        Log.AudIntensity(Trial) = str2double(get(Gui.AudIntensity, 'string'))/100;
        
        if Log.AudIntensity(Trial)
            soundwav = sin((1:Par.AudDuration*Par.Aud_sampfrequency)*2*pi*Log.AudFreq(Trial)/Par.Aud_sampfrequency);
            cgsound('MatrixSND',1,soundwav,Par.Aud_sampfrequency)
            cgsound('vol',1,Log.AudIntensity(Trial))
        end
        
        
        
        %% Set the TrialCond 
        
        if Log.Trialtype(Trial) == 1 % Go Stimulus
            if Log.OptoStim(Trial) == 1 % Opto
                if Par.MultiOpto == 1 % Multiple Opto Laser Powers
                    % pick a Laser Power for this Trial
                    Log.TrialCond(Trial) = OptoMatrix(1);
                    OptoMatrix(1) = [];
                    switch Log.TrialCond(Trial)
                        case 1 % No Go
                        case 2 % 0.1mW
                            Log.OptoValueArduino(Trial) = 77;
                            Log.OptoValue(Trial) = 0.1;
                        case 3 % 0.5mW
                            Log.OptoValueArduino(Trial) = 142;
                            Log.OptoValue(Trial) = 0.5;
                        case 4 % 1.0mW
                            Log.OptoValueArduino(Trial) = 165;
                            Log.OptoValue(Trial) = 1;
                        case 5 % 5.0mW
                            Log.OptoValueArduino(Trial) = 184;
                            Log.OptoValue(Trial) = 5;
                        case 6 % 10.0mW
                            Log.OptoValueArduino(Trial) = 200;
                            Log.OptoValue(Trial) = 10;
                    end
                elseif Par.MultiOpto == 0 && Par.ModulatedArduino == 1 % Modulated Arduino but only one Power
                    Log.TrialCond(Trial) = Par.OptoTrialCond;
                    Log.OptoValueArduino(Trial) = Par.OptoValueArduino;
                    Log.OptoValue(Trial) = Par.Laserpower;
                elseif Par.MultiOpto == 0 && Par.ModulatedArduino == 0  % Normal Arduino with one Power
                    Log.TrialCond(Trial) = Par.OptoTrialCond;
                    Log.OptoValueArduino(Trial) = NaN;
                    Log.OptoValue(Trial) = Par.Laserpower;
                end
                % Additionally Visual and/or Auditory
                if Log.Contrast(Trial) > 0 && Log.AudIntensity(Trial) == 0 % Opto Plus Visual
                    Log.TrialCond(Trial) = Log.TrialCond(Trial)+10;
                elseif Log.Contrast(Trial) == 0 && Log.AudIntensity(Trial) > 0 % Opto Plus Auditory
                    Log.TrialCond(Trial) = Log.TrialCond(Trial)+20;
                elseif Log.Contrast(Trial) > 0 && Log.AudIntensity(Trial) > 0 % Opto Plus Visual Plus Auditory
                    Log.TrialCond(Trial) = Log.TrialCond(Trial)+30;
                end
            elseif Log.Contrast(Trial) > 0 && Log.AudIntensity(Trial) == 0 % Visual Only
                Log.TrialCond(Trial) = 10;
                Log.OptoValueArduino(Trial) = NaN;
                Log.OptoValue(Trial) = NaN;
            elseif Log.Contrast(Trial) == 0 && Log.AudIntensity(Trial) > 0 % Auditory Only
                Log.TrialCond(Trial) = 20;
                Log.OptoValueArduino(Trial) = NaN;
                Log.OptoValue(Trial) = NaN;
            elseif Log.Contrast(Trial) > 0 && Log.AudIntensity(Trial) > 0 % Visual Plus Auditory
                Log.TrialCond(Trial) = 30;
                Log.OptoValueArduino(Trial) = NaN;
                Log.OptoValue(Trial) = NaN;
            end
        else % No Go Stimulus
            Log.TrialCond(Trial) = 1;
            Log.OptoValueArduino(Trial) = NaN;
            Log.OptoValue(Trial) = NaN;
        end
        
        %% If using modulated Arduino set the Laser Power to the correct Power for this trial
        
        if Par.ModulatedArduino == 1 && Log.Trialtype(Trial) == 1
            
            % change the setting to new power
            message = ['C' num2str(Log.OptoValueArduino(Trial))];
            fprintf(Par.Optoserial, message);
            pause(0.1)
            if Par.Optoserial.Bytesavailable
                resp = fscanf(Par.Optoserial, '%s');
            end
            
            % ask Laserpower Arduino which value it is set to
            message = 'P';
            fprintf(Par.Optoserial, 'P');             % ask for current power
            pause(0.1)
            if Par.Optoserial.BytesAvailable
                Log.OptoValueReceived(Trial) = str2double(fscanf(Par.Optoserial, '%s'));
            end
        else
            Log.OptoValueReceived(Trial) = NaN;
        end
        
        %% ITI and Cleanbaseline (fixedITI is at end of trial!)
        
        Log.randITI(Trial) = Par.random_ITI * rand;
        Log.ITI(Trial) = Par.ITI;
        % read out min and max Cleanbaseline
        CleanBaselineMin = str2double(get(Gui.CleanBaselineMin, 'string'));
        CleanBaselineMax = str2double(get(Gui.CleanBaselineMax, 'string'));
        Log.CleanBaseline(Trial) = CleanBaselineMin + rand(1) * (CleanBaselineMax - CleanBaselineMin);
        
        % first initialize camera if experiment is in the WF setup
        if strcmp(Log.Setup, 'WFsetup')
            dasbit(Par.Camport, 1) % initializes camera
        end
        
        % Cleanbaseline
        if Log.CleanBaseline(Trial)
            tempLickVec = LickVec;
            cleanBaseTimer = tic;
            while toc(cleanBaseTimer) < Log.CleanBaseline(Trial)            % Pause for Cleanbaselinetime until the mouse stops licking
                checkforLicks
                checkRunning
                if ~isequal(LickVec, tempLickVec)
                    cleanBaseTimer = tic;
                    tempLickVec = LickVec;
                end
            end
        end
        clear cleanBaseTimer
        
        % Random ITI minus baseline imaging time
        randITITimer = tic;
        while toc(randITITimer) <  Log.randITI(Trial) - Log.CleanBaseline(Trial) % pause the random ITI time without the cleanbaseline time and the PreImageTime
            checkforLicks
            checkRunning
        end
        clear randITITimer
        
        % Start Baseline imaging if in WF setup
        if strcmp(Log.Setup, 'WFsetup')
            dasbit(Par.Recport, 1) % starts recording
            pause(Par.PreStimTime) % pauses baseline time
        end
        
        
        %% Visual / Auditory / Optogenetic Stimulation

        checkforLicks
        
        % Send Start signal to Arduino and start the Trial
        fprintf(Par.sport, 'IS');   % starts the trial
        RunningDiff = toc(RunningTimer);
        
        if Log.Trialtype(Trial) == 1
            set(Gui.Currtrial,'Background',[0 1 0])
        else
            set(Gui.Currtrial,'Background',[1 1 0])
        end
        
        % If this is a Go Trial show the Visual Stimulus (if don't want one set contrast to 0)
        if Log.Contrast(Trial) && Log.Trialtype(Trial) == 1
            cgdrawsprite(1,0,0)
            cgdrawsprite(2,0,0)
            VisStatus = 1;
            cgflip('V')
            cgflip(Par.grey)
            cgflip('V')
        else
            VisStatus = 0;
        end
        
        % Play Auditory tone if wanted and this is a Go Trial
        if Log.AudIntensity(Trial) && Log.Trialtype(Trial) == 1
            cgsound('play', 1)
        end
        
        % Start Optogenetic Stimulation if wanted and this is a Go Trial
        if Log.OptoStim(Trial) && Log.Trialtype(Trial) == 1
            dasbit(Par.Optoport,1);   % turns on Laser
            Optostatus = 1;
            fprintf('Opto Trial: Laser Power %gmW Trial Cond %g \n', Log.OptoValue(Trial), Log.TrialCond(Trial))
        else
            Optostatus = 0;
        end
        
        % Stimulus is there (either Visual, Auditory, Opto or Combination)
        if strcmp(Log.Setup, 'WFsetup')
            dasbit(Par.Stimbitport, 1)  % sends a stimbit that stimulus is present
        end
        StimOnset = tic;
        
        % Enable the Lick spout for this trial
        if Log.Trialtype(Trial) == 1    % Go Trial
            fprintf(Par.sport, 'IE 1');
        else                            % No Go Trial
            fprintf(Par.sport, 'IE 2');
        end
        LickEnabled = 1;
        
        
        while toc(StimOnset) < max([Log.TimeToLick(Trial) Par.OptoDuration Par.VisDuration Par.AudDuration])

            checkforLicks
            checkRunning

            
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

            % check if should turn off opto
            if toc(StimOnset) > Par.OptoDuration && Optostatus == 1
                dasbit(Par.Optoport,0);   % turns off Laser
                Optostatus = 0;
                if strcmp(Log.Setup, 'WFsetup')
                    dasbit(Par.Stimbitport, 0)  % sets stimbit to 0 to mark that stimulus is gone
                end
            end
            
            % check if should turn off visual stimulus
            if toc(StimOnset) > Par.VisDuration && VisStatus == 1
                cgflip(Par.grey)
                VisStatus = 0;
                if strcmp(Log.Setup, 'WFsetup')
                    dasbit(Par.Stimbitport, 0)  % sets stimbit to 0 to mark that stimulus is gone
                end
            end
            
            % check if should turn off stimbit because auditory tone is off
            if toc(StimOnset) > Par.AudDuration && Log.AudIntensity(Trial) && Log.Trialtype(Trial) == 1 && strcmp(Log.Setup, 'WFsetup')
                dasbit(Par.Stimbitport, 0)  % sets stimbit to 0 to mark that stimulus is gone
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
        if Optostatus == 1
            dasbit(Par.Optoport,0);         % turns off Laser again, just in case
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
        
        % pause for the fixed ITI
        fixedITITimer = tic;
        while toc(fixedITITimer)< Log.ITI(Trial)
            checkforLicks
            checkRunning
        end
        clear fixedITITimer
        
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
        
        % read out and save the onset of the Blinking Mask in the Log file
        if Par.RecordBlinkMask
            while Par.mask_port.BytesAvailable
                BlinkTime = fread(Par.mask_port, 1, 'int32')/1000 - RunningDiff;
                BlinkVec = [BlinkVec BlinkTime]; %#ok<AGROW>
            end
        else
            BlinkVec = NaN;
        end
        Log.BlinkVec{Trial} = BlinkVec;
        
        
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
if Par.ModulatedArduino
    fclose(Par.Optoserial);
end
if Par.RecordRunning
    fclose(Par.running_port);
end
if Par.RecordBlinkMask
    fclose(Par.mask_port);
end

%% TrialCond Explanation

% 1     No Go
% 
% 2     0.1mW Opto
% 3     0.5mW Opto
% 4     1.0mW Opto
% 5     5.0mW Opto
% 6     10mW Opto
% 7     other mW Opto
% 
% 10    Vis Stim Only
% 
% 12    0.1mW Opto + VisStim
% 13    0.5mW Opto + VisStim
% 14    1.0mW Opto + VisStim
% 15    5.0mW Opto + VisStim
% 16    10mW Opto + VisStim
% 17    other mW Opto + VisStim
% 
% 20    Tone Only
% 
% 22    0.1mW Opto + Tone
% 23    0.5mW Opto + Tone
% 24    1.0mW Opto + Tone
% 25    5.0mW Opto + Tone
% 26    10mW Opto + Tone
% 27    other mW Opto + Tone
% 
% 30    Vis + Tone
% 
% 32    0.1mW Opto + Vis + Tone
% 33    0.5mW Opto + Vis + Tone
% 34    1.0mW Opto + Vis + Tone
% 35    5.0mW Opto + Vis + Tone
% 36    10mW Opto + Vis + Tone
% 37    other mW Opto + Vis + Tone




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