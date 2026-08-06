import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/shared/widgets/app_back_button_widget.dart';
import 'package:shared_core/shared_core.dart';

class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({super.key, required this.country});

  final String country;

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<PlaceModel> _results = const [];
  bool _isSearching = false;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    final requestId = ++_requestId;
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(query, requestId),
    );
  }

  Future<void> _search(String query, int requestId) async {
    final position = LocationService.lastPosition;
    final results = await MapProvider.searchPlaces(
      '$query, ${widget.country}',
      lat: position?.latitude,
      lng: position?.longitude,
    );
    if (!mounted || requestId != _requestId) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: AppBackButtonWidget.plain(onPressed: () => context.pop()),
        title: Text(widget.country),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search a pickup area',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onQueryChanged('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchController.text.trim().length < 2) {
      return const _LocationSearchHint();
    }
    if (_results.isEmpty) {
      return const _LocationSearchHint(
        title: 'No places found',
        message: 'Try a nearby landmark, street, or neighborhood.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppTheme.borderSide),
      itemBuilder: (context, index) {
        final place = _results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: const Icon(
            Icons.location_on_outlined,
            color: AppTheme.complete,
          ),
          title: Text(
            place.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            place.fullAddress,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.tertiaryColor),
          ),
          onTap: () => context.pop(place),
        );
      },
    );
  }
}

class _LocationSearchHint extends StatelessWidget {
  const _LocationSearchHint({
    this.title = 'Search for your pickup area',
    this.message = 'Use a place name, street, or landmark.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppTheme.complete,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.tertiaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
