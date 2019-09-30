%% checks is Mousename is spelled correctly

correctNamesTest = {'Test'};
correctNames191806 = {''};
correctNames = [correctNamesTest correctNames191806];

% compare with input mouse name
Namecmp = sum(strcmp(Log.Mouse, correctNames));

if Namecmp == 0
    dlgTitle    = 'User Question';
    dlgQuestion = sprintf('Are you sure you wrote the name correctly? You gave %s as input', Log.Mouse);
    choiceName = questdlg(dlgQuestion,dlgTitle,'Correct','Change Name', 'Change Name'); %Change Name = default
    switch choiceName
        case 'Correct'
            fprintf('you chose to stick with %s /n', Log.Mouse);
        case 'Change Name'
           Log.Mouse = correctNames{menu('Choose the Mouse',correctNames)};
    end
end