# 更新日志

## v3.0.0 - 数据导入导出与保护

### 新增功能

#### 1. CSV 导入导出
- 导出为 CSV 格式，可用 **Excel / WPS / 记事本** 打开编辑
- 导入 CSV 文件更新账本数据
- 支持 UTF-8 BOM 编码，Excel 直接正确显示中文
- 格式：类型,金额,分类,备注,日期

#### 2. JSON 完整备份
- 导出完整数据备份（JSON 格式）
- 导入备份恢复全部数据
- 保留所有原始字段信息

#### 3. 数据保护增强
- iOS 启用 **UIFileSharingEnabled**，支持 iTunes 文件共享
- 数据存储于 App 独立 Documents 目录，覆盖安装不丢失
- 支持 LSSupportsOpeningDocumentsInPlace，文件原位访问

### UI 变更
- 顶部菜单新增「数据管理」入口
- 数据管理页：数据统计、CSV 导入导出、JSON 备份恢复
- 数据保护说明卡片

### 技术实现
- share_plus 系统分享面板（支持 AirDrop/邮件/微信等）
- file_picker 文件选择器导入
- CSV 解析支持引号包裹字段
- iOS Info.plist 配置共享目录
