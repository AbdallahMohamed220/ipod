class FiledForceModel {
  Map<String, dynamic> getVisits(Map<String, dynamic> data) {
    Map<String, dynamic> visit = {
      'id': data['id'],
      'visit_id': data['visit_id'],
      'contact_id': data['contact']['contact_id'],
      'contact': (data['contact_id'] != null)
          ? getContactDetails(data['contact'])
          : {
              'name': data['visit_to'] ?? null,
              'contact_numbers': [], //[data['visit_mobile']],
              'address': data['visit_address'] ?? null
            },
      'assigned_to': data['assigned_to'],
      'user': getUserDetails(data['user']),
      'status': data['status'],
      'visit_on': data['visit_on'],
      'visited_on': data['visited_on'],
      'visited_address_latitude': data['visited_address_latitude'],
      'visited_address_longitude': data['visited_address_longitude'],
      'visited_address': data['visited_address'],
      'meet_with': data['meet_with'],
      'meet_with2': data['meet_with2'],
      'meet_with3': data['meet_with3'],
      'meet_with_mobile_no': data['meet_with_mobileno'],
      'meet_with_mobile_no2': data['meet_with_mobileno2'],
      'meet_with_mobile_no3': data['meet_with_mobileno3'],
      'meet_with_designation': data['meet_with_designation'],
      'meet_with_designation2': data['meet_with_designation2'],
      'meet_with_designation3': data['meet_with_designation3']
    };
    return visit;
  }

  Map<String, dynamic> getContactDetails(Map<String, dynamic> contactData) {
    List number = [
      contactData['mobile'],
      contactData['alternate_number'],
      contactData['landline']
    ];
    number.removeWhere((e) => e == null);
    List address = [
      contactData['address_line_1'],
      contactData['address_line_2']
    ];
    address.removeWhere((e) => e == null);
    List location = [
      contactData['city'],
      contactData['state'],
      contactData['country'],
      contactData['zip_code']
    ];
    location.removeWhere((e) => e == null);
    Map<String, dynamic> contact = {
      'supplier_business_name':
          (contactData['supplier_business_name'] != null &&
                  contactData['supplier_business_name'].toString().trim() != '')
              ? contactData['supplier_business_name']
              : null,
      'name': (contactData['name'] != null &&
              contactData['name'].toString().trim() != '')
          ? contactData['name']
          : null,
      'contact_numbers': number,
      'address': address.join('\n') + '\n' + location.join(', '),
      'email': "${contactData['email'] ?? ''}"
    };
    return contact;
  }

  Map<String, dynamic> getUserDetails(Map<String, dynamic> userData) {
    Map<String, dynamic> user = {
      'name':
          "${userData['surname'] ?? ''} ${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}"
    };
    return user;
  }
}
