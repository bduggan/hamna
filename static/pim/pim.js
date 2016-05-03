k = 10000;
function next_id() {
    k = k + 1;
    return k;
}
function gen(el) {
    return function() {
        var args = Array.from(arguments);
        var attrs = { key: next_id() };
        var contents = [];
        if (typeof(args[0]) == 'object'
             && !Array.isArray(args[0])
             && !args[0]['type']
        ) {
            attrs = args.shift()
            if (args.length == 0 ) {
              return React.createElement(el,attrs);
            }
        }
        if (! Array.isArray(args[0]) ) {
            attrs['key'] = next_id();
            return React.createElement(el,attrs,args);
        }
        contents = args.shift();
        return contents.map( function(v) {
            attrs['key'] = next_id();
            return React.createElement(el, attrs, v)
        } )
    }
}

function escape(str) {
  return str.replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}
function unescape(str) {
    return str.replace('&amp;', '&', 'g')
    .replace('&lt;','<','g')
    .replace('&gt;','>','g')
    .replace('&quot;', '"', 'g')
    .replace('&apos;', "'", 'g')
}
function pad(p) {
    if ( p > 9 ) return p;
    return '0' + p;
}
Date.prototype.addDays = function(days) {
    var result = new Date(this);
    result.setDate(result.getDate() + days);
    return result;
}
Date.prototype.ymd = function(d) {
    return [ 1900+this.getYear(), pad(this.getMonth()), pad(this.getDate())].join('-');
}
Date.prototype.d = function(d) {
    return pad(this.getDate())
}
