import 'package:design_system/design_system.dart';
import 'package:driver/src/features/earnings/domain/entities/earnings_summary.dart';
import 'package:driver/src/features/earnings/presentation/bloc/earnings_cubit.dart';
import 'package:driver/src/features/earnings/presentation/bloc/earnings_state.dart';
import 'package:driver/src/features/earnings/presentation/widgets/earnings_chart_card.dart';
import 'package:driver/src/features/earnings/presentation/widgets/earnings_period_bar.dart';
import 'package:driver/src/features/earnings/presentation/widgets/earnings_sections.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  static const _loadingSummary = EarningsPeriodSummary(
    total: 88.88,
    tripsCount: 3,
    days: [
      EarnDayBucket(day: 'Mon', amount: 30, tripsCount: 1),
      EarnDayBucket(day: 'Tue', amount: 20, tripsCount: 1),
      EarnDayBucket(day: 'Wed', amount: 38.88, tripsCount: 1),
      EarnDayBucket(day: 'Thu', amount: 0),
      EarnDayBucket(day: 'Fri', amount: 0),
      EarnDayBucket(day: 'Sat', amount: 0),
      EarnDayBucket(day: 'Sun', amount: 0),
    ],
  );

  EarningsPeriod _selectedPeriod = EarningsPeriod.weekly;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<EarningsCubit, EarningsState>(
          builder: (context, state) {
            final summary = state.data?.summaryFor(_selectedPeriod);
            final errorMessage = state.errorMessage;
            if (summary == null && errorMessage != null) {
              return AppRetryErrorView(
                title: 'Unable to load earnings',
                message: errorMessage,
                onRetry: context.read<EarningsCubit>().load,
              );
            }
            return RefreshIndicator(
              color: context.colorScheme.onSurface,
              onRefresh: context.read<EarningsCubit>().load,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360
                      ? AppSpacing.lg
                      : AppLayout.pagePaddingWide;
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.sm,
                      horizontalPadding,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppLayout.pageMaxWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const AppPageHeader(title: 'Earnings'),
                              const SizedBox(height: AppSpacing.xl),
                              if (summary == null)
                                _buildLoadingState()
                              else
                                _buildContent(
                                  summary,
                                  errorMessage: errorMessage,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() => ExcludeSemantics(
    child: Skeletonizer(
      key: const ValueKey<String>('driver-earnings-loading-skeleton'),
      child: _buildContent(_loadingSummary, isLoading: true),
    ),
  );

  Widget _buildContent(
    EarningsPeriodSummary summary, {
    String? errorMessage,
    bool isLoading = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (errorMessage != null) ...[
        AppErrorBanner(
          message: errorMessage,
          onRetry: context.read<EarningsCubit>().load,
          onDismiss: context.read<EarningsCubit>().dismissError,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      EarningsSummaryHeader(summary: summary, selectedPeriod: _selectedPeriod),
      const SizedBox(height: AppSpacing.xl),
      EarningsPeriodBar(
        selectedPeriod: _selectedPeriod,
        onSelected: (period) {
          if (period == _selectedPeriod) return;
          setState(() {
            _selectedPeriod = period;
            _showAll = false;
          });
        },
      ),
      const SizedBox(height: AppSpacing.xl),
      EarningsChartCard(days: summary.days, isLoading: isLoading),
      const SizedBox(height: AppSpacing.xl),
      EarningsStatsSection(summary: summary, selectedPeriod: _selectedPeriod),
      const SizedBox(height: AppSpacing.xxl),
      EarningsRecentList(
        summary: summary,
        selectedPeriod: _selectedPeriod,
        showAll: _showAll,
        onToggleShowAll: () => setState(() => _showAll = !_showAll),
      ),
    ],
  );
}
