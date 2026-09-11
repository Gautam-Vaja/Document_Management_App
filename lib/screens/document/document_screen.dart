import 'package:document_management_app/screens/DocumentScanner/header_screen.dart';
import 'package:document_management_app/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _documents = [
    {
      'title': 'Employment_Contract.pdf',
      'category': 'Contracts',
      'date': 'Sep 10, 2026',
      'size': '2.4 MB',
      'icon': Icons.picture_as_pdf,
      'color': const Color(0xFFEF4444),
    },
    {
      'title': 'Apartment_Lease_Agreement.pdf',
      'category': 'Contracts',
      'date': 'Sep 08, 2026',
      'size': '1.8 MB',
      'icon': Icons.picture_as_pdf,
      'color': const Color(0xFFEF4444),
    },
    {
      'title': 'Medical_Insurance_Card.png',
      'category': 'ID & Cards',
      'date': 'Sep 05, 2026',
      'size': '4.1 MB',
      'icon': Icons.image,
      'color': const Color(0xFF3B82F6),
    },
    {
      'title': 'Grocery_Store_Receipt.pdf',
      'category': 'Receipts',
      'date': 'Aug 29, 2026',
      'size': '850 KB',
      'icon': Icons.receipt_long,
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Quarterly_Tax_Invoice.pdf',
      'category': 'Invoices',
      'date': 'Aug 25, 2026',
      'size': '3.2 MB',
      'icon': Icons.description,
      'color': const Color(0xFFF59E0B),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredDocs = _selectedCategory == 'All'
        ? _documents
        : _documents.where((d) => d['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const HeaderScreen(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Documents',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 14),

              // Categories Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Contracts', 'Invoices', 'Receipts', 'ID & Cards']
                      .map((cat) => _buildCategoryChip(cat))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Documents List
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Text(
                          'No documents in this category',
                          style: GoogleFonts.nunito(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return _buildDocumentTile(doc);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(selectedIndex: 1),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5046E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5046E5) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          category,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTile(Map<String, dynamic> doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (doc['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(doc['icon'] as IconData, color: doc['color'] as Color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['title'] as String,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${doc['date']} • ${doc['size']}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
