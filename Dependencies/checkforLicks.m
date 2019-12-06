% checkforLicks

% this is bit confusing but this script should be used with the LickSensor
% Arduino script

I = '';
attempts = 0;
Lick = 0;
set(Gui.Lickbox,'Background',[1 1 1])

while Par.sport.BytesAvailable
    
    if Par.sport.BytesAvailable
        while ~strcmp(I, 'O') && Par.sport.BytesAvailable
            I = fscanf(Par.sport, '%s');
            if strcmp(I, 'O') 
                break
            end
        end
        pause(0.001)
        
        Inext = fscanf(Par.sport, '%s');
        switch Inext
            case 'X' % regular response
                if Par.sport.BytesAvailable
                    Reaction = fscanf(Par.sport, '%s');
                end
                if Par.sport.BytesAvailable
                    RT = fscanf(Par.sport, '%s');
                end
                if Par.sport.BytesAvailable
                    passfirst = str2double(fscanf(Par.sport, '%s'));
                end
                if Par.sport.BytesAvailable
                    ThresValue = str2double(fscanf(Par.sport, '%s'));
                    set(Gui.LickValue, 'string', num2str(ThresValue));
                end
                if Par.sport.BytesAvailable
                    thres1 = fscanf(Par.sport, '%s');
                    disp(['R ' thres1])
                end
                if Par.sport.BytesAvailable
                    thres2 = fscanf(Par.sport, '%s');
                end
            
            case 'Y' % all licks right (is what we use)
                if Par.sport.BytesAvailable
                    Lick = str2num(fscanf(Par.sport, '%s'));
                end
                LickVec = [LickVec, Lick];
                rlick = 1;
                set(Gui.Lickbox,'Background',[0 0 0])
                
            case 'Q' %Timing for opening rewardports
                if Par.sport.BytesAvailable
                    ValveOpenTime = ValveOpenTime+str2num(fscanf(Par.sport, '%s'));
                end
        end
        pause(0.001)
    end
    attempts = attempts + 1;
    if attempts > 50
        warning('Tried reading from serial port 50 times, still getting data. Something is wrong, stopping for now.')
        break
    end
    
end
drawnow
