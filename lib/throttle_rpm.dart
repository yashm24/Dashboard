import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:go_router/go_router.dart';
import 'package:desktop_serial_port_app/serial_port_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ThrottleRpmPage extends StatefulWidget {
  final String passedPortName;

  const ThrottleRpmPage({
    super.key,
    required this.passedPortName,
  });

  @override
  ThrottleRpmPageState createState() => ThrottleRpmPageState();
}

class ThrottleRpmPageState extends State<ThrottleRpmPage>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _rpmController;
  late Animation<double> _rpmAnimation;

  double _currentRpm = 0;
  final List<FlSpot> _voltageSpots = [];
  late FlSpot mostLeftSpot = const FlSpot(0, 0.5); // Direct initialization
  bool isSideStandDown = false;

  @override
  void initState() {
    super.initState();
    SerialPortService().initSerialPort(widget.passedPortName);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _rpmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rpmAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _rpmController,
        curve: Curves.easeInOut,
      ),
    );

    SerialPortService().throttleRpmNotifier.addListener(_updateChartData);
    SerialPortService().sideStandNotifier.addListener(_updateSideStandStatus);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _rpmController.dispose();
    SerialPortService().throttleRpmNotifier.removeListener(_updateChartData);
    SerialPortService()
        .sideStandNotifier
        .removeListener(_updateSideStandStatus);
    super.dispose();
  }

  double _mapRpmValue(double rpm) {
    const double minInput = 830.0;
    const double maxInput = 7300.0;
    const double minOutput = 0.0;
    const double maxOutput = 200.0;

    if (rpm < minInput) rpm = minInput;
    if (rpm > maxInput) rpm = maxInput;

    return ((rpm - minInput) / (maxInput - minInput)) *
            (maxOutput - minOutput) +
        minOutput;
  }

  double _mapRpmToVoltage(double rpm) {
    const double minRpm = 830.0;
    const double maxRpm = 7300.0;
    const double minVoltage = 0.5;
    const double maxVoltage = 4.5;

    if (rpm < minRpm) rpm = minRpm;
    if (rpm > maxRpm) rpm = maxRpm;

    return ((rpm - minRpm) / (maxRpm - minRpm)) * (maxVoltage - minVoltage) +
        minVoltage;
  }

  double _voltageToAngle(double voltage) {
    if (voltage < 0.5) return 0;
    if (voltage >= 0.5 && voltage <= 4.5) {
      return ((voltage - 0.5) / (4.5 - 0.5)) * (70 - 10) + 10;
    }
    return 90;
  }

  void _updateChartData() {
    double newRpm =
        double.tryParse(SerialPortService().throttleRpmNotifier.value) ?? 0;
    double mappedRpm = _mapRpmValue(newRpm);
    double newVoltage = _mapRpmToVoltage(newRpm);
    double newAngle = _voltageToAngle(newVoltage);

    newVoltage = newVoltage.clamp(0.5, 4.5);

    if (_voltageSpots.isNotEmpty && newVoltage == _voltageSpots.last.y) {
      // Skip update if the voltage hasn't changed
      return;
    }

    setState(() {
      // Remove spots that are out of the valid range
      _voltageSpots.removeWhere((spot) => spot.y < 0.5 || spot.y > 4.5);

      // If voltage is within valid range, update the chart data
      if (newVoltage >= 0.5 && newVoltage <= 4.5) {
        // Clear spots if voltage is within range and there are no existing valid spots
        if (_voltageSpots.isEmpty || _voltageSpots.first.y != 0.5) {
          _voltageSpots.clear();
          _voltageSpots.addAll([
            const FlSpot(0, 0.5),
            FlSpot(newAngle, newVoltage),
          ]);
        } else {
          _voltageSpots.add(FlSpot(newAngle, newVoltage));
        }
      }

      // Keep the list size manageable
      if (_voltageSpots.length > 50) {
        _voltageSpots.removeAt(0);
      }

      // Update the most left spot for tracking
      if (_voltageSpots.isNotEmpty) {
        mostLeftSpot = _voltageSpots.first;
      }
    });

    _updateRpm(mappedRpm);
  }

  void _updateRpm(double newRpm) {
    _rpmController.animateTo(
      newRpm,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
    _currentRpm = newRpm;
  }

  void _updateSideStandStatus() {
    setState(() {
      isSideStandDown = SerialPortService().sideStandNotifier.value == '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Melexis Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF007AFF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            context
                .go('/main-menu/${Uri.encodeComponent(widget.passedPortName)}');
          },
        ),
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // First Row: RPM Meter Gauge and Chart
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  // RPM Gauge (50% of the row)
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        const Text(
                          'Hand Throttle Gauge', // Title for the RPM Gauge
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8.0),
                              border:
                                  Border.all(color: Colors.white, width: 2.0),
                            ),
                            child: ValueListenableBuilder<String>(
                              valueListenable:
                                  SerialPortService().throttleRpmNotifier,
                              builder: (context, dataValue, child) {
                                double newRpm = double.tryParse(dataValue) ?? 0;
                                newRpm = _mapRpmValue(newRpm);
                                _updateRpm(newRpm);

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 8,
                                      child: AnimatedBuilder(
                                        animation: _rpmAnimation,
                                        builder: (context, child) {
                                          return SfRadialGauge(
                                            axes: <RadialAxis>[
                                              RadialAxis(
                                                minimum: 0,
                                                maximum: 220,
                                                ranges: <GaugeRange>[
                                                  GaugeRange(
                                                    startValue: 0,
                                                    endValue: 50,
                                                    color: Colors.white,
                                                  ),
                                                  GaugeRange(
                                                    startValue: 50,
                                                    endValue: 80,
                                                    color: Colors.green,
                                                  ),
                                                  GaugeRange(
                                                    startValue: 80,
                                                    endValue: 130,
                                                    color: Colors.white,
                                                  ),
                                                  GaugeRange(
                                                    startValue: 130,
                                                    endValue: 220,
                                                    color: Colors.red,
                                                  ),
                                                ],
                                                pointers: <GaugePointer>[
                                                  NeedlePointer(
                                                    value: _rpmAnimation.value,
                                                    needleColor:
                                                        const Color.fromARGB(
                                                            255, 201, 15, 15),
                                                    knobStyle: const KnobStyle(
                                                        color: Colors.white),
                                                  ),
                                                ],
                                                annotations: <GaugeAnnotation>[
                                                  GaugeAnnotation(
                                                    widget: Text(
                                                      '${_rpmAnimation.value.toStringAsFixed(0)} Km/h',
                                                      style: const TextStyle(
                                                          fontSize: 20,
                                                          color: Colors.white),
                                                    ),
                                                    positionFactor: 0.8,
                                                    angle: 90,
                                                  ),
                                                ],
                                                labelOffset: 10,
                                                axisLabelStyle:
                                                    const GaugeTextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                                majorTickStyle:
                                                    const MajorTickStyle(
                                                  color: Colors.white,
                                                  thickness: 2,
                                                ),
                                                minorTickStyle:
                                                    const MinorTickStyle(
                                                  color: Colors.white,
                                                  thickness: 1.5,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    // Speed Warning section
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          AnimatedBuilder(
                                            animation: _rpmAnimation,
                                            builder: (context, child) {
                                              if (_rpmAnimation.value > 130) {
                                                return FadeTransition(
                                                  opacity: _blinkController,
                                                  child: const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.warning,
                                                        color: Colors.red,
                                                        size: 24,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        "Speed Warning!",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              } else {
                                                return const SizedBox.shrink();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // Chart (50% of the row)
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        const Text(
                          'Hand Throttle Chart', // Title for the Chart
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8.0),
                              border:
                                  Border.all(color: Colors.white, width: 2.0),
                            ),
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  getDrawingHorizontalLine: (value) {
                                    return const FlLine(
                                      color: Color(0xff37434d),
                                      strokeWidth: 1,
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return const FlLine(
                                      color: Color(0xff37434d),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    axisNameWidget: const Text(
                                      'Angle (°)', // X-axis label
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    axisNameSize:
                                        30, // Adjusts space for X-axis title
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      interval: 10,
                                      getTitlesWidget:
                                          (double value, TitleMeta meta) {
                                        return Text(
                                          value.toStringAsFixed(0),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    axisNameWidget: const RotatedBox(
                                      quarterTurns: 4,
                                      child: Text(
                                        'Sensor Response (V)', // Y-axis label
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    axisNameSize:
                                        30, // Adjusts space for Y-axis title
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      interval: 0.5,
                                      getTitlesWidget:
                                          (double value, TitleMeta meta) {
                                        return Text(
                                          value.toStringAsFixed(1),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                    color: const Color(0xff37434d),
                                  ),
                                ),
                                minX: 0,
                                maxX: 90,
                                minY: 0.0,
                                maxY: 5.0,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _voltageSpots,
                                    isCurved: false,
                                    color: Colors.white,
                                    barWidth: 2,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
// Second Row: Side Stand Widget, Gear Positioning System, Fuel Level, Gear Reference Sensor
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  // Fuel Level Widget (1/4 width)
                  Expanded(
                    flex: 1, // Changed to 1 for equal distribution
                    child: Column(
                      children: [
                        const Text(
                          'Fuel Level Sensor', // Title for the Fuel Gauge
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8.0),
                              border:
                                  Border.all(color: Colors.white, width: 2.0),
                            ),
                            child: Center(
                              child: ValueListenableBuilder<int>(
                                valueListenable:
                                    SerialPortService().fuelNotifier,
                                builder: (context, fuelLevel, child) {
                                  double needleValue;
                                  switch (fuelLevel) {
                                    case 1:
                                      needleValue = 0; // Empty
                                      break;
                                    case 2:
                                      needleValue = 25; // 1/4
                                      break;
                                    case 3:
                                      needleValue = 50; // 1/2
                                      break;
                                    case 4:
                                      needleValue = 75; // 3/4
                                      break;
                                    case 5:
                                      needleValue = 100; // Full
                                      break;
                                    default:
                                      needleValue =
                                          0; // Default to Empty if value is unexpected
                                  }

                                  return SfRadialGauge(
                                    axes: <RadialAxis>[
                                      RadialAxis(
                                        minimum: 0,
                                        maximum: 100,
                                        showLabels:
                                            false, // Hide default numerical labels
                                        ranges: <GaugeRange>[
                                          GaugeRange(
                                            startValue: 0,
                                            endValue: 25,
                                            color: Colors.red,
                                            labelStyle: const GaugeTextStyle(
                                              color: Colors.red,
                                              fontSize: 18,
                                            ),
                                          ),
                                          GaugeRange(
                                            startValue: 25,
                                            endValue: 27,
                                            color: const Color.fromARGB(
                                                255, 0, 0, 0),
                                            startWidth: 10,
                                            endWidth: 10,
                                          ),
                                          GaugeRange(
                                            startValue: 27,
                                            endValue: 50,
                                            color: Colors.white,
                                            startWidth: 10,
                                            endWidth: 10,
                                          ),
                                          GaugeRange(
                                            startValue: 50,
                                            endValue: 52,
                                            color: const Color.fromARGB(
                                                255, 0, 0, 0),
                                            startWidth: 10,
                                            endWidth: 10,
                                          ),
                                          GaugeRange(
                                            startValue: 52,
                                            endValue: 75,
                                            color: Colors.white,
                                            startWidth: 10,
                                            endWidth: 10,
                                          ),
                                          GaugeRange(
                                            startValue: 75,
                                            endValue: 77,
                                            color: const Color.fromARGB(
                                                255, 0, 0, 0),
                                            startWidth: 10,
                                            endWidth: 10,
                                          ),
                                          GaugeRange(
                                            startValue: 77,
                                            endValue: 100,
                                            color: Colors.green,
                                            labelStyle: const GaugeTextStyle(
                                              color: Colors.green,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                        pointers: <GaugePointer>[
                                          NeedlePointer(
                                            value: needleValue,
                                            enableAnimation:
                                                true, // Enable smooth animation
                                            animationType: AnimationType.ease,
                                            needleLength: 0.7,
                                            needleColor: const Color.fromARGB(
                                                255, 201, 15, 15),
                                            knobStyle: const KnobStyle(
                                              color: Colors.white,
                                              sizeUnit: GaugeSizeUnit.factor,
                                              knobRadius: 0.11,
                                            ),
                                          ),
                                        ],
                                        annotations: const <GaugeAnnotation>[
                                          // Label for 'E'
                                          GaugeAnnotation(
                                            widget: Text(
                                              'E',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                  fontSize: 18),
                                            ),
                                            angle: 120,
                                            positionFactor:
                                                0.95, // Adjust position as needed
                                          ),
                                          // Label for 'F'
                                          GaugeAnnotation(
                                            widget: Text(
                                              'F',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 18),
                                            ),
                                            angle: 60,
                                            positionFactor:
                                                0.95, // Adjust position as needed
                                          ),
                                          // Gas station icon below the knob
                                          GaugeAnnotation(
                                            widget: Icon(
                                              Icons.local_gas_station,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            angle: 90,
                                            positionFactor:
                                                0.8, // Adjust position below the knob
                                          ),
                                        ],
                                        axisLabelStyle: const GaugeTextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        majorTickStyle: const MajorTickStyle(
                                          color: Colors
                                              .transparent, // Hide major ticks
                                          thickness: 2,
                                        ),
                                        minorTickStyle: const MinorTickStyle(
                                          color: Colors
                                              .transparent, // Hide minor ticks
                                          thickness: 1.5,
                                        ),
                                        labelsPosition:
                                            ElementsPosition.outside,
                                        ticksPosition: ElementsPosition.inside,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8.0),
                  // Gear Positioning System Widget (1/4 width)
                  Expanded(
                    flex: 1, // Changed to 1 for equal distribution
                    child: Column(
                      children: [
                        const Text(
                          'Gear Position System', // Title for the Gear Positioning System Widget
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding:
                                const EdgeInsets.all(4.0), // Reduced padding
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8.0),
                              border:
                                  Border.all(color: Colors.white, width: 2.0),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.settings,
                                      color: Colors.white,
                                      size: 58,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                ValueListenableBuilder<String>(
                                  valueListenable:
                                      SerialPortService().gpsNotifier,
                                  builder: (context, dataValue, child) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Gear: ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (dataValue == 'N')
                                          FadeTransition(
                                            opacity: _blinkController,
                                            child: const Text(
                                              'N',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        else
                                          Text(
                                            dataValue,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8.0),
                  // Side Stand Widget (1/4 width)
                  Expanded(
                    flex: 1, // Equal distribution
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Center items horizontally
                      children: [
                        const Text(
                          'Side Stand Indicator', // Title for the Side Stand Widget
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          // Ensure the Container expands to fill the available space
                          child: Container(
                            width: double
                                .infinity, // Ensure the Container takes full width
                            padding:
                                const EdgeInsets.all(8.0), // Consistent padding
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8.0),
                              border:
                                  Border.all(color: Colors.white, width: 2.0),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.motorcycle_sharp,
                                  color: isSideStandDown
                                      ? Colors.red
                                      : Colors.green,
                                  size: 58, // Consistent icon size
                                ),
                                const SizedBox(
                                    height:
                                        8.0), // Spacing between icon and text
                                Text(
                                  isSideStandDown
                                      ? 'Side Stand Down'
                                      : 'Side Stand Up',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8.0),
                  // Gear Reference Sensor Widget (1/4 width)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        const Text(
                          'Gear Reference Indicator', // Title for the Gear Position Indicator Widget
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8.0),
                              border:
                                  Border.all(color: Colors.white, width: 2.0),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/auto-rickshaw.svg', // path to your SVG file
                                  width: 58.0, // adjust the size as needed
                                  height: 58.0, // adjust the size as needed
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8.0),
                                ValueListenableBuilder<String>(
                                  valueListenable:
                                      SerialPortService().grsNotifier,
                                  builder: (context, grsValue, child) {
                                    final isOneActive = grsValue == '1';
                                    final isNeutralActive = grsValue == 'N';
                                    final isTwoActive = grsValue == '2';

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _blinkController,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity: isOneActive
                                                  ? _blinkController.value
                                                  : 1.0,
                                              child: Text(
                                                '1 ',
                                                style: TextStyle(
                                                  color: isOneActive
                                                      ? Colors.red
                                                      : Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: isOneActive
                                                      ? TextDecoration.underline
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        AnimatedBuilder(
                                          animation: _blinkController,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity: isNeutralActive
                                                  ? _blinkController.value
                                                  : 1.0,
                                              child: Text(
                                                'N ',
                                                style: TextStyle(
                                                  color: isNeutralActive
                                                      ? Colors.green
                                                      : Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: isNeutralActive
                                                      ? TextDecoration.underline
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        AnimatedBuilder(
                                          animation: _blinkController,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity: isTwoActive
                                                  ? _blinkController.value
                                                  : 1.0,
                                              child: Text(
                                                '2',
                                                style: TextStyle(
                                                  color: isTwoActive
                                                      ? Colors.red
                                                      : Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: isTwoActive
                                                      ? TextDecoration.underline
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
