import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'screens/evaluation_and_food_purcashe_road.dart';
import 'screens/search_coworking.dart';
import 'screens/eating_zones.dart';



void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Navigator',



        theme: ThemeData(
          useMaterial3: true, //Стилёво
          brightness: Brightness.dark, //Темная тема
          primaryColor: const Color(0xFF6200EA), //Кнопки,иконки,выделения
          scaffoldBackgroundColor: const Color(0xFF0A0F2A), //Фон всех экранов Scaffold

         colorScheme: const ColorScheme.dark( //ЦветСхема для виджетов
           primary: Color(0xFF7C4DFF), //Основной цвет colorScheme
           secondary: Color(0xFFB47CFF), //Вторичный цвет для акцента
           surface: Color(0xFF12163A), // Цвет поверхностей
          ),

         appBarTheme: const AppBarTheme( //Для всех баров
           backgroundColor: Color(0xFF0F142E), //Фон бара
            elevation: 0, //Тени только у баб под глазами
            centerTitle: true, //Заголовок у центра
          ),   
       ),
               home: const CampusNavigationScreen(), //Начальный экран
    );
  }
 }


 class CampusNavigationScreen extends StatefulWidget { //Главный экран и виджет меняющий состояние StatefulWidget
   const CampusNavigationScreen({super.key}); //может быть пригодится, что бы не путать виджеты

   @override //Замена версии родака
   State<CampusNavigationScreen> createState() => _CampusNavigationScreenState(); //Хранит изменяемые данные виджета и создает новый объект(приватный)
  } 

 class _CampusNavigationScreenState extends State<CampusNavigationScreen> {
   int _currentIndex = 0;


   final List<NavigationItem> _navigationItems = const [
     NavigationItem(title: 'Навигация по кампусу', icon: Icons.map),
     NavigationItem(title: 'Зоны питания', icon: Icons.food_bank),
     NavigationItem(
         title: 'Покупка еды и оценка заведения', icon: Icons.star_rate),
     NavigationItem(title: 'Поиск места для учебы', icon: Icons.search),
   ];


   final List<Widget> _screens = [
     NavigationMapScreen(),
     EatingZones(),
     // здесь зоны питания (для особо не знающих английский)
     EvaluationAndFoodPurcasheRoad(),
     // тут оценка заведения + маршрут покупки еды (для особо не знающих английский)
     SearchCoworking(),
     // поиск коворкинга ну или места для учебы
   ];


   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: Text(_navigationItems[_currentIndex].title),
       ),
       body: _screens[_currentIndex],
       bottomNavigationBar: _buildScrollableBottomNavBar(),
     );
   }


   Widget _buildScrollableBottomNavBar() {
     return Container(
       decoration: BoxDecoration(
         color: const Color(0xFF0F142E),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withValues(alpha: 0.3),
             blurRadius: 10,
             offset: const Offset(0, -2),
           ),
         ],
       ),
       child: SafeArea(
         child: SingleChildScrollView(
           scrollDirection: Axis.horizontal,
           physics: const BouncingScrollPhysics(),
           child: Row(
             children: _navigationItems
                 .asMap()
                 .entries
                 .map((entry) {
               final index = entry.key;
               final item = entry.value;
               final isSelected = _currentIndex == index;

               return Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 4),
                 child: _buildNavBarItem(
                   icon: item.icon,
                   title: item.title,
                   isSelected: isSelected,
                   onTap: () {
                     setState(() {
                       _currentIndex = index;
                     });
                   },
                 ),
               );
             }).toList(),
           ),
         ),
       ),
     );
   }


   Widget _buildNavBarItem({
     required IconData icon,
     required String title,
     required bool isSelected,
     required VoidCallback onTap,
   }) {
     return InkWell(

       onTap: onTap,
       borderRadius: BorderRadius.circular(30),
       child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
         margin: const EdgeInsets.symmetric(vertical: 8),
         decoration: BoxDecoration(
           color: isSelected
               ? const Color(0xFF7C4DFF).withValues(alpha: 0.2)
               : Colors.transparent,
           borderRadius: BorderRadius.circular(30),
         ),
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(
               icon,
               color: isSelected ? const Color(0xFFB47CFF) : const Color(
                   0xFF6A6A8B),
               size: 22,
             ),
             const SizedBox(width: 8),
             Text(
               title,
               style: TextStyle(
                 color: isSelected ? const Color(0xFFB47CFF) : const Color(
                     0xFF9A9AB0),
                 fontSize: 14,
                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
               ),
             ),
           ],
         ),
       ),
     );
   }
 }


  class NavigationItem {
    final String title;
    final IconData icon;

    const NavigationItem({
      required this.title,
      required this.icon,
    });
  }



  /*_currentIndex Хранит выбранный раздел
  setState() перерисовывает интерфес при нажатии
  _screens[index] отображает нужный экран
  SingleChildScrollView делает меню прокручиваемым
  isSelected управляет выбелением  */

class NavigationMapScreen extends StatefulWidget {
  const NavigationMapScreen({super.key});

  @override
  State<NavigationMapScreen> createState() => _NavigationMapScreenState();
}

class _NavigationMapScreenState extends State<NavigationMapScreen> {
  final MapController _mapController = MapController();
  
  LatLng _currentCenter = const LatLng(56.4695, 84.9475);
  double _currentZoom = 17;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(56.4695, 84.9475),
        initialZoom: 17,
        minZoom: 16,
        maxZoom: 19,
        onPositionChanged: (MapPosition position, bool hasGesture) {
          if (hasGesture) {
            final center = position.center;
            if (center != null) {
              _currentCenter = center;
              _currentZoom = position.zoom ?? 17;
              
              if (center.latitude < 56.460 || 
                  center.latitude > 56.478 ||
                  center.longitude < 84.938 ||
                  center.longitude > 84.958) {
                _animateBackToCenter();
              }
            }
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.flutter_androidmap1',
          tileBuilder: (context, widget, tile) {
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                // В стиле твоего приложения: темно-синий + фиолетовый акцент
                0.35, 0.25, 0.50, 0, 8,   // R — фиолетовый оттенок
                0.25, 0.30, 0.45, 0, 8,   // G — приглушенный
                0.50, 0.35, 0.70, 0, 12,  // B — синий акцент
                0,    0,    0,    1, 0,   // A
              ]),
              child: widget,
            );
          },
        ),
      ],
    );
  }

  void _animateBackToCenter() async {
    final start = _currentCenter;
    final end = const LatLng(56.4695, 84.9475);
    final steps = 20;
    
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 16));
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      
      _mapController.move(
        LatLng(lat, lng),
        _currentZoom,
      );
    }
  }
}