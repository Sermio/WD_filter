import 'package:flutter/material.dart';
import 'package:adv_basics/components/cCard.dart';
import 'package:adv_basics/data/items.dart'; // Asegúrate de que esta importación es correcta
import 'package:adv_basics/api/gets.dart';

class CardList extends StatefulWidget {
  const CardList({super.key});

  @override
  State<CardList> createState() {
    return _CardListState();
  }
}

class _CardListState extends State<CardList> {
  late Future<List<WorldshiftItem>> futureElements;
  List<WorldshiftItem> allItems = [];
  List<WorldshiftItem> filteredItems = [];
  final TextEditingController _descriptionFilterController =
      TextEditingController();
  final TextEditingController _locationFilterController =
      TextEditingController();
  final TextEditingController _raceFilterController = TextEditingController();
  final TextEditingController _typeFilterController = TextEditingController();
  final TextEditingController _nameFilterController =
      TextEditingController(); // Nuevo controlador para el filtro por nombre
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isBisChecked = false; // Variable para el estado del Checkbox

  @override
  void initState() {
    super.initState();
    var excelReader = ExcelReader('items.xlsx');
    futureElements = excelReader.readItems();
    futureElements.then((items) {
      setState(() {
        allItems = items;
        filteredItems = items;
      });
    });

    _descriptionFilterController.addListener(_filterItems);
    _locationFilterController.addListener(_filterItems);
    _raceFilterController.addListener(_filterItems);
    _typeFilterController.addListener(_filterItems);
    _nameFilterController.addListener(
        _filterItems); // Añadido el listener para el filtro por nombre
  }

  void _filterItems() {
    final descriptionQuery = _descriptionFilterController.text.toLowerCase();
    final locationQuery = _locationFilterController.text.toLowerCase();
    final raceQuery = _raceFilterController.text.toLowerCase();
    final typeQuery = _typeFilterController.text.toLowerCase();
    final nameQuery =
        _nameFilterController.text.toLowerCase(); // Filtro por nombre

    setState(() {
      filteredItems = allItems.where((item) {
        final description = item.description.toLowerCase();
        final location = item.location.toLowerCase();
        final race = item.race.toLowerCase();
        final type = item.type.toLowerCase();
        final name = item.name.toLowerCase(); // Añadido nombre

        final bis = item.bis;

        final matchesDescription = description.contains(descriptionQuery);
        final matchesLocation = location.contains(locationQuery);
        final matchesRace = race.contains(raceQuery);
        final matchesType = type.contains(typeQuery);
        final matchesName = name.contains(nameQuery); // Filtro por nombre
        final matchesBis =
            _isBisChecked ? bis : true; // Filtrar basado en el checkbox

        return (descriptionQuery.isEmpty || matchesDescription) &&
            (locationQuery.isEmpty || matchesLocation) &&
            (raceQuery.isEmpty || matchesRace) &&
            (typeQuery.isEmpty || matchesType) &&
            (nameQuery.isEmpty || matchesName) && // Añadido filtro por nombre
            (matchesBis);
      }).toList();
    });
  }

  void _onBisCheckboxChanged(bool? value) {
    setState(() {
      _isBisChecked = value ?? false;
      _filterItems(); // Refiltrar cuando cambie el estado del checkbox
    });
  }

  Widget _buildFilterTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          _filterItems();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double drawerWidth = MediaQuery.of(context).size.width * 0.4;

    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Items"),
          actions: [
            IconButton(
              icon: Icon(Icons.filter_alt_rounded),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
          ],
        ),
        endDrawer: Container(
          width: drawerWidth,
          child: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  color: Colors.blue,
                  height: 80, // Ajusta esta altura según tus necesidades
                  child: Center(
                    child: Text(
                      'Filters',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildFilterTextField('Name',
                          _nameFilterController), // Añadido filtro por nombre
                      _buildFilterTextField(
                          'Description', _descriptionFilterController),
                      _buildFilterTextField(
                          'Location', _locationFilterController),
                      _buildFilterTextField('Race', _raceFilterController),
                      _buildFilterTextField('Type', _typeFilterController),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Bis'),
                          IconButton(
                            icon: Icon(
                              Icons.star,
                              color: _isBisChecked
                                  ? Colors.yellow[700]
                                  : Colors.grey[350],
                            ),
                            onPressed: () {
                              _onBisCheckboxChanged(!_isBisChecked);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<WorldshiftItem>>(
                future: futureElements,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No items found'));
                  } else {
                    return ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Ccard(cardElement: item);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
