Par.Screenx = 1920;
Par.Screeny = 1080;
Par.Refresh = 60;
Par.ScreenID = 1;
Par.grey = [0.5 0.5 0.5];
Par.DistanceThres = 0.001;

addpath(genpath(fullfile(pwd)))

cgloadlib
cgshut
cgopen(Par.Screenx, Par.Screeny, 32,Par.Refresh , Par.ScreenID)

run makeVRsprites


TotalSpriteCounter = 1;
CurrSprite = SpriteOffset + 1;
CurrDistance = 0;
Times = [];
Timer = tic;

tic
while TotalSpriteCounter <= 200
    
    % at each refresh of the Screen read out the speed of the mouse
    % and determine the distance it ran in this time
    
    cgflip('V')
    
    % Check the running speed
    Speed = 0.2;
    Times = [Times toc(Timer)]; %#ok<AGROW> 
    CurrDistance = CurrDistance + Speed.*1/Par.Refresh;

    
    % Check if should move on to next Sprite
    if CurrDistance > Par.DistanceThres
        TotalSpriteCounter = TotalSpriteCounter + 1;
        CurrSprite = CurrSprite + 1;
        if CurrSprite == SpriteOffset + StepSize
            CurrSprite = SpriteOffset + 1;
        end
        cgdrawsprite(CurrSprite,0,0)
        cgflip(Par.grey)
        CurrDistance = 0;
    end

    pause(0.004)
    % Check the licks
    %checkLicks
    
end
toc

cgshut