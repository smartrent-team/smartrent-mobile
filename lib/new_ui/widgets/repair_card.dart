import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/repair_request.dart';
import 'package:intl/intl.dart';

class RepairCard extends StatelessWidget {
  final RepairRequest request;

  const RepairCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left accent bar
          Positioned(
            left: 0,
            top: 20,
            bottom: 20,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: _getStatusColor(request.status),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(request.status).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        request.icon,
                        color: _getStatusColor(request.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  request.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusBadge(request.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                request.category,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: _getStatusColor(request.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                "${request.dateTime.day}/${request.dateTime.month}/${request.dateTime.year} - ${request.dateTime.hour}:${request.dateTime.minute.toString().padLeft(2, '0')}",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (request.status == RepairStatus.processing) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request.id,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "Chi tiết",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_up, size: 18, color: Colors.grey[600]),
                        ],
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(RepairStatus status) {
    String text = "";
    Color color = Colors.grey;

    switch (status) {
      case RepairStatus.received:
        text = "Tiếp nhận";
        color = Colors.blue;
        break;
      case RepairStatus.processing:
        text = "Đang sửa";
        color = Colors.orange;
        break;
      case RepairStatus.completed:
        text = "Hoàn thành";
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.received:
        return Colors.blue;
      case RepairStatus.processing:
        return Colors.orange;
      case RepairStatus.completed:
        return Colors.green;
    }
  }
}
