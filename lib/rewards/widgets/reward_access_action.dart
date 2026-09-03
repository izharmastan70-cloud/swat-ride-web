import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/reward_production_gate.dart';
import '../models/reward_point_model.dart';
import '../reward_routes.dart';

/// Direct Rewards entry shared by every SWAT RIDE customer and partner role.
/// It only opens the wallet. It never applies discounts or confirms payments.
class RewardAccessAction extends StatelessWidget {
  const RewardAccessAction({super.key, required this.moduleName});

  final String moduleName;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Rewards & Loyalty',
      icon: const Icon(Icons.workspace_premium_outlined),
      onPressed: () => _openRewards(context),
    );
  }

  void _openRewards(BuildContext context) {
    if (!RewardProductionGate.customerRewardsAccessEnabled) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Rewards are temporarily unavailable while secure production processing is being completed.',
            ),
          ),
        );
      return;
    }
    final userId = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please sign in to open Rewards.')),
        );
      return;
    }

    Navigator.pushNamed(
      context,
      RewardRouteNames.wallet,
      arguments: RewardRouteArguments(
        userId: userId,
        module: _moduleFromName(moduleName),
      ),
    );
  }

  RewardModule _moduleFromName(String value) {
    for (final module in RewardModule.values) {
      if (module.name == value) return module;
    }
    return RewardModule.future;
  }
}
