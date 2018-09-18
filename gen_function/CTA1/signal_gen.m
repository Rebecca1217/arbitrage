function [sigOpen,sigClose,lines] = signal_gen(data1,data2,signalID,para)

lines = getLines(data1,data2,para);

[sigOpen,sigClose] = eval(['signal_',num2str(signalID),'(lines,para)']);
end


function [sigO,sigC] = signal_1(lines,para)

spread = lines.spread;
trend = lines.trend;
noise = lines.noise;

sigO = zeros(length(spread),1);
sigC = zeros(length(spread),1);

dif_N = [0;diff(noise)];
dif_T = [0;diff(trend)];
movH_BF1 = [nan;lines.movH(1:end-1)];
movL_BF1 = [nan;lines.movL(1:end-1)];
L =  noise>=movH_BF1 & dif_N>0 & dif_T>0;
S =  noise<=movL_BF1  & dif_N<0 & dif_T<0;
% L = dif_N>0 & dif_T>0;
% S = dif_N<0 & dif_T<0;

sigO(L) = 1;
sigO(S) = -1;

% CL = noise<=[nan;lines.movL2(1:end-1)];
% CS = noise>=[nan;lines.movH2(1:end-1)];
CL = dif_N<0;
CS = dif_N>0;
sigC(CL ) = -1;
sigC(CS ) = 1;

end

function [sigO,sigC] = signal_101(lines,para)

spread = lines.spread;
trend = lines.trend;
noise = lines.noise;

sigO = zeros(length(spread),1); 
sigC = zeros(length(spread),1);

dif_S = [0;diff(spread)];
dif_N = [0;diff(noise)];
dif_T = [0;diff(trend)];
movTH_BF1 = [nan;lines.movTH(1:end-1)];
movTL_BF1 = [nan;lines.movTL(1:end-1)];
movNH_BF1 = [nan;lines.movNH(1:end-1)];
movNL_BF1 = [nan;lines.movNL(1:end-1)];
% trend��MA5
trendMA5 = MAx(trend, 5);
noiseMA3 = MAx(noise, 3);

% �����trend
% L = noise>=movH_BF1 & [0;diff(lines.spreadH)]>=0  & dif_T>=0;
% L = [0;diff(lines.spreadH)]>=0  & dif_T>=0; % ������У��ź�̫����
L = noise >=movNH_BF1 & [0;diff(lines.spreadH)]>=0  & dif_T>=0 ; % noise��trend
% ��������۲noise����win2��max���۲��ֵƽ������������������һ�����գ� ����trendȡֵ>= 0
% S =  noise<=movL_BF1  & [0;diff(lines.spreadH)]<=0 & dif_T<=0 ;
% S = [0;diff(lines.spreadH)]<=0 & dif_T<=0 ;
S = noise <=movNL_BF1  & [0;diff(lines.spreadH)]<=0 & dif_T<=0 ;
% �������ռ۲�
% L = noise>=movH_BF1 & [0;diff(lines.spreadH)]>0  & dif_T>0;
% S =  noise<=movL_BF1  & [0;diff(lines.spreadH)]<0 & dif_T<0 ;
% L =  noise>=movH_BF1 & dif_N>0 & dif_T>0;
% S =   noise<=movL_BF1 & dif_N<0 & dif_T<0;
% L = dif_N>0 & dif_T>0 & [0;diff(lines.spreadL)]>=0;
% S = dif_N<0 & dif_T<0 & [0;diff(lines.spreadH)]<=0;

sigO(L) = 1;
sigO(S) = -1;

% CL = noise<=[nan;lines.movL2(1:end-1)];
% CS = noise>=[nan;lines.movH2(1:end-1)];
% addL1 = noise<movH_BF1; %δ���¸�
% addS1 = noise>movL_BF1; %δ���µ�
CL = dif_N<0 & ~lines.pivotH;% & dif_S<0);% & (addL1 & [0;addL1(1:end-1)]==1); CLѡ������noiseÿ���½�ͨ������һ��ȷ�Ϲյ��Ժ�ĵ㣬��ô����Ϊ�˲���ƽ��̫���У�
CS = dif_N>0 & ~lines.pivotL;% & dif_S>0 ;%(addS1 & [0;addS1(1:end-1)]==1); CS ѡ������noiseÿ������ͨ���ĳ���һ��ȷ�Ϲյ��Ժ�ĵ�
% �޸�ƽ���źţ����trend���ڹ�ȥ5�վ�ֵ�˾��˳�
% CL = (trend < trendMA5) ;
% CS = (trend > trendMA5) ;
sigC(CL ) = -1;
sigC(CS ) = 1;

end

%%
function lines = getLines(data1,data2,para)

win = para.win;
win2 = para.win2;
lines = table;
lines.date = data1.date;
lines.close1 = data1.close;
lines.close2 = data2.close;
lines.code1 = data1.fut;
lines.code2 = data2.fut;
lines.spread = para.rate*data1.close-data2.close;
lines.trend = sub_MASSA(lines,para.win,1,'spread'); % ÿ���ۼӹ������ڣ�����win�̶����ڹ����ģ�Ȼ��ȡSSA���е�end�����ϳ�һ���µ�SSA����
lines.noise = sub_MASSA(lines,para.win,2,'spread');
movNH = movmax(lines.noise,[win2-1,0]); % ÿwin2��noise��¼һ�����ֵ
movNH(win:win+win2-2) = cummax(lines.noise(1:win2-1)); % ��һ����Ŀ����:��ǰwin2���ճ�������Ȼmovmax����NaN���Զ�����
lines.movNH = movNH;
movNL = movmin(lines.noise,[win2-1,0]);
movNL(win:win+win2-2) = cummin(lines.noise(1:win2-1));
lines.movNL = movNL;
movTH = movmax(lines.trend,[win2-1,0]); % ÿwin2��noise��¼һ�����ֵ
movTH(win:win+win2-2) = cummax(lines.trend(1:win2-1)); % ��һ����Ŀ����:��ǰwin2���ճ�������Ȼmovmax����NaN���Զ�����
lines.movTH = movTH;
movTL = movmin(lines.trend,[win2-1,0]);
movTL(win:win+win2-2) = cummin(lines.trend(1:win2-1));
lines.movTL = movTL;


% �ֲ��ߵ͵�noise
dif_N = [0;diff(lines.noise)];
dif_N_BF1 = [0;dif_N(1:end-1)];
lines.pivotH = dif_N<0 & dif_N_BF1>0; % ��ʼ����ĵ�
lines.pivotL = dif_N>0 & dif_N_BF1<0; % ��ʼ�����ĵ�, lines.pivotL - 1���Ǽ�Сֵindex
noiseL = nan(length(lines.noise),1);
noiseL(lines.pivotL) = lines.noise(find(lines.pivotL)-1); %��Сֵ��Ӧ�ļ۲�޳������ƣ�ֻ�������ļ۲��
% ��һ���Ѽ�Сֵ��noise�ŵ���Сֵ��һ��index����Ҫ���
lines.noiseL = fillmissing(noiseL,'previous');

% ��Խtrend
delta = lines.spread-lines.trend;
delta_BF1 = [0;delta(1:end-1)];
lines.crossUp = delta_BF1<0 & delta>0;
lines.crossDn = delta_BF1>0 & delta<0;

% �۲�ľֲ��ߵ͵�
dif_S = [0;diff(lines.spread)];
dif_S_BF1 = [0;dif_S(1:end-1)];
lines.pivotH_S = dif_S<0 & dif_S_BF1>0;
lines.pivotL_S = dif_S>0 & dif_S_BF1<0;
spreadL = nan(length(lines.spread),1);
spreadL(lines.pivotL_S) = lines.spread(find(lines.pivotL_S)-1); %��Сֵ��Ӧ�ļ۲�
% if ~isempty(find(isnan(spreadL),1))
%     spreadL(1:find(isnan(spreadL),1,'last')) = cummax(lines.spread(1:find(isnan(spreadL),1,'last')));
% end
lines.spreadL = fillmissing(spreadL,'previous');
spreadH = nan(length(lines.spread),1);
spreadH(lines.pivotH_S) = lines.spread(find(lines.pivotH_S)-1);
% if ~isempty(find(isnan(spreadH),1))
%     spreadH(1:find(isnan(spreadH),1,'last')) = cummax(lines.spread(1:find(isnan(spreadH),1,'last')));
% end
lines.spreadH = fillmissing(spreadH,'previous');
end
