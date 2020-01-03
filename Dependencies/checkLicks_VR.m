% checkLicks_VR

% this is bit confusing, but this script should be used in combination with the arduino script LickSensor_VR

attempts = 0;
set(Gui.Lickbox,'Background',[1 1 1])


while Par.sport.BytesAvailable
    
    arduinoMessage = fscanf(Par.sport, '%s');
    switch arduinoMessage
        case 'L'                                    % There has been a Lick
            Lick = toc(RunningTimer);
            LickVec = [LickVec, Lick]; %#ok<AGROW>
            set(Gui.Lickbox,'Background',[0 0 0])
            
        case 'X'                                    % There has been a Response
            Reaction = fscanf(Par.sport, '%s');     % H = Hit or F = False Alarm
            RT = fscanf(Par.sport, '%s');
            ThresValue = str2double(fscanf(Par.sport, '%s'));
            set(Gui.LickValue, 'string', num2str(ThresValue));
    end
    pause(0.001)
    
    attempts = attempts + 1;
    if attempts > 50
        warning('Tried reading from serial port 50 times, still getting data. Something is wrong, stopping for now.')
        break
    end
end

drawnow