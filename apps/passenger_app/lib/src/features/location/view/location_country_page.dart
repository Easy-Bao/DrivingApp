import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/location/location_routes.dart';
import 'package:passenger_app/src/shared/widgets/app_back_button_widget.dart';
import 'package:shared_core/shared_core.dart';

class LocationCountryPage extends StatefulWidget {
  const LocationCountryPage({super.key});

  @override
  State<LocationCountryPage> createState() => _LocationCountryPageState();
}

class _LocationCountryPageState extends State<LocationCountryPage> {
  static const _countries = [
    'Philippines',
    'Malaysia',
    'Singapore',
    'Indonesia',
    'Thailand',
    'Vietnam',
    'Cambodia',
  ];

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectCountry(String country) async {
    final result = await context.pushNamed(
      LocationRoutes.search,
      queryParameters: {'country': country},
    );
    if (mounted && result is PlaceModel) {
      context.pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final countries = _countries
        .where((country) => country.toLowerCase().contains(_query))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: AppBackButtonWidget.plain(onPressed: () => context.pop()),
        title: const Text('Choose your area'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search country or region',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            Expanded(
              child: countries.isEmpty
                  ? const Center(
                      child: Text(
                        'No supported areas found',
                        style: TextStyle(color: AppTheme.tertiaryColor),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: countries.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppTheme.borderSide),
                      itemBuilder: (context, index) {
                        final country = countries[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          title: Text(
                            country,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectCountry(country),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
