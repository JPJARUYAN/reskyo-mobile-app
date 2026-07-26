import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../services/incident_service.dart';
import '../../services/dispatch_service.dart';
import '../../widgets/common_widgets.dart';

class ReportStatusScreen extends StatefulWidget {
  final String incidentId;

  const ReportStatusScreen({super.key, required this.incidentId});

  @override
  State<ReportStatusScreen> createState() => _ReportStatusScreenState();
}

class _ReportStatusScreenState extends State<ReportStatusScreen> {
  final _incidentService = IncidentService();
  final _dispatchService = DispatchService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Status'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<dynamic>(
        stream: _incidentService.subscribeToIncident(widget.incidentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final incident = snapshot.data;

          if (incident == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Incident Not Found',
              subtitle: 'This incident report could not be found.',
            );
          }

          final status = incident.status;
          final type = incident.type;
          final photoUrl = incident.photoUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(type, status, incident.createdAt),
                const SizedBox(height: AppSpacing.lg),
                _buildStatusTimeline(status),
                const SizedBox(height: AppSpacing.lg),
                _buildDetailsCard(incident),
                if (photoUrl != null && photoUrl.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildPhotoCard(photoUrl),
                ],
                const SizedBox(height: AppSpacing.lg),
                _buildDispatchInfo(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(IncidentType type, IncidentStatus status, DateTime createdAt) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: type.color.withOpacity(0.15),
                radius: 24,
                child: Icon(type.icon, color: type.color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(
                      'Reported ${DateFormat('MMM d, y • h:mm a').format(createdAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IncidentStatusBadge(status: status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(IncidentStatus currentStatus) {
    final steps = [
      IncidentStatus.reported,
      IncidentStatus.verified,
      IncidentStatus.dispatched,
      IncidentStatus.inProgress,
      IncidentStatus.resolved,
    ];

    final currentIdx = steps.indexOf(currentStatus);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isActive = i <= currentIdx;
            final isCurrent = i == currentIdx;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? step.color : AppColors.textSecondary.withOpacity(0.2),
                        border: isCurrent ? Border.all(color: step.color, width: 3) : null,
                      ),
                      child: isActive
                          ? Icon(step.icon, size: 14, color: Colors.white)
                          : null,
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 32,
                        color: isActive ? step.color.withOpacity(0.5) : AppColors.textSecondary.withOpacity(0.2),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(dynamic incident) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          _buildDetailRow(Icons.description, 'Description', incident.description),
          _buildDetailRow(Icons.location_on, 'Location', incident.address ?? 'Location captured'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(String photoUrl) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Incident Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.network(
              photoUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppColors.textSecondary.withOpacity(0.1),
                child: const Center(child: Icon(Icons.broken_image, size: 48)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchInfo() {
    return StreamBuilder<List<dynamic>>(
      stream: _dispatchService.subscribeToIncidentDispatches(widget.incidentId),
      builder: (context, snapshot) {
        final dispatches = snapshot.data ?? [];

        if (dispatches.isEmpty) {
          return const GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dispatch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.hourglass_empty, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Waiting for responder assignment...', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          );
        }

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dispatch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              ...dispatches.map((d) {
                final dStatus = d.status;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: DispatchStatusBadge(status: dStatus),
                  title: Text('Responder ${d.responderId.substring(0, 8)}...'),
                  subtitle: Text(dStatus.label),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
