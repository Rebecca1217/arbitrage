function Boll = mergeBoll(BollN,Boll,stL,edL)
% ��ÿ����Լ��Bollƴ������

bnames = fieldnames(BollN);
if isempty(Boll)
    for i = 1:length(bnames)
        str = ['Boll.',bnames{i},' = [];'];
        eval(str)
    end
end

for i = 1:length(bnames)
    str = ['Boll.',bnames{i},' = [Boll.',bnames{i},';BollN.',bnames{i},'(stL:edL,:)];'];
    eval(str)
end

