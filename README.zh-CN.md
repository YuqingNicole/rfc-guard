# RFC Guard — Claude Code 插件

一个 Stop hook 插件，自动检测 RFC 级别的架构变更，并根据工程品味准则审查代码质量。

## 功能

每次 Claude 完成回复时，RFC Guard 执行两层检查：

1. **关键词检测**（shell 脚本）— 扫描 `git diff`，匹配涉及架构决策的关键词（数据源、API 契约、AI 编排、合规边界、持久化等）
2. **工程品味审查**（AI agent）— 使用轻量模型，根据项目中的 `ENGINEERING_TASTE.md` 评估代码改动是否符合工程原则

任一检查未通过时，Claude 的操作将被阻断，并输出具体原因。

## 安装

### 通过 settings.json

在你的 Claude Code 配置文件中（`~/.claude/settings.json` 或项目级 `.claude/settings.json`）添加：

```json
{
  "extraKnownMarketplaces": {
    "nicole-plugins": {
      "source": {
        "source": "github",
        "repo": "YuqingNicole/rfc-guard"
      }
    }
  },
  "enabledPlugins": {
    "rfc-guard@nicole-plugins": true
  }
}
```

## 配置

### 自定义关键词

在 Claude Code settings 的 `env` 中设置环境变量：

```json
{
  "env": {
    "RFC_GUARD_EXTRA_PATTERNS": "my-service|my-api|自定义模式"
  }
}
```

也可以指向一个关键词文件（每行一个正则）：

```json
{
  "env": {
    "RFC_GUARD_PATTERNS_FILE": "/path/to/patterns.txt"
  }
}
```

### 自定义 RFC 目录

```json
{
  "env": {
    "RFC_GUARD_RFC_DIR": "./docs/rfcs"
  }
}
```

### 工程品味文件

agent hook 会按以下顺序查找你的工程品味文档：
1. `rfcs/ENGINEERING_TASTE.md`
2. `docs/ENGINEERING_TASTE.md`
3. `ENGINEERING_TASTE.md`

如果未找到，将使用内置的通用工程原则进行审查。

## 默认检测关键词

| 分类 | 关键词模式 |
|------|-----------|
| 数据源 | `polymarket`, `gamma-api`, `clob-api`, `kalshi`, `DataSource` |
| AI 编排 | `agent orchestrat`, `layer2`, `multi-agent` |
| 持久化 | `CREATE/ALTER/DROP TABLE`, `schema.prisma` |
| 跨平台匹配 | `cross-platform`, `EventMatch` |
| 合规边界 | `compliance`, `trust boundary`, `auth boundary` |
| 公共 API | `api/v*`, `/api/public`, `openapi`, `swagger` |

## 阻断逻辑

| 场景 | 行为 |
|------|------|
| 无代码改动 | 静默通过 |
| 改动仅涉及配置、文档、测试 | 静默通过 |
| 匹配到 RFC 级别关键词 | 阻断，输出匹配内容 + 现有 RFC 列表 |
| 违反工程品味原则 | 阻断，指出具体违反了哪条原则 |

## 工程品味审查的 8 条原则

1. **薄且显式的分层** — 不允许跨层泄漏
2. **边界处标准化** — 第三方 API 怪癖必须隔离在 adapter 内
3. **不过早平台化** — 在产品验证前，优先用简单本地模块
4. **精准手术式改动** — 最小化 patch，让意图显而易见
5. **朴素代码优于巧妙抽象** — 单次使用的抽象是负债
6. **边界处大声失败** — 静默降级只适用于展示层，不适用于契约完整性
7. **确定性代码做确定性工作** — 不用 AI 做路由/解析/过滤/排序
8. **产品合规边界** — 不引入钱包、交易、投资建议等功能

## 适用场景

- 有 RFC 规范的中大型项目
- 需要在 AI 辅助编程时保持架构一致性
- 团队多人协作，需要自动化守护设计决策
- 有明确的合规边界需要强制执行

## License

MIT
