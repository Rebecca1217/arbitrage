function sigLi = lossStop(sigLi, tddata, beta, lossRatio, Cost, oriAsset)
%LOSSSTOP 对输入信号进行止损调整

% 计算daily PL

% 交易成本
fixC = Cost.fix;
slip = Cost.float;
unit1 = Cost.unit1; %最小变动价位
unit2 = Cost.unit2;
contM1 = Cost.contM1; %合约乘数
contM2 = Cost.contM2;

% 价格数据
closedata = tddata(:,3:4); %收盘价
tddata = tddata(:,1:2); %成交价
tddata1 = tddata(:,1); %第一个品种
tddata2 = tddata(:,2); %第二个品种

Ratio = beta;

% 回测
tdList = zeros(size(tddata, 1),9); % 添加第九列，表示一次交易（信号区间）的累计盈亏
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
        % 至此得到了一个信号段内的全部手数
        % 计算每日收益
        d = opL + 1;
        while d <= clL
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
                % 本次交易（一个新号段）累计盈亏
                tdList(d, 9) = tdList(d - 1, 9) + tdList(d, 7);
                tdList(d,8) = asset+tdList(d,7); %累计市值
                % 开仓价差
                tdList(d,3) = op1-op2;
                if (tdList(d, 9) / oriAsset) < (-lossRatio)
                sigLi(i, 3) = d;
                clL = d;
                end
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
                % 本次交易（一个新号段）累计盈亏
                tdList(d, 9) = tdList(d - 1, 9) + tdList(d, 7);
                
                if tdList(d, 9) / oriAsset < (-lossRatio)
                sigLi(i, 3) = d;
                clL = d;
                end
            end
            if d==clL %平仓
                % 平仓的时候，要把第二天平仓带来的收益计算到最后这一天里面
                % 有个问题，如果正好本区间的最后一天发出了平仓信号，那第二天早上的开盘价没有数据啊
                % 因为这个地方已经是一个合约的全部交易区间了，第二天就没有交易了，所以也没法用wind取数，
                % 这里如果碰到最后一天发出平仓信号的话，就直接往前提前一天就可以了，因为下一步再信号清理的时候会把非主力区间的这些都清理掉，不影响最终结果的
                % 品种1
                op1 = closedata(d,1)*contM1*h1; %用前一天的收盘价开仓
                % 品种2
                op2 = closedata(d,2)*contM2*h2;
                % 平仓价差
                tdList(d,4) = op1-op2;
                
                if d < size(tddata1, 1)
                    cl1 = (tddata1(d+1)-sgn1*slip*unit1)*(1-sgn1*fixC)*contM1*h1; %平仓价
                    cl2 = (tddata2(d+1)-sgn2*slip*unit2)*(1-sgn2*fixC)*contM2*h2;
                else
                    % 这种情况是最后一天了，直接改后跳出即可
                    sigLi(i, 3) = sigLi(i, 3) - 1; % 平仓往上挪一天
                    clL = sigLi(i, 3);
                    d = d + 1;
                    break % 如果遇到时间段最后一天平仓，就把平仓日往上挪一行，也不用计算止损了，跳出去
%                     cl1 = (tddata1(d)-sgn1*slip*unit1)*(1-sgn1*fixC)*contM1*h1; %平仓价;
%                     cl2 = (tddata2(d)-sgn2*slip*unit2)*(1-sgn2*fixC)*contM2*h2;
                end
                % 当日盈亏(平仓没往上挪的情况，往上挪一天先不加了，因为如果上一天改止损平仓的话在上一天的时候就止损了；这部分的损益不保存，回测平台会重新算损益)
                tdList(d,7) = tdList(d,7)+(-sgn1*op1+sgn1*cl1)+(-sgn2*op2+sgn2*cl2);
                tdList(d,8) = tdList(d,8)+(-sgn1*op1+sgn1*cl1)+(-sgn2*op2+sgn2*cl2);
                tdList(d,9) = tdList(d,9) + (-sgn1*op1+sgn1*cl1) + (-sgn2*op2+sgn2*cl2);
                
                if (tdList(d, 9) / oriAsset) < (-lossRatio)
                sigLi(i, 3) = d;
                clL = d;
                end
            end
            d = d + 1;
        end
    end
    if clL-opL==1 %当根开下根平， 这种不需要止损
        % 如果遇到倒数第二天进，倒数第一天信号出的情况，直接就不要这个sigLi了
        if clL < size(tddata, 1)
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
        else
        sigLi(i, :) = [];    
        end
        
    end
    
    % 市值更新
    asset = tdList(clL,8);
    % 市值填充
    if i<num
        tdList(clL+1:sigLi(i+1,2),8) = asset;
    else
        tdList(clL:end,8) = asset;
    end
    
    
    % 判断是否止损，如果达到亏损比例限制，则更改信号退出行数
%     if tdList(d, 9) / oriAsset < (-lossRatio)
%         sigLi(i, 3) = d;
%     end
    
end

end

