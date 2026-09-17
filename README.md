<div align="center">

# Control

**一款全离线、无广告的个人自律管理 App**

计划 · 饮食 · 锻炼 · 记账 · 数据报告

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://www.android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 这是什么

Control 是一个**完全免费、开源、全离线**的自律管理 App。它把日常自我管理最常用的几件事收在一个应用里：
打卡计划、记录饮食、跟踪训练、记账与借贷、看数据报告。

没有账号注册，没有广告，没有联网请求——**所有数据只存在你自己的手机里**。

> 由个人独立开发维护（品牌：解夏制作）。欢迎提 Issue 反馈问题或功能建议。

## 功能

| 模块 | 说明 |
|---|---|
| 📋 **计划** | 每日/重复/一次性三类任务，优先级排序、月历与周历视图、连续打卡统计、番茄钟计时、实时洞察提示 |
| 🍚 **饮食** | 600+ 种常见食物营养库（每 100g 热量/蛋白/脂肪/碳水），支持自定义食物并**拍照识别**；按餐次记录、点击记录直接改食量自动换算；基于 Mifflin-St Jeor 公式计算基础代谢与热量缺口 |
| 🏋️ **锻炼** | 动作库（按部位/器械检索）、训练模板、组次重量记录、休息日标记、训练频率统计 |
| 💰 **记账** | 收入/支出记录与分类统计、月度预算与超支提醒、借贷（花呗/白条/信用卡）待还总额管理、愿望清单 |
| 📊 **我的** | 周/月数据报告、年度打卡热力图、成就徽章、体重趋势、JSON 备份与恢复、多款主题皮肤 |

**特色**

- 全离线运行：无网络权限依赖，无第三方埋点
- 零广告、无内购、无注册登录
- 数据可导出 JSON 备份，随时恢复或迁移
- 自定义 UI 与动效：多套皮肤、粒子反馈、流畅转场
- 安装包约 57MB（release，含全部 ABI）

## 下载安装

前往 [Releases](../../releases) 页面下载最新 `app-release.apk`，在 Android 手机上安装即可。

- 系统要求：**Android 8.0 (API 26) 及以上**
- 首次安装需在系统设置中允许「安装未知来源应用」
- 覆盖安装不会丢失数据（数据库带自动迁移）

> 本 App 未上架任何应用商店，请仅从本仓库 Releases 或作者本人处获取安装包。

## 自行构建

环境要求：Flutter 3.44+、JDK 17+、Android SDK。

```bash
git clone https://github.com/jiexia-QAQ/Control.git
cd Control

flutter pub get
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

调试运行：

```bash
flutter run
```

## 技术栈

- **Flutter 3.44 / Dart 3.12**，Android 原生壳
- **sqflite**（SQLite）本地存储，数据库版本化迁移
- **provider** 状态管理
- 图表全部为 **CustomPainter 自绘**（环形进度、饼图、折线图、热力图），不引入图表库
- lpinyin（食物/动作拼音搜索）、file_picker、share_plus、image_picker、flutter_local_notifications

## 项目结构

```
lib/
├── core/          # 主题、工具、触觉反馈
├── data/          # 内置食物库 / 动作库 / 模板种子数据
├── models/        # 数据模型（计划、饮食、锻炼、记账、体重…）
├── pages/         # 页面（plan / diet / workout / accounting / report / profile）
├── services/      # 数据库服务、通知、洞察、备份
├── state/         # 全局状态
└── widgets/       # 共享组件（卡片、图表、粒子动画…）
```

## 数据与隐私

- 所有记录保存在应用私有目录的 SQLite 数据库中，**不上传任何服务器**
- 应用不含广告 SDK、统计 SDK，无网络请求
- 卸载 App 会同时删除本地数据，建议先使用「设置 → 数据管理 → 导出备份」
- 自定义食物照片保存在应用私有目录，不随系统相册同步

## 版本历史

| 版本 | 主要内容 |
|---|---|
| 1.8 | 自定义食物拍照、分餐营养查看、计划排序与录入体验优化 |
| 1.7 | 一次性任务、数据报告、成就徽章、月度预算、阶段目标、番茄钟 |
| 1.6 | 记账模块（记账/借贷/仪表盘）、四款皮肤、粒子动画 |
| 1.5 | 实时洞察、饮食与锻炼联动统计 |
| 1.4 | 动画体系与视觉升级（iOS 式转场、粒子、图表自绘） |
| 1.2 ~ 1.3 | 图标与配色重构、彩蛋与空态优化、模块基础能力 |

## 反馈与定制

- 功能建议或 Bug：欢迎提交 [Issue](../../issues)
- 有定制需求（改功能、改界面、做同类工具）：同样可通过 Issue 或仓库主页联系方式沟通

## 许可证

本项目基于 [MIT License](LICENSE) 开源，可自由使用、修改与分发（请保留版权声明）。

```
Copyright (c) 2026 解夏制作
```

---

<div align="center">

**如果这个项目对你有帮助，欢迎点一个 ⭐ Star**

</div>
