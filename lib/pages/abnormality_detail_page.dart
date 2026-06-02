import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/abnormality.dart';
import '../models/work_log.dart';
import '../services/breach_service.dart';
import '../services/work_service.dart';
import '../state/app_providers.dart';
import '../widgets/abnormality_image.dart';
import '../widgets/breach_alert_overlay.dart';
import '../widgets/lcorp_button.dart';
import '../widgets/lcorp_grid_background.dart';
import '../widgets/qliphoth_counter_widget.dart';
import 'attachment_chat_page.dart';

/// 异想体详情页 / 工作控制台。
class AbnormalityDetailPage extends ConsumerStatefulWidget {
  const AbnormalityDetailPage({super.key, required this.abnormalityId});

  final String abnormalityId;

  @override
  ConsumerState<AbnormalityDetailPage> createState() =>
      _AbnormalityDetailPageState();
}

class _AbnormalityDetailPageState
    extends ConsumerState<AbnormalityDetailPage> {
  WorkOutcome? _lastOutcome;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Abnormality>> async =
        ref.watch(abnormalitiesProvider);

    final Abnormality? target = async.whenOrNull(
      data: (list) => list.firstWhere(
        (a) => a.id == widget.abnormalityId,
        orElse: () => list.first,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(target?.name ?? 'CONTAINMENT'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LCorpGridBackground()),
          Positioned.fill(
            child: target == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(target),
                        const SizedBox(height: 12),
                        _buildPortrait(target),
                        const SizedBox(height: 12),
                        _buildStatusPanel(target),
                        if (target.isEscaped) ...[
                          const SizedBox(height: 12),
                          _buildSuppressionPanel(target),
                        ],
                        const SizedBox(height: 16),
                        _buildDescription(target),
                        const SizedBox(height: 20),
                        _buildWorkConsole(target),
                        if (_lastOutcome != null) ...[
                          const SizedBox(height: 20),
                          _buildReactionPanel(_lastOutcome!),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Abnormality a) {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppColors.alert,
          child: Text(
            a.grade,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.background,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          a.id,
          style: const TextStyle(
            fontFamily: AppTheme.monoFontFamily,
            color: AppColors.hint,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        const Spacer(),
        if (a.isNegative)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.alert, width: 1),
            ),
            child: const Text(
              'NEGATIVE',
              style: TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                color: AppColors.alert,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPortrait(Abnormality a) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: AbnormalityImage(
        assetPath: a.portraitAssetPath,
        iconSize: 96,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildStatusPanel(Abnormality a) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '// CONTAINMENT STATUS',
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.alert,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          _LedBar(
            label: 'ENERGY',
            current: a.energyLevel,
            max: 100,
            segments: 10,
            color: a.isNegative ? AppColors.alert : AppColors.primary,
          ),
          const SizedBox(height: 6),
          QliphothCounterWidget(
            current: a.qliphothCounter,
            max: a.qliphothMax,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Abnormality a) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a.description,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.onBackground,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.background,
            child: Text(
              a.manageNote,
              style: const TextStyle(
                fontFamily: AppTheme.monoFontFamily,
                color: AppColors.hint,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkConsole(Abnormality a) {
    final List<_WorkAction> actions = [
      _WorkAction(WorkType.instinct, 'INSTINCT', '本能'),
      _WorkAction(WorkType.insight, 'INSIGHT', '洞察'),
      _WorkAction(WorkType.attachment, 'ATTACHMENT', '沟通'),
      _WorkAction(WorkType.repression, 'REPRESSION', '压迫'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '// WORK CONSOLE',
          style: TextStyle(
            fontFamily: AppTheme.monoFontFamily,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: actions
              .map(
                (act) => LCorpButton(
                  label: '${act.label}\n${act.zhLabel}',
                  onPressed: _busy ? null : () => _execute(a, act.id),
                  height: 56,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildReactionPanel(WorkOutcome o) {
    final Color tone = o.success ? AppColors.primary : AppColors.alert;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: tone, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                o.success
                    ? '// WORK SUCCEEDED'
                    : (o.isCriticalFail
                        ? '// CRITICAL FAILURE'
                        : '// WORK FAILED'),
                style: TextStyle(
                  fontFamily: AppTheme.monoFontFamily,
                  color: tone,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              if (o.peBoxGained > 0)
                Text(
                  '+${o.peBoxGained} PE',
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            o.reaction,
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.onBackground,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppressionPanel(Abnormality a) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.alert, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '// CONTAINMENT BREACH — ESCAPE',
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.alert,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '该异想体已脱离收容，每分钟扣除 ${a.escapeDrain ?? 0} PE Box。'
            '可派遣员工执行镇压，或等待 30 分钟后自动返回。',
            style: const TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: AppColors.onBackground,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LCorpButton(
                  label: 'SUPPRESS',
                  height: 40,
                  onPressed: _busy ? null : () => _suppress(a),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LCorpButton(
                  label: 'WAIT',
                  height: 40,
                  enableScanline: false,
                  onPressed: _busy
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('// MONITORING ESCAPE...'),
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _suppress(Abnormality a) async {
    setState(() => _busy = true);
    try {
      final SuppressionOutcome o = await ref
          .read(breachServiceProvider)
          .attemptSuppression(abnormalityId: a.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(o.success
              ? '// SUPPRESSION SUCCESS  +${o.peBoxGained} PE'
              : '// SUPPRESSION FAILED  HP ${o.hpDelta}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('// $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showBreachAlert(BreachEvent breach) async {
    final BreachType t = breach.type;
    final String title = t == BreachType.escape
        ? 'CONTAINMENT BREACH — ESCAPE'
        : (t == BreachType.penaltyBox
            ? 'CONTAINMENT BREACH — PENALTY'
            : 'CONTAINMENT INCIDENT');
    final String desc = t == BreachType.escape
        ? '${breach.abnormality.name} 已脱离收容。'
        : (t == BreachType.penaltyBox
            ? '${breach.abnormality.name} 触发惩罚，损失 ${breach.peBoxLost} PE Box。'
            : '${breach.abnormality.name} 已重置。');
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) => BreachAlertOverlay(
        title: title,
        description: desc,
        onAck: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _execute(Abnormality a, String workType) async {
    // 沟通工作：跳转聊天页（6.5）
    if (workType == WorkType.attachment) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              AttachmentChatPage(abnormalityId: a.id),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final WorkOutcome outcome = await ref
          .read(workServiceProvider)
          .performWork(abnormalityId: a.id, workType: workType);
      if (!mounted) return;
      setState(() => _lastOutcome = outcome);
      if (outcome.breach != null) {
        await _showBreachAlert(outcome.breach!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('// $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _WorkAction {
  const _WorkAction(this.id, this.label, this.zhLabel);
  final String id;
  final String label;
  final String zhLabel;
}

/// 分段式 LED 进度条（用于能量值与逆卡巴拉计数器）。
class _LedBar extends StatelessWidget {
  const _LedBar({
    required this.label,
    required this.current,
    required this.max,
    required this.segments,
    required this.color,
  });

  final String label;
  final int current;
  final int max;
  final int segments;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final int safeMax = max <= 0 ? 1 : max;
    final int safeSegments = segments <= 0 ? 1 : segments;
    final double progress = (current / safeMax).clamp(0.0, 1.0);
    final int litCount = (progress * safeSegments).round();

    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.monoFontFamily,
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(safeSegments, (i) {
              final bool lit = i < litCount;
              return Expanded(
                child: Container(
                  height: 14,
                  margin: EdgeInsets.only(
                    right: i == safeSegments - 1 ? 0 : 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        lit ? color : color.withValues(alpha: 0.10),
                    border: Border.all(color: color, width: 0.6),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
