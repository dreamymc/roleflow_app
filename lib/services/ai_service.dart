import 'dart:async';
import '../models/role.dart';

class AIService {
  // Singleton pattern
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // THE MOCK BRAIN
  // Later, we will replace this with: Future<String> generateRealSummary(...)
  Future<String> generateRoleSummary(Role role) async {
    // 1. Fake Loading Delay (looks like thinking)
    await Future.delayed(const Duration(seconds: 3));

    // 2. Return Context-Aware Fake Text
    // This makes it look like it actually looked at your role name.
    return "Based on your current activity in the '${role.name}' role, you are maintaining a consistent streak.\n\n"
        "However, you have high-priority tasks due within 48 hours. "
        "Your routine completion rate is 66%, which is good, but try to close the gap on your 'Daily Check-in'.\n\n"
        "💡 Suggestion: Focus on clearing the overdue items before starting new ones.";
  }
}