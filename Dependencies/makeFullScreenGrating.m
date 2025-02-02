function cogentGrating = makeFullScreenGrating(Orientation,Phase,RedCircle,gammaconversion)

global Par

%% Create an oversized Full Screen Grating for the Figure
[x,y]=meshgrid(-Par.Screenx:Par.Screenx);
x_ori =x*cosd(Orientation)+y*sind(Orientation);
OversizedGrating =sin(2*pi*(1/Par.Period)*x_ori + Phase);

%% Adjust to max and min Luminance of the Screen
OversizedGrating =  OversizedGrating - min( OversizedGrating(:)); % set range of OversizedGrating between [0, inf)
OversizedGrating =  OversizedGrating ./ max( OversizedGrating(:)) ; % set range of OversizedGrating between [0, 1]
OversizedGrating =  OversizedGrating .* diff([Par.blacklum Par.whitelum]) ; % set range of OversizedGrating between [0, LuminanceRange]
OversizedGrating =  OversizedGrating + Par.blacklum; %#ok<NASGU> % shift range of OversizedGrating to minimal luminance
OversizedGratingRGB = eval([gammaconversion '(OversizedGrating,''lum2rgb'')']);

if ~(isfield(Par,'morphingOn') && Par.morphingOn ==0)
    
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
else
    % Put in correct dimensions
    morphedGrating = (OversizedGratingRGB(ceil((size(OversizedGratingRGB,1)-Par.Screeny)./2):size(OversizedGratingRGB,1)-ceil((size(OversizedGratingRGB,1)-Par.Screeny)./2),...
        ceil((size(OversizedGratingRGB,2)-Par.Screenx)./2):size(OversizedGratingRGB,2)-ceil((size(OversizedGratingRGB,1)-Par.Screenx)./2)));

end
%% Create a morphed red circle if this is the figure texture

if RedCircle == 1
    
    % Create (round) circle on oversized Screen
    [xe,ye] = meshgrid((-Par.Screenx:Par.Screenx)./Par.PixPerDeg, fliplr((-Par.Screenx:Par.Screenx)./Par.PixPerDeg));
    OversizedEcc = hypot(xe-Par.FigX,ye-Par.FigY); % convert to Eccentricity
    OversizedCircle = zeros(size(xe));
    OversizedCircle(OversizedEcc<Par.FigSize/2) = 1;
    
    if ~(isfield(Par,'morphingOn') && Par.morphingOn ==0)
        % Morph it
        morphedCircle = logical(interp2(xang, yang, OversizedCircle, sphr_Vert, sphr_Horiz));
    else
        % Put in correct dimensions
        morphedCircle = logical(OversizedCircle(ceil((size(OversizedCircle,1)-Par.Screeny)./2):size(OversizedCircle,1)-ceil((size(OversizedCircle,1)-Par.Screeny)./2),...
            ceil((size(OversizedCircle,2)-Par.Screenx)./2):size(OversizedCircle,2)-ceil((size(OversizedCircle,1)-Par.Screenx)./2)));
    end
    
    % convert to cogent structure
    morphedGrating_R = morphedGrating;
    morphedGrating_R(morphedCircle) = 1;
    morphedGrating_GB = morphedGrating;
    morphedGrating_GB(morphedCircle) = 0;
    cogentGrating_R = reshape(morphedGrating_R',numel(morphedGrating_R),1);
    cogentGrating_GB = reshape(morphedGrating_GB',numel(morphedGrating_GB),1);
    cogentGrating = [cogentGrating_R, cogentGrating_GB, cogentGrating_GB];

elseif RedCircle == 3
    
    %% Create a blue square
    Square = zeros(Par.Screeny, Par.Screenx);
    if Par.FigSide == 1 %right
        Square(:,Par.Screenx/2:end) = 1;
    else
        Square(:,1:Par.Screenx/2) = 1;
    end
    Square = logical(Square);
    
   % convert to cogent structure
    morphedGrating_B = morphedGrating;
    morphedGrating_B(Square) = 1;
    morphedGrating_RG = morphedGrating;
    morphedGrating_RG(Square) = 0;
    cogentGrating_B = reshape(morphedGrating_B',numel(morphedGrating_B),1);
    cogentGrating_RG = reshape(morphedGrating_RG',numel(morphedGrating_RG),1);
    cogentGrating = [cogentGrating_RG, cogentGrating_RG, cogentGrating_B];
    
elseif RedCircle == 4
    
    %% Create a blue square on the other side
    Square = zeros(Par.Screeny, Par.Screenx);
    if Par.FigSide == 1 
        Square(:,1:Par.Screenx/2) = 1;
    else
        Square(:,Par.Screenx/2:end) = 1; 
    end
    Square = logical(Square);
    
   % convert to cogent structure
    morphedGrating_B = morphedGrating;
    morphedGrating_B(Square) = 1;
    morphedGrating_RG = morphedGrating;
    morphedGrating_RG(Square) = 0;
    cogentGrating_B = reshape(morphedGrating_B',numel(morphedGrating_B),1);
    cogentGrating_RG = reshape(morphedGrating_RG',numel(morphedGrating_RG),1);
    cogentGrating = [cogentGrating_RG, cogentGrating_RG, cogentGrating_B];

else
    
    % convert to cogent structure
    cogentGrating = reshape(morphedGrating',numel(morphedGrating),1);
    cogentGrating = [cogentGrating,cogentGrating,cogentGrating];
    
end

end