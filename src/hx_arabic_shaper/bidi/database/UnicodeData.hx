package hx_arabic_shaper.bidi.database;

import hx_arabic_shaper.bidi.database.UnicodeDB;
import hx_arabic_shaper.utils.UTF8String;

class UnicodeData {

  public static var index1 = UnicodeDB.index1;
  public static var index2 = UnicodeDB.index2;
  public static var Database_Records = UnicodeDB.Database_Records;
  public static var bidi_names = UnicodeDB.BidirectionalNames;

  public static inline var SHIFT = 7;

  public static function bidirectional(ch:UTF8String) {
    var code = ch.charCodeAt(0);
    var index = 0;
    if (code < 0x110000) {
      var sh1 = code >> SHIFT;
      index = index1[sh1];
      var n = code & ((1<<SHIFT) - 1);
      var sh2 = (index<<SHIFT) + n;
      index = index2[sh2];
    }

    var record = Database_Records[index];
    var bidi = record[DatabaseRecord.bidirectional];
    var name = bidi_names[bidi];

    return name;
  }

  public static function mirrored(ch:UTF8String) {
    var code = ch.charCodeAt(0);
    var index = 0;
    if (code < 0x110000) {
      index = index1[code >> SHIFT];
      var lsh = index << SHIFT;
      var added = code & (1<<SHIFT - 1);
      var i = lsh + added;
      index = index2[i];
    }

    return Database_Records[index][DatabaseRecord.mirrored];
  }

}

@:enum abstract DatabaseRecord(Int) from Int to Int {
  var bidirectional = 2;
  var mirrored = 3;
}