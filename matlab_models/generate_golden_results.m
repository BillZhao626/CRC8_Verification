function generate_golden_results()
%=========================
%  1. 记住来时目录
%=========================
oldFolder = pwd;

%=========================
%  2. 到项目根 & 建目录
%=========================
root = fileparts(fileparts(mfilename('fullpath')));
cd(root);
if ~exist('results','dir')
    mkdir('results');
end

%=========================
%  3. 加载测试向量（MATLAB 2022b 兼容写法）
%=========================
load('test_vectors/test_vectors.mat', 'all_vectors');  % 只加载变量
all_vectors = all_vectors;                             % 先赋值再索引

%=========================
%  4. CRC-8 变体配置
%=========================
variants   = {'ccitt','maxim','autosar'};
variantCfg = struct( ...
    'ccitt',   struct('poly',uint8(0x07),'init',uint8(0x00),'refIn',false,'refOut',false,'xorOut',uint8(0x00)), ...
    'maxim',   struct('poly',uint8(0x31),'init',uint8(0x00),'refIn',true, 'refOut',true, 'xorOut',uint8(0x00)), ...
    'autosar', struct('poly',uint8(0x2F),'init',uint8(0xFF),'refIn',false,'refOut',false,'xorOut',uint8(0xFF)) );

%=========================
%  5. 为每个变体生成黄金结果（跳过空数组）
%=========================
for v = 1:length(variants)
    varName = variants{v};
    cfg     = variantCfg.(varName);
    results = struct();

    for i = 1:length(all_vectors)
        vec = all_vectors{i};
        
        % 处理空数组和非空数组
        if isempty(vec)
            % 空数组：CRC值为初始值（对于CCITT就是0x00）
            crc = cfg.init;
        else
            % 非空数组：正常计算CRC
            crc = crc8_golden(vec, cfg.poly, cfg.init, cfg.refIn, cfg.refOut, cfg.xorOut);
        end

        results(i).input_length = length(vec);
        results(i).input_data   = vec;
        results(i).crc_value    = crc;
        results(i).variant      = varName;
    end

    % 保存 .mat + .csv
    save(['results/golden_' varName '.mat'], 'results');
    export_csv(results, ['results/golden_' varName '.csv']);
end

fprintf('黄金参考值生成完成\n');

%=========================
%  6. 回家
%=========================
cd(oldFolder);

%==================================================
% 子函数：导出 CSV
%==================================================
function export_csv(results, file)
    fid = fopen(file,'w');
    fprintf(fid,'Index,Length,Input_Data,CRC_Value\n');
    for i = 1:length(results)
        r = results(i);
        fprintf(fid,'%d,%d,"%s",0x%02X\n', ...
                i, r.input_length, mat2str(r.input_data), r.crc_value);
    end
    fclose(fid);
end
end