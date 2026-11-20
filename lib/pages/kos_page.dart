import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/kos_service.dart';

class KosPage extends StatefulWidget {
  const KosPage({super.key});

  @override
  State<KosPage> createState() => _KosPageState();
}

class _KosPageState extends State<KosPage> {
  late Future<List<Map<String, dynamic>>> _kosFuture;
  final _kosService = KosService();

  @override
  void initState() {
    super.initState();
    _kosFuture = _kosService.fetchAll();
  }

  Future<void> _refresh() async {
    setState(() => _kosFuture = _kosService.fetchAll());
  }

  Future<void> _showAddDialog() async {
    final nameC = TextEditingController();
    final addressC = TextEditingController();
    final priceC = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Nama kos'),
            ),
            TextField(
              controller: addressC,
              decoration: const InputDecoration(labelText: 'Alamat'),
            ),
            TextField(
              controller: priceC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga per bulan'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final price = int.tryParse(priceC.text.trim());
    if (nameC.text.trim().isEmpty ||
        addressC.text.trim().isEmpty ||
        price == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data kos belum lengkap')));
      }
      return;
    }

    try {
      await _kosService.add(
        name: nameC.text.trim(),
        address: addressC.text.trim(),
        price: price,
      );
      await _refresh();
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: ${e.message}')));
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> kos) async {
    final deleted = await _kosService.delete(kos['id'].toString());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Kos berhasil dihapus' : 'Akses ditolak oleh RLS',
        ),
      ),
    );
    if (deleted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Kos')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _kosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Gagal memuat kos: ${snapshot.error}'));
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(child: Text('Belum ada kos'));
            }
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final kos = items[index];
                final isMine = kos['owner_id'] == myId;
                return ListTile(
                  leading: const Icon(Icons.home_work_outlined),
                  title: Text(kos['name'] ?? '-'),
                  subtitle: Text(
                    '${kos['address'] ?? '-'} • Rp ${kos['price'] ?? 0}',
                  ),
                  trailing: isMine
                      ? IconButton(
                          tooltip: 'Hapus kos',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(kos),
                        )
                      : null,
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kos'),
      ),
    );
  }
}
