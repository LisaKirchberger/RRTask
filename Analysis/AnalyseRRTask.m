%% RRTask Analysis

clearvars
close all
clc

%%

Mice = {'Ariel', 'Bambi', 'Cruella'};
Mousechoice = menu('Choose the Mouse',Mice);
Mousename = Mice{Mousechoice};

%LogfileDir = 'Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs\RRTask';
LogfileDir = 'D:\Dropbox\19.18.03 FF Plasticity\Logfiles';
MatlabDir = pwd;

cd(LogfileDir)
lognames = dir([Mousename,'*']);
cd(MatlabDir)
dates1 = [lognames.datenum];
same_day = find(diff(dates1)<0.8)+1;
wanted_lognames = {lognames(:).name};
nr_sessions = size(wanted_lognames,2);
CombinedTable = table;
DayCounter = 0;

%% get the Data from all Sessions and combine it in CombinedTable

for Session = 1:nr_sessions
    
    load([LogfileDir '\' wanted_lognames{Session}])
    
    if exist('Log', 'var') && exist('Log_table', 'var')
       
        %% combine the Log_tables
        
        if ~ismember(Session, same_day)
            DayCounter = DayCounter +1;
        end
        
        % Add a Column to the Table with the SessID
        Log_table.SessID = ones(size(Log_table,1),1).*DayCounter;
        
        % Sort the table columns
        Log_table = Log_table(:,sort(Log_table.Properties.VariableNames));
        cmpTables = cellfun(@(c)strcmp(c,Log_table.Properties.VariableNames),CombinedTable.Properties.VariableNames, 'UniformOutput', false);
        missing_fields = Log_table.Properties.VariableNames(~sum(vertcat(cmpTables{:}),1));
        cmpTables2 = cellfun(@(c)strcmp(c,CombinedTable.Properties.VariableNames),Log_table.Properties.VariableNames, 'UniformOutput', false);
        missing_fields2 = CombinedTable.Properties.VariableNames(~sum(vertcat(cmpTables2{:}),1));

       
       % Fill missing fields with NaNs
       if Session == 1
           CombinedTable = Log_table;
       elseif ~isempty(missing_fields) && ~isempty(missing_fields2)
           % create the fields in the combined table and fill with NaNs
           EmptyColumn = NaN(size(CombinedTable,1),1); %#ok<NASGU>
           for f = 1:size(missing_fields,2)
               FieldName = missing_fields{f};
               eval(['CombinedTable.', FieldName, ' = EmptyColumn;'])
           end
           % sort the table columns
           CombinedTable = CombinedTable(:,sort(CombinedTable.Properties.VariableNames));
           % create the fields in the combined table and fill with NaNs
           EmptyColumn = NaN(size(Log_table,1),1);
           for f = 1:size(missing_fields2,2)
               FieldName = missing_fields2{f};
               eval(['Log_table.', FieldName, ' = EmptyColumn;'])
           end
           % sort the table columns
           Log_table = Log_table(:,sort(Log_table.Properties.VariableNames));
           % combine the tables
           CombinedTable = [CombinedTable; Log_table]; %#ok<AGROW>
       elseif ~isempty(missing_fields)
           % create the fields in the combined table and fill with NaNs
           EmptyColumn = NaN(size(CombinedTable,1),1);
           for f = 1:size(missing_fields,2)
               FieldName = missing_fields{f};
               eval(['CombinedTable.', FieldName, ' = EmptyColumn;'])
           end
           % sort the table columns
           CombinedTable = CombinedTable(:,sort(CombinedTable.Properties.VariableNames));
           % combine the tables
           CombinedTable = [CombinedTable; Log_table]; %#ok<AGROW>
       elseif ~isempty(missing_fields2)
           % create the fields in the combined table and fill with NaNs
           EmptyColumn = NaN(size(Log_table,1),1);
           for f = 1:size(missing_fields2,2)
               FieldName = missing_fields2{f};
               eval(['Log_table.', FieldName, ' = EmptyColumn;'])
           end
           % sort the table columns
           Log_table = Log_table(:,sort(Log_table.Properties.VariableNames));
           % combine the tables
           CombinedTable = [CombinedTable; Log_table]; %#ok<AGROW>
       else
            % just combine the tables
            CombinedTable = [CombinedTable; Log_table]; %#ok<AGROW>
        end
        
        clear Log Log_table
        
    end
end


%% Learning progress Phase 1

windowsize = 50;
wantedTrials = find(CombinedTable.Passives == 0 & CombinedTable.TaskPhase ==1);
wanted_Responses = CombinedTable.Reactionidx(wantedTrials);
Hitrate = [];
for i = 1:length(wantedTrials)
    if i <= windowsize/2
        Hitrate(i) = sum(wanted_Responses(1:i+windowsize/2-1)==1)/(i+windowsize/2-1);
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


%% Test Phase 3 or 4 or 5

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


% %% or
% 
% for t = [1 2 5 6]
%     wantedTrials = find(CombinedTable.Passives == 0 & CombinedTable.TestStim ==t & CombinedTable.TaskPhase == 5);
%     Resp_rate_test(t) = sum(CombinedTable.Reactionidx(wantedTrials)==1)/length(wantedTrials);
%     TestResp{t} = CombinedTable.Reactionidx(wantedTrials);
% end
% 
% for t = [3 4]
%     wantedTrials = find(CombinedTable.Passives == 0 & CombinedTable.TestStim ==t & CombinedTable.TaskPhase == 5);
%     Resp_rate_test(t) = sum(CombinedTable.Reactionidx(wantedTrials)==-1)/length(wantedTrials);
%     TestResp{t} = CombinedTable.Reactionidx(wantedTrials);
% end


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

%% 
if 0
   % create and save the visual stimuli of this mouse as bmps
   global Par
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
   ESC=0;
   while ~ESC
       Fgsprite = input('Input Figure Sprite \n');
       Bgsprite = input('Input Background Sprite \n');
       cgdrawsprite(Fgsprite,0,0)
       cgdrawsprite(Bgsprite,0,0)
       cgflip(Par.grey)
       Filename = [Filepath, '\', Mousename, '_', num2str(Fgsprite), '_', num2str(Bgsprite)];
       cgscrdmp(Filename)
       [kd,kp] = cgkeymap;
       if length(find(kp)) == 1
           if find(kp) == 1
               ESC = 1;
           end
       end
   end
   cgshut
end
