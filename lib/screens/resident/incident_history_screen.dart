import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../../services/incident_service.dart';
import '../../widgets/common_widgets.dart';
import 'report_status_screen.dart';

class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  final _authService = AuthService();
  final _incidentService = IncidentService();
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userId = _authService.currentUserId;
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_userId == null) {
      return const EmptyState(
        icon: Icons.person_off,
        title: 'Not Logged In',
        subtitle: 'Please log in to view your reports.',
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: _incidentService.getIncidents(reporterId: _userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final incidents = snapshot.data ?? [];

        if (incidents.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No Reports Yet',
            subtitle: 'Your submitted incident reports will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.sm),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final incident = incidents[index];
            final status = incident.status;
            final type = incident.type;
            final photoUrl = incident.photoUrl;

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportStatusScreen(incidentId: incident.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photoUrl != null && photoUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Image.network(
                            photoUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 64,
                              height: 64,
                              color: type.color.withOpacity(0.1),
                              child: Icon(type.icon, color: type.color, size: 28),
                            ),
                          ),
                        )
                      else
                        CircleAvatar(
                          backgroundColor: type.color.withOpacity(0.12),
                          radius: 28,
                          child: Icon(type.icon, color: type.color, size: 24),
                        ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    type.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IncidentStatusBadge(status: status),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              incident.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              DateFormat('MMM d, y • h:mm a').format(incident.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
