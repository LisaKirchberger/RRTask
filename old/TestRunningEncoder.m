%% Test Running Encoder

% upload the Arduino software on the arduino

running_port = serial('com11');
set(running_port,'InputBufferSize', 10240)
if strcmp(get(running_port, 'status'), 'closed')
    fopen(running_port);
end
set(running_port, 'baudrate', 250000);
set(running_port, 'timeout', 0.1);
% Reset the encoder value to 0
fprintf(running_port, '%i', 1);     %       if this doesn't work try:
                                    % fprintf(running_port, '1');
                                    %       or use
                                    % fwrite(running_port, 1);

%% Initialize some variables

RunningVec = [];
RunningTiming = [];
RunningTimer = tic;
                                    

%% checkRunning

% ask for last speed by sending a 0
fprintf(running_port, '%i', 0);     %       if this doesn't work try:
                                    % fprintf(running_port, '0');
                                    %       or use
                                    % fwrite(running_port, 0);

% store the latest Speed with the Matlab time
stored_Speed = 0;

while stored_Speed == 0
    if running_port.BytesAvailable
        Speed = fscanf(running_port);
        RunningVec = [RunningVec Speed];
        RunningTiming = [RunningTiming toc(RunningTimer)];
        stored_Speed = 1;
    end
end