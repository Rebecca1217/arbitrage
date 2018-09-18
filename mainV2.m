clear;close all
addpath('usual_function')
addpath newSystem3.0 newSystem3.0/gen_for_BT2  gen_function/CTA1
% mainV2 产生信号过程不改，保证信号和漫雪一样，结果调整为targetPortfolio输入回测平台

% 信号相关
signalName = 'CTA1';
signalID = 101;

% 品种
fut_variety = {'J','JM'};

% 策略参数
paraM.win = 20; %用于计算trend和noise的时间窗口
paraM.win2 = 10; % movH movL的时间窗口
paraM.rate = 1/1.35;
% 交易参数
Cost.fix = 0; %固定成本
Cost.float = 2; %滑点
tradeP = 'open'; %交易价格
oriAsset = 10000000; %初始金额
% 数据相关
stDate = 0;
edDate = 20180731;
load Z:\baseData\Tdays\future\Tdays_dly.mat
totaldate = Tdays(Tdays(:,1)>=stDate & Tdays(:,1)<=edDate,1);
sigDPath = '\\Cj-lmxue-dt\期货数据2.0\pairData';

% 添加路径
addpath(['gen_function\',signalName]);
% 导入数据
load \\Cj-lmxue-dt\期货数据2.0\usualData\minTickInfo.mat %品种最小变动价位
trade_unit = minTickInfo;
load(['\\Cj-lmxue-dt\期货数据2.0\usualData\PunitInfo\',num2str(totaldate(end)),'.mat']) %合约乘数
cont_multi = infoData;

proAsset = oriAsset;
for i_pair = 1:size(fut_variety,1)
    pFut1 = fut_variety{i_pair,1};
    pFut2 = fut_variety{i_pair,2};
    dataPath = [sigDPath,'\',pFut1,'_',pFut2];
    % 合约乘数
    contM1 = cont_multi{ismember(cont_multi(:,1),pFut1),2};
    contM2 = cont_multi{ismember(cont_multi(:,1),pFut2),2};
    % 参数
    pName = fieldnames(paraM);
    for p = 1:length(pName)
        str = ['para.',pName{p},'=paraM.',pName{p},'(i_pair);'];
        eval(str)
    end
    
    % 导入换月日数据
    load(['\\Cj-lmxue-dt\期货数据2.0\code2.0\data20_pair_data\chgInfo\',pFut1,'_',pFut2,'.mat'])
    chgInfo = chgInfo(chgInfo.date>stDate & chgInfo.date<=edDate,:);
    
    % 生成信号-按合约循环
    res = totaldate(totaldate >= chgInfo.date(1));
    res = res(1 : (end - 1));%不然最后一行是空值
    res = array2table([res, NaN(size(res, 1), 5)], 'VariableNames', {'Date', 'PosLabel', 'Hands1', 'Hands2', 'Cont1', 'Cont2'});
    res.Cont1 = num2cell(res.Cont1);
    res.Cont2 = num2cell(res.Cont2);
%     tdList = [];
%     sigAdj = [];
%     Boll = [];
%     data1 = [];
%     data2 = [];
    tstData = table();
    for c = 1:height(chgInfo)
        disp(c)
        c_stD = chgInfo.date(c); %该合约开始作为主力的日期
        if c~=height(chgInfo)
            c_edD = totaldate(find(totaldate==chgInfo.date(c+1),1)-1); %该合约作为主力的结束日期
        else %最后一段
            c_edD = totaldate(find(totaldate==edDate)-1);
        end
        cont1 = regexp(chgInfo{c,2}{1},'\w*(?=\.)','match');
        cont2 = regexp(chgInfo{c,3}{1},'\w*(?=\.)','match');
        % 导入数据
        data1 = getData([dataPath,'\',pFut1,'\',cont1{1},'.mat'],edDate);
        data2 = getData([dataPath,'\',pFut2,'\',cont2{1},'.mat'],edDate);
        [sigOpen,sigClose,lines] = signal_gen(data1,data2,signalID,para);
        sig = [sigOpen,sigClose];
       tstData = vertcat(tstData, lines(lines.date >= c_stD & lines.date <= c_edD, :)); 
        
        pureSig = pure_signal(sig, data1.date, c_stD, c_edD, oriAsset, data1.close, data2.close, paraM.rate*ones(size(sig,1),1), contM1, contM2);
%                 % 交易
%                 % 交易数据
%                 if strcmpi(tradeP,'open')
%                     tddata = [data1.open,data2.open];
%                 end
%                 tddata = [tddata,data1.close,data2.close];
%                 Cost.unit1 = trade_unit{ismember(trade_unit(:,1),pFut1),2};
%                 Cost.unit2 = trade_unit{ismember(trade_unit(:,1),pFut2),2};
%                 Cost.contM1 = contM1;
%                 Cost.contM2 = contM2;
%                 [tdListCont,sigAdjCont] = cal_rtn(sig,paraM.rate*ones(size(sig,1),1),tddata,data1.date,c_stD,c_edD,Cost,proAsset);
%         
%                 % 记录绩效和信号
%                 stL = find(tdListCont(:,1)==c_stD,1); %开始日期
%                 edL = find(tdListCont(:,1)==c_edD,1); %结束日期
%                 tdList = [tdList;tdListCont(stL:edL,:)];
%                 sigAdj = [sigAdj;sigAdjCont(stL:edL,:)];
%                 proAsset = tdList(end,9);
%                 if c==1
%                     ttLines = lines(lines.date>=c_stD & lines.date<=c_edD,:);
%                 else
%                     ttLines = [ttLines;lines(lines.date>=c_stD & lines.date<=c_edD,:)];
%                 end
%         
        resI = array2table(pureSig, 'VariableNames', {'Date', 'PosLabel', 'Hands1', 'Hands2'});
        resI.Cont1 = repmat(cont1, size(pureSig, 1), 1);
        resI.Cont2 = repmat(cont2, size(pureSig, 1), 1);
    fromIdx = find(res.Date == c_stD);
    endIdx = find(res.Date == c_edD);
    res((fromIdx : endIdx), :) = resI;
    end
end



targetPortfolio = num2cell(NaN(size(res, 1), 2));   %分配内存
for iDate = 1:size(res, 1)
    hands = {char(res(iDate, :).Cont1), res(iDate, :).Hands1;...
       char(res(iDate, :).Cont2), res(iDate, :).Hands2};
    targetPortfolio{iDate, 1} = hands;
    targetPortfolio{iDate, 2} = res.Date(iDate);
end

% getholdinghands部分不涉及换月日，因为是每段循环的，本部分内没有合约换月
% 但是合约换月日要用于输入回测平台数据部分adjFactor



% TradePara用于输入回测平台
TradePara.futDataPath = '\\Cj-lmxue-dt\期货数据2.0\dlyData\主力合约'; %期货主力合约数据路径
TradePara.futUnitPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\minTickInfo.mat'; %期货最小变动单位
TradePara.futMultiPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\PunitInfo'; %期货合约乘数
TradePara.futLiquidPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\liquidityInfo'; %期货品种流动性数据，用来筛选出活跃品种，剔除不活跃品种
TradePara.futSectorPath = '\\Cj-lmxue-dt\期货数据2.0\usualData\SectorInfo.mat'; %期货样本池数据，用来确定样本集对应的品种
TradePara.futMainContPath = '\\Cj-lmxue-dt\期货数据2.0\商品期货主力合约代码'; %主力合约代码
% TradePara.usualPath = '..\data\usualData';%基础通用数据 这个地址是哪里？
TradePara.usualPath = '\\Cj-lmxue-dt\期货数据2.0\usualData';
TradePara.fixC = 0.0000; %固定成本
TradePara.slip = 2; %滑点 
TradePara.PType = 'open'; %交易价格，一般用open（开盘价）或者avg(日均价）


[BacktestResult,err] = CTABacktest_GeneralPlatform_3(targetPortfolio,TradePara);

figure
% 净值曲线
plot((oriAsset + BacktestResult.nv(:, 2)) ./ oriAsset)

BacktestAnalysis = CTAAnalysis_GeneralPlatform_2(BacktestResult);

% 
% 
% figure
% plot(tdList(:,end))
% rtnC = [tdList(2:end,1),tick2ret(tdList(:,end))];
% analysis = getAnalysis(rtnC);
% 
% analysisI = zeros(6,height(chgInfo));
% figure
% for i = 1:height(chgInfo)
%     if i<height(chgInfo)
%         locs = ttLines.date>=chgInfo.date(i) & ttLines.date<chgInfo.date(i+1);
%     else
%         locs = ttLines.date>=chgInfo.date(i);
%     end
%     lines = ttLines(locs,:);
%     tdListI = tdList(locs,:);
%     subplot(5,5,i)
%     plot(tdListI(:,end))
%     title(num2str(i))
%     rtnC = [tdListI(2:end,1),tick2ret(tdListI(:,end))];
%     analysisI(:,i) = getAnalysis(rtnC);
% end
% 
% %
% year = floor(tdList(:,1)/10000);
% yearN = unique(year);
% analysisAnn = zeros(6,length(yearN));
% for i = 1:length(yearN)
%     rtn = [tdList(year==yearN(i),1),[0;tick2ret(tdList(year==yearN(i),end))]];
%     analysisAnn(:,i) = getAnalysis(rtn);
% end
