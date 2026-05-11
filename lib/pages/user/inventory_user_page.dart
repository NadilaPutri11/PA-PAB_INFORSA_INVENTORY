import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/item_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/inforsa_header.dart';
import 'forms/peminjaman_page.dart';

class InventoryUserPage extends StatefulWidget {
  const InventoryUserPage({super.key});

  @override
  State<InventoryUserPage> createState() => _InventoryUserPageState();
}

class _InventoryUserPageState extends State<InventoryUserPage> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> _listPerlengkapan = [
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

  final List<String> _listPeralatan = [
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

  String _selectedStatus = 'Semua';

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

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();

    List<ItemModel> filtered = inventory.items.where((item) {
      final matchSearch =
          _searchQuery.isEmpty ||
          item.namaBarang.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.kodeBarang.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchCategory = true;
      if (_selectedCategory == 'Perlengkapan') {
        matchCategory = _listPerlengkapan.any(
          (p) => item.namaBarang.toLowerCase().contains(p.toLowerCase()),
        );
      } else if (_selectedCategory == 'Peralatan') {
        matchCategory = _listPeralatan.any(
          (p) => item.namaBarang.toLowerCase().contains(p.toLowerCase()),
        );
      }

      bool matchStatus = true;
      final isAvailable = item.kondisiBarang == 'Baik' && item.volume > 0;
      if (_selectedStatus == 'Tersedia') {
        matchStatus = isAvailable;
      } else if (_selectedStatus == 'Tidak Tersedia') {
        matchStatus = !isAvailable;
      }

      return matchSearch && matchCategory && matchStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const InforsaHeader(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Katalog Aset',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Temukan dan pinjam perlengkapan yang\nAnda butuhkan untuk produktivitas kerja.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBECEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey, size: 20),
                    hintText: 'Cari nama aset, brand, atau SKU...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Filter
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _showFilterSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_list, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Filter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // List Aset
              inventory.isLoading && inventory.items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : filtered.isEmpty
                  ? Center(
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
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        return _buildAssetCard(context, filtered[index]);
                      },
                    ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    String tempCategory = _selectedCategory;
    String tempStatus = _selectedStatus;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Barang',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'KATEGORI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ['Semua', 'Perlengkapan', 'Peralatan'].map((cat) {
                    final isSelected = tempCategory == cat;
                    return _buildFilterChip(
                      label: cat,
                      isSelected: isSelected,
                      onTap: () {
                        setSheetState(() => tempCategory = cat);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ['Semua', 'Tersedia', 'Tidak Tersedia'].map((s) {
                    final isSelected = tempStatus == s;
                    return _buildFilterChip(
                      label: s,
                      isSelected: isSelected,
                      onTap: () {
                        setSheetState(() => tempStatus = s);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              tempCategory = 'Semua';
                              tempStatus = 'Semua';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = tempCategory;
                              _selectedStatus = tempStatus;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Terapkan Filter',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? Colors.black : Colors.white,
      elevation: isSelected ? 8.0 : 2.0,
      shadowColor: isSelected ? Colors.black45 : Colors.grey[300],
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? null : Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context, ItemModel item) {
    final isAvailable = item.kondisiBarang == 'Baik' && item.volume > 0;
    final categoryLabel =
        '${item.asalBarang.toUpperCase()} • ${item.kodeBarang}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: _buildAssetImage(item),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? const Color(0xFF1B4D3E).withValues(alpha: 0.85)
                        : const Color(0xFF4A3424).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAvailable ? 'TERSEDIA' : 'TIDAK TERSEDIA',
                    style: TextStyle(
                      color: isAvailable
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFFBBF24),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.namaBarang,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stok: ${item.volume} ${item.satuan}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    isAvailable
                        ? InkWell(
                            onTap: () async {
                              final submitted = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PeminjamanPage(
                                    item: item,
                                  ), 
                                ),
                              );

                              if (!context.mounted) return;

                              if (submitted == true) {
                                await context.read<InventoryProvider>().fetchItems();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Permohonan peminjaman berhasil dikirim'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    'Pinjam Aset',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBECEF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Tidak Tersedia',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
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

  String? _resolveFotoUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final value = rawUrl.trim();

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final normalizedPath = value.startsWith('barang/') ? value : 'barang/$value';
    return SupabaseService.storage.from('foto_barang').getPublicUrl(normalizedPath);
  }

  Widget _buildAssetImage(ItemModel item) {
    final resolvedUrl = _resolveFotoUrl(item.fotoUrl);

    if (resolvedUrl == null) {
      return Container(
        height: 180,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(
          Icons.inventory_2_outlined,
          size: 60,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      resolvedUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          height: 180,
          width: double.infinity,
          color: Colors.grey[200],
          child: const Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}
