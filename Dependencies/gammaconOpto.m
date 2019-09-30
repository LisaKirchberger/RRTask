function out = gammaconOpto(val,whichway)

%Convert rgb to luminance or vice versa using a gamma function
%values taken on 17/01/2012 in the psych room at contrast 85%, bright 50%
%Trinitron, T5400

%String argument can be either 'rgb2lum' or 'lum2rgb'

if nargin<2
    %Default is rgb to lumiannce conversion
    whichway = 'rgb2lum';
end

%Enter the best fitting values here from gammafit
% 03.03.2017 Lisa: these are the values for the OPTO setup
a = 0.221; 
b = 186.481;  
g = 2.21492; 

%Run the conversion
if strcmp('rgb2lum',whichway)
    out = a+b.*(val.^g); 
elseif strcmp('lum2rgb',whichway)
    valminarounded = round((val-a)*1000)/1000;
    out = exp((log(valminarounded)-log(b))./g);
else
    disp('Invalid string input!')
    out = NaN;
    return
end

return