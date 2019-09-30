function criterionvalue = CalcCriterion(input)

HitCounter = sum(input == 1);
CRCounter = sum(input == 2);
FACounter = sum(input == -1);
MissCounter = sum(input == 0);
Hitrate = HitCounter / (HitCounter + MissCounter);
FArate = FACounter / (FACounter + CRCounter);
if Hitrate == 0
    Hitrate = 0.01;
elseif Hitrate == 1
    Hitrate = 0.99;
elseif FArate == 0
    FArate = 0.01;
elseif FArate == 1
    FArate = 0.99;
end

criterionvalue = -0.5*(norminv(Hitrate)+ norminv(FArate));

end