import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../services/api_service.dart';
import '../widgets/signature_pad.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final int deliveryId;

  const DeliveryDetailScreen({super.key, required this.deliveryId});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  Map<String, dynamic>? _detail;
  List<Map<String, dynamic>> _posList = [];
  bool _loading = true;
  bool _submitting = false;
  final _receiverCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _status = 'delivered';
  int? _selectedPosId;
  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 2.5,
      exportBackgroundColor: Colors.white,
    );
    _load();
  }

  @override
  void dispose() {
    _receiverCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final detailResp = await ApiService.instance.getDeliveryDetail(widget.deliveryId);
      final posResp = await ApiService.instance.getPosList();
      final delivery = Map<String, dynamic>.from(detailResp['delivery'] ?? {});
      _detail = delivery;
      final amount = (delivery['amount_to_collect'] ?? 0).toDouble();
      _amountCtrl.text = amount.toStringAsFixed(2);
      _posList = posResp;
      if (_posList.isNotEmpty) {
        _selectedPosId = _posList.first['id'] as int;
      }
    } catch (_) {
      _detail = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    try {
      await ApiService.instance.startDelivery(widget.deliveryId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mission démarrée.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _submitProof() async {
    if (_receiverCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom du réceptionnaire requis.')));
      return;
    }
    if (_selectedPosId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisis le point d’encaissement.')));
      return;
    }
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La signature est obligatoire.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final Uint8List? raw = await _signatureController.toPngBytes();
      if (raw == null) throw Exception('Signature vide');
      final signatureBase64 = base64Encode(raw);
      await ApiService.instance.submitProof(
        deliveryId: widget.deliveryId,
        receiverName: _receiverCtrl.text.trim(),
        receiverPhone: _phoneCtrl.text.trim(),
        signatureBase64: signatureBase64,
        status: _status,
        amountCollected: double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0,
        targetPosConfigId: _selectedPosId!,
        note: _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preuve envoyée avec succès.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail mission')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? const Center(child: Text('Mission introuvable.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_detail!['sale_order'] ?? '') as String,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            _infoTile('Client', (_detail!['customer'] ?? '') as String),
                            _infoTile('Adresse', (_detail!['address'] ?? '') as String),
                            _infoTile('Téléphone', (_detail!['phone'] ?? '') as String),
                            _infoTile('État', (_detail!['state'] ?? '') as String),
                            _infoTile(
                              'Montant',
                              '${((_detail!['amount_to_collect'] ?? 0).toDouble()).toStringAsFixed(2)} ${(_detail!['currency'] ?? '') as String}',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed: _submitting ? null : _start,
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Départ'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Validation livraison', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _receiverCtrl,
                              decoration: const InputDecoration(labelText: 'Nom du réceptionnaire'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Téléphone du réceptionnaire'),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _status,
                              items: const [
                                DropdownMenuItem(value: 'delivered', child: Text('Livrée')),
                                DropdownMenuItem(value: 'partial', child: Text('Partielle')),
                                DropdownMenuItem(value: 'failed', child: Text('Échec')),
                              ],
                              onChanged: (value) => setState(() => _status = value ?? 'delivered'),
                              decoration: const InputDecoration(labelText: 'Résultat'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Montant encaissé'),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              value: _selectedPosId,
                              items: _posList
                                  .map(
                                    (e) => DropdownMenuItem<int>(
                                      value: e['id'] as int,
                                      child: Text((e['name'] ?? '') as String),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedPosId = value),
                              decoration: const InputDecoration(labelText: 'Point d’encaissement'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _noteCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(labelText: 'Note'),
                            ),
                            const SizedBox(height: 16),
                            const Text('Signature du client'),
                            const SizedBox(height: 8),
                            SignaturePad(controller: _signatureController),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _submitting ? null : _submitProof,
                              icon: const Icon(Icons.check_circle),
                              label: _submitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Envoyer la preuve'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
