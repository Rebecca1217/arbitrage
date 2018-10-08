function resRate = getRate(date, pFut1, pFut2, para)

dataPath = evalin('base', 'dataPath');
% 这里有个问题，上来就回归不行啊，回归不显著的就还是用1.35？
% 回归系数汇总的地方可以加权重，离现在更近的给予更大的权重试试
rateInit = para.rateInit;
chgInfo = evalin('base', 'chgInfo');
yearSeries = unique(year(num2str(date), 'yyyymmdd'));
numYear = length(yearSeries); % 时间序列共5年，第一年用1.35，以后每年用前一年的主力回归平均系数

resRate = NaN(length(date), 2);
resRate(:, 1) = date;
for iYear = 1 : numYear
    thisYear = yearSeries(iYear);
    resData = date(year(num2str(date), 'yyyymmdd') == thisYear);
    if iYear == 1
        resRate(1:length(resData), 2) = rateInit;
    else
        % 不是第一年的话 用上一年的每段主力回归系数的平均值
        % 这里有个问题，就是每段主力的样本量是不是足够大，如果不够大怎么办
        % 一个方案是样本量不够大的和回归结果不显著的就还是用rateInit替代，一起平均
        % 这个chgInfoSelec选出来其实不严谨，最后一行年末日期其实还没有换月，但是貌似没用到，回头 check一下看是否需要修改
        idx = year(num2str(chgInfo.date), 'yyyymmdd') == thisYear;
        idx(find(idx, 1, 'first') - 1) = 1;
        if iYear ~= numYear
            idx(find(idx, 1, 'last') + 1) = 1;
        end
        chgInfoSelec = chgInfo(idx, :);
        chgInfoSelec{1, 1} = resData(1);
        chgInfoSelec{end, 1} = resData(end);
        
        betaM = NaN(size(chgInfoSelec, 1) - 1, 1);
        for iRegression = 1 : (size(chgInfoSelec, 1) - 1)
        % 每一段主力自己回归得到一个系数，保存下来，最后平均得到这一年的系数
           % 日期从chgInfoSelec的本段第一天，到下一段开始到前一天 
           dateSeq = resData(resData >= chgInfoSelec{iRegression, 1} & resData < chgInfoSelec{iRegression + 1, 1});
           cont1 = regexp(chgInfoSelec{iRegression, 2}{1}, '\w*(?=\.)','match');
           cont2 = regexp(chgInfoSelec{iRegression, 3}{1}, '\w*(?=\.)','match');
           data1 = getData([dataPath,'\',pFut1,'\',cont1{1},'.mat'], dateSeq(end));
           data2 = getData([dataPath,'\',pFut2,'\',cont2{1},'.mat'], dateSeq(end));
           % 这个地方可以选择截取startDate或者不截取，不截取的话样本量就大一些，都试试
           
           [r, m, b] = regression(data1.close, data2.close, 'one'); % 回归是J作自变量，JM是因变量，系数和1/1.35对应
           % R2是很高很高的 厉害
           betaM(iRegression) = m;        
        end
        [~, idxFrom, ~]  = intersect(resRate(:, 1), resData(1));
        [~, idxTo, ~] = intersect(resRate(:, 1), resData(end));
        resRate(idxFrom : idxTo, 2) = mean(betaM);
    end
    
end

end
