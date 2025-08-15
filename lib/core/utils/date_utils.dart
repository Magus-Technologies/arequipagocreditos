import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }
  
  static String formatCurrency(double amount, {String symbol = 'S/.'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }
  
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} días atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutos atrás';
    } else {
      return 'Hace un momento';
    }
  }
  
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }
  
  static String relativeDateString(DateTime date) {
    if (isToday(date)) return 'Hoy';
    if (isYesterday(date)) return 'Ayer';
    return formatDate(date);
  }
}
