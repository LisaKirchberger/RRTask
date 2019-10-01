
%% Create an oversized Full Screen Grating for the Figure
[x,y]=meshgrid(-Par.Screenx:Par.Screenx);
x_ori =x*cosd(Par.FigOrient)+y*sind(Par.FigOrient);
OversizedGrating =sin(2*pi*(1/Par.Period)*x_ori + Log.FigPhase(Trial));

%% Adjust to max and min Luminance of the Screen
OversizedGrating =  OversizedGrating - min( OversizedGrating(:)); % set range of OversizedGrating between [0, inf)
OversizedGrating =  OversizedGrating ./ max( OversizedGrating(:)) ; % set range of OversizedGrating between [0, 1]
OversizedGrating =  OversizedGrating .* diff([Par.blacklum Par.whitelum]) ; % set range of OversizedGrating between [0, LuminanceRange]
OversizedGrating =  OversizedGrating + Par.blacklum; % shift range of OversizedGrating to minimal luminance
OversizedGratingRGB = eval([gammaconversion '(OversizedGrating,''lum2rgb'')']);

%% Morph the grating, convert Cartesian to spherical coordinates
% In image space, x and y are width and height of monitor and z is the distance from the eye. I want Theta to correspond to azimuth and Phi to
% correspond to elevation, but these are measured from the x-axis and x-y plane, respectively. So I need to exchange the axes prior to
% converting to spherical coordinates: orig (image) -> for conversion to spherical coords
% Z -> X          X -> Y              Y -> Z
ScreenDistanceTop = Par.ScreenDistanceBottom - (Par.ScreenHeight*sin(deg2rad(90-Par.ScreenAngle))); % Calculate the Distance of the Screen at the top of the Screen (only different from the distance to the bottom if the Screen is angled, so not at 90 degrees)
[xi,yi] = meshgrid(1:Par.Screenx,1:Par.Screeny);
cart_pointsX = -Par.MouseposX + (Par.ScreenWidth/Par.Screenx).*xi;
cart_pointsY = Par.ScreenHeight-Par.MouseposY - (Par.ScreenHeight/Par.Screeny).*yi;
cart_pointsZ = Par.ScreenDistanceBottom + ((Par.ScreenDistanceBottom-ScreenDistanceTop)/Par.Screeny).*yi;
[~, sphr_Horiz, ~] = cart2sph(cart_pointsZ,cart_pointsX,cart_pointsY);
[~, sphr_Vert, ~] = cart2sph(cart_pointsZ,cart_pointsY,cart_pointsX); 

rangeOversizedX = size(OversizedGratingRGB,1)*Par.RadPerPix;
rangeOversizedY = size(OversizedGratingRGB,2)*Par.RadPerPix;

anglesOversizedX = -(rangeOversizedX/2-Par.RadPerPix) : Par.RadPerPix : rangeOversizedX/2;
anglesOversizedY = -(rangeOversizedY/2-Par.RadPerPix) : Par.RadPerPix : rangeOversizedY/2;

[xang, yang] = meshgrid(anglesOversizedX, anglesOversizedY*-1);
morphedGrating = interp2(xang, yang, OversizedGratingRGB, sphr_Vert, sphr_Horiz);



%% Create a morphed red circle if this is the figure texture

% Create (round) circle on oversized Screen
[xe,ye] = meshgrid((-Par.Screenx:Par.Screenx)./Par.PixPerDeg, fliplr((-Par.Screenx:Par.Screenx)./Par.PixPerDeg));  
OversizedEcc = hypot(xe-Par.FigX,ye-Par.FigY); % convert to Eccentricity
OversizedCircle = zeros(size(xe));
OversizedCircle(OversizedEcc<Par.FigSize/2) = 1;

% Morph it
morphedCircle = interp2(xang, yang, OversizedCircle, sphr_Vert, sphr_Horiz);

imagesc(morphedCircle)

%% now show in Cogent TEMPORARY
cgloadlib
cgopen(Par.Screenx, Par.Screeny, 32,Par.Refresh , 0)
cogentGrating = reshape(morphedGrating',numel(morphedGrating),1);
cogentGrating = [cogentGrating,cogentGrating,cogentGrating];
cgloadarray(1,Par.Screenx,Par.Screeny,cogentGrating)
cgdrawsprite(1,0,0)
cgsetsprite(0)
cgflip(Par.grey)