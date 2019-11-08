function moving_Lines

% Globals
global	Num MinRad
% Initialize some globals
Num = 20;
MinRad = 10;

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

% However, the steady state distribution of stars around
% the centre is logarithmic so perform a log transformation
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
global Num x y Rad Spd k1 k2 Dir

% Set pen colour 1 (white)
cgpencol(1,1,1)
Col(1:Num,1:3) = 1;

% We break out of the loop when the escape key is pressed.
% Initialize the state to 'not pressed' (0).
kd(1) = 0;

while ~kd(1)
    
    % Read the keyboard
    
    kd = cgkeymap;
    
    % Set the offscreen area black
    cgflip(0,0,0);
    
    % Set the object colours according to distance from centre
    Col(:,3) = Rad'/400;
    Col(:,2) = 1-(Rad'/400);

    % lines - draw a line segment
    cgdraw(x-y,y,x+y,y,Col)
    %cgrect(x-y,y,x+y,y,Col)
    %cgrect(0,150,800,320)
    
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

