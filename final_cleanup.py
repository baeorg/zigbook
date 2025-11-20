#!/usr/bin/env python3
"""
最终清理脚本：彻底移除所有重复和格式问题
"""

import os
import re
import sys
from pathlib import Path

def final_cleanup_file(filepath):
    """最终清理单个文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return False

    cleaned_lines = []
    modified = False

    i = 0
    while i < len(lines):
        line = lines[i]
        original = line

        # 跳过空行
        if not line.strip():
            cleaned_lines.append(line)
            i += 1
            continue

        # 处理重复的注释行（///格式）
        if line.strip().startswith('//') and line.strip().count('//') >= 2:
            # 检测包含多个//的单行注释
            if '///' in line or (line.count('//') >= 3):
                # 清理格式：/// 英文
                line = re.sub(r'//+\s*', '//', line)
                # 保留第一段作为英文原文
                if '//' in line:
                    parts = line.split('//', 2)
                    if len(parts) >= 2:
                        prefix = parts[0]
                        english = parts[1].strip()
                        cleaned_lines.append(f"{prefix}// {english}")
                        i += 1
                        modified = True
                        continue

        # 处理普通//注释的重复行
        if line.strip().startswith('//') and not line.strip().startswith('///'):
            # 查找下一个完全相同的行
            if i + 1 < len(lines):
                next_line = lines[i + 1].strip()
                current_line = line.strip()

                # 如果下一行是重复的//注释，跳过
                if next_line and next_line.startswith('//') and current_line == next_line:
                    i += 1
                    modified = True
                    continue

        # 处理包含多个//的单行注释，拆分为两行
        if line.strip().startswith('//') and line.count('//') >= 3:
            parts = line.split('//')
            if len(parts) >= 2:
                prefix = parts[0]
                content = parts[-1].strip()  # 最后一个//后的内容作为英文
                cleaned_lines.append(f"{prefix}// {content}")
                i += 1
                modified = True
                continue

        # 处理格式：// 英文  // 英文  // 中文
        if line.strip().startswith('//') and '//' in line:
            parts = line.split('//')
            if len(parts) >= 3:
                prefix = parts[0]
                english = parts[-1].strip()  # 取最后一个//后的内容作为英文
                cleaned_lines.append(f"{prefix}// {english}")
                i += 1
                modified = True
                continue

        # 处理行内重复注释 // Handle null case
        if '//' in line and not line.strip().startswith('//'):
            parts = line.split('//', 1)
            if len(parts) == 2:
                code_part = parts[0]
                comment = parts[1].strip()

                # 如果包含重复格式，清理
                if '//' in comment:
                    comment_parts = comment.split('//')
                    english = comment_parts[-1].strip()
                    cleaned_lines.append(f"{code_part}// {english}")
                    i += 1
                    modified = True
                    continue

        cleaned_lines.append(line)
        i += 1

        if line != original:
            modified = True

    if modified:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(cleaned_lines)
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

    cleaned = 0
    for i, filepath in enumerate(zig_files, 1):
        if final_cleanup_file(filepath):
            print(f"[{i:3}/{len(zig_files)}] ✓ Final cleaned: {filepath.relative_to(Path('.'))}")
            cleaned += 1

    print(f"\n{'='*70}")
    print(f"总计: {len(zig_files)} 个文件")
    print(f"已最终清理: {cleaned} 个文件")
    print(f"{'='*70}")

if __name__ == "__main__":
    main()
