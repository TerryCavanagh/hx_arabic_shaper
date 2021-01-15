package hx_arabic_shaper.bidi;

import haxe.Utf8;
import hx_arabic_shaper.utils.UTF8String;

@:enum abstract DirectionalOverride(Int) from Int to Int {
  var Neutral = 0;
  var RTL = 1;
  var LTR = 2;
}

@:enum abstract DirectionalIsolate(Int) from Int to Int {
  var True = 1;
  var False = 0;
}

class Statics {

  public static inline var max_depth = 125;

  public static inline function _get_isolating_run_sequence_struct():IsolatingRunSequenceStruct {
    return new IsolatingRunSequenceStruct();
  }

  public static inline function _get_char_struct():CharStruct {
    return new CharStruct();
  }

  public static inline function _get_data_struct():DataStruct {
    return new DataStruct();
  }

}

class IsolatingRunSequenceStruct {
  public var chars:Array<CharStruct> = [];
  public var sos_type:UTF8String = null;
  public var eos_type:UTF8String = null;
  public var embedding_level:Int = 0;
  public var embedding_direction:UTF8String = "";

  public function new() {}
}

class CharStruct {
  public var ch:UTF8String = "";
  public var bidi_type:UTF8String = null;
  public var level:Dynamic = null;

  public var charcode(get,never):Int;

  inline function get_charcode() {
    return Utf8.charCodeAt(ch, 0);
  }
  
  public function new() {}
}

class DataStruct {
  public var level:Dynamic = null;
  public var chars:Array<CharStruct> = [];
  public var isolating_run_sequences:Array<IsolatingRunSequenceStruct> = [];

  public function new() {}
}
