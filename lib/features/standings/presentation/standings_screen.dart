import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/liquid_glass_theme.dart';
import '../../../services/standings_service.dart';

class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(currentStandingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Driver Standings', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.bg,
        leading: const BackButton(color: Colors.white),
      ),
      body: standingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.f1Red)),
        error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
        data: (standings) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Table header
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                child: Row(
                  children: const [
                    SizedBox(width: 32, child: Text('POS', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
                    SizedBox(width: 12),
                    Expanded(child: Text('DRIVER', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
                    Text('PTS', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < standings.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${standings[i].position}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: i == 0 ? AppTheme.f1Red : i < 3 ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${standings[i].givenName} ${standings[i].familyName}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: i < 3 ? Colors.white : AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(standings[i].constructorName, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${standings[i].points}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: i < 3 ? Colors.white : AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Text('pts', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (i < standings.length - 1)
                        const Divider(height: 1, color: AppTheme.border, indent: 60, endIndent: 0),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
