%%
clear all %#ok<CLALL>
clc

try
    %% Structure of this task:
    % Mouse is head fixed and sits or runs (running is not relevant for task) on a treadmill or is sitting in a tube
    % The mouse is presented with a replay of the stimuli of a different mouse
    addpath(genpath('Dependencies'))
    addpath(genpath('Analysis'))
    
    prompt = {'Mouse Name', 'Exp Nr', 'Date'};
    def = {'Name', '1', datestr(datenum(date), 'yyyymmdd') };
    answer = inputdlg(prompt,'Please enter parameters',1,def);
    Log.Mouse = answer{1};
    run checkMouse
    ReplayLog.Mouse = Log.Mouse;
    clear Log
    ReplayLog.Expnum = answer{2};
    ReplayLog.Date = answer{3};
    ReplayLog.Task = 'EasyOptoDetectionReplay';
    ReplayLog.Logfile_name = [ReplayLog.Mouse, '_', ReplayLog.Date, '_B', ReplayLog.Expnum];
    
        
    
    % Select the Setup
    Setups = {'Optosetup', 'WFsetup', 'Box1', 'Box2', 'Box3', 'Box4', 'Box5', 'Box6'};
    Setupchoice = menu('Choose the Setup',Setups);
    ReplayLog.Setup = Setups{Setupchoice};
    
    
    
    %% read in Log file you want to replay
    
    if strcmp(ReplayLog.Setup(1:3), 'Box')
        Matlabpath = pwd;
        pathend = strfind(Matlabpath, 'Easy')-1;
        Save_Location = [Matlabpath(1:pathend) 'Logfiles'];
    else
        Save_Location = fullfile('Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs',Log.Task);
    end
    
    if ~exist(Save_Location, 'dir')
        keyboard
    end
    
    cd(Save_Location)
    [ReplayLog.LoadedFile]= uigetfile('*');
    load(ReplayLog.LoadedFile)
    cd(Matlabpath)
    
    
    originalPar = Par;
    originalLog = Log;
    
    
    
    %% run the correct parameter file for the setup the mouse is in
    
    if strcmp(ReplayLog.Setup(1:3), 'Box')
        run Params_Boxes
    elseif strcmp(ReplayLog.Setup, 'Optosetup')
        run Params_Optosetup
    elseif strcmp(ReplayLog.Setup, 'WFsetup')
        run Params_WFsetup
    end
    

    %% open Cogent

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
    
    
    %% start the Arduino connection

    
    % start the connection to the Running Encoder Arduino if there is a running wheel
    try
        if strcmp(get(Par.running_port, 'status'), 'closed'); fopen(Par.running_port); end
        set(Par.running_port, 'baudrate', 57600);
        set(Par.running_port, 'timeout', 0.1);
        fwrite(Par.running_port, 1, 'int16');   % Reset the encoder value to 0
        ReplayLog.RecordRunning = 1;
    catch
        ReplayLog.RecordRunning = 0;
    end
    
    
    % start the connection to the Blinking Mask Arduino if there is a blink mask
    try
        if strcmp(get(Par.mask_port, 'status'), 'closed'); fopen(Par.mask_port); end
        set(Par.mask_port, 'baudrate', 57600);
        set(Par.mask_port, 'timeout', 0.1);
        if Par.mask_port.BytesAvailable
            flushinput(Par.mask_port); % delete everything that was in the buffer
        end
        ReplayLog.RecordBlinkMask = 1;
    catch
        ReplayLog.RecordBlinkMask = 0;
    end

    %% Main Script

    for Trial = 1:Log.Trial(end)
        
        %% Initialize some variables

        fprintf('Trial %d \n', Trial)
        RunningVec = [];
        RunningTiming = [];
        BlinkVec = [];
        
        

        %% check for communication from the serial port
        
        % Sync the Mask to the Trial onset
        if ReplayLog.RecordBlinkMask
            fprintf(Par.mask_port, 'T');     % the beginning of a trial is marked by sending a 'T'
            if Par.mask_port.BytesAvailable
                flushinput(Par.mask_port);   % delete everything that was in the buffer
            end
        end
        RunningTimer = tic; %use this later to subtract difference to stimulus onset
        
        if ReplayLog.RecordRunning
            checkRunning
        end
        
        
        %% make the Visual Stimulus
        
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
        

        
        if Log.AudIntensity(Trial)
            soundwav = sin((1:Par.AudDuration*Par.Aud_sampfrequency)*2*pi*Log.AudFreq(Trial)/Par.Aud_sampfrequency);
            cgsound('MatrixSND',1,soundwav,Par.Aud_sampfrequency)
            cgsound('vol',1,Log.AudIntensity(Trial))
        end
        
        
        %% ITI and Cleanbaseline (fixedITI is at end of trial!)

        % Cleanbaseline
        if Log.CleanBaseline(Trial)
            cleanBaseTimer = tic;
            while toc(cleanBaseTimer) < Log.CleanBaseline(Trial)            % Pause for Cleanbaselinetime until the mouse stops licking
                if ReplayLog.RecordRunning  
                    checkRunning
                end
                pause(0.2)
            end
        end
        clear cleanBaseTimer
        
        % Random ITI
        randITITimer = tic;
        while toc(randITITimer) <  Log.randITI(Trial) - Log.CleanBaseline(Trial) % pause the random ITI time without the cleanbaseline time
            if ReplayLog.RecordRunning
                checkRunning
            end
            pause(0.2)
        end
        clear randITITimer
        
       
        %% Visual / Auditory / Optogenetic Stimulation

        RunningDiff = toc(RunningTimer);

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
            fprintf('OPTOTRIAL \n')
        else
            Optostatus = 0;
        end

        StimOnset = tic;
  
        while toc(StimOnset) < max([Log.TimeToLick(Trial) Par.OptoDuration Par.VisDuration Par.AudDuration])

            if ReplayLog.RecordRunning
                checkRunning
            end
            

            % check if should turn off opto
            if toc(StimOnset) > Par.OptoDuration && Optostatus == 1
                dasbit(Par.Optoport,0);   % turns off Laser
                Optostatus = 0;
            end
            
            % check if should turn off visual stimulus
            if toc(StimOnset) > Par.VisDuration && VisStatus == 1
                cgflip(Par.grey)
                VisStatus = 0;
            end
            
        end
        
        
        
        % Check that everything is off
        if Optostatus == 1 || VisStatus == 1 
            cgflip(Par.grey)            % flips up a grey screen         
            %dasbit(Par.Optoport,0);     % turns off Laser again, just in case
        end

        if ReplayLog.RecordRunning
            checkRunning
        end
        
        % pause for the fixed ITI
        fixedITITimer = tic;
        while toc(fixedITITimer)< Log.ITI(Trial)
            if ReplayLog.RecordRunning
                checkRunning
            end
        end
        clear fixedITITimer
        
        % save the Running Data in the Log file
        ReplayLog.RunningVec{Trial} = RunningVec;
        ReplayLog.RunningTiming{Trial} = RunningTiming - RunningDiff;

        % read out and save the onset of the Blinking Mask in the Log file
        if ReplayLog.RecordBlinkMask
            while Par.mask_port.BytesAvailable
                BlinkTime = fread(Par.mask_port, 1, 'int32')/1000 - RunningDiff;
                BlinkVec = [BlinkVec BlinkTime]; %#ok<AGROW>
            end
        else
            BlinkVec = NaN;
        end
        Log.BlinkVec{Trial} = BlinkVec;
        
        
        %% Plot the running 
        if ReplayLog.RecordRunning
             plotRunning
        end
        
        
        %% save
        ReplayLog.AudFreq(Trial) = Log.AudFreq(Trial);
        ReplayLog.AudIntensity(Trial) = Log.AudIntensity(Trial);
        ReplayLog.Contrast(Trial) = Log.Contrast(Trial);
        ReplayLog.Trial(Trial) = Log.Trial(Trial);
        ReplayLog.OptoStim(Trial) = Log.OptoStim(Trial);
        ReplayLog.Trialtype(Trial) = Log.Trialtype(Trial);
        ReplayLog.randITI(Trial) = Log.randITI(Trial);
        ReplayLog.ITI(Trial) = Log.ITI(Trial);
        ReplayLog.CleanBaseline(Trial) = Log.CleanBaseline(Trial);
        

        save([Save_Location '\' ReplayLog.Logfile_name] , 'originalLog', 'originalPar', 'ReplayLog')
        
    end
    
    % Session has finished, turn the Log file into a Table and save it with the rest
    
    ReplayLog_table = table;
    ReplayLog_fieldnames = fieldnames(ReplayLog);
    for f = 1:length(ReplayLog_fieldnames)
        FieldData = getfield(ReplayLog, char(ReplayLog_fieldnames(f))); %#ok<GFLD>
        if ischar(FieldData)
            FieldData = repmat(FieldData,Trial,1);
        else
            FieldData = FieldData';
        end
        
        if isempty(FieldData)
            fprintf('skipping this field %s', char(ReplayLog_fieldnames(f)))
        else
            eval([ 'ReplayLog_table.' char(ReplayLog_fieldnames(f)), '=', 'FieldData', ';'])
        end
    end
    
    %% save
    save([Save_Location '\' ReplayLog.Logfile_name] , 'originalLog', 'originalPar', 'ReplayLog', 'ReplayLog_table')
    
catch ME
    
    disp(ME)
    
end

cogstd('sPriority','normal')
cgshut

disp('done')

if ReplayLog.RecordRunning
    fclose(Par.running_port);
end
if ReplayLog.RecordBlinkMask
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