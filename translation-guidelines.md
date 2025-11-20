# Zig技术文档翻译规范

## 翻译原则
- **信**: 技术术语准确，概念传达无误
- **达**: 语句通顺自然，符合中文表达习惯
- **雅**: 文风优雅，保持技术文档的专业性

## 保留内容
- 所有代码块（programlisting标签内容）
- Mermaid图表定义
- 技术术语和专有名词（如Zig、comptime、allocator等）
- 链接和交叉引用
- XML标签和属性

## 技术术语翻译规范

### 基础术语
- Zig → Zig（保持原样）
- comptime → 编译时
- allocator → 分配器
- module → 模块
- function → 函数
- variable → 变量
- constant → 常量
- struct → 结构体
- enum → 枚举
- union → 联合体
- error → 错误
- memory → 内存
- performance → 性能
- safety → 安全性
- cross-compilation → 交叉编译
- WebAssembly → WebAssembly（保持原样）

### 压缩与归档术语
- Decompress → 解压缩
- Compress → 压缩
- Stream → 流
- Archive → 归档
- Buffer → 缓冲区
- Iterator → 迭代器
- Metadata → 元数据
- Checksum → 校验和
- Payload → 有效负载
- Registry → 注册表
- Firmware → 固件
- Deterministic → 确定性
- Ring buffer → 环形缓冲区
- Scratch buffer → 临时缓冲区
- Peak memory → 峰值内存
- Stack-allocated → 栈分配
- Heap-allocated → 堆分配

### 算法与数据格式（保留不译）
- Deflate → Deflate算法
- gzip → gzip格式
- zlib → zlib库
- LZMA2 → LZMA2算法
- xz → xz格式
- zstd → zstd格式
- tar → TAR格式
- zip → ZIP格式
- Byte-for-byte → 逐字节
- Window → 窗口
- Flate → Flate容器

### 构建与调试术语
- ReleaseFast → ReleaseFast模式
- Debug build → 调试构建
- Release build → 发布构建
- Valgrind → Valgrind工具
- Leak detection → 泄漏检测
- Heap profiling → 堆分析
- Stack trace → 堆栈跟踪

## 翻译风格
- 使用正式的技术文档语言
- 避免口语化表达
- 保持技术概念的准确性
- 使用主动语态，增强可读性
- 适当使用技术术语，避免过度简化

## 特殊处理
- 引号保持原文格式
- 书名号使用中文《》
- 代码注释保持原样
- 文件名和路径保持原样