import 'package:flutter/material.dart';
import 'package:kenuniv/screens/auth/login_screen.dart';

class Sliderbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String userName;

  const Sliderbar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,

      color: Color(0xffC02221),
      child: Column(
        children: [
          DrawerHeader(
            child: Column(
              children: [
                Image.asset("assets/images/icons/user.png"),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          DrawerListTile(
            title: "Dashboard",

            svgSrc: "assets/images/icons/dashboard.png",
            selected: selectedIndex == 0,
            press: () => onItemSelected(0),
          ),
          DrawerListTile(
            title: "User Master",
            svgSrc: "assets/images/icons/usermaster.png",
            selected: selectedIndex == 1,
            press: () => onItemSelected(1),
          ),
          DrawerListTile(
            title: "Gift Scheme Master",
            svgSrc: "assets/images/icons/scheme.png",
            selected: selectedIndex == 2,
            press: () => onItemSelected(2),
          ),
          DrawerListTile(
            title: "Gift Stock Master",
            svgSrc: "assets/images/icons/stock.png",
            selected: selectedIndex == 3,
            press: () => onItemSelected(3),
          ),
          DrawerListTile(
            title: "Point Master",
            svgSrc: "assets/images/icons/qrcode.png",
            selected: selectedIndex == 4,
            press: () => onItemSelected(4),
          ),
          DrawerListTile(
            title: "Qr Code Generation",
            svgSrc: "assets/images/icons/qrcode.png",
            selected: selectedIndex == 5,
            press: () => onItemSelected(5),
          ),
          DrawerListTile(
            title: "Redemption Master",
            svgSrc: "assets/images/icons/redemption.png",
            selected: selectedIndex == 6,
            press: () => onItemSelected(6),
          ),
          DrawerListTile(
            title: "Wallet History",
            svgSrc: "assets/images/icons/wallet.png",
            selected: selectedIndex == 7,
            press: () => onItemSelected(7),
          ),
          DrawerListTile(
            title: "Applicator List",
            svgSrc: "assets/images/icons/contractor.png",
            selected: selectedIndex == 8,
            press: () => onItemSelected(8),
          ),
          DrawerListTile(
            title: "News Update",
            svgSrc: "assets/images/icons/news.png",
            selected: selectedIndex == 9,
            press: () => onItemSelected(9),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xffC02221),
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    Key? key,
    required this.title,
    required this.svgSrc,
    required this.press,
    this.selected = true,
  }) : super(key: key);

  final String title, svgSrc;
  final VoidCallback press;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: press,
          child: ListTile(
            leading: Image.asset(
              svgSrc,
              height: 20,
              color: selected ? const Color(0xFFBF1E2E) : Colors.white,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: selected ? const Color(0xFFBF1E2E) : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
