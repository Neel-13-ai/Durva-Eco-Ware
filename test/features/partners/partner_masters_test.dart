import 'package:flutter_test/flutter_test.dart';
import 'package:durvaeco/features/partners/data/models/customer_dto.dart';
import 'package:durvaeco/features/partners/data/models/payment_method_dto.dart';
import 'package:durvaeco/features/partners/data/models/supplier_dto.dart';
import 'package:durvaeco/features/partners/data/models/transporter_dto.dart';
import 'package:durvaeco/features/partners/data/models/vehicle_dto.dart';

void main() {
  group('SupplierDto Serialization', () {
    test('converts from and to JSON accurately', () {
      final json = {
        'id': 1,
        'supplierCode': 'SUP-001',
        'supplierName': 'Green Globe Enterprises',
        'contactPerson': 'Ramesh Gupta',
        'phone': '9876543210',
        'email': 'ramesh@greenglobe.com',
        'address': '12, Industrial Area',
        'city': 'Indore',
        'state': 'MP',
        'taxNumber': '23AABFG1403A1Z5',
        'paymentTermsDays': 30,
        'openingBalance': 0.0,
        'isActive': true,
      };

      final dto = SupplierDto.fromJson(json);
      expect(dto.id, 1);
      expect(dto.supplierCode, 'SUP-001');
      expect(dto.supplierName, 'Green Globe Enterprises');
      expect(dto.taxNumber, '23AABFG1403A1Z5');

      final encoded = dto.toJson();
      expect(encoded['supplierName'], 'Green Globe Enterprises');
      expect(encoded['supplierCode'], 'SUP-001');
    });
  });

  group('CustomerDto Serialization', () {
    test('converts from and to JSON with credit limits', () {
      final json = {
        'id': 10,
        'customerCode': 'CUS-001',
        'customerName': 'Eco Mart Store',
        'contactPerson': 'Manager',
        'phone': '9822112233',
        'creditLimit': 50000.0,
        'openingBalance': 0.0,
        'isActive': true,
      };

      final dto = CustomerDto.fromJson(json);
      expect(dto.customerCode, 'CUS-001');
      expect(dto.customerName, 'Eco Mart Store');
      expect(dto.creditLimit, 50000.0);
    });
  });

  group('TransporterDto and VehicleDto', () {
    test('models logistics transporter and assigned fleet vehicle', () {
      final transJson = {
        'id': 5,
        'transporterCode': 'TR-001',
        'transporterName': 'ABC Transport Co.',
        'phone': '9822211222',
        'gstNumber': '23AACFA0123A1Z5',
        'isActive': true,
      };

      final transporter = TransporterDto.fromJson(transJson);
      expect(transporter.transporterCode, 'TR-001');
      expect(transporter.transporterName, 'ABC Transport Co.');

      final vehJson = {
        'id': 20,
        'transporterId': 5,
        'transporterName': 'ABC Transport Co.',
        'vehicleNumber': 'MP09AB1234',
        'driverName': 'Mohan Singh',
        'driverPhone': '9822211222',
        'vehicleType': 'Truck (10 Ton)',
        'isActive': true,
      };

      final vehicle = VehicleDto.fromJson(vehJson);
      expect(vehicle.vehicleNumber, 'MP09AB1234');
      expect(vehicle.transporterId, 5);
      expect(vehicle.driverName, 'Mohan Singh');
    });
  });

  group('PaymentMethodDto Model', () {
    test('parses payment modes correctly', () {
      final json = {
        'id': 1,
        'methodName': 'Bank Transfer',
        'description': 'NEFT / RTGS / IMPS direct transfer',
        'isActive': true,
      };

      final method = PaymentMethodDto.fromJson(json);
      expect(method.methodName, 'Bank Transfer');
      expect(method.isActive, true);
    });
  });
}
