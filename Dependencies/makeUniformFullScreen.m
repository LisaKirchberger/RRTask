function cogentImage = makeUniformFullScreen(Luminance,RedCircle,CircleSize,gammaconversion)

global Par


if RedCircle == 1
    
    
    %% Create a uniform background with morphed red circle

    %% Create (round) circle on oversized Screen
    [xe,ye] = meshgrid((-Par.Screenx:Par.Screenx)./Par.PixPerDeg, fliplr((-Par.Screenx:Par.Screenx)./Par.PixPerDeg));
    OversizedEcc = hypot(xe-Par.FigX,ye-Par.FigY); % convert to Eccentricity
    OversizedCircle = zeros(size(xe));
    OversizedCircle(OversizedEcc<CircleSize/2) = 1;
    
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
        
        rangeOversizedX = size(OversizedCircle,1)*Par.RadPerPix;
        rangeOversizedY = size(OversizedCircle,2)*Par.RadPerPix;
        
        anglesOversizedX = -(rangeOversizedX/2-Par.RadPerPix) : Par.RadPerPix : rangeOversizedX/2;
        anglesOversizedY = -(rangeOversizedY/2-Par.RadPerPix) : Par.RadPerPix : rangeOversizedY/2;
        
        [xang, yang] = meshgrid(anglesOversizedX, anglesOversizedY*-1);
        morphedCircle = logical(interp2(xang, yang, OversizedCircle, sphr_Vert, sphr_Horiz));
    else
        % Put in correct dimensions
        morphedCircle = logical(OversizedCircle(ceil((size(OversizedCircle,1)-Par.Screeny)./2):size(OversizedCircle,1)-ceil((size(OversizedCircle,1)-Par.Screeny)./2),...
            ceil((size(OversizedCircle,2)-Par.Screenx)./2):size(OversizedCircle,2)-ceil((size(OversizedCircle,1)-Par.Screenx)./2)));
    end
    
    Screen = ones(Par.Screeny, Par.Screenx).*Luminance; %#ok<NASGU>
    ScreenRGB = eval([gammaconversion '(Screen,''lum2rgb'')']); 
    % convert to cogent structure
    cogentImage_R = ScreenRGB;
    cogentImage_R(morphedCircle) = 1;
    cogentImage_GB = ScreenRGB;
    cogentImage_GB(morphedCircle) = 0;
    cogentImage_R = reshape(cogentImage_R',numel(cogentImage_R),1);
    cogentImage_GB = reshape(cogentImage_GB',numel(cogentImage_GB),1);
    cogentImage = [cogentImage_R, cogentImage_GB, cogentImage_GB];

    
elseif RedCircle == 2
    
    %% Create a uniform background with morphed blue circle

    %% Create (round) circle on oversized Screen
    [xe,ye] = meshgrid((-Par.Screenx:Par.Screenx)./Par.PixPerDeg, fliplr((-Par.Screenx:Par.Screenx)./Par.PixPerDeg));
    OversizedEcc = hypot(xe-Par.FigX,ye-Par.FigY); % convert to Eccentricity
    OversizedCircle = zeros(size(xe));
    OversizedCircle(OversizedEcc<CircleSize/2) = 1;

    %% Morph the grating, convert Cartesian to spherical coordinates
    % In image space, x and y are width and height of monitor and z is the distance from the eye. I want Theta to correspond to azimuth and Phi to
    % correspond to elevation, but these are measured from the x-axis and x-y plane, respectively. So I need to exchange the axes prior to
    % converting to spherical coordinates: orig (image) -> for conversion to spherical coords
    % Z -> X          X -> Y              Y -> Z
    if ~(isfield(Par,'morphingOn') && Par.morphingOn ==0)
        ScreenDistanceTop = Par.ScreenDistanceBottom - (Par.ScreenHeight*sin(deg2rad(90-Par.ScreenAngle))); % Calculate the Distance of the Screen at the top of the Screen (only different from the distance to the bottom if the Screen is angled, so not at 90 degrees)
        [xi,yi] = meshgrid(1:Par.Screenx,1:Par.Screeny);
        cart_pointsX = -Par.MouseposX + (Par.ScreenWidth/Par.Screenx).*xi;
        cart_pointsY = Par.ScreenHeight-Par.MouseposY - (Par.ScreenHeight/Par.Screeny).*yi;
        cart_pointsZ = Par.ScreenDistanceBottom + ((Par.ScreenDistanceBottom-ScreenDistanceTop)/Par.Screeny).*yi;
        [~, sphr_Horiz, ~] = cart2sph(cart_pointsZ,cart_pointsX,cart_pointsY);
        [~, sphr_Vert, ~] = cart2sph(cart_pointsZ,cart_pointsY,cart_pointsX);
        
        rangeOversizedX = size(OversizedCircle,1)*Par.RadPerPix;
        rangeOversizedY = size(OversizedCircle,2)*Par.RadPerPix;
        
        anglesOversizedX = -(rangeOversizedX/2-Par.RadPerPix) : Par.RadPerPix : rangeOversizedX/2;
        anglesOversizedY = -(rangeOversizedY/2-Par.RadPerPix) : Par.RadPerPix : rangeOversizedY/2;
        
        [xang, yang] = meshgrid(anglesOversizedX, anglesOversizedY*-1);
        morphedCircle = logical(interp2(xang, yang, OversizedCircle, sphr_Vert, sphr_Horiz));
    else
        % Put in correct dimensions
        morphedCircle = logical(OversizedCircle(ceil((size(OversizedCircle,1)-Par.Screenx)./2):size(OversizedCircle,1)-ceil((size(OversizedCircle,1)-Par.Screenx)./2),...
            ceil((size(OversizedCircle,2)-Par.Screeny)./2):size(OversizedCircle,2)-ceil((size(OversizedCircle,1)-Par.Screeny)./2)));       
    end
        
    Screen = ones(Par.Screeny, Par.Screenx).*Luminance; %#ok<NASGU>
    ScreenRGB = eval([gammaconversion '(Screen,''lum2rgb'')']); 
    % convert to cogent structure
    cogentImage_B = ScreenRGB;
    cogentImage_B(morphedCircle) = 1;
    cogentImage_RG = ScreenRGB;
    cogentImage_RG(morphedCircle) = 0;
    cogentImage_B = reshape(cogentImage_B',numel(cogentImage_B),1);
    cogentImage_RG = reshape(cogentImage_RG',numel(cogentImage_RG),1);
    cogentImage = [cogentImage_RG, cogentImage_RG, cogentImage_B];

    
    
else
    
    %% Create an normal sized Full Screen
    Screen = ones(Par.Screeny, Par.Screenx).*Luminance; %#ok<NASGU>
    ScreenRGB = eval([gammaconversion '(Screen,''lum2rgb'')']); 
    
    % convert to cogent structure
    cogentImage = reshape(ScreenRGB',numel(ScreenRGB),1);
    cogentImage = [cogentImage,cogentImage,cogentImage];

end

end