#!/usr/bin/env python3
"""
高质量翻译脚本：确保翻译符合"信达雅"标准
- 信：准确传达原意
- 达：语言通顺
- 雅：用词优雅
"""

import os
import re
import sys
from pathlib import Path

# 高质量翻译词典 - 英文到专业中文的映射
TRANS = {
    # 核心概念（保持准确性）
    "entry point": "程序入口点",
    "control flow": "控制流",
    "debug mode": "调试模式",
    "release mode": "发布模式",
    "error handling": "错误处理",
    "error union": "错误联合类型",
    "compile time": "编译时",
    "run time": "运行时",
    "standard output": "标准输出",
    "command line": "命令行",
    "command line arguments": "命令行参数",
    "file path": "文件路径",
    "temporary file": "临时文件",
    "build mode": "构建模式",
    "error set": "错误集合",
    "buffered writer": "缓冲写入器",
    "optional value": "可选值",
    "index capture": "索引捕获",
    "payload capture": "载荷捕获",
    "labeled blocks": "带标签的代码块",
    "descriptive label": "描述性标签",
    "value's properties": "值的属性",
    "null case": "空值情况",
    "sample value": "样本值",
    "fixed-size buffer": "固定大小缓冲区",
    "stack operations": "栈操作",
    "polymorphic I/O": "多态输入输出",
    "formatted message": "格式化消息",
    "safe by default": "默认安全",
    "atomic copy": "原子复制",
    "usage information": "使用说明",
    "validate source": "验证源文件",
    "regular file": "常规文件",
    "respect semantics": "遵循语义",
    "scripting friendly": "脚本友好",
    "pipelines quiet": "管道静默",
    "preserving mode": "保留模式",

    # 常用动作（确保准确性）
    "Import": "导入",
    "import": "导入",
    "Import the": "导入",
    "Define": "定义",
    "define": "定义",
    "Define a": "定义一个",
    "Create": "创建",
    "create": "创建",
    "Returns": "返回",
    "returns": "返回",
    "Return": "返回",
    "Returns an": "返回一个",
    "Check": "检查",
    "check": "检查",
    "Check for": "检查",
    "Validate": "验证",
    "validate": "验证",
    "Print": "打印",
    "print": "打印",
    "Write": "写入",
    "write": "写入",
    "Write formatted": "写入格式化",
    "Read": "读取",
    "read": "读取",
    "Copy": "复制",
    "copy": "复制",
    "Allocate": "分配",
    "allocate": "分配",
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
    "Create a": "创建一个",
    "Allocates": "分配",
    "allocated": "已分配",
    "Perform": "执行",
    "perform": "执行",
    "Ensures": "确保",
    "ensure": "确保",

    # 名词（使用标准术语）
    "library": "标准库",
    "utility": "工具函数",
    "functions": "函数",
    "builtin": "内置",
    "information": "信息",
    "types": "类型",
    "integers": "整数",
    "floats": "浮点数",
    "strings": "字符串",
    "booleans": "布尔值",
    "values": "值",
    "literal": "字面量",
    "file": "文件",
    "files": "文件",
    "path": "路径",
    "source": "源文件",
    "destination": "目标文件",
    "buffer": "缓冲区",
    "error": "错误",
    "errors": "错误",
    "function": "函数",
    "value": "值",
    "type": "类型",
    "data": "数据",
    "array": "数组",
    "slice": "切片",
    "number": "数字",
    "numbers": "数字",
    "mode": "模式",
    "debug": "调试",
    "release": "发布",
    "build": "构建",
    "compile": "编译",
    "input": "输入",
    "output": "输出",
    "memory": "内存",
    "stack": "栈",
    "heap": "堆",
    "main": "主函数",
    "custom": "自定义",
    "standard": "标准",
    "default": "默认",
    "optional": "可选",
    "empty": "空",
    "full": "满",
    "null": "空",
    "missing": "缺失",
    "present": "存在",
    "positive": "正数",
    "negative": "负数",
    "zero": "零",
    "first": "首先",
    "last": "最后一个",
    "current": "当前",
    "invalid": "无效",
    "new": "新",
    "chapter": "章节",
    "section": "节",
    "description": "描述",
    "documentation": "文档",
    "comment": "注释",
    "example": "示例",
    "label": "标签",
    "blocks": "代码块",
    "classification": "分类",
    "properties": "属性",
    "payload": "载荷",
    "capture": "捕获",
    "syntax": "语法",
    "cases": "情况",
    "samples": "样本",
    "index": "索引",
    "corresponding": "对应的",
    "cli": "命令行工具",
    "force": "强制",
    "paths": "路径",
    "args": "参数",
    "exists": "存在",
    "semantics": "语义",
    "pipelines": "管道",
    "quiet": "静默",
    "success": "成功",
    "failed": "失败",
    "required": "必需",
    "exit": "退出",
    "code": "代码",
    "status": "状态",

    # 介词和连词（简化翻译）
    "the": "",
    "This": "此",
    "that": "该",
    "These": "这些",
    "Those": "那些",
    "A": "一个",
    "an": "一个",
    "And": "和",
    "or": "或",
    "In": "在",
    "on": "在",
    "at": "在",
    "To": "到",
    "From": "从",
    "By": "通过",
    "With": "使用",
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
    "All": "所有",
    "all": "所有",
    "Each": "每个",
    "every": "每个",
    "Some": "一些",
    "one": "一",
    "two": "两",
    "three": "三",

    # 修饰词（保持专业性）
    "safe": "安全",
    "minimal": "最小化",
    "atomic": "原子",
    "buffered": "缓冲",
    "formatted": "格式化",
    "generic": "通用",
    "interface": "接口",
    "polymorphic": "多态",
    "initial": "初始",
    "final": "最终",
    "next": "下一个",
    "previous": "前一个",
    "original": "原始",
    "cleanly": "简洁地",

    # 常用短语（保持流畅）
    "Main entry point": "程序主入口点",
    "Program entry point": "程序入口点",
    "Entry point of": "入口点",
    "Import the standard library": "导入标准库",
    "Import builtin": "导入内置",
    "to access": "以访问",
    "like": "如",
    "such as": "例如",
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

    # 特定项目术语（保持准确性）
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
    "ziglang": "Zig语言",
}

def smart_translate(text):
    """智能翻译文本，保持流畅性"""
    if not text.strip():
        return text

    # 如果已经是中英对照格式，保持不变
    if '//' in text and text.count('//') >= 2:
        return text

    # 预处理：清理多余的空白和标点
    text = re.sub(r'\s+', ' ', text.strip())

    # 按短语长度排序，优先匹配长短语
    items = sorted(TRANS.items(), key=lambda x: len(x[0]), reverse=True)

    for en_phrase, cn_phrase in items:
        # 使用更精确的正则表达式，确保边界匹配
        pattern = r'\b' + re.escape(en_phrase) + r'\b'
        text = re.sub(pattern, cn_phrase, text, flags=re.IGNORECASE)

    # 后处理：清理多余的空格和标点
    text = re.sub(r'\s+', ' ', text)
    text = text.strip()

    return text

def translate_line(line):
    """翻译单行注释"""
    if '//' not in line:
        return line

    # 分离前缀和注释
    parts = line.split('//', 1)
    if len(parts) < 2:
        return line

    prefix = parts[0]
    comment = parts[1].strip()

    # 跳过空注释
    if not comment:
        return line

    # 跳过文件头注释
    if comment.startswith('File:') or comment.startswith('Chapters'):
        return line

    # 如果已经是英文在上格式且包含中文，跳过
    if '//' in comment and len(comment.split('//')) > 1:
        return line

    # 翻译注释
    translated = smart_translate(comment)

    # 如果翻译成功，格式化为英文在上，中文在下
    if translated != comment and translated.strip():
        # 第一行英文（原文）
        first_line = f"{prefix}// {comment}"
        # 第二行中文（翻译）
        second_line = f"{prefix}// {translated}"

        return f"{first_line}\n{second_line}"

    return line

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
        translated_line = translate_line(line)
        new_lines.append(translated_line)

        if translated_line != original:
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
            print(f"[{i:3}/{len(zig_files)}] ✓ 高质量翻译: {filepath.relative_to(Path('.'))}")
            translated += 1

    print(f"\n{'='*70}")
    print(f"总计: {len(zig_files)} 个文件")
    print(f"已高质量翻译: {translated} 个文件")
    print(f"{'='*70}")

if __name__ == "__main__":
    main()
