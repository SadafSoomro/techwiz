/// MEMBER 4 - Events & Maps
/// Data models mapped from the Node/Express + SQLite event responses.
library;

import 'json_utils.dart';

// ---------------------------------------------------------------------------
// EventItem
// ---------------------------------------------------------------------------
class EventItem {
  final int id;
  final String title;
  final String description;
  final String category;
  final String city;
  final String venue;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String eventDate;
  final String? endDate;
  final String startTime;
  final String endTime;
  final String? ticketLink;
  final double ticketPrice;
  final String currency;
  final String? imageUrl;
  final String organizer;
  final int capacity;
  final int attendeesCount;
  final bool isFeatured;
  final String status;
  final double? distanceKm;
  final int daysUntil;
  final int seatsLeft;
  final bool isSaved;
  final int savesCount;
  final int ticketsSold;

  const EventItem({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Fan Convention',
    this.city = '',
    this.venue = '',
    this.address,
    this.latitude,
    this.longitude,
    this.eventDate = '',
    this.endDate,
    this.startTime = '10:00',
    this.endTime = '18:00',
    this.ticketLink,
    this.ticketPrice = 0,
    this.currency = 'PKR',
    this.imageUrl,
    this.organizer = '',
    this.capacity = 0,
    this.attendeesCount = 0,
    this.isFeatured = false,
    this.status = 'upcoming',
    this.distanceKm,
    this.daysUntil = 0,
    this.seatsLeft = 0,
    this.isSaved = false,
    this.savesCount = 0,
    this.ticketsSold = 0,
  });

  bool get isFree => ticketPrice <= 0;
  bool get hasCoordinates => latitude != null && longitude != null;
  bool get isMultiDay => endDate != null && endDate!.isNotEmpty && endDate != eventDate;
  String get initial => title.trim().isEmpty ? 'E' : title.trim()[0].toUpperCase();

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: asInt(json['id']),
      title: asString(json['title'], fallback: 'Untitled event'),
      description: asString(json['description']),
      category: asString(json['category'], fallback: 'Fan Convention'),
      city: asString(json['city']),
      venue: asString(json['venue']),
      address: asNullableString(json['address']),
      latitude: asNullableDouble(json['latitude']),
      longitude: asNullableDouble(json['longitude']),
      eventDate: asString(json['event_date']),
      endDate: asNullableString(json['end_date']),
      startTime: asString(json['start_time'], fallback: '10:00'),
      endTime: asString(json['end_time'], fallback: '18:00'),
      ticketLink: asNullableString(json['ticket_link']),
      ticketPrice: asDouble(json['ticket_price']),
      currency: asString(json['currency'], fallback: 'PKR'),
      imageUrl: asNullableString(json['image_url']),
      organizer: asString(json['organizer']),
      capacity: asInt(json['capacity']),
      attendeesCount: asInt(json['attendees_count']),
      isFeatured: asBool(json['is_featured']),
      status: asString(json['status'], fallback: 'upcoming'),
      distanceKm: asNullableDouble(json['distance_km']),
      daysUntil: asInt(json['days_until']),
      seatsLeft: asInt(json['seats_left']),
      isSaved: asBool(json['is_saved']),
      savesCount: asInt(json['saves_count']),
      ticketsSold: asInt(json['tickets_sold']),
    );
  }

  EventItem copyWith({bool? isSaved, int? attendeesCount, int? seatsLeft}) {
    return EventItem(
      id: id,
      title: title,
      description: description,
      category: category,
      city: city,
      venue: venue,
      address: address,
      latitude: latitude,
      longitude: longitude,
      eventDate: eventDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      ticketLink: ticketLink,
      ticketPrice: ticketPrice,
      currency: currency,
      imageUrl: imageUrl,
      organizer: organizer,
      capacity: capacity,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      isFeatured: isFeatured,
      status: status,
      distanceKm: distanceKm,
      daysUntil: daysUntil,
      seatsLeft: seatsLeft ?? this.seatsLeft,
      isSaved: isSaved ?? this.isSaved,
      savesCount: savesCount,
      ticketsSold: ticketsSold,
    );
  }
}

// ---------------------------------------------------------------------------
// EventCategory
// ---------------------------------------------------------------------------
class EventCategory {
  final String name;
  final String icon;
  final String color;
  final String description;
  final int eventsCount;

  const EventCategory({
    required this.name,
    this.icon = '',
    this.color = '',
    this.description = '',
    this.eventsCount = 0,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      name: asString(json['name']),
      icon: asString(json['icon']),
      color: asString(json['color']),
      description: asString(json['description']),
      eventsCount: asInt(json['events_count']),
    );
  }
}

// ---------------------------------------------------------------------------
// EventCity
// ---------------------------------------------------------------------------
class EventCity {
  final String city;
  final int eventsCount;
  final double? latitude;
  final double? longitude;

  const EventCity({
    required this.city,
    this.eventsCount = 0,
    this.latitude,
    this.longitude,
  });

  factory EventCity.fromJson(Map<String, dynamic> json) {
    return EventCity(
      city: asString(json['city']),
      eventsCount: asInt(json['events_count']),
      latitude: asNullableDouble(json['latitude']),
      longitude: asNullableDouble(json['longitude']),
    );
  }
}

// ---------------------------------------------------------------------------
// MapPin  (light payload used by the Map screen)
// ---------------------------------------------------------------------------
class MapPin {
  final int id;
  final String title;
  final String category;
  final String city;
  final String venue;
  final double latitude;
  final double longitude;
  final String eventDate;
  final String startTime;
  final double ticketPrice;
  final String currency;
  final bool isFeatured;

  const MapPin({
    required this.id,
    required this.title,
    this.category = '',
    this.city = '',
    this.venue = '',
    this.latitude = 0,
    this.longitude = 0,
    this.eventDate = '',
    this.startTime = '10:00',
    this.ticketPrice = 0,
    this.currency = 'PKR',
    this.isFeatured = false,
  });

  factory MapPin.fromJson(Map<String, dynamic> json) {
    return MapPin(
      id: asInt(json['id']),
      title: asString(json['title'], fallback: 'Event'),
      category: asString(json['category']),
      city: asString(json['city']),
      venue: asString(json['venue']),
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
      eventDate: asString(json['event_date']),
      startTime: asString(json['start_time'], fallback: '10:00'),
      ticketPrice: asDouble(json['ticket_price']),
      currency: asString(json['currency'], fallback: 'PKR'),
      isFeatured: asBool(json['is_featured']),
    );
  }
}

// ---------------------------------------------------------------------------
// EventTicket
// ---------------------------------------------------------------------------
class EventTicket {
  final int id;
  final String ticketCode;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String currency;
  final String seatNumber;
  final String status;
  final String bookedAt;
  final String bookedAgo;
  final int eventId;
  final String title;
  final String category;
  final String city;
  final String venue;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String eventDate;
  final String? endDate;
  final String startTime;
  final String endTime;
  final String organizer;
  final int daysUntil;

  const EventTicket({
    required this.id,
    required this.ticketCode,
    this.quantity = 1,
    this.unitPrice = 0,
    this.totalPrice = 0,
    this.currency = 'PKR',
    this.seatNumber = '',
    this.status = 'confirmed',
    this.bookedAt = '',
    this.bookedAgo = '',
    this.eventId = 0,
    this.title = '',
    this.category = '',
    this.city = '',
    this.venue = '',
    this.address,
    this.latitude,
    this.longitude,
    this.eventDate = '',
    this.endDate,
    this.startTime = '10:00',
    this.endTime = '18:00',
    this.organizer = '',
    this.daysUntil = 0,
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isFree => totalPrice <= 0;
  String get initial => title.trim().isEmpty ? 'E' : title.trim()[0].toUpperCase();

  factory EventTicket.fromJson(Map<String, dynamic> json) {
    return EventTicket(
      id: asInt(json['id']),
      ticketCode: asString(json['ticket_code']),
      quantity: asInt(json['quantity']),
      unitPrice: asDouble(json['unit_price']),
      totalPrice: asDouble(json['total_price']),
      currency: asString(json['currency'], fallback: 'PKR'),
      seatNumber: asString(json['seat_number']),
      status: asString(json['status'], fallback: 'confirmed'),
      bookedAt: asString(json['booked_at']),
      bookedAgo: asString(json['booked_ago']),
      eventId: asInt(json['event_id']),
      title: asString(json['title']),
      category: asString(json['category']),
      city: asString(json['city']),
      venue: asString(json['venue']),
      address: asNullableString(json['address']),
      latitude: asNullableDouble(json['latitude']),
      longitude: asNullableDouble(json['longitude']),
      eventDate: asString(json['event_date']),
      endDate: asNullableString(json['end_date']),
      startTime: asString(json['start_time'], fallback: '10:00'),
      endTime: asString(json['end_time'], fallback: '18:00'),
      organizer: asString(json['organizer']),
      daysUntil: asInt(json['days_until']),
    );
  }
}

// ---------------------------------------------------------------------------
// CalendarDay  (events grouped per day)
// ---------------------------------------------------------------------------
class CalendarDay {
  final String date;
  final int count;
  final List<EventItem> events;

  const CalendarDay({required this.date, this.count = 0, this.events = const []});

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: asString(json['date']),
      count: asInt(json['count']),
      events: parseList(json['events'], EventItem.fromJson),
    );
  }

  DateTime? get dateTime => DateTime.tryParse(date);
}

// ---------------------------------------------------------------------------
// EventsStats  (header counters on the Events screen)
// ---------------------------------------------------------------------------
class EventsStats {
  final int upcomingEvents;
  final int cities;
  final int featured;
  final int mySaved;
  final int myTickets;

  const EventsStats({
    this.upcomingEvents = 0,
    this.cities = 0,
    this.featured = 0,
    this.mySaved = 0,
    this.myTickets = 0,
  });

  factory EventsStats.fromJson(Map<String, dynamic> json) {
    return EventsStats(
      upcomingEvents: asInt(json['upcoming_events']),
      cities: asInt(json['cities']),
      featured: asInt(json['featured']),
      mySaved: asInt(json['my_saved']),
      myTickets: asInt(json['my_tickets']),
    );
  }
}
