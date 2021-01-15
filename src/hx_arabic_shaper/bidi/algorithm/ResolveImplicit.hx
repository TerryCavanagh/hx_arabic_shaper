package hx_arabic_shaper.bidi.algorithm;

import hx_arabic_shaper.bidi.Statics;
import hx_arabic_shaper.bidi.Statics.*;

class ResolveImplicit {
  static function I1(ch:CharStruct) {
    if (ch.level % 2 == 0) {
      switch (ch.bidi_type) {
        case "R":
          ch.level += 1;
        case 'AN', 'EN':
          ch.level += 2;
      }
    }
  }

  static function I2(ch:CharStruct) {
    if (ch.level % 2 == 1) {
      switch (ch.bidi_type) {
        case 'L', 'AN', 'EN':
          ch.level += 1;
      }
    }
  }

  public static function resolve_implicit_levels(data:DataStruct) {
    for (ch in data.chars) {
      I1(ch);
      I2(ch);
    }
  }
}