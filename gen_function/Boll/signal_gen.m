function [sigOpen,sigClose,Boll] = signal_gen(maindata1,maindata2,contM1,contM2,signalID,para)

Boll = get_ATR(maindata1,maindata2,contM1,contM2,para);


str = ['[sigOpen,sigClose] = signal_',num2str(signalID),'(Boll,para);'];
eval(str)

end

%%
function [sigOpen,sigClose] = signal_1(Boll,para)

res = Boll.res;
opB = Boll.OPL; %�������õ��¹졢�Ϲ�
stB = Boll.STL; %ֹ�����õ��¹졢�Ϲ�

resBF = [nan;res(1:end-1)];
opBBF = [[nan,nan];opB(1:end-1,:)];
stBBF = [[nan,nan];stB(1:end-1,:)];

sigOpen = zeros(length(res),1);
sigClose = zeros(length(res),1);

sigOpen(and(resBF<opBBF(:,1),res>opB(:,1))) = 1; %�ϴ��¹�
sigOpen(and(resBF>opBBF(:,2),res<opB(:,2))) = -1; %�´��Ϲ�

sigClose(or(sigOpen==1,and(resBF<stBBF(:,2),res>stB(:,2)))) = 1; %���������źŻ����´����¹� 
sigClose(or(sigOpen==-1,and(resBF>stBBF(:,1),res<stB(:,1)))) = -1; %���������źŻ����ϴ����Ϲ�


end

function [sigOpen,sigClose] = signal_2(Boll,para)
% ˫����ϵͳ������

maF = Boll.maF;
maS = Boll.maS;

dif = maF-maS;
difBF = [nan;dif(1:end-1)];

sigOpen = zeros(length(dif),1);
sigClose = zeros(length(dif),1);

sigOpen(and(difBF<0,dif>0)) = 1; %���
sigOpen(and(difBF>0,dif<0)) = -1; %����

sigClose(sigOpen==1) = 1;
sigClose(sigOpen==-1) = -1;



end

function [sigOpen,sigClose] = signal_3(Boll,para)
% �ư���ͨ��������

% �ƶ��ߵͼ�
res = Boll.res;
maH = Boll.maH;
maL = Boll.maL;
maHBF = [nan;maH(1:end-1)];
maLBF = [nan;maL(1:end-1)];



sigOpen = zeros(length(res),1);
sigClose = zeros(length(res),1);

% 
difUP = res-maHBF; %res���Ϲ�Ĳ�ֵ
difDN = res-maLBF; %res���¹�Ĳ�ֵ
difUPBF = [nan;difUP(1:end-1)];
difDNBF = [nan;difDN(1:end-1)];

flagOPL = and(difDNBF<0,difDN>0);
flagOPS = and(difUPBF>0,difUP<0);

flagSTL = flagOPS;
flagSTS = flagOPL;

sigOpen(flagOPL) = 1; %���
sigOpen(flagOPS) = -1; %����

sigClose(flagSTS) = 1;
sigClose(flagSTL) = -1;



end
%%
function Boll = get_Boll(maindata1,maindata2,contM1,contM2,para)

win = para.win;
OPthr = para.OPthr;
STthr = para.STthr;


Close1 = maindata1(:,2)*contM1;
Close2 = maindata2(:,2)*contM2;
Close = [Close1,Close2];

res = zeros(length(Close),1);
beta = zeros(length(Close),2);
ma = zeros(length(Close),1);
sd = zeros(length(Close),1);
for t = win:length(Close1)
    [~,~,~,~,reg1] = egcitest(Close(t-win+1:t,:));
    beta(t,:) = reg1.coeff';
    res(t) = reg1.res(end)+beta(t,1);
    if t==win
        res(1:win-1) = reg1.res(1:win-1)+beta(t,1);
    end
    ma(t) = mean(res(t-win+1:t));
    sd(t) = std(res(t-win+1:t));
end
ma(1:win-1) = nan;
sd(1:win-1) = nan;

Boll.res = res;
Boll.beta = beta;
Boll.MA = ma;
Boll.SD = sd;
Boll.OPL = [ma-OPthr*sd,ma+OPthr*sd];
Boll.STL = [ma-STthr*sd,ma+STthr*sd];
end


function Boll = get_ATR(maindata1,maindata2,contM1,contM2,para)
% �õ�ȨATR�ķ�ʽ��ȷ������Ʒ�ֵ���Ա���

win = para.win;
OPthr = para.OPthr;
STthr = para.STthr;
winB = para.winB;

% o c h l
price1 = maindata1(:,1:4);
price2 = maindata2(:,1:4);
% atr
ATR1 = ATR(price1,win)*contM1;
ATR2 = ATR(price2,win)*contM2;

% ���
beta = zeros(length(ATR1),2);
beta(:,2) = ATR1./ATR2; 

% beta(:,2) = ones(length(ATR1),1);

% �۲�
res = price1(:,2)-price2(:,2).*beta(:,2);
ma = MA_self(res,winB);
% sd = ATR(res,winB);
sd = nan(length(price1),1);
for t = winB:length(price1)
    sd(t) = std(res(t-winB+1:t));
end


Boll.res = res;
Boll.beta = beta;
Boll.MA = ma;
Boll.SD = sd;
Boll.OPL = [ma-OPthr*sd,ma+OPthr*sd];
Boll.STL = [ma-STthr*sd,ma+STthr*sd];
end



%{
function Boll = get_ATR(maindata1,maindata2,contM1,contM2,para)
% �õ�ȨATR�ķ�ʽ��ȷ������Ʒ�ֵ���Ա���

win = para.win;
winF = para.winF;
winS = para.winS;

% o c h l
price1 = maindata1(:,1:4);
price2 = maindata2(:,1:4);
% atr
ATR1 = ATR(price1,win)*contM1;
ATR2 = ATR(price2,win)*contM2;

% ���
beta = zeros(length(ATR1),2);
beta(:,2) = ATR1./ATR2; 

% beta(:,2) = ones(length(ATR1),1);
% 
% �۲�
res = price1(:,2)-price2(:,2).*beta(:,2);

% ������
st = find(~isnan(res),1,'first');
maF = tsmovavg(res(st:end),'e',winF,1);
maS = tsmovavg(res(st:end),'e',winS,1);
maF = [nan(st-1,1);maF];
maS = [nan(st-1,1);maS];


Boll.res = res;
Boll.beta = beta;
Boll.maF = maF;
Boll.maS = maS;
end
%}
