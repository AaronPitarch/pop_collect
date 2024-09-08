import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _signOut(context,)
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          //Mostrar la lista de la coleccion
          final funkoDocs = snapshot.data!.docs;
          
          return ListView.builder(
            itemCount: funkoDocs.length,
            itemBuilder: (context, index) {
              final funko = funkoDocs[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.toys),
                  title: Text(funko['name'] ?? 'Nombre no disponible'),
                  subtitle: Text(funko['description'] ?? 'Sin descripcion'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFunko,
        child: const Icon(Icons.add),
      ),
    );
  }
}