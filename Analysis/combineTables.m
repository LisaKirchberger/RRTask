function CombinedTable = combineTables(input)

CombinedTable = table;
DayCounter = 1;

for Sess = 1:size(input,2)
    
    load(input{Sess})
    if ~exist('Log_table', 'var')
        load(input{Sess}, 'Log')
        Trial = Log.Trial(end);
        Log_table = table;
        Log_fieldnames = fieldnames(Log);
        for f = 1:length(Log_fieldnames)
            FieldData = getfield(Log, char(Log_fieldnames(f))); %#ok<GFLD>
            if ischar(FieldData)
                FieldData = repmat(FieldData,Trial,1);
            elseif length(FieldData) ~= Trial
                FieldData(length(FieldData)+1:Trial) = NaN;
                FieldData = FieldData';
            else
                FieldData = FieldData';
            end
            eval([ 'Log_table.' char(Log_fieldnames(f)), '=', 'FieldData', ';'])
        end
    end
    
    % Have to trick around a little bit, otherwise can't concatenate the table later
    if isa(Log_table.Laserpower,'char')
        Log_table.Laserpower = cellstr(Log_table.Laserpower);
    end
    if isa(Log_table.Setup, 'char')
        Log_table.Setup = cellstr(Log_table.Setup);
    end
    if sum(strcmp('Exposure',Log_table.Properties.VariableNames))
        Log_table.Exposure = table2array(varfun(@str2num, Log_table, 'InputVariables', 'Exposure'));
    end
        
    
    if Sess > 1 
       cmp_until = regexp(input{Sess}, '_'); cmp_until = cmp_until(end);
       if ~strcmp(input{Sess}(1:cmp_until), input{Sess-1}(1:cmp_until))
           DayCounter = DayCounter +1;
       end
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
    
    if Sess == 1
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
    clear Log_table
    
end
