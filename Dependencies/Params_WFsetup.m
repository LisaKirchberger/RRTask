global Par

% Serial connections
Par.sport = serial('com9');
Par.running_port = serial('com10');

% Task Parameters
Par.ITI = 6;                        % in seconds
Par.FA_Timeout = 5;                 % in seconds
Par.random_ITI = 2;                 % in seconds
Par.maxSpeed = 5;
Par.DistanceThres = 1;

% Setup Parameters
gammaconversion = 'gammaconWF';
Par.ScreenID = 1;
Par.Screenx = 1920;
Par.Screeny = 1080;
Par.Refresh = 60;
Par.ScreenDistance = 14;            % distance of screen, in cm
Par.ScreenWidth = 122;              % width of screen, in cm
Par.ScreenHeight = 68;              % height of screen, in cm
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

Par.MouseposX = 61;                 % distance of mouse eyes in cm from left screen edge
Par.MouseposY = 34;                 % distance of mouse eyes in cm from bottom of the screen
Par.ScreenAngle = 90;               % in degrees, measured from table surface in front of screen to plane of screen (always 90 basically)
Par.ScreenDistanceBottom = 14;      % distance of screen, in cm at bottom of screen (or perpendicular to the mouse, only differs if the Screen has an angle) 


% dasbit parameters
Par.Camport = 0;
Par.Shutterport = 1;
Par.Recport = 2;
Par.Stimbitport = 3;
Par.Optoport = 4;


% other imaging parameters
Par.Exposure = str2double(Log.Exposure);
Par.PreStimTime = 0.5;      % in seconds
Par.PostStimTime = 0.2;

% Audio
Par.Aud_nchannels = 1;                  % number of channels, 1=mono, 2=stereo;
Par.Aud_nbits = 8;                      % Number of bits per sample, 8 or 16
Par.Aud_sampfrequency = 11025;          % number of samples per second, e.g. 8000, 11025, 22050 and 44100
Par.Aud_nbuffers = 2;                   % number of sound buffers


%% make a JSON file

% define the fields
fields.project = 'Mouse_Plasticity';
fields.dataset = 'Widefield_Data';
fields.subject = Log.Mouse;
fields.condition = 'awake';
fields.investigator = 'LisaKirchberger';
fields.date = Log.Date;
fields.setup = 'WF';
fields.stimulus = Log.Task;
expname = Log.Logfile_name;
SaveDataFolder = Par.Save_Location2;

run GenerateJSONfile
