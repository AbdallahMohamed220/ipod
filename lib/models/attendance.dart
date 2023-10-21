import 'package:intl/intl.dart';

import '../apis/attendance.dart';
import '../pages/login.dart';

class Attendance {
//check-in model
  Future<String> doCheckIn(
      {checkInNote, iPAddress, latitude, longitude}) async {
    Map<String, dynamic> checkInMap = {
      "user_id": USERID,
      "clock_in_time": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
      "clock_in_note": "$checkInNote",
      "ip_address": "$iPAddress",
      "latitude": "$latitude",
      "longitude": "$longitude"
    };
    String message = '';
    Map<String, dynamic>? response =
        await AttendanceApi().checkIO(checkInMap, true);
    if (response!.containsKey('success')) {
      message = response['msg'];
    } else {
      message = response['error']['message'];
    }
    return message;
  }

  //check-out model
  Future<String> doCheckOut({latitude, longitude, checkOutNote}) async {
    Map<String, dynamic> checkOutMap = {
      "user_id": USERID,
      "clock_out_time":
          DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
      "clock_out_note": "$checkOutNote",
      "latitude": "$latitude",
      "longitude": "$longitude"
    };
    Map<String, dynamic>? response =
        await AttendanceApi().checkIO(checkOutMap, false);
    String message = '';
    if (response!.containsKey('success')) {
      message = response['msg'];
    } else {
      message = response['error']['message'];
    }
    return message;
  }

  Future<bool> getAttendanceStatus(userId) async {
    var result = await AttendanceApi().getAttendanceDetails(userId);
    if (result.length > 0) {
      if (result['clock_out_time'] != null)
        return false;
      else
        return true;
    } else
      return false;
  }

  Future<String?> getCheckInTime(userId) async {
    String? checkIn;
    var result = await AttendanceApi().getAttendanceDetails(userId);
    if (result != null && result.isNotEmpty) checkIn = result['clock_in_time'];
    return checkIn;
  }
}
