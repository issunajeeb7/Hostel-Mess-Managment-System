import 'package:flutter/material.dart';
import 'package:mess_bytes/polling_screen.dart';
import 'admin_scan_screen.dart';
import 'voucher_market_place_screen.dart';
import 'profile_screen.dart';
import 'claimed_voucher_screen.dart';
import 'share_meal_screen.dart';
import 'fee_payment_screen.dart';
import 'admin_fee_status_screen.dart';
import 'admin_poll_create_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final String userId;
  final String userRole;

  const MainScreen({
    Key? key,
    required this.initialIndex,
    required this.userId,
    required this.userRole,
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // _selectedIndex = widget.initialIndex;
  }

  int _selectedIndex = 0;
  // Create a function to load icons from assets based on user role
  Widget _loadIcon(String iconName, bool isSelected) {
    final iconSize = 30.0;
    return Image.asset(
      'assets/$iconName${isSelected ? '' : '_outlined'}.png',
      width: iconSize,
      height: iconSize,
      color: isSelected ? Colors.black : const Color.fromARGB(255, 0, 0, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> screens;
    List<BottomNavigationBarItem> bottomItems;

    if (widget.userRole == 'admin') {
      screens = [
        const AdminScanScreen(),
        const AdminFeeStatusScreen(),
        CreatePollScreen(),

        // Add more admin-specific screens here
      ];
      bottomItems = [
        BottomNavigationBarItem(
          icon: _loadIcon('qr', _selectedIndex == 0),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: _loadIcon('dollar', _selectedIndex == 1),
          label: 'Other',
        ),
        BottomNavigationBarItem(
          icon: _loadIcon('poll', _selectedIndex == 2),
          label: 'Other',
        ),
        // Add more items for admin-specific features here
      ];
    } else if (widget.userRole == 'non-hosteller') {
      screens = [
        VoucherMarketplaceScreen(),
        ClaimedVoucher(),
        // Add more non-hosteller-specific screens here
      ];
      bottomItems = [
        BottomNavigationBarItem(
          icon: _loadIcon('shoppingcart', _selectedIndex == 0),
          label: 'Marketplace',
        ),
        BottomNavigationBarItem(
          icon: _loadIcon('ticketicon', _selectedIndex == 1),
          label: 'Other',
        ),
        // Add more items for non-hosteller-specific features here
      ];
    } else {
      // For the default user
      screens = [
        ProfileScreen(userId: widget.userId),
        ShareMealScreen(),
        FeePaymentScreen(),
        BreakfastPoll()
        // Add more default user-specific screens here
      ];
      bottomItems = [
        BottomNavigationBarItem(
          icon: _loadIcon('home', _selectedIndex == 0),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: _loadIcon('fastfood', _selectedIndex == 1),
          label: 'Meal Cut',
        ),
        BottomNavigationBarItem(
          icon: _loadIcon('dollar', _selectedIndex == 2),
          label: 'Fees',
        ),
        BottomNavigationBarItem(
          icon: _loadIcon('poll', _selectedIndex == 3),
          label: 'Fees',
        ),
        // Add more items for default user-specific features here
      ];
    }

    // Define the color of the yellow square
    const activeIconColor = Color(0xFFFBC32C);

    // Define the size of the rounded square
    // final squareSize = 36.0; // The size of the square

    // Create a function to wrap an icon with a yellow square if it's selected
    Widget _wrapIcon(Widget icon, bool isSelected) {
      return isSelected
          ? Container(
              width: 45,
              height: 40,
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: activeIconColor,
                borderRadius:
                    BorderRadius.circular(10), // Adjust for rounded corners
              ),
              child: Center(child: icon),
            )
          : icon;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
            ),
            const SizedBox(
                height:
                    0), // Add a small space between the body and the bottom navigation bar
          ],
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          
          items: bottomItems.map((item) {
            final index = bottomItems.indexOf(item);
            // Wrap the icon with a yellow square if it's selected
            return BottomNavigationBarItem(
              icon: _wrapIcon(item.icon, _selectedIndex == index),
              label: item.label,
            );
          }).toList(),
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          // elevation: 0, // Remove the shadow to prevent additional padding
        ),
      ),
    );
  }
}
