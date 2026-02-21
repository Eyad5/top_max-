import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../models/country_model.dart';
import 'package:country_flags/country_flags.dart';


class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  List<CountryModel> countries = [];

  Future<void> fetchCountries() async {
    final res = await DioClient.dio.get('location/countries');

    final data = res.data['data'] as List;

    setState(() {
      countries =
          data.map((e) => CountryModel.fromJson(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Countries Test')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: fetchCountries,
            child: const Text('Fetch Countries'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: countries.length,
              itemBuilder: (context, index) {
                final c = countries[index];
                return ListTile(
                  leading: CountryFlag.fromCountryCode(
                    c.iso,
                    height: 28,
                     width: 28,
                     ),

                  title: Text(c.name),
                  subtitle: Text('${c.iso}  ${c.code}'),
                  trailing: Text('#${c.id}'),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
