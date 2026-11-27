import 'package:flutter/material.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/inventory/data/models/stock_adjustment_request.dart';

double computeProjectedStock(
  AdjustmentMode mode,
  double currentOnHand,
  double enteredQty,
) {
  switch (mode) {
    case AdjustmentMode.increase:
      return currentOnHand + enteredQty;
    case AdjustmentMode.decrease:
      return currentOnHand - enteredQty;
    case AdjustmentMode.recount:
      return enteredQty;
  }
}

class StockImpactPreviewCard extends StatelessWidget {
  const StockImpactPreviewCard({
    super.key,
    required this.currentOnHand,
    required this.mode,
    required this.enteredQty,
  });

  final double currentOnHand;
  final AdjustmentMode mode;
  final double? enteredQty;

  @override
  Widget build(BuildContext context) {
    final qty = enteredQty ?? 0.0;
    final projected = computeProjectedStock(mode, currentOnHand, qty);
    final delta = projected - currentOnHand;
    final isNegative = projected < 0;

    final deltaText = delta > 0
        ? '+${delta.toStringAsFixed(2)}'
        : delta.toStringAsFixed(2);
    final deltaColor = delta > 0
        ? const Color(0xFF16A34A)
        : (delta < 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B));

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: isNegative ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: isNegative ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PreviewMetric(
              label: 'Current Stock',
              value: currentOnHand.toStringAsFixed(2),
              color: const Color(0xFF0F172A),
            ),
          ),
          Expanded(
            child: _PreviewMetric(
              label: 'Delta',
              value: deltaText,
              color: deltaColor,
            ),
          ),
          Expanded(
            child: _PreviewMetric(
              label: 'New Balance',
              value: projected.toStringAsFixed(2),
              color: isNegative ? const Color(0xFFDC2626) : BrandColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
