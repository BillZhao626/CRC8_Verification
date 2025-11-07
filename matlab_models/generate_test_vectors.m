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
%  3. 构造测试向量（约束随机测试）
%=========================
% 3.1 确定性测试向量（20个）- 保留作为基础覆盖
deterministic_vectors = {
    uint8([]); uint8(0); uint8(1); uint8(255);
    uint8([0:255]); uint8([1,2,3,4,5]);
    uint8(1:100); uint8(randi([0 255],1,1000));
    uint8(repmat(7,1,50));          % 固定字节
    uint8(randi([0 255],1,777));    % 777 随机
    uint8([255:-1:0]);              % 降序 0~255
    uint8(2.^(0:7));                % 1,2,4,8,16,32,64,128
    uint8([0,0,0,0]); uint8([255,255,255,255]);
    uint8([128,64,32,16]); uint8([1,2,4,8,16,32,64,128]);
    uint8(repmat([0x55],1,10)); uint8(repmat([0xAA],1,10));
    uint8(repmat([0x0F],1,10)); uint8(repmat([0xF0],1,10));
    % 补充边界和特殊模式
    uint8([0,1,2,3]); uint8([252,253,254,255]);
    uint8([127,128,129]); uint8([0x7F, 0x80]);
    uint8([1,0,1,0]); uint8([0xFF,0x00,0xFF,0x00])
};

% 3.2 约束随机测试向量生成器
fprintf('生成约束随机测试向量...\n');
rng(42);  % 固定随机种子，确保可重现
num_random = 1000 - length(deterministic_vectors);
random_vectors = cell(num_random, 1);

% 约束定义
constraints = struct();
constraints.length_short = [1, 10];      % 短向量：1-10字节
constraints.length_medium = [11, 100];   % 中向量：11-100字节
constraints.length_long = [101, 1000];  % 长向量：101-1000字节

% 长度分布权重（确保不同长度都有覆盖）
length_weights = [0.2, 0.4, 0.4];  % 短:中:长 = 20%:40%:40%

% 模式类型定义
pattern_types = {'random', 'sequential', 'repeated', 'alternating', ...
                 'increasing', 'decreasing', 'boundary', 'mixed'};

for i = 1:num_random
    % 约束1：长度分布（加权随机）
    rand_val = rand();
    if rand_val < length_weights(1)
        len = randi(constraints.length_short);
    elseif rand_val < length_weights(1) + length_weights(2)
        len = randi(constraints.length_medium);
    else
        len = randi(constraints.length_long);
    end
    
    % 约束2：模式类型（均匀分布）
    pattern_idx = randi(length(pattern_types));
    pattern_type = pattern_types{pattern_idx};
    
    % 根据模式类型生成向量
    switch pattern_type
        case 'random'
            % 纯随机：均匀分布
            vec = uint8(randi([0, 255], 1, len));
            
        case 'sequential'
            % 连续序列：从随机起点开始
            start_val = randi([0, 255]);
            vec = uint8(mod(start_val:(start_val+len-1), 256));
            
        case 'repeated'
            % 重复模式：1-4字节的重复
            pattern_len = randi([1, min(4, len)]);
            pattern = uint8(randi([0, 255], 1, pattern_len));
            vec = uint8(repmat(pattern, 1, ceil(len/pattern_len)));
            vec = vec(1:len);
            
        case 'alternating'
            % 交替模式：两个字节交替
            byte1 = randi([0, 255]);
            byte2 = randi([0, 255]);
            vec = uint8(repmat([byte1, byte2], 1, ceil(len/2)));
            vec = vec(1:len);
            
        case 'increasing'
            % 递增：从随机值开始，如果长度超过256则循环
            if len <= 256
                max_start = max(0, 256 - len);
                if max_start < 0
                    max_start = 0;
                end
                start_val = randi([0, max_start]);
                vec = uint8(start_val:(start_val+len-1));
            else
                % 长度超过256，使用模运算循环
                start_val = randi([0, 255]);
                vec = uint8(mod(start_val:(start_val+len-1), 256));
            end
            
        case 'decreasing'
            % 递减：从随机值开始，如果长度超过256则循环
            if len <= 256
                min_start = min(255, len - 1);
                if min_start < 0
                    min_start = 0;
                end
                start_val = randi([min_start, 255]);
                vec = uint8(start_val:-1:(start_val-len+1));
            else
                % 长度超过256，使用模运算循环
                start_val = randi([0, 255]);
                temp_vec = mod(start_val:-1:(start_val-len+1), 256);
                vec = uint8(temp_vec);
            end
            
        case 'boundary'
            % 边界值密集：0x00和0xFF占多数
            boundary_prob = 0.7;  % 70%概率是边界值
            vec = uint8(zeros(1, len));
            for j = 1:len
                if rand() < boundary_prob
                    vec(j) = uint8(randi([0, 1]) * 255);  % 0x00 或 0xFF
                else
                    vec(j) = uint8(randi([0, 255]));
                end
            end
            
        case 'mixed'
            % 混合模式：随机组合多种模式
            % 如果长度太小，退化为随机模式
            if len < 2
                vec = uint8(randi([0, 255], 1, len));
            else
                % 确保段数在有效范围内：至少2段，最多min(10, len)段
                max_segments = min(10, len);
                min_segments = 2;
                if max_segments < min_segments
                    max_segments = min_segments;
                end
                num_segments = randi([min_segments, max_segments]);
                
                % 分配段长度
                segment_lens = randi([1, len], 1, num_segments);
                segment_lens = round(segment_lens / sum(segment_lens) * len);
                % 确保总和正确
                segment_lens(end) = len - sum(segment_lens(1:end-1));
                % 确保每段至少1字节
                segment_lens(segment_lens < 1) = 1;
                if sum(segment_lens) ~= len
                    segment_lens(end) = len - sum(segment_lens(1:end-1));
                end
                
                vec = uint8([]);
                for seg = 1:num_segments
                    seg_type = pattern_types{randi(length(pattern_types))};
                    seg_len = segment_lens(seg);
                    
                    if seg_len <= 0
                        continue;  % 跳过无效段
                    end
                    
                    switch seg_type
                        case 'random'
                            seg_vec = uint8(randi([0, 255], 1, seg_len));
                        case 'repeated'
                            pattern = uint8(randi([0, 255], 1, 1));
                            seg_vec = uint8(repmat(pattern, 1, seg_len));
                        case 'sequential'
                            start = randi([0, 255]);
                            seg_vec = uint8(mod(start:(start+seg_len-1), 256));
                        otherwise
                            seg_vec = uint8(randi([0, 255], 1, seg_len));
                    end
                    vec = [vec, seg_vec];
                end
                % 确保长度正确
                if length(vec) > len
                    vec = vec(1:len);
                elseif length(vec) < len
                    % 如果不够，用随机值填充
                    vec = [vec, uint8(randi([0, 255], 1, len - length(vec)))];
                end
            end
    end
    
    random_vectors{i} = vec;
    
    % 进度显示
    if mod(i, 100) == 0
        fprintf('  已生成 %d/%d 个随机向量\n', i, num_random);
    end
end

% 3.3 合并所有向量
all_vectors = [deterministic_vectors(:); random_vectors(:)];

fprintf('生成了 %d 个确定性向量 + %d 个约束随机向量 = 总计 %d 个测试向量\n', ...
        length(deterministic_vectors), num_random, length(all_vectors));

%=========================
%  4. 保存 & 清单
%=========================
save('test_vectors/test_vectors.mat', 'all_vectors');

desc = fopen('test_vectors/vector_descriptions.txt','w');
fprintf(desc, 'CRC-8 测试向量描述（约束随机测试）\n');
fprintf(desc, '========================================\n');
fprintf(desc, '总计: %d 个测试向量\n', length(all_vectors));
fprintf(desc, '  - 确定性向量: %d 个\n', length(deterministic_vectors));
fprintf(desc, '  - 约束随机向量: %d 个\n', num_random);
fprintf(desc, '\n');

% 统计信息
lengths = zeros(length(all_vectors), 1);
for i = 1:length(all_vectors)
    lengths(i) = length(all_vectors{i});
end

fprintf(desc, '长度分布统计:\n');
fprintf(desc, '  空数组: %d 个\n', sum(lengths == 0));
fprintf(desc, '  短向量(1-10): %d 个\n', sum(lengths >= 1 & lengths <= 10));
fprintf(desc, '  中向量(11-100): %d 个\n', sum(lengths >= 11 & lengths <= 100));
fprintf(desc, '  长向量(101-1000): %d 个\n', sum(lengths >= 101 & lengths <= 1000));
fprintf(desc, '  平均长度: %.1f 字节\n', mean(lengths));
fprintf(desc, '  最大长度: %d 字节\n', max(lengths));
fprintf(desc, '\n');

% 详细描述前100个向量（包含所有确定性向量）
fprintf(desc, '详细描述（前100个向量）:\n');
fprintf(desc, '----------------------------------------\n');
for i = 1:min(100, length(all_vectors))
    v = all_vectors{i};
    if isempty(v)
        fprintf(desc,'Vector %4d: 空数组\n', i);
    else
        fprintf(desc,'Vector %4d: len=%4d  first=0x%02X last=0x%02X', ...
                i, length(v), v(1), v(end));
        if i <= length(deterministic_vectors)
            fprintf(desc, ' [确定性]');
        else
            fprintf(desc, ' [随机]');
        end
        fprintf(desc, '\n');
    end
end

if length(all_vectors) > 100
    fprintf(desc, '\n... (其余 %d 个向量为约束随机生成，详见统计信息)\n', ...
            length(all_vectors) - 100);
end

fclose(desc);

fprintf('测试向量已保存到 test_vectors/test_vectors.mat\n');
fprintf('描述文件已保存到 test_vectors/vector_descriptions.txt\n');

%=========================
%  5. 回家
%=========================
cd(oldFolder);
end