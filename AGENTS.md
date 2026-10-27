# AGENTS.md - Code-Template 微前端标准模板工程

> 💡 **上位准则**：工作区通用 SDD+TDD 研发流水线、编码风格、双模主题 Token 及自动交付规章，统一遵循 [`../AGENTS.md`](../AGENTS.md)（`code-common/rules/AGENTS.md`）。

---

## 1. 模块定位与专有约束

1. **活样板与派生器双重职责**：
   - 本仓库提供 `ModuleKey="template"`、`TablePrefix="tpl_"`、端口 `:8090`/`5180` 的黄金标准基准实现；
   - `scripts/init-module.sh` 负责一键派生新业务模块，并为新模块自动生成 SDD+TDD `docs/` 骨架（`00-prompt` ~ `06-ops`）、精简版 `AGENTS.md` 与 `README.md`。
2. **`docs/` 目录特殊说明**：
   - 本仓库自身的 `docs/`（`01-快速开始...` ~ `06-上线前自检...`）已通过软链接挂载至 `code-bench/docs/02-业务模块模板工程文档` 供门户在线展示，严禁删除；派生新项目时脚本会自动将其排除。
3. **可派生性同步红线**：
   - 修改 `config/config.go`、`frontend/src/constants.ts`、`frontend/vite.config.ts` 等元数据时，必须同步验证 `scripts/init-module.sh` 的替换规则匹配无误。
