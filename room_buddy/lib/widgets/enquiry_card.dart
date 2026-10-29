import 'package:flutter/material.dart';
import 'package:room_buddy/models/enquiry_model.dart';
import 'package:room_buddy/core/utils/helpers.dart';
import 'package:room_buddy/core/constants/app_colors.dart';

class EnquiryCard extends StatefulWidget {
  final EnquiryModel enquiry;
  final bool isLandlord;
  final Function(String)? onRespond;
  final Function(String)? onUpdateStatus;

  const EnquiryCard({
    super.key,
    required this.enquiry,
    this.isLandlord = false,
    this.onRespond,
    this.onUpdateStatus,
  });

  @override
  State<EnquiryCard> createState() => _EnquiryCardState();
}

class _EnquiryCardState extends State<EnquiryCard> {
  bool _isExpanded = false;
  final TextEditingController _replyController = TextEditingController();

  final List<String> _quickReplies = [
    'Yes, it is available for move-in!',
    'Would you like to schedule a visit?',
    'Rent includes water and high-speed WiFi.',
  ];

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'responded':
        return const Color(0xFF10B981); // Emerald
      case 'closed':
        return const Color(0xFF64748B); // Slate
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'responded':
        return const Color(0xFFD1FAE5);
      case 'closed':
        return const Color(0xFFF1F5F9);
      default:
        return const Color(0xFFEEF2FF);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'responded':
        return Icons.check_circle_outline_rounded;
      case 'closed':
        return Icons.lock_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.enquiry.status);
    final statusBg = _getStatusBg(widget.enquiry.status);
    final status = widget.enquiry.status.toLowerCase();

    final initials = widget.isLandlord
        ? (widget.enquiry.studentName.isNotEmpty
            ? widget.enquiry.studentName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
            : 'ST')
        : (widget.enquiry.landlordName.isNotEmpty
            ? widget.enquiry.landlordName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
            : 'LL');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status == 'pending' ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: status == 'pending' ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: status == 'pending' ? const Color(0x14F59E0B) : const Color(0x0A0F172A),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top clickable card header
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(20),
                bottom: Radius.circular(_isExpanded ? 0 : 20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender Row & Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar circle
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.isLandlord
                                  ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                                  : [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name and Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.isLandlord ? widget.enquiry.studentName : widget.enquiry.landlordName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.isLandlord ? 'Student' : 'Landlord',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                Helpers.timeAgo(widget.enquiry.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getStatusIcon(widget.enquiry.status), size: 13, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                widget.enquiry.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Property reference chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.apartment_rounded, size: 16, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.enquiry.propertyTitle.isNotEmpty
                                  ? widget.enquiry.propertyTitle
                                  : 'Property #${widget.enquiry.propertyId}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Initial Inquiry Message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        widget.enquiry.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                          height: 1.45,
                        ),
                        maxLines: _isExpanded ? null : 2,
                        overflow: _isExpanded ? null : TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Expand / Collapse Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.enquiry.responses.isEmpty
                              ? 'No responses yet'
                              : '${widget.enquiry.responses.length} response${widget.enquiry.responses.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.enquiry.responses.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF4F46E5),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _isExpanded ? 'Hide conversation' : 'View conversation & reply',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: const Color(0xFF4F46E5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expanded conversation and landlord actions
            if (_isExpanded) ...[
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conversation History',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Responses list
                    if (widget.enquiry.responses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.mark_chat_unread_outlined, size: 20, color: Color(0xFF94A3B8)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Awaiting landlord reply. Students usually book within 24 hours of response!',
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...widget.enquiry.responses.map((resp) {
                        final isMe = widget.isLandlord
                            ? resp.senderId == widget.enquiry.landlordId
                            : resp.senderId == widget.enquiry.studentId;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            constraints: const BoxConstraints(maxWidth: 380),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF4F46E5) : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(isMe ? 14 : 2),
                                bottomRight: Radius.circular(isMe ? 2 : 14),
                              ),
                              border: Border.all(
                                color: isMe ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x080F172A),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      resp.senderName.isNotEmpty ? resp.senderName : (isMe ? 'You' : 'Student'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: isMe ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      Helpers.timeAgo(resp.timestamp),
                                      style: TextStyle(
                                        color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  resp.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isMe ? Colors.white : const Color(0xFF334155),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    // Quick replies (for Landlord)
                    if (widget.isLandlord && status != 'closed') ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Quick Replies:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _quickReplies.map((reply) {
                          return InkWell(
                            onTap: () {
                              _replyController.text = reply;
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                reply,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Reply Input Box
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x080F172A),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _replyController,
                                minLines: 1,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Type your reply to student...',
                                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4F46E5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                onPressed: () {
                                  final text = _replyController.text.trim();
                                  if (text.isNotEmpty && widget.onRespond != null) {
                                    widget.onRespond!(text);
                                    _replyController.clear();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Status management buttons
                      Row(
                        children: [
                          if (status == 'pending')
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => widget.onUpdateStatus?.call('responded'),
                                icon: const Icon(Icons.check_rounded, size: 16, color: Color(0xFF10B981)),
                                label: const Text('Mark Responded', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF10B981)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          if (status == 'pending') const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => widget.onUpdateStatus?.call('closed'),
                              icon: const Icon(Icons.archive_outlined, size: 16, color: Color(0xFF64748B)),
                              label: const Text('Close Enquiry', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
