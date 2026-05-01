# AI 协作规则

## 项目进入
每次开始工作时，先读取 `README.md`、`context.md`、`progress.md`、`decisions.md`，理解项目当前状态后再行动。

## 工作模式
默认先判断本轮属于哪种模式：
- 讨论模式：先梳理思路，不急着改文件
- 执行模式：直接修改文件、生成产物、跑验证
- 整理模式：把散乱内容整理进文档
- 复盘模式：总结进展、更新记录、提炼下一步

## 文件分工
- `README.md`：项目入口、当前状态、下一步
- `context.md`：项目背景、业务信息、约束
- `progress.md`：按日期记录推进
- `decisions.md`：关键决策和原因
- `resources.md`：云端链接、外部资料、素材索引
- `docs/`：稳定文档
- `work/`：推进中的草稿和实验
- `artifacts/`：过程资产
- `deliverables/`：阶段性交付物
- `archive/`：旧版本和废弃方案

## 全局与项目分层
- 方法全局化，材料项目化
- 跨项目复用的通用 skill 放在 `/Users/dewens/.codex/skills/`
- 通用脚本放在 `/Users/dewens/Projects/scripts/`
- 跨项目 GitHub 工具源码放在 `/Users/dewens/Projects/_tools/`
- 当前项目背景、客户信息、设定、PRD、真实数据和临时实验材料只放在当前项目文件夹内

## 收尾规则
每次完成执行后：
1. 更新 `progress.md`
2. 必要时更新 `README.md` 的当前状态和下一步
3. 如果产生关键取舍，更新 `decisions.md`
4. 如果新增外部资源，更新 `resources.md`
5. 明确说明本次改了什么、还剩什么

## Git 规则
- 重要变化完成后，建议提交一版 Git
- 不要把密钥、账号密码、真实敏感数据写入 Git
- 大型媒体、原始数据、批量生成素材优先放云端或 `artifacts/raw/`，必要时用索引记录

## 边界
不要删除已有重要内容，除非 Dewens 明确要求。
不要把简单任务过度复杂化。
