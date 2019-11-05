% By default, we mask the grating by a transparency mask:
drawmask=1;

% Grating cycles/pixel
f=0.005;

% Speed of grating in cycles per second:
cyclespersecond=2;

% Angle of the grating: We default to 30 degrees.
angle=0;

movieDurationSecs=40; % Abort demo after 20 seconds.


try
    AssertOpenGL;
    
    % Get the list of screens and choose the one with the highest screen number.
    %screenNumber=max(Screen('Screens'));
    screenNumber = 1;
    Resolution = Screen('Resolution', screenNumber);
    xpix = Resolution.width;
    ypix = Resolution.height;
    
    
    % Find the color values which correspond to white and black.
    white=WhiteIndex(screenNumber);
    black=BlackIndex(screenNumber);
    
    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
    gray=round((white+black)/2);
    
    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if gray == white
        gray=white / 2;
    end
    
    inc=white-gray;
    
    % Open a double buffered fullscreen window with a gray background:
    [w, screenRect]=Screen('OpenWindow',screenNumber, gray);
    
    % Calculate parameters of the grating:
    p=ceil(1/f); % pixels/cycle, rounded up.
    fr=f*2*pi;
    visiblesize=xpix;
    visible2size=xpix;
    
    % Create one single static grating image:
    % MK: We only need a single texture row (i.e. 1 pixel in height) to
    % define the whole grating! If srcRect in the Drawtexture call below is
    % "higher" than that (i.e. visibleSize >> 1), the GPU will
    % automatically replicate pixel rows. This 1 pixel height saves memory
    % and memory bandwith, ie. potentially faster.
    [x,y]=meshgrid(-xpix/2:xpix/2 + p, 1);
    grating=gray + inc*cos(fr*x);
    
    [x2,y2]=meshgrid(-xpix/2:xpix/2 + p, 1);
    grating2=gray + inc*cos(fr*x2);
    
    
    % Store grating in texture:
    gratingtex=Screen('MakeTexture', w, grating);
    grating2tex=Screen('MakeTexture', w, grating2);
    
%     % Create a single  binary transparency mask and store it to a texture:
    xprop = 0.6;
    yprop = 0.25;
    xt1 = [xpix round(xprop*xpix) round(xprop*xpix) xpix];
    yt1 = [0 round(yprop*ypix) round((1-yprop)*ypix) ypix];
    Mask1 = poly2mask(xt1,yt1,ypix, xpix);
    xt2 = [0 round((1-xprop)*xpix) round((1-xprop)*xpix) 0]; 
    yt2 = [0 round(yprop*ypix) round((1-yprop)*ypix) ypix];
    Mask2 = poly2mask(xt2,yt2,ypix, xpix);
    Maskt(:,:,2) = (~(Mask1+Mask2)).* white;
    Maskt(:,:,1) = ones(size(Maskt,1), size(Maskt,2)).*gray;
    masktex=Screen('MakeTexture', w, Maskt);
    Screen('Blendfunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % Definition of the drawn rectangle on the screen:
    dstRect=[0 0 xpix/2 ypix];
    %dstRect=CenterRect(dstRect, screenRect);
    
    % Definition of the drawn rectangle on the screen:
    dst2Rect = [xpix/2 0 xpix ypix];
    %dst2Rect=[0 0 visible2size visible2size];
    %dst2Rect=CenterRect(dst2Rect, screenRect);
    
    % Query duration of monitor refresh interval:
    ifi=Screen('GetFlipInterval', w);
    
    waitframes = 1;
    waitduration = waitframes * ifi;
    
    % Recompute p, this time without the ceil() operation from above.
    % Otherwise we will get wrong drift speed due to rounding!
    p=1/f; % pixels/cycle
    
    % Translate requested speed of the grating (in cycles per second)
    % into a shift value in "pixels per frame", assuming given
    % waitduration: This is the amount of pixels to shift our "aperture" at
    % each redraw:
    shiftperframe= cyclespersecond * p * waitduration;
    
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
    vbl=Screen('Flip', w); 
    
    % We run at most 'movieDurationSecs' seconds if user doesn't abort via
    % keypress.
    vblendtime = vbl + movieDurationSecs;
    i=0;
    
    % Animationloop:
    while (vbl < vblendtime) && ~KbCheck
        
        % Shift the grating by "shiftperframe" pixels per frame:
        
        i=i+1;
        Currpos = Mousedistance(i);
        % read in the mouse position
        xoffset = mod(Currpos*shiftperframe,p);
      
        
        
        % Define shifted srcRect that cuts out the properly shifted rectangular
        % area from the texture:
        srcRect=[xoffset 0 xoffset + visiblesize visiblesize];
        src2Rect=[-xoffset 0 -xoffset + visible2size visible2size];
        
        % Draw grating texture, rotated by "angle":
        Screen('DrawTexture', w, gratingtex, srcRect, dstRect, angle);
        
        Screen('DrawTexture', w, grating2tex, src2Rect, dst2Rect, angle);
        
        if drawmask==1
            % Draw aperture over grating:
            Screen('DrawTexture', w, masktex, [0 0 xpix ypix],[0 0 xpix ypix], 0);
        end;
        
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
    end;
    
    Priority(0);
    sca;
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above. Importantly, it closes the onscreen window if its open.
    sca;
    Priority(0);
    psychrethrow(psychlasterror);
end %try..catch..
