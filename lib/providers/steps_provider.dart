import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/step_service.dart';

/// Today's live step count. Stays in the loading state forever on platforms
/// without a step sensor (web/desktop), which the UI treats as "unavailable".
final stepsProvider = StreamProvider<int>((ref) => StepService.todaySteps());
