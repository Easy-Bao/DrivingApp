import 'package:flutter/foundation.dart';

/// Coordinates the committed tab selection, back history, and live page
/// position used by a swipe-driven tab shell.
///
/// The committed index is intentionally separate from [pagePosition]. The
/// former drives routing and accessibility semantics; the latter follows the
/// [PageController] continuously while a page is being dragged or animated.
class TabNavigationCoordinator extends ChangeNotifier {
  int? _selectedIndex;
  final List<int> _navigationHistory = <int>[];
  final ValueNotifier<double> _pagePosition = ValueNotifier<double>(0);

  int get selectedIndex => _selectedIndex ?? 0;
  ValueListenable<double> get pagePosition => _pagePosition;

  bool get canPop =>
      _navigationHistory.length <= 1 &&
      _navigationHistory.isNotEmpty &&
      _navigationHistory.last == 0;

  void initialize(int index) {
    if (_selectedIndex != null) return;

    _selectedIndex = index;
    _navigationHistory.add(index);
    _pagePosition.value = index.toDouble();
  }

  void updatePagePosition(double position) {
    if (!position.isFinite || _pagePosition.value == position) return;
    _pagePosition.value = position;
  }

  void commit(int index) {
    if (_selectedIndex == null) {
      initialize(index);
      notifyListeners();
      return;
    }
    if (_selectedIndex == index) return;

    _selectedIndex = index;
    _navigationHistory.add(index);
    notifyListeners();
  }

  int goBackToPreviousTab() {
    if (_navigationHistory.length > 1) {
      _navigationHistory.removeLast();
      _selectedIndex = _navigationHistory.last;
    } else {
      _navigationHistory
        ..clear()
        ..add(0);
      _selectedIndex = 0;
    }
    notifyListeners();
    return selectedIndex;
  }

  @override
  void dispose() {
    _pagePosition.dispose();
    super.dispose();
  }
}
