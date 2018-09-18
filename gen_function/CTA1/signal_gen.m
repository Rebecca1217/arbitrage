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
% trend的MA5
trendMA5 = MAx(trend, 5);
noiseMA3 = MAx(noise, 3);

% 会出现trend
% L = noise>=movH_BF1 & [0;diff(lines.spreadH)]>=0  & dif_T>=0;
% L = [0;diff(lines.spreadH)]>=0  & dif_T>=0; % 这个不行，信号太多了
L = noise >=movNH_BF1 & [0;diff(lines.spreadH)]>=0  & dif_T>=0 ; % noise改trend
% 开仓做多价差：noise超过win2日max，价差极大值平滑曲线向上跳升的下一交易日， 上日trend取值>= 0
% S =  noise<=movL_BF1  & [0;diff(lines.spreadH)]<=0 & dif_T<=0 ;
% S = [0;diff(lines.spreadH)]<=0 & dif_T<=0 ;
S = noise <=movNL_BF1  & [0;diff(lines.spreadH)]<=0 & dif_T<=0 ;
% 开仓做空价差
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
% addL1 = noise<movH_BF1; %未创新高
% addS1 = noise>movL_BF1; %未创新低
CL = dif_N<0 & ~lines.pivotH;% & dif_S<0);% & (addL1 & [0;addL1(1:end-1)]==1); CL选出的是noise每个下降通道除第一个确认拐点以后的点，这么做是为了不让平仓太敏感？
CS = dif_N>0 & ~lines.pivotL;% & dif_S>0 ;%(addS1 & [0;addS1(1:end-1)]==1); CS 选出的是noise每个上升通道的除第一个确认拐点以后的点
% 修改平仓信号，如果trend低于过去5日均值了就退出
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
lines.trend = sub_MASSA(lines,para.win,1,'spread'); % 每天累加滚动窗口，不是win固定窗口滚动的，然后取SSA序列的end滚动合成一个新的SSA序列
lines.noise = sub_MASSA(lines,para.win,2,'spread');
movNH = movmax(lines.noise,[win2-1,0]); % 每win2个noise记录一个最大值
movNH(win:win+win2-2) = cummax(lines.noise(1:win2-1)); % 这一步的目的是:把前win2个空出来，不然movmax遇到NaN会自动补齐
lines.movNH = movNH;
movNL = movmin(lines.noise,[win2-1,0]);
movNL(win:win+win2-2) = cummin(lines.noise(1:win2-1));
lines.movNL = movNL;
movTH = movmax(lines.trend,[win2-1,0]); % 每win2个noise记录一个最大值
movTH(win:win+win2-2) = cummax(lines.trend(1:win2-1)); % 这一步的目的是:把前win2个空出来，不然movmax遇到NaN会自动补齐
lines.movTH = movTH;
movTL = movmin(lines.trend,[win2-1,0]);
movTL(win:win+win2-2) = cummin(lines.trend(1:win2-1));
lines.movTL = movTL;


% 局部高低点noise
dif_N = [0;diff(lines.noise)];
dif_N_BF1 = [0;dif_N(1:end-1)];
lines.pivotH = dif_N<0 & dif_N_BF1>0; % 开始下落的点
lines.pivotL = dif_N>0 & dif_N_BF1<0; % 开始回升的点, lines.pivotL - 1就是极小值index
noiseL = nan(length(lines.noise),1);
noiseL(lines.pivotL) = lines.noise(find(lines.pivotL)-1); %极小值对应的价差（剔除了趋势，只看噪声的价差？）
% 这一步把极小值的noise放到极小值下一个index上是要干嘛？
lines.noiseL = fillmissing(noiseL,'previous');

% 穿越trend
delta = lines.spread-lines.trend;
delta_BF1 = [0;delta(1:end-1)];
lines.crossUp = delta_BF1<0 & delta>0;
lines.crossDn = delta_BF1>0 & delta<0;

% 价差的局部高低点
dif_S = [0;diff(lines.spread)];
dif_S_BF1 = [0;dif_S(1:end-1)];
lines.pivotH_S = dif_S<0 & dif_S_BF1>0;
lines.pivotL_S = dif_S>0 & dif_S_BF1<0;
spreadL = nan(length(lines.spread),1);
spreadL(lines.pivotL_S) = lines.spread(find(lines.pivotL_S)-1); %极小值对应的价差
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
