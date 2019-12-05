%  checkRunning

if Par.RecordRunning == 1
    % ask for last speed by sending a 2
    fwrite(Par.running_port, 2, 'int16');
    % store the latest Speed with the Matlab time
    stored_Speed = 0;
    timeout = tic;
    while stored_Speed == 0 && toc(timeout)<0.1
        if Par.running_port.BytesAvailable
            Speed = fread(Par.running_port,1, 'int16');
            RunningVec = [RunningVec Speed]; %#ok<AGROW>
            RunningTiming = [RunningTiming toc(RunningTimer)]; %#ok<AGROW>
            stored_Speed = 1;
            % want to cap the speed and not go backwards
            if Speed > Par.maxSpeed
                Speed = Par.maxSpeed;
            elseif Speed < 0
                Speed = 0;
            end
        end
    end
    clear timeout
else
    RunningVec = NaN;
    RunningTiming = NaN;
end

