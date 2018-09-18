function SSA = sub_MASSA(TableDataI,win,k,dataType)
% 用SSA计算移动均线

data = eval(['TableDataI(:,{''',dataType,'''})']);
SSA = nan(height(data),1);
for i = win:height(data)
    tmp = sub_SSA(data(1:i,:),win,k,dataType);
    SSA(i) = tmp(end);
end
