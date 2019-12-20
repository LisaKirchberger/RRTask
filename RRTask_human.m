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
    prompt = {'Name', 'Exp Nr', 'Date'};
    def = {'Name', '1', datestr(datenum(date), 'yyyymmdd')};
    answer = inputdlg(prompt,'Please enter parameters',1,def);
    
    Log.Task = 'RRTask_human';
    Log.Mouse = answer{1};
    
    Orientations = [0 90 45 135];
    pick = randi(4,1);
    newOris = [Orientations(pick) Orientations(pick)+90 Orientations(pick)+45 Orientations(pick)+45+90];
    newOris(newOris>=180) = newOris(newOris>=180)-180;
    Par.GoFigOrient = newOris(1);
    Par.GoBgOrient = newOris(2);
    Par.NoGoFigOrient = newOris(3);
    Par.NoGoBgOrient = newOris(4);
    
    Par.FigX = 0;
    Par.FigY = 0;
    
    Log.Expnum = answer{2};
    Log.Date = answer{3};
    Log.Logfile_name = [Log.Mouse, '_', Log.Date, '_B', Log.Expnum];

    Log.Setup = 'Laptop';

    %% Saving location of Logfile 
    
    % Saving Location
    Par.Save_Location = pwd;
    
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
    run Params_Debug

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
    
    
     %% make sprites of VR and all visual stimuli
    
    run makeVisStimsprites
    

    %% make the GUI & initialize variables

    TrialMatrix = [];
    TestMatrix = [];
    Trial = 0;
    HitCounter = 0;
    MissCounter = 0;
    FACounter = 0;
    CRCounter = 0;
    currPhase = 2;
    
    %% Main Script

    
    while ~stopaftertrial
        
        %% Initialize some variables
        
        Trial = Trial + 1;
        fprintf('Trial %d \n', Trial)
        ButtonVec = [];
        Reaction = [];
        
        % Initialization time timer (subtract from ITI):
        InitializeTimer = tic;
        
        %% Read in Parameters from the GUI
        
        Log.GoTrialProportion(Trial) = 50;
        Log.Trial(Trial) = Trial;
        Log.VisDuration(Trial) = 0.5;
        Log.TaskPhase(Trial) = currPhase;
        

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
            elseif Log.TaskPhase(Trial) == 5
                TestStim = 1:6;
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
            Log.Trialtype(Trial) = TrialMatrix(1);
            TrialMatrix(1) = [];
            Log.TestStim(Trial) = NaN;
            
        else                                                                % Testphase
            Log.TestStim(Trial) = TestMatrix(1);                            % There are 4 test stimuli (for now) which are:
            TestMatrix(1) = [];                                             
            if Log.TestStim(Trial) == 1 || Log.TestStim(Trial) == 2         % 1 Go      Figure grating, Background grey                  
                Log.Trialtype(Trial) = 1;                                   % 2 Go      Figure grey, Background grating    
            elseif Log.TestStim(Trial) == 3 || Log.TestStim(Trial) == 4     % 3 NoGo    Figure grating, Background grey
                Log.Trialtype(Trial) = 0;                                   % 4 NoGo    Figure grey, Background grating
            elseif Log.TestStim(Trial) == 5 || Log.TestStim(Trial) == 6     % 5 random reward Go Fig + NoGo Bg 
                Log.Trialtype(Trial) = 1;                                   % 6 random reward NoGo Fig + Go Bg
            else 
                Log.Trialtype(Trial) = TrialMatrix(1);                      % NaN       is a normal trial, just take next normal trial from trial matrix
                TrialMatrix(1) = [];
            end
       
        end
  
        
        %% check for communication from the serial port

        RunningTimer = tic; %use this later to subtract difference to stimulus onset
        checkButton
        
        %% make the Visual Stimulus
        
            
       if Log.TaskPhase(Trial) == 1      % Black/White Figure and Black/White Background
            if Log.Trialtype(Trial) == 1
                Log.Fgsprite(Trial) = 3; % White Figure
                Log.Bgsprite(Trial) = 2; % Black Background
            else
                Log.Fgsprite(Trial) = 1; % Black Figure
                Log.Bgsprite(Trial) = 4; % White Background
                Log.Trialtype(Trial) = 1;
            end
            
        elseif Log.TaskPhase(Trial) == 2 || isnan(Log.TestStim(Trial))    % Go and NoGo Figure-Ground stimuli
            if Log.Trialtype(Trial) == 1
                Log.Fgsprite(Trial) = 6+randi(4,1);      % GoFigOri in 1 of 4 Phases (7-10)
                Log.Bgsprite(Trial) = 10+randi(4,1);     % GoBgOri in 1 of 4 Phases (11-14)
            else
                Log.Fgsprite(Trial) = 14+randi(4,1);     % NoGoFigOri in 1 of 4 Phases (15-18)
                Log.Bgsprite(Trial) = 18+randi(4,1);     % NoGoBgOri in 1 of 4 Phases (19-22)
            end
            
        else    % Test Stimuli
            switch Log.TestStim(Trial)
                case 1
                    Log.Fgsprite(Trial) = 6+randi(4,1);      % GoFigOri in 1 of 4 Phases (7-10)
                    Log.Bgsprite(Trial) = 6;                 % Grey background
                case 2
                    Log.Fgsprite(Trial) = 5;                 % Grey Figure
                    Log.Bgsprite(Trial) = 10+randi(4,1);     % GoBgOri in 1 of 4 Phases (11-14)
                case 3
                    Log.Fgsprite(Trial) = 14+randi(4,1);     % NoGoFigOri in 1 of 4 Phases (15-18)
                    Log.Bgsprite(Trial) = 6;                 % Grey background
                case 4
                    Log.Fgsprite(Trial) = 5;                 % Grey Figure
                    Log.Bgsprite(Trial) = 18+randi(4,1);     % NoGoBgOri in 1 of 4 Phases (19-22)
                case 5
                    Log.Fgsprite(Trial) = 6+randi(4,1);      % GoFigOri in 1 of 4 Phases (7-10)
                    Log.Bgsprite(Trial) = 18+randi(4,1);     % NoGoBgOri in 1 of 4 Phases (19-22)
                case 6
                    Log.Fgsprite(Trial) = 14+randi(4,1);     % NoGoFigOri in 1 of 4 Phases (15-18)
                    Log.Bgsprite(Trial) = 10+randi(4,1);     % GoBgOri in 1 of 4 Phases (11-14)
            end
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
            checkButton
            checkedOnce = 1;
        end
        clear fixedITITimer
 
        % Random ITI minus once the CleanBaseline Time
        checkedOnce = 0;
        randITITimer = tic;
        while toc(randITITimer) <  (Log.randITI(Trial)) || ~checkedOnce 
            checkButton
            checkedOnce = 1;
        end
        clear randITITimer

        
        
        %% Display the Visual Go or NoGo Stimulus

        checkButton
        
        % Send Start signal to Arduino and start the Trial
        RunningDiff = toc(RunningTimer);
        
        % Show the Visual Stimulus   
        cgdrawsprite(Log.Fgsprite(Trial),0,0)
        cgdrawsprite(Log.Bgsprite(Trial),0,0)
        VisStatus = 1;
        cgflip('V')
        cgflip(Par.grey)
        cgflip('V')
        StimOnset = tic;
        
        preButtonVec = ButtonVec;
        TrialOver = 0;

        while toc(StimOnset) < Log.VisDuration(Trial) && ~TrialOver

            checkButton

            if ~isequal(preButtonVec, ButtonVec)
                if Log.Trialtype(Trial) == 1
                    Reaction = '1';
                    RT = toc(StimOnset);
                    % show a correct sprite
                    cgdrawsprite(100,0,0)
                    VisStatus = 0;
                    cgflip(Par.grey)
                    pause(0.3)
                    TrialOver = 1;
                else
                    Reaction = '0';
                    RT = toc(StimOnset);
                    % show the cross sprite
                    cgdrawsprite(101,0,0)
                    VisStatus = 0;
                    cgflip(Par.grey)
                    % 5s timeout
                    pause(5)
                    TrialOver = 1;
                end
            end
            
            % check if should turn off visual stimulus
            if toc(StimOnset) > Log.VisDuration(Trial) && VisStatus == 1
                cgflip(Par.grey)
                VisStatus = 0;
            end

        end
        
        
        % end of trial
        Log.Stimdur(Trial) = toc(StimOnset);
        
        % Check that everything is off
        if VisStatus == 1 || LickEnabled == 1
            cgflip(Par.grey)                % flips up a grey screen         
        end

        checkButton

        
        % save the Button press Data in the Log file
        Log.ButtonVec{Trial} = ButtonVec - RunningDiff;
        
        
        %% Process response
        
        if strcmp(Reaction, '1')
            Log.Reaction{Trial} = 'Hit';
            Log.Reactionidx(Trial) = 1;
            HitCounter = HitCounter + 1;
            Log.RT(Trial) = RT;
        elseif strcmp(Reaction, '0')
            Log.Reaction{Trial} = 'False Alarm';
            FACounter = FACounter + 1;
            Log.Reactionidx(Trial) = -1;
            Log.RT(Trial) = RT;
        else
            if Log.Trialtype(Trial) == 1
                Log.Reaction{Trial} = 'Miss';
                Log.RT(Trial) = NaN;
                Log.Reactionidx(Trial) = 0;
                MissCounter = MissCounter + 1;
            elseif Log.Trialtype(Trial) == 0
                Log.Reaction{Trial} = 'Correct Rejection';
                Log.RT(Trial) = NaN;
                CRCounter = CRCounter + 1;
                Log.Reactionidx(Trial) = 2;
            end
        end
        
        
        %% update the d prime plot
        Par.d_prime_windowsize = 20;
        if Trial <= Par.d_prime_windowsize
            wantedTrials = isnan(Log.TestStim);
            Log.dprime(Trial) = Calcdprime(Log.Reactionidx(wantedTrials));
            Log.criterion(Trial) = CalcCriterion(Log.Reactionidx(wantedTrials));
        else
            wantedTrials = isnan(Log.TestStim) & Log.Trial>Trial-Par.d_prime_windowsize;
            Log.dprime(Trial) = Calcdprime(Log.Reactionidx(wantedTrials));
            Log.criterion(Trial) = CalcCriterion(Log.Reactionidx(wantedTrials));
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

    save([Par.Save_Location '\' Log.Logfile_name] , 'Log', 'Par', 'Log_table')
    
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