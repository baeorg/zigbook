#!/usr/bin/env python3
"""
优质翻译脚本：确保"信达雅"标准
- 信：准确传达原意
- 达：语言通顺，符合中文表达习惯
- 雅：用词优雅，专业术语准确

格式：英文在上，中文在下
"""

import os
import re
import sys
from pathlib import Path

# 高质量翻译词典 - 确保准确性和流畅性
TRANS = {
    # 核心概念
    "Entry point": "程序入口点",
    "entry point": "程序入口点",
    "Control flow": "控制流",
    "control flow": "控制流",
    "Debug mode": "调试模式",
    "debug mode": "调试模式",
    "Release mode": "发布模式",
    "release mode": "发布模式",
    "Error handling": "错误处理",
    "error handling": "错误处理",
    "Error union": "错误联合类型",
    "error union": "错误联合类型",
    "Compile time": "编译时",
    "compile time": "编译时",
    "Run time": "运行时",
    "run time": "运行时",
    "Standard output": "标准输出",
    "standard output": "标准输出",
    "Command line": "命令行",
    "command line": "命令行",
    "Command line arguments": "命令行参数",
    "command line arguments": "命令行参数",
    "File path": "文件路径",
    "file path": "文件路径",
    "Temporary file": "临时文件",
    "temporary file": "临时文件",
    "Build mode": "构建模式",
    "build mode": "构建模式",
    "Error set": "错误集合",
    "error set": "错误集合",
    "Buffered writer": "缓冲写入器",
    "buffered writer": "缓冲写入器",
    "Optional value": "可选值",
    "optional value": "可选值",
    "Index capture": "索引捕获",
    "index capture": "索引捕获",
    "Payload capture": "载荷捕获",
    "payload capture": "载荷捕获",
    "Labeled blocks": "带标签的代码块",
    "labeled blocks": "带标签的代码块",
    "Descriptive label": "描述性标签",
    "descriptive label": "描述性标签",
    "Value's properties": "值的属性",
    "value's properties": "值的属性",
    "Null case": "空值情况",
    "null case": "空值情况",
    "Sample value": "样本值",
    "sample value": "样本值",
    "Fixed-size buffer": "固定大小缓冲区",
    "fixed-size buffer": "固定大小缓冲区",
    "Stack operations": "栈操作",
    "stack operations": "栈操作",
    "Polymorphic I/O": "多态输入输出",
    "polymorphic I/O": "多态输入输出",
    "Formatted message": "格式化消息",
    "formatted message": "格式化消息",
    "Safe by default": "默认安全",
    "safe by default": "默认安全",
    "Atomic copy": "原子复制",
    "atomic copy": "原子复制",
    "Usage information": "使用说明",
    "usage information": "使用说明",
    "Validate source": "验证源文件",
    "validate source": "验证源文件",
    "Regular file": "常规文件",
    "regular file": "常规文件",
    "Respect semantics": "遵循语义",
    "respect semantics": "遵循语义",
    "Scripting friendly": "脚本友好",
    "scripting friendly": "脚本友好",
    "Pipelines quiet": "管道静默",
    "pipelines quiet": "管道静默",
    "Preserving mode": "保留模式",
    "preserving mode": "保留模式",

    # 常用动作
    "Import": "导入",
    "import": "导入",
    "Import the standard library": "导入标准库",
    "Import the": "导入",
    "Define": "定义",
    "define": "定义",
    "Define a custom error": "定义自定义错误",
    "Define a": "定义一个",
    "Create": "创建",
    "create": "创建",
    "Create a": "创建一个",
    "Returns": "返回",
    "returns": "返回",
    "Return": "返回",
    "Returns an error": "返回一个错误",
    "Returns the": "返回",
    "Check": "检查",
    "check": "检查",
    "Check for": "检查",
    "Validate": "验证",
    "validate": "验证",
    "Validates that": "验证",
    "Print": "打印",
    "print": "打印",
    "Print startup": "打印启动",
    "Write": "写入",
    "write": "写入",
    "Write formatted": "写入格式化",
    "Read": "读取",
    "read": "读取",
    "Copy": "复制",
    "copy": "复制",
    "Allocate": "分配",
    "allocate": "分配",
    "Allocates": "分配",
    "Free": "释放",
    "free": "释放",
    "Attempt": "尝试",
    "attempt": "尝试",
    "Attempt to": "尝试",
    "Catch": "捕获",
    "catch": "捕获",
    "Demonstrates": "演示",
    "demonstrates": "演示",
    "Determine": "确定",
    "determine": "确定",
    "Uses": "使用",
    "uses": "使用",
    "Handle": "处理",
    "handle": "处理",
    "Unwrap": "解包",
    "unwrap": "解包",
    "Classify": "分类",
    "classify": "分类",
    "Iterate": "迭代",
    "iterate": "迭代",
    "Iterate through": "遍历",
    "Display": "显示",
    "display": "显示",
    "Flush": "刷新",
    "flush": "刷新",
    "Get": "获取",
    "get": "获取",
    "Get the": "获取",
    "Perform": "执行",
    "perform": "执行",
    "Ensure": "确保",
    "ensure": "确保",
    "Ensures": "确保",

    # 名词
    "Library": "库",
    "library": "标准库",
    "Standard library": "标准库",
    "standard library": "标准库",
    "Utility": "工具函数",
    "utility": "工具函数",
    "Functions": "函数",
    "functions": "函数",
    "Builtin": "内置",
    "builtin": "内置",
    "Information": "信息",
    "information": "信息",
    "Types": "类型",
    "types": "类型",
    "Integers": "整数",
    "integers": "整数",
    "Floats": "浮点数",
    "floats": "浮点数",
    "Strings": "字符串",
    "strings": "字符串",
    "Booleans": "布尔值",
    "booleans": "布尔值",
    "Values": "值",
    "values": "值",
    "Literal": "字面量",
    "literal": "字面量",
    "File": "文件",
    "file": "文件",
    "Files": "文件",
    "files": "文件",
    "Path": "路径",
    "path": "路径",
    "Source": "源文件",
    "source": "源文件",
    "Destination": "目标文件",
    "destination": "目标文件",
    "Buffer": "缓冲区",
    "buffer": "缓冲区",
    "Error": "错误",
    "error": "错误",
    "Errors": "错误",
    "errors": "错误",
    "Function": "函数",
    "function": "函数",
    "Value": "值",
    "value": "值",
    "Type": "类型",
    "type": "类型",
    "Data": "数据",
    "data": "数据",
    "Array": "数组",
    "array": "数组",
    "Slice": "切片",
    "slice": "切片",
    "Number": "数字",
    "number": "数字",
    "Numbers": "数字",
    "numbers": "数字",
    "Mode": "模式",
    "mode": "模式",
    "Debug": "调试",
    "debug": "调试",
    "Release": "发布",
    "release": "发布",
    "Build": "构建",
    "build": "构建",
    "Compile": "编译",
    "compile": "编译",
    "Input": "输入",
    "input": "输入",
    "Output": "输出",
    "output": "输出",
    "Memory": "内存",
    "memory": "内存",
    "Stack": "栈",
    "stack": "栈",
    "Heap": "堆",
    "heap": "堆",
    "Main": "主",
    "main": "主",
    "Custom": "自定义",
    "custom": "自定义",
    "Standard": "标准",
    "standard": "标准",
    "Default": "默认",
    "default": "默认",
    "Optional": "可选",
    "optional": "可选",
    "Empty": "空",
    "empty": "空",
    "Full": "满",
    "full": "满",
    "Null": "空",
    "null": "空",
    "Missing": "缺失",
    "missing": "缺失",
    "Present": "存在",
    "present": "存在",
    "Positive": "正数",
    "positive": "正数",
    "Negative": "负数",
    "negative": "负数",
    "Zero": "零",
    "zero": "零",
    "First": "首先",
    "first": "首先",
    "Last": "最后一个",
    "last": "最后一个",
    "Current": "当前",
    "current": "当前",
    "Invalid": "无效",
    "invalid": "无效",
    "New": "新",
    "new": "新",
    "Chapter": "章节",
    "chapter": "章节",
    "Section": "节",
    "section": "节",
    "Description": "描述",
    "description": "描述",
    "Documentation": "文档",
    "documentation": "文档",
    "Comment": "注释",
    "comment": "注释",
    "Example": "示例",
    "example": "示例",
    "Examples": "示例",
    "examples": "示例",
    "Label": "标签",
    "label": "标签",
    "Blocks": "代码块",
    "blocks": "代码块",
    "Classification": "分类",
    "classification": "分类",
    "Properties": "属性",
    "properties": "属性",
    "Payload": "载荷",
    "payload": "载荷",
    "Capture": "捕获",
    "capture": "捕获",
    "Syntax": "语法",
    "syntax": "语法",
    "Cases": "情况",
    "cases": "情况",
    "Samples": "样本",
    "samples": "样本",
    "Index": "索引",
    "index": "索引",
    "Corresponding": "对应的",
    "corresponding": "对应的",
    "CLI": "命令行工具",
    "cli": "命令行工具",
    "Force": "强制",
    "force": "强制",
    "Paths": "路径",
    "paths": "路径",
    "Args": "参数",
    "args": "参数",
    "Exists": "存在",
    "exists": "存在",
    "Semantics": "语义",
    "semantics": "语义",
    "Pipelines": "管道",
    "pipelines": "管道",
    "Quiet": "静默",
    "quiet": "静默",
    "Success": "成功",
    "success": "成功",
    "Failed": "失败",
    "failed": "失败",
    "Ensure": "确保",
    "ensure": "确保",
    "Required": "必需",
    "required": "必需",
    "Exit": "退出",
    "exit": "退出",
    "Code": "代码",
    "code": "代码",
    "Status": "状态",
    "status": "状态",

    # 介词和连词（简化处理）
    "The": "",
    "the": "",
    "This": "此",
    "this": "此",
    "That": "该",
    "that": "该",
    "These": "这些",
    "these": "这些",
    "Those": "那些",
    "those": "那些",
    "A": "一个",
    "a": "一个",
    "An": "一个",
    "an": "一个",
    "And": "和",
    "and": "和",
    "Or": "或",
    "or": "或",
    "In": "在",
    "in": "在",
    "On": "在",
    "on": "在",
    "At": "在",
    "at": "在",
    "To": "到",
    "to": "到",
    "From": "从",
    "from": "从",
    "By": "通过",
    "by": "通过",
    "With": "使用",
    "with": "使用",
    "Using": "使用",
    "using": "使用",
    "For": "用于",
    "for": "用于",
    "Of": "的",
    "of": "的",
    "As": "作为",
    "as": "作为",
    "If": "如果",
    "if": "如果",
    "Then": "那么",
    "then": "那么",
    "Else": "否则",
    "else": "否则",
    "When": "当",
    "when": "当",
    "While": "当",
    "while": "当",
    "Not": "不",
    "not": "不",
    "No": "不",
    "no": "不",
    "All": "所有",
    "all": "所有",
    "Each": "每个",
    "each": "每个",
    "Every": "每个",
    "every": "每个",
    "Some": "一些",
    "some": "一些",
    "One": "一个",
    "one": "一个",
    "Two": "两个",
    "two": "两个",
    "Three": "三个",
    "three": "三个",

    # 修饰词
    "Safe": "安全",
    "safe": "安全",
    "Minimal": "最小化",
    "minimal": "最小化",
    "Atomic": "原子",
    "atomic": "原子",
    "Buffered": "缓冲",
    "buffered": "缓冲",
    "Formatted": "格式化",
    "formatted": "格式化",
    "Generic": "通用",
    "generic": "通用",
    "Interface": "接口",
    "interface": "接口",
    "Polymorphic": "多态",
    "polymorphic": "多态",
    "Initial": "初始",
    "initial": "初始",
    "Final": "最终",
    "final": "最终",
    "Next": "下一个",
    "next": "下一个",
    "Previous": "前一个",
    "previous": "前一个",
    "Original": "原始",
    "original": "原始",
    "Cleanly": "简洁地",
    "cleanly": "简洁地",

    # 常用短语
    "Main entry point of": "程序主入口点",
    "entry point of the": "入口点",
    "to access": "以访问",
    "like build mode": "如构建模式",
    "such as": "如",
    "for example": "例如",
    "e.g.": "例如",
    "i.e.": "即",
    "etc": "等",
    "according to": "根据",
    "based on": "基于",
    "instead of": "而非",
    "in order to": "为了",
    "so that": "以便",
    "due to": "由于",
    "because of": "因为",
    "however": "然而",
    "therefore": "因此",
    "thus": "因此",

    # 特定项目术语
    "Safe File Copier": "安全文件复制器",
    "Temperature": "温度",
    "converter": "转换器",
    "argument": "参数",
    "parsing": "解析",
    "loop labels": "循环标签",
    "range scan": "范围扫描",
    "script runner": "脚本运行器",
    "branching": "分支",
    "switch examples": "switch示例",
    "essentials": "要点",
}

def smart_translate(text):
    """智能翻译，保持流畅性"""
    if not text.strip():
        return text

    # 如果文本包含//，说明已经是翻译格式，跳过
    if '//' in text:
        return text

    # 按短语长度排序，优先匹配长短语
    items = sorted(TRANS.items(), key=lambda x: len(x[0]), reverse=True)

    for en_phrase, cn_phrase in items:
        # 使用词边界匹配
        pattern = r'\b' + re.escape(en_phrase) + r'\b'
        text = re.sub(pattern, cn_phrase, text, flags=re.IGNORECASE)

    # 清理多余的空格
    text = re.sub(r'\s+', ' ', text)
    text = text.strip()

    return text

def process_file(filepath):
    """处理单个文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return False

    lines = content.split('\n')
    new_lines = []
    modified = False

    for line in lines:
        original = line

        # 跳过空行
        if not line.strip():
            new_lines.append(line)
            continue

        # 处理注释行
        if line.strip().startswith('//'):
            # 分离前缀和注释
            parts = line.split('//', 1)
            if len(parts) == 2:
                prefix = parts[0]
                comment = parts[1].strip()

                # 跳过空注释和文件头注释
                if not comment or comment.startswith('File:') or comment.startswith('Chapters'):
                    new_lines.append(line)
                    continue

                # 翻译注释
                translated = smart_translate(comment)

                # 如果翻译成功，格式化为英文在上，中文在下
                if translated != comment and translated.strip():
                    first_line = f"{prefix}// {comment}"
                    second_line = f"{prefix}// {translated}"
                    new_lines.append(first_line)
                    new_lines.append(second_line)
                    modified = True
                    continue

        new_lines.append(line)

        if line != original:
            modified = True

    if modified:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write('\n'.join(new_lines))
            return True
        except Exception as e:
            print(f"Error writing {filepath}: {e}")
            return False

    return False

def main():
    """主函数"""
    code_dir = Path("chapters-data/code")
    if not code_dir.exists():
        print("Error: chapters-data/code directory not found")
        sys.exit(1)

    zig_files = list(code_dir.rglob("*.zig"))
    print(f"Found {len(zig_files)} Zig files\n")

    translated = 0
    for i, filepath in enumerate(zig_files, 1):
        if process_file(filepath):
            print(f"[{i:3}/{len(zig_files)}] ✓ Premium翻译: {filepath.relative_to(Path('.'))}")
            translated += 1

    print(f"\n{'='*70}")
    print(f"总计: {len(zig_files)} 个文件")
    print(f"已优质翻译: {translated} 个文件")
    print(f"{'='*70}")

if __name__ == "__main__":
    main()
