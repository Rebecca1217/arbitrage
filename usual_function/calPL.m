function [outputArg1,outputArg2] = calPL(sig,inputArg2)
% tdList:�ֲַ��򣬿���ʱ�㣬���ּ۲ƽ�ּ۲�, Ʒ��1������Ʒ��2����������ӯ�����,�ۼ��ʲ�
% �ÿ���ǰһ������̼ۼ��㿪������
% c_edD�Ǿɺ�Լ�����һ�죬�ɺ�Լ��ƽ��ʱ��Ӧ������һ��ƽ��

% ���׳ɱ�
fixC = Cost.fix;
slip = Cost.float;
unit1 = Cost.unit1; %��С�䶯��λ
unit2 = Cost.unit2;
contM1 = Cost.contM1; %��Լ����
contM2 = Cost.contM2;

% ���׼�
closedata = tddata(:,3:4); %���̼�
tddata = tddata(:,1:2); %�ɽ���
Ratio = beta;

% ��ƽ���ź�
sigOp = sig(:,1); % ���ֱ��
sigCl = sig(:,2); % ƽ�ֱ��
sigLi = zeros(length(sigOp),3); % ���򣬿�ƽ�ź������� ��3�У���һ���źŷ��򣬵ڶ��п����кţ������ж�Ӧƽ���к�
c = 1;
for t = 1:size(sigLi,1)
    opL = find(sigOp(c:end)~=0,1,'first')+c-1;
    if isempty(opL) || opL==length(sigOp)
        break;
    else
        sigLi(t,1) = sigOp(opL);
        sigLi(t,2) = opL;
    end
    clL = find(sigCl(opL+1:end)==-sigOp(opL),1,'first')+opL;
    if isempty(clL)
        sigLi(t,3) = size(sigLi,1);
        break;
    else
        sigLi(t,3) = clL;
        c = clL;
    end
end
sigLi(sigLi(:,1)==0,:) = [];
% ��ƽ���źŸ��ݺ�Լ��������ʱ����е���
stL = find(date==c_stD,1);
edL = find(date==c_edD,1);





end

