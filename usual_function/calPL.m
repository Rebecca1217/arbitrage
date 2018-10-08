function [outputArg1,outputArg2] = calPL(sig,inputArg2)
% tdList:持仓方向，开仓时点，开仓价差，平仓价差, 品种1手数，品种2手数，当日盈亏金额,累计资产
% 用开仓前一天的收盘价计算开仓手数
% c_edD是旧合约的最后一天，旧合约在平仓时，应该在下一日平仓

% 交易成本
fixC = Cost.fix;
slip = Cost.float;
unit1 = Cost.unit1; %最小变动价位
unit2 = Cost.unit2;
contM1 = Cost.contM1; %合约乘数
contM2 = Cost.contM2;

% 交易价
closedata = tddata(:,3:4); %收盘价
tddata = tddata(:,1:2); %成交价
Ratio = beta;

% 开平仓信号
sigOp = sig(:,1); % 开仓标记
sigCl = sig(:,2); % 平仓标记
sigLi = zeros(length(sigOp),3); % 方向，开平信号所在行 共3列，第一列信号方向，第二列开仓行号，第三列对应平仓行号
c = 1;
for t = 1:size(sigLi,1)
    opL = find(sigOp(c:end)~=0,1,'first')+c-1;
    if isempty(opL) || opL==length(sigOp)
        break;
    else
        sigLi(t,1) = sigOp(opL);
        sigLi(t,2) = opL;
    end
    clL = find(sigCl(opL+1:end)==-sigOp(opL),1,'first')+opL;
    if isempty(clL)
        sigLi(t,3) = size(sigLi,1);
        break;
    else
        sigLi(t,3) = clL;
        c = clL;
    end
end
sigLi(sigLi(:,1)==0,:) = [];
% 开平仓信号根据合约做主力的时间进行调整
stL = find(date==c_stD,1);
edL = find(date==c_edD,1);





end

