import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pop_collect/presentation/screens/add_funko_screen.dart';
import 'package:pop_collect/presentation/screens/funko_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';

  //Funcion cerrar sesion
  void _signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  //Funcion para añadir un nuevo Funko
  Future<void> _addFunko() async {
    await _firestore.collection('funkos').add({
      'name': 'Nuevo Funko',
      'description': 'Descripcion del Funko',
      'userId': _auth.currentUser?.uid,
      'createAdt': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Column(
        children: [ 
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar Funko',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('funkos').where('userId', isEqualTo: _auth.currentUser?.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
            
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar la coleccion'),
                  );
                }
            
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay Funkos para mostrar'),
                  );
                }
            
                //Filtrar funkos
                final funkoDocs = snapshot.data!.docs.where((doc) {
                  final funkoName = doc['name'].toString().toLowerCase();
                  return funkoName.contains(_searchQuery);
                }).toList();
                
                return ListView.builder(
                  itemCount: funkoDocs.length,
                  itemBuilder: (context, index) {
                    final funko = funkoDocs[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.toys),
                        title: Text(funko['name'] ?? 'Nombre no disponible'),
                        subtitle: Text(funko['description'] ?? 'Sin descripcion'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FunkoDetailScreen(funkoId: funkoDocs[index].id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFunkoScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}