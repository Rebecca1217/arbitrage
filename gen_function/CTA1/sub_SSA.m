function [SSA,V] = sub_SSA(TableDataI,win,k,dataType)
% ���������׷ֽ���
% win:������
% k:��ȡ�����ɷָ���
% dataType:ѡ��ļ۸�

data = eval(['TableDataI.',dataType]);
% ת���ɣ�len-win+1,win�����ƶ����ھ���
H = zeros(length(data)-win+1,win);
for j = 1:length(data)-win+1
    H(j,:) = data(j:j+win-1); 
end
% �������ѭ��������hankel��������
% H = hankel(data(1:(length(data) -win + 1)), data((length(data) - win + 1): length(data)));
% �ȶ�H��һ������ֵ��׼������ ����C���ܳ�֮ΪЭ�������
% H = H - mean(H);
% ����H��Э�������
C = H'*H; % C������Э������󣬹�����ô�а�...���������ֻ�ǰѷǷ���ת��Ϊ�������ڼ�������ֵ
% ��C������ֵ�ֽ� % C�Ƿ�����ʵ��������ֵ�ֽ⣬����Ŀ�����õ�����ֵ H(a*b)
% ��a>=b������£�Hsvd������V��H'Hsvd������V��һ���ģ�����a<b�Ļ�����b-a����Ĳ��ֲ�һ������һ�еķ���Ҳ��һ������֪Ϊɶ,�Ҿ��ÿ�����matlab�����ļ��㷽ʽ����
[V,~,~] = svd(C); 
% disp(abs(sigma(1, 1)) / sum(sum(abs(sigma)))) ��һ��������ƽ��ռ��80%����
% ȡ��k����������
Vk = V(:,k); % ��k����������
Pk = H*Vk;
% ��k�����ɷ��ع���H
Hk = Pk*Vk';
% �Խ�ƽ������
a = zeros(length(data),1);
a(1:win-1) = 1:win-1;
a(length(data)-win+2:length(data)) = win-1:-1:1;
a(win:length(data)-win+1) = win; % ��仰��length(data)<2winʱû��...
SSA = zeros(length(data),1);
for p = 1:length(data)
    for j = max([1,p+win-length(data)]):min([win,p])
        SSA(p) = SSA(p)+Hk(p-j+1,j);
    end
end
SSA = 1./a.*SSA;
        
    