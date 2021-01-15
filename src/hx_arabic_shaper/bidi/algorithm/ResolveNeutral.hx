package hx_arabic_shaper.bidi.algorithm;

import hx_arabic_shaper.bidi.Statics;
import hx_arabic_shaper.bidi.Statics.*;
import hx_arabic_shaper.bidi.database.UnicodeData;
import hx_arabic_shaper.bidi.database.BidiBrackets;
import hx_arabic_shaper.utils.ReverseIterator;

class ResolveNeutral {

  static function sort_ascending(a:Array<Dynamic>, b:Array<Dynamic>) {
    if (a[0] < b[0]) {
      return -1;
    }
    return 1;
  }

  static function identify_bracket_pairs(sequence:IsolatingRunSequenceStruct, data:DataStruct) {
    var stack:Array<Array<Dynamic>> = [];
    var pair_indexes:Array<Array<Dynamic>> = [];

    for (ch in sequence.chars) {

      if (BidiBrackets.brackets.exists(ch.ch)) {
        var entry = BidiBrackets.brackets[ch.ch];
        var bracket_type = entry[1];
        var text_position = data.chars.indexOf(ch);

        if (bracket_type == "o") {
          if (stack.length <= 63) {
            stack.push([entry[0], text_position]);
          } else {
            break;
          }
        } else if (bracket_type == "c") {
          var element_index = stack.length - 1;
          
          while (element_index > 0 && entry[0] != stack[element_index][0]) {
            element_index -= 1;
          }
        
          var element = stack[element_index];
          if (element != null && element[0] == entry[0]) {
            pair_indexes.push([element[1], text_position]);
            stack.pop();
          }
        
        }
      }
    }

    pair_indexes.sort(sort_ascending);

    return pair_indexes;
  }

  static function N0(sequence:IsolatingRunSequenceStruct, data:DataStruct) {
    var bracket_pairs = identify_bracket_pairs(sequence, data);

    for (bracket_pair in bracket_pairs) {
      var strong_type = null;

      var chars = data.chars.slice(bracket_pair[0], bracket_pair[1]);

      for (ch in chars) {
        var bidi_type = ch.bidi_type;

        switch (bidi_type) {
          case 'EN', 'AN':
            bidi_type = "R";
        }

        if (bidi_type == sequence.embedding_direction) {
          data.chars[bracket_pair[0]].bidi_type = sequence.embedding_direction;
          data.chars[bracket_pair[1]].bidi_type = sequence.embedding_direction;
          strong_type = null;
          break;
        } else if (bidi_type == "L" || bidi_type == "R") {
          strong_type = bidi_type;
        }
      }

      if (strong_type != null) {
        var found_preceding_strong_type = false;

        for (i in new ReverseIterator(bracket_pair[0], -1)) {
          var ch = data.chars[i];

          var bidi_type = ch.bidi_type;
        
          switch (bidi_type) {
            case 'EN', 'AN':
              bidi_type = "R";
          }

          if (bidi_type == strong_type) {
            data.chars[bracket_pair[0]].bidi_type = strong_type;
            data.chars[bracket_pair[1]].bidi_type = strong_type;
            found_preceding_strong_type = true;
            break;
          }

          if (!found_preceding_strong_type) {
            data.chars[bracket_pair[0]].bidi_type = sequence.embedding_direction;
            data.chars[bracket_pair[1]].bidi_type = sequence.embedding_direction;
          }
        }
      }

      chars = data.chars.slice(bracket_pair[0] + 1, bracket_pair[1]);
      for (ch in chars) {
        var original_type = UnicodeData.bidirectional(ch.ch);
        if (original_type != "NSM") {
          break;
        }

        ch.bidi_type = data.chars[bracket_pair[0]].bidi_type;
      }
    }
  }

  static function N1(sequence:IsolatingRunSequenceStruct) {
    var strong_type = null;
    var NI_sequence = [];
    var is_in_sequence = false;

    for (ch in sequence.chars) {
      switch (ch.bidi_type) {
        case "B", "S", "WS", "ON", "FSI", "LRI", "RLI", "PDI":
          is_in_sequence = true;
          NI_sequence.push(ch);
        case _:
          var new_type = null;
          switch (ch.bidi_type) {
            case 'R', 'EN', 'AN':
              new_type = "R";
            case "L":
              new_type = "L";
          }

          if (new_type != null) {
            if (is_in_sequence && strong_type == new_type) {
              for (_ch in NI_sequence) {
                _ch.bidi_type = strong_type;
              }
            }
            NI_sequence = [];
            is_in_sequence = false;
            strong_type = new_type;
          }
      }
    }
  }

  static function N2(sequence:IsolatingRunSequenceStruct) {
    for (ch in sequence.chars) {
      switch(ch.bidi_type) {
        case "B", "S", "WS", "ON", "FSI", "LRI", "RLI", "PDI":
          ch.bidi_type = sequence.embedding_direction;
      }
    }
  }

  public static function resolve_neutral_and_isolate_formatting_types(data:DataStruct) {
    for (sequence in data.isolating_run_sequences) {
      N0(sequence, data);
      N1(sequence);
      N2(sequence);
    }
  }

}