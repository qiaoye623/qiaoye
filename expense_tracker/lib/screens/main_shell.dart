import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ledger_provider.dart';
import 'ledger_tab.dart';
import 'details_tab.dart';
import 'profile_tab.dart';
import 'add_transaction_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1;

  final List<Widget> _pages = const [
    LedgerTab(),
    DetailsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: Row(
          children: [
            Expanded(child: _buildNavItem(Icons.book_outlined, '账本', 0)),
            Expanded(child: _buildNavItem(Icons.receipt_long_outlined, '明细', 1)),
            Expanded(child: _buildNavItem(Icons.person_outline, '我的', 2)),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () {
            final ledgerId =
                context.read<LedgerProvider>().currentLedger?.id;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddTransactionScreen(preSelectedLedgerId: ledgerId),
              ),
            );
          },
          shape: const CircleBorder(),
          backgroundColor: const Color(0xFF1677FF),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          context.read<LedgerProvider>().switchLedger(
                context.read<LedgerProvider>().currentLedger?.id ?? 1,
              );
        }
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26,
              color: isSelected ? const Color(0xFF1677FF) : const Color(0xFF999999)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? const Color(0xFF1677FF) : const Color(0xFF999999))),
        ],
      ),
    );
  }
}
