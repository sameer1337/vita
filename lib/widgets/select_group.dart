import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'fade_in.dart';

/// A single selectable option row used by [SingleSelectGroup] and
/// [MultiSelectGroup]. Animates color/border on selection and gives a subtle
/// scale feedback on tap.
class OptionTile extends StatefulWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<OptionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppTheme.sage.withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.selected
                    ? AppTheme.sage
                    : const Color(0xFFE2E8E5),
                width: widget.selected ? 2 : 1,
              ),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: AppTheme.sage.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w500,
                      color: AppTheme.deepSage,
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: widget.selected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: const Icon(Icons.check_circle,
                      color: AppTheme.sage, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pick exactly one option.
class SingleSelectGroup extends StatelessWidget {
  const SingleSelectGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < options.length; i++)
          FadeIn(
            delay: Duration(milliseconds: 60 * i),
            child: OptionTile(
              label: options[i],
              selected: selected == options[i],
              onTap: () => onSelected(options[i]),
            ),
          ),
      ],
    );
  }
}

/// Pick any number of options.
class MultiSelectGroup extends StatelessWidget {
  const MultiSelectGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < options.length; i++)
          FadeIn(
            delay: Duration(milliseconds: 60 * i),
            child: OptionTile(
              label: options[i],
              selected: selected.contains(options[i]),
              onTap: () => onToggle(options[i]),
            ),
          ),
      ],
    );
  }
}
