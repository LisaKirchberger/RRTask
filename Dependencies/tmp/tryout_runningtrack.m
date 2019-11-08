%%
Par.Screenx = 1920;
Par.Screeny = 1200;
Par.ScreenDistance = 11;  % distance of screen, in cm
Par.ScreenWidth = 51;     % width of screen, in cm
Par.ScreenHeight = 31;    % height of screen, in cm
Par.PixPerDeg = (Par.Screenx/2)/atand((0.5*Par.ScreenWidth)/Par.ScreenDistance);
Par.SpatialFreq = 0.08;
Par.Period = round(Par.PixPerDeg./Par.SpatialFreq);
Orientation =0;

Frequency_start = 0.002;
Frequency_end = 1;
%%
 Fs = 14;
 t = 0:1/Fs:500;
 f_in_start = 0.001;
 f_in_end = 0.04;
 f_in = linspace(f_in_start, f_in_end, length(t));
 phase_in = cumsum(f_in/Fs);
 y = sin(2*pi*phase_in);
 
figure; plot(t,y)
 %%
 
 [x,y]=meshgrid(-Par.Screenx:Par.Screenx);
x_ori =x*cosd(Orientation)+y*sind(Orientation);
OversizedGrating =sin(2*pi*(1/Par.Period)*x_ori + Phase);
figure;imagesc(OversizedGrating)
OversizedGrating =sin(2*pi*(x_ori/Par.Period) + Phase);
figure;imagesc(OversizedGrating)

OversizedGrating =sin(2*pi*cumsum(x_ori)/Par.Period);
figure;imagesc(OversizedGrating)