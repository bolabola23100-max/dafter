import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const ActionButton({super.key, 
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? const Color(0xFF0E4C4C) : const Color(0xFFF1F3F4),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: primary ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primary ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}