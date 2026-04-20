import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../models/item_model.dart';

import 'edit_item_page.dart';

class InventoryAdminPage extends StatefulWidget {
  const InventoryAdminPage({super.key});

  @override
  State<InventoryAdminPage> createState() => _InventoryAdminPageState();
}

class _InventoryAdminPageState extends State<InventoryAdminPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // State filter
  String _selectedAsal = 'Semua';
  String _selectedKategori = 'Semua';
  String _selectedTahun = 'Semua Tahun';
  String _selectedSatuan = 'Semua Satuan';

  // State Pengurutan (Sorting)
  String _selectedSort = 'Terbaru';

  // State Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inventory = context.read<InventoryProvider>();
      if (inventory.items.isEmpty) {
        inventory.fetchItems();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilter(VoidCallback updateState) {
    setState(() {
      updateState();
      _currentPage = 1;
    });
  }

  String _cekKategoriBarang(String namaBarang) {
    final name = namaBarang.toLowerCase();

    final listPerlengkapan = [
      'kertas',
      'buku',
      'karton',
      'mika',
      'origami',
      'pulpen',
      'pensil',
      'spidol',
      'map',
      'amplop',
      'label',
      'tinta',
      'stamp pad',
      'isi staples',
      'isi lem',
      'lakban',
      'selotip',
      'double tape',
      'tali',
      'push pin',
      'kantong',
      'kue',
      'kopi',
      'teh',
      'sendok',
      'sedotan',
      'tutup',
      'tusuk',
      'obat',
      'promag',
      'kasa',
      'tape',
      'oxycan',
      'masker',
      'moisturizer',
      'pengharum',
      'lap',
      'kuas',
      't-shirt',
      'crocs',
      'nametag',
      'spanduk',
      'balon',
      'pita',
      'bola',
      'shuttlecock',
      'kartu',
      'baterai',
      'lampu',
      'cover',
    ];
    for (var p in listPerlengkapan) {
      if (name.contains(p)) return 'Perlengkapan';
    }

    final listPeralatan = [
      'printer',
      'kabel',
      'converter',
      'ht',
      'toa',
      'kipas',
      'kompor',
      'tensi',
      'fingertip',
      'staples',
      'lem tembak',
      'gunting',
      'cutter',
      'penggaris',
      'stempel',
      'dispenser',
      'galon',
      'termos',
      'wajan',
      'baki',
      'botol',
      'piring',
      'jam',
      'tempat sampah',
      'stopkontak',
      'kotak',
      'pipa',
      'helm',
      'drum',
      'figura',
      'xbanner',
      'sapu',
      'sekop',
      'serokan',
      'scoreboard',
      'jaring',
      'catur',
      'bendera',
    ];
    for (var p in listPeralatan) {
      if (name.contains(p)) return 'Peralatan';
    }

    return 'Peralatan';
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();

    // 1. Filtering Data
    List<ItemModel> filtered = inventory.items.where((item) {
      final matchSearch =
          _searchQuery.isEmpty ||
          item.namaBarang.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.kodeBarang.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchAsal =
          _selectedAsal == 'Semua' ||
          item.asalBarang.toLowerCase() == _selectedAsal.toLowerCase();

      final matchSatuan =
          _selectedSatuan == 'Semua Satuan' ||
          item.satuan.toLowerCase() == _selectedSatuan.toLowerCase();

      final matchKategori =
          _selectedKategori == 'Semua' ||
          _cekKategoriBarang(item.namaBarang) == _selectedKategori;

      return matchSearch && matchAsal && matchSatuan && matchKategori;
    }).toList();

    // Sorting Data (Terbaru / Terlama)
    filtered.sort((a, b) {
      DateTime dateA = a.tanggalPembukuan ?? DateTime.now();
      DateTime dateB = b.tanggalPembukuan ?? DateTime.now();

      if (_selectedSort == 'Terbaru') {
        return dateB.compareTo(dateA); // Descending
      } else {
        return dateA.compareTo(dateB); // Ascending
      }
    });

    // 2. Kalkulasi Pagination
    final int totalPages = (filtered.length / _itemsPerPage).ceil();
    int displayPage = (_currentPage > totalPages && totalPages > 0)
        ? 1
        : _currentPage;

    // 3. Potong Data (Maksimal 5 item)
    final paginatedItems = filtered.isEmpty
        ? <ItemModel>[]
        : filtered
              .skip((displayPage - 1) * _itemsPerPage)
              .take(_itemsPerPage)
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 16),

              // =======================================================
              // FITUR BARU: Dropdown / Accordion Filter Berdasarkan
              // =======================================================
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    leading: const Icon(
                      Icons.filter_list,
                      size: 22,
                      color: Colors.black87,
                    ),
                    title: const Text(
                      'Filter Berdasarkan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 20,
                    ),
                    children: [
                      FilterRowWidget(
                        label: 'ASAL:',
                        options: const ['Semua', 'Beli', 'Hibah'],
                        selectedValue: _selectedAsal,
                        onSelect: (val) =>
                            _updateFilter(() => _selectedAsal = val),
                      ),
                      FilterRowWidget(
                        label: 'KATEGORI:',
                        options: const ['Semua', 'Perlengkapan', 'Peralatan'],
                        selectedValue: _selectedKategori,
                        onSelect: (val) =>
                            _updateFilter(() => _selectedKategori = val),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomDropdown(
                              label: 'TAHUN PENGADAAN',
                              value: _selectedTahun,
                              items: const [
                                'Semua Tahun',
                                '2024',
                                '2023',
                                '2022',
                              ],
                              onChanged: (val) =>
                                  _updateFilter(() => _selectedTahun = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomDropdown(
                              label: 'NAMA SATUAN',
                              value: _selectedSatuan,
                              items: const [
                                'Semua Satuan',
                                'Pcs',
                                'Unit',
                                'Set',
                              ],
                              onChanged: (val) =>
                                  _updateFilter(() => _selectedSatuan = val!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Header List (Dilengkapi Dropdown Sorting)
              _buildHeaderJudul(),
              const SizedBox(height: 20),

              // Pagination
              AdminPagination(
                totalPages: totalPages,
                currentPage: displayPage,
                onPageChanged: (page) => setState(() => _currentPage = page),
              ),
              const SizedBox(height: 24),

              // List Aset
              _buildListAset(
                inventory.isLoading,
                inventory.items.isEmpty,
                paginatedItems,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // --- KOMPONEN KECIL ---

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => _updateFilter(() => _searchQuery = val),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey, size: 22),
          hintText: 'Cari barang berdasarkan nama atau kode SKU...',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildHeaderJudul() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Inventaris\nGudang',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F2859),
            height: 1.1,
          ),
        ),

        // Tombol Dropdown Urutkan
        PopupMenuButton<String>(
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (String value) {
            setState(() {
              _selectedSort = value;
              _currentPage = 1; // Reset ke halaman 1 jika urutan diubah
            });
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'Terbaru',
              child: Text(
                'Terbaru',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const PopupMenuItem(
              value: 'Terlama',
              child: Text(
                'Terlama',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          child: Row(
            children: [
              const Icon(Icons.sort, size: 18, color: Color(0xFF0F2859)),
              const SizedBox(width: 8),
              Text(
                'Urutkan:\n$_selectedSort',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2859),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListAset(
    bool isLoading,
    bool hasNoCachedData,
    List<ItemModel> items,
  ) {
    if (isLoading && hasNoCachedData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 60,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                'Tidak ada barang ditemukan',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => AdminAssetCard(item: items[index]),
    );
  }
}

// =========================================================================
// WIDGET-WIDGET YANG DI-EXTRACT (Filter, Dropdown, Pagination, Card)
// =========================================================================

class FilterRowWidget extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelect;

  const FilterRowWidget({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((opt) {
                final isSelected = selectedValue == opt;
                return Material(
                  color: isSelected ? const Color(0xFF0F2859) : Colors.white,
                  elevation: isSelected ? 6.0 : 2.0,
                  shadowColor: isSelected
                      ? const Color(0xFF0F2859).withValues(alpha: 0.5)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => onSelect(opt),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.grey,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class AdminPagination extends StatelessWidget {
  final int totalPages;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const AdminPagination({
    super.key,
    required this.totalPages,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages == 0) return const SizedBox();

    int startPage = currentPage > 2 ? currentPage - 1 : 1;
    int endPage = startPage + 3;
    if (endPage > totalPages) {
      endPage = totalPages;
      startPage = endPage - 3 > 0 ? endPage - 3 : 1;
    }

    final paginationItems = [
      {'label': 'First', 'icon': Icons.arrow_back},
      for (int i = startPage; i <= endPage; i++) {'label': i.toString()},
      {'label': 'Last', 'icon': Icons.arrow_forward},
    ];

    return Material(
      color: Colors.white,
      elevation: 4.0,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: paginationItems.asMap().entries.map((entry) {
            final isLast = entry.key == paginationItems.length - 1;
            final item = entry.value;
            final isSelected = item['label'] == currentPage.toString();

            return Expanded(
              child: Material(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (item['label'] == 'First') {
                      onPageChanged(1);
                    } else if (item['label'] == 'Last') {
                      onPageChanged(totalPages);
                    } else {
                      onPageChanged(int.parse(item['label'].toString()));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        right: isLast
                            ? BorderSide.none
                            : BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: item.containsKey('icon')
                        ? Column(
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['label'].toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                              item['label'].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0F2859),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// === DESAIN CARD 100% SESUAI FIGMA ===

class AdminAssetCard extends StatelessWidget {
  final ItemModel item;

  const AdminAssetCard({super.key, required this.item});

  Widget _buildThumbnail() {
    final photoUrl = item.fotoUrl;

    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: Colors.grey,
          size: 28,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        photoUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            color: const Color(0xFFE2E8F0),
            child: const Center(
              child: Icon(
                Icons.inventory_2_outlined,
                color: Colors.grey,
                size: 28,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFFE2E8F0),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = item.kondisiBarang.toLowerCase() == 'baik';
    final Color statusBgColor = isAvailable
        ? const Color(0xFF9FF7A3)
        : const Color(0xFFFCA5A5);
    final Color statusTextColor = isAvailable
        ? const Color(0xFF1B5E20)
        : const Color(0xFFB71C1C);

    String formattedPrice = '-';
    if (item.hargaBarang != null) {
      formattedPrice =
          'Rp ${NumberFormat('#,###', 'id_ID').format(item.hargaBarang)}';
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Icon Box Kiri
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildThumbnail(),
          ),
          const SizedBox(width: 16),

          // 2. Konten Kanan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Atas: Judul, SKU & Tombol Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.namaBarang,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${item.kodeBarang}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tombol Edit & Delete
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (!context.mounted) return;
                            try {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditItemPage(item: item),
                                ),
                              ).catchError((e) {
                                debugPrint('Edit item navigation error: $e');
                              });
                            } catch (e) {
                              debugPrint('Error navigating to edit: $e');
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Barang'),
                                content: Text(
                                  'Yakin ingin menghapus "${item.namaBarang}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              final success = await context
                                  .read<InventoryProvider>()
                                  .deleteItem(item.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Barang berhasil dihapus'
                                          : 'Gagal menghapus barang',
                                    ),
                                    backgroundColor: success
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Baris Grid 1 (JUMLAH & ASAL)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'JUMLAH',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${item.volume} ',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: item.satuan,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ASAL',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.asalBarang,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Baris Grid 2 (NILAI & STATUS)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NILAI',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedPrice,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STATUS',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.kondisiBarang.toUpperCase(),
                              style: TextStyle(
                                color: statusTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
