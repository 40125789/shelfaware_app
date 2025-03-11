String getTimeRemaining(String expiryDateStr) {
    DateTime? expiryDate;

    try {
      // Manually convert the "dd/MM/yyyy" format to "yyyy-MM-dd"
      String formattedDate = expiryDateStr;
      List<String> dateParts = formattedDate.split('/');

      if (dateParts.length == 3) {
        // Reformat to "yyyy-MM-dd" format
        formattedDate =
            '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}'; // yyyy-MM-dd
      }

      // Now, use DateTime.parse() with the reformatted date
      expiryDate = DateTime.parse(formattedDate);

      // Check if expiryDate is null or invalid
      if (expiryDate == null) {
        return 'Invalid expiry date';
      }
    } catch (e) {
      return 'Invalid expiry date'; // Return an error message if parsing fails
    }

    // Calculate the difference in hours between the expiry date and the current time
    final int expiryDiffInHours = expiryDate.difference(DateTime.now()).inHours;

    // If the item is expired
    if (expiryDiffInHours < 0) {
      return 'Expired';
    }

    // If the item expires in less than 24 hours
    if (expiryDiffInHours < 24) {
      return 'This item expires in less than a day';
    }

    // If the item expires tomorrow
    final int expiryDiffInDays = expiryDate.difference(DateTime.now()).inDays;
    if (expiryDiffInDays == 1) {
      return 'This item expires tomorrow';
    }

    // If the item expires in more than 1 day
    return 'This item expires in: $expiryDiffInDays days';
  }