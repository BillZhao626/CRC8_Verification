function verify_python_golden()
%=========================
%  1. 记住来时目录
%=========================
oldFolder = pwd;

%=========================
%  2. 到项目根
%=========================
root = fileparts(fileparts(mfilename('fullpath')));
cd(root);

%=========================
%  3. 加载 MATLAB 黄金参考（CRC-8/CCITT, poly 0x07）
%=========================
load('results/golden_ccitt.mat');   % 变量名：results
total   = length(results);
passed  = 0;
failed  = [];

%=========================
%  4. 把"cursor_code"目录加入 Python 搜索路径（2022b+ 语法）
%=========================
sysPath = py.sys.path();                               % 取路径列表
cursorDir = fullfile(root, 'cursor_code');
if ~any(strcmp(string(sysPath), cursorDir))
    sysPath.append(cursorDir);                         % 括号语法
end

% 直接导模块（cursor_code 不是包，用文件级导入）
pyMod = py.importlib.import_module('golden_crc8');   % 文件 golden_crc8.py
pyCRC = pyMod.calculate_crc8;                        % 拿函数

%=========================
%  5. 逐条比对（约束随机测试，1000个向量）
%=========================
fprintf('=== MATLAB vs Python 黄金模型 (CRC-8/CCITT) ===\n');
fprintf('约束随机测试：%d 个测试向量\n', length(results));
showAll = false;  % 默认只显示前20个确定性向量+失败向量
showProgress = true;  % 显示进度
num_deterministic = 20;  % 确定性向量数量（前20个）

fprintf('显示模式: 前%d个确定性向量 + 所有失败向量\n', num_deterministic);
if showAll
    fprintf('(已启用显示全部模式)\n');
end
fprintf('------------------------------------------------------\n');

for i = 1:length(results)
    vec      = results(i).input_data;
    expected = results(i).crc_value;      % MATLAB 结果

    % 字节数组 → Python bytes（关键：直接传递字节值，不经过字符编码）
    % 处理空数组和非空数组
    if isempty(vec)
        % 空数组：直接创建空 bytes
        pyBytes = py.bytes();
    else
        % 非空数组：逐个转换为 Python list
        pyList = py.list();
        for k = 1:length(vec)
            pyList.append(int64(vec(k)));  % 转为 Python int
        end
        pyBytes = py.bytes(pyList);        % list → bytes
    end
    actual   = double(pyCRC(pyBytes));     % Python 返回 int

    if actual == expected
        passed = passed + 1;
        flag = '✓';
    else
        failed = [failed, i];
        flag = '✗';
    end

    % 显示策略：前20个确定性向量 + 所有失败向量 + (可选)全部
    should_display = showAll || i <= num_deterministic || actual ~= expected;
    
    if should_display
        if isempty(vec)
            fprintf('%s Vec%4d: data=[]  MATLAB=0x%02X  Python=0x%02X (空数组)\n', ...
                    flag, i, expected, actual);
        elseif length(vec) <= 10
            % 短向量：显示完整数据
            fprintf('%s Vec%4d: data=%s  MATLAB=0x%02X  Python=0x%02X\n', ...
                    flag, i, mat2str(vec), expected, actual);
        else
            % 长向量：只显示长度和首尾元素
            fprintf('%s Vec%4d: len=%4d [0x%02X...0x%02X]  MATLAB=0x%02X  Python=0x%02X\n', ...
                    flag, i, length(vec), vec(1), vec(end), expected, actual);
        end
    end
    
    % 进度显示（每100个）
    if showProgress && mod(i, 100) == 0
        fprintf('  进度: %d/%d (%.1f%%)  通过: %d  失败: %d\n', ...
                i, length(results), 100*i/length(results), passed, length(failed));
    end
end

%=========================
%  6. 结果汇总（详细统计）
%=========================
fprintf('======================================================\n');
fprintf('测试汇总：\n');
fprintf('  总测试向量: %d\n', length(results));
fprintf('  通过: %d\n', passed);
fprintf('  失败: %d\n', length(failed));
fprintf('  通过率: %.2f%%\n', 100*passed/length(results));

% 按长度范围统计
lengths = zeros(length(results), 1);
for i = 1:length(results)
    lengths(i) = length(results(i).input_data);
end

% 统计各长度范围的通过情况
empty_idx = lengths == 0;
short_idx = lengths >= 1 & lengths <= 10;
medium_idx = lengths >= 11 & lengths <= 100;
long_idx = lengths >= 101 & lengths <= 1000;

empty_total = sum(empty_idx);
empty_passed = empty_total - sum(ismember(find(empty_idx), failed));
short_total = sum(short_idx);
short_passed = short_total - sum(ismember(find(short_idx), failed));
medium_total = sum(medium_idx);
medium_passed = medium_total - sum(ismember(find(medium_idx), failed));
long_total = sum(long_idx);
long_passed = long_total - sum(ismember(find(long_idx), failed));

fprintf('\n按长度范围统计：\n');
fprintf('  空数组: %d/%d (%.1f%%)\n', ...
        empty_passed, empty_total, 100*empty_passed/max(1,empty_total));
fprintf('  短向量(1-10): %d/%d (%.1f%%)\n', ...
        short_passed, short_total, 100*short_passed/max(1,short_total));
fprintf('  中向量(11-100): %d/%d (%.1f%%)\n', ...
        medium_passed, medium_total, 100*medium_passed/max(1,medium_total));
fprintf('  长向量(101-1000): %d/%d (%.1f%%)\n', ...
        long_passed, long_total, 100*long_passed/max(1,long_total));

% 确定性向量 vs 随机向量统计
deterministic_passed = num_deterministic - sum(failed <= num_deterministic);
random_passed = passed - deterministic_passed;
random_total = length(results) - num_deterministic;

fprintf('\n按测试类型统计：\n');
fprintf('  确定性向量: %d/%d (%.1f%%)\n', ...
        deterministic_passed, num_deterministic, ...
        100*deterministic_passed/num_deterministic);
fprintf('  约束随机向量: %d/%d (%.1f%%)\n', ...
        random_passed, random_total, 100*random_passed/max(1,random_total));

if ~isempty(failed)
    fprintf('\n⚠️  发现失败用例，请检查上方标记为 ✗ 的测试项\n');
    fprintf('  失败编号: ');
    if length(failed) <= 20
        fprintf('%s\n', mat2str(failed));
    else
        fprintf('%s ... (共%d个)\n', mat2str(failed(1:20)), length(failed));
    end
else
    fprintf('\n🎉 所有测试向量均通过！MATLAB 与 Python 结果 100%% 一致！\n');
    fprintf('   约束随机测试验证了算法在各种数据模式下的行为一致性\n');
end
fprintf('======================================================\n');

%=========================
%  7. 回家
%=========================
cd(oldFolder);
end