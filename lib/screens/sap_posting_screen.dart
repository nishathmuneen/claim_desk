import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/card_refill_request.dart';
import '../models/expense_claim.dart';
import '../providers/claim_desk_provider.dart';

class SapPostingScreen extends StatelessWidget {
  const SapPostingScreen({super.key});

  void _showSapPostingModal(
    BuildContext context,
    ClaimDeskProvider provider,
    ExpenseClaim claim,
  ) {
    String paymentStatus = 'Paid';
    final paymentNoCtrl = TextEditingController(text: 'PAY-2026-${DateTime.now().millisecond % 900 + 100}');
    final sapRefCtrl = TextEditingController(text: 'SAP-1900${DateTime.now().millisecond % 900 + 100}');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: AppTheme.primaryOrange, size: 22),
            SizedBox(width: 8),
            Text('Post SAP & Payment (BRD 5.6)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${claim.docRefNumber} • SAR ${claim.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentStatus,
                  decoration: const InputDecoration(labelText: 'Payment Status'),
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                    DropdownMenuItem(value: 'Cleared', child: Text('Cleared')),
                  ],
                  onChanged: (val) {
                    if (val != null) paymentStatus = val;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: paymentNoCtrl,
                  decoration: const InputDecoration(labelText: 'Payment Number'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: sapRefCtrl,
                  decoration: const InputDecoration(labelText: 'SAP Document Reference Number'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Note: Posting marks this document as Fully Closed. No further edits will be allowed.',
                  style: TextStyle(fontSize: 11, color: AppTheme.dangerRed, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              provider.postSapPaymentDetails(
                claimId: claim.id,
                paymentStatus: paymentStatus,
                paymentNumber: paymentNoCtrl.text,
                sapDocRefNumber: sapRefCtrl.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.navyDark,
                  content: Text('${claim.docRefNumber} posted (${sapRefCtrl.text.trim()}) & marked Fully Closed.'),
                ),
              );
            },
            child: const Text('Post & Close Claim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final readyForSap = provider.approvedPendingSapClaims;
    final closed = provider.fullyClosedClaims;
    final refills = provider.refillRequests;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AppTheme.navyDark,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryOrange,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              tabs: [
                Tab(text: 'SAP & Payment Posting'),
                Tab(text: 'Card Refill Queue'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSapTab(context, provider, readyForSap, closed),
                _buildRefillsTab(context, provider, refills),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSapTab(
    BuildContext context,
    ClaimDeskProvider provider,
    List<ExpenseClaim> readyForSap,
    List<ExpenseClaim> closed,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'READY FOR SAP POSTING',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          if (readyForSap.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No approved claims currently awaiting SAP reference posting.'),
              ),
            )
          else
            ...readyForSap.map(
              (c) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('${c.docRefNumber} • ${c.employeeName}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${c.description}\nTotal: SAR ${c.grandTotal.toStringAsFixed(2)}'),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () => _showSapPostingModal(context, provider, c),
                    child: const Text('Post SAP', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'FULLY CLOSED (LOCKED)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),
          ...closed.map(
            (c) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.lock_outline_rounded, color: AppTheme.closedPurple),
                title: Text('${c.docRefNumber} • ${c.sapDocRefNumber ?? ""}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: Text('Payment: ${c.paymentStatus ?? "-"} (${c.paymentNumber ?? "-"})'),
                trailing: Text(
                  'SAR ${c.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefillsTab(
    BuildContext context,
    ClaimDeskProvider provider,
    List<CardRefillRequest> refills,
  ) {
    if (refills.isEmpty) {
      return const Center(child: Text('No card refill requests in queue.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: refills.length,
      itemBuilder: (ctx, i) {
        final r = refills[i];
        final isLoaded = r.status == RefillStatus.fundsLoaded;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${r.refillId} • ${r.custodianName}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLoaded ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isLoaded ? 'Funds Loaded' : 'Pending AP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isLoaded ? const Color(0xFF059669) : AppTheme.goldDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Requested: SAR ${r.requestedAmount.toStringAsFixed(2)} • ${DateFormat('dd MMM yyyy').format(r.requestDate)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryOrange),
                ),
                const SizedBox(height: 4),
                Text(r.businessJustification, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                if (!isLoaded) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                      icon: const Icon(Icons.bolt_rounded, size: 17),
                      label: const Text('Approve & Load Funds to Card'),
                      onPressed: () {
                        provider.approveAndDisburseRefill(r.refillId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.navyDark,
                            content: Text('SAR ${r.requestedAmount.toStringAsFixed(0)} loaded to ${r.custodianName}\'s card!'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

