import 'package:flutter/material.dart';

class ContractorList extends StatefulWidget {
  const ContractorList({super.key});

  @override
  State<ContractorList> createState() => _ContractorListState();
}

class _ContractorListState extends State<ContractorList> {
  // Controllers for filters
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedLocation;
  final List<String> _locations = ['All', 'Campus A', 'Campus B', 'Campus C'];

  // Dummy data for DataTable
  final List<Map<String, String>> _contractors = [
    {
      'no': '1',
      'id': 'CNT-001',
      'company': 'Alpha Builders',
      'person': 'John Doe',
      'date': '2023-06-01',
      'mobile': '9876543210',
      'location': 'Campus A',
    },
    {
      'no': '2',
      'id': 'CNT-002',
      'company': 'Beta Constructions',
      'person': 'Jane Smith',
      'date': '2023-05-20',
      'mobile': '9123456789',
      'location': 'Campus B',
    },
    {
      'no': '3',
      'id': 'CNT-003',
      'company': 'Gamma Infra',
      'person': 'Sam Wilson',
      'date': '2023-04-15',
      'mobile': '9988776655',
      'location': 'Campus C',
    },
    {
      'no': '4',
      'id': 'CNT-004',
      'company': 'Delta Works',
      'person': 'Lisa Ray',
      'date': '2023-05-10',
      'mobile': '9001122334',
      'location': 'Campus A',
    },
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applicator List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by Name, ID, Company, or Mobile',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Contract Location Dropdown
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedLocation,
                            items: _locations
                                .map(
                                  (loc) => DropdownMenuItem<String>(
                                    value: loc,
                                    child: Text(loc),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedLocation = val;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Contract Location',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Date Picker
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _dateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Registration Date',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Apply Filters Button
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {},
                              child: const Text('APPLY FILTERS'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // DataTable Card
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('No.')),
                        DataColumn(label: Text('Contractor ID')),
                        DataColumn(label: Text('Company Name')),
                        DataColumn(label: Text('Contact Person')),
                        DataColumn(label: Text('Registration Date')),
                        DataColumn(label: Text('Mobile No.')),
                        DataColumn(label: Text('Location')),
                      ],
                      rows: _contractors
                          .map(
                            (c) => DataRow(
                              cells: [
                                DataCell(Text(c['no']!)),
                                DataCell(Text(c['id']!)),
                                DataCell(Text(c['company']!)),
                                DataCell(Text(c['person']!)),
                                DataCell(Text(c['date']!)),
                                DataCell(Text(c['mobile']!)),
                                DataCell(Text(c['location']!)),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
