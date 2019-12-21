global Par

% Task Parameters
Par.ITI = 3;                        % in seconds
Par.FA_Timeout = 5;                 % in seconds
Par.random_ITI = 3;                 % in seconds

% Setup Parameters
gammaconversion = 'gammaconBoxes';
Par.ScreenID = 1;
%Get screen dimensions:
Pix_SS = get(0,'MonitorPositions');
Par.Screenx = Pix_SS(Par.ScreenID,3); 
Par.Screeny =  Pix_SS(Par.ScreenID,4);
Par.Refresh = 60;
Par.ScreenWidth = 51;           % width of screen, in cm
Par.ScreenHeight = 29;          % height of screen, in cm

Par.minlum = eval([gammaconversion '(0,''rgb2lum'')']);
Par.maxlum = eval([gammaconversion '(1,''rgb2lum'')']);
Par.greylum = (Par.minlum+Par.maxlum)./2;
Par.lumrange = Par.maxlum - Par.minlum;
Par.grey = eval([gammaconversion '(Par.greylum,''lum2rgb'')']);
Par.grey = [Par.grey Par.grey Par.grey];
Par.contrast = 0.8;
Par.whitelum = Par.greylum + Par.contrast * Par.lumrange/2;
Par.white = eval([gammaconversion '(Par.whitelum,''lum2rgb'')']);
Par.white = [Par.white Par.white Par.white];
Par.blacklum = Par.greylum - Par.contrast * Par.lumrange/2;
Par.PixPerDeg = (Par.Screenx/2)/atand((0.5*Par.ScreenWidth)/Par.ScreenDistance);
Par.DegPerPix = 1/Par.PixPerDeg;
Par.RadPerPix = Par.DegPerPix*pi/180;
Par.morphingOn = 0;

Par.FigSize = 15;
Par.RelativeApertureSizes = [1 2 4 8]; % 1 Bg same area as Fig, 2 Bg twice surface area as Fig, 4 Bg 4 times area as Fig, etc. 
counter = 0;
for p = Par.RelativeApertureSizes
   counter = counter + 1;
   surfacearea = (Par.FigSize/2)^2*pi;
   Par.ApertureSizes(counter) = sqrt((p*surfacearea+surfacearea)/pi)*2;
end
Par.SpatialFreq = 0.25;
Par.Period = round(Par.PixPerDeg./Par.SpatialFreq);
Par.PhaseOpt = 0:0.5*pi:2*pi-0.5*pi;

% 
% % Par.MouseposX = 25.05;          % distance of mouse eyes in cm from left screen edge
% % Par.MouseposY = 14.5;           % distance of mouse eyes in cm from bottom of the screen
% % Par.ScreenAngle = 90;           % in degrees, measured from table surface in front of screen to plane of screen (always 90 basically)
% % Par.ScreenDistanceBottom = 11.8;% distance of screen, in cm at bottom of screen (or perpendicular to the mouse, only differs if the Screen has an angle) 
% % 


