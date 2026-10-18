import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class OrganizerParticipantScreen extends StatefulWidget {
  const OrganizerParticipantScreen({super.key});

  @override
  State<OrganizerParticipantScreen> createState() =>
      _OrganizerParticipantScreenState();
}

class _OrganizerParticipantScreenState
    extends State<OrganizerParticipantScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'Semua';

  // Data contoh untuk tampilan awal.
  // Nantinya bisa diganti dengan data dari API Laravel.
  final List<Map<String, String>> _participants = [
    {
      'name': 'Andi Pratama',
      'nim': '3312511101',
      'event': 'Seminar Teknologi 2026',
      'status': 'Terdaftar',
    },
    {
      'name': 'Siti Aulia',
      'nim': '3312511102',
      'event': 'Festival Musik Batam',
      'status': 'Hadir',
    },
    {
      'name': 'Rizky Ramadhan',
      'nim': '3312511103',
      'event': 'Turnamen Futsal Kampus',
      'status': 'Terdaftar',
    },
    {
      'name': 'Nadia Putri',
      'nim': '3312511104',
      'event': 'Seminar Teknologi 2026',
      'status': 'Hadir',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredParticipants = _participants.where((participant) {
      final keyword = _searchController.text.toLowerCase();

      final matchesSearch =
          participant['name']!.toLowerCase().contains(keyword) ||
          participant['nim']!.toLowerCase().contains(keyword);

      final matchesFilter = _selectedFilter == 'Semua' ||
          participant['status'] == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Peserta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari nama atau NIM...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: ['Semua', 'Terdaftar', 'Hadir'].map((filter) {
                final selected = _selectedFilter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredParticipants.isEmpty
                ? const Center(
                    child: Text(
                      'Peserta tidak ditemukan.',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredParticipants.length,
                    itemBuilder: (context, index) {
                      final participant = filteredParticipants[index];
                      final isPresent = participant['status'] == 'Hadir';
                      final name = participant['name']!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(0xFFDBEAFE),
                              child: Text(
                                name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'NIM ${participant['nim']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    participant['event']!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      participant['status']!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isPresent
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}