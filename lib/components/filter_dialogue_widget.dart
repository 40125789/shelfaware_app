import 'package:flutter/material.dart';

class FilterDialog extends StatefulWidget {
  final bool filterExpiringSoon;
  final bool filterNewlyAdded;
  final double? filterDistance;
  final ValueChanged<bool> onExpiringSoonChanged;
  final ValueChanged<bool> onNewlyAddedChanged;
  final ValueChanged<double?> onDistanceChanged;
  final VoidCallback onApply;

  FilterDialog({
    required this.filterExpiringSoon,
    required this.filterNewlyAdded,
    required this.filterDistance,
    required this.onExpiringSoonChanged,
    required this.onNewlyAddedChanged,
    required this.onDistanceChanged,
    required this.onApply,
  });

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late bool filterExpiringSoon;
  late bool filterNewlyAdded;
  late double? filterDistance;

  @override
  void initState() {
    super.initState();
    filterExpiringSoon = widget.filterExpiringSoon;
    filterNewlyAdded = widget.filterNewlyAdded;
    filterDistance = widget.filterDistance;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: BottomSheet(
        onClosing: () {},
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(context),
                  SizedBox(height: 20),
                  _buildSortOptions(),
                  SizedBox(height: 20),
                  _buildDistanceOptions(),
                  SizedBox(height: 20),
                  _buildApplyButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        Center(
          child: Column(
            children: [
              Text(
                'Donations Filter',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Divider(thickness: 2, color: Theme.of(context).dividerColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sort by:', style: Theme.of(context).textTheme.bodyLarge),
        Row(
          children: [
            _buildToggleButton(
              label: 'Expiring Soon',
              isSelected: filterExpiringSoon,
              onPressed: () {
                setState(() {
                  filterExpiringSoon = !filterExpiringSoon;
                });
                widget.onExpiringSoonChanged(filterExpiringSoon);
              },
            ),
            SizedBox(width: 10),
            _buildToggleButton(
              label: 'Newly Added',
              isSelected: filterNewlyAdded,
              onPressed: () {
                setState(() {
                  filterNewlyAdded = !filterNewlyAdded;
                });
                widget.onNewlyAddedChanged(filterNewlyAdded);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Maximum Distance:', style: Theme.of(context).textTheme.bodyLarge),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [0.3, 0.6, 1.3].map((distance) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildToggleButton(
                  label: '${distance.toStringAsFixed(1)} miles',
                  isSelected: filterDistance == distance,
                  onPressed: () {
                    setState(() {
                      filterDistance = filterDistance == distance ? null : distance;
                    });
                    widget.onDistanceChanged(filterDistance);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        foregroundColor: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
        backgroundColor: isSelected ? Colors.green : Theme.of(context).colorScheme.surface,
      ),
      child: Text(label),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onApply,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: Text(
          'Apply',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
