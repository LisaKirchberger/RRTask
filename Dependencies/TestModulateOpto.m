%%
dasinit(23);
for i = 0:7
    dasbit(i, 0)
end

%%
% start the connection to the Opto Arduino
Par.Optoserial = serial('COM14');
set(Par.Optoserial,'InputBufferSize', 10240)
if strcmp(get(Par.Optoserial, 'status'), 'closed'); fopen(Par.Optoserial); end
set(Par.Optoserial, 'baudrate', 250000);
set(Par.Optoserial, 'timeout', 0.1);

%%

dasbit(0,0)
pause(12)
newPower = num2str(200);
message = ['C' newPower];
fprintf(Par.Optoserial, message);             % change the setting to new power

if Par.Optoserial.BytesAvailable
    resp = fscanf(Par.Optoserial, '%s')
end

pause(1)

message = 'P';
fprintf(Par.Optoserial, message);             % ask for current power
pause(0.1)
if Par.Optoserial.BytesAvailable
    resp = fscanf(Par.Optoserial, '%s')
end

dasbit(0,1)

%%


%%

fclose(Par.Optoserial)