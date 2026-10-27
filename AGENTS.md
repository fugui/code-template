# AGENTS.md - Code-Template 微前端标准模板工程开发与维护准则

本项目为 **Code-Template（CodeBench 综合工作台微前端业务子模块官方脚手架与活样板工程）**。
所有进入本项目的 AI 代理（Agents）与维护者必须严格遵循本准则及工作区上位宪法（`../AGENTS.md` / `code-common/rules/AGENTS.md`）。

---

## 1. 项目定位与双重职责

`code-template` 承担两项核心职责：
1. **平台级微前端活样板 (Living Template)**：提供 100% 符合团队规范的 Go + React 18 全栈基准实现（含双模运行容器、`@code/common` 组件复用、亮暗双模主题 Token、5 页滑动窗口 URL 分页、GORM 表前缀隔离、RBAC 角色鉴权、字段级 Diff 操作审计及 `testdb` 物理隔离单测）。
2. **SDD + TDD 工程派生器 (`scripts/init-module.sh`)**：支持一键派生出全新的业务子系统（如 `code-traefik`、`code-monitor`），并在新工程中自动生成完整的 **SDD (规范驱动开发) + TDD (测试驱动开发)** 文档知识库骨架（`docs/00-prompt` ~ `docs/06-ops`）、子项目专属 `AGENTS.md` 与 `README.md`。

> **重要约束**：本仓库根目录下的 `docs/` 目录（`01-快速开始与脚手架初始化.md` ~ `06-上线前自检清单与常见问题排查.md`）已通过软链接挂载至 `code-bench/docs/02-业务模块模板工程文档`，专供宿主门户「开发者文档」在线渲染。派生新业务项目时，`scripts/init-module.sh` 不会将这些脚手架教程拷入新项目，而是为新项目生成独立的 SDD + TDD `docs/` 体系。

---

## 2. 目录结构与边界

```text
code-template/
├── main.go                     # 后端入口：go:embed 静态资源、路由集中注册与 server.Run 启动
├── config/                     # 配置加载与模块级元数据常量 (ModuleKey, TablePrefix, AdminRole)
├── models/                     # GORM v2 数据模型（强制 tpl_ 表前缀隔离）与种子数据初始化
├── handlers/                   # HTTP 控制器（Health, Auth, Item CRUD + Audit Diff, Settings）与物理隔离单测
├── frontend/                   # React 18 + Vite 5 + Module Federation 前端工程
│   ├── src/App.tsx             # 嵌入模式 (EmbeddedRoutes) 与独立调试模式 (StandaloneShell) 双模根容器
│   ├── src/menu.ts             # 暴露给 CodeBench 宿主的动态侧边栏菜单契约 (./menu)
│   └── src/pages/              # 看板页、黄金标准列表页 (URL 同步分页 + Drawer + Confirm) 与配置页
├── scripts/
│   └── init-module.sh          # 一键派生新业务模块与生成 SDD+TDD 文档骨架的核心脚本
├── docs/                       # 挂载至 CodeBench 门户的平台脚手架使用指南
├── AGENTS.md                   # AI 代理维护准则
└── README.md                   # 模板工程总览
```

---

## 3. 核心红线与质量门禁

1. **零硬编码与双模主题合规**：`frontend/src` 下严禁出现 `#fff`、`#000`、`rgba(...)` 等硬编码色值，严禁滥用静态内联 `style={{ ... }}`，严禁出现 `any` 类型。
2. **模板可派生性保障**：任何对 `config/config.go`、`frontend/src/constants.ts`、`frontend/vite.config.ts` 等核心元数据的修改，必须同步验证 `scripts/init-module.sh` 的替换规则依然精确匹配。
3. **测试与静态检查必过**：每次修改后必须执行 `make test && make lint && make build && make clean`，确保全链路零警告通过，并在单次回复前清理所有构建产物与后台进程，自动提交并 push 至 `origin/main`。
