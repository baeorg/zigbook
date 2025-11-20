## ADDED Requirements

### Requirement: 多语言内容同步
系统 SHALL 确保中英文版本的内容在结构和元数据上保持一致。

#### Scenario: 元数据本地化验证
- **WHEN** 检查中文版本的章节文件时
- **THEN** 所有元数据字段（keywords、changes等）必须使用中文
- **AND** 元数据内容必须与章节主题相关

#### Scenario: 文件完整性检查
- **WHEN** 运行内容同步检查时
- **THEN** 英文版本的每个章节都必须有对应的中文版本
- **AND** 文件命名格式必须保持一致

#### Scenario: 内容结构一致性
- **WHEN** 比较中英文章节时
- **THEN** 章节结构、代码示例、格式必须保持一致
- **AND** 只有语言内容不同，其他所有元素应该相同

### Requirement: 翻译工作流程规范
项目 SHALL 建立规范的翻译工作流程以确保内容同步。

#### Scenario: 翻译更新触发
- **WHEN** 英文版本章节内容更新时
- **THEN** 必须触发对应的中文版本更新流程
- **AND** 更新必须包括内容翻译和元数据本地化

#### Scenario: 质量检查自动化
- **WHEN** 内容提交到仓库时
- **THEN** 自动化检查必须验证中英文内容一致性
- **AND** 不一致的内容应该阻止合并

## MODIFIED Requirements

### Requirement: 章节元数据管理
所有章节文件的元数据 SHALL 与其语言版本保持一致。

#### Scenario: 元数据字段验证
- **WHEN** 验证章节文件时
- **THEN** keywords 必须使用章节对应的语言
- **AND** changes 字段必须描述该语言版本的修改历史
- **AND** 所有日期字段必须与英文版本保持同步