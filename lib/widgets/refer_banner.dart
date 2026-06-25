import 'package:flutter/material.dart';

/// Calm, supportive banner shown when the AI sets `refer_to_professional: true`.
/// Never blocks access to the app — it offers support, not a harder plan.
class ReferBanner extends StatelessWidget {
  const ReferBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF3E7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7CFA6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.favorite_outline, color: Color(0xFFB07B2E)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'It might help to talk to someone',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF7A5418),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Based on what you shared, connecting with a professional could be '
            'a kind next step. You can keep using Vita anytime — here are some '
            'free, confidential resources:',
            style: TextStyle(color: Color(0xFF7A5418), height: 1.4),
          ),
          const SizedBox(height: 12),
          _resource('988 Suicide & Crisis Lifeline', 'Call or text 988 (US)'),
          _resource('Crisis Text Line', 'Text HOME to 741741'),
          _resource('Find help worldwide', 'iasp.info/resources'),
        ],
      ),
    );
  }

  Widget _resource(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3, right: 8),
            child: Icon(Icons.circle, size: 7, color: Color(0xFFB07B2E)),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF7A5418), fontSize: 14),
                children: [
                  TextSpan(
                    text: '$title — ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
