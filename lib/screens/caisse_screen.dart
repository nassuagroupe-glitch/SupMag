import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

const _keypadKeys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', ',', '0', '←'];

class CaisseScreen extends StatelessWidget {
  const CaisseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 20,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SectionKicker('Caissier · poste 03 · ${state.currentStore.name}'),
                  const ScreenTitle('Caisse'),
                ],
              ),
              AppSegmented<String>(
                value: state.caisseVariant,
                onChanged: state.setCaisseVariant,
                options: const [('grille', 'Variante A — grille tactile'), ('scan', 'Variante B — scan & clavier')],
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 860;
            final left = state.caisseVariant == 'grille' ? const _GrilleVariant() : const _ScanVariant();
            const right = _TicketPanel();
            if (narrow) {
              return Column(children: [left, const SizedBox(height: 24), right]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: left),
                const SizedBox(width: 34),
                SizedBox(width: 380, child: right),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _GrilleVariant extends StatefulWidget {
  const _GrilleVariant();
  @override
  State<_GrilleVariant> createState() => _GrilleVariantState();
}

class _GrilleVariantState extends State<_GrilleVariant> {
  String category = 'Tous';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final categories = ['Tous', ...{for (final p in state.products) p.category}];
    var items = state.matchingProducts();
    if (category != 'Tous') items = items.where((p) => p.category == category).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: state.setQuery,
                decoration: const InputDecoration(hintText: 'Rechercher ou scanner un code-barres…'),
              ),
            ),
            const SizedBox(width: 10),
            const StatusTag('Scanner USB connecté', variant: TagVariant.outline),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in categories)
              GestureDetector(
                onTap: () => setState(() => category = c),
                child: StatusTag(c, variant: c == category ? TagVariant.accent : TagVariant.neutral),
              ),
          ],
        ),
        const SizedBox(height: 14),
        // Wrap of fixed-width, content-height tiles — not a GridView — so a
        // tile can grow a little taller for a long name/price without a
        // fixed row height forcing an overflow.
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final p in items.take(16))
              SizedBox(
                width: 158,
                child: Material(
                  color: AppColors.neutral100,
                  borderRadius: AppRadius.md,
                  child: InkWell(
                    borderRadius: AppRadius.md,
                    onTap: () => state.addToCart(p.id),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 92),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(p.name, style: const TextStyle(fontSize: 14, height: 1.25), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text(fmtFcfa(p.priceSell), style: const TextStyle(fontFamily: 'Source Serif 4', fontWeight: FontWeight.w600, fontSize: 17)),
                                Text('/ ${p.unit}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ScanVariant extends StatelessWidget {
  const _ScanVariant();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final matches = state.matchingProducts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledField(
          label: 'Code-barres / réf. produit',
          child: TextField(
            onChanged: state.setQuery,
            onSubmitted: (_) => matches.isNotEmpty ? state.addToCart(matches.first.id) : null,
            style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 24),
            decoration: const InputDecoration(hintText: 'Douchette ou saisie manuelle — Entrée pour ajouter'),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SUGGESTIONS', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: AppColors.neutral600)),
                  const SizedBox(height: 8),
                  for (final p in matches.take(7))
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => state.addToCart(p.id),
                        borderRadius: AppRadius.md,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                          child: Row(
                            children: [
                              Expanded(child: Text(p.name)),
                              const SizedBox(width: 10),
                              Text(p.barcode, style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
                              const SizedBox(width: 14),
                              Text(fmtFcfa(p.priceSell), style: const TextStyle(fontFamily: 'Source Serif 4', fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      AppButton(label: 'Peser un vrac (balance)', variant: AppButtonVariant.secondary, onPressed: () => state.addToCart('att')),
                      AppButton(label: 'Annuler le ticket', variant: AppButtonVariant.ghost, onPressed: state.clearCart),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 232,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('QUANTITÉ', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: AppColors.neutral600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: AppRadius.md),
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
                          child: Text(state.keypad.isEmpty ? '1' : state.keypad, style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 26, fontWeight: FontWeight.w700)),
                        ),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.6,
                          children: [
                            for (final k in _keypadKeys)
                              Material(
                                color: AppColors.bg,
                                borderRadius: AppRadius.md,
                                child: InkWell(
                                  borderRadius: AppRadius.md,
                                  onTap: () => state.pressKey(k),
                                  child: Center(child: Text(k, style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 17))),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TicketPanel extends StatelessWidget {
  const _TicketPanel();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final credit = state.creditAccounts.where((c) => c.storeId == state.currentStoreId).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: AppRadius.md, boxShadow: AppShadows.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Ticket N° ${state.ticketPreviewNo}',
                  style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 20, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('${state.cart.length} lignes', style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: state.cart.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Ticket vide — ajoutez un produit pour commencer.', style: TextStyle(color: AppColors.neutral600, fontStyle: FontStyle.italic)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.cart.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => _CartLineTile(line: state.cart[i]),
                  ),
          ),
          const SizedBox(height: 10),
          _TotalsBlock(state: state),
          const SizedBox(height: 14),
          const Text('MODE DE PAIEMENT', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: AppColors.neutral600)),
          const SizedBox(height: 7),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 3.2,
            children: [
              for (final m in const ['Espèces', 'Orange Money', 'MTN MoMo', 'Wave', 'Ardoise client', 'Carte bancaire'])
                Material(
                  color: state.payMethod == m ? AppColors.accent200 : Colors.white,
                  borderRadius: AppRadius.md,
                  child: InkWell(
                    borderRadius: AppRadius.md,
                    onTap: () => state.setPayMethod(m),
                    child: Center(child: Text(m, style: TextStyle(fontSize: 13, color: state.payMethod == m ? AppColors.accent900 : AppColors.text))),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Encaisser ${fmtFcfa(state.cartTotalTtc)} FCFA',
            expand: true,
            onPressed: state.cart.isEmpty ? null : state.validateSale,
          ),
          if (state.receipt != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: AppRadius.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ticket N° ${state.receipt!.no} encaissé', style: const TextStyle(fontFamily: 'Source Serif 4', fontWeight: FontWeight.w600)),
                  Text('${fmtFcfa(state.receipt!.amount)} FCFA · ${state.receipt!.pay}', style: const TextStyle(color: AppColors.neutral700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    const StatusTag('Facture normalisée DGI', variant: TagVariant.accent),
                    StatusTag(state.offline ? 'En file — sera envoyé' : 'Transmis au siège', variant: TagVariant.neutral),
                  ]),
                ],
              ),
            ),
          ],
          if (credit != null) ...[
            const SizedBox(height: 12),
            Text(
              'Client fidélité : ${credit.customerName} — ardoise ${fmtFcfa(credit.balance)} FCFA (plafond ${fmtFcfa(credit.ceiling)})',
              style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final qtyLabel = line.product.vrac ? '${line.qty.toStringAsFixed(1).replaceAll('.', ',')} kg' : '× ${line.qty.round()}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.product.name),
                Text(
                  '${fmtFcfa(line.product.priceSell)} FCFA / ${line.product.unit} · ${line.product.tva > 0 ? 'TVA 18 %' : 'exonéré'}',
                  style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtFcfa(line.total), style: const TextStyle(fontFamily: 'Source Serif 4', fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              // Wrap (not Row) so this never overflows if the ticket panel
              // ends up narrower than the controls' natural width.
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                children: [
                  _MiniButton(icon: Icons.remove, onTap: () => state.bump(line.product.id, line.product.vrac ? -0.5 : -1)),
                  SizedBox(width: 40, child: Center(child: Text(qtyLabel, style: const TextStyle(fontSize: 13)))),
                  _MiniButton(icon: Icons.add, onTap: () => state.bump(line.product.id, line.product.vrac ? 0.5 : 1)),
                  IconButton(
                    onPressed: () => state.removeFromCart(line.product.id),
                    tooltip: 'Retirer',
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.accent2_700),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppRadius.md,
      child: InkWell(
        borderRadius: AppRadius.md,
        onTap: onTap,
        child: SizedBox(width: 26, height: 26, child: Icon(icon, size: 14)),
      ),
    );
  }
}

class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool muted = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: muted ? AppColors.neutral700 : AppColors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(value, style: TextStyle(fontSize: 13, color: muted ? AppColors.neutral700 : AppColors.text)),
            ],
          ),
        );
    return Column(
      children: [
        row('Total HT', '${fmtFcfa(state.cartTotalTtc - state.cartTva)} FCFA'),
        row('TVA 18 % (produits taxables)', '${fmtFcfa(state.cartTva)} FCFA'),
        row("Produits exonérés (1ère nécessité)", '${fmtFcfa(state.cartExonere)} FCFA', muted: true),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Net à payer', style: TextStyle(fontFamily: 'Source Serif 4', fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text('${fmtFcfa(state.cartTotalTtc)} FCFA', style: const TextStyle(fontFamily: 'Source Serif 4', fontSize: 30, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
