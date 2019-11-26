run Params_Boxes
Par.ScreenID = 0;

% Initialize some variables
NumLinesVR = 20;                   % number of lines
StepSize = 20;              % number of stetps per cycle
MinRad = 10;                % starting position
BGCol = [0 0 0];            % BG Color
HorizonCol = [0.5 0.5 0.5]; % Horizon Color
SpriteOffset = 100;

% Initialize cogent
cgloadlib
cgopen(Par.Screenx, Par.Screeny, 32,Par.Refresh , Par.ScreenID)
cogstd('sPriority','high')
% Flip up a Screen in BGCol
cgflip(BGCol);


% The initial distance from centre screen (Rad) takes values from MinRad to 400
RngRad = 400 - MinRad;

%  perform a log transformation
k1 = log(MinRad);
k2 = log(RngRad/MinRad);

% Distances of bars from 0 to 1
spacing = linspace(0,1,NumLinesVR);
startingPoints = linspace(spacing(1), spacing(2), StepSize);

% Make sprites once
for s = 1:StepSize-1
    
    cgmakesprite(SpriteOffset+s,Par.Screenx,Par.Screeny,BGCol)
    cgsetsprite(SpriteOffset+s) 
    
    % want lines spaced linearly logarithmically
    Rad = exp(k1 + (spacing+startingPoints(s))*k2);
    
    % The direction of motion is downwards --> pi
    Dir = pi;
    
    % Set the x and y positions
    x = Rad.*sin(Dir);
    y = Rad.*cos(Dir);
    
    % Set the object colours according to distance from centre
    Col(1:NumLinesVR,1:3) = 0.1;
    Col(:,2) = 0.1+Rad'/400;
    Col(Col(:,2)>1,2) = 1; %#ok<SAGROW>
    
    % lines - draw a line segment
    cgpencol(0,0.2,0)
    cgpolygon([1.5*(min(x)+min(y)) 1.5*(max(x)+max(y)) 1.5*(max(x)-max(y)) 1.5*(min(x)-min(y)) ], [min(y) max(y) max(y) min(y)])
    cgalign('l','c')
    cgrect(x,y,1.5*(x+y),y/11,Col)
    cgalign('r','c')
    cgrect(x,y,1.5*(x-y),y/11,Col)
    
    % Draw a Horizon
    cgalign('c','c')
    cgpencol(HorizonCol)
    cgpolygon([-Par.Screenx/2 -Par.Screenx/2 Par.Screenx/2 Par.Screenx/2], [-(MinRad/400*Par.Screeny/2) Par.Screeny/2 Par.Screeny/2 -(MinRad/400*Par.Screeny/2)])
    
    cgsetsprite(0)
    
end

for i = 1:10
    
    for s = 1:StepSize-1
        cgdrawsprite(SpriteOffset+s,0,0)
        cgflip(BGCol);
    end
end

% Close up and return
cgshut


