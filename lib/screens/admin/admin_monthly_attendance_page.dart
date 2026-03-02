import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminMonthlyAttendancePage extends StatelessWidget {
  final String schoolId;
  final String classId;
  final int month;
  final int year;

  const AdminMonthlyAttendancePage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.month,
    required this.year,
  });

  /// 🔹 Calculate attendance with student names
  Future<List<Map<String, dynamic>>> calculate() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .get();

    Map<String, int> present = {};
    int totalDays = 0;

    for (var doc in snapshot.docs) {

      // doc.id = "2026-03-02"
      final dateParts = doc.id.split("-");
      final docYear = int.parse(dateParts[0]);
      final docMonth = int.parse(dateParts[1]);

      if (docYear == year && docMonth == month) {

        final classData = doc.data()[classId];

        if (classData != null) {
          totalDays++;

          (classData as Map<String, dynamic>)
              .forEach((studentId, value) {
            if (value == true) {
              present[studentId] =
                  (present[studentId] ?? 0) + 1;
            }
          });
        }
      }
    }

    List<Map<String, dynamic>> result = [];

    for (var entry in present.entries) {

      final studentDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(entry.key)
          .get();

      final name =
      studentDoc.exists ? studentDoc['name'] : entry.key;

      final percentage =
      totalDays == 0 ? 0 : (entry.value / totalDays) * 100;

      result.add({
        "name": name,
        "percentage": percentage,
      });
    }

    return result;
  }

  /// 🔹 Export PDF with names
  Future<void> exportPDF(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Monthly Attendance Report",
                style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            ...data.map((e) => pw.Text(
                "${e["name"]} : ${e["percentage"].toStringAsFixed(1)}%")),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: Text("Monthly Report - $classId")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: calculate(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.isEmpty) {
            return const Center(
                child: Text("No attendance data"));
          }

          /// 🔹 Calculate class average
          double classAverage = data
              .map((e) => e["percentage"] as double)
              .reduce((a, b) => a + b) /
              data.length;

          return Column(
            children: [

              /// 📊 Class Average
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  "Class Average: ${classAverage.toStringAsFixed(1)}%",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),

              /// 📊 Chart
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    barGroups: data
                        .asMap()
                        .entries
                        .map((entry) {
                      int index = entry.key;
                      double value =
                      entry.value["percentage"];

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: value,
                            width: 14,
                          )
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// 📥 Export PDF
              ElevatedButton(
                onPressed: () => exportPDF(data),
                child: const Text("Export PDF"),
              ),

              const Divider(),

              /// 📋 Student List
              Expanded(
                child: ListView(
                  children: data.map((e) {
                    double percent = e["percentage"];

                    return ListTile(
                      title: Text(e["name"]),
                      subtitle: Text(
                          "${percent.toStringAsFixed(1)}%"),
                      trailing: percent < 75
                          ? const Icon(Icons.warning,
                          color: Colors.red)
                          : const Icon(Icons.check_circle,
                          color: Colors.green),
                    );
                  }).toList(),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}