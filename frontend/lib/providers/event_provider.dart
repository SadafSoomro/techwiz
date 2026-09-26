import 'package:flutter/material.dart';
import '../models/event_models.dart';
import '../models/json_utils.dart';
import '../services/event_service.dart';

/// MEMBER 4 - Events & Maps
/// Holds all state used by the Events, Calendar, Map, Categories and
/// Event Ticket screens, plus the simulated "current location".
class EventProvider extends ChangeNotifier {
  // -------------------- simulated device location --------------------
  /// Coordinates of the supported cities. The app uses these as the
  /// "current location" so distance / nearby discovery works without
  /// requiring a GPS permission (the SRS only needs city filtering,
  /// which this also powers).
  static const Map<String, List<double>> cityCoordinates = {
    'Karachi': [24.8607, 67.0011],
    'Lahore': [31.5204, 74.3587],
    'Islamabad': [33.6844, 73.0479],
    'Rawalpindi': [33.5651, 73.0169],
    'Faisalabad': [31.4180, 73.0790],
    'Multan': [30.1575, 71.5249],
    'Peshawar': [34.0151, 71.5249],
    'Quetta': [30.1798, 66.9750],
  };

  // ----------------------------- state -----------------------------
  bool _loading = false;
  String? _errorMessage;

  List<EventItem> _events = [];
  List<EventItem> _nearbyEvents = [];
  List<MapPin> _mapPins = [];
  List<EventCategory> _categories = [];
  List<EventCity> _cities = [];
  List<CalendarDay> _calendarDays = [];
  List<EventItem> _savedEvents = [];
  List<EventTicket> _myTickets = [];

  EventsStats _stats = const EventsStats();
  EventItem? _nextEvent;

  String _city = 'All';
  String _category = 'All';
  String _query = '';
  String _sort = 'date';
  bool _freeOnly = false;

  String _currentCity = 'Karachi';
  double _latitude = 24.8607;
  double _longitude = 67.0011;
  bool _usingDeviceLocation = false;

  late DateTime _calendarMonth;
  DateTime _selectedDay = DateTime.now();

  EventProvider() {
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month);
  }

  // ---------------------------- getters ----------------------------
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  List<EventItem> get events => _events;
  List<EventItem> get nearbyEvents => _nearbyEvents;
  List<MapPin> get mapPins => _mapPins;
  List<EventCategory> get categories => _categories;
  List<EventCity> get cities => _cities;
  List<CalendarDay> get calendarDays => _calendarDays;
  List<EventItem> get savedEvents => _savedEvents;
  List<EventTicket> get myTickets => _myTickets;

  EventsStats get stats => _stats;
  EventItem? get nextEvent => _nextEvent;

  String get city => _city;
  String get category => _category;
  String get query => _query;
  String get sort => _sort;
  bool get freeOnly => _freeOnly;

  String get currentCity => _currentCity;
  double get latitude => _latitude;
  double get longitude => _longitude;
  bool get usingDeviceLocation => _usingDeviceLocation;

  DateTime get calendarMonth => _calendarMonth;
  DateTime get selectedDay => _selectedDay;

  List<EventItem> get selectedDayEvents => _eventsOnDay(_selectedDay);

  /// Events on a given calendar day (used by the Calendar screen).
  List<EventItem> eventsOnDay(DateTime day) => _eventsOnDay(day);

  List<EventItem> _eventsOnDay(DateTime day) {
    final target =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    for (final entry in _calendarDays) {
      if (entry.date == target) return entry.events;
    }
    return const [];
  }

  String get calendarMonthKey =>
      '${_calendarMonth.year}-${_calendarMonth.month.toString().padLeft(2, '0')}';

  // ---------------------------- helpers ----------------------------
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Keeps every list in sync after a save / booking change.
  void _replaceEvent(EventItem updated) {
    List<EventItem> mapList(List<EventItem> list) => list
        .map((e) => e.id == updated.id
            ? e.copyWith(
                isSaved: updated.isSaved,
                attendeesCount: updated.attendeesCount,
                seatsLeft: updated.seatsLeft,
              )
            : e)
        .toList();

    _events = mapList(_events);
    _nearbyEvents = mapList(_nearbyEvents);
    _savedEvents = mapList(_savedEvents);
  }

  // ==================================================================
  // LOCATION (GPS simulation / city selection)
  // ==================================================================
  void setCityLocation(String city) {
    _currentCity = city;
    final coords = cityCoordinates[city];
    if (coords != null) {
      _latitude = coords[0];
      _longitude = coords[1];
    }
    _usingDeviceLocation = false;
    notifyListeners();
  }

  /// Simulated device fix used when no GPS plugin is bundled. Karachi is the
  /// app's home city.
  static const List<double> devicePosition = [24.8607, 67.0011];

  /// "Use my location" - picks the nearest supported city to the given
  /// point. A real GPS plugin can feed these coordinates later; until then we
  /// fall back to [devicePosition].
  ///
  /// Passing the *currently selected* city here (as the Map screen used to)
  /// made the button look broken, because it always snapped back to the same
  /// place.
  void useDeviceLocation({double? lat, double? lng}) {
    final fixLat = lat ?? devicePosition[0];
    final fixLng = lng ?? devicePosition[1];

    _latitude = fixLat;
    _longitude = fixLng;
    _usingDeviceLocation = true;

    String nearest = _currentCity;
    double smallest = double.infinity;

    cityCoordinates.forEach((name, coords) {
      final d = (coords[0] - fixLat).abs() + (coords[1] - fixLng).abs();
      if (d < smallest) {
        smallest = d;
        nearest = name;
      }
    });

    _currentCity = nearest;
    notifyListeners();
  }

  /// Re-centres the map on the device location and refreshes every
  /// location-aware list. Returns the city that was resolved.
  Future<String> recenterOnDeviceLocation() async {
    useDeviceLocation();
    await loadNearby(radiusKm: 2000);
    await loadMapPins();
    return _currentCity;
  }

  // ==================================================================
  // OVERVIEW
  // ==================================================================
  Future<void> loadOverview() async {
    final result = await EventService.overview();
    final data = result.data;
    if (result.success && data != null) {
      _stats = EventsStats.fromJson(parseMap(data['stats']) ?? const {});
      final next = parseMap(data['nextEvent']);
      _nextEvent = next == null ? null : EventItem.fromJson(next);
      notifyListeners();
    }
  }

  // ==================================================================
  // FILTERS
  // ==================================================================
  Future<void> loadFilters() async {
    final categoriesResult = await EventService.categories();
    if (categoriesResult.success && categoriesResult.data != null) {
      _categories = categoriesResult.data!;
    }

    final citiesResult = await EventService.cities();
    if (citiesResult.success && citiesResult.data != null) {
      _cities = citiesResult.data!;
    }

    notifyListeners();
  }

  // ==================================================================
  // EVENTS LIST
  // ==================================================================
  Future<void> loadEvents({
    String? city,
    String? category,
    String? query,
    String? sort,
    bool? freeOnly,
  }) async {
    _city = city ?? _city;
    _category = category ?? _category;
    _query = query ?? _query;
    _sort = sort ?? _sort;
    _freeOnly = freeOnly ?? _freeOnly;

    _setLoading(true);
    _errorMessage = null;

    final result = await EventService.events(
      city: _city == 'All' ? '' : _city,
      category: _category == 'All' ? '' : _category,
      query: _query,
      sort: _sort,
      freeOnly: _freeOnly,
      latitude: _sort == 'distance' ? _latitude : null,
      longitude: _sort == 'distance' ? _longitude : null,
    );

    if (result.success && result.data != null) {
      _events = result.data!;
    } else {
      _errorMessage = result.message;
    }

    _setLoading(false);
  }

  // ==================================================================
  // NEARBY (GPS discovery)
  // ==================================================================
  Future<void> loadNearby({double radiusKm = 150}) async {
    _setLoading(true);
    final result = await EventService.nearby(
      latitude: _latitude,
      longitude: _longitude,
      radiusKm: radiusKm,
    );

    if (result.success && result.data != null) {
      _nearbyEvents = result.data!;
    } else {
      _errorMessage = result.message;
    }
    _setLoading(false);
  }

  // ==================================================================
  // MAP PINS
  // ==================================================================
  Future<void> loadMapPins({String? city, String? category}) async {
    _setLoading(true);
    final result = await EventService.mapPins(
      city: (city ?? (_city == 'All' ? '' : _city)),
      category: (category ?? (_category == 'All' ? '' : _category)),
    );

    if (result.success && result.data != null) {
      _mapPins = result.data!;
    } else {
      _errorMessage = result.message;
    }
    _setLoading(false);
  }

  // ==================================================================
  // CALENDAR
  // ==================================================================
  Future<void> loadCalendar({DateTime? month, String? city, String? category}) async {
    if (month != null) _calendarMonth = DateTime(month.year, month.month);
    if (city != null) _city = city;
    if (category != null) _category = category;

    _setLoading(true);
    final result = await EventService.calendar(
      month: calendarMonthKey,
      city: _city == 'All' ? '' : _city,
      category: _category == 'All' ? '' : _category,
    );

    final data = result.data;
    if (result.success && data != null) {
      _calendarDays = parseList(data['days'], CalendarDay.fromJson);
    } else {
      _errorMessage = result.message;
    }
    _setLoading(false);
  }

  Future<void> changeMonth(int delta) async {
    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + delta);
    await loadCalendar();
  }

  void selectDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  /// Jumps the calendar to a date and loads that month.
  Future<void> goToMonth(DateTime day) async {
    _selectedDay = day;
    await loadCalendar(month: day);
  }

  // ==================================================================
  // SAVED / INTERESTED
  // ==================================================================
  Future<void> loadSavedEvents() async {
    _setLoading(true);
    final result = await EventService.savedEvents();
    if (result.success && result.data != null) {
      _savedEvents = result.data!;
    } else {
      _errorMessage = result.message;
    }
    _setLoading(false);
  }

  Future<EventResult<List<int>>> toggleSave(EventItem event) async {
    final result = await EventService.toggleSave(event.id);

    if (result.success && result.data != null) {
      _replaceEvent(event.copyWith(isSaved: result.data![0] == 1));

      // refresh the saved list lazily so the Saved screen stays correct
      if (result.data![0] == 1) {
        if (!_savedEvents.any((e) => e.id == event.id)) {
          _savedEvents = [..._savedEvents, event.copyWith(isSaved: true)];
        }
      } else {
        _savedEvents = _savedEvents.where((e) => e.id != event.id).toList();
      }

      _stats = EventsStats(
        upcomingEvents: _stats.upcomingEvents,
        cities: _stats.cities,
        featured: _stats.featured,
        mySaved: result.data![1],
        myTickets: _stats.myTickets,
      );

      notifyListeners();
    }

    return result;
  }

  // ==================================================================
  // TICKETS
  // ==================================================================
  Future<void> loadMyTickets() async {
    _setLoading(true);
    final result = await EventService.myTickets();
    if (result.success && result.data != null) {
      _myTickets = result.data!;
    } else {
      _errorMessage = result.message;
    }
    _setLoading(false);
  }

  Future<EventResult<EventTicket>> bookTicket({
    required int eventId,
    int quantity = 1,
  }) async {
    _setLoading(true);
    final result = await EventService.bookTicket(eventId: eventId, quantity: quantity);

    if (result.success) {
      await loadMyTickets();
      await loadOverview();
    } else {
      _errorMessage = result.message;
      _setLoading(false);
    }

    return result;
  }

  Future<EventResult<bool>> cancelTicket(int ticketId) async {
    final result = await EventService.cancelTicket(ticketId);
    if (result.success) {
      _myTickets = _myTickets.where((t) => t.id != ticketId).toList();
      notifyListeners();
    }
    return result;
  }

  /// Finds an existing confirmed ticket for an event (if any).
  EventTicket? ticketForEvent(int eventId) {
    for (final ticket in _myTickets) {
      if (ticket.eventId == eventId && ticket.isConfirmed) return ticket;
    }
    return null;
  }
}
