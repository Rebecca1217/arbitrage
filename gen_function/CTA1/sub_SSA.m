function [SSA,V] = sub_SSA(TableDataI,win,k,dataType)
% 计算奇异谱分解结果
% win:窗口期
% k:截取的主成分个数
% dataType:选择的价格

data = eval(['TableDataI.',dataType]);
% 转换成（len-win+1,win）的移动窗口矩阵
H = zeros(length(data)-win+1,win);
for j = 1:length(data)-win+1
    H(j,:) = data(j:j+win-1); 
end
% 上面这个循环可以用hankel函数代替
% H = hankel(data(1:(length(data) -win + 1)), data((length(data) - win + 1): length(data)));
% 先对H做一个减均值标准化处理， 这样C才能称之为协方差矩阵
% H = H - mean(H);
% 计算H的协方差矩阵
C = H'*H; % C并不是协方差矩阵，姑且这么叫吧...我理解这里只是把非方阵转化为方阵用于计算特征值
% 对C做奇异值分解 % C是方阵，其实就是特征值分解，最终目的是拿到特征值 H(a*b)
% 在a>=b的情况下，Hsvd出来的V和H'Hsvd出来的V是一样的，但是a<b的话除了b-a后面的部分不一样，第一列的符号也不一样，不知为啥,我觉得可能是matlab函数的计算方式问题
[V,~,~] = svd(C); 
% disp(abs(sigma(1, 1)) / sum(sum(abs(sigma)))) 第一个特征根平均占比80%左右
% 取第k个特征向量
Vk = V(:,k); % 第k个特征向量
Pk = H*Vk;
% 由k个主成分重构的H
Hk = Pk*Vk';
% 对角平滑处理
a = zeros(length(data),1);
a(1:win-1) = 1:win-1;
a(length(data)-win+2:length(data)) = win-1:-1:1;
a(win:length(data)-win+1) = win; % 这句话在length(data)<2win时没用...
SSA = zeros(length(data),1);
for p = 1:length(data)
    for j = max([1,p+win-length(data)]):min([win,p])
        SSA(p) = SSA(p)+Hk(p-j+1,j);
    end
end
SSA = 1./a.*SSA;
        
    