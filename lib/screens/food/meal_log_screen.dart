import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/daily_data.dart';
import '../../providers/daily_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Log a meal by photo or text. The photo is analyzed by Groq vision, then
/// nutrition is looked up; the user confirms (and can edit calories) before it
/// is saved to today's totals.
class MealLogScreen extends ConsumerStatefulWidget {
  const MealLogScreen({super.key});

  @override
  ConsumerState<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends ConsumerState<MealLogScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();
  final _textController = TextEditingController();

  bool _photoMode = true;
  Uint8List? _photoBytes;
  String? _photoPath;
  bool _loading = false;
  String? _error;
  NutritionResult? _result;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _error = null);
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() {
        _photoBytes = bytes;
        _photoPath = x.path;
        _result = null;
      });
    } catch (e) {
      setState(() => _error = 'Could not open the camera/gallery: $e');
    }
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final NutritionResult res;
      if (_photoMode) {
        if (_photoBytes == null) {
          throw ApiException('Add a photo first.');
        }
        res = await _api.nutritionFromPhoto(_photoBytes!);
      } else {
        final text = _textController.text.trim();
        if (text.isEmpty) throw ApiException('Describe your meal first.');
        res = await _api.nutritionFromText(text);
      }
      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _save() {
    final r = _result;
    if (r == null) return;
    ref.read(dailyProvider.notifier).logMeal(
          FoodEntry(
            label: r.label,
            calories: r.calories,
            proteinG: r.proteinG,
            carbsG: r.carbsG,
            fatG: r.fatG,
            photoPath: _photoMode ? _photoPath : null,
            loggedAt: DateTime.now(),
          ),
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log a meal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _modeToggle(),
            const SizedBox(height: 20),
            if (_photoMode) _photoSection() else _textSection(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _errorBox(_error!),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              _resultCard(_result!),
            ],
            const SizedBox(height: 24),
            if (_result == null)
              FilledButton.icon(
                onPressed: _loading ? null : _analyze,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_loading ? 'Analyzing…' : 'Analyze meal'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modeToggle() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: true,
          icon: Icon(Icons.photo_camera_rounded),
          label: Text('Photo'),
        ),
        ButtonSegment(
          value: false,
          icon: Icon(Icons.edit_note_rounded),
          label: Text('Describe'),
        ),
      ],
      selected: {_photoMode},
      onSelectionChanged: (s) => setState(() {
        _photoMode = s.first;
        _result = null;
        _error = null;
      }),
    );
  }

  Widget _photoSection() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.sage.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8E5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _photoBytes == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_rounded,
                            size: 48, color: AppTheme.sage),
                        SizedBox(height: 8),
                        Text('Snap or choose a photo of your meal',
                            style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                : Image.memory(_photoBytes!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _textSection() {
    return TextField(
      controller: _textController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'e.g. 2 eggs, 2 slices toast with butter, and a banana',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
        ),
      ),
    );
  }

  Widget _resultCard(NutritionResult r) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.label,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.deepSage)),
          const SizedBox(height: 4),
          Text('${r.calories} kcal',
              style: const TextStyle(
                  color: AppTheme.sage,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 16),
          Row(
            children: [
              _macroPill('P', r.proteinG, const Color(0xFF6B9080)),
              const SizedBox(width: 10),
              _macroPill('C', r.carbsG, const Color(0xFF5B8DB8)),
              const SizedBox(width: 10),
              _macroPill('F', r.fatG, const Color(0xFFD9A86C)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _result = null),
                  child: const Text('Redo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Add to today'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Estimates only — adjust portions in your head if it looks off.',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _macroPill(String letter, int grams, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('$grams g',
                style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(letter,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0566E).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE0566E)),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
