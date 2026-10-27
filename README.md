# Code-Template（CodeBench 标准微前端模块脚手架）🧩

`code-template` 是面向 **CodeBench 综合工作台**的新业务子系统官方脚手架与活样板工程（Living Template）。  
开发者可基于本模板通过一行脚本快速派生出符合平台规范的独立全栈业务模块，并在**不改动 `code-bench` 一行代码**的前提下，仅通过 `gateways` 配置实现运行时即插即用挂载。

---

## ✨ 模板内置能力一览

* **一键派生脚手架 (`scripts/init-module.sh`)**：自动校验命名冲突，原子替换模块标识、端口、数据库表前缀、RBAC 角色与模块联邦配置，并为新项目自动生成 **SDD (规范驱动) + TDD (测试驱动)** 文档骨架（`docs/00-prompt` ~ `docs/06-ops`）、专属 `AGENTS.md` 与 `README.md`。
* **微前端与独立调试双模容器**：
  * **嵌入模式 (`isEmbedded=true`)**：自动融入 CodeBench 门户布局、共享登录态 JWT 与亮/暗主题，动态暴露 `./App` 与 `./menu`。
  * **独立模式 (`isEmbedded=false`)**：自带 `UnifiedLogin` 登录页、调试侧边栏与亮/暗主题切换器，支持无宿主独立开发调试。
* **黄金标准 CRUD 示范页**：完整落地 5 页滑动窗口 URL 同步分页（`Pagination` + `usePagination`）、`Drawer` 抽屉表单、`ConfirmDialog` 二次确认、`MemberSearchSelect` 成员检索、`StatusTag`、`EmptyState` 与 `Toast`。
* **企业级 Go 后端底座**：统一集成 `code-common/backend` 的 `server.Run` 自动前缀剥离、`AuthMiddleware` + `RequireAdmin` 鉴权、`commonAudit` 字段级 Diff 操作审计、共享库表前缀隔离与 `testdb.SetupIsolatedDB` 物理隔离单测。
* **100% 双模主题合规**：全量采用 `--color-*` Design Tokens 与 `.code-tpl-*` Flat BEM 样式规范，零硬编码色值、零静态内联样式。

---

## 🚀 3 分钟快速派生新模块

确保你的工作区目录与 `code-common` 同级并排放置：

```text
workspace/
├── code-common/          # 平台公共资产库（必需）
├── code-bench/           # 微前端组装台宿主（联调时使用）
└── code-monitor/         # 你从 code-template 克隆出的新模块
```

执行一键初始化脚本（以新建 `monitor` 模块为例）：

```bash
# 方式 A：直接在父级工作区目录一键派生（推荐，脚本会自动创建 code-monitor 目录）
code-template/scripts/init-module.sh \
  --key monitor \
  --title "集群监控诊断" \
  --port 8091 \
  --dev-port 5181 \
  --table-prefix mon_

# 方式 B：从 Git 克隆后在目标目录下就地初始化
git clone <code-template-repo-url> code-monitor
cd code-monitor
bash scripts/init-module.sh \
  --key monitor \
  --title "集群监控诊断" \
  --port 8091 \
  --dev-port 5181 \
  --table-prefix mon_

# 进入新模块目录，安装依赖、执行检查并编译验证
cd code-monitor
cp config.yaml.example config.yaml
make install && make lint && make test && make build
```

最后将脚本输出的 `gateways` 配置片段粘贴至 `code-bench/config.yaml` 并重启 `code-bench`，即可在工作台看到新模块！

---

## 📚 开发者指导文档中心 (`docs/`)

本仓库 `docs/` 目录提供从入门到上线的完整技术指南（同步挂载于 CodeBench 在线「开发者文档」菜单）：

* 📖 [**文档总览与导航地图**](file:///home/fugui/codes/code-template/docs/README.md)
* 🚀 [**01 - 快速开始与脚手架初始化**](file:///home/fugui/codes/code-template/docs/01-%E5%BF%AB%E9%80%9F%E5%BC%80%E5%A7%8B%E4%B8%8E%E8%84%9A%E6%89%8B%E6%9E%B6%E5%88%9D%E5%A7%8B%E5%8C%96.md)
* 🔌 [**02 - 微前端契约与双模运行机制**](file:///home/fugui/codes/code-template/docs/02-%E5%BE%AE%E5%89%8D%E7%AB%AF%E5%A5%91%E7%BA%A6%E4%B8%8E%E5%8F%8C%E6%A8%A1%E8%BF%90%E8%A1%8C%E6%9C%BA%E5%88%B6.md)
* ⚙️ [**03 - 后端开发与公共能力集成指南**](file:///home/fugui/codes/code-template/docs/03-%E5%90%8E%E7%AB%AF%E5%BC%80%E5%8F%91%E4%B8%8E%E5%85%AC%E5%85%B1%E8%83%BD%E5%8A%9B%E9%9B%86%E6%88%90%E6%8C%87%E5%8D%97.md)
* 🎨 [**04 - 前端组件复用与双模主题规范**](file:///home/fugui/codes/code-template/docs/04-%E5%89%8D%E7%AB%AF%E7%BB%84%E4%BB%B6%E5%A4%8D%E7%94%A8%E4%B8%8E%E5%8F%8C%E6%A8%A1%E4%B8%BB%E9%A2%98%E8%A7%84%E8%8C%83.md)
* 📦 [**05 - 联调构建与生产部署指南**](file:///home/fugui/codes/code-template/docs/05-%E8%81%94%E8%B0%83%E6%9E%84%E5%BB%BA%E4%B8%8E%E7%94%9F%E4%BA%A7%E9%83%A8%E7%BD%B2%E6%8C%87%E5%8D%97.md)
* 🛠️ [**06 - 上线前自检清单与常见问题排查**](file:///home/fugui/codes/code-template/docs/06-%E4%B8%8A%E7%BA%BF%E5%89%8D%E8%87%AA%E6%A3%80%E6%B8%85%E5%8D%95%E4%B8%8E%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98%E6%8E%92%E6%9F%A5.md)

---

## 🛠️ 常用 Makefile 命令

| 命令 | 说明 |
| :--- | :--- |
| `make install` | 安装前端 `npm` 依赖 |
| `make build` | 编译前端 `dist` 并内嵌构建 Go 单二进制可执行文件 |
| `make test` | 执行 `go fmt`、`go vet` 与后端全量单元测试 |
| `make lint` | 执行前端 TypeScript 类型检查与 ESLint 静态规范检查 |
| `make run` | 构建并直接启动本地单二进制服务（默认 `:8090`） |
| `make clean` | 清理构建产物 `frontend/dist` 与可执行二进制 |
