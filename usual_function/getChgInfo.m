function chgInfo = getChgInfo(chgInfo0,stDate,edDate)
% ȥ�������ز����Ļ�������

date = cell2mat(chgInfo0(:,1));
cont1 = chgInfo0(:,2);
cont2 = chgInfo0(:,3);
cont1 = regexp(cont1,'\w*(?=\.)','match');
cont2 = regexp(cont2,'\w*(?=\.)','match');
cont1 = reshape([cont1{:}],size(cont1));
cont2 = reshape([cont2{:}],size(cont2));

stL = find(date>=stDate,1,'first');
edL = find(date<=edDate,1,'last');
chgInfo = [num2cell(date),cont1,cont2];
chgInfo = chgInfo(stL:edL,:);
