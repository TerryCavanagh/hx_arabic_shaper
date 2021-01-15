package hx_arabic_shaper.utils;

// Map iteration order is undefined and I couldn't find one implementation which maintains the order of additions
//so I made this quick "implementation" (it's not an actual Map implementation)
abstract ArrayMap<K, V>(Array<{key:K, value:V}>) {
  public inline function new() this = [];

  public inline function exists(key:K) {
    var r = false;
    for(v in this) {
      if(v.key == key) {
        r = true;
        break;
      }
    }
    return r;
  }

  public inline function get(key:K) {
    var r = null;
    for(v in this) {
      if (v.key == key) {
        r = v.value;
        break;
      }
    }
    return r;
  }

  public inline function set(key:K, value:V) {
    remove(key);
    this.push({key:key, value:value});
  }

  public inline function remove(key:K) {
    var val = null;
    for(v in this) {
      if(v.key == key) {
        val = v;
        break;
      }
    }
    if(val == null) {
      return false;
    } else {
      return this.remove(val);
    }
  }

  private function keyfilter(e:{key:K, value:V}):K {
    return e.key;
  }
  public inline function keys() {
    return this.map(keyfilter).iterator();
  }
  
  private function valuefilter(e:{key:K, value:V}):V {
    return e.value;
  }
  public inline function iterator() {
    return this.map(valuefilter).iterator();
  }
}