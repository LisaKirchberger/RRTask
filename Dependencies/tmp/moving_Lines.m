function moving_Lines

% Globals
global	Num MinRad BGCol HorizonCol
% Initialize some globals
Num = 20;
MinRad = 10;
BGCol = [0 0 0];
HorizonCol = [0.5 0.5 0.5];

% Initialize cogent
cgloadlib
cgopen(1,0,0,1)

% Initialize the stars
InitLines

% Move the Lines towards viewer
moveLines

% Close up and return
cgshut

% Clear globals
clear global Num x y Rad MinRad Spd 

return



%-----------------------------------------------------

function InitLines

% Globals
global Num x y Rad MinRad Spd k1 k2 Dir

% The initial distance from centre screen (Rad) takes
% values from MinRad to 400
RngRad = 400 - MinRad;

%  perform a log transformation
k1 = log(MinRad);
k2 = log(RngRad/MinRad);

% want lines spaced linearly logarithmically
Rad = exp(k1 + linspace(0,1,Num)*k2);

% The speed factor 
mySpd = 1.01;
Spd = repmat(mySpd,1,Num);

% The direction of motion is downwards --> pi
Dir = pi;

% Set the initial x and y positions
x = Rad.*sin(Dir);
y = Rad.*cos(Dir);


return

%-----------------------------------------------------

% This function moves the lines
function moveLines

% Globals
global Num x y Rad Spd k1 k2 Dir BGCol HorizonCol

% Set pen colour 1 (white)
cgpencol(1,1,1)
Col(1:Num,1:3) = 0.3;
Col(:,3) = 0.3;
% We break out of the loop when the escape key is pressed.
% Initialize the state to 'not pressed' (0).
kd(1) = 0;

while ~kd(1)
    
    % Read the keyboard
    
    kd = cgkeymap;
    
    % Flip up a Screen in BGCol
    cgflip(BGCol);
    
    % Set the object colours according to distance from centre
    Col(:,2) = 0.3+Rad'/400;
    Col(Col(:,2)>1,2) = 1;

    % lines - draw a line segment
    % this works: 
    %cgdraw(x-y,y,x+y,y,Col)
    
    % or this:
    cgpencol(0,0.2,0)
    cgpolygon([min(x)+min(y) max(x)+max(y) max(x)-max(y) min(x)-min(y) ], [min(y) max(y) max(y) min(y)])
    
    cgalign('l','c')
    cgrect(x,y,x+y,y/11,Col)
    cgalign('r','c')
    cgrect(x,y,x-y,y/11,Col)
    

    % Draw a Horizon
    cgalign('r','c')
    cgrect(400,150,800,320, HorizonCol)

    
    % Update the positions
    x = x.*Spd;
    y = y.*Spd;
    Rad = Rad.*Spd;
    
    
    % Check for wraparound
    a = find(Rad > 400);
    if ~isempty(a)
        % stick this line to the beginning
        % find out where min is in linspace
        ascRad = sort(Rad);
        RadLin1 = (log(ascRad(1))-k1)/k2;
        RadLin2 = (log(ascRad(2))-k1)/k2;
        LinStepSize = RadLin2-RadLin1;
        wantedRadLin = RadLin1-LinStepSize;
        Rad(a) = exp(k1+wantedRadLin*k2);
        x(a) = Rad(a).*sin(Dir);
        y(a) = Rad(a).*cos(Dir);
    end

end

return

