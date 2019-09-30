%%
clear all %#ok<CLALL>
clc

try
    %% Structure of this task:
    % Mouse is head fixed and sits or runs (running is not relevant for task) on a treadmill
    % On Go Trials the mouse is presented with an auditory stimulus (frequency of the tone can be varied) and/or an
    % optogenetic stimulus The start of a trial is marked by a full screen checkerboard stimulus combined with
    % optogenetic stimulation on go trials and nothing appears on no go trials
    % In trials with optogenetic stimulation mouse has to lick to get a reward,
    % in other trials there is no reward
           
    addpath(genpath('Dependencies'))
    addpath(genpath('Analysis'))
    
    %% Experiment Parameters
    prompt = {'Mouse Name', 'Exp Nr', 'Date', 'Laser power', 'Task Name', 'Color', 'Exposure', 'Setup'};
    def = {'Name', '1', datestr(datenum(date), 'yyyymmdd'), 'NaN', 'EasyOptoDetection', 'Red', '50', 'WFsetup'};
    answer = inputdlg(prompt,'Please enter parameters',1,def);
    Log.Mouse = answer{1};
    Log.Expnum = answer{2};
    Log.Date = answer{3};
    Log.Laserpower = answer{4};
    Log.Task = answer{5};
    Log.LaserColor = answer{6};
    Log.Exposure = answer{7};
    Log.Setup = answer{8};
    Log.ControlMouse = [];
    Log.Logfile_name = [Log.Mouse, '_', Log.Date, '_B', Log.Expnum];
    
    run checkMouse
    
    % Saving location
    Par.Save_Location = fullfile('\\NIN518\Imaging\',[Log.Mouse Log.Date]);
    if ~exist(Par.Save_Location, 'dir')
        keyboard
    end
    Par.Save_Location2 = fullfile('Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs');
    
    % Check if Logfile with identical name already exists
    Matlabpath = pwd;
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
    
    
    %% make a JSON file
    
    % define the fields
    fields.project = 'Mouse_Plasticity';
    fields.dataset = 'Widefield_Data';
    fields.subject = Log.Mouse;
    fields.condition = 'awake';
    fields.investigator = 'LisaKirchberger';
    fields.date = Log.Date;
    fields.setup = 'WF';
    fields.stimulus = Log.Task;
    expname = Log.Logfile_name;
    SaveDataFolder = Par.Save_Location;
    
    run GenerateJSONfile
   

    %% open Cogent

    % Read in Parameters
    run Params_WFsetup
    cgloadlib
    cgshut
    %Screen
    cgopen(Par.Screenx, Par.Screeny, 32,Par.Refresh , Par.ScreenID) %real
    cogstd('sPriority','high')
    for i = 1:120
        cgflip(Par.grey)
    end
    %Sound
    cgsound('open',Par.Aud_nchannels,Par.Aud_nbits,Par.Aud_sampfrequency,-50,1) % -50db volume attenuation, sound device 0 (default sound device)
    
    %% initialize the DAS card
    
    dasinit(22);
    dasbit(Par.Camport, 0)      % Campera port 0
    dasbit(Par.Shutterport, 0)  % Shutter port 1
    dasbit(Par.Recport, 0)      % Recording port 2
    dasbit(Par.Stimbitport, 0)  % Stimbit port 3
    dasbit(Par.Optoport, 0)     % Opto port 4

    
    
    %% start the Arduino connection
    
    % start the connection to the Lick Detection Arduino
    set(Par.sport,'InputBufferSize', 10240)
    if strcmp(get(Par.sport, 'status'), 'closed'); fopen(Par.sport); end
    set(Par.sport, 'baudrate', 250000);
    set(Par.sport, 'timeout', 0.1);
    sendtoard(Par.sport, 'ID');             % disable reward, just to be safe
    
    % start the connection to the Running Encoder Arduino if there is a running wheel
    try
        if strcmp(get(Par.running_port, 'status'), 'closed'); fopen(Par.running_port); end
        set(Par.running_port, 'baudrate', 57600);
        set(Par.running_port, 'timeout', 0.1);
        fwrite(Par.running_port, 1, 'int16');   % Reset the encoder value to 0
        Par.RecordRunning = 1;
    catch
        Par.RecordRunning = 0;
    end
    
    % start the connection to the Blinking Mask Arduino if there is a blink mask
    try
        if strcmp(get(Par.mask_port, 'status'), 'closed'); fopen(Par.mask_port); end
        set(Par.mask_port, 'baudrate', 57600);
        set(Par.mask_port, 'timeout', 0.1);
        if Par.mask_port.BytesAvailable
            flushinput(Par.mask_port); % delete everything that was in the buffer
        end
        Par.RecordBlinkMask = 1;
    catch
        Par.RecordBlinkMask = 0;
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
    
    
    %% Main Script
    while ~StartSession
        pause(0.1)
    end
    delete(Gui.StartButton)
    dasbit(Par.Shutterport, 1)     % opens the shutter
    disp('Shutter open')
    
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
        Log.Passivedelay(Trial) = str2double(get(Gui.Passivedelay, 'string'))/1000;
        
        % send Rewardtime, Threshold and Passvie Delay to Arduino
        sendtoard(Par.sport, ['IL ' get(Gui.RewardDur, 'String')])
        sendtoard(Par.sport, ['IF ' get(Gui.Threshold, 'String')])
        sendtoard(Par.sport, ['IT ' get(Gui.Passivedelay, 'String')])
        
        
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
        
        if Log.Contrast(Trial)
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
        end
        
        
        %% make the Auditory Stimulus
        
        Log.AudFreq(Trial) = str2double(get(Gui.AudFreq, 'string'));
        Log.AudIntensity(Trial) = str2double(get(Gui.AudIntensity, 'string'))/100;
        
        if Log.AudIntensity(Trial)
            soundwav = sin((1:Par.AudDuration*Par.Aud_sampfrequency)*2*pi*Log.AudFreq(Trial)/Par.Aud_sampfrequency);
            cgsound('MatrixSND',1,soundwav,Par.Aud_sampfrequency)
            cgsound('vol',1,Log.AudIntensity(Trial))
        end
        
        
        %% ITI and Cleanbaseline (fixedITI is at end of trial!)
        
        Log.randITI(Trial) = Par.random_ITI * rand;
        Log.ITI(Trial) = Par.ITI;
        Log.CleanBaseline(Trial) = str2double(get(Gui.CleanBaseline, 'string'));
        
        % first initialize camera 
        dasbit(Par.Camport, 1) % initializes camera
        
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
        while toc(randITITimer) <  Log.randITI(Trial) - Log.CleanBaseline(Trial) - Par.PreStimTime  % pause the random ITI time without the cleanbaseline time and the PreImageTime
            checkforLicks
            checkRunning
        end
        clear randITITimer
        
        % Start Baseline imaging
        dasbit(Par.Recport, 1) % starts recording
        pause(Par.PreStimTime) % pauses baseline time
        
        
        %% Visual / Auditory / Optogenetic Stimulation

        
        % Send Start signal to Arduino and start the Trial
        fprintf(Par.sport, 'IS');   % starts the trial
        RunningDiff = toc(RunningTimer);
        
        
        % If this is a Go Trial show the Visual Stimulus (if don't want one set contrast to 0)
        if Log.Contrast(Trial) && Log.Trialtype(Trial) == 1
            cgdrawsprite(1,0,0)
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
            fprintf('OPTOTRIAL \n')
        else
            Optostatus = 0;
        end
        
        % Stimulus is there (either Visual, Auditory, Opto or Combination)
        dasbit(Par.Stimbitport, 1)  % sends a stimbit that stimulus is present
        StimOnset = tic;
        GraceEnabled = 1;
  
        while toc(StimOnset) < max([Log.TimeToLick(Trial) Par.OptoDuration Par.VisDuration Par.AudDuration])

            checkforLicks
            checkRunning
            
            % check if grace period is over and Licking should be enabled
            if toc(StimOnset) > Par.Grace_duration && GraceEnabled == 1
                if Log.Trialtype(Trial) == 1    % Go Trial
                    sendtoard(Par.sport, 'IE 1')
                else                            % No Go Trial
                    sendtoard(Par.sport, 'IE 2')
                end
                LickEnabled = 1;
                GraceEnabled = 0;
            end
            
            % check if should give a passive
            if Log.Passives(Trial) && toc(StimOnset) > Log.Passivedelay(Trial) && ~gavepassive
                sendtoard(Par.sport, 'IP')          % give passive
                gavepassive = 1;
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
                dasbit(Par.Stimbitport, 0)  % sets stimbit to 0 to mark that stimulus is gone
            end
            
            % check if should turn off visual stimulus
            if toc(StimOnset) > Par.VisDuration && VisStatus == 1
                cgflip(Par.grey)
                VisStatus = 0;
                dasbit(Par.Stimbitport, 0)  % sets stimbit to 0 to mark that stimulus is gone
            end
            
            % check if should turn off stimbit because auditory tone is off
            if toc(StimOnset) > Par.AudDuration && Log.AudIntensity(Trial) && Log.Trialtype(Trial) == 1
                dasbit(Par.Stimbitport, 0)  % sets stimbit to 0 to mark that stimulus is gone
            end
            
        end
        
        % end of trial
        Log.Stimdur(Trial) = toc(StimOnset);
        dasbit(Par.Stimbitport, 0)      % sets stimbit to 0 to mark that stimulus is gone
        
        % Check that everything is off
        if Optostatus == 1 || VisStatus == 1 || LickEnabled == 1
            cgflip(Par.grey)                % flips up a grey screen         
            dasbit(Par.Optoport,0);         % turns off Laser again, just in case
            sendtoard(Par.sport, 'ID');     % disable the lick reward
        end
        
        % Stop recording and turn camera off
        dasbit(Par.Recport, 0)  % stops recording
        dasbit(Par.Camport, 0)  % stops camera

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
        % save in imaging folder in the format Enny uses
        save([Par.Save_Location '\' Log.Mouse Log.Expnum] , 'Log', 'Par', 'RunningTimecourseAVG')
        % also save it on Z:drive in my format
        save([Par.Save_Location2 '\' Log.Logfile_name] , 'Log', 'Par', 'RunningTimecourseAVG')

        
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
    % save in imaging folder in the format Enny uses
    save([Par.Save_Location '\' Log.Mouse Log.Expnum] , 'Log', 'Par', 'Log_table', 'RunningTimecourseAVG')
    % also save it on Z:drive in my format
    save([Par.Save_Location2 '\' Log.Logfile_name] , 'Log', 'Par', 'Log_table', 'RunningTimecourseAVG')
    
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
if Par.RecordBlinkMask
    fclose(Par.mask_port);
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