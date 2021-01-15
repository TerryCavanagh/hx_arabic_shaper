package hx_arabic_shaper.bidi.algorithm;

import hx_arabic_shaper.bidi.Statics;
import hx_arabic_shaper.bidi.Statics.*;
import hx_arabic_shaper.bidi.database.UnicodeData;
import hx_arabic_shaper.bidi.database.BidiBrackets;
import hx_arabic_shaper.utils.ReverseIterator;

class ReorderResolved {

  static function L1(data:DataStruct) {
    var resetable_chars = [];

    for (ch in data.chars) {
      var original_type = UnicodeData.bidirectional(ch.ch);

      switch (original_type) {
        case 'WS', 'FSI', 'LRI', 'RLI', 'PDI':
          resetable_chars.push(ch);
        case 'B', 'S':
          ch.level = data.level;
          for (ch2 in resetable_chars) {
            ch2.level = data.level;
          }
          resetable_chars = [];
        default:
          resetable_chars = [];
      }
    }

    for (ch2 in resetable_chars) {
      ch2.level = data.level;
    }
  }

  static function L2(data:DataStruct) {
    var highest_level = 0;
    var lowest_odd_level = Math.POSITIVE_INFINITY;

    for (ch in data.chars) {
      if (ch.level > highest_level) {
        highest_level = ch.level;
      }
      if (ch.level < lowest_odd_level && (ch.level % 2) == 1) {
        lowest_odd_level = ch.level;
      }
    }

    if (lowest_odd_level == Math.POSITIVE_INFINITY) {
      // no rtl text, do nothing
      return;
    }

    for (i in new ReverseIterator(highest_level, Std.int(lowest_odd_level) - 1)) {
      var sequences = [[]];
      var sequence_index = 0;
      
      for (ch in data.chars) {
        if (ch.level >= i) {
          sequences[sequence_index].push(ch);
        } else if (sequences[sequence_index].length > 0) {
          sequences.push([]);
          sequence_index += 1;
        }
      }

      for (sequence_chars in sequences) {
        if(sequence_chars.length == 0) {
          continue;
        }
        var first_char = sequence_chars[0];
        var index = data.chars.indexOf(first_char);
        var chars = [];

        for (j in 0...index) {
          chars.push(data.chars[j]);
        }
        for (j in new ReverseIterator(index + sequence_chars.length - 1, index - 1)) {
          chars.push(data.chars[j]);
        }
        for (j in (index + sequence_chars.length)...data.chars.length) {
          chars.push(data.chars[j]);
        }

        data.chars = chars;

      }

    }
  }

  static function L3(data:DataStruct) {
    var non_spacing_chars = [];
    for (ch in data.chars) {
      var original_type = UnicodeData.bidirectional(ch.ch);
      if (original_type == "NSM") {
        non_spacing_chars.push(ch);
      } else if (original_type == "R") {
        non_spacing_chars.push(ch);

        var first_char = non_spacing_chars[0];
        var index = data.chars.indexOf(first_char);
        var chars = [];

        for (j in 0...index) {
          chars.push(data.chars[j]);
        }
        for (j in new ReverseIterator(index + non_spacing_chars.length - 1, index - 1)) {
          chars.push(data.chars[j]);
        }
        for (j in (index + non_spacing_chars.length)...(data.chars.length)) {
          chars.push(data.chars[j]);
        }

        for (j in index...(index + non_spacing_chars.length)) {
          // SHOULDN'T BE chars?????
          data.chars.splice(j, 1);
        }

        data.chars = chars;

        non_spacing_chars = [];
      } else {
        non_spacing_chars = [];
      }
    }
  }

  static function L4(data:DataStruct) {
    for (ch in data.chars) {
      if (ch.level % 2 == 1 && BidiBrackets.mirrored.exists(ch.ch)) {
        ch.ch = BidiBrackets.mirrored.get(ch.ch);
      }
    }
  }

  public static function reorder_resolved_levels(data:DynamicAccess) {
    L1(data);
    L2(data);
    L3(data);
    L4(data);
  }

}