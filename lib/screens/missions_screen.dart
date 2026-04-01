import 'package:flutter/material.dart';

import '../models/delivery.dart';
import '../services/api_service.dart';
import 'delivery_detail_screen.dart';
import 'login_screen.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  late Future<List<Delivery>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.getDeliveries();
  }

  Future<void> _reload() async {
    setState(() {
      _future = ApiService.instance.getDeliveries();
    });
    await _future;
  }

  Future<void> _logout() async {
    await ApiService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String _stateLabel(String state) {
    switch (state) {
      case 'assigned':
        return 'Assignée';
      case 'in_transit':
        return 'En route';
      case 'partial':
        return 'Partielle';
      case 'delivered':
        return 'Livrée';
      case 'failed':
        return 'Échec';
      case 'returned':
        return 'Retournée';
      case 'cancelled':
        return 'Annulée';
      default:
        return state;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes missions'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: FutureBuilder<List<Delivery>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Aucune mission trouvée.')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    title: Text('${item.saleOrder} • ${item.customer}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(item.address),
                        const SizedBox(height: 4),
                        Text('POS: ${item.targetPos}'),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${item.amountToCollect.toStringAsFixed(2)} ${item.currency}'),
                        const SizedBox(height: 4),
                        Text(_stateLabel(item.state)),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DeliveryDetailScreen(deliveryId: item.id),
                        ),
                      );
                      await _reload();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
