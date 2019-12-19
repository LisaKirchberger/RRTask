global Par

% Serial connections
Par.sport = serial('com16');
Par.running_port = serial('com12');

% Task Parameters
Par.ITI = 4;                        % in seconds
Par.FA_Timeout = 5;                 % in seconds
Par.random_ITI = 2;                 % in seconds
Par.maxSpeed = 5;
Par.DistanceThres = 1;

% Setup Parameters
gammaconversion = 'gammaconOpto';
Par.ScreenID = 1;
Par.Screenx = 1920;
Par.Screeny = 1200;
Par.Refresh = 60;
Par.ScreenDistance = 11;  % distance of screen, in cm
Par.ScreenWidth = 51;     % width of screen, in cm
Par.ScreenHeight = 31;    % height of screen, in cm
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


Par.FigSize = 35;
Par.RelativeApertureSizes = [1 2 4 8]; % 1 Bg same area as Fig, 2 Bg twice surface area as Fig, 4 Bg 4 times area as Fig, etc. 
counter = 0;
for p = Par.RelativeApertureSizes
   counter = counter + 1;
   surfacearea = (Par.FigSize/2)^2*pi;
   Par.ApertureSizes(counter) = sqrt((p*surfacearea+surfacearea)/pi)*2;
end
Par.SpatialFreq = 0.08;
Par.Period = round(Par.PixPerDeg./Par.SpatialFreq);
Par.PhaseOpt = 0:0.5*pi:2*pi-0.5*pi;

Par.MouseposX = 25.05;          % distance of mouse eyes in cm from left screen edge
Par.MouseposY = 14.5;           % distance of mouse eyes in cm from bottom of the screen
Par.ScreenAngle = 90;           % in degrees, measured from table surface in front of screen to plane of screen (always 90 basically)
Par.ScreenDistanceBottom = 11.8;% distance of screen, in cm at bottom of screen (or perpendicular to the mouse, only differs if the Screen has an angle) 

% Audio
Par.Aud_nchannels = 1;                  % number of channels, 1=mono, 2=stereo;
Par.Aud_nbits = 8;                      % Number of bits per sample, 8 or 16
Par.Aud_sampfrequency = 11025;          % number of samples per second, e.g. 8000, 11025, 22050 and 44100
Par.Aud_nbuffers = 2;                   % number of sound buffers
