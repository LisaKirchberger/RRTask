% Open a Screen
screenNumber=max(Screen('Screens'));
Resolution = Screen('Resolution', screenNumber);
[window, rect]=Screen('OpenWindow',0);

xpix = Resolution.width;
ypix = Resolution.height;
white=WhiteIndex(screenNumber);
black=BlackIndex(screenNumber);
gray=round((white+black)/2);
inc=white-gray;
% Parameters for the grating
CycPerPix=0.05;
cyclespersecond=1;
angle=0; %in degrees
movieDurationSecs=20; % Abort demo after 20 seconds.
texsize=300; % Half-Size of the grating image.
PixPerCyc=ceil(1/CycPerPix); % pixels/cycle, rounded up.
fr=CycPerPix*2*pi;
visiblesize=2*texsize+1;
visible2size=visiblesize/2;

% Create one single static grating image:
[x,y]=meshgrid(-xpix/2:xpix/2 + PixPerCyc, 1);
grating=gray + inc*cos(fr*x);
% Store grating in texture:
gratingtex=Screen('MakeTexture', window, grating);






try
    
    
    dur=1;
    
    xprop = 0.6;
    yprop = 0.25;
    
    %Screen('FillPoly',window,rand(3,1)*255,[xpix round(xprop*xpix) round(xprop*xpix) xpix; 0 round(yprop*ypix) round((1-yprop)*ypix) ypix]')
    Screen('FillPoly',window,gratingtex,[xpix round(xprop*xpix) round(xprop*xpix) xpix; 0 round(yprop*ypix) round((1-yprop)*ypix) ypix]')
    
    Screen('FillPoly',window,gratingtex,[0 round((1-xprop)*xpix) round((1-xprop)*xpix) 0; 0 round(yprop*ypix) round((1-yprop)*ypix) ypix]')
    
    Screen('Flip',window)
    WaitSecs(dur)
    
    sca
    Priority(0)
    
catch
    
    sca;
    Priority(0);
    psychrethrow(psychlasterror);
    
end