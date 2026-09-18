import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class SampleDataService {
  static List<AppUser> getInitialUsers() {
    return [
      AppUser(
        id: 'admin_1',
        name: 'Dr. R. Rajendran',
        email: 'warden@gce.edu',
        phone: '9876543210',
        role: AppConstants.roleAdmin,
        isActive: true,
      ),
      AppUser(
        id: 'rep_1',
        name: 'V. Senthil Nathan',
        email: 'rep@gce.edu',
        phone: '9876543211',
        role: AppConstants.roleRepresentative,
        assignedRoomIds: ['room_101', 'room_102'],
        isActive: true,
      ),
      AppUser(
        id: 'rep_2',
        name: 'M. Praveen Kumar',
        email: 'praveen@gce.edu',
        phone: '9876543212',
        role: AppConstants.roleRepresentative,
        assignedRoomIds: ['room_103', 'room_104'],
        isActive: true,
      ),
    ];
  }

  static List<RoomModel> getInitialRooms() {
    return [
      RoomModel(
        id: 'room_101',
        roomNumber: '101',
        block: 'Block A',
        capacity: 4,
        studentCount: 3,
      ),
      RoomModel(
        id: 'room_102',
        roomNumber: '102',
        block: 'Block A',
        capacity: 4,
        studentCount: 2,
      ),
      RoomModel(
        id: 'room_103',
        roomNumber: '103',
        block: 'Block B',
        capacity: 4,
        studentCount: 2,
      ),
      RoomModel(
        id: 'room_104',
        roomNumber: '104',
        block: 'Block B',
        capacity: 6,
        studentCount: 3,
      ),
    ];
  }

  static List<StudentModel> getInitialStudents() {
    return [
      StudentModel(
        id: 'stud_1',
        name: 'Arun Kumar',
        registerNumber: '24IT001',
        rollNumber: 'IT2401',
        department: 'Information Technology (IT)',
        year: '2nd Year',
        phone: '9123456780',
        roomId: 'room_101',
        roomNumber: '101',
      ),
      StudentModel(
        id: 'stud_2',
        name: 'Siva',
        registerNumber: '24IT002',
        rollNumber: 'IT2402',
        department: 'Information Technology (IT)',
        year: '2nd Year',
        phone: '9123456781',
        roomId: 'room_101',
        roomNumber: '101',
      ),
      StudentModel(
        id: 'stud_3',
        name: 'Karthik',
        registerNumber: '24IT003',
        rollNumber: 'IT2403',
        department: 'Computer Science & Engineering (CSE)',
        year: '2nd Year',
        phone: '9123456782',
        roomId: 'room_101',
        roomNumber: '101',
      ),
      StudentModel(
        id: 'stud_4',
        name: 'Ramesh',
        registerNumber: '24ME019',
        rollNumber: 'ME2419',
        department: 'Mechanical Engineering (MECH)',
        year: '3rd Year',
        phone: '9123456783',
        roomId: 'room_102',
        roomNumber: '102',
      ),
      StudentModel(
        id: 'stud_5',
        name: 'Vijay',
        registerNumber: '24EC045',
        rollNumber: 'EC2445',
        department: 'Electronics & Communication (ECE)',
        year: '1st Year',
        phone: '9123456784',
        roomId: 'room_102',
        roomNumber: '102',
      ),
      StudentModel(
        id: 'stud_6',
        name: 'Dinesh Kumar',
        registerNumber: '24CS012',
        rollNumber: 'CS2412',
        department: 'Computer Science & Engineering (CSE)',
        year: '3rd Year',
        phone: '9123456785',
        roomId: 'room_103',
        roomNumber: '103',
      ),
      StudentModel(
        id: 'stud_7',
        name: 'Saravanan',
        registerNumber: '24EE023',
        rollNumber: 'EE2423',
        department: 'Electrical & Electronics (EEE)',
        year: '4th Year',
        phone: '9123456786',
        roomId: 'room_103',
        roomNumber: '103',
      ),
      StudentModel(
        id: 'stud_8',
        name: 'Manoj',
        registerNumber: '24CV015',
        rollNumber: 'CV2415',
        department: 'Civil Engineering (CIVIL)',
        year: '1st Year',
        phone: '9123456787',
        roomId: 'room_104',
        roomNumber: '104',
      ),
      StudentModel(
        id: 'stud_9',
        name: 'Anand',
        registerNumber: '24MT008',
        rollNumber: 'MT2408',
        department: 'Metallurgical Engineering (MET)',
        year: '2nd Year',
        phone: '9123456788',
        roomId: 'room_104',
        roomNumber: '104',
      ),
      StudentModel(
        id: 'stud_10',
        name: 'Gokul',
        registerNumber: '24IT030',
        rollNumber: 'IT2430',
        department: 'Information Technology (IT)',
        year: '4th Year',
        phone: '9123456789',
        roomId: 'room_104',
        roomNumber: '104',
      ),
    ];
  }

  static List<AttendanceModel> getInitialAttendance() {
    final today = AppDateUtils.todayStorage();
    return [
      AttendanceModel(
        id: '${today}_stud_1',
        studentId: 'stud_1',
        studentName: 'Arun Kumar',
        registerNumber: '24IT001',
        roomId: 'room_101',
        roomNumber: '101',
        date: today,
        status: AppConstants.statusPresent,
        markedBy: 'rep_1',
        markedByName: 'V. Senthil Nathan',
      ),
      AttendanceModel(
        id: '${today}_stud_2',
        studentId: 'stud_2',
        studentName: 'Siva',
        registerNumber: '24IT002',
        roomId: 'room_101',
        roomNumber: '101',
        date: today,
        status: AppConstants.statusPresent,
        markedBy: 'rep_1',
        markedByName: 'V. Senthil Nathan',
      ),
      AttendanceModel(
        id: '${today}_stud_3',
        studentId: 'stud_3',
        studentName: 'Karthik',
        registerNumber: '24IT003',
        roomId: 'room_101',
        roomNumber: '101',
        date: today,
        status: AppConstants.statusAbsent,
        markedBy: 'rep_1',
        markedByName: 'V. Senthil Nathan',
      ),
      AttendanceModel(
        id: '${today}_stud_4',
        studentId: 'stud_4',
        studentName: 'Ramesh',
        registerNumber: '24ME019',
        roomId: 'room_102',
        roomNumber: '102',
        date: today,
        status: AppConstants.statusPresent,
        markedBy: 'rep_1',
        markedByName: 'V. Senthil Nathan',
      ),
      AttendanceModel(
        id: '${today}_stud_5',
        studentId: 'stud_5',
        studentName: 'Vijay',
        registerNumber: '24EC045',
        roomId: 'room_102',
        roomNumber: '102',
        date: today,
        status: AppConstants.statusPresent,
        markedBy: 'rep_1',
        markedByName: 'V. Senthil Nathan',
      ),
    ];
  }
}
