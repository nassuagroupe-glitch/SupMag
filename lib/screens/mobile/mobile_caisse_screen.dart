import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';

/// Phone-shaped till: same cart/keypad logic as the desktop Caisse screen,
/// laid out single-column for a handheld terminal.
class MobileCaisseScreen extends StatelessWidget {
  const MobileCaisseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final matches = state.matchingProducts();
    final queued = state.recentTickets.where((t) => !t.synced && t.storeId == state.currentStoreId).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Caisse mobile', style: Theme.of(context).textTheme.headlineMedium),
              Row(
                children: [
                  StatusTag(state.currentStore.name.split(' ').first, variant: TagVariant.outline),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: state.offline ? 'Repasser en ligne' : 'Passer hors ligne',
                    icon: Icon(state.offline ? Icons.cloud_off : Icons.cloud_done, size: 20, color: state.offline ? AppColors.accent2_700 : AppColors.accent700),
                    onPressed: state.toggleOffline,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              TextField(
                onChanged: state.setQuery,
                onSubmitted: (_) => matches.isNotEmpty ? state.addToCart(matches.first.id) : null,
                decoration: const InputDecoration(hintText: 'Scanner un article', prefixIcon: Icon(Icons.qr_code_scanner)),
              ),
              const SizedBox(height: 10),
              if (state.query.isNotEmpty)
                Column(
                  children: [
                    for (final p in matches.take(4))
                      ListTile(
                        dense: true,
                        title: Text(p.name),
                        trailing: Text(fmtFcfa(p.priceSell)),
                        onTap: () => state.addToCart(p.id),
                      ),
                  ],
                ),
              const SizedBox(height: 6),
              if (state.cart.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Text('Ticket vide.', style: TextStyle(color: AppColors.neutral600)))
              else
                for (final l in state.cart)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text('${l.product.name} ×${l.qty.round()}')),
                        Text(fmtFcfa(l.total)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadows.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Net à payer', style: TextStyle(fontFamily: 'Source Serif 4', fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text('${fmtFcfa(state.cartTotalTtc)} FCFA', style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 26, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7,
                  childAspectRatio: 2.6,
                  children: [
                    for (final m in const ['Espèces', 'Orange Money', 'Wave', 'Ardoise'])
                      OutlinedButton(
                        onPressed: () => state.setPayMethod(m == 'Ardoise' ? 'Ardoise client' : m),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: state.payMethod == m || (m == 'Ardoise' && state.payMethod == 'Ardoise client') ? AppColors.accent200 : null,
                        ),
                        child: Text(m),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AppButton(label: 'Encaisser', expand: true, onPressed: state.cart.isEmpty ? null : state.validateSale),
                if (queued > 0) ...[
                  const SizedBox(height: 6),
                  Text('$queued tickets en file d\'attente · envoi dès le retour du réseau', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
