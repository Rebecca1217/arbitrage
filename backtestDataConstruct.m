% ��Ҫ���У�Date, Close, Open, Settle, High, Low, adjFactor, mainCont��ʵ�ʲ�һ����ʲôCont��
% ���futureData
% ����J��futureData�ز�����


fut = 'J';
futureData = struct;
futureData.Date = res.Date;

futureData.mainCont = cellfun(@(x1, y, z) regexp(x1, '\d*(?=\.)', 'match'), res.Cont1); % ��ʵ�ʽ��׵ĺ�Լ����������Լ���غϣ�ֻ��Ϊ������ز�ƽ̨������������Ϊ������Լ
contName = futureData.mainCont;
futureData.Close = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Close'), res.Date, str2double(futureData.mainCont));
futureData.Open = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Open'), res.Date, str2double(futureData.mainCont));
futureData.Settle = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Settle'), res.Date, str2double(futureData.mainCont));
futureData.High = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'High'), res.Date, str2double(futureData.mainCont));
futureData.Low = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Low'), res.Date, str2double(futureData.mainCont));

% ��Լ���±����
contChgLabel = ismember(res.Date, chgInfo.date);

adjFactor = [res.Date str2double(futureData.mainCont) contChgLabel futureData.Open];
adjFactor(:, 5) = [adjFactor(1, 2); adjFactor(1:(end-1), 2)]; % ��Ϊ���Բ����һ��ͻ��£����԰ѵ�һ����ϣ����߻�ͷ��getprice��һ�£�����NaN�Ļ����NaN
adjFactor(:, 6) = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Open'), adjFactor(:, 1), adjFactor(:, 5));%ǰһ���Լ�ڽ���Ŀ��̼�
adjFactor(:, 7) = adjFactor(:, 6) ./ adjFactor(:, 4);
adjFactor(:, 7) = fillone(adjFactor(:, 7));
futureData.adjFactor = [adjFactor(:, 1) adjFactor(:, 7) adjFactor(:, 3)];

save('E:\Repository\hedge\backtestData\strategyPCA\J.mat', 'futureData')


% ����PP��futureData�ز�����
fut = 'JM';
futureData = struct;
futureData.Date = res.Date;

futureData.mainCont = cellfun(@(x1, y, z) regexp(x1, '\d*(?=\.)', 'match'), res.Cont2); % ��ʵ�ʽ��׵ĺ�Լ����������Լ���غϣ�ֻ��Ϊ������ز�ƽ̨������������Ϊ������Լ
futureData.Close = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Close'), res.Date, str2double(futureData.mainCont));
futureData.Open = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Open'), res.Date, str2double(futureData.mainCont));
futureData.Settle = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Settle'), res.Date, str2double(futureData.mainCont));
futureData.High = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'High'), res.Date, str2double(futureData.mainCont));
futureData.Low = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Low'), res.Date, str2double(futureData.mainCont));


adjFactor = [res.Date str2double(futureData.mainCont) contChgLabel futureData.Open];
adjFactor(:, 5) = [adjFactor(1, 2); adjFactor(1:(end-1), 2)]; % ��Ϊ���Բ����һ��ͻ��£����԰ѵ�һ����ϣ����߻�ͷ��getprice��һ�£�����NaN�Ļ����NaN
adjFactor(:, 6) = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Open'), adjFactor(:, 1), adjFactor(:, 5));%ǰһ���Լ�ڽ���Ŀ��̼�
adjFactor(:, 7) = adjFactor(:, 6) ./ adjFactor(:, 4);
adjFactor(:, 7) = fillone(adjFactor(:, 7));
futureData.adjFactor = [adjFactor(:, 1) adjFactor(:, 7) adjFactor(:, 3)];

save('E:\Repository\hedge\backtestData\strategyPCA\JM.mat', 'futureData')
