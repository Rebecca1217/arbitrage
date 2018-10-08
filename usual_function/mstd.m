function outputMAPrice = mstd(priceSeries, x, lag)
%MAx input priceSeries and x, output is the x-day std
% leave the first (x-1) day NaN
% lag = 0 ,包括当前点,一共x个，lag = 1，不包括当前点，是除了当前点以外的之前x-1个点的sigma
narginchk(3,3); 
if x > length(priceSeries)
    error('x is too large for priceSeries!')
end

iDay = 1;
res = NaN(length(priceSeries) - lag, x - lag);
while iDay <= (x - lag)
    addColumn = [NaN(iDay - 1, 1); priceSeries(1 : (end - iDay + 1 - lag))];
    res(:, iDay) = addColumn;
    iDay = iDay + 1;
end

outputMAPrice = std(res, 0, 2);
outputMAPrice = [NaN(lag, 1); outputMAPrice];

end

