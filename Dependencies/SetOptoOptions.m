OptoOptions = {'Multi Powers', 'Fixed Power Modulated Arduino', 'Fixed Power Normal Arduino', 'No Opto'};
Optochoice = menu('Choose',OptoOptions);
switch Optochoice
    case 1               %Multi Powers
        prompt = {'Laser Color', 'make sure Laser is set to 233 when BNC is not connected and you are using modulated Arduino!!!'};
        def = {'Red',''};
        answer = inputdlg(prompt,'Please enter parameters',1,def);
        Log.LaserColor = answer{1};
        Log.Laserpower = '0mW 0.1mW 0.5mW 1mW 5mW 10mW';
        Par.MultiOpto = 1;
        Par.ModulatedArduino = 1;
    case 2              %Fixed Power Modulated Arduino
        prompt = {'Laser Power', 'Laser Color', 'make sure Laser is set to 233 when BNC is not connected and you are using modulated Arduino!!!'};
        def = {'5', 'Red',''};
        answer = inputdlg(prompt,'Please enter parameters',1,def);
        Log.Laserpower = answer{1};
        Log.LaserColor = answer{2};
        Par.MultiOpto = 0;
        Par.ModulatedArduino = 1;
        % determine the Arduino Value for this power
        Par.Laserpower = str2double(Log.Laserpower);
        if Par.Laserpower == 0.1
            Par.OptoTrialCond = 2;
            Par.OptoValueArduino = 77;
        elseif Par.Laserpower == 0.5
            Par.OptoTrialCond = 3;
            Par.OptoValueArduino = 142;
        elseif Par.Laserpower == 1
            Par.OptoTrialCond = 4;
            Par.OptoValueArduino = 165;
        elseif Par.Laserpower == 5
            Par.OptoTrialCond = 5;
            Par.OptoValueArduino = 184;
        elseif Par.Laserpower == 10
            Par.OptoTrialCond = 6;
            Par.OptoValueArduino = 200;
        else
            disp('This does not work, if want to use modulated Arduino must input either 0.1 0.5 1 5 10 mW as Laser Power')
            keyboard
        end
        
    case 3              %Fixed Power Normal Arduino
        prompt = {'Laser Power', 'Laser Color'};
        def = {'5', 'Red'};
        answer = inputdlg(prompt,'Please enter parameters',1,def);
        Log.Laserpower = answer{1};
        Log.LaserColor = answer{2};
        Par.MultiOpto = 0;
        Par.ModulatedArduino = 0;
        % determine the Arduino Value for this power
        Par.Laserpower = str2double(Log.Laserpower);
        if Par.Laserpower == 0.1
            Par.OptoTrialCond = 2;
        elseif Par.Laserpower == 0.5
            Par.OptoTrialCond = 3;
        elseif Par.Laserpower == 1
            Par.OptoTrialCond = 4;
        elseif Par.Laserpower == 5
            Par.OptoTrialCond = 5;
        elseif Par.Laserpower == 10
            Par.OptoTrialCond = 6;
        else
            Par.OptoTrialCond = 7;
        end
        
    case 4              %No Opto
        Log.Laserpower = 'NaN';
        Log.LaserColor = 'Red';
        Par.MultiOpto = 0;
        Par.ModulatedArduino = 0;
end