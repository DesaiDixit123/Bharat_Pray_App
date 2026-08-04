import 'package:flutter_test/flutter_test.dart';
import 'package:bharat_pray/models/yatra_model.dart';
import 'package:bharat_pray/models/journey_models.dart';

void main() {
  group('YatraModel JSON Parsing & Null Safety Tests', () {
    test('Parses valid Popular Yatra JSON correctly', () {
      final json = {
        '_id': '66b1a2f91234567890abcdef',
        'title': 'Char Dham Yatra',
        'slug': 'char-dham-yatra',
        'description': 'Sacred pilgrimage to four holy shrines',
        'distance': 1250,
        'walkingSteps': 150000,
        'duration': 14,
        'followersCount': 12450,
        'image': 'https://api.bharatpray.com/uploads/yatra/chardham.jpg',
        'banner': 'https://api.bharatpray.com/uploads/yatra/chardham_banner.jpg',
        'templeLocation': {
          'latitude': 30.7346,
          'longitude': 79.0669,
          'address': 'Kedarnath, Uttarakhand'
        },
        'status': true,
        'isPopular': true,
        'priority': 10,
        'displayOrder': 1,
      };

      final model = YatraModel.fromJson(json);

      expect(model.id, equals('66b1a2f91234567890abcdef'));
      expect(model.title, equals('Char Dham Yatra'));
      expect(model.estimatedDaysNum, equals(14));
      expect(model.estimatedStepsNum, equals(150000));
      expect(model.followersCountNum, equals(12450));
      expect(model.priority, equals(10));
      expect(model.displayOrder, equals(1));
      expect(model.isPopular, isTrue);
      expect(model.status, isTrue);
      expect(model.templeLocation?.latitude, equals(30.7346));
    });

    test('Handles missing keys and null values safely without crashing', () {
      final json = <String, dynamic>{
        '_id': null,
        'title': null,
        'distance': null,
        'walkingSteps': null,
        'duration': null,
        'followersCount': null,
        'templeLocation': null,
      };

      final model = YatraModel.fromJson(json);

      expect(model.id, isNotEmpty);
      expect(model.title, equals('Devotional Yatra'));
      expect(model.distance, equals('0 KM'));
      expect(model.steps, equals('0 Steps'));
      expect(model.duration, equals('1 Day'));
      expect(model.estimatedDaysNum, equals(1));
      expect(model.status, isTrue);
    });

    test('Handles unexpected data types defensively', () {
      final json = {
        '_id': 12345, // int instead of string
        'title': 9999, // int instead of string
        'distance': '120.5', // string instead of double
        'walkingSteps': '45000', // string instead of int
        'duration': '7', // string instead of int
        'priority': '5', // string instead of int
        'displayOrder': '2', // string instead of int
        'status': 'true', // string instead of bool
        'isPopular': 'true', // string instead of bool
      };

      final model = YatraModel.fromJson(json);

      expect(model.id, equals('12345'));
      expect(model.title, equals('9999'));
      expect(model.estimatedStepsNum, equals(45000));
      expect(model.estimatedDaysNum, equals(7));
      expect(model.priority, equals(5));
      expect(model.displayOrder, equals(2));
      expect(model.status, isTrue);
      expect(model.isPopular, isTrue);
    });
  });

  group('ContinueYatraModel JSON Parsing Tests', () {
    test('Parses active running journey JSON correctly', () {
      final json = {
        'journeyId': 'j_777',
        'routeId': 'r_888',
        'title': 'Somnath Pilgrimage Yatra',
        'coverImage': 'https://api.bharatpray.com/uploads/yatra/somnath.jpg',
        'totalDistanceMeters': 50000.0,
        'accumulatedDistanceMeters': 22500.0,
        'remainingDistanceMeters': 27500.0,
        'accumulatedSteps': 32000,
        'progressPercent': 45.0,
        'currentDay': 3,
        'estimatedDays': 7,
        'status': 'STARTED',
      };

      final model = ContinueYatraModel.fromJson(json);

      expect(model.journeyId, equals('j_777'));
      expect(model.routeId, equals('r_888'));
      expect(model.title, equals('Somnath Pilgrimage Yatra'));
      expect(model.accumulatedDistanceMeters, equals(22500.0));
      expect(model.remainingDistanceMeters, equals(27500.0));
      expect(model.progressPercent, equals(45.0));
      expect(model.currentDay, equals(3));
      expect(model.estimatedDays, equals(7));
      expect(model.status, equals('STARTED'));
      expect(model.distanceCoveredKm, equals('22.5 KM'));
      expect(model.remainingDistanceKm, equals('27.5 KM'));
    });

    test('Handles empty and invalid JSON defensively', () {
      final model = ContinueYatraModel.fromJson(null);

      expect(model.title, equals('Active Yatra'));
      expect(model.status, equals('STARTED'));
      expect(model.progressPercent, equals(0.0));
    });
  });

  group('PaginationModel & ApiResponseModel Tests', () {
    test('Parses pagination payload correctly', () {
      final json = {
        'page': 2,
        'limit': 10,
        'totalDocs': 35,
        'totalPages': 4,
        'hasNextPage': true,
        'hasPrevPage': true,
      };

      final model = PaginationModel.fromJson(json);

      expect(model.page, equals(2));
      expect(model.limit, equals(10));
      expect(model.totalDocs, equals(35));
      expect(model.totalPages, equals(4));
      expect(model.hasNextPage, isTrue);
      expect(model.hasPrevPage, isTrue);
    });

    test('ApiResponseModel parses generic data envelope', () {
      final json = {
        'IsSuccess': true,
        'Status': 200,
        'Message': 'Popular yatras loaded',
        'Data': {
          'docs': [
            {
              '_id': 'y1',
              'title': 'Kedarnath Pilgrimage',
              'distance': 14.5,
              'walkingSteps': 22000,
              'duration': 3,
            }
          ],
          'totalDocs': 1,
          'limit': 10,
          'page': 1,
          'totalPages': 1
        }
      };

      final response = ApiResponseModel<List<YatraModel>>.fromJson(
        json,
        (dataJson) {
          final docs = dataJson['docs'] as List;
          return docs.map((d) => YatraModel.fromJson(d)).toList();
        },
      );

      expect(response.isSuccess, isTrue);
      expect(response.statusCode, equals(200));
      expect(response.message, equals('Popular yatras loaded'));
      expect(response.data, isNotNull);
      expect(response.data!.length, equals(1));
      expect(response.data!.first.title, equals('Kedarnath Pilgrimage'));
      expect(response.pagination?.totalDocs, equals(1));
    });
  });
}
