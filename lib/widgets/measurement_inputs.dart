import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

const double _cmPerInch = 2.54;
const double _kgPerLb = 0.45359237;

/// A pill-shaped two-option unit toggle (e.g. "cm" / "ft·in").
class _UnitToggle extends StatelessWidget {
  const _UnitToggle({
    required this.left,
    required this.right,
    required this.rightSelected,
    required this.onChanged,
  });

  final String left;
  final String right;
  final bool rightSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF1EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(left, !rightSelected, () => onChanged(false)),
          _segment(right, rightSelected, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.deepSage : Colors.black45,
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration({String? hint, String? suffix}) {
  return InputDecoration(
    hintText: hint,
    suffixText: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.sage, width: 2),
    ),
  );
}

/// Height input supporting centimetres or feet + inches. Always reports the
/// canonical value in centimetres via [onCm].
class HeightInput extends StatefulWidget {
  const HeightInput({
    super.key,
    required this.cm,
    required this.imperial,
    required this.onCm,
    required this.onUnitChanged,
  });

  final double? cm;
  final bool imperial;
  final ValueChanged<double?> onCm;
  final ValueChanged<bool> onUnitChanged;

  @override
  State<HeightInput> createState() => _HeightInputState();
}

class _HeightInputState extends State<HeightInput> {
  final _cmCtrl = TextEditingController();
  final _ftCtrl = TextEditingController();
  final _inCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _populateFromCm();
  }

  @override
  void didUpdateWidget(covariant HeightInput old) {
    super.didUpdateWidget(old);
    // Only re-sync the fields when the unit switches, not on every keystroke.
    if (old.imperial != widget.imperial) _populateFromCm();
  }

  void _populateFromCm() {
    final cm = widget.cm;
    if (widget.imperial) {
      if (cm != null) {
        final totalIn = cm / _cmPerInch;
        final ft = totalIn ~/ 12;
        final inch = (totalIn - ft * 12).round();
        _ftCtrl.text = '$ft';
        _inCtrl.text = '$inch';
      }
    } else {
      _cmCtrl.text = cm != null ? cm.toStringAsFixed(0) : '';
    }
  }

  void _emitMetric() {
    widget.onCm(double.tryParse(_cmCtrl.text));
  }

  void _emitImperial() {
    final ft = int.tryParse(_ftCtrl.text);
    final inch = int.tryParse(_inCtrl.text) ?? 0;
    if (ft == null) {
      widget.onCm(null);
    } else {
      widget.onCm((ft * 12 + inch) * _cmPerInch);
    }
  }

  @override
  void dispose() {
    _cmCtrl.dispose();
    _ftCtrl.dispose();
    _inCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UnitToggle(
          left: 'cm',
          right: 'ft·in',
          rightSelected: widget.imperial,
          onChanged: widget.onUnitChanged,
        ),
        const SizedBox(height: 16),
        if (!widget.imperial)
          TextField(
            controller: _cmCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            decoration: _decoration(hint: 'e.g. 178', suffix: 'cm'),
            onChanged: (_) => _emitMetric(),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ftCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  decoration: _decoration(hint: 'e.g. 5', suffix: 'ft'),
                  onChanged: (_) => _emitImperial(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _inCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  decoration: _decoration(hint: 'e.g. 10', suffix: 'in'),
                  onChanged: (_) => _emitImperial(),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Weight input supporting kilograms or pounds. Reports the canonical value in
/// kilograms via [onKg].
class WeightInput extends StatefulWidget {
  const WeightInput({
    super.key,
    required this.kg,
    required this.imperial,
    required this.onKg,
    required this.onUnitChanged,
    this.hint,
  });

  final double? kg;
  final bool imperial;
  final ValueChanged<double?> onKg;
  final ValueChanged<bool> onUnitChanged;
  final String? hint;

  @override
  State<WeightInput> createState() => _WeightInputState();
}

class _WeightInputState extends State<WeightInput> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _populate();
  }

  @override
  void didUpdateWidget(covariant WeightInput old) {
    super.didUpdateWidget(old);
    if (old.imperial != widget.imperial) _populate();
  }

  void _populate() {
    final kg = widget.kg;
    if (kg == null) {
      _ctrl.text = '';
    } else if (widget.imperial) {
      _ctrl.text = (kg / _kgPerLb).toStringAsFixed(0);
    } else {
      _ctrl.text = kg.toStringAsFixed(0);
    }
  }

  void _emit() {
    final v = double.tryParse(_ctrl.text);
    if (v == null) {
      widget.onKg(null);
    } else {
      widget.onKg(widget.imperial ? v * _kgPerLb : v);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UnitToggle(
          left: 'kg',
          right: 'lb',
          rightSelected: widget.imperial,
          onChanged: widget.onUnitChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          decoration: _decoration(
            hint: widget.hint ?? (widget.imperial ? 'e.g. 185' : 'e.g. 85'),
            suffix: widget.imperial ? 'lb' : 'kg',
          ),
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
