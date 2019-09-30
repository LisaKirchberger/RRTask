function color = getcolor(color1, color2, fraction)

% interpolate between two colors (color1 and color2), 
% fraction has to be between 0 and 1
% when fraction is 0, color = color1
% when fraction is 1, color = color2

if fraction < 0 || fraction > 1
    error('fraction must be between 0 and 1')
end

color = color1 + (color2 - color1) * fraction;