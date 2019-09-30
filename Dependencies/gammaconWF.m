function out = gammaconWF(val,whichway)

%Convert rgb to luminance or vive versa using a gamma function
%values taken on 19/03/2015 in the imaging room at backlight 25, contrast 50%, bright 50%
%55inch imaging screen

%String argument can be either 'rgb2lum' or 'lum2rgb'
%% Matt's script 17/03/2017
%String argument can be either 'rgb2lum' or 'lum2rgb'

if nargin<2
    %Default is rgb to luminance conversion
    whichway = 'rgb2lum';
end

%Enter the best fitting values here from gammafit
a = 0.02; %The baseline luminace level at 0 RGB
b = 255.1; 
g = 2.135;

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


%% OLD
% a  = 255.1;
% b = 2.135;
% % if val == 0
% %     out = zeros(size(val, 1), size(val, 2));
% % else
% if strcmp('rgb2lum',whichway)
%     out = a.*(val.^b);
% elseif strcmp('lum2rgb',whichway)
%     %     out = exp((log(val)-log(a))./(b+0.072));
%     out = exp((log(val)-log(a))./b);
% else
%     disp('Invalid string input!')
%     out = 0;
%     return
% end
% end
% return