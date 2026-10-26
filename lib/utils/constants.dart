import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'GCE Boys Hostel';
  static const String appVersion = 'boys-hostel-3';
  static const String appSubtitle = 'Hostel Management & Attendance System';

  // Hostel Information
  static const String collegeName = 'Government College of Engineering';
  static const String hostelName = 'GCE Boys Hostel (boys-hostel-3)';

  // Default Blocks
  static const List<String> defaultBlocks = [
    'Block A',
    'Block B',
    'Block C',
    'Block D',
    'Main Hostel',
    'PG Block',
  ];

  // Fallback blocks list
  static List<String> blocks = List.from(defaultBlocks);

  // Departments
  static const List<String> departments = [
    'Computer Science & Engineering (CSE)',
    'Information Technology (IT)',
    'Electronics & Communication (ECE)',
    'Electrical & Electronics (EEE)',
    'Mechanical Engineering (MECH)',
    'Civil Engineering (CIVIL)',
    'Metallurgical Engineering (MET)',
  ];

  // Academic Years
  static const List<String> years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleRepresentative = 'representative';

  // Attendance Status
  static const String statusPresent = 'present';
  static const String statusAbsent = 'absent';
  static const String statusNotMarked = 'not_marked';

  // Room Maintenance Complaint Categories & Statuses
  static const List<String> complaintCategories = [
    'Electrical (Fan, Light, Switch)',
    'Plumbing (Water, Tap, Restroom)',
    'Furniture (Bed, Table, Door, Lock)',
    'Cleaning / Housekeeping',
    'Room Facility Issue',
    'Other Issue',
  ];
  static const String complaintPending = 'pending';
  static const String complaintInProgress = 'in_progress';
  static const String complaintResolved = 'resolved';

  // Individual Student Conduct & Disciplinary Complaint Categories
  static const List<String> studentComplaintCategories = [
    'Curfew & Roll Call Violation',
    'Ragging & Physical / Verbal Bullying',
    'Hostel Noise & Night Disturbance',
    'Alcohol / Smoking / Substance Abuse',
    'Hostel Property Damage & Vandalism',
    'Misbehavior & Insubordination',
    'Unauthorized Outsiders / Guests in Room',
    'Other Disciplinary Violation',
  ];

  static const List<String> studentComplaintSeverities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  // Mess & Food Complaint Meal Types & Categories
  static const List<String> messMealTypes = [
    'Breakfast',
    'Lunch',
    'Snacks / Tea',
    'Dinner',
    'General / All Meals',
  ];

  static const List<String> messComplaintCategories = [
    'Food Quality & Taste (Poor taste / Uncooked / Spoiled)',
    'Late Food Serving / Meal Delay',
    'Food Shortage / Insufficient Quantity',
    'Hygiene & Mess Cleanliness',
    'Drinking Water & Utensils Cleanliness',
    'Menu Deviation / Scheduled Item Not Served',
    'Mess Staff Behavior / Service Issue',
    'Other Mess Issue',
  ];

  static const List<String> messComplaintSeverities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  // Firestore / Local Collections
  static const String colUsers = 'users';
  static const String colRooms = 'rooms';
  static const String colStudents = 'students';
  static const String colAttendance = 'attendance';
  static const String colBlocks = 'blocks';
  static const String colComplaints = 'complaints';
  static const String colStudentComplaints = 'student_complaints';
  static const String colMessComplaints = 'mess_complaints';
  static const String collectionUsers = 'users';
  static const String collectionRooms = 'rooms';
  static const String collectionStudents = 'students';
  static const String collectionAttendance = 'attendance';
  static const String collectionComplaints = 'complaints';
  static const String collectionStudentComplaints = 'student_complaints';
  static const String collectionMessComplaints = 'mess_complaints';

  // Color Palette Accents
  static const Color primaryNavy = Color(0xFF1E3A8A); // Indigo / Deep Navy
  static const Color primaryBlue = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color statusPresentColor = Color(0xFF10B981); // Emerald Green
  static const Color statusAbsentColor = Color(0xFFEF4444); // Crimson Red
  static const Color statusPendingColor = Color(0xFFF59E0B); // Amber
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
}
