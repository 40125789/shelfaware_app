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
  late double? filterDistance; // Nullable type for distance

  @override
  void initState() {
    super.initState();
    filterExpiringSoon = widget.filterExpiringSoon;
    filterNewlyAdded = widget.filterNewlyAdded;
    filterDistance = widget.filterDistance;
  }

  ButtonStyle buttonStyle(double? selectedDistance, double buttonDistance) {
    return ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      foregroundColor: selectedDistance == buttonDistance ? Colors.white : Colors.black,
      backgroundColor: selectedDistance == buttonDistance ? Colors.green : Colors.grey[200],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: BottomSheet(
        onClosing: () {},
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
                    Divider(
                      thickness: 2,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort by:'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        filterExpiringSoon = !filterExpiringSoon;
                      });
                      widget.onExpiringSoonChanged(filterExpiringSoon);
                    },
                    style: buttonStyle(filterExpiringSoon ? 1.0 : 0.0, 1.0),
                    child: Text('Expiring Soon'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        filterNewlyAdded = !filterNewlyAdded;
                      });
                      widget.onNewlyAddedChanged(filterNewlyAdded);
                    },
                    style: buttonStyle(filterNewlyAdded ? 1.0 : 0.0, 1.0),
                    child: Text('Newly Added'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Filter by Distance:'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filterDistance = filterDistance == 0.3 ? null : 0.3; // Toggle the distance
                        });
                        widget.onDistanceChanged(filterDistance); // Pass nullable double
                      },
                      style: buttonStyle(filterDistance, 0.3),
                      child: Text('0.3 miles'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filterDistance = filterDistance == 0.6 ? null : 0.6; // Toggle the distance
                        });
                        widget.onDistanceChanged(filterDistance); // Pass nullable double
                      },
                      style: buttonStyle(filterDistance, 0.6),
                      child: Text('0.6 miles'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filterDistance = filterDistance == 1.3 ? null : 1.3; // Toggle the distance
                        });
                        widget.onDistanceChanged(filterDistance); // Pass nullable double
                      },
                      style: buttonStyle(filterDistance, 1.3),
                      child: Text('1.3 miles'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onApply,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
