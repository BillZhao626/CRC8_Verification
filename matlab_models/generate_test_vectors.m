function generate_test_vectors()
%=========================
%  1. 记住来时目录
%=========================
oldFolder = pwd;

%=========================
%  2. 到项目根 & 建目录
%=========================
root      = fileparts(fileparts(mfilename('fullpath')));
cd(root);
if ~exist('test_vectors','dir'); mkdir('test_vectors'); end

%=========================
%  3. 构造测试向量
%=========================
basic_vectors = {
    uint8([]); uint8(0); uint8(1); uint8(255);
    uint8([0:255]); uint8([1,2,3,4,5]);
    uint8(1:100); uint8(randi([0 255],1,1000));
    % ↓ 新增 4 条，凑成 20
    uint8(repmat(7,1,50));          % 固定字节
    uint8(randi([0 255],1,777));    % 777 随机
    uint8([255:-1:0]);              % 降序 0~255
    uint8(2.^(0:7))                 % 1,2,4,8,16,32,64,128
};

edge_vectors = {
    uint8([0,0,0,0]); uint8([255,255,255,255]);
    uint8([128,64,32,16]); uint8([1,2,4,8,16,32,64,128])
};

pattern_vectors = {
    uint8(repmat([0x55],1,10)); uint8(repmat([0xAA],1,10));
    uint8(repmat([0x0F],1,10)); uint8(repmat([0xF0],1,10))
};

all_vectors = [basic_vectors(:); edge_vectors(:); pattern_vectors(:)];

%=========================
%  4. 保存 & 清单
%=========================
save('test_vectors/test_vectors.mat', 'all_vectors');

desc = fopen('test_vectors/vector_descriptions.txt','w');
for i = 1:length(all_vectors)
    v = all_vectors{i};
    if isempty(v)
        fprintf(desc,'Vector %d: 空数组\n',i);
    else
        fprintf(desc,'Vector %d: len=%d  first=0x%02X last=0x%02X\n',i,length(v),v(1),v(end));
    end
end
fclose(desc);

fprintf('生成了 %d 个测试向量\n', length(all_vectors));

%=========================
%  5. 回家
%=========================
cd(oldFolder);
end