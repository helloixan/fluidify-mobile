import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:fluidify_mobile/models/app_size.dart';
import 'package:flutter/material.dart';

class FluidifyToggleSwitch extends StatefulWidget {
  final String leftText;
  final String rightText;
  final Function(bool isLeftSelected) onChanged;

  const FluidifyToggleSwitch({
    super.key,
    required this.leftText,
    required this.rightText,
    required this.onChanged,
  });

  @override
  State<FluidifyToggleSwitch> createState() => _FluidifyToggleSwitchState();
}

class _FluidifyToggleSwitchState extends State<FluidifyToggleSwitch> {
  bool _isLeftSelected = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: AppSize.screenWidth(context) * 0.9,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment:
                _isLeftSelected ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!_isLeftSelected) {
                      setState(() => _isLeftSelected = true);
                      widget.onChanged(true);
                    }
                  },
                  child: Center(
                    child: Text(
                      widget.leftText,
                      style: fBoldTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _isLeftSelected
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_isLeftSelected) {
                      setState(() => _isLeftSelected = false);
                      widget.onChanged(false);
                    }
                  },
                  child: Center(
                    child: Text(
                      widget.rightText,
                      style: fBoldTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: !_isLeftSelected
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
