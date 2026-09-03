import 'package:flutter/material.dart';

import '../models/agent_evaluation_run.dart';
import '../services/agent_evaluation_run_repository.dart';

/// Super Admin read-only history for Phase 42 evaluation runs.
///
/// This screen intentionally exposes no create/update/delete action, no
/// training action, no prompt/model mutation, no provider action, and no
/// deployment action.
class AgentEvaluationResultsScreen extends StatelessWidget {
  AgentEvaluationResultsScreen({
    super.key,
    AgentEvaluationRunRepository? repository,
  }) : _repository = repository ?? AgentEvaluationRunRepository();

  final AgentEvaluationRunRepository _repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Evaluation Results')),
      body: StreamBuilder<List<AgentEvaluationRun>>(
        stream: _repository.watchRecent(limit: 100),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<AgentEvaluationRun>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Evaluation history could not be loaded.\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final List<AgentEvaluationRun> runs =
                  snapshot.data ?? const <AgentEvaluationRun>[];

              if (runs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No evaluation runs have been persisted yet.\n\n'
                      'This screen is read-only.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: runs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  return _runCard(runs[index]);
                },
              );
            },
      ),
    );
  }

  Widget _runCard(AgentEvaluationRun run) {
    final String status = run.failClosed
        ? 'FAIL CLOSED'
        : run.eligibleForHumanReview
        ? 'HUMAN REVIEW ELIGIBLE'
        : 'NOT ELIGIBLE';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              status,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _metric('Run ID', run.runId),
            _metric('Catalog', run.catalogVersion),
            _metric('Evaluator', run.evaluatorVersion),
            _metric('Policy', run.policyVersion),
            _metric(
              'Pass',
              '${run.passedCount}/${run.totalCount} '
                  '(${run.passPercent.toStringAsFixed(1)}%)',
            ),
            _metric(
              'Weighted score',
              '${run.weightedScorePercent.toStringAsFixed(1)}%',
            ),
            _metric('Failed', run.failedCount.toString()),
            _metric('Blocked', run.blockedCount.toString()),
            _metric('Critical failures', run.criticalFailureCount.toString()),
            _metric('High failures', run.highFailureCount.toString()),
            _metric('Safety violations', run.safetyViolationCount.toString()),
            _metric('Threshold passed', run.thresholdPassed ? 'YES' : 'NO'),
            _metric('Fail closed', run.failClosed ? 'YES' : 'NO'),
            _metric(
              'Human review eligible',
              run.eligibleForHumanReview ? 'YES' : 'NO',
            ),
            _metric('Completed', run.completedAt.toLocal().toIso8601String()),
            const SizedBox(height: 8),
            const Text(
              'Read-only evidence. No training, prompt/model update, '
              'provider execution or deployment is available here.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value'),
    );
  }
}
