import 'dart:io';

import 'package:flutter/material.dart';

import '../models/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final String? alertText;
  final Color? alertColor;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    this.alertText,
    this.alertColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: vehicle.photoPath != null
              ? FileImage(File(vehicle.photoPath!))
              : null,
          child: vehicle.photoPath == null
              ? const Icon(Icons.directions_car_outlined)
              : null,
        ),
        title: Text(vehicle.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${vehicle.make} ${vehicle.model}${vehicle.year != null ? ' (${vehicle.year})' : ''} • ${vehicle.plateNumber}\n'
          '${vehicle.mileage} km',
        ),
        isThreeLine: true,
        trailing: alertText != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (alertColor ?? Colors.grey).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alertText!,
                  style: TextStyle(color: alertColor, fontWeight: FontWeight.w600, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
