function [tdList,sigAdj] = cal_rtn(sig,beta,tddata,date,c_stD,c_edD,Cost,oriAsset)
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
% ���⿪ʼ��70���ǽ�ԭʼ�ź��޳����źţ��õ������Ŀ�ƽ���ź�
sigOp = sig(:,1);
sigCl = sig(:,2);
% ��ƽ���ź�������
sigLi = zeros(length(sigOp),3); % ���򣬿�ƽ�ź�������
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
% ��ʼ
stS = find(and(sigLi(:,2)<=stL,sigLi(:,3)>=stL),1,'first'); %�����Լ��Ϊ������Լ֮ʱ�ĵ�һ�������źţ�����֮ǰ�Ϳ��֣��������ƽ�ֵ����
if isempty(stS) %��һ����Լ������������⣬��Ϊ�Ǵ�ĳ��Ʒ�ֵ������տ�ʼ��
    stS = find(and(sigLi(:,2)>=stL,sigLi(:,2)<=edL),1,'first'); % ���û��������������ҵ�һ����������ſ��ֵ��ź�
    if isempty(stS) %�������Լ��Ϊ������Լ�ڼ䣬û�з��������ź�
        tdList = [date,zeros(length(sig),8)];
        tdList(:,end) = oriAsset;
        sigAdj = zeros(size(sig));
        return;
    end
end
if stS>1
    sigLi(1:stS-1,:) = []; %�Ѹú�Լ��û��Ϊ������Լʱ��Ŀ����ź�ȥ��
    sigLi(1,2) = stL-1;  % stL��ʱ�����������Լ��stL-1��ʱ������һ����Լ��������Լ�أ���ǰ��Լ��Ϊ������Լ�ĵ�һ�ν���Ӧ�ô�stL��ʼ�ɣ�����
end
% ����
edS = find(and(sigLi(:,2)<=edL,sigLi(:,3)>=edL),1,'last'); %�����Լ��Ϊ������Լ֮������һ�������ź�
if isempty(edS) %����Ҳ��������źţ������ʱ��֮ǰƽ���ˣ�����û���µĿ����ź�
    edS = find(sigLi(:,3)<=edL,1,'last'); %�����ʱ��֮ǰ���һ��ƽ���ź�������
    sigLi(edS+1:end,:) = [];
else
    sigLi(edS+1:end,:) = [];
    sigLi(end,3) = edL;
end


% �۸�����
tddata1 = tddata(:,1); %��һ��Ʒ��
tddata2 = tddata(:,2); %�ڶ���Ʒ��

% �ز�
tdList = zeros(length(sig),8);
num = size(sigLi,1);
asset = oriAsset;
tdList(1:sigLi(1,2),8) = asset;
for i = 1:num %����źż���
    opL = sigLi(i,2); %�����ź�������
    clL = sigLi(i,3); %ƽ���ź�������
    sgn1 = sigLi(i,1); %���ַ���-��һ��Ʒ�ֵķ���
    sgn2 = -sigLi(i,1); %���ַ���-�ڶ���Ʒ�ֵķ���
    sgn = sigLi(i,1);
    if clL-opL>1 %���ǵ������¸�ƽ�����
        tdList(opL+1:clL-1,1) = sgn;
        tdList(opL+1,2) = 2-sgn; %��տ�
        tdList(clL,2) = 3-sgn; %���ƽ
        % ��������ÿ����ƽ��
        chgH1 = 0;
        chgH2 = 0;
        for d = opL:clL-1
            % ���㿪������
            hands = calOpenHands(closedata(d,:),Ratio(d),asset,contM1,contM2); %��ǰһ������̼�ȥ���㵱�������
            if d==opL %����ʱ������
                h1 = hands(1);
                h2 = hands(2);
            end
            if d>opL %����ڿ���ʱ�����ı仯
                chgH1 = hands(1)-h1;
                chgH2 = hands(2)-h2;
            end
            if abs(chgH1)>2 || abs(chgH2)>2 %����Ʒ��������һ���ĳֲ������仯����2�֣�������Ʒ��һ�����
                tdList(d+1,5) = hands(1);
                tdList(d+1,6) = hands(2);
                h1 = hands(1);
                h2 = hands(2);
            else
                tdList(d+1,5) = h1;
                tdList(d+1,6) = h2;
            end
        end
        % ����ÿ������
        for d = opL+1:clL
            % Ʒ�ֱַ���к��㣬Ȼ�����
            h1 = tdList(d,5);
            h2 = tdList(d,6);
            if d==opL+1 %����
                % Ʒ��1
                op1 = (tddata1(d)+sgn1*slip*unit1)*(1+sgn1*fixC)*contM1*h1; %���ּ�
                cl1 = closedata(d,1)*contM1*h1; %����ƽ�ּ�
                % Ʒ��2
                op2 = (tddata2(d)+sgn2*slip*unit2)*(1+sgn2*fixC)*contM2*h2; %���ּ�
                cl2 = closedata(d,2)*contM2*h2; %����ƽ�ּ�
                % ����ӯ��
                tdList(d,7) = (-sgn1*op1+sgn1*cl1)+(-sgn2*op2+sgn2*cl2);
                tdList(d,8) = asset+tdList(d,7); %�ۼ���ֵ
                % ���ּ۲�
                tdList(d,3) = op1-op2;
            elseif d>opL+1 && d<=clL %�ǿ�ƽ����
                % Ʒ��1
                hChg1 = h1-tdList(d-1,5); %�����仯
                op1 = closedata(d-1,1)*contM1*h1; %��ǰһ������̼ۿ���
                cl1 = closedata(d,1)*contM1*h1; %����ƽ�ּ�
                %                 opChg1 = (tddata1(d)+sgn1*slip*unit1)*(1+sgn1*fixC)*contM1*hChg1; %���ּ�
                % �о�����ط������㣬��Ҫ���ǽ�ȥhChg1�ķ���
                opChg1 = (tddata1(d)+sgn1*slip*unit1 * sign(hChg1))*(1+sgn1*fixC)*contM1*hChg1; %���ּ�
                clChg1 = closedata(d,1)*contM1*hChg1; %ƽ�ּ�
                % Ʒ��2
                hChg2 = h2-tdList(d-1,6); %�����仯
                op2 = closedata(d-1,2)*contM2*h2; %��ǰһ������̼ۿ���
                cl2 = closedata(d,2)*contM2*h2; %����ƽ�ּ�
                %                 opChg2 = (tddata2(d)+sgn2*slip*unit2)*(1+sgn2*fixC)*contM2*hChg2; %���ּ�
                opChg2 = (tddata2(d)+sgn2*slip*unit2 * sign(hChg2))*(1+sgn2*fixC)*contM2*hChg2; %���ּ�
                clChg2 = closedata(d,2)*contM2*hChg2; %ƽ�ּ�
                % ����ӯ��
                tdList(d,7) = (-sgn1*op1+sgn1*cl1)+(-sgn1*opChg1+sgn1*clChg1)+...
                    (-sgn2*op2+sgn2*cl2)+(-sgn2*opChg2+sgn2*clChg2);
                tdList(d,8) = tdList(d-1,8)+tdList(d,7); %�ۼ���ֵ
            end
            if d==clL %ƽ��
                % ƽ�ֵ�ʱ��Ҫ�ѵڶ���ƽ�ִ�����������㵽�����һ������
                % Ʒ��1
                op1 = closedata(d,1)*contM1*h1; %��ǰһ������̼ۿ���
                cl1 = (tddata1(d+1)-sgn1*slip*unit1)*(1-sgn1*fixC)*contM1*h1; %ƽ�ּ�
                % Ʒ��2
                op2 = closedata(d,2)*contM2*h2;
                cl2 = (tddata2(d+1)-sgn2*slip*unit2)*(1-sgn2*fixC)*contM2*h2;
                % ����ӯ��
                tdList(d,7) = tdList(d,7)+(-sgn1*op1+sgn1*cl1)+(-sgn2*op2+sgn2*cl2);
                tdList(d,8) = tdList(d,8)+(-sgn1*op1+sgn1*cl1)+(-sgn2*op2+sgn2*cl2);
                % ƽ�ּ۲�
                tdList(d,4) = op1-op2;
            end
        end
    end
    if clL-opL==1 %�������¸�ƽ
        tdList(opL+1,1) = sgn;
        tdList(opL+1,2) = 5.5-0.5*sgn;
        hands = calOpenHands(closedata(opL,:),Ratio(opL),asset,contM1,contM2); %��ǰһ������̼�ȥ���㵱�������
        tdList(opL+1,5) = hands(1);
        tdList(opL+1,6) = hands(2);
        % Ʒ��1
        h1 = hands(1);
        op1 = (tddata1(opL+1)+sgn1*slip*unit1)*(1+sgn1*fixC)*contM1*h1; %���ּ�
        cl1 = (tddata1(clL+1)+sgn1*slip*unit1)*(1+sgn1*fixC)*contM1*h1; %ƽ�ּ�
        % Ʒ��2
        h2 = hands(2);
        op2 = (tddata2(opL+1)+sgn2*slip*unit2)*(1+sgn2*fixC)*contM2*h2; %���ּ�
        cl2 = (tddata2(clL+1)+sgn2*slip*unit2)*(1+sgn2*fixC)*contM2*h2; %ƽ�ּ�
        % ����ӯ��
        tdList(opL+1,7) = (-sgn1*op1+sgn1*cl1)+(-sgn2*op2+sgn2*cl2);
        tdList(opL+1,8) = asset+tdList(opL+1,7);
        % ��ƽ�ּ۲�
        tdList(opL+1,3) = op1-op2;
        tdList(opL+1,4) = cl1-cl2;
    end
    
    % ��ֵ����
    asset = tdList(clL,8);
    % ��ֵ���
    if i<num
        tdList(clL+1:sigLi(i+1,2),8) = asset;
    else
        tdList(clL:end,8) = asset;
    end
    
end

tdList = [date,tdList];

% ����sig
sigAdj = zeros(size(sig));
sigAdj(sigLi(:,2),1) = sigLi(:,1);
sigAdj(sigLi(:,3),2) = -sigLi(:,1);






