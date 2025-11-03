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
%  5. 逐条比对（包含空数组边界测试）
%=========================
fprintf('=== MATLAB vs Python 黄金模型 (CRC-8/CCITT) ===\n');
showAll = true;  % 显示全部测试结果
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

    % 显示所有测试结果
    if isempty(vec)
        fprintf('%s Vec%-2d: data=[]  MATLAB=0x%02X  Python=0x%02X (空数组)\n', ...
                flag, i, expected, actual);
    elseif length(vec) <= 10
        % 短向量：显示完整数据
        fprintf('%s Vec%-2d: data=%s  MATLAB=0x%02X  Python=0x%02X\n', ...
                flag, i, mat2str(vec), expected, actual);
    else
        % 长向量：只显示长度和首尾元素
        fprintf('%s Vec%-2d: len=%d [%d...%d]  MATLAB=0x%02X  Python=0x%02X\n', ...
                flag, i, length(vec), vec(1), vec(end), expected, actual);
    end
end

%=========================
%  6. 结果汇总
%=========================
fprintf('======================================================\n');
fprintf('测试汇总：\n');
fprintf('  总测试向量: %d\n', length(results));
fprintf('  通过: %d\n', passed);
fprintf('  失败: %d\n', length(failed));
fprintf('  通过率: %.2f%%\n', 100*passed/length(results));

if ~isempty(failed)
    fprintf('  失败编号: %s\n', mat2str(failed));
    fprintf('\n⚠️  发现失败用例，请检查上方标记为 ✗ 的测试项\n');
else
    fprintf('\n🎉 所有测试向量均通过！MATLAB 与 Python 结果 100%% 一致！\n');
end
fprintf('======================================================\n');

%=========================
%  7. 回家
%=========================
cd(oldFolder);
end