function [tdList,sigAdj] = cal_rtn(sig,beta,tddata,date,c_stD,c_edD,Cost,oriAsset)
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
% 从这开始到70行是将原始信号剔除假信号，得到真正的开平仓信号
sigOp = sig(:,1);
sigCl = sig(:,2);
% 开平仓信号所在行
sigLi = zeros(length(sigOp),3); % 方向，开平信号所在行
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
% 开始
stS = find(and(sigLi(:,2)<=stL,sigLi(:,3)>=stL),1,'first'); %这个合约作为主力合约之时的第一个开仓信号，主力之前就开仓，主力后才平仓的情况
if isempty(stS) %第一个合约可能有这个问题，因为是从某个品种的上市日开始的
    stS = find(and(sigLi(:,2)>=stL,sigLi(:,2)<=edL),1,'first'); % 如果没有上述情况，就找第一个才主力后才开仓的信号
    if isempty(stS) %在这个合约作为主力合约期间，没有发出开仓信号
        tdList = [date,zeros(length(sig),8)];
        tdList(:,end) = oriAsset;
        sigAdj = zeros(size(sig));
        return;
    end
end
if stS>1
    sigLi(1:stS-1,:) = []; %把该合约还没作为主力合约时候的开仓信号去掉
    sigLi(1,2) = stL-1;  % stL的时候才是主力合约，stL-1的时候还是上一个合约是主力合约呢，当前合约作为主力合约的第一次交易应该从stL开始吧？？？
end
% 结束
edS = find(and(sigLi(:,2)<=edL,sigLi(:,3)>=edL),1,'last'); %这个合约作为主力合约之后的最后一个开仓信号
if isempty(edS) %如果找不到这种信号：在这个时点之前平仓了，但是没有新的开仓信号
    edS = find(sigLi(:,3)<=edL,1,'last'); %在这个时点之前最后一个平仓信号所在行
    sigLi(edS+1:end,:) = [];
else
    sigLi(edS+1:end,:) = [];
    sigLi(end,3) = edL;
end


% 价格数据
tddata1 = tddata(:,1); %第一个品种
tddata2 = tddata(:,2); %第二个品种

% 回测
tdList = zeros(length(sig),8);
num = size(sigLi,1);
asset = oriAsset;
tdList(1:sigLi(1,2),8) = asset;
for i = 1:num %逐个信号计算
    opL = sigLi(i,2); %开仓信号所在行
    clL = sigLi(i,3); %平仓信号所在行
    sgn1 = sigLi(i,1); %开仓方向-第一个品种的方向
    sgn2 = -sigLi(i,1); %开仓方向-第二个品种的方向
    sgn = sigLi(i,1);
    if clL-opL>1 %不是当根开下根平的情况
        tdList(opL+1:clL-1,1) = sgn;
        tdList(opL+1,2) = 2-sgn; %多空开
        tdList(clL,2) = 3-sgn; %多空平
        % 开仓手数每天再平衡
        chgH1 = 0;
        chgH2 = 0;
        for d = opL:clL-1
            % 计算开仓手数
            hands = calOpenHands(closedata(d,:),Ratio(d),asset,contM1,contM2); %用前一天的收盘价去计算当天的手数
            if d==opL %开仓时的手数
                h1 = hands(1);
                h2 = hands(2);
            end
            if d>opL %相比于开仓时手数的变化
                chgH1 = hands(1)-h1;
                chgH2 = hands(2)-h2;
            end
            if abs(chgH1)>2 || abs(chgH2)>2 %两个品种中任意一个的持仓手数变化超过2手，则两个品种一起调仓
                tdList(d+1,5) = hands(1);
                tdList(d+1,6) = hands(2);
                h1 = hands(1);
                h2 = hands(2);
            else
                tdList(d+1,5) = h1;
                tdList(d+1,6) = h2;
            end
        end
        % 计算每日收益
        for d = opL+1:clL
            % 品种分别进行核算，然后加总
            h1 = tdList(d,5);
            h2 = tdList(d,6);
            if d==opL+1 %开仓
                % 品种1
                op1 = (tddata1(d)+sgn1*slip*unit1)*(1+sgn1*fixC)*contM1*h1; %开仓价
                cl1 = closedata(d,1)*contM1*h1; %当日平仓价
                % 品种2
                op2 = (tddata2(d)+sgn2*slip*unit2)*(1+sgn2*fixC)*contM2*h2; %开仓价
                cl2 = closedata(d,2)*contM2*h2; %当日平仓价
                % 当日盈亏
                tdList(d,7) = (-sgn1*op1+sgn1*cl1)+(-sgn2*op2+sgn2*cl2);
                tdList(d,8) = asset+tdList(d,7); %累计市值
                % 开仓价差
                tdList(d,3) = op1-op2;
            elseif d>opL+1 && d<=clL %非开平仓日
                % 品种1
                hChg1 = h1-tdList(d-1,5); %手数变化
                op1 = closedata(d-1,1)*contM1*h1; %用前一天的收盘价开仓
                cl1 = closedata(d,1)*contM1*h1; %当日平仓价
                %                 opChg1 = (tddata1(d)+sgn1*slip*unit1)*(1+sgn1*fixC)*contM1*hChg1; %开仓价
                % 感觉这个地方处理滑点，需要考虑进去hChg1的方向
                opChg1 = (tddata1(d)+sgn1*slip*unit1 * sign(hChg1))*(1+sgn1*fixC)*contM1*hChg1; %开仓价
                clChg1 = closedata(d,1)*contM1*hChg1; %平仓价
                % 品种2
                hChg2 = h2-tdList(d-1,6); %手数变化
                op2 = closedata(d-1,2)*contM2*h2; %用前一天的收盘价开仓
                cl2 = closedata(d,2)*contM2*h2; %当日平仓价
                %                 opChg2 = (tddata2(d)+sgn2*slip*unit2)*(1+sgn2*fixC)*contM2*hChg2; %开仓价
                opChg2 = (tddata2(d)+sgn2*slip*unit2 * sign(hChg2))*(1+sgn2*fixC)*contM2*hChg2; %开仓价
                clChg2 = closedata(d,2)*contM2*hChg2; %平仓价
                % 当日盈亏
                tdList(d,7) = (-sgn1*op1+sgn1*cl1)+(-sgn1*opChg1+sgn1*clChg1)+...
                    (-sgn2*op2+sgn2*cl2)+(-sgn2*opChg2+sgn2*clChg2);
                tdList(d,8) = tdList(d-1,8)+tdList(d,7); %累计市值
            end
            if d==clL %平仓
                % 平仓的时候，要把第二天平仓带来的收益计算到最后这一天里面
                % 品种1
                op1 = closedata(d,1)*contM1*h1; %用前一天的收盘价开仓
                cl1 = (tddata1(d+1)-sgn1*slip*unit1)*(1-sgn1*fixC)*contM1*h1; %平仓价
                % 品种2
                op2 = closedata(d,2)*contM2*h2;
                cl2 = (tddata2(d+1)-sgn2*slip*unit2)*(1-sgn2*fixC)*contM2*h2;
                % 当日盈亏
                tdList(d,7) = tdList(d,7)+(-sgn1*op1+sgn1*cl1)+(-sgn2*op2+sgn2*cl2);
                tdList(d,8) = tdList(d,8)+(-sgn1*op1+sgn1*cl1)+(-sgn2*op2+sgn2*cl2);
                % 平仓价差
                tdList(d,4) = op1-op2;
            end
        end
    end
    if clL-opL==1 %当根开下根平
        tdList(opL+1,1) = sgn;
        tdList(opL+1,2) = 5.5-0.5*sgn;
        hands = calOpenHands(closedata(opL,:),Ratio(opL),asset,contM1,contM2); %用前一天的收盘价去计算当天的手数
        tdList(opL+1,5) = hands(1);
        tdList(opL+1,6) = hands(2);
        % 品种1
        h1 = hands(1);
        op1 = (tddata1(opL+1)+sgn1*slip*unit1)*(1+sgn1*fixC)*contM1*h1; %开仓价
        cl1 = (tddata1(clL+1)+sgn1*slip*unit1)*(1+sgn1*fixC)*contM1*h1; %平仓价
        % 品种2
        h2 = hands(2);
        op2 = (tddata2(opL+1)+sgn2*slip*unit2)*(1+sgn2*fixC)*contM2*h2; %开仓价
        cl2 = (tddata2(clL+1)+sgn2*slip*unit2)*(1+sgn2*fixC)*contM2*h2; %平仓价
        % 当日盈亏
        tdList(opL+1,7) = (-sgn1*op1+sgn1*cl1)+(-sgn2*op2+sgn2*cl2);
        tdList(opL+1,8) = asset+tdList(opL+1,7);
        % 开平仓价差
        tdList(opL+1,3) = op1-op2;
        tdList(opL+1,4) = cl1-cl2;
    end
    
    % 市值更新
    asset = tdList(clL,8);
    % 市值填充
    if i<num
        tdList(clL+1:sigLi(i+1,2),8) = asset;
    else
        tdList(clL:end,8) = asset;
    end
    
end

tdList = [date,tdList];

% 调整sig
sigAdj = zeros(size(sig));
sigAdj(sigLi(:,2),1) = sigLi(:,1);
sigAdj(sigLi(:,3),2) = -sigLi(:,1);






