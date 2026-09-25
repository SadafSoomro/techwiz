import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/event_models.dart';
import '../models/json_utils.dart';
import 'auth_storage.dart';

/// MEMBER 4 - Events & Maps
/// Thin HTTP layer over the /api/events routes.
/// The JWT saved by the login flow is attached automatically, so the same
/// service works for public browsing and for personal data
/// (saved events, my tickets).
class EventResult<T> {
  final bool success;
  final String message;
  final T? data;

  EventResult({required this.success, required this.message, this.data});

  factory EventResult.failure(String message) =>
      EventResult(success: false, message: message);
}

class EventService {
  // ------------------------------------------------------------------
  // low level helpers
  // ------------------------------------------------------------------
  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>?> _send(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse(url).replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );

    final headers = await _headers();
    final encoded = body == null ? null : jsonEncode(body);

    late final http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(uri, headers: headers, body: encoded);
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: encoded);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers, body: encoded);
        break;
      default:
        response = await http.get(uri, headers: headers);
    }

    if (response.body.isEmpty) {
      return {'success': false, 'message': 'Empty response from server'};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ==================================================================
  // EVENTS LIST / DISCOVERY
  // ==================================================================

  /// Event listing with filters.
  /// [sort] = date | popular | price_low | price_high | distance | newest
  static Future<EventResult<List<EventItem>>> events({
    String city = '',
    String category = '',
    String query = '',
    String sort = 'date',
    String from = '',
    String to = '',
    bool freeOnly = false,
    bool featuredOnly = false,
    double? latitude,
    double? longitude,
    int limit = 40,
  }) async {
    try {
      final json = await _send('GET', ApiConfig.eventsUrl, query: {
        'city': city,
        'category': category,
        'q': query,
        'sort': sort,
        'from': from,
        'to': to,
        if (freeOnly) 'free': 1,
        if (featuredOnly) 'featured': 1,
        'lat': ?latitude,
        'lng': ?longitude,
        'limit': limit,
      });

      if (json?['success'] == true) {
        return EventResult(
          success: true,
          message: 'OK',
          data: parseList(json!['events'], EventItem.fromJson),
        );
      }
      return EventResult.failure(json?['message'] ?? 'Could not load events');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  /// GPS style discovery - returns events sorted by distance from a point.
  static Future<EventResult<List<EventItem>>> nearby({
    required double latitude,
    required double longitude,
    double radiusKm = 150,
  }) async {
    try {
      final json = await _send('GET', ApiConfig.eventsNearbyUrl, query: {
        'lat': latitude,
        'lng': longitude,
        'radius': radiusKm,
      });

      if (json?['success'] == true) {
        return EventResult(
          success: true,
          message: 'OK',
          data: parseList(json!['events'], EventItem.fromJson),
        );
      }
      return EventResult.failure(json?['message'] ?? 'Could not load nearby events');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  /// Light payload used to draw the pins on the Map screen.
  static Future<EventResult<List<MapPin>>> mapPins({
    String city = '',
    String category = '',
  }) async {
    try {
      final json = await _send('GET', ApiConfig.eventsMapUrl, query: {
        'city': city,
        'category': category,
      });

      if (json?['success'] == true) {
        return EventResult(
          success: true,
          message: 'OK',
          data: parseList(json!['pins'], MapPin.fromJson),
        );
      }
      return EventResult.failure(json?['message'] ?? 'Could not load map pins');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  static Future<EventResult<Map<String, dynamic>>> details(int eventId) async {
    try {
      final json = await _send('GET', ApiConfig.eventDetailsUrl(eventId));
      if (json?['success'] == true) {
        return EventResult(success: true, message: 'OK', data: json);
      }
      return EventResult.failure(json?['message'] ?? 'Event not found');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  // ==================================================================
  // FILTERS / CALENDAR / OVERVIEW
  // ==================================================================
  static Future<EventResult<List<EventCategory>>> categories() async {
    try {
      final json = await _send('GET', ApiConfig.eventsCategoriesUrl);
      if (json?['success'] == true) {
        return EventResult(
          success: true,
          message: 'OK',
          data: parseList(json!['categories'], EventCategory.fromJson),
        );
      }
      return EventResult.failure(json?['message'] ?? 'Could not load categories');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  static Future<EventResult<List<EventCity>>> cities() async {
    try {
      final json = await _send('GET', ApiConfig.eventsCitiesUrl);
      if (json?['success'] == true) {
        return EventResult(
          success: true,
          message: 'OK',
          data: parseList(json!['cities'], EventCity.fromJson),
        );
      }
      return EventResult.failure(json?['message'] ?? 'Could not load cities');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  /// [month] must be "YYYY-MM".
  static Future<EventResult<Map<String, dynamic>>> calendar({
    required String month,
    String city = '',
    String category = '',
  }) async {
    try {
      final json = await _send('GET', ApiConfig.eventsCalendarUrl, query: {
        'month': month,
        'city': city,
        'category': category,
      });

      if (json?['success'] == true) {
        return EventResult(success: true, message: 'OK', data: json);
      }
      return EventResult.failure(json?['message'] ?? 'Could not load the calendar');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  static Future<EventResult<Map<String, dynamic>>> overview() async {
    try {
      final json = await _send('GET', ApiConfig.eventsOverviewUrl);
      if (json?['success'] == true) {
        return EventResult(success: true, message: 'OK', data: json);
      }
      return EventResult.failure(json?['message'] ?? 'Could not load the overview');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  // ==================================================================
  // SAVED / INTERESTED
  // ==================================================================
  static Future<EventResult<List<EventItem>>> savedEvents() async {
    try {
      final json = await _send('GET', ApiConfig.eventsSavedUrl);
      if (json?['success'] == true) {
        return EventResult(
          success: true,
          message: 'OK',
          data: parseList(json!['events'], EventItem.fromJson),
        );
      }
      return EventResult.failure(json?['message'] ?? 'Could not load saved events');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  /// Toggle "Interested" -> returns [saved, totalSaved].
  static Future<EventResult<List<int>>> toggleSave(int eventId) async {
    try {
      final json = await _send('POST', ApiConfig.eventSaveUrl(eventId));
      if (json?['success'] == true) {
        return EventResult(
          success: true,
          message: json!['message'] ?? '',
          data: [
            json['saved'] == true ? 1 : 0,
            asInt(json['total_saved']),
          ],
        );
      }
      return EventResult.failure(json?['message'] ?? 'Could not update');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  // ==================================================================
  // TICKETS (simulated booking - no real payment, per the SRS scope)
  // ==================================================================
  static Future<EventResult<EventTicket>> bookTicket({
    required int eventId,
    int quantity = 1,
  }) async {
    try {
      final json = await _send(
        'POST',
        ApiConfig.eventBookTicketUrl(eventId),
        body: {'quantity': quantity},
      );

      final ticket = parseMap(json?['ticket']);
      if (json?['success'] == true && ticket != null) {
        return EventResult(
          success: true,
          message: json!['message'] ?? 'Booking confirmed',
          data: EventTicket.fromJson(ticket),
        );
      }
      return EventResult.failure(json?['message'] ?? 'Could not book the ticket');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  static Future<EventResult<List<EventTicket>>> myTickets() async {
    try {
      final json = await _send('GET', ApiConfig.eventsTicketsUrl);
      if (json?['success'] == true) {
        return EventResult(
          success: true,
          message: 'OK',
          data: parseList(json!['tickets'], EventTicket.fromJson),
        );
      }
      return EventResult.failure(json?['message'] ?? 'Could not load your tickets');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  static Future<EventResult<EventTicket>> ticket(int ticketId) async {
    try {
      final json = await _send('GET', ApiConfig.eventTicketUrl(ticketId));
      final ticket = parseMap(json?['ticket']);
      if (json?['success'] == true && ticket != null) {
        return EventResult(
          success: true,
          message: 'OK',
          data: EventTicket.fromJson(ticket),
        );
      }
      return EventResult.failure(json?['message'] ?? 'Ticket not found');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }

  static Future<EventResult<bool>> cancelTicket(int ticketId) async {
    try {
      final json = await _send('DELETE', ApiConfig.eventTicketUrl(ticketId));
      if (json?['success'] == true) {
        return EventResult(
          success: true,
          message: json!['message'] ?? 'Ticket cancelled',
          data: true,
        );
      }
      return EventResult.failure(json?['message'] ?? 'Could not cancel the ticket');
    } catch (e) {
      return EventResult.failure('Network error ($e)');
    }
  }
}
