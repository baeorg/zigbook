# Project Context

## Purpose
The Zig Programming Language Book (Zigbook) 是一个全面的、基于项目的 Zig 编程语言指南。它旨在通过超过 60 个章节，从基础到高级系统编程，以循序渐进的方式教授 Zig 语言。项目交替介绍概念章节和项目章节，确保学习者能够通过实际项目巩固所学概念。

主要目标：
- 提供结构化的 Zig 语言学习路径
- 通过实际项目展示系统编程概念
- 建立从基础知识到高级应用的完整学习体系
- 保持内容的持续更新以反映最新的语言特性和最佳实践

## Tech Stack

### Frontend Technologies
- **Next.js 14.2+** - React 全栈框架，用于站点渲染
- **React 18.3+** - 用户界面库
- **TypeScript 5+** - 类型安全的 JavaScript
- **Tailwind CSS 3.4+** - 实用优先的 CSS 框架
- **DaisyUI 4.12+** - 基于 Tailwind 的组件库
- **PrismJS 1.29+** - 语法高亮库

### Content Management
- **AsciiDoc** - 主要文档格式，用于书籍内容
- **XML/DocBook** - 部分章节的结构化文档格式
- **xml2js** - XML 解析库

### Development Tools
- **Bun 1.3.2** - 包管理器和运行时
- **ESLint 8.57.1** - 代码质量检查
- **PostCSS 8+** - CSS 后处理器
- **Autoprefixer 10.4+** - CSS 前缀自动添加

## Project Conventions

### Code Style
- **TypeScript**: 严格模式，完整类型定义
- **React**: 函数组件，hooks 优先
- **命名约定**:
  - 文件名：kebab-case (`user-auth.ts`)
  - 组件名：PascalCase (`UserProfile`)
  - 变量/函数：camelCase (`getUserData`)
- **文件结构**: 按功能分组，保持单一职责原则

### Architecture Patterns
- **Next.js App Router** - 使用现代的 app 目录结构
- **组件化设计** - 可复用的 UI 组件
- **静态站点生成** - 优化性能和 SEO
- **响应式设计** - 支持多设备访问

### Content Structure
- **章节编号**: 双数字前缀 (`01__`, `02__`)
- **文件命名**:
  - AsciiDoc: `##__chapter-name.adoc`
  - XML: `##__chapter-name.xml`
- **双语支持**: 英文和中文版本 (`pages/` 和 `pages-zh/`)

### Testing Strategy
- **ESLint**: 代码质量和一致性检查
- **类型检查**: TypeScript 编译器严格模式
- **构建验证**: 确保站点可以正常构建和运行
- **内容验证**: 确保 AsciiDoc/XML 格式正确

### Git Workflow
- **主分支**: `main` - 生产环境代码
- **提交格式**:
  - `docs:` - 文档更新
  - `site:` - 站点功能
  - `book:` - 书籍结构
  - `fix:` - 错误修复
- **提交信息**: 简洁明了，包含变更原因

## Domain Context

### Educational Content Domain
- **编程教育**: 专注于系统编程和内存管理概念
- **Zig 生态系统**: 语言特性、标准库、构建系统
- **项目导向学习**: 每个项目都演示特定的编程概念

### Technical Writing Standards
- **人工编写**: 拒绝 AI 生成内容，保持人工审核
- **渐进式学习**: 章节之间相互依赖，按顺序学习
- **实用主义**: 重视实际应用而非纯理论

## Important Constraints

### Content Quality
- **无 AI 生成内容**: 所有书籍内容必须人工编写和审核
- **技术准确性**: 代码示例必须可以运行和验证
- **版本兼容性**: 与推荐 Zig 版本保持一致

### Performance
- **静态站点生成**: 优化加载速度
- **代码高亮**: 大量代码片段需要高效渲染
- **多语言支持**: 处理英文和中文内容

### Accessibility
- **Web 标准**: 遵循 WCAG 指南
- **响应式设计**: 支持各种屏幕尺寸
- **键盘导航**: 支持键盘快捷键

## External Dependencies

### Zig Ecosystem
- **Zig 编译器**: 根据 `.zigversion` 文件的推荐版本
- **Zig 标准库**: 文档和示例代码的主要来源

### Web Services
- **GitHub**: 源代码托管和协作
- **Vercel/Netlify**: 部署平台（推测）

### Build Tools
- **Node.js**: LTS 或更新版本
- **Bun**: 推荐的包管理器
- **Zig**: 用于示例代码验证
