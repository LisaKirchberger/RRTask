%% RRTask Analysis

clearvars
%close all
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



