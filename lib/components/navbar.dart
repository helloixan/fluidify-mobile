import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.home_filled,
              inactiveIcon: Icons.home_outlined,
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.quiz_rounded,
              inactiveIcon: Icons.quiz_outlined,
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.leaderboard,
              inactiveIcon: Icons.leaderboard_outlined,
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.person,
              inactiveIcon: Icons.person_outline,
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData inactiveIcon,
    required int index,
  }) {
    final isActive = selectedIndex == index;
    const activeColor = regularBlue;
    final inactiveColor = Colors.grey.shade500;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? icon : inactiveIcon,
            color: isActive ? activeColor : inactiveColor,
            size: 35,
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 5,
            width: 5,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
