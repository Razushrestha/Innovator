import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:innovator/App_data/App_data.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Report> reports = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final appData = AppData();
      final token = appData.authToken;

      if (token == null) {
        setState(() {
          error = 'Authentication required. Please login again.';
          isLoading = false;
        });
        return;
      }

      developer.log(
        'Fetching reports with token: ${token.substring(0, 20)}...',
      );

      final response = await http.get(
        Uri.parse('http://182.93.94.210:3064/api/v1/reports'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> reportsData = data['data'];

        developer.log('Successfully fetched ${reportsData.length} reports');

        setState(() {
          reports = reportsData.map((json) => Report.fromJson(json)).toList();
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Handle unauthorized - clear token and redirect to login
        await appData.logout();
        setState(() {
          error = 'Session expired. Please login again.';
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load reports: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Reports Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.indigo[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchReports,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
            ),
            SizedBox(height: 16),
            Text(
              'Loading reports...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              error!,
              style: TextStyle(fontSize: 16, color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchReports,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No reports found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All clear! No reports to review.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchReports,
      color: Colors.indigo[600],
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          return ReportCard(report: reports[index]);
        },
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final Report report;

  const ReportCard({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report #${report.id.substring(report.id.length - 6)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                _buildStatusChip(report.status),
              ],
            ),
            SizedBox(height: 12),

            // Reporter info
            _buildUserInfo(
              'Reported by',
              report.reporter,
              Icons.person_outline,
              Colors.blue[600]!,
            ),
            SizedBox(height: 8),

            // Reported user info
            _buildUserInfo(
              'Reported user',
              report.reportedUser,
              Icons.person_off_outlined,
              Colors.red[600]!,
            ),
            SizedBox(height: 12),

            // Reason and description
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.report_problem_outlined,
                        size: 16,
                        color: Colors.orange[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Reason: ${report.reason}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    report.description,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Footer with date and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(report.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (report.status == 'pending')
                  Row(
                    children: [
                      Text(
                        'Pending',
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ],
                  ),
                if (report.status == 'resolved')
                  Row(
                    children: [
                      Text(
                        'Resolved',
                        style: TextStyle(fontSize: 18, color: Colors.green),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.hourglass_empty;
        break;
      case 'approved':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.cancel_outlined;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String label, User user, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            '${user.name} (${user.email})',
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleAction(BuildContext context, String action, String reportId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm ${action.toUpperCase()}'),
          content: Text('Are you sure you want to $action this report?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implement API call to update report status
                _updateReportStatus(context, reportId, action);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    action == 'approve' ? Colors.green[600] : Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text(action.toUpperCase()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateReportStatus(
    BuildContext context,
    String reportId,
    String action,
  ) async {
    try {
      // Implement your API call here
      // final response = await http.patch(
      //   Uri.parse('http://182.93.94.210:3064/api/v1/reports/$reportId'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'status': action == 'approve' ? 'approved' : 'rejected'}),
      // );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report ${action}d successfully'),
          backgroundColor:
              action == 'approve' ? Colors.green[600] : Colors.red[600],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to $action report: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }
}

// Data models
class Report {
  final String id;
  final User reporter;
  final User reportedUser;
  final String reason;
  final String description;
  final String status;
  final String createdAt;

  Report({
    required this.id,
    required this.reporter,
    required this.reportedUser,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['_id'],
      reporter: User.fromJson(json['reporter']),
      reportedUser: User.fromJson(json['reportedUser']),
      reason: json['reason'],
      description: json['description'],
      status: json['status'],
      createdAt: json['createdAt'],
    );
  }
}

class User {
  final String id;
  final String email;
  final String name;

  User({required this.id, required this.email, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['_id'], email: json['email'], name: json['name']);
  }
}
