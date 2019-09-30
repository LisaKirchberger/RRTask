% Serial connections
Par.sport = serial('com3');
Par.running_port = [];
Par.mask_port = [];

% Task Parameters
Par.ITI = 2;                        % in seconds
Par.FA_Timeout = 5;                 % in seconds
Par.random_ITI = 8;                 % in seconds
Par.VisDuration = 1;                % in seconds
Par.Grace_duration = 0.2;           % in seconds

% Setup Parameters
gammaconversion = 'gammaconBoxes';
Par.ScreenID = 2;
Par.Screenx = 1280;
Par.Screeny = 720;
Par.Refresh = 60;
Par.ScreenWidth = 51;           % width of screen, in cm
Par.ScreenHeight = 29;          % height of screen, in cm
Par.ScreenDistance = 11.8;      % from mouse horizontally to the Screen
Par.minlum = eval([gammaconversion '(0,''rgb2lum'')']);
Par.maxlum = eval([gammaconversion '(1,''rgb2lum'')']);
Par.greylum = (Par.minlum+Par.maxlum)./2;
Par.lumrange = Par.maxlum - Par.minlum;
Par.grey = eval([gammaconversion '(Par.greylum,''lum2rgb'')']);
Par.grey = [Par.grey Par.grey Par.grey];
Par.contrast = 0.9;
Par.whitelum = Par.greylum + Par.contrast * Par.lumrange/2;
Par.blacklum = Par.greylum - Par.contrast * Par.lumrange/2;
Par.Optoport = [];
Par.PixPerDeg = (Par.Screenx/2)/atand((0.5*Par.ScreenWidth)/Par.ScreenDistance);
Par.DegPerPix = 1/Par.PixPerDeg;
Par.RadPerPix = Par.DegPerPix*pi/180;
Par.SpatialFreq = 0.08;
Par.Period = round(Par.PixPerDeg./Par.SpatialFreq);

Par.MouseposX = 25.05;          % distance of mouse eyes in cm from left screen edge
Par.MouseposY = 14.5;           % distance of mouse eyes in cm from bottom of the screen
Par.ScreenAngle = 90;           % in degrees, measured from table surface in front of screen to plane of screen (always 90 basically)
Par.ScreenDistanceBottom = 11.8;% distance of screen, in cm at bottom of screen (or perpendicular to the mouse, only differs if the Screen has an angle) 

