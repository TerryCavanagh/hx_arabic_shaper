package hx_arabic_shaper.bidi.algorithm;

import hx_arabic_shaper.bidi.Statics;
import hx_arabic_shaper.bidi.Statics.*;
import hx_arabic_shaper.bidi.Statics.DirectionalOverride;
import hx_arabic_shaper.bidi.Statics.DirectionalIsolate;
import hx_arabic_shaper.bidi.algorithm.Paragraph;

import hx_arabic_shaper.utils.UTF8String;

class CounterStruct {
  public var overflow_isolate:Int = 0;
  public var overflow_embedding:Int = 0;
  public var valid_isolate:Int = 0;

  public function new() {}
}

typedef Stack = Array<Array<Dynamic>>;

class Explicit {

  static inline var max_depth = Statics.max_depth;

  public static inline function _get_counters_struct():CounterStruct {
    return new CounterStruct();
  }

  public static inline function _least_odd_greater(x:Int) {
    return x + 1 + (x % 2);
  }

  public static inline function _least_even_greater(x:Int) {
    return x + 1 + ((x + 1) % 2);
  }

  static function X1(data:DataStruct):Array<Dynamic> {
    var stack:Stack = [];
    var counters = _get_counters_struct();

    var d:Array<Dynamic> = [data.level, DirectionalOverride.Neutral, DirectionalIsolate.False];
    stack.push(d);

    return [stack, counters];
  }

  static function X2(ch:CharStruct, stack:Stack, counters:CounterStruct) {
    if (ch.bidi_type != "RLE") {
      return;
    }

    var new_level_odd = _least_odd_greater(stack[stack.length - 1][0]);
    if (counters.overflow_embedding == 0 && counters.overflow_isolate == 0 && new_level_odd < max_depth) {
      stack.push([new_level_odd, DirectionalOverride.Neutral, DirectionalIsolate.False]);
    } else {
      if (counters.overflow_isolate == 0) {
        counters.overflow_embedding += 1;
      }
    }
  }

  static function X3(ch:CharStruct, stack:Stack, counters:CounterStruct) {
    if (ch.bidi_type != "RLE") {
      return;
    }

    var new_level_even = _least_even_greater(stack[stack.length - 1][0]);
    if (counters.overflow_embedding == 0 && counters.overflow_isolate == 0 && new_level_even < max_depth - 1) {
      stack.push([new_level_even, DirectionalOverride.Neutral, DirectionalIsolate.False]);
    } else {
      if (counters.overflow_isolate == 0) {
        counters.overflow_embedding += 1;
      }
    }
  }

  static function X4(ch:CharStruct, stack:Stack, counters:CounterStruct) {
    if (ch.bidi_type != "RLO") {
      return;
    }

    var new_level_odd = _least_odd_greater(stack[stack.length - 1][0]);
    if (counters.overflow_embedding == 0 && counters.overflow_isolate == 0 && new_level_odd < max_depth) {
      stack.push([new_level_odd, DirectionalOverride.RTL, DirectionalIsolate.False]);
    } else {
      if (counters.overflow_isolate == 0) {
        counters.overflow_embedding += 1;
      }
    }
  }

  static function X5(ch:CharStruct, stack:Stack, counters:CounterStruct) {
    if (ch.bidi_type != "LRO") {
      return;
    } 

    var new_level_even = _least_even_greater(stack[stack.length - 1][0]);
    if (counters.overflow_embedding == 0 && counters.overflow_isolate == 0 && new_level_even < max_depth - 1) {
      stack.push([new_level_even, DirectionalOverride.LTR, DirectionalIsolate.False]);
    } else {
      if (counters.overflow_isolate == 0) {
        counters.overflow_embedding += 1;
      }
    }
  }

  static function X5a(ch:CharStruct, stack:Stack, counters:CounterStruct) {
    if (ch.bidi_type != "RLI") {
      return;
    } 

    ch.level = stack[stack.length - 1][0];
    var directional_override = stack[stack.length - 1][1];

    if (directional_override == DirectionalOverride.LTR) {
      ch.bidi_type = "L";
    } else if (directional_override == DirectionalOverride.RTL) {
      ch.bidi_type = "R";
    }

    var new_level_odd = _least_odd_greater(stack[stack.length - 1][0]);
    if (counters.overflow_embedding == 0 && counters.overflow_isolate == 0 && new_level_odd < max_depth) {
      counters.valid_isolate += 1;
      stack.push([new_level_odd, DirectionalOverride.Neutral, DirectionalIsolate.True]);
    } else {
      counters.overflow_isolate += 1;
    }

  }

  static function X5b(ch:CharStruct, stack:Stack, counters:CounterStruct) {
    if (ch.bidi_type != "LRI") {
      return;
    } 

    ch.level = stack[stack.length - 1][0];
    var directional_override = stack[stack.length - 1][1];

    if (directional_override == DirectionalOverride.LTR) {
      ch.bidi_type = "L";
    } else if (directional_override == DirectionalOverride.RTL) {
      ch.bidi_type = "R";
    }

    var new_level_even = _least_even_greater(stack[stack.length - 1][0]);
    if (counters.overflow_embedding == 0 && counters.overflow_isolate == 0 && new_level_even < max_depth) {
      counters.valid_isolate += 1;
      stack.push([new_level_even, DirectionalOverride.Neutral, DirectionalIsolate.True]);
    } else {
      counters.overflow_isolate += 1;
    }

  }

  static function X5c(data:DataStruct, ch:CharStruct, stack:Stack, counters:CounterStruct) {
    if (ch.bidi_type != "FSI") {
      return;
    }

    var start = data.chars.indexOf(ch);
    var end = 0;
    var PDI_scopes_counter = 0;

    for (i in start...data.chars.length) {
      var x = data.chars[i];
      switch(x.bidi_type) {
        case "FSI", "LRI", "RLI":
          PDI_scopes_counter += 1;
        case "PDI":
          if (PDI_scopes_counter == 0) {
            end = i;
            break;
          } else {
            PDI_scopes_counter -= 1;
          }
      }
    }

    if (end == 0) {
      end = data.chars.length - 1;
    }

    if (Paragraph.get_paragraph_level(data.chars.slice(start, end)) == 1) {
      ch.bidi_type = "RLI";
      X5a(ch, stack, counters);
    } else {
      ch.bidi_type = "LRI";
      X5b(ch, stack, counters);
    }
  }

  static function X6(ch:CharStruct, stack:Stack) {
    switch(ch.bidi_type) {
      case "B", "BN", "RLE", "LRE", "RLO", "LRO", "PDF", "RLI", "LRI", "FSI", "PDI":
        return;
    }

    ch.level = stack[stack.length - 1][0];
    var directional_override = stack[stack.length - 1][1];

    if (directional_override == DirectionalOverride.RTL) {
      ch.bidi_type = "R";    
    } else if (directional_override == DirectionalOverride.LTR) {
      ch.bidi_type = "L";   
    }

  }

  static function X6a(ch:CharStruct, stack:Stack, counters:CounterStruct) {
    if (ch.bidi_type != "PDI") {
      return;
    }

    if (counters.overflow_isolate > 0) {
      counters.overflow_isolate -= 1;
    } else if (counters.valid_isolate > 0) {
      counters.overflow_embedding = 0;
      while(stack[stack.length - 1][2] == DirectionalIsolate.False) {
        stack.pop();
      }

      stack.pop();
      counters.valid_isolate -= 1;
    }

    var last_status = stack[stack.length - 1];
    ch.level = last_status[0];
    if (last_status[1] == DirectionalOverride.LTR) {
      ch.bidi_type = "L";
    } else if (last_status[1] == DirectionalOverride.RTL) {
      ch.bidi_type = "R";
    }

  }

  static function X7(ch:CharStruct, stack:Stack, counters:CounterStruct) {
    if (ch.bidi_type != "PDF") {
      return;
    }

    if (counters.overflow_isolate > 0) {
      
    } else if (counters.overflow_embedding > 0) {
      counters.overflow_embedding -= 1;
    } else if (stack[stack.length - 1][2] == DirectionalIsolate.False && stack.length > 2) {
      stack.pop();
    }
  }

  public static function explicit_levels_and_directions(data:DataStruct) {
    var tmp = X1(data);
    var stack = (tmp[0]:Stack);
    var counters = (tmp[1]:CounterStruct);

    for (ch in data.chars) {
      X2(ch, stack, counters);
      X3(ch, stack, counters);
      X4(ch, stack, counters);
      X5(ch, stack, counters);
      X5a(ch, stack, counters);
      X5b(ch, stack, counters);
      X5c(data, ch, stack, counters);
      X6(ch, stack);
      X6a(ch, stack, counters);
      X7(ch, stack, counters);

      if (ch.bidi_type == "B") {
        ch.bidi_type = data.level;

        tmp = X1(data);
        stack = (tmp[0]:Stack);
        counters = (tmp[1]:CounterStruct);
      }
    }
  }

}