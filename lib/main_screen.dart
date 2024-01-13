import 'package:flutter/material.dart';
import 'admin_scan_screen.dart';
import 'voucher_market_place_screen.dart';
import 'profile_screen.dart';
import 'claimed_voucher_screen.dart';
import 'share_meal_screen.dart';
import 'fee_payment_screen.dart';
import 'admin_fee_status_screen.dart';

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
      color: isSelected ? Colors.black : Color.fromARGB(255, 0, 0, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> screens;
    List<BottomNavigationBarItem> bottomItems;

    if (widget.userRole == 'admin') {
      screens = [
        AdminScanScreen(),
        AdminFeeStatusScreen(),
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
        // Add more items for default user-specific features here
      ];
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent, // Set splash color to transparent
          highlightColor:
              Colors.transparent, // Set highlight color to transparent
        ),
        child: BottomNavigationBar(
          items: bottomItems,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.black, // Color for the selected item
          unselectedItemColor: Colors.grey, // Color for the unselected item
          backgroundColor: Color(0xFFFBC32C), // The background color
          type: BottomNavigationBarType
              .fixed, // This ensures all items are fixed to the bottom bar
          showSelectedLabels:
              false, // This will hide the label text for selected items
          showUnselectedLabels:
              false, // This will hide the label text for unselected items
        ),
      ),
    );
  }
}
