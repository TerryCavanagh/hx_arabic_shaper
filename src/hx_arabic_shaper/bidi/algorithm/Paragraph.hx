package hx_arabic_shaper.bidi.algorithm;

import hx_arabic_shaper.bidi.Statics;
import hx_arabic_shaper.bidi.Statics.*;
import hx_arabic_shaper.bidi.database.UnicodeData;
import haxe.Utf8;

import hx_arabic_shaper.utils.UTF8String;

class Paragraph {
  public static function preprocess_text(text:UTF8String) {
    var ls = [];
    for(i in 0...Utf8.length(text)) {
      var ch = Utf8.sub(text, i, 1);
      var struct = Statics._get_char_struct();
      struct.ch = ch;
      struct.bidi_type = UnicodeData.bidirectional(ch);
      ls.push(struct);
    }

    return ls;
  }

  public static function get_paragraph_level(chars:Array<CharStruct>) {
    for (ch in chars) {
      var bidi_type = ch.bidi_type;
      switch(bidi_type) {
        case "AL", "R":
          return 1;
        case "L":
          return 0;
      }
    }

    return 0;
  }
}