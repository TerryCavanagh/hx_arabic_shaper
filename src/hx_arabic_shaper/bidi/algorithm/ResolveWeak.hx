package hx_arabic_shaper.bidi.algorithm;

import hx_arabic_shaper.bidi.Statics;
import hx_arabic_shaper.bidi.Statics.*;
import hx_arabic_shaper.utils.ReverseIterator;

import hx_arabic_shaper.utils.UTF8String;

class ResolveWeak {
  
  static function W1(data:DataStruct, sequence:IsolatingRunSequenceStruct, ch:CharStruct, char_index:Int) {
    if (ch.bidi_type != "NSM") {
      return;
    }

    if (ch == sequence.chars[0]) {
      ch.bidi_type = sequence.sos_type;
    } else {
      var prev_char = data.chars[char_index - 1];
      switch(prev_char.bidi_type) {
        case 'PDI', 'LRI', 'RLI', 'FSI':
          ch.bidi_type = "ON";
        default:
          ch.bidi_type = prev_char.bidi_type;
      }
    }
  }

  static function W2(ch:CharStruct, last_strong_type:UTF8String) {
    if (ch.bidi_type != "EN") {
      return;
    }

    if (last_strong_type == "AL") {
      ch.bidi_type = "AN";
    }
  }

  static function W3(ch:CharStruct) {
    if (ch.bidi_type == "AL") {
      ch.bidi_type = "R";
    }
  }

  static function W4(data:DataStruct, ch:CharStruct, char_index:Int) {
    if (char_index > 0 && char_index < data.chars.length - 1) {
      if (ch.bidi_type == "ES") {
        var prev_char = data.chars[char_index - 1];
        var following_char = data.chars[char_index + 1];

        if (prev_char.bidi_type == "EN" && following_char.bidi_type == "EN") {
          ch.bidi_type = "EN";
        }
      }

      if (ch.bidi_type == "CS") {
        var prev_char = data.chars[char_index - 1];
        var following_char = data.chars[char_index + 1];

        if ((prev_char.bidi_type == "EN" || prev_char.bidi_type == "AN")
          && (following_char.bidi_type == "EN" || following_char.bidi_type == "AN")) {
          ch.bidi_type = prev_char.bidi_type;
        }
      }
    }
  }

  static function W5(data:DataStruct, ch:CharStruct, char_index:Int) {
    if(ch.bidi_type != "EN") {
      return;
    }

    for (i in char_index...data.chars.length) {
      var _ch = data.chars[i];
      if (_ch.bidi_type != "ET") {
        break;
      }
      _ch.bidi_type = "EN";
    }

    for(i in new ReverseIterator(char_index, -1)) {
      var _ch = data.chars[i];
      if (_ch.bidi_type != "ET") {
        break;
      }
      _ch.bidi_type = "EN";
    }
  }

  static function W6(ch:CharStruct) {
    switch(ch.bidi_type) {
      case 'ET', 'ES', 'CS':
        ch.bidi_type = "ON";
    }
  }

  static function W7(ch:CharStruct, last_strong_type:UTF8String) {
    if (ch.bidi_type == "EN" && last_strong_type == "L") {
      ch.bidi_type = "L";
    }
  }

  public static function resolve_weak_types(data:DataStruct) {
    for (sequence in data.isolating_run_sequences) {
      var last_strong_type = null;
      for (ch in sequence.chars) {
        var char_index = data.chars.indexOf(ch);

        switch (ch.bidi_type) {
          case 'AL', 'R', 'L':
            last_strong_type = ch.bidi_type;
        }

        W1(data, sequence, ch, char_index);
        W2(ch, last_strong_type);
        W3(ch);
        W4(data, ch, char_index);
        W5(data, ch, char_index);
        W6(ch);
        W7(ch, last_strong_type);

      }
    }
  }

}