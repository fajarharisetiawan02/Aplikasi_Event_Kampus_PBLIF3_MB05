import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';
import '../utils/app_colors.dart';
import 'ticket_detail_screen.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<TicketModel>> _futureTickets;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _futureTickets = TicketService.getMyTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiket Saya', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(12)),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF64748B),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            dividerColor: Colors.transparent,
            tabs: const [Tab(text: 'Aktif'), Tab(text: 'Riwayat')],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<TicketModel>>(
            future: _futureTickets,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Gagal memuat tiket: ${snapshot.error}'));
              }

              final allTickets = snapshot.data ?? [];
              final activeTickets = allTickets.where((t) => t.status == TicketStatus.aktif).toList();
              final historyTickets = allTickets.where((t) => t.status != TicketStatus.aktif).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildTicketList(activeTickets, emptyText: 'Belum ada tiket aktif'),
                  _buildTicketList(historyTickets, emptyText: 'Belum ada riwayat tiket'),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTicketList(List<TicketModel> tickets, {required String emptyText}) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.confirmation_number_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyText, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: tickets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ticketCard(tickets[index]),
    );
  }

  Widget _ticketCard(TicketModel ticket) {
    final isActive = ticket.status == TicketStatus.aktif;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: Image.network(
                ticket.eventImage,
                width: 90,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 90,
                  height: 100,
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: Icon(Icons.image_outlined, color: AppColors.primaryBlue),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.eventTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(ticket.eventDate, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(ticket.eventLocation, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ticket.statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? AppColors.primaryBlue : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}