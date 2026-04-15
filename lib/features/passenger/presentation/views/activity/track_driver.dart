import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';

class AcitivityTrackDriver extends StatefulWidget {
  const AcitivityTrackDriver({super.key});

  @override
  State<AcitivityTrackDriver> createState() => _AcitivityTrackDriverState();
}

class _AcitivityTrackDriverState extends State<AcitivityTrackDriver> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          Container(
            color: AppTheme.surface,
            child: Center(
              child: Icon(
                Icons.map_sharp,
                size: 100,
                color: AppTheme.outlineBorderColor,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: AppTheme.surface,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Text(
                    "ARRIVING IN",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    "4 min",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(
                          'https://via.placeholder.com/60',
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Xyrel D. Tenefrancia",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              "Bao Bao",
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Plate Number",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          Icons.message,
                          "Message",
                          AppTheme.outlineBorderColor,
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionButton(
                          Icons.call,
                          "Call",
                          AppTheme.primaryColor,
                          Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {},
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsetsGeometry.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppTheme.cancel.withValues(alpha: 0.1),
                        borderRadius: BorderRadiusGeometry.circular(32),
                      ),
                      child: Text(
                        "Cancel Trip",
                        style: TextStyle(
                          color: AppTheme.cancel,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color bg, Color text) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: text, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: text, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
