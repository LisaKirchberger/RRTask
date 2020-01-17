%% RRTask Analysis

clearvars
close all
clc

%% load and combine the Logfiles

Mice = {'Ariel', 'Bambi', 'Cruella'};
Mousechoice = menu('Choose the Mouse',Mice);
Mousename = Mice{Mousechoice};

LogfileDir = 'D:\Dropbox\19.18.03 FF Plasticity\Logfiles';                  %LogfileDir = 'Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs\RRTask';
MatlabDir = pwd;

cd(LogfileDir)
lognames = dir([Mousename,'*']);
cd(MatlabDir)
for Sess = 1:size(lognames,1)
    LoadFiles{Sess} = [lognames(Sess).folder '\' lognames(Sess).name];      
end
CombinedTable = combineTables(LoadFiles);


%% Learning progress Phase 1

windowsize = 50;
wantedTrials = find(CombinedTable.Passives == 0 & CombinedTable.TaskPhase ==1);
wanted_Responses = CombinedTable.Reactionidx(wantedTrials);
Hitrate = [];
for i = 1:length(wantedTrials)
    if i <= windowsize/2
        Hitrate(i) = sum(wanted_Responses(1:i+windowsize/2-1)==1)/(i+windowsize/2-1); %#ok<*SAGROW>
    elseif i > length(wanted_Responses)-windowsize/2
        Hitrate(i) = sum(wanted_Responses(i-windowsize/2:end)==1)/(length(wanted_Responses)-i+1+windowsize/2);
    else
        Hitrate(i) = sum(wanted_Responses(i-windowsize/2:i+windowsize/2-1)==1)/windowsize;
    end
end
figure('Position', [83   796   465   267])
plot(Hitrate.*100, 'k-', 'LineWidth', 1)
axis tight
hold on
cumTrials = 0;
for i = unique(CombinedTable.SessID(wantedTrials))'
    SessTrials = length(find(CombinedTable.SessID(wantedTrials) == i));
    plot([cumTrials+SessTrials cumTrials+SessTrials], [0 100], 'k--', 'LineWidth', 0.5)
    cumTrials = cumTrials+SessTrials;
end
box off
set(gca, 'TickDir', 'out')
ylim([0 100])
xlabel('Trials')
ylabel('Hitrate')
title(sprintf('Learning Progress Phase 1 %s', Mousename))

%% Learning progress Phase 2

windowsize = 200;
wantedTrials = find(CombinedTable.Passives == 0 & CombinedTable.TaskPhase ==2);
wanted_Responses = CombinedTable.Reactionidx(wantedTrials);
dprime_learning = [];
for i = 1:length(wantedTrials)
    if i <= windowsize/2
        dprime_learning(i) = Calcdprime(wanted_Responses(1:i+windowsize/2-1));
    elseif i > length(wanted_Responses)-windowsize/2
        dprime_learning(i) = Calcdprime(wanted_Responses(i-windowsize/2:end));
    else
        dprime_learning(i) = Calcdprime(wanted_Responses(i-windowsize/2:i+windowsize/2-1));
    end
end
figure('Position', [83   394   471   315])
plot(dprime_learning, 'b-', 'LineWidth', 1)
axis tight
hold on
plot(get(gca, 'XLim'),[0 0],'r')
plot(get(gca, 'XLim'),[1.5 1.5],'g')
cumTrials = 0;
for i = unique(CombinedTable.SessID(wantedTrials))'
    SessTrials = length(find(CombinedTable.SessID(wantedTrials) == i));
    plot([cumTrials+SessTrials cumTrials+SessTrials], get(gca, 'YLim'), 'k--', 'LineWidth', 0.5)
    cumTrials = cumTrials+SessTrials;
end
box off
set(gca, 'TickDir', 'out')
xlabel('Trials')
ylabel('dprime')
title(sprintf('Learning Progress Phase 2 %s', Mousename))


%% Correction of one File
% have to correct sth, in the first Session Dropbox was turned off, so
% conditions 5 and 6 were accidentally sometimes NoGo trials, correct this!
% the wrong Logfile was called {Bambi_20191217_B1}, change all CR into Miss
% and all FA into Hit
% change all CR into Hits
wrongCRTrials = find(strcmp(cellstr(CombinedTable.Logfile_name), 'Bambi_20191217_B1') & ~isnan(CombinedTable.TestStim) & CombinedTable.Reactionidx == 2);
for i = 1:length(wrongCRTrials)
    CombinedTable.Reactionidx(wrongCRTrials(i)) = 0;
end
wrongFATrials = find(strcmp(cellstr(CombinedTable.Logfile_name), 'Bambi_20191217_B1') & ~isnan(CombinedTable.TestStim) & CombinedTable.Reactionidx == -1);
for i = 1:length(wrongFATrials) 
    CombinedTable.Reactionidx(wrongFATrials(i)) = 1;
end


%% Test Phase 3 or 4 or 5

for t = [1 2 5 6 7 8 9 10]
    wantedTrials = find(CombinedTable.Passives == 0 & CombinedTable.TestStim ==t);
    Resp_rate_test(t) = sum(CombinedTable.Reactionidx(wantedTrials)==1)/length(wantedTrials);
    TestResp{t} = CombinedTable.Reactionidx(wantedTrials);
end

for t = [3 4 11 12 13 14]
    wantedTrials = find(CombinedTable.Passives == 0 & CombinedTable.TestStim ==t);
    Resp_rate_test(t) = sum(CombinedTable.Reactionidx(wantedTrials)==-1)/length(wantedTrials);
    TestResp{t} = CombinedTable.Reactionidx(wantedTrials);
end


%% show the Hit/Miss/FA/CR distribution
figure
hold all
for t = 1:length(Resp_rate_test)
    for i = 1:length(TestResp{t})
        switch TestResp{t}(i)
            case 1 %Hit
                plot(i,t, 's','MarkerFaceColor', [0 1 0], 'MarkerEdgeColor', 'k', 'MarkerSize', 12)
            case 0 %Miss
                plot(i,t, 's','MarkerFaceColor', [1 0.5 0.3], 'MarkerEdgeColor', 'k', 'MarkerSize', 12)
            case 2 %CR
                plot(i,t, 's','MarkerFaceColor', [0 1 1], 'MarkerEdgeColor', 'k', 'MarkerSize', 12)
            case -1 %FA
                plot(i,t, 's','MarkerFaceColor', [1 0 0], 'MarkerEdgeColor', 'k', 'MarkerSize', 12)
        end
    end
end
box off
set(gca, 'TickDir', 'out')
xlabel('Trial')
ylabel('Test Stimulus')
ylim([0 length(Resp_rate_test)+1])
yticks(1:length(Resp_rate_test))
title(sprintf('Test Stimuli %s', Mousename))


%% plot the d-prime for the TestPhase 

windowsize = 50;
wantedTrials = find(CombinedTable.Passives == 0 & CombinedTable.TaskPhase > 2 & isnan(CombinedTable.TestStim));
wanted_Responses = CombinedTable.Reactionidx(wantedTrials);
dprime_testing = [];
for i = 1:length(wantedTrials)
    if i <= windowsize/2
        dprime_testing(i) = Calcdprime(wanted_Responses(1:i+windowsize/2-1));
    elseif i > length(wanted_Responses)-windowsize/2
        dprime_testing(i) = Calcdprime(wanted_Responses(i-windowsize/2:end));
    else
        dprime_testing(i) = Calcdprime(wanted_Responses(i-windowsize/2:i+windowsize/2-1));
    end
end
figure('Position', [82    47   471   315])
plot(dprime_testing, 'k-', 'LineWidth', 1)
axis tight
hold on
plot(get(gca, 'XLim'),[0 0],'r')
plot(get(gca, 'XLim'),[1.5 1.5],'g')
cumTrials = 0;
for i = unique(CombinedTable.SessID(wantedTrials))'
    SessTrials = length(find(CombinedTable.SessID(wantedTrials) == i));
    plot([cumTrials+SessTrials cumTrials+SessTrials], get(gca, 'YLim'), 'k--', 'LineWidth', 0.5)
    cumTrials = cumTrials+SessTrials;
end
box off
set(gca, 'TickDir', 'out')
xlabel('Trials')
ylabel('dprime')
title(sprintf('Accuracy Test Phase %s', Mousename))

% overall d-prime
dprime_testing_all = Calcdprime(wanted_Responses);
Hitrate_all = sum(CombinedTable.Reactionidx(wantedTrials)==1)/(sum(CombinedTable.Reactionidx(wantedTrials)==1)+sum(CombinedTable.Reactionidx(wantedTrials)==0));
FArate_all = sum(CombinedTable.Reactionidx(wantedTrials)==-1)/(sum(CombinedTable.Reactionidx(wantedTrials)==-1)+sum(CombinedTable.Reactionidx(wantedTrials)==2));


%% Visual Stimuli for each Mouse

if 1
   % create and save the visual stimuli of this mouse as bmps
   global Par %#ok<UNRCH>
   cd ..
   addpath(genpath('Dependencies'))
   cd(MatlabDir)
   Log.Mouse = Mousename;
   run checkMouse
   run Params_Boxes
   Par.ScreenID = 0;
   cgloadlib
   cgshut
   cgopen(Par.Screenx, Par.Screeny, 32,Par.Refresh , Par.ScreenID)
   cogstd('sPriority','high')
   run makeVisStimsprites
   Filepath = 'D:\Dropbox\19.18.07 RRTask\VisualStimuli';
   try
       while 1
           Fgsprite = input('Input Figure Sprite \n');          % e.g. 7 Go     15 NoGo
           Bgsprite = input('Input Background Sprite \n');      % e.g. 11 Go    19 NoGo
           cgdrawsprite(Fgsprite,0,0)
           cgdrawsprite(Bgsprite,0,0)
           cgflip(Par.grey)
           Filename = [Filepath, '\', Mousename, '_', num2str(Fgsprite), '_', num2str(Bgsprite)];
           cgscrdmp(Filename)
       end
   catch
       cgshut
   end
end
