import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mat_month_picker_dialog/mat_month_picker_dialog.dart';
import 'calendar_day_slot_navigator.dart';
import 'date_functions.dart';

/// Enum for choosing the month page index.
enum MonthType {
  selected,
  previous,
  next,
}

/// StatefulWidget for displaying and interacting with a calendar with selectable date ranges.
class SelectedDateRangeWidget extends StatefulWidget {
  /// Number of days shown in each slot.
  final int? slotLength;

  /// Color for highlighting selected dates.
  final Color? activeColor;

  /// show other dates
  final Color? deActiveColor;

  /// Color for non-selected dates.
  final bool? isGradientColor;

  /// Gradient for selected date highlighting.
  final LinearGradient? activeGradientColor;

  /// Gradient for non-selected dates.
  final LinearGradient? deActiveGradientColor;

  /// Border radius for the day boxes.
  final double? dayBoxBorderRadius;

  /// Border radius for the tabs switching months and years.
  final double? monthYearTabBorderRadius;

  /// Customizable header text.
  final String? headerText;

  /// Callback function when a date is selected.
  final Function(DateTime selectedDate)? onDateSelect;

  /// List of specific dates to enable or disable.
  final List<DateTime>? rangeDates;

  /// Enum for different date selection scenarios.
  final DateSelectionType? dateSelectionType;

  /// there are 2 types of design variants DayDisplayMode.outsideDateBox, DayDisplayMode.inDateBox
  final DayDisplayMode? dayDisplayMode;

  /// Custom text style.
  final TextStyle? textStyle;

  ///  Border width for the day boxes.
  final double? dayBorderWidth;

  /// Aspect ratio for the height of day boxes.
  final double? dayBoxHeightAspectRatio;

  /// show month in day box
  final bool? showMonthInDayBox;

  /// show arrow for change day slots
  final bool showarrow;

  /// initial selected date
  final DateTime? initialSelectedDate;

  const SelectedDateRangeWidget(
      {super.key,
      this.slotLength,
      this.activeColor,
      this.deActiveColor,
      this.isGradientColor,
      this.activeGradientColor,
      this.deActiveGradientColor,
      this.dayBoxBorderRadius,
      this.monthYearTabBorderRadius,
      this.headerText,
      this.onDateSelect,
      this.rangeDates,
      this.dateSelectionType,
      this.dayDisplayMode,
      this.textStyle,
      this.dayBorderWidth,
      this.dayBoxHeightAspectRatio,
      this.showMonthInDayBox = false,
      this.showarrow = true,
      this.initialSelectedDate});

  @override
  State<SelectedDateRangeWidget> createState() =>
      _SelectedDateRangeWidgetState();
}

/// Private State class for SelectedDateRangeWidget to manage its state.
class _SelectedDateRangeWidgetState extends State<SelectedDateRangeWidget> {
  String? dailyDate;
  DateTime? yearSelected;
  DateTime? monthSelected;
  int dateSelected = 0;
  var month = DateTime.now().month;
  List<List<DateTime>> listDate = [];
  List<DateTime> dates = [];
  var year = DateTime.now().year;
  var weekDays = [];
  bool isPreviousArrow = true;
  bool isNextArrow = true;
  int days = 0;
  int pageIndex = 0;
  DateTime nullDateTime = DateTime(0001, 1, 1);
  DateTime selectedDate = DateTime.now();
  // DateTime todayDate = DateTime.now();

  /// PageController to control the visible month.
  PageController pageController =
      PageController(viewportFraction: 1, keepPage: true);
  String? selectMonth;
  String? selectYear;
  final currentMonth = DateFormat('MMMM').format(DateTime.now());

  int slotLengthLocal = 0;

  @override
  void didUpdateWidget(covariant SelectedDateRangeWidget oldWidget) {
    if (widget.slotLength != oldWidget.slotLength) {
      slotLengthLocal = widget.slotLength!;
      nullDateTime = DateTime(0001, 1, 1);
      selectedDate = widget.initialSelectedDate ?? DateTime.now();
      // todayDate = DateTime.now();
      getDatesInMonth(selectedDate, MonthType.selected);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialSelectedDate ?? DateTime.now();
    slotLengthLocal = widget.slotLength!;

    /// initialize page view controller
    pageController = PageController(viewportFraction: 1, keepPage: true);

    /// Default today's date as selected.
    dateSelected = DateTime.now().day;

    /// Get all dates from current month.
    getDatesInMonth(selectedDate, MonthType.selected);

    /// Add listener to update arrows based on page position.
    pageController.addListener(
      () {
        if ((pageController.position.pixels ==
            pageController.position.maxScrollExtent)) {
          isNextArrow = true;
          setState(() {});
        } else {
          isNextArrow = false;
          setState(() {});
        }
        if ((pageController.position.pixels ==
            pageController.position.minScrollExtent)) {
          isPreviousArrow = true;
          setState(() {});
        } else {
          isPreviousArrow = false;
          setState(() {});
        }
      },
    );
  }

  /// Get all dates for the given month and organize them into weeks
  void getDatesInMonth(DateTime date, MonthType type) {
    listDate.clear();
    dates.clear();
    weekDays.clear();

    DateTime firstDayOfMonth = DateTime(date.year, date.month, 1);
    DateTime lastDayOfMonth = DateTime(date.year, date.month + 1, 0);

    if (date.month == DateTime.now().month &&
        date.year == DateTime.now().year) {
      dateSelected = DateTime.now().day;
    }

    selectMonth = DateFormat("MMMM").format(date);

    /// Set year tab text and dialog box initial values.
    year = date.year;

    monthSelected = date;
    yearSelected = date;

    final difference = lastDayOfMonth.difference(firstDayOfMonth);
    for (int i = 0; i <= difference.inDays; i++) {
      var currentDay = firstDayOfMonth.add(Duration(days: i));
      dates.add(currentDay);
      weekDays.add(DateFormat('EEE').format(currentDay));
    }

    int pageLength = (dates.length / slotLengthLocal).ceil();
    for (var i = 0; i < pageLength; i++) {
      var localList = dates.sublist(
        i * slotLengthLocal,
        (i * slotLengthLocal + slotLengthLocal) > dates.length
            ? dates.length
            : (i * slotLengthLocal + slotLengthLocal),
      );

      // Add remaining dates in slots if any.
      if (localList.length < slotLengthLocal) {
        int totalBlankDateSlots = slotLengthLocal - localList.length;
        int i = 0;
        do {
          localList.add(DateTime(0001, 1, 1));
          i++;
        } while (i < totalBlankDateSlots);
      }
      listDate.add(localList);
    }
    setPage(date, type);
  }

  /// Set the page index based on the selected date and update navigation flags.
  void setPage(DateTime date, MonthType type) {
    days = date.day;
    dailyDate = DateFormat("d/M/yyyy").format(date);

    switch (type) {
      case MonthType.selected:
        {
          int currentDatePageIndex = -1;
          for (int i = 0; i < listDate.length; i++) {
            if (listDate[i]
                .contains(DateTime(date.year, date.month, date.day))) {
              currentDatePageIndex = i;
              break;
            }
          }
          pageIndex = currentDatePageIndex;
          break;
        }

      case MonthType.previous:
        pageIndex = listDate.length - 1;
        break;

      case MonthType.next:
        pageIndex = 0;
        break;
    }

    ///show previous next date slot call back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.jumpToPage(pageIndex);
      }
    });

    setState(() {});
  }

  /// Determines if a date should be active or disabled based on DateSelectionType.
  bool isDateActive(DateTime date) {
    switch (widget.dateSelectionType) {
      case DateSelectionType.activeAllDates:
        return true;

      case DateSelectionType.activePastDates:
        return DateFunctions.isPastDate(date);

      case DateSelectionType.activeFutureDates:
        return DateFunctions.isFutureDate(date);

      case DateSelectionType.activeTodayAndPastDates:
        return DateFunctions.isTodayAndPastDate(date);

      case DateSelectionType.activeTodayAndFutureDates:
        return DateFunctions.isTodayAndFutureDate(date);

      case DateSelectionType.activeRangeDates:
        return (widget.rangeDates!
                .where((e) => DateFunctions.isSameDates(e, date))
                .toList()
                .isNotEmpty)
            ? true
            : false;

      case DateSelectionType.deActiveRangeDates:
        return (widget.rangeDates!
                .where((e) => DateFunctions.isSameDates(e, date))
                .toList()
                .isNotEmpty)
            ? false
            : true;

      default:
        return true;
    }
  }

  /// Navigate to the previous month's view.
  void funcSetPreviousMonth() {
    if (pageController.page == 0.0) {
      if (listDate.isNotEmpty) {
        DateTime varYesterdayDate =
            listDate.first.first.subtract(const Duration(days: 1));
        getDatesInMonth(varYesterdayDate, MonthType.previous);
      }
    }
  }

  /// Navigate to the next month's view.
  void funcSetNextMonth() {
    if (pageController.page == listDate.length - 1) {
      if (listDate.isNotEmpty) {
        DateTime varTomorrowDate = listDate.last
            .where((e) => e != nullDateTime)
            .toList()
            .last
            .add(const Duration(days: 1));
        getDatesInMonth(varTomorrowDate, MonthType.next);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double parentWidth = constraints.maxWidth;
        final double sw = parentWidth / 100;
        return SizedBox(
            width: parentWidth,
            child: Column(
              children: [
                /// Header text, month and year selection tabs.
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                  child: Row(
                    children: [
                      // Display header text.
                      Expanded(
                        child: Text(
                          widget.headerText!,
                          style: widget.textStyle!.copyWith(
                              fontSize: 14.0,
                              color: widget.activeColor,
                              fontWeight: FontWeight.w500),
                        ),
                      ),

                      // Month selection interactive tab.
                      InkWell(
                        onTap: () async {
                          var selected = await showMonthPicker(
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: widget.activeColor!,
                                    secondary: widget.deActiveColor!,
                                    onSurface: widget.activeColor!,
                                    onPrimary: widget.deActiveColor!,
                                  ),
                                  dialogTheme: DialogThemeData(
                                      backgroundColor: widget.activeColor!),
                                  textTheme: TextTheme(
                                    headlineSmall: widget.textStyle,
                                    titleLarge: widget.textStyle,
                                    labelSmall: widget.textStyle,
                                    bodyLarge: widget.textStyle,
                                    titleMedium: widget.textStyle,
                                    titleSmall: widget.textStyle,
                                    bodySmall: widget.textStyle,
                                    labelLarge: widget.textStyle!
                                        .copyWith(color: Colors.white),
                                    bodyMedium: widget.textStyle,
                                    displayLarge: widget.textStyle,
                                    displayMedium: widget.textStyle,
                                    displaySmall: widget.textStyle,
                                    headlineMedium: widget.textStyle,
                                    headlineLarge: widget.textStyle,
                                    labelMedium: widget.textStyle,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: widget.activeColor!,
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                            context: context,
                            firstDate: DateTime(1900, 1, 1),
                            lastDate: DateTime(2050, 12, 31),
                            initialDate: monthSelected ?? DateTime.now(),
                          );
                          if (selected != null) {
                            dates.clear();
                            setState(() {
                              monthSelected = selected;
                              yearSelected = selected;
                              month = selected.month;
                              year = selected.year;
                              selectMonth = DateFormat('MMMM').format(selected);
                              getDatesInMonth(selected, MonthType.selected);
                            });
                          }
                        },
                        child: Container(
                          decoration: !widget.isGradientColor!
                              ? BoxDecoration(
                                  color: widget.activeColor,
                                  borderRadius: BorderRadius.circular(
                                      widget.monthYearTabBorderRadius!),
                                )
                              : BoxDecoration(
                                  gradient: widget.activeGradientColor,
                                  borderRadius: BorderRadius.circular(
                                      widget.monthYearTabBorderRadius!),
                                ),
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: Row(
                            children: [
                              Text(
                                selectMonth ?? currentMonth,
                                style: widget.textStyle!.copyWith(
                                    color: widget.deActiveColor!,
                                    fontSize: 12.0),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: widget.deActiveColor!,
                                size: sw * 3,
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// Year selection interactive tab
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: InkWell(
                          onTap: () async {
                            var selected = await showDatePicker(
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: widget.activeColor!,
                                      onPrimary: widget.deActiveColor!,
                                      onSurface: widget.activeColor!,
                                      surface: widget.deActiveColor!,
                                    ),
                                    dialogTheme: DialogThemeData(
                                        backgroundColor: widget.deActiveColor!),
                                    textTheme: TextTheme(
                                      headlineSmall: widget.textStyle,
                                      titleLarge: widget.textStyle,
                                      labelSmall: widget.textStyle,
                                      bodyLarge: widget.textStyle,
                                      titleMedium: widget.textStyle,
                                      titleSmall: widget.textStyle,
                                      bodySmall: widget.textStyle,
                                      labelLarge: widget.textStyle!
                                          .copyWith(color: widget.activeColor!),
                                      bodyMedium: widget.textStyle,
                                      displayLarge: widget.textStyle,
                                      displayMedium: widget.textStyle,
                                      displaySmall: widget.textStyle,
                                      headlineMedium: widget.textStyle,
                                      headlineLarge: widget.textStyle,
                                      labelMedium: widget.textStyle,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: widget.activeColor!,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                              context: context,
                              firstDate: DateTime(1900, 1, 1),
                              lastDate: DateTime(2050, 12, 31),
                              initialDate: yearSelected ?? DateTime.now(),
                              initialDatePickerMode: DatePickerMode.year,
                            );
                            if (selected != null) {
                              setState(() {
                                yearSelected = selected;
                                year = selected.year;
                                getDatesInMonth(selected, MonthType.selected);
                                monthSelected = selected;
                                selectMonth =
                                    DateFormat('MMMM').format(selected);
                                selectedDate = selected;
                                widget.onDateSelect!(selectedDate);
                              });
                            }
                          },
                          child: Container(
                            decoration: !widget.isGradientColor!
                                ? BoxDecoration(
                                    color: widget.activeColor,
                                    borderRadius: BorderRadius.circular(
                                        widget.monthYearTabBorderRadius!),
                                  )
                                : BoxDecoration(
                                    gradient: widget.activeGradientColor,
                                    borderRadius: BorderRadius.circular(
                                        widget.monthYearTabBorderRadius!),
                                  ),
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                            child: Row(
                              children: [
                                Text(
                                  year.toString(),
                                  style: widget.textStyle!.copyWith(
                                      color: widget.deActiveColor!,
                                      fontSize: 12.0),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: widget.deActiveColor!,
                                  size: sw * 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Container for navigation arrows and calendar days.
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ///show previous calendar slot
                      Column(
                        children: [
                          widget.dayDisplayMode == DayDisplayMode.outsideDateBox
                              ? Text(
                                  "",
                                  style: widget.textStyle!.copyWith(
                                    fontSize: 11.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                )
                              : const SizedBox(),
                          widget.showarrow
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      pageController.previousPage(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        curve: Curves.ease,
                                      );
                                    });
                                    funcSetPreviousMonth();
                                  },
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: sw),
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      color: widget.activeColor,
                                      size: sw * 5,
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: sw * 5,
                                ),
                        ],
                      ),

                      /// Display the calendar day slots within a PageView builder.
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: widget.dayBoxHeightAspectRatio! > 9
                              ? 9
                              : widget.dayBoxHeightAspectRatio!,
                          child: PageView.builder(
                            controller: pageController,
                            itemCount: listDate.length,
                            itemBuilder: (context, index) {
                              return Row(
                                children: listDate[index].map((date) {
                                  bool isActive = isDateActive(date);
                                  bool isSelected = date.day ==
                                              selectedDate.day &&
                                          date.month == selectedDate.month &&
                                          date.year == selectedDate.year
                                      ? true
                                      : false;

                                  if (date.day == selectedDate.day &&
                                      !isActive) {
                                    isSelected = false;
                                  }

                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 5, right: 5),
                                      child:
                                          DateFormat('yyyy').format(date) ==
                                                  "0001"
                                              ? const SizedBox()
                                              : GestureDetector(
                                                  onTap: !isActive
                                                      ? null
                                                      : () {
                                                          setState(() {
                                                            selectedDate = date;
                                                            dateSelected =
                                                                date.day;
                                                            dailyDate = DateFormat(
                                                                    "d/M/yyyy")
                                                                .format(date);
                                                            if (widget
                                                                    .onDateSelect !=
                                                                null) {
                                                              widget.onDateSelect!(
                                                                  date);
                                                            }
                                                          });
                                                        },
                                                  child:

                                                      /// Layout 1: Display mode for day outside date box.
                                                      widget.dayDisplayMode ==
                                                              DayDisplayMode
                                                                  .outsideDateBox
                                                          ? Column(
                                                              children: [
                                                                Text(
                                                                  DateFormat(
                                                                          'EEE')
                                                                      .format(
                                                                          date),
                                                                  style: widget
                                                                      .textStyle!
                                                                      .copyWith(
                                                                    fontSize:
                                                                        11.0,
                                                                    color: isActive
                                                                        ? (DateFunctions.isToDayDate(date)
                                                                            ? widget.activeColor // Highlight today's weekday
                                                                            : widget.activeColor)
                                                                        : widget.activeColor!.withValues(alpha: 0.5),
                                                                    fontWeight: DateFunctions.isToDayDate(
                                                                            date)
                                                                        ? FontWeight
                                                                            .bold
                                                                        : FontWeight
                                                                            .normal, // Bold for today's weekday
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  maxLines: 1,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      Container(
                                                                    decoration: !widget
                                                                            .isGradientColor!
                                                                        ? BoxDecoration(
                                                                            color: isSelected
                                                                                ? widget.activeColor
                                                                                : DateFunctions.isToDayDate(date)
                                                                                    ? widget.activeColor!.withValues(alpha: 0.3)
                                                                                    : widget.deActiveColor,
                                                                            borderRadius: BorderRadius.circular(widget.dayBoxBorderRadius!),
                                                                            border: Border.all(
                                                                              width: DateFunctions.isToDayDate(date) ? (widget.dayBorderWidth! + 1) : widget.dayBorderWidth!,
                                                                              color: DateFunctions.isToDayDate(date)
                                                                                  ? widget.activeColor!
                                                                                  : !isSelected
                                                                                      ? widget.activeColor!
                                                                                      : widget.activeColor!.withValues(alpha: 0.1),
                                                                            ))
                                                                        : BoxDecoration(
                                                                            gradient: isSelected
                                                                                ? widget.activeGradientColor
                                                                                : DateFunctions.isToDayDate(date)
                                                                                    ? LinearGradient(
                                                                                        colors: widget.activeGradientColor!.colors.map((color) => color.withValues(alpha: 0.3)).toList(),
                                                                                        begin: widget.activeGradientColor!.begin,
                                                                                        end: widget.activeGradientColor!.end,
                                                                                        stops: widget.activeGradientColor!.stops,
                                                                                        tileMode: widget.activeGradientColor!.tileMode,
                                                                                      )
                                                                                    : widget.deActiveGradientColor,
                                                                            borderRadius: BorderRadius.circular(widget.dayBoxBorderRadius!),
                                                                            border: Border.all(
                                                                              width: DateFunctions.isToDayDate(date) ? (widget.dayBorderWidth! + 1) : widget.dayBorderWidth!,
                                                                              color: DateFunctions.isToDayDate(date)
                                                                                  ? widget.activeColor!
                                                                                  : !isSelected
                                                                                      ? widget.activeColor!
                                                                                      : widget.activeColor!.withValues(alpha: 0.1),
                                                                            )),
                                                                    child:
                                                                        Center(
                                                                      child:
                                                                          FittedBox(
                                                                        fit: BoxFit
                                                                            .scaleDown,
                                                                        // Adjusts the text to fit the box
                                                                        child:
                                                                            Text(
                                                                          date.day
                                                                              .toString(),
                                                                          style: widget
                                                                              .textStyle!
                                                                              .copyWith(
                                                                            fontSize:
                                                                                14.0,
                                                                            color: !isActive
                                                                                ? widget.activeColor!.withValues(alpha: 0.5)
                                                                                : isSelected
                                                                                    ? widget.deActiveColor
                                                                                    : DateFunctions.isToDayDate(date)
                                                                                        ? widget.activeColor // Highlight today's date
                                                                                        : widget.activeColor,
                                                                            fontWeight: DateFunctions.isToDayDate(date) || isSelected
                                                                                ? FontWeight.bold
                                                                                : FontWeight.normal,
                                                                          ),
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          maxLines:
                                                                              1,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 1)
                                                              ],
                                                            )
                                                          :

                                                          /// Layout 2: Display mode for day inside date box.
                                                          Container(
                                                              decoration: !widget
                                                                      .isGradientColor!
                                                                  ? BoxDecoration(
                                                                      color: isSelected
                                                                          ? widget.activeColor
                                                                          : DateFunctions.isToDayDate(date)
                                                                              ? widget.activeColor!.withValues(alpha: 0.3)
                                                                              : widget.deActiveColor,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              widget.dayBoxBorderRadius!),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        width: DateFunctions.isToDayDate(date)
                                                                            ? (widget.dayBorderWidth! +
                                                                                1)
                                                                            : widget.dayBorderWidth!,
                                                                        color: DateFunctions.isToDayDate(date)
                                                                            ? widget.activeColor!
                                                                            : !isSelected
                                                                                ? widget.activeColor!
                                                                                : widget.activeColor!.withValues(alpha: 0.1),
                                                                      ),
                                                                    )
                                                                  : BoxDecoration(
                                                                      gradient: isSelected
                                                                          ? widget.activeGradientColor
                                                                          : DateFunctions.isToDayDate(date)
                                                                              ? LinearGradient(
                                                                                  colors: widget.activeGradientColor!.colors.map((color) => color.withValues(alpha: 0.3)).toList(),
                                                                                  begin: widget.activeGradientColor!.begin,
                                                                                  end: widget.activeGradientColor!.end,
                                                                                  stops: widget.activeGradientColor!.stops,
                                                                                  tileMode: widget.activeGradientColor!.tileMode,
                                                                                )
                                                                              : widget.deActiveGradientColor,
                                                                      borderRadius: BorderRadius.circular(widget.dayBoxBorderRadius!),
                                                                      border: Border.all(
                                                                        width: DateFunctions.isToDayDate(date)
                                                                            ? (widget.dayBorderWidth! +
                                                                                1)
                                                                            : widget.dayBorderWidth!,
                                                                        color: DateFunctions.isToDayDate(date)
                                                                            ? widget.activeColor!
                                                                            : !isSelected
                                                                                ? widget.activeColor!
                                                                                : widget.activeColor!.withValues(alpha: 0.1),
                                                                      )),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  FittedBox(
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    // Adjusts the text to fit the box
                                                                    child: Text(
                                                                      DateFormat(
                                                                              'EEE')
                                                                          .format(
                                                                              date),
                                                                      style: widget
                                                                          .textStyle!
                                                                          .copyWith(
                                                                        fontSize:
                                                                            11.0,
                                                                        fontWeight: DateFunctions.isToDayDate(date)
                                                                            ? FontWeight.bold
                                                                            : FontWeight.normal, // Bold for today's weekday
                                                                        color: !isActive
                                                                            ? widget.activeColor!.withValues(alpha: 0.5)
                                                                            : isSelected
                                                                                ? widget.deActiveColor
                                                                                : widget.activeColor,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      maxLines:
                                                                          1,
                                                                    ),
                                                                  ),
                                                                  FittedBox(
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    // Adjusts the text to fit the box
                                                                    child: Text(
                                                                      date.day
                                                                          .toString(),
                                                                      style: widget
                                                                          .textStyle!
                                                                          .copyWith(
                                                                        color: !isActive
                                                                            ? widget.activeColor!.withValues(alpha: 0.5)
                                                                            : isSelected
                                                                                ? widget.deActiveColor
                                                                                : widget.activeColor,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            13.0,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      maxLines:
                                                                          1,
                                                                    ),
                                                                  ),
                                                                  widget.showMonthInDayBox!
                                                                      ? FittedBox(
                                                                          fit: BoxFit
                                                                              .scaleDown,
                                                                          // Adjusts the text to fit the box
                                                                          child:
                                                                              Text(
                                                                            DateFormat("MMM").format(date).toString(),
                                                                            style:
                                                                                widget.textStyle!.copyWith(
                                                                              fontSize: 11.0,
                                                                              fontWeight: DateFunctions.isToDayDate(date) ? FontWeight.bold : FontWeight.normal, // Bold for today's weekday
                                                                              color: !isActive
                                                                                  ? widget.activeColor!.withValues(alpha: 0.5)
                                                                                  : isSelected
                                                                                      ? widget.deActiveColor
                                                                                      : widget.activeColor,
                                                                            ),
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        )
                                                                      : const SizedBox(),
                                                                ],
                                                              ),
                                                            ),
                                                ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ),

                      // Button to navigate to the next month or date slot.
                      Column(
                        children: [
                          widget.dayDisplayMode == DayDisplayMode.outsideDateBox
                              ? Text(
                                  "",
                                  style: widget.textStyle!.copyWith(
                                    fontSize: 11.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                )
                              : const SizedBox(),
                          widget.showarrow
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      pageController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        curve: Curves.ease,
                                      );
                                    });
                                    funcSetNextMonth();
                                  },
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: sw),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      color: widget.activeColor,
                                      size: sw * 5,
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: sw * 5,
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ));
      },
    );
  }
}
