import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/card_statement.dart';
import '../models/expense_claim.dart';
import '../providers/claim_desk_provider.dart';
import '../widgets/kinetic_background.dart';
import 'new_claim_screen.dart';

class ReconciliationScreen extends StatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends State<ReconciliationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _importSampleStatement(BuildContext context, ClaimDeskProvider provider) {
    final now = DateTime.now();
    final batchId = now.millisecondsSinceEpoch % 10000;
    final cardNum = provider.activeCard.cardNumber;
    final empId = provider.activeUser.employeeId;

    final sampleRows = [
      CardStatementTransaction(
        id: 'STX-$batchId-1',
        cardNumber: cardNum,
        companyCode: 'COMP-1000',
        date: now.subtract(const Duration(days: 1)),
        merchantOrAtm: 'Naft Fuel Station #118',
        description: 'POS Swipe — Diesel & Fleet Fuel',
        amount: 420.00,
        type: StatementTxType.posSwipe,
        employeeId: empId,
        isSubmitted: false,
      ),
      CardStatementTransaction(
        id: 'STX-$batchId-2',
        cardNumber: cardNum,
        companyCode: 'COMP-1000',
        date: now,
        merchantOrAtm: 'SNB ATM - Jubail Industrial',
        description: 'ATM Cash Withdrawal (Auto Cash Advance)',
        amount: 500.00,
        type: StatementTxType.atmWithdrawal,
        employeeId: empId,
        isSubmitted: true,
      ),
    ];

    final count = provider.importCardStatement(sampleRows);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.navyDark,
        content: Text(
          'Imported $count statement rows: +1 POS swipe (Not Submitted) & +SAR 500 ATM Cash Advance!',
        ),
      ),
    );
  }

  void _showAddSubCustodianModal(BuildContext context, ClaimDeskProvider provider) {
    final nameCtrl = TextEditingController();
    final empIdCtrl = TextEditingController();
    final ccCtrl = TextEditingController(text: provider.activeUser.costCenter);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Employee Under Card',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Employee Full Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: empIdCtrl,
              decoration: const InputDecoration(labelText: 'Employee ID (e.g. EMP-9104)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ccCtrl,
              decoration: const InputDecoration(labelText: 'Cost Center'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || empIdCtrl.text.trim().isEmpty) {
                return;
              }
              provider.addSubCustodian(
                name: nameCtrl.text,
                employeeId: empIdCtrl.text,
                costCenter: ccCtrl.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.navyDark,
                  content: Text('Linked ${nameCtrl.text.trim()} under card for advance tracking.'),
                ),
              );
            },
            child: const Text('Add Employee'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimDeskProvider>();
    final card = provider.activeCard;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Card & Cash Reconciliation'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text(
                'Import Statement',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _importSampleStatement(context, provider),
            ),
          ),
        ],
      ),
      body: KineticBackground(
        child: Column(
          children: [
            // Card Identity Header Strip (BRD Screenshot Top Info)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  _metaChip('Name', card.cardholderName),
                  _metaChip('Card Number', card.maskedCardNumber),
                  _metaChip(
                    'Expiry',
                    DateFormat('yyyy-MM').format(card.endDate),
                  ),
                ],
              ),
            ),

            // 5 Sub-Tabs matching BRD Screenshot
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppTheme.royalBlue,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.royalBlue,
                labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Card Detail Statement'),
                  Tab(text: 'Expense List'),
                  Tab(text: 'Deposit List'),
                  Tab(text: 'Summary List'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(provider),
                  _buildStatementTab(context, provider),
                  _buildExpenseListTab(provider),
                  _buildDepositListTab(provider),
                  _buildSummaryTab(context, provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ClaimDeskProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Text(
                'Card and Cash Balance Statement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3730A3),
                ),
              ),
            ),
            _ledgerRow('Initial Deposit', provider.initialDepositAmount),
            _ledgerRow('Enhancement/Diminution Deposit (+/-)', provider.enhancementDepositAmount),
            _sectionRow('A)', 'Bill Submitted and Approved', provider.approvedTotal),
            _subRow('Swipe expense submitted and approved', provider.approvedSwipeTotal),
            _subRow('Cash expense submitted and approved', provider.approvedCashTotal),
            _sectionRow('B)', 'Bill Submitted and in Approval', provider.inApprovalTotal),
            _subRow('Swipe Bills submitted and In Approval', provider.inApprovalSwipeTotal),
            _subRow('Cash Bills submitted and In Approval', provider.inApprovalCashTotal),
            _sectionRow('C)', 'Expenses Incurred and Not Submitted', provider.notSubmittedTotal),
            _subRow('Swipe Bills Not Submitted', provider.notSubmittedSwipeTotal),
            _subRow('Cash Bills Not Submitted', provider.notSubmittedCashTotal),
            _sectionRow('D)', 'Employee Advance', provider.employeeAdvanceTotal),
            _sectionRow('E)', 'Employee Reimbursement', provider.employeeReimbursementTotal),
            _sectionRow('F)', 'Employee Cash In Hand', provider.employeeCashInHandTotal),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Balance in Card',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  Text(
                    'SAR ${provider.reconciledCardBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ledgerRow(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)))),
          Text(
            amount.toStringAsFixed(2),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _sectionRow(String code, String title, double amount) {
    return Container(
      color: const Color(0xFFE5E7EB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                decoration: TextDecoration.underline,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Text(
            amount.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _subRow(String label, double amount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(44, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
          Text(
            amount.toStringAsFixed(2),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementTab(BuildContext context, ClaimDeskProvider provider) {
    final txs = provider.statementTransactions;
    if (txs.isEmpty) {
      return const Center(child: Text('No card statement transactions imported yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: txs.length,
      itemBuilder: (ctx, i) {
        final tx = txs[i];
        final isSwipe = tx.type == StatementTxType.posSwipe || tx.type == StatementTxType.online;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: tx.type == StatementTxType.atmWithdrawal
                  ? const Color(0xFFDBEAFE)
                  : tx.type == StatementTxType.deposit
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFF7ED),
              child: Icon(
                tx.type == StatementTxType.atmWithdrawal
                    ? Icons.local_atm_rounded
                    : tx.type == StatementTxType.deposit
                        ? Icons.account_balance_wallet_rounded
                        : Icons.credit_card_rounded,
                size: 18,
                color: tx.type == StatementTxType.atmWithdrawal
                    ? const Color(0xFF2563EB)
                    : tx.type == StatementTxType.deposit
                        ? const Color(0xFF059669)
                        : AppTheme.primaryOrange,
              ),
            ),
            title: Text(tx.merchantOrAtm, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            subtitle: Text(
              '${DateFormat('dd MMM yyyy').format(tx.date)} • ${tx.description}',
              style: const TextStyle(fontSize: 11.5),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'SAR ${tx.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                if (isSwipe && !tx.isSubmitted)
                  InkWell(
                    onTap: () {
                      final draft = provider.createDraftFromStatementTx(tx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewClaimScreen(initialDraft: draft),
                        ),
                      );
                    },
                    child: const Text(
                      'Create Draft ➔',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  )
                else
                  Text(
                    tx.isSubmitted ? 'Reconciled / Linked' : 'Pending',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF059669)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpenseListTab(ClaimDeskProvider provider) {
    final lines = provider.claims.expand((c) => c.lines.map((l) => MapEntry(c, l))).toList();
    if (lines.isEmpty) {
      return const Center(child: Text('No expense lines recorded yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lines.length,
      itemBuilder: (ctx, i) {
        final claim = lines[i].key;
        final line = lines[i].value;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text('${claim.docRefNumber} • ${line.category}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text(
              'Invoice: ${line.invoiceNumber} • ${line.paymentSource == PaymentSource.cashAdvance ? "Cash Advance" : "Card Swipe"}',
              style: const TextStyle(fontSize: 11.5),
            ),
            trailing: Text(
              'SAR ${line.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryOrange),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepositListTab(ClaimDeskProvider provider) {
    final deposits = provider.statementTransactions
        .where((t) => t.type == StatementTxType.deposit)
        .toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deposits.length,
      itemBuilder: (ctx, i) {
        final d = deposits[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.savings_outlined, color: Color(0xFF059669)),
            title: Text(d.merchantOrAtm, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            subtitle: Text(DateFormat('dd MMM yyyy').format(d.date)),
            trailing: Text(
              '+ SAR ${d.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(BuildContext context, ClaimDeskProvider provider) {
    final advances = provider.cashAdvances;
    final subs = provider.subCustodians;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EMPLOYEE CASH ADVANCE SUMMARY',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 15),
                label: const Text('Add Employee', style: TextStyle(fontSize: 12)),
                onPressed: () => _showAddSubCustodianModal(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (advances.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No cash advances created yet. Import an ATM withdrawal to auto-create one.'),
              ),
            )
          else
            ...advances.map(
              (adv) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${adv.employeeName} (${adv.employeeId})',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          Text(
                            'Cash In Hand: SAR ${adv.remainingBalance.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total Withdrawn: SAR ${adv.totalWithdrawn.toStringAsFixed(2)}  •  Reconciled: SAR ${adv.totalDeducted.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (subs.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'LINKED EMPLOYEES UNDER THIS CARD',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            ...subs.map(
              (s) => Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${s.employeeId} • Cost Center: ${s.costCenter}'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

