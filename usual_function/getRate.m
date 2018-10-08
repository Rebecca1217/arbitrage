function resRate = getRate(date, pFut1, pFut2, para)

dataPath = evalin('base', 'dataPath');
% �����и����⣬�����ͻع鲻�а����ع鲻�����ľͻ�����1.35��
% �ع�ϵ�����ܵĵط����Լ�Ȩ�أ������ڸ����ĸ�������Ȩ������
rateInit = para.rateInit;
chgInfo = evalin('base', 'chgInfo');
yearSeries = unique(year(num2str(date), 'yyyymmdd'));
numYear = length(yearSeries); % ʱ�����й�5�꣬��һ����1.35���Ժ�ÿ����ǰһ��������ع�ƽ��ϵ��

resRate = NaN(length(date), 2);
resRate(:, 1) = date;
for iYear = 1 : numYear
    thisYear = yearSeries(iYear);
    resData = date(year(num2str(date), 'yyyymmdd') == thisYear);
    if iYear == 1
        resRate(1:length(resData), 2) = rateInit;
    else
        % ���ǵ�һ��Ļ� ����һ���ÿ�������ع�ϵ����ƽ��ֵ
        % �����и����⣬����ÿ���������������ǲ����㹻�������������ô��
        % һ��������������������ĺͻع����������ľͻ�����rateInit�����һ��ƽ��
        % ���chgInfoSelecѡ������ʵ���Ͻ������һ����ĩ������ʵ��û�л��£�����ò��û�õ�����ͷ checkһ�¿��Ƿ���Ҫ�޸�
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
        % ÿһ�������Լ��ع�õ�һ��ϵ�����������������ƽ���õ���һ���ϵ��
           % ���ڴ�chgInfoSelec�ı��ε�һ�죬����һ�ο�ʼ��ǰһ�� 
           dateSeq = resData(resData >= chgInfoSelec{iRegression, 1} & resData < chgInfoSelec{iRegression + 1, 1});
           cont1 = regexp(chgInfoSelec{iRegression, 2}{1}, '\w*(?=\.)','match');
           cont2 = regexp(chgInfoSelec{iRegression, 3}{1}, '\w*(?=\.)','match');
           data1 = getData([dataPath,'\',pFut1,'\',cont1{1},'.mat'], dateSeq(end));
           data2 = getData([dataPath,'\',pFut2,'\',cont2{1},'.mat'], dateSeq(end));
           % ����ط�����ѡ���ȡstartDate���߲���ȡ������ȡ�Ļ��������ʹ�һЩ��������
           
           [r, m, b] = regression(data1.close, data2.close, 'one'); % �ع���J���Ա�����JM���������ϵ����1/1.35��Ӧ
           % R2�Ǻܸߺܸߵ� ����
           betaM(iRegression) = m;        
        end
        [~, idxFrom, ~]  = intersect(resRate(:, 1), resData(1));
        [~, idxTo, ~] = intersect(resRate(:, 1), resData(end));
        resRate(idxFrom : idxTo, 2) = mean(betaM);
    end
    
end

end
