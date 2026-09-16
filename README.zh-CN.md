<div align="center">

<h1>PRISM</h1>

<p><b>Priority-Rank Integrated Search Mechanism / 优先秩集成搜索机制</b></p>

<p><i>以种群秩为统一分配信号,贯通两个搜索阶段</i></p>

<p><img src="assets/badge-paradigm.svg" alt="秩条件化">&nbsp;<img src="assets/badge-benchmarks.svg" alt="CEC 基准测试">&nbsp;<img src="assets/badge-matlab.svg" alt="MATLAB">&nbsp;<img src="assets/badge-status.svg" alt="投稿评审中">&nbsp;<img src="assets/badge-license.svg" alt="MIT 许可"></p>

</div>


> **稿件状态说明。** 本仓库是配套论文的参考实现与文档。该论文目前**正在某同行评议期刊的审稿阶段**,评审期间不公开期刊名称。此处的代码、插图与文档对应投稿版本,评审结束后可能更新。


| | |
|:--|:--|
| **论文题目** | PRISM: A Priority-Rank Integrated Search Mechanism for Single-Objective Black-Box Optimization |
| **作者** | **Qingke Zhang**\* |
| **单位** | 山东师范大学 计算机与人工智能学院,济南 250358 |
| **通讯作者** | 张庆科 教授 — [tsingke@sdnu.edu.cn](mailto:tsingke@sdnu.edu.cn) |
| **状态** | 投稿评审中(暂不公开期刊名称) |


**主要亮点**

- 提出 PRISM——面向单目标黑箱优化的秩驱动搜索机制。
- 引入秩优先引导(RPG),依据秩与搜索进度自适应接收多源信息。
- 设计分层反射精炼(SRR),对不同层级实施差异化开发与多样性恢复。
- 在 144 个 CEC2017/CEC2022 函数–维度算例上取得最低总体 Friedman 秩。
- 在带约束的无人机路径规划与多级阈值图像分割上验证了有效迁移能力。


## 目录

1. [背景与动机](#1-背景与动机)
2. [方法概述](#2-方法概述)
3. [主要贡献](#3-主要贡献)
4. [框架与机制](#4-框架与机制)
5. [基准评测](#5-基准评测)
6. [应用案例](#6-应用案例)
7. [参考实现](#7-参考实现)
8. [资助与致谢](#8-资助与致谢)


## 1. 背景与动机

当导数不可用或计算代价过高时,基于种群的黑箱优化往往是首选工具。差分进化、粒子群优化以及其后涌现的大量种群类方法,已被广泛应用于工程设计、图像处理、调度与自主规划。这些方法共享同一项稀缺资源:固定的评估预算必须在"广泛探索搜索空间"与"精细打磨已有前景区域"之间分配。

大量工作借助"排序"来解决这一分配问题。这一思路颇具吸引力,因为秩是尺度无关的——在任何保序的目标函数变换下它都保持不变,因而在良态问题与病态问题上含义一致。但在多数秩感知设计中,排序只被用于**单个**决策:选择哪些父代、选择压力偏置多强,或如何把种群划分为若干组与角色。秩在每个循环里只被读取一次,随后即被丢弃。

由此留下一个更具体的问题。处于不同搜索状态的个体,理应对方向性信息有不同的需求;而一次更新所产生的种群,理应与更新前的种群需要不同的精炼行为。若这两个决策彼此独立处理,那么"一个解接收多少信息"与"它随后扮演什么角色"之间就只存在弱耦合——尽管二者天然由同一个量所标定。

PRISM 的立场是:秩不必只花一次。它把归一化秩当作统一且尺度无关的分配信号,在**同一个搜索循环中被读取两次**,并让第二次读取依赖于第一次所产生的新种群。


## 2. 方法概述

PRISM 的每次迭代顺序执行两个阶段,并赋予二者各自明确的职责。

**秩优先引导(RPG)** 决定每个个体有权接收多少方向性信息。接收深度是归一化秩与预算消耗程度的函数,而信息本身由四个人群关系场中均匀抽取的子集加权融合而成。秩较优的解接收更少,秩较差的解接收更多;整套调度随预算消耗而逐步收紧。

**分层反射精炼(SRR)** 随后对 RPG 刚产生的种群重新排序,并为由此形成的三个层级——精英层、中间层、劣势层——分别指派**不同**的精炼行为。因此,一个解所获得的精炼方式取决于它在更新**之后**所处的位置,而非更新之前。

成功历史自适应、ε-接受与自适应种群缩减作为支撑性调控并行运行:它们调节参数、以极小概率接受非改进试验解,并随预算消耗收缩种群规模,但不构成"秩条件化分配"这一核心原理本身。由于第二阶段消费的是第一阶段产生的排序,精炼成为引导的自然延续,而非争夺同一批评估次数的竞争者。


## 3. 主要贡献

**秩条件化的是两个前后相继的决策,而非一个。** 既有秩感知设计把排序用于选择压力或种群拓扑。PRISM 在同一循环中读取排序两次:更新前由 RPG 将其转换为信息接收深度,更新后由 SRR 将**新的**排序转换为精炼行为。两个决策通过种群本身耦合在一起——而种群恰恰是上一阶段真正改变的对象。

**RPG 由秩与进度共同分配接收深度。** 每个个体按幅度加权融合四个人群关系场中的均匀抽取子集——全局质量对比、探索性变异、高质量位移、劣者向优者的校正。个体可动用的场数量由 `K_i = ⌈1 + 3(1 − τ)ρ_i⌉` 决定:当前最优只接收一个场,其余个体接收二至四个,且秩越差者分配到的深度不低于秩较优者。深度随运行推进阶梯式下降;由于该规则仅建立在 `ρ` 与 `τ` 之上,它完全尺度无关。

**SRR 把更新后的排序转换为三种不同的任务。** 重新排序后,顶层进行局部精炼,中间层向导师池学习,底层则用于多样性恢复——其职责是防止搜索塌缩,而非打磨任何解。该设计的前提是"恰当的行为由更新后的位次决定",而消融实验支持这一点:移除 SRR 造成的性能退化在所有被考察组件中最为严重。

**评测覆盖了多个比较维度。** PRISM 在 144 个 CEC2017/CEC2022 函数–维度算例上与 25 种算法对比,随后通过受控变体、加权信息源归因分析与单因子参数敏感性分析加以考察。两个应用——带约束的三维无人机路径规划与 20 阈值 Kapur 图像分割——用于检验同一机制能否在数值基准从不涉及的表示形式与可行性条件下依然成立。


## 4. 框架与机制

整体控制流程如下图所示。RPG 首先运行并产生试验种群;SRR 对该种群重新排序并逐层精炼;随后支撑性调控闭合本轮循环,再由预算检查把控制权送回顶部。

<p align="center">
  <img src="figures/fig1_framework.png" alt="PRISM 总体框架" width="100%">
</p>

<p align="center">
  <em><b>图 1.</b> PRISM 框架。RPG 与 SRR 构成两阶段秩引导搜索,成功历史自适应、ε-接受、自适应种群缩减与最优解更新提供支撑性调控。</em>
</p>

两个阶段分述如下。

**秩优先引导。** 记归一化秩 `ρ_i = (r_i − 1)/(N − 1)`、搜索进度 `τ = FEs/MaxFEs`,RPG 由当前最优 `x_best`、随机抽取的精英参照、随机抽取的劣势参照以及两个互异随机解构造四个关系场:

| 场 | 定义 | 作用 |
|:--|:--|:--|
| Φ₁ | `x_best − x_poor` | 全局质量对比 |
| Φ₂ | `x_r1 − x_r2` | 探索性变异 |
| Φ₃ | `x_best − x_elite` | 高质量位移 |
| Φ₄ | `x_elite − x_poor` | 劣者向优者的校正 |

四者并非线性无关——Φ₁ = Φ₃ + Φ₄——但由于 RPG 仅从四人中**无放回**均匀抽取规模为 `K_i` 的子集 `S_i`,并只用幅度归一化权重重新加权所抽中的场,它们在操作层面仍然彼此区分。所得步长经二项交叉掩码施加(强制激活一个坐标),试验解在评估前裁剪回边界盒内。由于 `K_i` 仅依赖 `ρ` 与 `τ`,整套分配规则对目标函数的任何保序缩放均保持不变。

**分层反射精炼。** SRR 对 RPG 之后的种群重新排序,并划分为精英层(前 `pN`)、中间层(至多 `⌊N/2⌋`)与劣势层(其余)。当精英层已收缩至某半径阈值之内时,精英层朝当前最优解做局部移动;否则精英层向由领先解构成的导师池学习。中间层同样向导师池学习,其坐标激活概率随秩上升。劣势层则被拉向导师池中心并叠加随机扰动项——这是多样性恢复动作,而非精炼动作。一个随秩变化的小重置概率会直接重新初始化个别坐标,避免底层整体退化。

**支撑性自适应与调控。** 成功历史自适应为缩放因子与交叉率各维护 `H = 5` 个记忆条目,在累积足够多的严格改进后按改进量加权 Lehmer 均值更新。两个阶段均采用贪婪选择,但非受保护个体可以概率 `ε_acc = 0.001` 接受非改进试验解;每轮扫描开始时被判定为最优的个体免于此规则。种群规模随预算消耗由 `N₀` 线性收缩至 `N_min = min{N₀, max(4, round(rD))}`,并按适应度优先删除秩最差的个体。

**计算复杂度。** 每个循环至多执行三次排序与两次种群扫描。排序代价为 `O(N log N)`,场构造、融合与坐标更新代价为 `O(ND)`,因此不计目标函数评估的算术代价为 `O(N log N + ND)`。存储为种群的 `O(ND)` 加上成功历史记忆的 `O(H)`,目标函数评估次数以 `MaxFEs` 为界。在典型黑箱场景中目标评估主导运行时间,而种群缩减会随运行推进持续降低每轮的额外开销。


## 5. 基准评测

PRISM 在 CEC2017(30 个函数,10D/30D/50D/100D)与 CEC2022(12 个函数,10D/20D)上评测,共 144 个函数–维度算例。全部 26 种算法使用相同的边界、目标接口、维度、初始化计数与 `10000D` 次函数评估预算,并统一固定 `N₀ = 40`,以便在共同初始种群下隔离搜索规则本身的差异。每种方法独立运行 20 次,比较结果由双侧 Wilcoxon 秩和检验与覆盖全部算例的 Friedman 秩共同支撑。

### 总体排名

| 设置 | PRISM 的 Friedman 秩 | PRISM 名次 |
|:--|:--:|:--:|
| CEC2017 @ 10D | 3.80 | 第 1 |
| CEC2017 @ 30D | 2.67 | 第 1 |
| CEC2017 @ 50D | 2.27 | 第 1 |
| CEC2017 @ 100D | 3.43 | 第 1 |
| CEC2022 @ 10D | 4.13 | 第 1 |
| CEC2022 @ 20D | 3.88 | 第 1 |
| **全部 144 个算例** | **3.20** | **26 种算法中第 1** |

PRISM 取得 26 种算法中最低的总体 Friedman 秩(3.20),并在六个设置中**全部排名第一**。全局检验确认 26 种算法并不等价(χ²_F = 2206.05,df = 25;Iman–Davenport F_F = 226.31,p < 0.001)。在全部算例上最接近的竞争者为 GSK(5.52)、L-SRTDE(5.88)、APO(6.74)、SHADE(7.43)与 jSO(7.52)。

<p align="center">
  <img src="figures/fig3a_benchmark_30d.png" alt="30D 下的最终误差分布与收敛曲线" width="96%">
  <br>
  <em><b>图 2.</b> 30D 下 PRISM 与七种主要竞争算法在 CEC2017 F5、F10、F18、F26 上的最终误差分布(上)与平均最优收敛曲线(下),20 次独立运行。</em>
</p>

<p align="center">
  <img src="figures/fig3b_benchmark_100d.png" alt="100D 下的最终误差分布与收敛曲线" width="96%">
  <br>
  <em><b>图 3.</b> 100D 下的同类对比。优势并不局限于低维一端。</em>
</p>

### 机制与鲁棒性分析

五个受控变体在完全相同的设置下运行。移除 SRR 造成的退化最为显著;禁用种群缩减带来中等程度的损失;而两个 RPG 深度控制变体——固定 `K_i = 2` 与打乱秩–个体对应关系——主要表现出总体层面的影响。

| 变体 | 平均 Friedman 秩 | W/T/L(共 120) |
|:--|:--:|:--:|
| **PRISM(完整版)** | **3.04** | — |
| 移除 SRR | 4.83 | 79 / 34 / 7 |
| 移除 APR | 3.52 | 29 / 83 / 8 |
| 移除 SHA | 3.25 | 16 / 88 / 16 |
| 固定 `K_i = 2` | 3.16 | 8 / 111 / 1 |
| 打乱 `ρ` | 3.21 | 5 / 113 / 2 |

这一结果厘清了各设计要素的角色。SRR 是承重组件:缺少更新后的分层精炼,仅靠反复的 RPG 搜索明显更弱。种群缩减是真正意义上的资源分配调节器。成功历史自适应只起支撑作用——移除它的影响更小且依赖维度,该变体甚至在 100D 上排名更好。两个 RPG 深度变体带来温和的总体增益,而逐函数的差异大多在统计上不可判别,这与"深度规则塑造的是分配方式、而非决定单个函数的结果"相一致。

<p align="center">
  <img src="figures/fig2_guidance_contribution.png" alt="四个 RPG 场的加权参与率" width="96%">
  <br>
  <em><b>图 4.</b> 四个 RPG 场在 CEC2017 严格改进中的加权参与率:30D 与 100D 的总体比率(左),以及早期、中期、晚期比率(右)。多场增益按融合权重归因;这些比率是描述性的,而非对单个场独立效应的因果估计。</em>
</p>

<p align="center">
  <img src="figures/fig4_sensitivity.png" alt="单因子参数敏感性" width="96%">
  <br>
  <em><b>图 5.</b> 三个主要参数的单因子敏感性,每个取值报告为 CEC2017 在 10D、30D、50D、100D 上的平均 Friedman 秩。红色标记为默认值 `p = 0.20`、`q = 7`、`r = 0.25`。</em>
</p>

敏感性研究表明默认值位于相对平坦的工作区间内。三者中导师池规模 `q` 最不敏感(`q = 5`–`9`),最小种群系数 `r` 在 `0.15`–`0.30` 间保持稳定;精英比例 `p` 的响应最剧烈,这符合预期——它决定了 SRR 把种群中多大比例视为精英层。


## 6. 应用案例

基准测试衡量的是固定协议下的解质量,而非优化器能否在表示形式与约束由他人设定的真实问题上立足。因此 PRISM 在**不做任何改动**的前提下被嵌入两个决策结构差异显著的应用。

**带约束的三维无人机路径规划。** 五个自由航路点(`M = 5`,`D = 15`)在包含圆柱障碍、软威胁区与禁飞区的工作空间内连接起点与终点。被评估的轨迹是依次经过起点、航路点与终点的六段折线——评估与可视化阶段均不做 B 样条平滑,因此优化器被按其**实际产生**的路径打分。罚函数目标综合了归一化路径长度、软邻近/威胁项、基于转角的最大机动性项以及硬约束罚项。此处 PRISM 直接在受约束的连续向量上搜索,可行性沿每一段连续校验。

**基于 Kapur 熵的多级阈值图像分割。** 每个候选解是一个递增的灰度阈值向量,经统一的确定性映射修复为可行解,并以图像直方图上的 Kapur 熵打分。难度随阈值数量增加,目标面也随阈值数上升而愈发崎岖。此处优化器搜索的是连续空间,而候选解被映射到离散决策结构上。

### 无人机路径规划结果

在统一的 6000 次函数评估预算下独立运行 20 次,PRISM 在三个较难场景(S2–S4)上取得最低平均最终代价,并获得最佳总体场景秩(**1.25**)。优势随几何难度上升而扩大:相对于最佳竞争均值,PRISM 在 S2、S3、S4 上把平均代价分别降低约 **1.0%**、**2.9%** 与 **2.4%**。在最简单场景(S1)上 GSK 略低——0.3596 对 0.3599——因此该增益并非一致占优,而是随场景复杂度增长的总体优势。

约束统计支持同样的判断。PRISM 在**全部 80 次运行中达到 100% 几何可行性**,并取得 **98.8% 的综合合规率(80 次运行中有 79 次同时满足几何与机动性要求)**。综合合规率上最接近的竞争者达到 97.5%,其余竞争者介于 8.8% 与 93.8% 之间。

<p align="center">
  <img src="figures/fig5_uav_path.png" alt="代表性合规无人机路径" width="96%">
  <br>
  <em><b>图 6.</b> 禁飞区场景下的代表性综合合规路径。灰色圆柱与圆形表示障碍,红色虚线圈表示软威胁区,红色矩形表示禁飞区,绿色方块与橙色菱形分别标记起点与终点。</em>
</p>

<p align="center">
  <img src="figures/fig6_uav_convergence.png" alt="无人机平均最优收敛曲线" width="88%">
  <br>
  <em><b>图 7.</b> 统一 6000 次函数评估预算下,PRISM 与四个最佳竞争算法在 20 次独立运行中的无人机平均最优收敛曲线。主图为对数纵轴,插图为 3000 至 6000 次评估的后期区间在线性坐标下的放大。数值越小越好。</em>
</p>

### 多级阈值分割结果

在 12 幅图像、20 阈值、每次 20 次独立运行(4000 次函数评估)的设置下,PRISM 取得最佳总体 Kapur 秩(**1.67**)与最高的总体平均 Kapur 熵(**49.7604**),最接近的竞争者分别为 1.83 与 49.7418。PRISM 与该竞争者在 12 幅图像中各有 6 幅取得最高的逐图均值。微小的数值差距与并列的最优次数表明,这一优势是总体性的而非一致性的:PRISM 在完整图像集上的总体秩更好,但并未在每幅图像上都占优。

<p align="center">
  <img src="figures/fig7_segmentation_visual.png" alt="20 阈值 Kapur 重建结果" width="96%">
  <br>
  <em><b>图 8.</b> 三幅测试图像上的 20 阈值重建示例。各列依次为原图,以及 Kapur 最优的 CMA-ES、EO 与 PRISM 重建结果。</em>
</p>

<p align="center">
  <img src="figures/fig8_segmentation_convergence.png" alt="Kapur 平均最优收敛曲线" width="88%">
  <br>
  <em><b>图 9.</b> 六幅代表性图像上 Kapur 平均最优收敛曲线,20 次运行、4000 次函数评估。数值越大越好。</em>
</p>

结论的适用范围是被刻意限定的。这两项研究说明:同一套 RPG–SRR 机制无需针对任务重新设计,即可被**嵌入**带约束的连续规划问题与离散映射的分割问题,并在两者上产生稳定且具竞争力的结果。它们并不构成"通用优化器优于所有领域专用求解器"的证据;而应用相关的可行性与修复层始终位于优化器之外。


## 7. 参考实现

参考实现是单个自包含的 MATLAB 函数。除调用者提供的目标函数句柄外无任何外部依赖,并可复现论文中报告的基准配置。

```matlab
% 调用者提供目标函数句柄与问题定义。
% 文件内部将 MaxFEs 设为 popsize * maxiter,故 N0 = 40、maxiter = 7500
% 可复现 D = 30 时的 10000*D 次函数评估预算。
[gbestX, gbestfitness, gbesthistory] = PRISM( ...
    [], 40, 30, 100, -100, [], [], 7500, @myObjective, 1, false);
```

<details>
<summary><b>点击展开完整 <code>PRISM.m</code> 源码(含内联文档)</b></summary>


```matlab
function [gbestX,gbestfitness,gbesthistory] = PRISM(mainHandle,popsize,dimension,xmax,xmin,vmax,vmin,maxiter,Func,FuncId,VisualSwitch)
% =========================================================================
%  PRISM -- Priority-Rank Integrated Search Mechanism
%
%  Reference implementation of the algorithm described in the manuscript:
%    "PRISM: A Priority-Rank Integrated Search Mechanism for Single-Objective
%     Black-Box Optimization"
%
%  The manuscript is currently UNDER REVIEW at a peer-reviewed journal.
%  The journal name is withheld for the duration of the review process.
%  This citation record will be updated once the review concludes.
%
%  Copyright (c) 2026  Qingke Zhang
%  School of Computer Science and Artificial Intelligence
%  Shandong Normal University, Jinan 250358, China
%
%  Released under the MIT License. See the LICENSE file in the repository
%  root for the full text. If you use this code in academic work, please
%  cite the manuscript above (see also CITATION.cff).
%
%  Version : V1.0
%  Updated : 2026-09-16
%
% -------------------------------------------------------------------------
%  Input arguments
%    mainHandle    - reserved handle for an external driver (currently unused)
%    popsize       - initial population size N0
%    dimension     - problem dimensionality D
%    xmax, xmin    - upper / lower bounds on the decision variables; scalar or
%                    1-by-D vectors
%    vmax, vmin    - reserved velocity bounds (currently unused: PRISM is a
%                    position-only search and carries no velocity term)
%    maxiter       - iteration cap; MaxFEs is derived as popsize * maxiter
%    Func          - function handle of the objective, called as f(x, FuncId)
%    FuncId        - numeric identifier forwarded to Func
%    VisualSwitch  - display flag; when true, progress is printed every 10%
%                    of the evaluation budget
%
%  Output arguments
%    gbestX        - best solution found, 1-by-D
%    gbestfitness  - objective value of gbestX
%    gbesthistory  - 1-by-MaxFEs record of the best-so-far objective value
%
% -------------------------------------------------------------------------
%  Design notes
%    MaxFEs is computed as popsize * maxiter rather than hard-coded, so the
%    benchmark configuration (N0 = 40, a 10000*D function-evaluation budget)
%    is reproduced by passing maxiter = 250*D. The search itself uses no
%    velocity term: every trial is produced by clipping a position update
%    to [lb, ub].
%
%    Default parameters: p = 0.20, q = 7, r = 0.25, H = 5, epsAccept = 0.001.
%
%    Note: this file releases a snapshot of the implementation that
%    accompanies the submitted manuscript. Any code or results released
%    after the review process concludes should be treated as authoritative.
% =========================================================================
FEs = 0;
MaxFEs = popsize * maxiter;
Fitness = Func;

q = 7;
p = 0.20;
r = 0.25;
epsAccept = 0.001;
epsVal = realmin;
[lb,ub,range] = makeBounds(xmin,xmax,dimension,epsVal);
H = 5;
Mchi = 0.5 * ones(H,1);
MCR  = 0.9 * ones(H,1);
kh = 1;

chiList = [];
crList = [];
dfList = [];

N0 = popsize;
Nmin = min(N0,max(4,round(r * dimension)));
x = lb + rand(popsize,dimension).*range;
fitness = inf(popsize,1);

gbestfitness = inf;
gbestX = zeros(1,dimension);
gbesthistory = zeros(1,MaxFEs);

for i = 1:popsize
    if FEs >= MaxFEs, break; end

    fitness(i) = Fitness(x(i,:)',FuncId);
    FEs = FEs + 1;
    if fitness(i) < gbestfitness
        gbestfitness = fitness(i);
        gbestX = x(i,:);
    end
    gbesthistory(FEs) = gbestfitness;
end
while FEs < MaxFEs

    [~,ind] = sort(fitness,'ascend');
    bestID = ind(1);
    Best = x(bestID,:);
    rank = zeros(popsize,1);
    rank(ind) = 1:popsize;

    % ================= Stage 1: rank-priority learning =================
    for i = 1:popsize
        if FEs >= MaxFEs, break; end

        t = min(1,max(0,FEs/MaxFEs));

        chi = min(1.0,max(0.05,Mchi(randi(H)) + 0.05*randn));
        CR  = min(1.0,max(0.30,MCR(randi(H))  + 0.05*randn));
        elitePool = ind(2:min(q,popsize));
        if isempty(elitePool)
            elitePool = ind(1);
        end
        poorPool = ind(max(1,popsize-q+1):popsize);
        Elite = x(elitePool(randi(numel(elitePool))),:);
        Worst = x(poorPool(randi(numel(poorPool))),:);
        ids = selectID(popsize,i,2);

        Phi = zeros(4,dimension);
        nPhi = 4;

        Phi(1,:) = Best - Worst;
        Phi(2,:) = x(ids(1),:) - x(ids(2),:);
        Phi(3,:) = Best - Elite;
        Phi(4,:) = Elite - Worst;

        if popsize > 1
            rho = min(1,max(0,(rank(i)-1)/(popsize-1)));
        else
            rho = 0;
        end

        K = max(1,min(nPhi,ceil(1 + 3*(1-t)*rho)));
        Omega = randperm(nPhi,K);

        s = zeros(1,K);
        for k = 1:K
            s(k) = norm(Phi(Omega(k),:)) + epsVal;
        end
        step = zeros(1,dimension);
        total = sum(s) + epsVal;

        for k = 1:K
            step = step + (s(k)/total) * chi * Phi(Omega(k),:);
        end

        oldx = x(i,:);
        oldfit = fitness(i);

        newx = oldx;
        jrand = randi(dimension);
        mask = rand(1,dimension) < CR;
        mask(jrand) = true;

        newx(mask) = oldx(mask) + step(mask);
        newx = clip(newx,lb,ub);
        newfit = Fitness(newx',FuncId);
        FEs = FEs + 1;
        if newfit < oldfit
            df = oldfit - newfit;
            x(i,:) = newx;
            fitness(i) = newfit;

            chiList = [chiList; chi]; 
            crList  = [crList;  CR];  
            dfList  = [dfList;  df];  

        elseif rand < epsAccept && i ~= bestID
            x(i,:) = newx;
            fitness(i) = newfit;
        end

        if numel(chiList) >= H
            w = dfList / (sum(dfList) + epsVal);

            Mchi(kh) = sum(w.*chiList.^2)/(sum(w.*chiList)+epsVal);
            MCR(kh)  = sum(w.*crList.^2)/(sum(w.*crList)+epsVal);

            Mchi(kh) = min(1.0,max(0.05,Mchi(kh)));
            MCR(kh)  = min(1.0,max(0.30,MCR(kh)));

            kh = mod(kh,H) + 1;
            chiList = [];
            crList = [];
            dfList = [];
        end
        if fitness(i) < gbestfitness
            gbestfitness = fitness(i);
            gbestX = x(i,:);
        end
        gbesthistory(FEs) = gbestfitness;
    end
    if FEs >= MaxFEs, break; end
    % ================= Stage 2: stratified reflection =================
    [~,ind] = sort(fitness,'ascend');
    bestID = ind(1);

    rank = zeros(popsize,1);
    rank(ind) = 1:popsize;

    topN = min(popsize,max(2,round(p * popsize)));
    half = floor(popsize/2);

    tutorPool = ind(1:min(q,popsize));
    eliteSet = ind(1:topN);

    radius = mean(sqrt(sum((x(eliteSet,:) - gbestX).^2,2))) / dimension;
    radius = max(1e-10,radius);

    center = mean(x(ind(1:min(q,popsize)),:),1);

    t = min(1,max(0,FEs/MaxFEs));
    localFlag = radius < 0.01;

    zeta = min(0.10,max(0.01,0.01 + 0.09*(1-t)));
    ns = 0.05 * (1-t);
    for i = 1:popsize
        if FEs >= MaxFEs, break; end

        ri = rank(i);
        oldx = x(i,:);
        oldfit = fitness(i);

        if ri <= topN && localFlag
            newx = oldx + radius*(gbestX-oldx) + 0.3*radius*range.*randn(1,dimension);
            newx = clip(newx,lb,ub);
            [x(i,:),fitness(i),FEs] = tryEval( ...
                oldx,newx,oldfit,Fitness,FuncId,FEs,i==bestID,epsAccept);
        else
            if ri <= topN
                phi = 0.10 + 0.10*(1-t);
                useTutor = true;
            elseif ri <= half
                phi = min(0.50,max(1/dimension,(ri-topN)/(half-topN+epsVal)*0.30));
                useTutor = true;
            else
                phi = min(0.50,max(min(3,dimension)/dimension,(ri-half)/(popsize-half+epsVal)*0.50));
                useTutor = false;
            end
            mask = rand(1,dimension) < phi;
            if any(mask)
                newx = oldx;

                if useTutor
                    tutor = x(tutorPool(randi(numel(tutorPool))),:);
                    newx(mask) = oldx(mask) + ...
                        (tutor(mask)-oldx(mask)).*rand(1,sum(mask));
                else
                    dir = center - oldx;
                    newx(mask) = oldx(mask) + ...
                        rand*dir(mask) + ns*range(mask).*randn(1,sum(mask));
                end
                reset = mask & (rand(1,dimension) < zeta);
                if any(reset)
                    newx(reset) = lb(reset) + range(reset).*rand(1,sum(reset));
                end
                newx = clip(newx,lb,ub);
                [x(i,:),fitness(i),FEs] = tryEval( ...
                    oldx,newx,oldfit,Fitness,FuncId,FEs,i==bestID,epsAccept);
            end
        end
        if fitness(i) < gbestfitness
            gbestfitness = fitness(i);
            gbestX = x(i,:);
        end
        if FEs <= MaxFEs
            gbesthistory(FEs) = gbestfitness;
        end
    end
    % ================= Adaptive population reduction =================
    newN = round(N0 - (N0-Nmin)*(FEs/MaxFEs));
    newN = max(Nmin,min(N0,newN));
    if popsize > newN
        [~,idx] = sort(fitness,'ascend');
        del = idx(end-(popsize-newN)+1:end);
        x(del,:) = [];
        fitness(del) = [];
        popsize = numel(fitness);
    end
    if nargin >= 11 && VisualSwitch
        if mod(FEs,max(1,floor(MaxFEs/10))) == 0
            fprintf('PRISM | FEs=%d/%d | Pop=%d | Best=%.16e\n',FEs,MaxFEs,popsize,gbestfitness);
        end
    end
end
if FEs < MaxFEs
    gbesthistory(FEs+1:MaxFEs) = gbestfitness;
elseif FEs > MaxFEs
    gbesthistory = gbesthistory(1:MaxFEs);
end
end
function [x,fit,FEs] = tryEval(oldx,newx,oldfit,Fitness,FuncId,FEs,protected,epsAccept)
newfit = Fitness(newx',FuncId);
FEs = FEs + 1;
if newfit < oldfit || (~protected && rand < epsAccept)
    x = newx;
    fit = newfit;
else
    x = oldx;
    fit = oldfit;
end
end
function x = clip(x,lb,ub)
x = min(max(x,lb),ub);
end
function r = selectID(N,i,count)
if N <= 1
    r = ones(1,count);
    return;
end
pool = 1:N;
pool(pool == i) = [];
if isempty(pool)
    r = ones(1,count);
elseif numel(pool) >= count
    r = pool(randperm(numel(pool),count));
else
    r = pool(randi(numel(pool),1,count));
end
end
function [lb,ub,range] = makeBounds(xmin,xmax,D,epsVal)
if isscalar(xmin)
    lb = repmat(xmin,1,D);
else
    lb = reshape(xmin,1,D);
end
if isscalar(xmax)
    ub = repmat(xmax,1,D);
else
    ub = reshape(xmax,1,D);
end
range = ub - lb;
range(range == 0) = epsVal;
end
```

</details>

完整文件位于仓库根目录 [`PRISM.m`](PRISM.m)。默认参数为 `p = 0.20`、`q = 7`、`r = 0.25`、`H = 5`、`ε_acc = 0.001`;基准协议中初始种群规模 `N₀ = 40`。


## 8. 资助与致谢

本工作受国家自然科学基金资助(项目批准号 62006144)。作者诚挚感谢编辑与各位审稿人付出的宝贵时间、提出的深刻意见,以及为评审和改进本稿件所做的努力。


## 版权所有

Copyright (c) 2026 Qingke Zhang. 保留所有权利。

源代码 `PRISM.m` 依据 [MIT 许可证](LICENSE) 发布。本仓库中的论文、插图与文档归作者所有,未经许可不得再分发。配套论文目前处于投稿评审阶段;在引用信息更新之前,请按"投稿评审中的稿件"引用本工作。详见 [NOTICE.md](NOTICE.md)。


<div align="center">
<sub>山东师范大学 计算机与人工智能学院</sub>
</div>
