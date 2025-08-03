import 'package:flutter/material.dart';
import 'package:finns_mobile/features/dashboard/widgets/info_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange.shade600,
        title: const Text(
          'Si Ternak',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white, // Warna latar belakang
                shape: BoxShape.circle, // Membuat bulat penuh
              ),
              child: IconButton(
                icon: Icon(
                  LucideIcons.user,
                  color: Colors.black87, // Warna icon
                  size: 20,
                ),
                onPressed: () {
                },
                padding: EdgeInsets.zero, // Menghilangkan padding default
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.orange.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InfoCard(
                  icon: LucideIcons.layers,
                  label: 'Populasi Ayam',
                  value: '150 Ekor',
                  color: Colors.orange.shade300,
                ),
                InfoCard(
                  icon: LucideIcons.egg,
                  label: 'Telur',
                  value: '200kg',
                  color: Colors.yellow.shade600,
                ),
                InfoCard(
                  icon: LucideIcons.activity,
                  label: 'FCR',
                  value: '2.4',
                  color: Colors.green.shade400,
                ),
                InfoCard(
                  icon: LucideIcons.feather,
                  label: 'Pullet (Grower)',
                  value: '50 Ekor',
                  color: Colors.blue.shade300,
                ),
              ],
            ),
          ),
          // const Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          //   child: Text(
          //     'Himbauan',
          //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          //   ),
          // ),
          // const NoticeCard(
          //   title: 'Cek peternakan kamu dan cari tahu supaya berkembang',
          //   description:
          //       'Lihat perkembangan peternakan kamu supaya berkembang pesat',
          // ),
          // const NoticeCard(
          //   title: 'Peternakan kamu ayam nya pada mati',
          //   description:
          //       'Segera Lihat apa yang terjadi dengan ayam petelur kamu',
          // ),
          // const NoticeCard(
          //   title: 'Cek perkembangan ayam petelur kamu seminggu ini',
          //   description: 'Lihat statistik mingguan produksi dan populasi',
          // ),
        ],
      ),
    );
  }
}
