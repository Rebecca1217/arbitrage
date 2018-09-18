clear;close all
addpath('usual_function')
addpath newSystem3.0 newSystem3.0/gen_for_BT2  gen_function/CTA1
% mainV2 �����źŹ��̲��ģ���֤�źź���ѩһ�����������ΪtargetPortfolio����ز�ƽ̨

% �ź����
signalName = 'CTA1';
signalID = 101;

% Ʒ��
fut_variety = {'J','JM'};

% ���Բ���
paraM.win = 20; %���ڼ���trend��noise��ʱ�䴰��
paraM.win2 = 10; % movH movL��ʱ�䴰��
paraM.rate = 1/1.35;
% ���ײ���
Cost.fix = 0; %�̶��ɱ�
Cost.float = 2; %����
tradeP = 'open'; %���׼۸�
oriAsset = 10000000; %��ʼ���
% �������
stDate = 0;
edDate = 20180731;
load Z:\baseData\Tdays\future\Tdays_dly.mat
totaldate = Tdays(Tdays(:,1)>=stDate & Tdays(:,1)<=edDate,1);
sigDPath = '\\Cj-lmxue-dt\�ڻ�����2.0\pairData';

% ���·��
addpath(['gen_function\',signalName]);
% ��������
load \\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat %Ʒ����С�䶯��λ
trade_unit = minTickInfo;
load(['\\Cj-lmxue-dt\�ڻ�����2.0\usualData\PunitInfo\',num2str(totaldate(end)),'.mat']) %��Լ����
cont_multi = infoData;

proAsset = oriAsset;
for i_pair = 1:size(fut_variety,1)
    pFut1 = fut_variety{i_pair,1};
    pFut2 = fut_variety{i_pair,2};
    dataPath = [sigDPath,'\',pFut1,'_',pFut2];
    % ��Լ����
    contM1 = cont_multi{ismember(cont_multi(:,1),pFut1),2};
    contM2 = cont_multi{ismember(cont_multi(:,1),pFut2),2};
    % ����
    pName = fieldnames(paraM);
    for p = 1:length(pName)
        str = ['para.',pName{p},'=paraM.',pName{p},'(i_pair);'];
        eval(str)
    end
    
    % ���뻻��������
    load(['\\Cj-lmxue-dt\�ڻ�����2.0\code2.0\data20_pair_data\chgInfo\',pFut1,'_',pFut2,'.mat'])
    chgInfo = chgInfo(chgInfo.date>stDate & chgInfo.date<=edDate,:);
    
    % �����ź�-����Լѭ��
    res = totaldate(totaldate >= chgInfo.date(1));
    res = res(1 : (end - 1));%��Ȼ���һ���ǿ�ֵ
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
        c_stD = chgInfo.date(c); %�ú�Լ��ʼ��Ϊ����������
        if c~=height(chgInfo)
            c_edD = totaldate(find(totaldate==chgInfo.date(c+1),1)-1); %�ú�Լ��Ϊ�����Ľ�������
        else %���һ��
            c_edD = totaldate(find(totaldate==edDate)-1);
        end
        cont1 = regexp(chgInfo{c,2}{1},'\w*(?=\.)','match');
        cont2 = regexp(chgInfo{c,3}{1},'\w*(?=\.)','match');
        % ��������
        data1 = getData([dataPath,'\',pFut1,'\',cont1{1},'.mat'],edDate);
        data2 = getData([dataPath,'\',pFut2,'\',cont2{1},'.mat'],edDate);
        [sigOpen,sigClose,lines] = signal_gen(data1,data2,signalID,para);
        sig = [sigOpen,sigClose];
       tstData = vertcat(tstData, lines(lines.date >= c_stD & lines.date <= c_edD, :)); 
        
        pureSig = pure_signal(sig, data1.date, c_stD, c_edD, oriAsset, data1.close, data2.close, paraM.rate*ones(size(sig,1),1), contM1, contM2);
%                 % ����
%                 % ��������
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
%                 % ��¼��Ч���ź�
%                 stL = find(tdListCont(:,1)==c_stD,1); %��ʼ����
%                 edL = find(tdListCont(:,1)==c_edD,1); %��������
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



targetPortfolio = num2cell(NaN(size(res, 1), 2));   %�����ڴ�
for iDate = 1:size(res, 1)
    hands = {char(res(iDate, :).Cont1), res(iDate, :).Hands1;...
       char(res(iDate, :).Cont2), res(iDate, :).Hands2};
    targetPortfolio{iDate, 1} = hands;
    targetPortfolio{iDate, 2} = res.Date(iDate);
end

% getholdinghands���ֲ��漰�����գ���Ϊ��ÿ��ѭ���ģ���������û�к�Լ����
% ���Ǻ�Լ������Ҫ��������ز�ƽ̨���ݲ���adjFactor



% TradePara��������ز�ƽ̨
TradePara.futDataPath = '\\Cj-lmxue-dt\�ڻ�����2.0\dlyData\������Լ'; %�ڻ�������Լ����·��
TradePara.futUnitPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\minTickInfo.mat'; %�ڻ���С�䶯��λ
TradePara.futMultiPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\PunitInfo'; %�ڻ���Լ����
TradePara.futLiquidPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\liquidityInfo'; %�ڻ�Ʒ�����������ݣ�����ɸѡ����ԾƷ�֣��޳�����ԾƷ��
TradePara.futSectorPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData\SectorInfo.mat'; %�ڻ����������ݣ�����ȷ����������Ӧ��Ʒ��
TradePara.futMainContPath = '\\Cj-lmxue-dt\�ڻ�����2.0\��Ʒ�ڻ�������Լ����'; %������Լ����
% TradePara.usualPath = '..\data\usualData';%����ͨ������ �����ַ�����
TradePara.usualPath = '\\Cj-lmxue-dt\�ڻ�����2.0\usualData';
TradePara.fixC = 0.0000; %�̶��ɱ�
TradePara.slip = 2; %���� 
TradePara.PType = 'open'; %���׼۸�һ����open�����̼ۣ�����avg(�վ��ۣ�


[BacktestResult,err] = CTABacktest_GeneralPlatform_3(targetPortfolio,TradePara);

figure
% ��ֵ����
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
