function out = gammaconBoxes(val,whichway)

%Convert rgb to luminance or vice versa using a gamma function
%values taken on 17/01/2012 in the psych room at contrast 85%, bright 50%
%Trinitron, T5400

%String argument can be either 'rgb2lum' or 'lum2rgb'

if nargin<2
    %Default is rgb to luminance conversion
    whichway = 'rgb2lum';
end

%Enter the best fitting values here from gammafit
a = 0.02; %The baseline luminace level at 0 RGB
b = 247.4; 
g = 1.941;

%Run the conversion
if strcmp('rgb2lum',whichway)
    out = a+b.*(val.^g); 
elseif strcmp('lum2rgb',whichway)
    out = exp((log(val-a)-log(b))./g);
else
    disp('Invalid string input!')
    out = NaN;
    return
end

return
