class Confrence {
  late String displayName;
  late String emailID;
  late String room;
  late String subject;
  late String avatarUrl;
  Confrence(
      {required String displayName,
      required String emailID,
      required String subject,
      required String avatarUrl,
      required String room}) {
    this.displayName = displayName;
    this.emailID = emailID;
    this.room = room;
    this.avatarUrl = avatarUrl;
    this.subject = subject;
  }
}
