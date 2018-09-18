% 需要的列：Date, Close, Open, Settle, High, Low, adjFactor, mainCont（实际不一定是什么Cont）
% 替代futureData
% 构造J的futureData回测数据


fut = 'J';
futureData = struct;
futureData.Date = res.Date;

futureData.mainCont = cellfun(@(x1, y, z) regexp(x1, '\d*(?=\.)', 'match'), res.Cont1); % 是实际交易的合约，和主力合约不重合，只是为了输入回测平台方便所以命名为主力合约
contName = futureData.mainCont;
futureData.Close = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Close'), res.Date, str2double(futureData.mainCont));
futureData.Open = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Open'), res.Date, str2double(futureData.mainCont));
futureData.Settle = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Settle'), res.Date, str2double(futureData.mainCont));
futureData.High = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'High'), res.Date, str2double(futureData.mainCont));
futureData.Low = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Low'), res.Date, str2double(futureData.mainCont));

% 合约换月标记日
contChgLabel = ismember(res.Date, chgInfo.date);

adjFactor = [res.Date str2double(futureData.mainCont) contChgLabel futureData.Open];
adjFactor(:, 5) = [adjFactor(1, 2); adjFactor(1:(end-1), 2)]; % 因为策略不会第一天就换月，所以把第一天填补上，或者回头把getprice改一下，输入NaN的话输出NaN
adjFactor(:, 6) = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Open'), adjFactor(:, 1), adjFactor(:, 5));%前一天合约在今天的开盘价
adjFactor(:, 7) = adjFactor(:, 6) ./ adjFactor(:, 4);
adjFactor(:, 7) = fillone(adjFactor(:, 7));
futureData.adjFactor = [adjFactor(:, 1) adjFactor(:, 7) adjFactor(:, 3)];

save('E:\Repository\hedge\backtestData\strategyPCA\J.mat', 'futureData')


% 构造PP的futureData回测数据
fut = 'JM';
futureData = struct;
futureData.Date = res.Date;

futureData.mainCont = cellfun(@(x1, y, z) regexp(x1, '\d*(?=\.)', 'match'), res.Cont2); % 是实际交易的合约，和主力合约不重合，只是为了输入回测平台方便所以命名为主力合约
futureData.Close = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Close'), res.Date, str2double(futureData.mainCont));
futureData.Open = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Open'), res.Date, str2double(futureData.mainCont));
futureData.Settle = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Settle'), res.Date, str2double(futureData.mainCont));
futureData.High = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'High'), res.Date, str2double(futureData.mainCont));
futureData.Low = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Low'), res.Date, str2double(futureData.mainCont));


adjFactor = [res.Date str2double(futureData.mainCont) contChgLabel futureData.Open];
adjFactor(:, 5) = [adjFactor(1, 2); adjFactor(1:(end-1), 2)]; % 因为策略不会第一天就换月，所以把第一天填补上，或者回头把getprice改一下，输入NaN的话输出NaN
adjFactor(:, 6) = arrayfun(@(x1, y, z, o) getprice(x1, y, fut, 'Open'), adjFactor(:, 1), adjFactor(:, 5));%前一天合约在今天的开盘价
adjFactor(:, 7) = adjFactor(:, 6) ./ adjFactor(:, 4);
adjFactor(:, 7) = fillone(adjFactor(:, 7));
futureData.adjFactor = [adjFactor(:, 1) adjFactor(:, 7) adjFactor(:, 3)];

save('E:\Repository\hedge\backtestData\strategyPCA\JM.mat', 'futureData')
