% Mouse specific Parameters for RRTask
% Figure and Ground Orientations:
% 0 is horizontal
% 90 is vertical

switch Log.Mouse
    case 'Test'
        Par.GoFigOrient = 0;
        Par.GoBgOrient = 90;
        Par.NoGoFigOrient = 45;
        Par.NoGoBgOrient = 135;
        
    case 'A'
        Par.GoFigOrient = 0;
        Par.GoBgOrient = 90;
        Par.NoGoFigOrient = 45;
        Par.NoGoBgOrient = 135;
        
    case 'B'
        Par.GoFigOrient = 45;
        Par.GoBgOrient = 135;
        Par.NoGoFigOrient = 0;
        Par.NoGoBgOrient = 90;
        
    case 'C'
        Par.GoFigOrient = 90;
        Par.GoBgOrient = 0;
        Par.NoGoFigOrient = 135;
        Par.NoGoBgOrient = 45;
        
end
