import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pop_collect/presentation/screens/add_funko_screen.dart';
import 'package:pop_collect/presentation/screens/edit_funko_screen.dart';
import 'package:pop_collect/presentation/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(_showFavoritesOnly ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
            },
          )
        ],
      ),
      body: Column(
        children: [ 
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
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
            
                //Filtrar funkos segun busqueda y favoritos
                final funkoDocs = snapshot.data!.docs.where((doc) {
                  final funkoName = doc['name'].toString().toLowerCase();
                  final isFavorite = (doc.data() as Map<String, dynamic>)['isFavorite'] ?? false;
                  return funkoName.contains(_searchQuery) && (!_showFavoritesOnly || isFavorite);
                }).toList();
                
                return ListView.builder(
                  itemCount: funkoDocs.length,
                  itemBuilder: (context, index) {
                    final doc = funkoDocs[index];
                    final funko = doc.data() as Map<String, dynamic>;
                    final isFavorite = funko['isFavorite'] ?? false;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.toys),
                        title: Text(funko['name'] ?? 'Nombre no disponible'),
                        subtitle: Text(funko['description'] ?? 'Sin descripcion'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                              onPressed: () {
                                doc.reference.update({'isFavorite': !isFavorite});
                              } 
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(context, doc.id);
                              }
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditFunkoScreen(funkoId: doc.id),
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
      //Boton para añadir nuevos funkos
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddFunkoScreen(),
            ),
          );
        },
        tooltip: 'Añadir funko',
        child: const Icon(Icons.add),
      ),
    );
  }

  //Metodo para mostrar un dialogo de confirmacion antes de eliminar
  void _showDeleteConfirmation(BuildContext context, String funkoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Funko'),
        content: const Text('¿Estás seguro de eliminar este Funko?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _deleteFunko(funkoId);
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ]
      )
    );
  }

  //Metodo para eliminar un funko de Firestore
  Future<void> _deleteFunko(String funkoId) async {
    try {
      await _firestore.collection('funkos').doc(funkoId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funko eliminado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el funko: $e')),
      );
    }
  }
}