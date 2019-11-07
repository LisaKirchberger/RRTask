%% checks is Mousename is spelled correctly

correctNamesTest = {'Test'};
correctNames191801 = {};
correctNames191803 = {};
correctNames191806 = {'Ariel', 'Bambi', 'Cruella'};
correctNames = [correctNamesTest correctNames191801 correctNames191803 correctNames191806];

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

% Mouse specific Parameters for RRTask
% Figure and Ground Orientations:
% 0 is vertical
% 90 is horizontal

switch Log.Mouse
    case 'Test'
        Par.GoFigOrient = 0;
        Par.GoBgOrient = 90;
        Par.NoGoFigOrient = 45;
        Par.NoGoBgOrient = 135;
        Par.FigX = 30;
        Par.FigY = 20;
        
    case 'Ariel'
        Par.GoFigOrient = 0;
        Par.GoBgOrient = 90;
        Par.NoGoFigOrient = 45;
        Par.NoGoBgOrient = 135;
        Par.FigX = 30;
        Par.FigY = 20;
        
    case 'Bambi'
        Par.GoFigOrient = 45;
        Par.GoBgOrient = 135;
        Par.NoGoFigOrient = 0;
        Par.NoGoBgOrient = 90;
        Par.FigX = 0;
        Par.FigY = 20;
        
    case 'Cruella'
        Par.GoFigOrient = 90;
        Par.GoBgOrient = 0;
        Par.NoGoFigOrient = 135;
        Par.NoGoBgOrient = 45;
        Par.FigX = -30;
        Par.FigY = 20;
        
end


