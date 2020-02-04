function RRTask_human
%%
clear all %#ok<CLALL>
clc

%% Text for participants
text4participantsFlip1 = {'Dear Participant, to validate research in mice, we ask you to play the mouse vision game.', ...
    'Sehr geehrter Teilnehmer, um die Forschung an Mäusen zu validieren, bitten wir Sie, das Maus-Vision-Spiel zu spielen.', ...
    'Geachte deelnemer, om onderzoek bij muizen te valideren, vragen wij u het muizen-visie-spel te spelen'};

text4participantsFlip2 = {'It will maximally take 20 minutes. {Press Enter to continue}', 'Es dauert maximal 20 Minuten. {Drück Enter um fortzufahren}' ,  'Het duurt maximaal 20 minuten. {Druk op Enter om door te gaan}'};

text4participantsFlip3 = {'The participant with the best score, besides eternal fame, receives a bottle of wine or beer and a box of chocolates.' ...
    'Der Teilnehmer mit der besten Punktzahl bekommt, neben dem ewigen Ruhm, eine Flasche Wein oder Bier und Schokola.', ...
    'De deelnemer met de beste score ontvangt, naast eeuwige roem, een fles wijn of bier en een doosje chocola. '};

text4participantsFlip4 = {'If multiple participants have the same score, the winner is the one with the fastest time. {Press Enter to continue}','Wenn mehrere Teilnehmer die gleiche Punktzahl haben, ist der Gewinner derjenige mit der schnellsten Zeit.  {Drück Enter um fortzufahren}','Als meerdere deelnemers dezelfde score hebben, is de winnaar degene met de snelste tijd. {Druk op Enter om door te gaan}'};

text4participantsFlip5 = {'Good luck! {Press Space to start, and also to play}', 'Viel Glück! {Drücken Sie die Leertaste, um zu starten und zu spielen}', 'Succes! {Druk op spatie om te beginnen en ook om te spelen}'};

text4participantsFlip6 = {'You will no longer receive feedback, but continue as you learned {Press Enter to continue}','Sie erhalten kein Feedback mehr, aber fahr fort wie gelernt {Drück Enter um fortzufahren}','Je krijgt nu geen feedback meer, maar ga door zoals je geleerd hebt {Druk op Enter om door te gaan}'};

try    
    addpath(genpath(fullfile(pwd,'Dependencies')))
    addpath(genpath(fullfile(pwd,'Analysis')))
    
    global Par Log %#ok<TLEV>
    
    %% Experiment Parameters
    prompt = {'Name','Distance to computer screen in cm','Experiment Number','Date','Gender (M/F/N)','Age','Nationality'};
    def = {'Name','60', '1',datestr(datenum(date), 'yyyymmdd'),'','',''};
    answer = inputdlg(prompt,'Please enter parameters',1,def);
    SpacePress = 0;
    ESC = 0;
    
    Log.Task = 'RRTask_human';
    Log.Name = answer{1};
    
    Orientations = [0 90 45 135];
    pick = randi(4,1);
    newOris = [Orientations(pick) Orientations(pick)+90 Orientations(pick)+45 Orientations(pick)+45+90];
    newOris(newOris>=180) = newOris(newOris>=180)-180;
    Par.GoFigOrient = newOris(1);
    Par.GoBgOrient = newOris(2);
    Par.NoGoFigOrient = newOris(3);
    Par.NoGoBgOrient = newOris(4);
    Par.ScreenDistance = str2num(answer{2});      % from human horizontally to the Screen

    Par.FigX = 0;
    Par.FigY = 0;
    
    Log.Expnum = answer{3};
    Log.Date = answer{4};
    Log.Gender = answer{5};
    Log.Age = answer{6};
    Log.Nationality = answer{7};
    Log.Logfile_name = [Log.Name, '_', Log.Date, '_B', Log.Expnum];
    
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
                Log.Logfile_name = [Log.Name, '_', Log.Date, '_B', Log.Expnum];
            case 'Exit'
                keyboard
        end
    end
    %     cd(Matlabpath)
    
    
    %% Read in Setup specific parameter file
    run Params_Human
    
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
    %     cgsound('open',Par.Aud_nchannels,Par.Aud_nbits,Par.Aud_sampfrequency,-50,1) % -50db volume attenuation, sound device 0 (default sound device)
    
    %% Show Text Slides
    cgfont('Arial',25)
    cgpencol(1,0,0)
    
    cgtext(text4participantsFlip1{1},0,200)
    cgtext(text4participantsFlip1{2},0,0)
    cgtext(text4participantsFlip1{3},0,-200)
          
    cgflip(Par.grey) 
    
    texttimer = tic;
    
    %% make sprites of VR and all visual stimuli in the mean time
    run makeVisStimsprites    
        
    cgflip(Par.grey)
        
    cgfont('Arial',25)
    cgpencol(1,0,0)
    cgtext(text4participantsFlip1{1},0,200)
    cgtext(text4participantsFlip1{2},0,0)
    cgtext(text4participantsFlip1{3},0,-200)
    
    cgtext(text4participantsFlip2{1},0,150)
    cgtext(text4participantsFlip2{2},0,-50)
    cgtext(text4participantsFlip2{3},0,-250)
    
    cgflip(Par.grey)
    %% Wait for button press to be on screen long enough
    while ~SpacePress
        [kd,kp] = cgkeymap;
        if length(find(kp)) >= 1
            if find(kp) == 28 %Enter
                SpacePress = 1;
                Log.DoneText1 = toc(texttimer);
            end
        end
    end
    SpacePress = 0;
    cgflip(Par.grey)

    %% Remaining text
    cgfont('Arial',25)
    cgpencol(1,0,0)
    cgtext(text4participantsFlip3{1},0,200)
    cgtext(text4participantsFlip3{2},0,0)
    cgtext(text4participantsFlip3{3},0,-200)
    cgflip(Par.grey)

    
    % Wait for button press to be on screen long enough
      while ~SpacePress
        [kd,kp] = cgkeymap;
        if length(find(kp)) >= 1
            if find(kp) == 28 %Enter
                SpacePress = 1;
                Log.DoneText2 = toc(texttimer);
            end
        end
    end
    cgflip(Par.grey)
    SpacePress = 0;

    cgfont('Arial',25)
    cgpencol(1,0,0)
    cgtext(text4participantsFlip4{1},0,200)
    cgtext(text4participantsFlip4{2},0,0)
    cgtext(text4participantsFlip4{3},0,-200)
    cgflip(Par.grey)

    % Wait for button press to be on screen long enough
      while ~SpacePress
        [kd,kp] = cgkeymap;
        if length(find(kp)) >= 1
            if find(kp) == 28 %Enter
                SpacePress = 1;
                Log.DoneText3 = toc(texttimer);
            end
        end
    end
    
    cgflip(Par.grey)
    SpacePress = 0;
 
    cgfont('Arial',25)
    cgpencol(1,0,0)
    cgtext(text4participantsFlip5{1},0,200)
    cgtext(text4participantsFlip5{2},0,0)
    cgtext(text4participantsFlip5{3},0,-200)
    cgflip(Par.grey)

        
    %% make the GUI & initialize variables    
    TrialMatrix = [];
    TestMatrix = [];
    Trial = 0;
    HitCounter = 0;
    MissCounter = 0;
    FACounter = 0;
    CRCounter = 0;
    
    % start with Phase 2 (Testing with all Test Stimuli is Phase 5)
    currPhase = 2;
    TestStimCounter = 0;
    
    %% Wait for button press to be on screen long enough
    while ~SpacePress
        [kd,kp] = cgkeymap;
        if length(find(kp)) >= 1
            if find(kp) == 57
                SpacePress = 1;
                Log.DoneText4 = toc(texttimer);
            end
        end
    end
    cgflip(Par.grey)    
    SpacePress = 0;

    StartParadigmClock = tic;
     %% Main Script
    while TestStimCounter < 400 && ~ESC
        
     
%         fprintf('Trial %d \n', Trial)
        
        %% Change phase if necessary        
        if Trial>50 && Log.TaskPhase(Trial) == 2 && sum(Log.dprime(Trial-10:Trial-1) > 2) == 10 %at least for 10 trials dprime>2
            currPhase = 5;
            %inform participant no feedback is given
            cgfont('Arial',25)
            cgpencol(1,0,0)
            cgtext(text4participantsFlip6{1},0,200)
            cgtext(text4participantsFlip6{2},0,0)
            cgtext(text4participantsFlip6{3},0,-200)
            cgflip(Par.grey)
            
            % Wait for button press to be on screen long enough
            while ~SpacePress
                [kd,kp] = cgkeymap;
                if length(find(kp)) >= 1
                    if find(kp) == 28 || find(kp) == 57%Enter
                        SpacePress = 1;
                        Log.DoneText5 = toc(texttimer);
                    end
                end
            end
            cgflip(Par.grey)
        end

        %% Initialize some variables
        Trial = Trial + 1;
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
                    if Log.TaskPhase(Trial)<=3
                        % show a correct sprite
                        cgdrawsprite(100,0,0)
                        VisStatus = 0;
                        cgflip(Par.grey)
                    end
                    pause(0.3)
                    TrialOver = 1;
                else
                    Reaction = '0';
                    RT = toc(StimOnset);
                    if Log.TaskPhase(Trial)<=3
                        % show the cross sprite
                        cgdrawsprite(101,0,0)
                        VisStatus = 0;
                        cgflip(Par.grey)
                    end
                    % timeout
                    pause(Par.FA_Timeout)
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
        if VisStatus == 1 
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
        
        
        %% update the current d prime, if this is Phase 2 and dprime is above 2 move to Phase 5
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
     
        
        %% save        
        save([Par.Save_Location '\' Log.Logfile_name] , 'Log', 'Par')
        
        
        %% check for stopaftertrial        
        if Log.TaskPhase(Trial) == 5
            TestStimCounter = TestStimCounter + 1;
        end        
    end
    
    Log.TotalTime = toc(StartParadigmClock);
    
    % Session has finished, turn the Log file into a Table and save it with the rest
    
    Log_table = table;
    Log_fieldnames = fieldnames(Log);
    for f = 1:length(Log_fieldnames)
        FieldData = getfield(Log, char(Log_fieldnames(f))); %#ok<GFLD>
        if ischar(FieldData) || length(FieldData)==1
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

return