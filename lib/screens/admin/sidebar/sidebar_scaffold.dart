import 'package:flutter/material.dart';
import 'package:kenuniv/screens/admin/contractor_list.dart';
import 'package:kenuniv/screens/admin/dashboard_screen.dart';
import 'package:kenuniv/screens/admin/news_update.dart';
import 'package:kenuniv/screens/admin/point_master.dart';
import 'package:kenuniv/screens/admin/qr_code_screen.dart';
import 'package:kenuniv/screens/admin/redemption_history.dart';
import 'package:kenuniv/screens/admin/wallet_history.dart';
import 'package:kenuniv/screens/admin/scheme_master.dart';
import 'package:kenuniv/screens/admin/sidebar/sidebar.dart';
import 'package:kenuniv/screens/admin/stock_master.dart';
import 'package:kenuniv/screens/admin/user_master.dart';

class SidebarScaffold extends StatefulWidget {
  final String userName; // add this

  const SidebarScaffold({super.key, required this.userName});

  @override
  State<SidebarScaffold> createState() => _SidebarScaffoldState();
}

class _SidebarScaffoldState extends State<SidebarScaffold> {
  int selectedIndex = 0;

  final List<Widget> screens = [
    DashboardScreen(),
    UserMaster(),
    SchemeMaster(),
    StockMaster(),
    PointMaster(),
    QrCodeScreen(),
    RedemptionHistory(),
    WalletHistory(),
    ContractorList(),
    NewsUpdate(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sliderbar(
            selectedIndex: selectedIndex,
            onItemSelected: (index) {
              setState(() => selectedIndex = index);
            },
            userName: widget.userName,
          ),
          Expanded(child: screens[selectedIndex]),
        ],
      ),
    );
  }
}
