(function(scope){
'use strict';

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}




// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**_UNUSED/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**_UNUSED/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**/
	if (typeof x.$ === 'undefined')
	//*/
	/**_UNUSED/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0 = 0;
var _Utils_Tuple0_UNUSED = { $: '#0' };

function _Utils_Tuple2(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2_UNUSED(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3_UNUSED(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr(c) { return c; }
function _Utils_chr_UNUSED(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil = { $: 0 };
var _List_Nil_UNUSED = { $: '[]' };

function _List_Cons(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons_UNUSED(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log = F2(function(tag, value)
{
	return value;
});

var _Debug_log_UNUSED = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString(value)
{
	return '<internals>';
}

function _Debug_toString_UNUSED(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash_UNUSED(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.k.ar === region.i.ar)
	{
		return 'on line ' + region.k.ar;
	}
	return 'on lines ' + region.k.ar + ' through ' + region.i.ar;
}



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**_UNUSED/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap_UNUSED(value) { return { $: 0, a: value }; }
function _Json_unwrap_UNUSED(value) { return value.a; }

function _Json_wrap(value) { return value; }
function _Json_unwrap(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		c: null
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			});
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.dj,
		impl.dZ,
		impl.dU,
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
{
	var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
	$elm$core$Result$isOk(result) || _Debug_crash(2 /**_UNUSED/, _Json_errorToString(result.a) /**/);
	var managers = {};
	var initPair = init(result.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);

	function sendToApp(msg, viewMetadata)
	{
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsDebug('Elm', scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}




// HELPERS


var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

var _VirtualDom_init = F4(function(virtualNode, flagDecoder, debugMetadata, args)
{
	// NOTE: this function needs _Platform_export available to work

	/**/
	var node = args['node'];
	//*/
	/**_UNUSED/
	var node = args && args['node'] ? args['node'] : _Debug_crash(0);
	//*/

	node.parentNode.replaceChild(
		_VirtualDom_render(virtualNode, function() {}),
		node
	);

	return {};
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: 0,
		a: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 1,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 2,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: 3,
		d: _VirtualDom_organizeFacts(factList),
		g: model,
		h: render,
		i: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: 4,
		j: tagger,
		k: node,
		b: 1 + (node.b || 0)
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: 5,
		l: refs,
		m: thunk,
		k: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a0',
		n: key,
		o: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a1',
		n: key,
		o: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a2',
		n: key,
		o: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a3',
		n: key,
		o: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a4',
		n: key,
		o: { f: namespace, o: value }
	};
});



// XSS ATTACK VECTOR CHECKS
//
// For some reason, tabs can appear in href protocols and it still works.
// So '\tjava\tSCRIPT:alert("!!!")' and 'javascript:alert("!!!")' are the same
// in practice. That is why _VirtualDom_RE_js and _VirtualDom_RE_js_html look
// so freaky.
//
// Pulling the regular expressions out to the top level gives a slight speed
// boost in small benchmarks (4-10%) but hoisting values to reduce allocation
// can be unpredictable in large programs where JIT may have a harder time with
// functions are not fully self-contained. The benefit is more that the js and
// js_html ones are so weird that I prefer to see them near each other.


var _VirtualDom_RE_script = /^script$/i;
var _VirtualDom_RE_on_formAction = /^(on|formAction$)/i;
var _VirtualDom_RE_js = /^\s*j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:/i;
var _VirtualDom_RE_js_html = /^\s*(j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:|d\s*a\s*t\s*a\s*:\s*t\s*e\s*x\s*t\s*\/\s*h\s*t\s*m\s*l\s*(,|;))/i;


function _VirtualDom_noScript(tag)
{
	return _VirtualDom_RE_script.test(tag) ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return _VirtualDom_RE_on_formAction.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return _VirtualDom_RE_js.test(value)
		? /**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return _VirtualDom_RE_js_html.test(value)
		? /**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlJson(value)
{
	return (typeof _Json_unwrap(value) === 'string' && _VirtualDom_RE_js_html.test(_Json_unwrap(value)))
		? _Json_wrap(
			/**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		) : value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a0')
		? A2(_VirtualDom_on, attr.n, _VirtualDom_mapHandler(func, attr.o))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2($elm$json$Json$Decode$map, func, handler.a)
				:
			A3($elm$json$Json$Decode$map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				$elm$json$Json$Decode$succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return _Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		V: func(record.V),
		br: record.br,
		bm: record.bm
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	for (var facts = {}; factList.b; factList = factList.b) // WHILE_CONS
	{
		var entry = factList.a;

		var tag = entry.$;
		var key = entry.n;
		var value = entry.o;

		if (tag === 'a2')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, _Json_unwrap(value))
				: facts[key] = _Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a3' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === 5)
	{
		return _VirtualDom_render(vNode.k || (vNode.k = vNode.m()), eventNode);
	}

	if (tag === 0)
	{
		return _VirtualDom_doc.createTextNode(vNode.a);
	}

	if (tag === 4)
	{
		var subNode = vNode.k;
		var tagger = vNode.j;

		while (subNode.$ === 4)
		{
			typeof tagger !== 'object'
				? tagger = [tagger, subNode.j]
				: tagger.push(subNode.j);

			subNode = subNode.k;
		}

		var subEventRoot = { j: tagger, p: eventNode };
		var domNode = _VirtualDom_render(subNode, subEventRoot);
		domNode.elm_event_node_ref = subEventRoot;
		return domNode;
	}

	if (tag === 3)
	{
		var domNode = vNode.h(vNode.g);
		_VirtualDom_applyFacts(domNode, eventNode, vNode.d);
		return domNode;
	}

	// at this point `tag` must be 1 or 2

	var domNode = vNode.f
		? _VirtualDom_doc.createElementNS(vNode.f, vNode.c)
		: _VirtualDom_doc.createElement(vNode.c);

	if (_VirtualDom_divertHrefToApp && vNode.c == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, vNode.d);

	for (var kids = vNode.e, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === 1 ? kids[i] : kids[i].b, eventNode));
	}

	return domNode;
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		key === 'a1'
			? _VirtualDom_applyStyles(domNode, value)
			:
		key === 'a0'
			? _VirtualDom_applyEvents(domNode, eventNode, value)
			:
		key === 'a3'
			? _VirtualDom_applyAttrs(domNode, value)
			:
		key === 'a4'
			? _VirtualDom_applyAttrsNS(domNode, value)
			:
		((key !== 'value' && key !== 'checked') || domNode[key] !== value) && (domNode[key] = value);
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		typeof value !== 'undefined'
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		typeof value !== 'undefined'
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			allCallbacks[key] = undefined;
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.q;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.q = newHandler;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: $elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(eventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.q;
		var result = _Json_runHelp(handler.a, event);

		if (!$elm$core$Result$isOk(result))
		{
			return;
		}

		var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.V;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.br;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.bm) && event.preventDefault(),
			eventNode
		);
		var tagger;
		var i;
		while (tagger = currentEventNode.j)
		{
			if (typeof tagger == 'function')
			{
				message = tagger(message);
			}
			else
			{
				for (var i = tagger.length; i--; )
				{
					message = tagger[i](message);
				}
			}
			currentEventNode = currentEventNode.p;
		}
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.q = initialHandler;

	return callback;
}

function _VirtualDom_equalEvents(x, y)
{
	return x.$ == y.$ && _Json_equality(x.a, y.a);
}



// DIFF


// TODO: Should we do patches like in iOS?
//
// type Patch
//   = At Int Patch
//   | Batch (List Patch)
//   | Change ...
//
// How could it not be better?
//
function _VirtualDom_diff(x, y)
{
	var patches = [];
	_VirtualDom_diffHelp(x, y, patches, 0);
	return patches;
}


function _VirtualDom_pushPatch(patches, type, index, data)
{
	var patch = {
		$: type,
		r: index,
		s: data,
		t: undefined,
		u: undefined
	};
	patches.push(patch);
	return patch;
}


function _VirtualDom_diffHelp(x, y, patches, index)
{
	if (x === y)
	{
		return;
	}

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === 1 && yType === 2)
		{
			y = _VirtualDom_dekey(y);
			yType = 1;
		}
		else
		{
			_VirtualDom_pushPatch(patches, 0, index, y);
			return;
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case 5:
			var xRefs = x.l;
			var yRefs = y.l;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.k = x.k;
				return;
			}
			y.k = y.m();
			var subPatches = [];
			_VirtualDom_diffHelp(x.k, y.k, subPatches, 0);
			subPatches.length > 0 && _VirtualDom_pushPatch(patches, 1, index, subPatches);
			return;

		case 4:
			// gather nested taggers
			var xTaggers = x.j;
			var yTaggers = y.j;
			var nesting = false;

			var xSubNode = x.k;
			while (xSubNode.$ === 4)
			{
				nesting = true;

				typeof xTaggers !== 'object'
					? xTaggers = [xTaggers, xSubNode.j]
					: xTaggers.push(xSubNode.j);

				xSubNode = xSubNode.k;
			}

			var ySubNode = y.k;
			while (ySubNode.$ === 4)
			{
				nesting = true;

				typeof yTaggers !== 'object'
					? yTaggers = [yTaggers, ySubNode.j]
					: yTaggers.push(ySubNode.j);

				ySubNode = ySubNode.k;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && xTaggers.length !== yTaggers.length)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !_VirtualDom_pairwiseRefEqual(xTaggers, yTaggers) : xTaggers !== yTaggers)
			{
				_VirtualDom_pushPatch(patches, 2, index, yTaggers);
			}

			// diff everything below the taggers
			_VirtualDom_diffHelp(xSubNode, ySubNode, patches, index + 1);
			return;

		case 0:
			if (x.a !== y.a)
			{
				_VirtualDom_pushPatch(patches, 3, index, y.a);
			}
			return;

		case 1:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKids);
			return;

		case 2:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKeyedKids);
			return;

		case 3:
			if (x.h !== y.h)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
			factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

			var patch = y.i(x.g, y.g);
			patch && _VirtualDom_pushPatch(patches, 5, index, patch);

			return;
	}
}

// assumes the incoming arrays are the same length
function _VirtualDom_pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}

function _VirtualDom_diffNodes(x, y, patches, index, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.c !== y.c || x.f !== y.f)
	{
		_VirtualDom_pushPatch(patches, 0, index, y);
		return;
	}

	var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
	factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

	diffKids(x, y, patches, index);
}



// DIFF FACTS


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function _VirtualDom_diffFacts(x, y, category)
{
	var diff;

	// look for changes and removals
	for (var xKey in x)
	{
		if (xKey === 'a1' || xKey === 'a0' || xKey === 'a3' || xKey === 'a4')
		{
			var subDiff = _VirtualDom_diffFacts(x[xKey], y[xKey] || {}, xKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[xKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(xKey in y))
		{
			diff = diff || {};
			diff[xKey] =
				!category
					? (typeof x[xKey] === 'string' ? '' : null)
					:
				(category === 'a1')
					? ''
					:
				(category === 'a0' || category === 'a3')
					? undefined
					:
				{ f: x[xKey].f, o: undefined };

			continue;
		}

		var xValue = x[xKey];
		var yValue = y[xKey];

		// reference equal, so don't worry about it
		if (xValue === yValue && xKey !== 'value' && xKey !== 'checked'
			|| category === 'a0' && _VirtualDom_equalEvents(xValue, yValue))
		{
			continue;
		}

		diff = diff || {};
		diff[xKey] = yValue;
	}

	// add new stuff
	for (var yKey in y)
	{
		if (!(yKey in x))
		{
			diff = diff || {};
			diff[yKey] = y[yKey];
		}
	}

	return diff;
}



// DIFF KIDS


function _VirtualDom_diffKids(xParent, yParent, patches, index)
{
	var xKids = xParent.e;
	var yKids = yParent.e;

	var xLen = xKids.length;
	var yLen = yKids.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		_VirtualDom_pushPatch(patches, 6, index, {
			v: yLen,
			i: xLen - yLen
		});
	}
	else if (xLen < yLen)
	{
		_VirtualDom_pushPatch(patches, 7, index, {
			v: xLen,
			e: yKids
		});
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var xKid = xKids[i];
		_VirtualDom_diffHelp(xKid, yKids[i], patches, ++index);
		index += xKid.b || 0;
	}
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(xParent, yParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var xKids = xParent.e;
	var yKids = yParent.e;
	var xLen = xKids.length;
	var yLen = yKids.length;
	var xIndex = 0;
	var yIndex = 0;

	var index = rootIndex;

	while (xIndex < xLen && yIndex < yLen)
	{
		var x = xKids[xIndex];
		var y = yKids[yIndex];

		var xKey = x.a;
		var yKey = y.a;
		var xNode = x.b;
		var yNode = y.b;

		var newMatch = undefined;
		var oldMatch = undefined;

		// check if keys match

		if (xKey === yKey)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNode, localPatches, index);
			index += xNode.b || 0;

			xIndex++;
			yIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var xNext = xKids[xIndex + 1];
		var yNext = yKids[yIndex + 1];

		if (xNext)
		{
			var xNextKey = xNext.a;
			var xNextNode = xNext.b;
			oldMatch = yKey === xNextKey;
		}

		if (yNext)
		{
			var yNextKey = yNext.a;
			var yNextNode = yNext.b;
			newMatch = xKey === yNextKey;
		}


		// swap x and y
		if (newMatch && oldMatch)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			_VirtualDom_insertNode(changes, localPatches, xKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNextNode, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		// insert y
		if (newMatch)
		{
			index++;
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			index += xNode.b || 0;

			xIndex += 1;
			yIndex += 2;
			continue;
		}

		// remove x
		if (oldMatch)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 1;
			continue;
		}

		// remove x, insert y
		if (xNext && xNextKey === yNextKey)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNextNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (xIndex < xLen)
	{
		index++;
		var x = xKids[xIndex];
		var xNode = x.b;
		_VirtualDom_removeNode(changes, localPatches, x.a, xNode, index);
		index += xNode.b || 0;
		xIndex++;
	}

	while (yIndex < yLen)
	{
		var endInserts = endInserts || [];
		var y = yKids[yIndex];
		_VirtualDom_insertNode(changes, localPatches, y.a, y.b, undefined, endInserts);
		yIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || endInserts)
	{
		_VirtualDom_pushPatch(patches, 8, rootIndex, {
			w: localPatches,
			x: inserts,
			y: endInserts
		});
	}
}



// CHANGES FROM KEYED DIFF


var _VirtualDom_POSTFIX = '_elmW6BL';


function _VirtualDom_insertNode(changes, localPatches, key, vnode, yIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		entry = {
			c: 0,
			z: vnode,
			r: yIndex,
			s: undefined
		};

		inserts.push({ r: yIndex, A: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.c === 1)
	{
		inserts.push({ r: yIndex, A: entry });

		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(entry.z, vnode, subPatches, entry.r);
		entry.r = yIndex;
		entry.s.s = {
			w: subPatches,
			A: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	_VirtualDom_insertNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, yIndex, inserts);
}


function _VirtualDom_removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		var patch = _VirtualDom_pushPatch(localPatches, 9, index, undefined);

		changes[key] = {
			c: 1,
			z: vnode,
			r: index,
			s: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.c === 0)
	{
		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(vnode, entry.z, subPatches, index);

		_VirtualDom_pushPatch(localPatches, 9, index, {
			w: subPatches,
			A: entry
		});

		return;
	}

	// this key has already been removed or moved, a duplicate!
	_VirtualDom_removeNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, index);
}



// ADD DOM NODES
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function _VirtualDom_addDomNodes(domNode, vNode, patches, eventNode)
{
	_VirtualDom_addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.b, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function _VirtualDom_addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.r;

	while (index === low)
	{
		var patchType = patch.$;

		if (patchType === 1)
		{
			_VirtualDom_addDomNodes(domNode, vNode.k, patch.s, eventNode);
		}
		else if (patchType === 8)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var subPatches = patch.s.w;
			if (subPatches.length > 0)
			{
				_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 9)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var data = patch.s;
			if (data)
			{
				data.A.s = domNode;
				var subPatches = data.w;
				if (subPatches.length > 0)
				{
					_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.t = domNode;
			patch.u = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.r) > high)
		{
			return i;
		}
	}

	var tag = vNode.$;

	if (tag === 4)
	{
		var subNode = vNode.k;

		while (subNode.$ === 4)
		{
			subNode = subNode.k;
		}

		return _VirtualDom_addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);
	}

	// tag must be 1 or 2 at this point

	var vKids = vNode.e;
	var childNodes = domNode.childNodes;
	for (var j = 0; j < vKids.length; j++)
	{
		low++;
		var vKid = tag === 1 ? vKids[j] : vKids[j].b;
		var nextLow = low + (vKid.b || 0);
		if (low <= index && index <= nextLow)
		{
			i = _VirtualDom_addDomNodesHelp(childNodes[j], vKid, patches, i, low, nextLow, eventNode);
			if (!(patch = patches[i]) || (index = patch.r) > high)
			{
				return i;
			}
		}
		low = nextLow;
	}
	return i;
}



// APPLY PATCHES


function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	_VirtualDom_addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return _VirtualDom_applyPatchesHelp(rootDomNode, patches);
}

function _VirtualDom_applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.t
		var newNode = _VirtualDom_applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function _VirtualDom_applyPatch(domNode, patch)
{
	switch (patch.$)
	{
		case 0:
			return _VirtualDom_applyPatchRedraw(domNode, patch.s, patch.u);

		case 4:
			_VirtualDom_applyFacts(domNode, patch.u, patch.s);
			return domNode;

		case 3:
			domNode.replaceData(0, domNode.length, patch.s);
			return domNode;

		case 1:
			return _VirtualDom_applyPatchesHelp(domNode, patch.s);

		case 2:
			if (domNode.elm_event_node_ref)
			{
				domNode.elm_event_node_ref.j = patch.s;
			}
			else
			{
				domNode.elm_event_node_ref = { j: patch.s, p: patch.u };
			}
			return domNode;

		case 6:
			var data = patch.s;
			for (var i = 0; i < data.i; i++)
			{
				domNode.removeChild(domNode.childNodes[data.v]);
			}
			return domNode;

		case 7:
			var data = patch.s;
			var kids = data.e;
			var i = data.v;
			var theEnd = domNode.childNodes[i];
			for (; i < kids.length; i++)
			{
				domNode.insertBefore(_VirtualDom_render(kids[i], patch.u), theEnd);
			}
			return domNode;

		case 9:
			var data = patch.s;
			if (!data)
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.A;
			if (typeof entry.r !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.s = _VirtualDom_applyPatchesHelp(domNode, data.w);
			return domNode;

		case 8:
			return _VirtualDom_applyPatchReorder(domNode, patch);

		case 5:
			return patch.s(domNode);

		default:
			_Debug_crash(10); // 'Ran into an unknown patch!'
	}
}


function _VirtualDom_applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = _VirtualDom_render(vNode, eventNode);

	if (!newNode.elm_event_node_ref)
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function _VirtualDom_applyPatchReorder(domNode, patch)
{
	var data = patch.s;

	// remove end inserts
	var frag = _VirtualDom_applyPatchReorderEndInsertsHelp(data.y, patch);

	// removals
	domNode = _VirtualDom_applyPatchesHelp(domNode, data.w);

	// inserts
	var inserts = data.x;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.A;
		var node = entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u);
		domNode.insertBefore(node, domNode.childNodes[insert.r]);
	}

	// add end inserts
	if (frag)
	{
		_VirtualDom_appendChild(domNode, frag);
	}

	return domNode;
}


function _VirtualDom_applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (!endInserts)
	{
		return;
	}

	var frag = _VirtualDom_doc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.A;
		_VirtualDom_appendChild(frag, entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u)
		);
	}
	return frag;
}


function _VirtualDom_virtualize(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		return _VirtualDom_text(node.textContent);
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return _VirtualDom_text('');
	}


	// ELEMENT NODES

	var attrList = _List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;
		attrList = _List_Cons( A2(_VirtualDom_attribute, name, value), attrList );
	}

	var tag = node.tagName.toLowerCase();
	var kidList = _List_Nil;
	var kids = node.childNodes;

	for (var i = kids.length; i--; )
	{
		kidList = _List_Cons(_VirtualDom_virtualize(kids[i]), kidList);
	}
	return A3(_VirtualDom_node, tag, attrList, kidList);
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.e;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return {
		$: 1,
		c: keyedNode.c,
		d: keyedNode.d,
		e: kids,
		f: keyedNode.f,
		b: keyedNode.b
	};
}




// ELEMENT


var _Debugger_element;

var _Browser_element = _Debugger_element || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.dj,
		impl.dZ,
		impl.dU,
		function(sendToApp, initialModel) {
			var view = impl.d_;
			/**/
			var domNode = args['node'];
			//*/
			/**_UNUSED/
			var domNode = args && args['node'] ? args['node'] : _Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = view(model);
				var patches = _VirtualDom_diff(currNode, nextNode);
				domNode = _VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
});



// DOCUMENT


var _Debugger_document;

var _Browser_document = _Debugger_document || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.dj,
		impl.dZ,
		impl.dU,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.bn && impl.bn(sendToApp)
			var view = impl.d_;
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				var doc = view(model);
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.cW);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.dY) && (_VirtualDom_doc.title = title = doc.dY);
			});
		}
	);
});



// ANIMATION


var _Browser_cancelAnimationFrame =
	typeof cancelAnimationFrame !== 'undefined'
		? cancelAnimationFrame
		: function(id) { clearTimeout(id); };

var _Browser_requestAnimationFrame =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };


function _Browser_makeAnimator(model, draw)
{
	draw(model);

	var state = 0;

	function updateIfNeeded()
	{
		state = state === 1
			? 0
			: ( _Browser_requestAnimationFrame(updateIfNeeded), draw(model), 1 );
	}

	return function(nextModel, isSync)
	{
		model = nextModel;

		isSync
			? ( draw(model),
				state === 2 && (state = 1)
				)
			: ( state === 0 && _Browser_requestAnimationFrame(updateIfNeeded),
				state = 2
				);
	};
}



// APPLICATION


function _Browser_application(impl)
{
	var onUrlChange = impl.dF;
	var onUrlRequest = impl.dG;
	var key = function() { key.a(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
		bn: function(sendToApp)
		{
			key.a = sendToApp;
			_Browser_window.addEventListener('popstate', key);
			_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

			return F2(function(domNode, event)
			{
				if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download'))
				{
					event.preventDefault();
					var href = domNode.href;
					var curr = _Browser_getUrl();
					var next = $elm$url$Url$fromString(href).a;
					sendToApp(onUrlRequest(
						(next
							&& curr.cq === next.cq
							&& curr.b0 === next.b0
							&& curr.cn.a === next.cn.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		dj: function(flags)
		{
			return A3(impl.dj, flags, _Browser_getUrl(), key);
		},
		d_: impl.d_,
		dZ: impl.dZ,
		dU: impl.dU
	});
}

function _Browser_getUrl()
{
	return $elm$url$Url$fromString(_VirtualDom_doc.location.href).a || _Debug_crash(1);
}

var _Browser_go = F2(function(key, n)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
});

var _Browser_pushUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
});

var _Browser_replaceUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
});



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_on = F3(function(node, eventName, sendToSelf)
{
	return _Scheduler_spawn(_Scheduler_binding(function(callback)
	{
		function handler(event)	{ _Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, _VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
});

var _Browser_decodeEvent = F2(function(decoder, event)
{
	var result = _Json_runHelp(decoder, event);
	return $elm$core$Result$isOk(result) ? $elm$core$Maybe$Just(result.a) : $elm$core$Maybe$Nothing;
});



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof _VirtualDom_doc.hidden !== 'undefined')
		? { dg: 'hidden', c0: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { dg: 'mozHidden', c0: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { dg: 'msHidden', c0: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { dg: 'webkitHidden', c0: 'webkitvisibilitychange' }
		: { dg: 'hidden', c0: 'visibilitychange' };
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return _Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? _Scheduler_succeed(doStuff(node))
				: _Scheduler_fail($elm$browser$Browser$Dom$NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = F2(function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return _Utils_Tuple0;
	});
});



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		cy: _Browser_getScene(),
		cM: {
			d1: _Browser_window.pageXOffset,
			d3: _Browser_window.pageYOffset,
			d$: _Browser_doc.documentElement.clientWidth,
			df: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		d$: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		df: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = F2(function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return _Utils_Tuple0;
	});
});



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			cy: {
				d$: node.scrollWidth,
				df: node.scrollHeight
			},
			cM: {
				d1: node.scrollLeft,
				d3: node.scrollTop,
				d$: node.clientWidth,
				df: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = F3(function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return _Utils_Tuple0;
	});
});



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			cy: _Browser_getScene(),
			cM: {
				d1: x,
				d3: y,
				d$: _Browser_doc.documentElement.clientWidth,
				df: _Browser_doc.documentElement.clientHeight
			},
			c9: {
				d1: x + rect.left,
				d3: y + rect.top,
				d$: rect.width,
				df: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		_VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			_VirtualDom_doc.location.reload(false);
		}
	}));
}



function _Time_now(millisToPosix)
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(millisToPosix(Date.now())));
	});
}

var _Time_setInterval = F2(function(interval, task)
{
	return _Scheduler_binding(function(callback)
	{
		var id = setInterval(function() { _Scheduler_rawSpawn(task); }, interval);
		return function() { clearInterval(id); };
	});
});

function _Time_here()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(
			A2($elm$time$Time$customZone, -(new Date().getTimezoneOffset()), _List_Nil)
		));
	});
}


function _Time_getZoneName()
{
	return _Scheduler_binding(function(callback)
	{
		try
		{
			var name = $elm$time$Time$Name(Intl.DateTimeFormat().resolvedOptions().timeZone);
		}
		catch (e)
		{
			var name = $elm$time$Time$Offset(new Date().getTimezoneOffset());
		}
		callback(_Scheduler_succeed(name));
	});
}



var _Bitwise_and = F2(function(a, b)
{
	return a & b;
});

var _Bitwise_or = F2(function(a, b)
{
	return a | b;
});

var _Bitwise_xor = F2(function(a, b)
{
	return a ^ b;
});

function _Bitwise_complement(a)
{
	return ~a;
};

var _Bitwise_shiftLeftBy = F2(function(offset, a)
{
	return a << offset;
});

var _Bitwise_shiftRightBy = F2(function(offset, a)
{
	return a >> offset;
});

var _Bitwise_shiftRightZfBy = F2(function(offset, a)
{
	return a >>> offset;
});




// STRINGS


var _Parser_isSubString = F5(function(smallString, offset, row, col, bigString)
{
	var smallLength = smallString.length;
	var isGood = offset + smallLength <= bigString.length;

	for (var i = 0; isGood && i < smallLength; )
	{
		var code = bigString.charCodeAt(offset);
		isGood =
			smallString[i++] === bigString[offset++]
			&& (
				code === 0x000A /* \n */
					? ( row++, col=1 )
					: ( col++, (code & 0xF800) === 0xD800 ? smallString[i++] === bigString[offset++] : 1 )
			)
	}

	return _Utils_Tuple3(isGood ? offset : -1, row, col);
});



// CHARS


var _Parser_isSubChar = F3(function(predicate, offset, string)
{
	return (
		string.length <= offset
			? -1
			:
		(string.charCodeAt(offset) & 0xF800) === 0xD800
			? (predicate(_Utils_chr(string.substr(offset, 2))) ? offset + 2 : -1)
			:
		(predicate(_Utils_chr(string[offset]))
			? ((string[offset] === '\n') ? -2 : (offset + 1))
			: -1
		)
	);
});


var _Parser_isAsciiCode = F3(function(code, offset, string)
{
	return string.charCodeAt(offset) === code;
});



// NUMBERS


var _Parser_chompBase10 = F2(function(offset, string)
{
	for (; offset < string.length; offset++)
	{
		var code = string.charCodeAt(offset);
		if (code < 0x30 || 0x39 < code)
		{
			return offset;
		}
	}
	return offset;
});


var _Parser_consumeBase = F3(function(base, offset, string)
{
	for (var total = 0; offset < string.length; offset++)
	{
		var digit = string.charCodeAt(offset) - 0x30;
		if (digit < 0 || base <= digit) break;
		total = base * total + digit;
	}
	return _Utils_Tuple2(offset, total);
});


var _Parser_consumeBase16 = F2(function(offset, string)
{
	for (var total = 0; offset < string.length; offset++)
	{
		var code = string.charCodeAt(offset);
		if (0x30 <= code && code <= 0x39)
		{
			total = 16 * total + code - 0x30;
		}
		else if (0x41 <= code && code <= 0x46)
		{
			total = 16 * total + code - 55;
		}
		else if (0x61 <= code && code <= 0x66)
		{
			total = 16 * total + code - 87;
		}
		else
		{
			break;
		}
	}
	return _Utils_Tuple2(offset, total);
});



// FIND STRING


var _Parser_findSubString = F5(function(smallString, offset, row, col, bigString)
{
	var newOffset = bigString.indexOf(smallString, offset);
	var target = newOffset < 0 ? bigString.length : newOffset + smallString.length;

	while (offset < target)
	{
		var code = bigString.charCodeAt(offset++);
		code === 0x000A /* \n */
			? ( col=1, row++ )
			: ( col++, (code & 0xF800) === 0xD800 && offset++ )
	}

	return _Utils_Tuple3(newOffset, row, col);
});


// CREATE

var _Regex_never = /.^/;

var _Regex_fromStringWith = F2(function(options, string)
{
	var flags = 'g';
	if (options.du) { flags += 'm'; }
	if (options.c$) { flags += 'i'; }

	try
	{
		return $elm$core$Maybe$Just(new RegExp(string, flags));
	}
	catch(error)
	{
		return $elm$core$Maybe$Nothing;
	}
});


// USE

var _Regex_contains = F2(function(re, string)
{
	return string.match(re) !== null;
});


var _Regex_findAtMost = F3(function(n, re, str)
{
	var out = [];
	var number = 0;
	var string = str;
	var lastIndex = re.lastIndex;
	var prevLastIndex = -1;
	var result;
	while (number++ < n && (result = re.exec(string)))
	{
		if (prevLastIndex == re.lastIndex) break;
		var i = result.length - 1;
		var subs = new Array(i);
		while (i > 0)
		{
			var submatch = result[i];
			subs[--i] = submatch
				? $elm$core$Maybe$Just(submatch)
				: $elm$core$Maybe$Nothing;
		}
		out.push(A4($elm$regex$Regex$Match, result[0], result.index, number, _List_fromArray(subs)));
		prevLastIndex = re.lastIndex;
	}
	re.lastIndex = lastIndex;
	return _List_fromArray(out);
});


var _Regex_replaceAtMost = F4(function(n, re, replacer, string)
{
	var count = 0;
	function jsReplacer(match)
	{
		if (count++ >= n)
		{
			return match;
		}
		var i = arguments.length - 3;
		var submatches = new Array(i);
		while (i > 0)
		{
			var submatch = arguments[i];
			submatches[--i] = submatch
				? $elm$core$Maybe$Just(submatch)
				: $elm$core$Maybe$Nothing;
		}
		return replacer(A4($elm$regex$Regex$Match, match, arguments[arguments.length - 2], count, _List_fromArray(submatches)));
	}
	return string.replace(re, jsReplacer);
});

var _Regex_splitAtMost = F3(function(n, re, str)
{
	var string = str;
	var out = [];
	var start = re.lastIndex;
	var restoreLastIndex = re.lastIndex;
	while (n--)
	{
		var result = re.exec(string);
		if (!result) break;
		out.push(string.slice(start, result.index));
		start = re.lastIndex;
	}
	out.push(string.slice(start));
	re.lastIndex = restoreLastIndex;
	return _List_fromArray(out);
});

var _Regex_infinity = Infinity;


function _Url_percentEncode(string)
{
	return encodeURIComponent(string);
}

function _Url_percentDecode(string)
{
	try
	{
		return $elm$core$Maybe$Just(decodeURIComponent(string));
	}
	catch (e)
	{
		return $elm$core$Maybe$Nothing;
	}
}var $elm$core$Basics$EQ = 1;
var $elm$core$Basics$GT = 2;
var $elm$core$Basics$LT = 0;
var $elm$core$List$cons = _List_cons;
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === -2) {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (!node.$) {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Result$Err = function (a) {
	return {$: 1, a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 0, a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 2, a: a};
};
var $elm$core$Basics$False = 1;
var $elm$core$Basics$add = _Basics_add;
var $elm$core$Maybe$Just = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Maybe$Nothing = {$: 1};
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\n    ',
		A2($elm$core$String$split, '\n', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\n\n(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 0:
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 1) {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\'' + (f + '\']'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 1:
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 2:
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\n\n',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\n\n';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\n\n    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\n\n' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 0, a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 1, a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.q) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.t),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.t);
		} else {
			var treeLen = builder.q * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.w) : builder.w;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.q);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.t) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.t);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{w: nodeList, q: (len / $elm$core$Array$branchFactor) | 0, t: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = 0;
var $elm$core$Result$isOk = function (result) {
	if (!result.$) {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$map2 = _Json_map2;
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $elm$virtual_dom$VirtualDom$toHandlerInt = function (handler) {
	switch (handler.$) {
		case 0:
			return 0;
		case 1:
			return 1;
		case 2:
			return 2;
		default:
			return 3;
	}
};
var $elm$browser$Browser$External = function (a) {
	return {$: 1, a: a};
};
var $elm$browser$Browser$Internal = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $elm$browser$Browser$Dom$NotFound = $elm$core$Basics$identity;
var $elm$url$Url$Http = 0;
var $elm$url$Url$Https = 1;
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {bW: fragment, b0: host, ck: path, cn: port_, cq: protocol, cr: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$core$String$toInt = _String_toInt;
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 1) {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$core$String$startsWith = _String_startsWith;
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		0,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		1,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $elm$core$Task$Perform = $elm$core$Basics$identity;
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$core$Task$init = $elm$core$Task$succeed(0);
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return 0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0;
		return A2($elm$core$Task$map, tagger, task);
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			A2($elm$core$Task$map, toMessage, task));
	});
var $elm$browser$Browser$element = _Browser_element;
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$json$Json$Decode$decodeString = _Json_runOnString;
var $elm$json$Json$Decode$decodeValue = _Json_run;
var $author$project$Model$Model = function (items) {
	return function (boxes) {
		return function (boxId) {
			return function (nextId) {
				return function (imageCache) {
					return function (text) {
						return function (mouse) {
							return function (search) {
								return function (icon) {
									return function (selection) {
										return {a4: boxId, bL: boxes, aa: icon, dh: imageCache, b7: items, dt: mouse, dw: nextId, C: search, ax: selection, dX: text};
									};
								};
							};
						};
					};
				};
			};
		};
	};
};
var $elm$json$Json$Decode$andThen = _Json_andThen;
var $author$project$ModelParts$Box = F4(
	function (id, rect, scroll, items) {
		return {aK: id, b7: items, aO: rect, aU: scroll};
	});
var $author$project$ModelParts$Point = F2(
	function (x, y) {
		return {d1: x, d3: y};
	});
var $author$project$ModelParts$Rectangle = F4(
	function (x1, y1, x2, y2) {
		return {d2: x1, a0: x2, d4: y1, a1: y2};
	});
var $author$project$ModelParts$AssocP = function (a) {
	return {$: 1, a: a};
};
var $author$project$ModelParts$AssocProps = {};
var $author$project$ModelParts$BoxItem = F4(
	function (id, boxAssocId, visibility, props) {
		return {cX: boxAssocId, aK: id, ac: props, al: visibility};
	});
var $author$project$ModelParts$TopicP = function (a) {
	return {$: 0, a: a};
};
var $author$project$ModelParts$TopicProps = F2(
	function (pos, displayMode) {
		return {aI: displayMode, av: pos};
	});
var $author$project$ModelParts$BlackBox = 0;
var $author$project$ModelParts$BoxD = function (a) {
	return {$: 1, a: a};
};
var $author$project$ModelParts$Detail = 1;
var $author$project$ModelParts$LabelOnly = 0;
var $author$project$ModelParts$TopicD = function (a) {
	return {$: 0, a: a};
};
var $author$project$ModelParts$Unboxed = 2;
var $author$project$ModelParts$WhiteBox = 1;
var $elm$json$Json$Decode$fail = _Json_fail;
var $author$project$ModelParts$displayModeDecoder = function (str) {
	switch (str) {
		case 'LabelOnly':
			return $elm$json$Json$Decode$succeed(
				$author$project$ModelParts$TopicD(0));
		case 'Detail':
			return $elm$json$Json$Decode$succeed(
				$author$project$ModelParts$TopicD(1));
		case 'BlackBox':
			return $elm$json$Json$Decode$succeed(
				$author$project$ModelParts$BoxD(0));
		case 'WhiteBox':
			return $elm$json$Json$Decode$succeed(
				$author$project$ModelParts$BoxD(1));
		case 'Unboxed':
			return $elm$json$Json$Decode$succeed(
				$author$project$ModelParts$BoxD(2));
		default:
			return $elm$json$Json$Decode$fail('\"' + (str + '\" is an invalid DisplayMode'));
	}
};
var $elm$json$Json$Decode$field = _Json_decodeField;
var $elm$json$Json$Decode$int = _Json_decodeInt;
var $elm$json$Json$Decode$map4 = _Json_map4;
var $elm$json$Json$Decode$oneOf = _Json_oneOf;
var $elm$json$Json$Decode$string = _Json_decodeString;
var $author$project$ModelParts$Pinned = 0;
var $author$project$ModelParts$Removed = {$: 1};
var $author$project$ModelParts$Unpinned = 1;
var $author$project$ModelParts$Visible = function (a) {
	return {$: 0, a: a};
};
var $author$project$ModelParts$visibilityDecoder = function (str) {
	switch (str) {
		case 'Pinned':
			return $elm$json$Json$Decode$succeed(
				$author$project$ModelParts$Visible(0));
		case 'Visible':
			return $elm$json$Json$Decode$succeed(
				$author$project$ModelParts$Visible(1));
		case 'Removed':
			return $elm$json$Json$Decode$succeed($author$project$ModelParts$Removed);
		default:
			return $elm$json$Json$Decode$fail('\"' + (str + '\" is an invalid Visibility'));
	}
};
var $author$project$ModelParts$boxItemDecoder = A5(
	$elm$json$Json$Decode$map4,
	$author$project$ModelParts$BoxItem,
	A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'boxAssocId', $elm$json$Json$Decode$int),
	A2(
		$elm$json$Json$Decode$andThen,
		$author$project$ModelParts$visibilityDecoder,
		A2($elm$json$Json$Decode$field, 'visibility', $elm$json$Json$Decode$string)),
	$elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$json$Json$Decode$field,
				'topicProps',
				A2(
					$elm$json$Json$Decode$map,
					$author$project$ModelParts$TopicP,
					A3(
						$elm$json$Json$Decode$map2,
						$author$project$ModelParts$TopicProps,
						A2(
							$elm$json$Json$Decode$field,
							'pos',
							A3(
								$elm$json$Json$Decode$map2,
								$author$project$ModelParts$Point,
								A2($elm$json$Json$Decode$field, 'x', $elm$json$Json$Decode$int),
								A2($elm$json$Json$Decode$field, 'y', $elm$json$Json$Decode$int))),
						A2(
							$elm$json$Json$Decode$andThen,
							$author$project$ModelParts$displayModeDecoder,
							A2($elm$json$Json$Decode$field, 'display', $elm$json$Json$Decode$string))))),
				A2(
				$elm$json$Json$Decode$field,
				'assocProps',
				$elm$json$Json$Decode$succeed(
					$author$project$ModelParts$AssocP($author$project$ModelParts$AssocProps)))
			])));
var $elm$json$Json$Decode$list = _Json_decodeList;
var $elm$core$Dict$RBEmpty_elm_builtin = {$: -2};
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $elm$core$Dict$Black = 1;
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: -1, a: a, b: b, c: c, d: d, e: e};
	});
var $elm$core$Dict$Red = 0;
var $elm$core$Dict$balance = F5(
	function (color, key, value, left, right) {
		if ((right.$ === -1) && (!right.a)) {
			var _v1 = right.a;
			var rK = right.b;
			var rV = right.c;
			var rLeft = right.d;
			var rRight = right.e;
			if ((left.$ === -1) && (!left.a)) {
				var _v3 = left.a;
				var lK = left.b;
				var lV = left.c;
				var lLeft = left.d;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					key,
					value,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					rK,
					rV,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, left, rLeft),
					rRight);
			}
		} else {
			if ((((left.$ === -1) && (!left.a)) && (left.d.$ === -1)) && (!left.d.a)) {
				var _v5 = left.a;
				var lK = left.b;
				var lV = left.c;
				var _v6 = left.d;
				var _v7 = _v6.a;
				var llK = _v6.b;
				var llV = _v6.c;
				var llLeft = _v6.d;
				var llRight = _v6.e;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					lK,
					lV,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, llK, llV, llLeft, llRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, key, value, lRight, right));
			} else {
				return A5($elm$core$Dict$RBNode_elm_builtin, color, key, value, left, right);
			}
		}
	});
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$Dict$insertHelp = F3(
	function (key, value, dict) {
		if (dict.$ === -2) {
			return A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
		} else {
			var nColor = dict.a;
			var nKey = dict.b;
			var nValue = dict.c;
			var nLeft = dict.d;
			var nRight = dict.e;
			var _v1 = A2($elm$core$Basics$compare, key, nKey);
			switch (_v1) {
				case 0:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						A3($elm$core$Dict$insertHelp, key, value, nLeft),
						nRight);
				case 1:
					return A5($elm$core$Dict$RBNode_elm_builtin, nColor, nKey, value, nLeft, nRight);
				default:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						nLeft,
						A3($elm$core$Dict$insertHelp, key, value, nRight));
			}
		}
	});
var $elm$core$Dict$insert = F3(
	function (key, value, dict) {
		var _v0 = A3($elm$core$Dict$insertHelp, key, value, dict);
		if ((_v0.$ === -1) && (!_v0.a)) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, 1, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$fromList = function (assocs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, dict) {
				var key = _v0.a;
				var value = _v0.b;
				return A3($elm$core$Dict$insert, key, value, dict);
			}),
		$elm$core$Dict$empty,
		assocs);
};
var $author$project$ModelParts$toDictDecoder = function (items) {
	return $elm$json$Json$Decode$succeed(
		$elm$core$Dict$fromList(
			A2(
				$elm$core$List$map,
				function (item) {
					return _Utils_Tuple2(item.aK, item);
				},
				items)));
};
var $author$project$ModelParts$boxDecoder = A5(
	$elm$json$Json$Decode$map4,
	$author$project$ModelParts$Box,
	A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int),
	A2(
		$elm$json$Json$Decode$field,
		'rect',
		A5(
			$elm$json$Json$Decode$map4,
			$author$project$ModelParts$Rectangle,
			A2($elm$json$Json$Decode$field, 'x1', $elm$json$Json$Decode$int),
			A2($elm$json$Json$Decode$field, 'y1', $elm$json$Json$Decode$int),
			A2($elm$json$Json$Decode$field, 'x2', $elm$json$Json$Decode$int),
			A2($elm$json$Json$Decode$field, 'y2', $elm$json$Json$Decode$int))),
	A2(
		$elm$json$Json$Decode$field,
		'scroll',
		A3(
			$elm$json$Json$Decode$map2,
			$author$project$ModelParts$Point,
			A2($elm$json$Json$Decode$field, 'x', $elm$json$Json$Decode$int),
			A2($elm$json$Json$Decode$field, 'y', $elm$json$Json$Decode$int))),
	A2(
		$elm$json$Json$Decode$field,
		'items',
		A2(
			$elm$json$Json$Decode$andThen,
			$author$project$ModelParts$toDictDecoder,
			$elm$json$Json$Decode$list($author$project$ModelParts$boxItemDecoder))));
var $elm$core$Basics$composeR = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var $NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$custom = $elm$json$Json$Decode$map2($elm$core$Basics$apR);
var $NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$hardcoded = A2($elm$core$Basics$composeR, $elm$json$Json$Decode$succeed, $NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$custom);
var $author$project$Feature$Icon$Closed = 1;
var $author$project$Feature$Icon$init = {cl: 1};
var $author$project$Feature$Mouse$NoDrag = function (a) {
	return {$: 4, a: a};
};
var $author$project$Feature$Mouse$init = {
	c6: $author$project$Feature$Mouse$NoDrag($elm$core$Maybe$Nothing)
};
var $author$project$Feature$Search$NoSearch = {$: 2};
var $author$project$Feature$Search$init = {cw: $author$project$Feature$Search$NoSearch, cH: ''};
var $author$project$Feature$Sel$init = {b7: _List_Nil};
var $author$project$Feature$Text$NoEdit = {$: 1};
var $author$project$Feature$Text$init = {c7: $author$project$Feature$Text$NoEdit, cc: ''};
var $author$project$ModelParts$Assoc = function (a) {
	return {$: 1, a: a};
};
var $author$project$ModelParts$AssocInfo = F4(
	function (id, assocType, player1, player2) {
		return {cT: assocType, aK: id, dK: player1, dL: player2};
	});
var $author$project$ModelParts$Item = F3(
	function (id, info, assocIds) {
		return {bH: assocIds, aK: id, b2: info};
	});
var $author$project$ModelParts$Topic = function (a) {
	return {$: 0, a: a};
};
var $author$project$ModelParts$TopicInfo = F4(
	function (id, icon, text, size) {
		return {aa: icon, aK: id, bo: size, dX: text};
	});
var $elm$core$Set$Set_elm_builtin = $elm$core$Basics$identity;
var $elm$core$Set$empty = $elm$core$Dict$empty;
var $elm$core$Set$insert = F2(
	function (key, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$insert, key, 0, dict);
	});
var $elm$core$Set$fromList = function (list) {
	return A3($elm$core$List$foldl, $elm$core$Set$insert, $elm$core$Set$empty, list);
};
var $author$project$ModelParts$assocIdsDecoder = A2(
	$elm$json$Json$Decode$andThen,
	A2($elm$core$Basics$composeR, $elm$core$Set$fromList, $elm$json$Json$Decode$succeed),
	A2(
		$elm$json$Json$Decode$field,
		'assocIds',
		$elm$json$Json$Decode$list($elm$json$Json$Decode$int)));
var $author$project$ModelParts$Crosslink = 1;
var $author$project$ModelParts$Hierarchy = 0;
var $author$project$ModelParts$assocTypeDecoder = function (str) {
	switch (str) {
		case 'Hierarchy':
			return $elm$json$Json$Decode$succeed(0);
		case 'Crosslink':
			return $elm$json$Json$Decode$succeed(1);
		default:
			return $elm$json$Json$Decode$fail('\"' + (str + '\" is an invalid AssocType'));
	}
};
var $elm$json$Json$Decode$map3 = _Json_map3;
var $author$project$ModelParts$maybeString = function (str) {
	return $elm$json$Json$Decode$succeed(
		function () {
			if (str === '') {
				return $elm$core$Maybe$Nothing;
			} else {
				return $elm$core$Maybe$Just(str);
			}
		}());
};
var $author$project$ModelParts$Size = F2(
	function (w, h) {
		return {b_: h, cN: w};
	});
var $author$project$ModelParts$TextSize = F2(
	function (view, editor) {
		return {c8: editor, d_: view};
	});
var $author$project$ModelParts$textSizeDecoder = A2(
	$elm$json$Json$Decode$field,
	'size',
	A3(
		$elm$json$Json$Decode$map2,
		$author$project$ModelParts$TextSize,
		A2(
			$elm$json$Json$Decode$field,
			'view',
			A3(
				$elm$json$Json$Decode$map2,
				$author$project$ModelParts$Size,
				A2($elm$json$Json$Decode$field, 'w', $elm$json$Json$Decode$int),
				A2($elm$json$Json$Decode$field, 'h', $elm$json$Json$Decode$int))),
		A2(
			$elm$json$Json$Decode$field,
			'editor',
			A3(
				$elm$json$Json$Decode$map2,
				$author$project$ModelParts$Size,
				A2($elm$json$Json$Decode$field, 'w', $elm$json$Json$Decode$int),
				A2($elm$json$Json$Decode$field, 'h', $elm$json$Json$Decode$int)))));
var $author$project$ModelParts$itemDecoder = $elm$json$Json$Decode$oneOf(
	_List_fromArray(
		[
			A2(
			$elm$json$Json$Decode$field,
			'topic',
			A4(
				$elm$json$Json$Decode$map3,
				$author$project$ModelParts$Item,
				A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int),
				A2(
					$elm$json$Json$Decode$map,
					$author$project$ModelParts$Topic,
					A5(
						$elm$json$Json$Decode$map4,
						$author$project$ModelParts$TopicInfo,
						A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int),
						A2(
							$elm$json$Json$Decode$andThen,
							$author$project$ModelParts$maybeString,
							A2($elm$json$Json$Decode$field, 'icon', $elm$json$Json$Decode$string)),
						A2($elm$json$Json$Decode$field, 'text', $elm$json$Json$Decode$string),
						$author$project$ModelParts$textSizeDecoder)),
				$author$project$ModelParts$assocIdsDecoder)),
			A2(
			$elm$json$Json$Decode$field,
			'assoc',
			A4(
				$elm$json$Json$Decode$map3,
				$author$project$ModelParts$Item,
				A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int),
				A2(
					$elm$json$Json$Decode$map,
					$author$project$ModelParts$Assoc,
					A5(
						$elm$json$Json$Decode$map4,
						$author$project$ModelParts$AssocInfo,
						A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int),
						A2(
							$elm$json$Json$Decode$andThen,
							$author$project$ModelParts$assocTypeDecoder,
							A2($elm$json$Json$Decode$field, 'type', $elm$json$Json$Decode$string)),
						A2($elm$json$Json$Decode$field, 'player1', $elm$json$Json$Decode$int),
						A2($elm$json$Json$Decode$field, 'player2', $elm$json$Json$Decode$int))),
				$author$project$ModelParts$assocIdsDecoder))
		]));
var $NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required = F3(
	function (key, valDecoder, decoder) {
		return A2(
			$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$custom,
			A2($elm$json$Json$Decode$field, key, valDecoder),
			decoder);
	});
var $author$project$Model$decoder = A2(
	$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$hardcoded,
	$author$project$Feature$Sel$init,
	A2(
		$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$hardcoded,
		$author$project$Feature$Icon$init,
		A2(
			$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$hardcoded,
			$author$project$Feature$Search$init,
			A2(
				$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$hardcoded,
				$author$project$Feature$Mouse$init,
				A2(
					$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$hardcoded,
					$author$project$Feature$Text$init,
					A2(
						$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$hardcoded,
						$elm$core$Dict$empty,
						A3(
							$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
							'nextId',
							$elm$json$Json$Decode$int,
							A3(
								$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
								'boxId',
								$elm$json$Json$Decode$int,
								A3(
									$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
									'boxes',
									A2(
										$elm$json$Json$Decode$andThen,
										$author$project$ModelParts$toDictDecoder,
										$elm$json$Json$Decode$list($author$project$ModelParts$boxDecoder)),
									A3(
										$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
										'items',
										A2(
											$elm$json$Json$Decode$andThen,
											$author$project$ModelParts$toDictDecoder,
											$elm$json$Json$Decode$list($author$project$ModelParts$itemDecoder)),
										$elm$json$Json$Decode$succeed($author$project$Model$Model)))))))))));
var $elm$json$Json$Encode$string = _Json_wrap;
var $author$project$AppEmbed$evidence = _Platform_outgoingPort('evidence', $elm$json$Json$Encode$string);
var $elm$core$List$isEmpty = function (xs) {
	if (!xs.b) {
		return true;
	} else {
		return false;
	}
};
var $author$project$AppEmbed$jsonPair = F2(
	function (key, value) {
		return '\"' + (key + ('\":' + value));
	});
var $author$project$AppEmbed$jsonString = function (value) {
	return '\"' + (value + '\"');
};
var $author$project$AppEmbed$emitEvidence = F2(
	function (kind, fields) {
		return $author$project$AppEmbed$evidence(
			'{' + (A2(
				$author$project$AppEmbed$jsonPair,
				'kind',
				$author$project$AppEmbed$jsonString(kind)) + ($elm$core$List$isEmpty(fields) ? '}' : (',' + (A2($elm$core$String$join, ',', fields) + '}')))));
	});
var $author$project$AppEmbed$Flags = F2(
	function (slug, stored) {
		return {bp: slug, bs: stored};
	});
var $elm$json$Json$Decode$maybe = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder),
				$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
			]));
};
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$AppEmbed$flagsDecoder = A3(
	$elm$json$Json$Decode$map2,
	$author$project$AppEmbed$Flags,
	A2(
		$elm$json$Json$Decode$map,
		$elm$core$Maybe$withDefault('empty'),
		$elm$json$Json$Decode$maybe(
			A2($elm$json$Json$Decode$field, 'slug', $elm$json$Json$Decode$string))),
	A2(
		$elm$json$Json$Decode$map,
		$elm$core$Maybe$withDefault('{}'),
		$elm$json$Json$Decode$maybe(
			A2($elm$json$Json$Decode$field, 'stored', $elm$json$Json$Decode$string))));
var $author$project$ModelParts$rootBoxId = 0;
var $author$project$Config$rootBoxName = 'DM6 Elm';
var $elm$core$Dict$singleton = F2(
	function (key, value) {
		return A5($elm$core$Dict$RBNode_elm_builtin, 1, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
	});
var $author$project$Model$init = function () {
	var rootTopic = A4(
		$author$project$ModelParts$TopicInfo,
		0,
		$elm$core$Maybe$Nothing,
		$author$project$Config$rootBoxName,
		A2(
			$author$project$ModelParts$TextSize,
			A2($author$project$ModelParts$Size, 0, 0),
			A2($author$project$ModelParts$Size, 0, 0)));
	return {
		a4: $author$project$ModelParts$rootBoxId,
		bL: A2(
			$elm$core$Dict$singleton,
			$author$project$ModelParts$rootBoxId,
			A4(
				$author$project$ModelParts$Box,
				$author$project$ModelParts$rootBoxId,
				A4($author$project$ModelParts$Rectangle, 0, 0, 0, 0),
				A2($author$project$ModelParts$Point, 0, 0),
				$elm$core$Dict$empty)),
		aa: $author$project$Feature$Icon$init,
		dh: $elm$core$Dict$empty,
		b7: A2(
			$elm$core$Dict$singleton,
			0,
			A3(
				$author$project$ModelParts$Item,
				0,
				$author$project$ModelParts$Topic(rootTopic),
				$elm$core$Set$empty)),
		dt: $author$project$Feature$Mouse$init,
		dw: 1,
		C: $author$project$Feature$Search$init,
		ax: $author$project$Feature$Sel$init,
		dX: $author$project$Feature$Text$init
	};
}();
var $author$project$AppEmbed$jsonInt = function (value) {
	return $elm$core$String$fromInt(value);
};
var $elm_community$undo_redo$UndoList$UndoList = F3(
	function (past, present, future) {
		return {u: future, s: past, aw: present};
	});
var $elm_community$undo_redo$UndoList$fresh = function (state) {
	return A3($elm_community$undo_redo$UndoList$UndoList, _List_Nil, state, _List_Nil);
};
var $author$project$Undo$reset = function (_v0) {
	var model = _v0.a;
	var cmd = _v0.b;
	return _Utils_Tuple2(
		$elm_community$undo_redo$UndoList$fresh(model),
		cmd);
};
var $elm$core$Dict$sizeHelp = F2(
	function (n, dict) {
		sizeHelp:
		while (true) {
			if (dict.$ === -2) {
				return n;
			} else {
				var left = dict.d;
				var right = dict.e;
				var $temp$n = A2($elm$core$Dict$sizeHelp, n + 1, right),
					$temp$dict = left;
				n = $temp$n;
				dict = $temp$dict;
				continue sizeHelp;
			}
		}
	});
var $elm$core$Dict$size = function (dict) {
	return A2($elm$core$Dict$sizeHelp, 0, dict);
};
var $author$project$AppEmbed$storeSnapshotEvidence = F2(
	function (reason, model) {
		return A2(
			$author$project$AppEmbed$emitEvidence,
			'dm6.store.snapshot',
			_List_fromArray(
				[
					A2(
					$author$project$AppEmbed$jsonPair,
					'reason',
					$author$project$AppEmbed$jsonString(reason)),
					A2(
					$author$project$AppEmbed$jsonPair,
					'boxId',
					$author$project$AppEmbed$jsonInt(model.a4)),
					A2(
					$author$project$AppEmbed$jsonPair,
					'itemCount',
					$author$project$AppEmbed$jsonInt(
						$elm$core$Dict$size(model.b7))),
					A2(
					$author$project$AppEmbed$jsonPair,
					'boxCount',
					$author$project$AppEmbed$jsonInt(
						$elm$core$Dict$size(model.bL)))
				]));
	});
var $elm$json$Json$Decode$value = _Json_decodeValue;
var $author$project$AppEmbed$init = function (rawFlags) {
	var flags = function () {
		var _v3 = A2($elm$json$Json$Decode$decodeValue, $author$project$AppEmbed$flagsDecoder, rawFlags);
		if (!_v3.$) {
			var decoded = _v3.a;
			return decoded;
		} else {
			return {bp: 'empty', bs: '{}'};
		}
	}();
	var _v0 = function () {
		var _v1 = A2($elm$json$Json$Decode$decodeString, $elm$json$Json$Decode$value, flags.bs);
		if (!_v1.$) {
			var value = _v1.a;
			var _v2 = A2($elm$json$Json$Decode$decodeValue, $author$project$Model$decoder, value);
			if (!_v2.$) {
				var decodedModel = _v2.a;
				return _Utils_Tuple2(decodedModel, 'native-model');
			} else {
				return _Utils_Tuple2($author$project$Model$init, 'empty-after-native-decode-error');
			}
		} else {
			return _Utils_Tuple2($author$project$Model$init, 'empty-after-stored-json-error');
		}
	}();
	var model = _v0.a;
	var initSource = _v0.b;
	var initCmd = $elm$core$Platform$Cmd$batch(
		_List_fromArray(
			[
				A2(
				$author$project$AppEmbed$emitEvidence,
				'dm6.import.completed',
				_List_fromArray(
					[
						A2(
						$author$project$AppEmbed$jsonPair,
						'source',
						$author$project$AppEmbed$jsonString(initSource)),
						A2(
						$author$project$AppEmbed$jsonPair,
						'slug',
						$author$project$AppEmbed$jsonString(flags.bp)),
						A2(
						$author$project$AppEmbed$jsonPair,
						'boxId',
						$author$project$AppEmbed$jsonInt(model.a4)),
						A2(
						$author$project$AppEmbed$jsonPair,
						'itemCount',
						$author$project$AppEmbed$jsonInt(
							$elm$core$Dict$size(model.b7))),
						A2(
						$author$project$AppEmbed$jsonPair,
						'boxCount',
						$author$project$AppEmbed$jsonInt(
							$elm$core$Dict$size(model.bL)))
					])),
				A2($author$project$AppEmbed$storeSnapshotEvidence, 'after-import', model)
			]));
	return $author$project$Undo$reset(
		_Utils_Tuple2(model, initCmd));
};
var $author$project$Model$NoOp = {$: 13};
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $author$project$AppEmbed$pageJson = _Platform_incomingPort('pageJson', $elm$json$Json$Decode$string);
var $author$project$Model$Mouse = function (a) {
	return {$: 7, a: a};
};
var $author$project$Feature$Mouse$Move = function (a) {
	return {$: 2, a: a};
};
var $author$project$Feature$Mouse$Up = {$: 3};
var $elm$browser$Browser$Events$Document = 0;
var $elm$browser$Browser$Events$MySub = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $elm$browser$Browser$Events$State = F2(
	function (subs, pids) {
		return {cm: pids, cF: subs};
	});
var $elm$browser$Browser$Events$init = $elm$core$Task$succeed(
	A2($elm$browser$Browser$Events$State, _List_Nil, $elm$core$Dict$empty));
var $elm$browser$Browser$Events$nodeToKey = function (node) {
	if (!node) {
		return 'd_';
	} else {
		return 'w_';
	}
};
var $elm$browser$Browser$Events$addKey = function (sub) {
	var node = sub.a;
	var name = sub.b;
	return _Utils_Tuple2(
		_Utils_ap(
			$elm$browser$Browser$Events$nodeToKey(node),
			name),
		sub);
};
var $elm$core$Process$kill = _Scheduler_kill;
var $elm$core$Dict$foldl = F3(
	function (func, acc, dict) {
		foldl:
		while (true) {
			if (dict.$ === -2) {
				return acc;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldl, func, acc, left)),
					$temp$dict = right;
				func = $temp$func;
				acc = $temp$acc;
				dict = $temp$dict;
				continue foldl;
			}
		}
	});
var $elm$core$Dict$merge = F6(
	function (leftStep, bothStep, rightStep, leftDict, rightDict, initialResult) {
		var stepState = F3(
			function (rKey, rValue, _v0) {
				stepState:
				while (true) {
					var list = _v0.a;
					var result = _v0.b;
					if (!list.b) {
						return _Utils_Tuple2(
							list,
							A3(rightStep, rKey, rValue, result));
					} else {
						var _v2 = list.a;
						var lKey = _v2.a;
						var lValue = _v2.b;
						var rest = list.b;
						if (_Utils_cmp(lKey, rKey) < 0) {
							var $temp$rKey = rKey,
								$temp$rValue = rValue,
								$temp$_v0 = _Utils_Tuple2(
								rest,
								A3(leftStep, lKey, lValue, result));
							rKey = $temp$rKey;
							rValue = $temp$rValue;
							_v0 = $temp$_v0;
							continue stepState;
						} else {
							if (_Utils_cmp(lKey, rKey) > 0) {
								return _Utils_Tuple2(
									list,
									A3(rightStep, rKey, rValue, result));
							} else {
								return _Utils_Tuple2(
									rest,
									A4(bothStep, lKey, lValue, rValue, result));
							}
						}
					}
				}
			});
		var _v3 = A3(
			$elm$core$Dict$foldl,
			stepState,
			_Utils_Tuple2(
				$elm$core$Dict$toList(leftDict),
				initialResult),
			rightDict);
		var leftovers = _v3.a;
		var intermediateResult = _v3.b;
		return A3(
			$elm$core$List$foldl,
			F2(
				function (_v4, result) {
					var k = _v4.a;
					var v = _v4.b;
					return A3(leftStep, k, v, result);
				}),
			intermediateResult,
			leftovers);
	});
var $elm$browser$Browser$Events$Event = F2(
	function (key, event) {
		return {bT: event, b8: key};
	});
var $elm$core$Platform$sendToSelf = _Platform_sendToSelf;
var $elm$browser$Browser$Events$spawn = F3(
	function (router, key, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var actualNode = function () {
			if (!node) {
				return _Browser_doc;
			} else {
				return _Browser_window;
			}
		}();
		return A2(
			$elm$core$Task$map,
			function (value) {
				return _Utils_Tuple2(key, value);
			},
			A3(
				_Browser_on,
				actualNode,
				name,
				function (event) {
					return A2(
						$elm$core$Platform$sendToSelf,
						router,
						A2($elm$browser$Browser$Events$Event, key, event));
				}));
	});
var $elm$core$Dict$union = F2(
	function (t1, t2) {
		return A3($elm$core$Dict$foldl, $elm$core$Dict$insert, t2, t1);
	});
var $elm$browser$Browser$Events$onEffects = F3(
	function (router, subs, state) {
		var stepRight = F3(
			function (key, sub, _v6) {
				var deads = _v6.a;
				var lives = _v6.b;
				var news = _v6.c;
				return _Utils_Tuple3(
					deads,
					lives,
					A2(
						$elm$core$List$cons,
						A3($elm$browser$Browser$Events$spawn, router, key, sub),
						news));
			});
		var stepLeft = F3(
			function (_v4, pid, _v5) {
				var deads = _v5.a;
				var lives = _v5.b;
				var news = _v5.c;
				return _Utils_Tuple3(
					A2($elm$core$List$cons, pid, deads),
					lives,
					news);
			});
		var stepBoth = F4(
			function (key, pid, _v2, _v3) {
				var deads = _v3.a;
				var lives = _v3.b;
				var news = _v3.c;
				return _Utils_Tuple3(
					deads,
					A3($elm$core$Dict$insert, key, pid, lives),
					news);
			});
		var newSubs = A2($elm$core$List$map, $elm$browser$Browser$Events$addKey, subs);
		var _v0 = A6(
			$elm$core$Dict$merge,
			stepLeft,
			stepBoth,
			stepRight,
			state.cm,
			$elm$core$Dict$fromList(newSubs),
			_Utils_Tuple3(_List_Nil, $elm$core$Dict$empty, _List_Nil));
		var deadPids = _v0.a;
		var livePids = _v0.b;
		var makeNewPids = _v0.c;
		return A2(
			$elm$core$Task$andThen,
			function (pids) {
				return $elm$core$Task$succeed(
					A2(
						$elm$browser$Browser$Events$State,
						newSubs,
						A2(
							$elm$core$Dict$union,
							livePids,
							$elm$core$Dict$fromList(pids))));
			},
			A2(
				$elm$core$Task$andThen,
				function (_v1) {
					return $elm$core$Task$sequence(makeNewPids);
				},
				$elm$core$Task$sequence(
					A2($elm$core$List$map, $elm$core$Process$kill, deadPids))));
	});
var $elm$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _v0 = f(mx);
		if (!_v0.$) {
			var x = _v0.a;
			return A2($elm$core$List$cons, x, xs);
		} else {
			return xs;
		}
	});
var $elm$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			$elm$core$List$maybeCons(f),
			_List_Nil,
			xs);
	});
var $elm$browser$Browser$Events$onSelfMsg = F3(
	function (router, _v0, state) {
		var key = _v0.b8;
		var event = _v0.bT;
		var toMessage = function (_v2) {
			var subKey = _v2.a;
			var _v3 = _v2.b;
			var node = _v3.a;
			var name = _v3.b;
			var decoder = _v3.c;
			return _Utils_eq(subKey, key) ? A2(_Browser_decodeEvent, decoder, event) : $elm$core$Maybe$Nothing;
		};
		var messages = A2($elm$core$List$filterMap, toMessage, state.cF);
		return A2(
			$elm$core$Task$andThen,
			function (_v1) {
				return $elm$core$Task$succeed(state);
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Platform$sendToApp(router),
					messages)));
	});
var $elm$browser$Browser$Events$subMap = F2(
	function (func, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var decoder = _v0.c;
		return A3(
			$elm$browser$Browser$Events$MySub,
			node,
			name,
			A2($elm$json$Json$Decode$map, func, decoder));
	});
_Platform_effectManagers['Browser.Events'] = _Platform_createManager($elm$browser$Browser$Events$init, $elm$browser$Browser$Events$onEffects, $elm$browser$Browser$Events$onSelfMsg, 0, $elm$browser$Browser$Events$subMap);
var $elm$browser$Browser$Events$subscription = _Platform_leaf('Browser.Events');
var $elm$browser$Browser$Events$on = F3(
	function (node, name, decoder) {
		return $elm$browser$Browser$Events$subscription(
			A3($elm$browser$Browser$Events$MySub, node, name, decoder));
	});
var $elm$browser$Browser$Events$onMouseMove = A2($elm$browser$Browser$Events$on, 0, 'mousemove');
var $elm$browser$Browser$Events$onMouseUp = A2($elm$browser$Browser$Events$on, 0, 'mouseup');
var $elm$json$Json$Decode$float = _Json_decodeFloat;
var $elm$core$Basics$round = _Basics_round;
var $author$project$Utils$toIntDecoder = function (_float) {
	return $elm$json$Json$Decode$succeed(
		$elm$core$Basics$round(_float));
};
var $author$project$Utils$pointDecoder = A3(
	$elm$json$Json$Decode$map2,
	$author$project$ModelParts$Point,
	A2(
		$elm$json$Json$Decode$andThen,
		$author$project$Utils$toIntDecoder,
		A2($elm$json$Json$Decode$field, 'clientX', $elm$json$Json$Decode$float)),
	A2(
		$elm$json$Json$Decode$andThen,
		$author$project$Utils$toIntDecoder,
		A2($elm$json$Json$Decode$field, 'clientY', $elm$json$Json$Decode$float)));
var $author$project$Feature$MouseAPI$dragSub = $elm$core$Platform$Sub$batch(
	_List_fromArray(
		[
			$elm$browser$Browser$Events$onMouseMove(
			A2(
				$elm$json$Json$Decode$map,
				$author$project$Model$Mouse,
				A2($elm$json$Json$Decode$map, $author$project$Feature$Mouse$Move, $author$project$Utils$pointDecoder))),
			$elm$browser$Browser$Events$onMouseUp(
			A2(
				$elm$json$Json$Decode$map,
				$author$project$Model$Mouse,
				$elm$json$Json$Decode$succeed($author$project$Feature$Mouse$Up)))
		]));
var $author$project$Feature$Mouse$Down = {$: 0};
var $elm$browser$Browser$Events$onMouseDown = A2($elm$browser$Browser$Events$on, 0, 'mousedown');
var $author$project$Feature$MouseAPI$mouseDownSub = $elm$browser$Browser$Events$onMouseDown(
	$elm$json$Json$Decode$succeed(
		$author$project$Model$Mouse($author$project$Feature$Mouse$Down)));
var $elm$core$Platform$Sub$none = $elm$core$Platform$Sub$batch(_List_Nil);
var $author$project$Feature$MouseAPI$sub = function (_v0) {
	var present = _v0.aw;
	var _v1 = present.dt.c6;
	switch (_v1.$) {
		case 0:
			return $elm$core$Platform$Sub$none;
		case 2:
			return $elm$core$Platform$Sub$none;
		case 1:
			return $author$project$Feature$MouseAPI$dragSub;
		case 3:
			return $author$project$Feature$MouseAPI$dragSub;
		default:
			return $author$project$Feature$MouseAPI$mouseDownSub;
	}
};
var $author$project$Feature$Text$ImageFilePicked = function (a) {
	return {$: 4, a: a};
};
var $author$project$Model$Text = function (a) {
	return {$: 6, a: a};
};
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $elm$json$Json$Decode$index = _Json_decodeIndex;
var $author$project$Feature$TextAPI$onPickImageFile = _Platform_incomingPort(
	'onPickImageFile',
	A2(
		$elm$json$Json$Decode$andThen,
		function (_v0) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (_v1) {
					return $elm$json$Json$Decode$succeed(
						_Utils_Tuple2(_v0, _v1));
				},
				A2($elm$json$Json$Decode$index, 1, $elm$json$Json$Decode$int));
		},
		A2($elm$json$Json$Decode$index, 0, $elm$json$Json$Decode$int)));
var $author$project$Feature$TextAPI$sub = $author$project$Feature$TextAPI$onPickImageFile(
	A2($elm$core$Basics$composeL, $author$project$Model$Text, $author$project$Feature$Text$ImageFilePicked));
var $author$project$AppEmbed$subscriptions = function (undo) {
	return $elm$core$Platform$Sub$batch(
		_List_fromArray(
			[
				$author$project$Feature$MouseAPI$sub(undo),
				$author$project$Feature$TextAPI$sub,
				$author$project$AppEmbed$pageJson(
				function (_v0) {
					return $author$project$Model$NoOp;
				})
			]));
};
var $author$project$AppEmbed$jsonBoxPath = function (boxPath) {
	return '[' + (A2(
		$elm$core$String$join,
		',',
		A2($elm$core$List$map, $elm$core$String$fromInt, boxPath)) + ']');
};
var $author$project$AppEmbed$jsonPoint = F2(
	function (prefix, point) {
		return A2(
			$author$project$AppEmbed$jsonPair,
			prefix + 'X',
			$author$project$AppEmbed$jsonInt(point.d1)) + (',' + A2(
			$author$project$AppEmbed$jsonPair,
			prefix + 'Y',
			$author$project$AppEmbed$jsonInt(point.d3)));
	});
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $author$project$AppEmbed$semanticEvidence = F3(
	function (msg, oldUndo, newUndo) {
		switch (msg.$) {
			case 3:
				var itemId = msg.a;
				var boxPath = msg.b;
				return $elm$core$Platform$Cmd$batch(
					_List_fromArray(
						[
							A2(
							$author$project$AppEmbed$emitEvidence,
							'dm6.selection.changed',
							_List_fromArray(
								[
									A2(
									$author$project$AppEmbed$jsonPair,
									'itemId',
									$author$project$AppEmbed$jsonInt(itemId)),
									A2(
									$author$project$AppEmbed$jsonPair,
									'boxPath',
									$author$project$AppEmbed$jsonBoxPath(boxPath))
								])),
							A2($author$project$AppEmbed$storeSnapshotEvidence, 'after-selection', newUndo.aw)
						]));
			case 0:
				var player1 = msg.a;
				var player2 = msg.b;
				var boxId = msg.c;
				return $elm$core$Platform$Cmd$batch(
					_List_fromArray(
						[
							A2(
							$author$project$AppEmbed$emitEvidence,
							'dm6.cross-map.boundary',
							_List_fromArray(
								[
									A2(
									$author$project$AppEmbed$jsonPair,
									'operation',
									$author$project$AppEmbed$jsonString('add-assoc')),
									A2(
									$author$project$AppEmbed$jsonPair,
									'player1',
									$author$project$AppEmbed$jsonInt(player1)),
									A2(
									$author$project$AppEmbed$jsonPair,
									'player2',
									$author$project$AppEmbed$jsonInt(player2)),
									A2(
									$author$project$AppEmbed$jsonPair,
									'boxId',
									$author$project$AppEmbed$jsonInt(boxId))
								])),
							A2($author$project$AppEmbed$storeSnapshotEvidence, 'after-add-assoc', newUndo.aw)
						]));
			case 1:
				var topicId = msg.a;
				var sourceBoxId = msg.b;
				var origPos = msg.c;
				var targetBoxId = msg.d;
				var targetPath = msg.e;
				var dropPos = msg.f;
				return $elm$core$Platform$Cmd$batch(
					_List_fromArray(
						[
							A2(
							$author$project$AppEmbed$emitEvidence,
							'dm6.cross-map.boundary',
							_List_fromArray(
								[
									A2(
									$author$project$AppEmbed$jsonPair,
									'operation',
									$author$project$AppEmbed$jsonString('move-topic-to-box')),
									A2(
									$author$project$AppEmbed$jsonPair,
									'topicId',
									$author$project$AppEmbed$jsonInt(topicId)),
									A2(
									$author$project$AppEmbed$jsonPair,
									'sourceBoxId',
									$author$project$AppEmbed$jsonInt(sourceBoxId)),
									A2(
									$author$project$AppEmbed$jsonPair,
									'targetBoxId',
									$author$project$AppEmbed$jsonInt(targetBoxId)),
									A2(
									$author$project$AppEmbed$jsonPair,
									'targetPath',
									$author$project$AppEmbed$jsonBoxPath(targetPath)),
									A2($author$project$AppEmbed$jsonPoint, 'orig', origPos),
									A2($author$project$AppEmbed$jsonPoint, 'drop', dropPos)
								])),
							A2(
							$author$project$AppEmbed$emitEvidence,
							'dm6.drag.ended',
							_List_fromArray(
								[
									A2(
									$author$project$AppEmbed$jsonPair,
									'mode',
									$author$project$AppEmbed$jsonString('move-topic-to-box')),
									A2(
									$author$project$AppEmbed$jsonPair,
									'topicId',
									$author$project$AppEmbed$jsonInt(topicId)),
									A2(
									$author$project$AppEmbed$jsonPair,
									'sourceBoxId',
									$author$project$AppEmbed$jsonInt(sourceBoxId)),
									A2(
									$author$project$AppEmbed$jsonPair,
									'targetBoxId',
									$author$project$AppEmbed$jsonInt(targetBoxId))
								])),
							A2($author$project$AppEmbed$storeSnapshotEvidence, 'after-move-topic-to-box', newUndo.aw)
						]));
			case 2:
				return $elm$core$Platform$Cmd$batch(
					_List_fromArray(
						[
							A2(
							$author$project$AppEmbed$emitEvidence,
							'dm6.drag.ended',
							_List_fromArray(
								[
									A2(
									$author$project$AppEmbed$jsonPair,
									'mode',
									$author$project$AppEmbed$jsonString('topic-drag-no-target'))
								])),
							A2($author$project$AppEmbed$storeSnapshotEvidence, 'after-topic-dragged', newUndo.aw)
						]));
			case 7:
				var mouseMsg = msg.a;
				switch (mouseMsg.$) {
					case 1:
						var className = mouseMsg.a;
						var itemId = mouseMsg.b;
						var boxPath = mouseMsg.c;
						var pos = mouseMsg.d;
						return A2(
							$author$project$AppEmbed$emitEvidence,
							'dm6.drag.started',
							_List_fromArray(
								[
									A2(
									$author$project$AppEmbed$jsonPair,
									'class',
									$author$project$AppEmbed$jsonString(className)),
									A2(
									$author$project$AppEmbed$jsonPair,
									'itemId',
									$author$project$AppEmbed$jsonInt(itemId)),
									A2(
									$author$project$AppEmbed$jsonPair,
									'boxPath',
									$author$project$AppEmbed$jsonBoxPath(boxPath)),
									A2($author$project$AppEmbed$jsonPoint, 'mouse', pos)
								]));
					case 2:
						var pos = mouseMsg.a;
						return A2(
							$author$project$AppEmbed$emitEvidence,
							'dm6.drag.moved',
							_List_fromArray(
								[
									A2($author$project$AppEmbed$jsonPoint, 'mouse', pos)
								]));
					case 3:
						return A2(
							$author$project$AppEmbed$emitEvidence,
							'dm6.drag.ended',
							_List_fromArray(
								[
									A2(
									$author$project$AppEmbed$jsonPair,
									'mode',
									$author$project$AppEmbed$jsonString('mouse-up'))
								]));
					default:
						return $elm$core$Platform$Cmd$none;
				}
			default:
				return $elm$core$Platform$Cmd$none;
		}
	});
var $author$project$Logger$log = F2(
	function (_v0, val) {
		return val;
	});
var $author$project$Utils$logError = F3(
	function (funcName, text, val) {
		return A2($author$project$Logger$log, '### ERROR @' + (funcName + (': ' + text)), val);
	});
var $author$project$Utils$illegalId = F4(
	function (funcName, item, id, val) {
		return A3(
			$author$project$Utils$logError,
			funcName,
			$elm$core$String$fromInt(id) + (' is an illegal ' + (item + ' ID')),
			val);
	});
var $author$project$Utils$illegalItemId = F3(
	function (funcName, id, val) {
		return A4($author$project$Utils$illegalId, funcName, 'Item', id, val);
	});
var $elm$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			if (dict.$ === -2) {
				return $elm$core$Maybe$Nothing;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var _v1 = A2($elm$core$Basics$compare, targetKey, key);
				switch (_v1) {
					case 0:
						var $temp$targetKey = targetKey,
							$temp$dict = left;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
					case 1:
						return $elm$core$Maybe$Just(value);
					default:
						var $temp$targetKey = targetKey,
							$temp$dict = right;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
				}
			}
		}
	});
var $elm$core$Dict$getMin = function (dict) {
	getMin:
	while (true) {
		if ((dict.$ === -1) && (dict.d.$ === -1)) {
			var left = dict.d;
			var $temp$dict = left;
			dict = $temp$dict;
			continue getMin;
		} else {
			return dict;
		}
	}
};
var $elm$core$Dict$moveRedLeft = function (dict) {
	if (((dict.$ === -1) && (dict.d.$ === -1)) && (dict.e.$ === -1)) {
		if ((dict.e.d.$ === -1) && (!dict.e.d.a)) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var lLeft = _v1.d;
			var lRight = _v1.e;
			var _v2 = dict.e;
			var rClr = _v2.a;
			var rK = _v2.b;
			var rV = _v2.c;
			var rLeft = _v2.d;
			var _v3 = rLeft.a;
			var rlK = rLeft.b;
			var rlV = rLeft.c;
			var rlL = rLeft.d;
			var rlR = rLeft.e;
			var rRight = _v2.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				0,
				rlK,
				rlV,
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					rlL),
				A5($elm$core$Dict$RBNode_elm_builtin, 1, rK, rV, rlR, rRight));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v4 = dict.d;
			var lClr = _v4.a;
			var lK = _v4.b;
			var lV = _v4.c;
			var lLeft = _v4.d;
			var lRight = _v4.e;
			var _v5 = dict.e;
			var rClr = _v5.a;
			var rK = _v5.b;
			var rV = _v5.c;
			var rLeft = _v5.d;
			var rRight = _v5.e;
			if (clr === 1) {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$moveRedRight = function (dict) {
	if (((dict.$ === -1) && (dict.d.$ === -1)) && (dict.e.$ === -1)) {
		if ((dict.d.d.$ === -1) && (!dict.d.d.a)) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var _v2 = _v1.d;
			var _v3 = _v2.a;
			var llK = _v2.b;
			var llV = _v2.c;
			var llLeft = _v2.d;
			var llRight = _v2.e;
			var lRight = _v1.e;
			var _v4 = dict.e;
			var rClr = _v4.a;
			var rK = _v4.b;
			var rV = _v4.c;
			var rLeft = _v4.d;
			var rRight = _v4.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				0,
				lK,
				lV,
				A5($elm$core$Dict$RBNode_elm_builtin, 1, llK, llV, llLeft, llRight),
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					lRight,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight)));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v5 = dict.d;
			var lClr = _v5.a;
			var lK = _v5.b;
			var lV = _v5.c;
			var lLeft = _v5.d;
			var lRight = _v5.e;
			var _v6 = dict.e;
			var rClr = _v6.a;
			var rK = _v6.b;
			var rV = _v6.c;
			var rLeft = _v6.d;
			var rRight = _v6.e;
			if (clr === 1) {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$removeHelpPrepEQGT = F7(
	function (targetKey, dict, color, key, value, left, right) {
		if ((left.$ === -1) && (!left.a)) {
			var _v1 = left.a;
			var lK = left.b;
			var lV = left.c;
			var lLeft = left.d;
			var lRight = left.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				lK,
				lV,
				lLeft,
				A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, lRight, right));
		} else {
			_v2$2:
			while (true) {
				if ((right.$ === -1) && (right.a === 1)) {
					if (right.d.$ === -1) {
						if (right.d.a === 1) {
							var _v3 = right.a;
							var _v4 = right.d;
							var _v5 = _v4.a;
							return $elm$core$Dict$moveRedRight(dict);
						} else {
							break _v2$2;
						}
					} else {
						var _v6 = right.a;
						var _v7 = right.d;
						return $elm$core$Dict$moveRedRight(dict);
					}
				} else {
					break _v2$2;
				}
			}
			return dict;
		}
	});
var $elm$core$Dict$removeMin = function (dict) {
	if ((dict.$ === -1) && (dict.d.$ === -1)) {
		var color = dict.a;
		var key = dict.b;
		var value = dict.c;
		var left = dict.d;
		var lColor = left.a;
		var lLeft = left.d;
		var right = dict.e;
		if (lColor === 1) {
			if ((lLeft.$ === -1) && (!lLeft.a)) {
				var _v3 = lLeft.a;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					key,
					value,
					$elm$core$Dict$removeMin(left),
					right);
			} else {
				var _v4 = $elm$core$Dict$moveRedLeft(dict);
				if (_v4.$ === -1) {
					var nColor = _v4.a;
					var nKey = _v4.b;
					var nValue = _v4.c;
					var nLeft = _v4.d;
					var nRight = _v4.e;
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						$elm$core$Dict$removeMin(nLeft),
						nRight);
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			}
		} else {
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				value,
				$elm$core$Dict$removeMin(left),
				right);
		}
	} else {
		return $elm$core$Dict$RBEmpty_elm_builtin;
	}
};
var $elm$core$Dict$removeHelp = F2(
	function (targetKey, dict) {
		if (dict.$ === -2) {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_cmp(targetKey, key) < 0) {
				if ((left.$ === -1) && (left.a === 1)) {
					var _v4 = left.a;
					var lLeft = left.d;
					if ((lLeft.$ === -1) && (!lLeft.a)) {
						var _v6 = lLeft.a;
						return A5(
							$elm$core$Dict$RBNode_elm_builtin,
							color,
							key,
							value,
							A2($elm$core$Dict$removeHelp, targetKey, left),
							right);
					} else {
						var _v7 = $elm$core$Dict$moveRedLeft(dict);
						if (_v7.$ === -1) {
							var nColor = _v7.a;
							var nKey = _v7.b;
							var nValue = _v7.c;
							var nLeft = _v7.d;
							var nRight = _v7.e;
							return A5(
								$elm$core$Dict$balance,
								nColor,
								nKey,
								nValue,
								A2($elm$core$Dict$removeHelp, targetKey, nLeft),
								nRight);
						} else {
							return $elm$core$Dict$RBEmpty_elm_builtin;
						}
					}
				} else {
					return A5(
						$elm$core$Dict$RBNode_elm_builtin,
						color,
						key,
						value,
						A2($elm$core$Dict$removeHelp, targetKey, left),
						right);
				}
			} else {
				return A2(
					$elm$core$Dict$removeHelpEQGT,
					targetKey,
					A7($elm$core$Dict$removeHelpPrepEQGT, targetKey, dict, color, key, value, left, right));
			}
		}
	});
var $elm$core$Dict$removeHelpEQGT = F2(
	function (targetKey, dict) {
		if (dict.$ === -1) {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_eq(targetKey, key)) {
				var _v1 = $elm$core$Dict$getMin(right);
				if (_v1.$ === -1) {
					var minKey = _v1.b;
					var minValue = _v1.c;
					return A5(
						$elm$core$Dict$balance,
						color,
						minKey,
						minValue,
						left,
						$elm$core$Dict$removeMin(right));
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			} else {
				return A5(
					$elm$core$Dict$balance,
					color,
					key,
					value,
					left,
					A2($elm$core$Dict$removeHelp, targetKey, right));
			}
		} else {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		}
	});
var $elm$core$Dict$remove = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$removeHelp, key, dict);
		if ((_v0.$ === -1) && (!_v0.a)) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, 1, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$update = F3(
	function (targetKey, alter, dictionary) {
		var _v0 = alter(
			A2($elm$core$Dict$get, targetKey, dictionary));
		if (!_v0.$) {
			var value = _v0.a;
			return A3($elm$core$Dict$insert, targetKey, value, dictionary);
		} else {
			return A2($elm$core$Dict$remove, targetKey, dictionary);
		}
	});
var $author$project$Item$update = F3(
	function (itemId, transform, model) {
		return _Utils_update(
			model,
			{
				b7: A3(
					$elm$core$Dict$update,
					itemId,
					function (maybeItem) {
						if (!maybeItem.$) {
							var item = maybeItem.a;
							return $elm$core$Maybe$Just(
								transform(item));
						} else {
							return A3($author$project$Utils$illegalItemId, 'update', itemId, $elm$core$Maybe$Nothing);
						}
					},
					model.b7)
			});
	});
var $author$project$Item$insertAssocId_ = F3(
	function (assocId, itemId, model) {
		return A3(
			$author$project$Item$update,
			itemId,
			function (item) {
				return _Utils_update(
					item,
					{
						bH: A2($elm$core$Set$insert, assocId, item.bH)
					});
			},
			model);
	});
var $author$project$Item$nextId = function (model) {
	return _Utils_update(
		model,
		{dw: model.dw + 1});
};
var $author$project$Item$addAssoc = F4(
	function (assocType, player1, player2, model) {
		var id = model.dw;
		var assoc = A4($author$project$ModelParts$AssocInfo, id, assocType, player1, player2);
		var item = A3(
			$author$project$ModelParts$Item,
			id,
			$author$project$ModelParts$Assoc(assoc),
			$elm$core$Set$empty);
		return _Utils_Tuple2(
			$author$project$Item$nextId(
				A3(
					$author$project$Item$insertAssocId_,
					id,
					player2,
					A3(
						$author$project$Item$insertAssocId_,
						id,
						player1,
						_Utils_update(
							model,
							{
								b7: A3($elm$core$Dict$insert, id, item, model.b7)
							})))),
			id);
	});
var $author$project$Utils$info = F2(
	function (funcName, val) {
		return A2($author$project$Logger$log, '@' + funcName, val);
	});
var $author$project$Utils$illegalBoxId = F3(
	function (funcName, id, val) {
		return A4($author$project$Utils$illegalId, funcName, 'Box', id, val);
	});
var $author$project$Box$update = F3(
	function (boxId, transform, model) {
		return _Utils_update(
			model,
			{
				bL: A3(
					$elm$core$Dict$update,
					boxId,
					function (maybeBox) {
						if (!maybeBox.$) {
							var box = maybeBox.a;
							return $elm$core$Maybe$Just(
								transform(box));
						} else {
							return A3($author$project$Utils$illegalBoxId, 'update', boxId, $elm$core$Maybe$Nothing);
						}
					},
					model.bL)
			});
	});
var $author$project$Box$addItem = F4(
	function (itemId, props, boxId, model) {
		var _v0 = A4($author$project$Item$addAssoc, 0, boxId, itemId, model);
		var newModel = _v0.a;
		var boxAssocId = _v0.b;
		var boxItem = A4(
			$author$project$ModelParts$BoxItem,
			itemId,
			boxAssocId,
			$author$project$ModelParts$Visible(1),
			props);
		var _v1 = A2(
			$author$project$Utils$info,
			'addItem',
			{cX: boxAssocId, a4: boxId, dm: itemId, ac: props});
		return A3(
			$author$project$Box$update,
			boxId,
			function (box) {
				return _Utils_update(
					box,
					{
						b7: A3($elm$core$Dict$insert, itemId, boxItem, box.b7)
					});
			},
			newModel);
	});
var $author$project$Main$addAssocAndAddToBox = F5(
	function (assocType, player1, player2, boxId, model) {
		var props = $author$project$ModelParts$AssocP($author$project$ModelParts$AssocProps);
		var _v0 = A4($author$project$Item$addAssoc, assocType, player1, player2, model);
		var newModel = _v0.a;
		var assocId = _v0.b;
		return A4($author$project$Box$addItem, assocId, props, boxId, newModel);
	});
var $author$project$Main$addAssoc = F4(
	function (player1, player2, boxId, model) {
		return A5($author$project$Main$addAssocAndAddToBox, 1, player1, player2, boxId, model);
	});
var $author$project$Main$cacheImageUrl = F3(
	function (imageId, url, model) {
		return _Utils_Tuple2(
			_Utils_update(
				model,
				{
					dh: A3($elm$core$Dict$insert, imageId, url, model.dh)
				}),
			$elm$core$Platform$Cmd$none);
	});
var $author$project$Feature$SelAPI$setItems = F2(
	function (items, model) {
		var selection = model.ax;
		return _Utils_update(
			model,
			{
				ax: _Utils_update(
					selection,
					{b7: items})
			});
	});
var $author$project$Feature$SelAPI$clear = function (model) {
	return A2($author$project$Feature$SelAPI$setItems, _List_Nil, model);
};
var $author$project$Feature$SearchAPI$setResult = F2(
	function (result, model) {
		var search = model.C;
		return _Utils_update(
			model,
			{
				C: _Utils_update(
					search,
					{cw: result})
			});
	});
var $author$project$Feature$SearchAPI$closeMenu = function (model) {
	return A2($author$project$Feature$SearchAPI$setResult, $author$project$Feature$Search$NoSearch, model);
};
var $author$project$Feature$IconAPI$closePicker = function (model) {
	var icon = model.aa;
	return _Utils_update(
		model,
		{
			aa: _Utils_update(
				icon,
				{cl: 1})
		});
};
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $author$project$Box$firstId = function (boxPath) {
	if (boxPath.b) {
		var boxId = boxPath.a;
		return boxId;
	} else {
		return A3($author$project$Utils$logError, 'firstId', 'boxPath is empty!', -1);
	}
};
var $elm$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			if (!list.b) {
				return false;
			} else {
				var x = list.a;
				var xs = list.b;
				if (isOkay(x)) {
					return true;
				} else {
					var $temp$isOkay = isOkay,
						$temp$list = xs;
					isOkay = $temp$isOkay;
					list = $temp$list;
					continue any;
				}
			}
		}
	});
var $author$project$Feature$SelAPI$isSelected = F3(
	function (itemId, boxId, model) {
		return A2(
			$elm$core$List$any,
			function (_v0) {
				var id = _v0.a;
				var boxPath = _v0.b;
				if (boxPath.b) {
					var boxId_ = boxPath.a;
					return _Utils_eq(itemId, id) && _Utils_eq(boxId, boxId_);
				} else {
					return false;
				}
			},
			model.ax.b7);
	});
var $author$project$ModelParts$View = 0;
var $elm$core$Basics$min = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) < 0) ? x : y;
	});
var $author$project$Box$Size$accumulateRect = F2(
	function (rectAcc, rect) {
		return A4(
			$author$project$ModelParts$Rectangle,
			A2($elm$core$Basics$min, rectAcc.d2, rect.d2),
			A2($elm$core$Basics$min, rectAcc.d4, rect.d4),
			A2($elm$core$Basics$max, rectAcc.a0, rect.a0),
			A2($elm$core$Basics$max, rectAcc.a1, rect.a1));
	});
var $author$project$Config$whiteBoxPadding = 12;
var $author$project$Box$Size$addBoxPadding = function (rect) {
	return A4($author$project$ModelParts$Rectangle, rect.d2 - $author$project$Config$whiteBoxPadding, rect.d4 - $author$project$Config$whiteBoxPadding, rect.a0 + $author$project$Config$whiteBoxPadding, rect.a1 + $author$project$Config$whiteBoxPadding);
};
var $author$project$Config$topicHeight = 28;
var $author$project$Config$topicH2 = ($author$project$Config$topicHeight / 2) | 0;
var $author$project$Config$topicWidth = 156;
var $author$project$Config$topicW2 = ($author$project$Config$topicWidth / 2) | 0;
var $author$project$Box$Size$boxExtent = F2(
	function (pos, rect) {
		var boxWidth = rect.a0 - rect.d2;
		var boxHeight = rect.a1 - rect.d4;
		return A4($author$project$ModelParts$Rectangle, pos.d1 - $author$project$Config$topicW2, pos.d3 - $author$project$Config$topicH2, (pos.d1 - $author$project$Config$topicW2) + boxWidth, (pos.d3 + $author$project$Config$topicH2) + boxHeight);
	});
var $author$project$Box$byId = F2(
	function (boxId, model) {
		return A2($elm$core$Dict$get, boxId, model.bL);
	});
var $author$project$Box$byIdOrLog = F2(
	function (boxId, model) {
		var _v0 = A2($author$project$Box$byId, boxId, model);
		if (!_v0.$) {
			var box = _v0.a;
			return $elm$core$Maybe$Just(box);
		} else {
			return A3($author$project$Utils$illegalBoxId, 'byIdOrLog', boxId, $elm$core$Maybe$Nothing);
		}
	});
var $author$project$Feature$Text$Edit = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Config$topicBorderWidth = 1;
var $author$project$Config$topicDetailMaxWidth = 300;
var $author$project$Config$topicSize = A2($author$project$ModelParts$Size, $author$project$Config$topicWidth, $author$project$Config$topicHeight);
var $author$project$Logger$toString = function (_v0) {
	return '';
};
var $author$project$Utils$fail = F3(
	function (funcName, args, val) {
		return A2(
			$author$project$Logger$log,
			'--> @' + (funcName + (' ' + ($author$project$Logger$toString(args) + ' failed'))),
			val);
	});
var $author$project$Item$byId = F2(
	function (itemId, model) {
		var _v0 = A2($elm$core$Dict$get, itemId, model.b7);
		if (!_v0.$) {
			var item = _v0.a;
			return $elm$core$Maybe$Just(item);
		} else {
			return A3($author$project$Utils$illegalItemId, 'byId', itemId, $elm$core$Maybe$Nothing);
		}
	});
var $author$project$Utils$topicMismatch = F3(
	function (funcName, id, val) {
		return A3(
			$author$project$Utils$logError,
			funcName,
			$elm$core$String$fromInt(id) + ' is not a Topic but an Assoc',
			val);
	});
var $author$project$Item$topicById = F2(
	function (topicId, model) {
		var _v0 = A2($author$project$Item$byId, topicId, model);
		if (!_v0.$) {
			var info = _v0.a.b2;
			if (!info.$) {
				var topic = info.a;
				return $elm$core$Maybe$Just(topic);
			} else {
				return A3($author$project$Utils$topicMismatch, 'topicById', topicId, $elm$core$Maybe$Nothing);
			}
		} else {
			return A3($author$project$Utils$fail, 'topicById', topicId, $elm$core$Maybe$Nothing);
		}
	});
var $author$project$Item$topicSize = F3(
	function (topicId, get, model) {
		var _v0 = A2($author$project$Item$topicById, topicId, model);
		if (!_v0.$) {
			var size = _v0.a.bo;
			return $elm$core$Maybe$Just(
				get(size));
		} else {
			return A3(
				$author$project$Utils$fail,
				'topicSize',
				{bD: topicId},
				$elm$core$Maybe$Nothing);
		}
	});
var $author$project$Box$Size$detailTopicExtent = F4(
	function (topicId, boxPath, pos, model) {
		var isEdit = _Utils_eq(
			model.dX.c7,
			A2($author$project$Feature$Text$Edit, topicId, boxPath));
		var get = isEdit ? function ($) {
			return $.c8;
		} : function ($) {
			return $.d_;
		};
		var maybeSize = function () {
			var _v1 = A3($author$project$Item$topicSize, topicId, get, model);
			if (!_v1.$) {
				var size = _v1.a;
				return isEdit ? $elm$core$Maybe$Just(
					_Utils_update(
						size,
						{cN: $author$project$Config$topicDetailMaxWidth})) : $elm$core$Maybe$Just(size);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		}();
		if (!maybeSize.$) {
			var size = maybeSize.a;
			return A4($author$project$ModelParts$Rectangle, pos.d1 - $author$project$Config$topicW2, pos.d3 - $author$project$Config$topicH2, (((pos.d1 - $author$project$Config$topicW2) + size.cN) + $author$project$Config$topicSize.b_) + (2 * $author$project$Config$topicBorderWidth), ((pos.d3 - $author$project$Config$topicH2) + size.b_) + (2 * $author$project$Config$topicBorderWidth));
		} else {
			return A4($author$project$ModelParts$Rectangle, 0, 0, 0, 0);
		}
	});
var $author$project$Box$Size$topicExtent = function (pos) {
	return A4($author$project$ModelParts$Rectangle, pos.d1 - $author$project$Config$topicW2, pos.d3 - $author$project$Config$topicH2, (pos.d1 + $author$project$Config$topicW2) + (2 * $author$project$Config$topicBorderWidth), (pos.d3 + $author$project$Config$topicH2) + (2 * $author$project$Config$topicBorderWidth));
};
var $author$project$Box$isVisible = function (item) {
	var _v0 = item.al;
	if (!_v0.$) {
		return true;
	} else {
		return false;
	}
};
var $elm$core$Basics$not = _Basics_not;
var $elm$core$Dict$values = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, valueList) {
				return A2($elm$core$List$cons, value, valueList);
			}),
		_List_Nil,
		dict);
};
var $author$project$Box$isEmpty = F2(
	function (boxId, model) {
		var _v0 = A2($author$project$Box$byIdOrLog, boxId, model);
		if (!_v0.$) {
			var box = _v0.a;
			return !A2(
				$elm$core$List$any,
				$author$project$Box$isVisible,
				$elm$core$Dict$values(box.b7));
		} else {
			return false;
		}
	});
var $elm$core$Dict$member = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$get, key, dict);
		if (!_v0.$) {
			return true;
		} else {
			return false;
		}
	});
var $author$project$Item$isBox = F2(
	function (id, model) {
		return A2($elm$core$Dict$member, id, model.bL);
	});
var $author$project$Feature$SelAPI$single = function (model) {
	var _v0 = model.ax.b7;
	if (_v0.b && (!_v0.b.b)) {
		var selItem = _v0.a;
		return $elm$core$Maybe$Just(selItem);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Feature$SelAPI$revelationBoxPath = function (model) {
	var _v0 = model.C.cw;
	switch (_v0.$) {
		case 0:
			var _v1 = $author$project$Feature$SelAPI$single(model);
			if (!_v1.$) {
				var _v2 = _v1.a;
				var id = _v2.a;
				var boxPath = _v2.b;
				var _v3 = A2($author$project$Item$isBox, id, model);
				if (_v3) {
					return $elm$core$Maybe$Just(
						A2($elm$core$List$cons, id, boxPath));
				} else {
					return $elm$core$Maybe$Just(
						_List_fromArray(
							[model.a4]));
				}
			} else {
				return $elm$core$Maybe$Just(
					_List_fromArray(
						[model.a4]));
			}
		case 1:
			var _v4 = $author$project$Feature$SelAPI$single(model);
			if (!_v4.$) {
				var _v5 = _v4.a;
				var boxPath = _v5.b;
				return $elm$core$Maybe$Just(boxPath);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		default:
			return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Feature$SelAPI$revelationBoxId = function (model) {
	var _v0 = $author$project$Feature$SelAPI$revelationBoxPath(model);
	if ((!_v0.$) && _v0.a.b) {
		var _v1 = _v0.a;
		var boxId = _v1.a;
		return $elm$core$Maybe$Just(boxId);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Map$Model$limboState = function (model) {
	var _v0 = $author$project$Feature$SelAPI$revelationBoxId(model);
	if (!_v0.$) {
		var boxId = _v0.a;
		var _v1 = model.C.cw;
		_v1$2:
		while (true) {
			switch (_v1.$) {
				case 0:
					if (!_v1.b.$) {
						var topicId = _v1.b.a;
						return $elm$core$Maybe$Just(
							_Utils_Tuple3(topicId, $elm$core$Maybe$Nothing, boxId));
					} else {
						break _v1$2;
					}
				case 1:
					if (!_v1.b.$) {
						var _v2 = _v1.b.a;
						var topicId = _v2.a;
						var assocId = _v2.b;
						return $elm$core$Maybe$Just(
							_Utils_Tuple3(
								topicId,
								$elm$core$Maybe$Just(assocId),
								boxId));
					} else {
						break _v1$2;
					}
				default:
					break _v1$2;
			}
		}
		return $elm$core$Maybe$Nothing;
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Map$Model$isLimboTopic = F3(
	function (topicId, boxId, model) {
		var _v0 = $author$project$Map$Model$limboState(model);
		if (!_v0.$) {
			var _v1 = _v0.a;
			var topicId_ = _v1.a;
			var boxId_ = _v1.c;
			return _Utils_eq(topicId, topicId_) && _Utils_eq(boxId, boxId_);
		} else {
			return false;
		}
	});
var $author$project$Map$Model$effectiveDisplayMode = F4(
	function (topicId, boxId, model, props) {
		return _Utils_update(
			props,
			{
				aI: function () {
					if (A3($author$project$Map$Model$isLimboTopic, topicId, boxId, model)) {
						var _v0 = props.aI;
						if (!_v0.$) {
							return $author$project$ModelParts$TopicD(1);
						} else {
							var _v1 = A2($author$project$Box$isEmpty, topicId, model);
							if (_v1) {
								return props.aI;
							} else {
								return $author$project$ModelParts$BoxD(1);
							}
						}
					} else {
						return props.aI;
					}
				}()
			});
	});
var $author$project$Box$hasItem = F3(
	function (boxId, itemId, model) {
		var _v0 = A2($author$project$Box$byIdOrLog, boxId, model);
		if (!_v0.$) {
			var box = _v0.a;
			return A2($elm$core$Dict$member, itemId, box.b7);
		} else {
			return false;
		}
	});
var $author$project$Config$initTopicPos = A2($author$project$ModelParts$Point, 104, 72);
var $author$project$Box$initTopicPos = F2(
	function (boxId, model) {
		var _v0 = A2($author$project$Box$byIdOrLog, boxId, model);
		if (!_v0.$) {
			var box = _v0.a;
			return A2($author$project$ModelParts$Point, ($author$project$Config$initTopicPos.d1 + box.aO.d2) + box.aU.d1, ($author$project$Config$initTopicPos.d3 + box.aO.d4) + box.aU.d3);
		} else {
			return A2($author$project$ModelParts$Point, 0, 0);
		}
	});
var $author$project$Box$initTopicProps = F3(
	function (topicId, boxId, model) {
		return A2(
			$author$project$ModelParts$TopicProps,
			A2($author$project$Box$initTopicPos, boxId, model),
			function () {
				var _v0 = A2($author$project$Item$isBox, topicId, model);
				if (_v0) {
					return $author$project$ModelParts$BoxD(0);
				} else {
					return $author$project$ModelParts$TopicD(0);
				}
			}());
	});
var $author$project$Box$isTopic = function (item) {
	var _v0 = item.ac;
	if (!_v0.$) {
		return true;
	} else {
		return false;
	}
};
var $elm$core$List$filter = F2(
	function (isGood, list) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, xs) {
					return isGood(x) ? A2($elm$core$List$cons, x, xs) : xs;
				}),
			_List_Nil,
			list);
	});
var $author$project$Map$Model$isLimboAssoc = F3(
	function (assocId, boxId, model) {
		var _v0 = $author$project$Map$Model$limboState(model);
		if ((!_v0.$) && (!_v0.a.b.$)) {
			var _v1 = _v0.a;
			var assocId_ = _v1.b.a;
			var boxId_ = _v1.c;
			return _Utils_eq(assocId, assocId_) && _Utils_eq(boxId, boxId_);
		} else {
			return false;
		}
	});
var $author$project$Map$Model$isLimboItem = F3(
	function (item, boxId, model) {
		var isLimbo = function () {
			var _v0 = item.ac;
			if (!_v0.$) {
				return $author$project$Map$Model$isLimboTopic;
			} else {
				return $author$project$Map$Model$isLimboAssoc;
			}
		}();
		return A3(isLimbo, item.aK, boxId, model);
	});
var $author$project$Map$Model$shouldItemRender = F3(
	function (boxId, model, item) {
		return $author$project$Box$isVisible(item) || A3($author$project$Map$Model$isLimboItem, item, boxId, model);
	});
var $author$project$Map$Model$itemsToRender = F3(
	function (box, filter, model) {
		return A2(
			$elm$core$List$filter,
			A2($author$project$Map$Model$shouldItemRender, box.aK, model),
			A2(
				$elm$core$List$filter,
				filter,
				$elm$core$Dict$values(box.b7)));
	});
var $author$project$Map$Model$topicsToRender = F2(
	function (box, model) {
		var topics = A2(
			$elm$core$List$map,
			function (boxItem) {
				return _Utils_update(
					boxItem,
					{
						ac: function () {
							var _v3 = boxItem.ac;
							if (!_v3.$) {
								var props = _v3.a;
								return $author$project$ModelParts$TopicP(
									A4($author$project$Map$Model$effectiveDisplayMode, boxItem.aK, box.aK, model, props));
							} else {
								return A3($author$project$Utils$logError, 'topicsToRender', 'Found assoc in a topic list', boxItem.ac);
							}
						}()
					});
			},
			A3($author$project$Map$Model$itemsToRender, box, $author$project$Box$isTopic, model));
		var limboTopic = function () {
			var _v0 = $author$project$Map$Model$limboState(model);
			if (!_v0.$) {
				var _v1 = _v0.a;
				var topicId = _v1.a;
				var limboBoxId = _v1.c;
				if (_Utils_eq(limboBoxId, box.aK) && (!A3($author$project$Box$hasItem, box.aK, topicId, model))) {
					var props = $author$project$ModelParts$TopicP(
						A4(
							$author$project$Map$Model$effectiveDisplayMode,
							topicId,
							box.aK,
							model,
							A3($author$project$Box$initTopicProps, topicId, box.aK, model)));
					var _v2 = A2(
						$author$project$Utils$info,
						'viewLimboTopic',
						_Utils_Tuple3(topicId, 'not in box', box.aK));
					return _List_fromArray(
						[
							A4($author$project$ModelParts$BoxItem, topicId, -1, $author$project$ModelParts$Removed, props)
						]);
				} else {
					return _List_Nil;
				}
			} else {
				return _List_Nil;
			}
		}();
		return _Utils_ap(topics, limboTopic);
	});
var $author$project$Box$updateTopicProps_ = F4(
	function (topicId, boxId, transform, model) {
		return A3(
			$author$project$Box$update,
			boxId,
			function (box) {
				return _Utils_update(
					box,
					{
						b7: A3(
							$elm$core$Dict$update,
							topicId,
							function (item_) {
								if (!item_.$) {
									var item = item_.a;
									var _v1 = item.ac;
									if (!_v1.$) {
										var props = _v1.a;
										return $elm$core$Maybe$Just(
											_Utils_update(
												item,
												{
													ac: $author$project$ModelParts$TopicP(
														transform(props))
												}));
									} else {
										return A3($author$project$Utils$topicMismatch, 'updateTopicProps_', topicId, $elm$core$Maybe$Nothing);
									}
								} else {
									return A3($author$project$Utils$illegalItemId, 'updateTopicProps_', topicId, $elm$core$Maybe$Nothing);
								}
							},
							box.b7)
					});
			},
			model);
	});
var $author$project$Box$setTopicPosByDelta = F4(
	function (topicId, boxId, delta, model) {
		return A4(
			$author$project$Box$updateTopicProps_,
			topicId,
			boxId,
			function (props) {
				return _Utils_update(
					props,
					{
						av: A2($author$project$ModelParts$Point, props.av.d1 + delta.d1, props.av.d3 + delta.d3)
					});
			},
			model);
	});
var $author$project$Box$Size$adjustBoxPos = F5(
	function (boxId, parentBoxId, newRect, oldRect, model) {
		return A4(
			$author$project$Box$setTopicPosByDelta,
			boxId,
			parentBoxId,
			A2($author$project$ModelParts$Point, newRect.d2 - oldRect.d2, newRect.d4 - oldRect.d4),
			model);
	});
var $elm$core$List$drop = F2(
	function (n, list) {
		drop:
		while (true) {
			if (n <= 0) {
				return list;
			} else {
				if (!list.b) {
					return list;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs;
					n = $temp$n;
					list = $temp$list;
					continue drop;
				}
			}
		}
	});
var $elm$core$List$member = F2(
	function (x, xs) {
		return A2(
			$elm$core$List$any,
			function (a) {
				return _Utils_eq(a, x);
			},
			xs);
	});
var $author$project$Box$updateRect = F3(
	function (boxId, transform, model) {
		return A3(
			$author$project$Box$update,
			boxId,
			function (box) {
				return _Utils_update(
					box,
					{
						aO: transform(box.aO)
					});
			},
			model);
	});
var $author$project$Box$Size$setBoxRect = F3(
	function (boxId, rect, model) {
		return A3(
			$author$project$Box$updateRect,
			boxId,
			function (_v0) {
				return rect;
			},
			model);
	});
var $author$project$Box$Size$updateBoxGeometry = F4(
	function (boxPath, newRect, oldRect, model) {
		if (boxPath.b) {
			if (boxPath.b.b) {
				var boxId = boxPath.a;
				var _v1 = boxPath.b;
				var parentBoxId = _v1.a;
				var _v2 = function () {
					var _v3 = model.dt.c6;
					if ((_v3.$ === 3) && (!_v3.a)) {
						var _v4 = _v3.a;
						var dragPath = _v3.c;
						return _Utils_Tuple3(
							true,
							_Utils_eq(
								A2(
									$elm$core$List$drop,
									$elm$core$List$length(dragPath) - $elm$core$List$length(boxPath),
									dragPath),
								boxPath),
							A2($elm$core$List$member, boxId, dragPath));
					} else {
						return _Utils_Tuple3(false, false, false);
					}
				}();
				var isDragInProgress = _v2.a;
				var isOnDragPath = _v2.b;
				var isBoxInDragPath = _v2.c;
				return isDragInProgress ? (isOnDragPath ? A5(
					$author$project$Box$Size$adjustBoxPos,
					boxId,
					parentBoxId,
					newRect,
					oldRect,
					A3($author$project$Box$Size$setBoxRect, boxId, newRect, model)) : (isBoxInDragPath ? model : A3($author$project$Box$Size$setBoxRect, boxId, newRect, model))) : A3($author$project$Box$Size$setBoxRect, boxId, newRect, model);
			} else {
				var boxId = boxPath.a;
				return A3($author$project$Box$Size$setBoxRect, boxId, newRect, model);
			}
		} else {
			return A3($author$project$Utils$logError, 'updateBoxGeometry', 'boxPath is empty!', model);
		}
	});
var $author$project$Box$Size$accumulateItem = F4(
	function (boxItem, boxPath, rectAcc, model) {
		var _v11 = A3($author$project$Box$Size$calcItemRect, boxItem, boxPath, model);
		var rect = _v11.a;
		var model_ = _v11.b;
		return _Utils_Tuple2(
			A2($author$project$Box$Size$accumulateRect, rectAcc, rect),
			model_);
	});
var $author$project$Box$Size$calcBoxRect = F2(
	function (boxPath, model) {
		var boxId = $author$project$Box$firstId(boxPath);
		var _v8 = A2($author$project$Box$byIdOrLog, boxId, model);
		if (!_v8.$) {
			var box = _v8.a;
			var _v9 = A3(
				$elm$core$List$foldr,
				F2(
					function (boxItem, _v10) {
						var rectAcc = _v10.a;
						var modelAcc = _v10.b;
						return A4($author$project$Box$Size$accumulateItem, boxItem, boxPath, rectAcc, modelAcc);
					}),
				_Utils_Tuple2(
					A4($author$project$ModelParts$Rectangle, 0, 0, 0, 0),
					model),
				A2($author$project$Map$Model$topicsToRender, box, model));
			var rect = _v9.a;
			var model_ = _v9.b;
			var newRect = $author$project$Box$Size$addBoxPadding(rect);
			return _Utils_Tuple2(
				newRect,
				A4($author$project$Box$Size$updateBoxGeometry, boxPath, newRect, box.aO, model_));
		} else {
			return _Utils_Tuple2(
				A4($author$project$ModelParts$Rectangle, 0, 0, 0, 0),
				model);
		}
	});
var $author$project$Box$Size$calcItemRect = F3(
	function (boxItem, boxPath, model) {
		var _v0 = boxItem.ac;
		if (!_v0.$) {
			var pos = _v0.a.av;
			var displayMode = _v0.a.aI;
			if (!displayMode.$) {
				if (!displayMode.a) {
					var _v2 = displayMode.a;
					return _Utils_Tuple2(
						$author$project$Box$Size$topicExtent(pos),
						model);
				} else {
					var _v3 = displayMode.a;
					return _Utils_Tuple2(
						A4($author$project$Box$Size$detailTopicExtent, boxItem.aK, boxPath, pos, model),
						model);
				}
			} else {
				switch (displayMode.a) {
					case 0:
						var _v4 = displayMode.a;
						return _Utils_Tuple2(
							$author$project$Box$Size$topicExtent(pos),
							model);
					case 1:
						var _v5 = displayMode.a;
						var _v6 = A2(
							$author$project$Box$Size$calcBoxRect,
							A2($elm$core$List$cons, boxItem.aK, boxPath),
							model);
						var rect_ = _v6.a;
						var model_ = _v6.b;
						return _Utils_Tuple2(
							A2($author$project$Box$Size$boxExtent, pos, rect_),
							model_);
					default:
						var _v7 = displayMode.a;
						return _Utils_Tuple2(
							$author$project$Box$Size$topicExtent(pos),
							model);
				}
			}
		} else {
			return _Utils_Tuple2(
				A4($author$project$ModelParts$Rectangle, 0, 0, 0, 0),
				model);
		}
	});
var $elm$core$Tuple$second = function (_v0) {
	var y = _v0.b;
	return y;
};
var $author$project$Box$Size$auto = function (model) {
	return A2(
		$author$project$Box$Size$calcBoxRect,
		_List_fromArray(
			[model.a4]),
		model).b;
};
var $author$project$Box$fromPath = function (boxPath) {
	return A2(
		$elm$core$String$join,
		',',
		A2($elm$core$List$map, $elm$core$String$fromInt, boxPath));
};
var $author$project$Box$elemId = F3(
	function (name, id, boxPath) {
		return name + ('-' + ($elm$core$String$fromInt(id) + (',' + $author$project$Box$fromPath(boxPath))));
	});
var $author$project$Feature$Text$GotTextSize = F3(
	function (a, b, c) {
		return {$: 2, a: a, b: b, c: c};
	});
var $elm$core$Task$onError = _Scheduler_onError;
var $elm$core$Task$attempt = F2(
	function (resultToMessage, task) {
		return $elm$core$Task$command(
			A2(
				$elm$core$Task$onError,
				A2(
					$elm$core$Basics$composeL,
					A2($elm$core$Basics$composeL, $elm$core$Task$succeed, resultToMessage),
					$elm$core$Result$Err),
				A2(
					$elm$core$Task$andThen,
					A2(
						$elm$core$Basics$composeL,
						A2($elm$core$Basics$composeL, $elm$core$Task$succeed, resultToMessage),
						$elm$core$Result$Ok),
					task)));
	});
var $elm$browser$Browser$Dom$getElement = _Browser_getElement;
var $author$project$Utils$toString = $author$project$Logger$toString;
var $author$project$Feature$TextAPI$measureElement = F3(
	function (elemId, topicId, sizeField) {
		return A2(
			$elm$core$Task$attempt,
			function (result) {
				if (!result.$) {
					var element = result.a.c9;
					return $author$project$Model$Text(
						A3(
							$author$project$Feature$Text$GotTextSize,
							topicId,
							sizeField,
							A2(
								$author$project$ModelParts$Size,
								$elm$core$Basics$round(element.d$),
								$elm$core$Basics$round(element.df))));
				} else {
					var err = result.a;
					return A3(
						$author$project$Utils$logError,
						'measureElement',
						$author$project$Utils$toString(err),
						$author$project$Model$NoOp);
				}
			},
			$elm$browser$Browser$Dom$getElement(elemId));
	});
var $author$project$Feature$TextAPI$setEditState = F2(
	function (state, model) {
		var text = model.dX;
		return _Utils_update(
			model,
			{
				dX: _Utils_update(
					text,
					{c7: state})
			});
	});
var $author$project$Feature$TextAPI$leaveEdit = function (model) {
	var _v0 = model.dX.c7;
	if (!_v0.$) {
		var topicId = _v0.a;
		var boxPath = _v0.b;
		var elemId = A3($author$project$Box$elemId, 'topic', topicId, boxPath);
		return _Utils_Tuple2(
			$author$project$Box$Size$auto(
				A2($author$project$Feature$TextAPI$setEditState, $author$project$Feature$Text$NoEdit, model)),
			A3($author$project$Feature$TextAPI$measureElement, elemId, topicId, 0));
	} else {
		return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
	}
};
var $author$project$Main$cancelUI = F2(
	function (maybeTarget, model) {
		var shouldClear = function () {
			if (!maybeTarget.$) {
				var _v1 = maybeTarget.a;
				var itemId = _v1.a;
				var boxPath = _v1.b;
				return !A3(
					$author$project$Feature$SelAPI$isSelected,
					itemId,
					$author$project$Box$firstId(boxPath),
					model);
			} else {
				return true;
			}
		}();
		return $author$project$Feature$TextAPI$leaveEdit(
			$author$project$Feature$SearchAPI$closeMenu(
				$author$project$Feature$IconAPI$closePicker(
					(shouldClear ? $author$project$Feature$SelAPI$clear : $elm$core$Basics$identity)(model))));
	});
var $elm$core$Maybe$andThen = F2(
	function (callback, maybeValue) {
		if (!maybeValue.$) {
			var value = maybeValue.a;
			return callback(value);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Utils$assocMismatch = F3(
	function (funcName, id, val) {
		return A3(
			$author$project$Utils$logError,
			funcName,
			$elm$core$String$fromInt(id) + ' is not an Assoc but a Topic',
			val);
	});
var $author$project$Item$assocById = F2(
	function (assocId, model) {
		var _v0 = A2($author$project$Item$byId, assocId, model);
		if (!_v0.$) {
			var info = _v0.a.b2;
			if (!info.$) {
				return A3($author$project$Utils$assocMismatch, 'assocById', assocId, $elm$core$Maybe$Nothing);
			} else {
				var assoc = info.a;
				return $elm$core$Maybe$Just(assoc);
			}
		} else {
			return A3($author$project$Utils$fail, 'assocById', assocId, $elm$core$Maybe$Nothing);
		}
	});
var $author$project$Item$hasPlayer = F3(
	function (playerId, model, assocId) {
		var _v0 = A2($author$project$Item$assocById, assocId, model);
		if (!_v0.$) {
			var assoc = _v0.a;
			return _Utils_eq(assoc.dK, playerId) || _Utils_eq(assoc.dL, playerId);
		} else {
			return false;
		}
	});
var $author$project$Box$isAssoc = function (item) {
	return !$author$project$Box$isTopic(item);
};
var $author$project$Box$assocsOfPlayer_ = F3(
	function (playerId, items, model) {
		return A2(
			$elm$core$List$filter,
			A2($author$project$Item$hasPlayer, playerId, model),
			A2(
				$elm$core$List$map,
				function ($) {
					return $.aK;
				},
				A2(
					$elm$core$List$filter,
					$author$project$Box$isAssoc,
					$elm$core$Dict$values(items))));
	});
var $author$project$Box$removeItem__ = F2(
	function (itemId, items) {
		return A3(
			$elm$core$Dict$update,
			itemId,
			function (maybeItem) {
				if (!maybeItem.$) {
					var item = maybeItem.a;
					return $elm$core$Maybe$Just(
						_Utils_update(
							item,
							{al: $author$project$ModelParts$Removed}));
				} else {
					return $elm$core$Maybe$Nothing;
				}
			},
			items);
	});
var $author$project$Box$removeItem_ = F3(
	function (itemId, items, model) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (assocId, itemsAcc) {
					return A3($author$project$Box$removeItem_, assocId, itemsAcc, model);
				}),
			A2($author$project$Box$removeItem__, itemId, items),
			A3($author$project$Box$assocsOfPlayer_, itemId, items, model));
	});
var $elm$core$Dict$map = F2(
	function (func, dict) {
		if (dict.$ === -2) {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				A2(func, key, value),
				A2($elm$core$Dict$map, func, left),
				A2($elm$core$Dict$map, func, right));
		}
	});
var $author$project$Box$updateTopicPropsInAllBoxes_ = F3(
	function (topicId, transform, model) {
		return _Utils_update(
			model,
			{
				bL: A2(
					$elm$core$Dict$map,
					F2(
						function (_v0, box) {
							return _Utils_update(
								box,
								{
									b7: A3(
										$elm$core$Dict$update,
										topicId,
										function (item_) {
											if (!item_.$) {
												var item = item_.a;
												var _v2 = item.ac;
												if (!_v2.$) {
													var props = _v2.a;
													return $elm$core$Maybe$Just(
														_Utils_update(
															item,
															{
																ac: $author$project$ModelParts$TopicP(
																	transform(props))
															}));
												} else {
													return A3($author$project$Utils$topicMismatch, 'updateTopicPropsInAllBoxes_', topicId, item_);
												}
											} else {
												return $elm$core$Maybe$Nothing;
											}
										},
										box.b7)
								});
						}),
					model.bL)
			});
	});
var $author$project$Box$resetEmptyBox_ = F2(
	function (boxId, model) {
		var _v0 = A2($author$project$Box$isEmpty, boxId, model);
		if (_v0) {
			return A3(
				$author$project$Box$updateTopicPropsInAllBoxes_,
				boxId,
				function (props) {
					return _Utils_update(
						props,
						{
							aI: $author$project$ModelParts$BoxD(0)
						});
				},
				model);
		} else {
			return model;
		}
	});
var $author$project$Box$removeItem = F3(
	function (itemId, boxId, model) {
		return A2(
			$author$project$Box$resetEmptyBox_,
			boxId,
			A3(
				$author$project$Box$update,
				boxId,
				function (box) {
					return _Utils_update(
						box,
						{
							b7: A3($author$project$Box$removeItem_, itemId, box.b7, model)
						});
				},
				model));
	});
var $author$project$Feature$SelAPI$select = F3(
	function (itemId, boxPath, model) {
		var _v0 = A2(
			$author$project$Utils$info,
			'select',
			_Utils_Tuple2(itemId, boxPath));
		return A2(
			$author$project$Feature$SelAPI$setItems,
			_List_fromArray(
				[
					_Utils_Tuple2(itemId, boxPath)
				]),
			model);
	});
var $author$project$Box$setTopicPos = F4(
	function (topicId, boxId, pos, model) {
		return A4(
			$author$project$Box$updateTopicProps_,
			topicId,
			boxId,
			function (props) {
				return _Utils_update(
					props,
					{av: pos});
			},
			model);
	});
var $author$project$Utils$itemNotInBox = F4(
	function (funcName, itemId, boxId, val) {
		return A3(
			$author$project$Utils$logError,
			funcName,
			'item ' + ($elm$core$String$fromInt(itemId) + (' not in box ' + $elm$core$String$fromInt(boxId))),
			val);
	});
var $author$project$Box$itemByIdOrLog_ = F3(
	function (itemId, boxId, model) {
		return A2(
			$elm$core$Maybe$andThen,
			function (box) {
				var _v0 = A2($elm$core$Dict$get, itemId, box.b7);
				if (!_v0.$) {
					var boxItem = _v0.a;
					return $elm$core$Maybe$Just(boxItem);
				} else {
					return A4($author$project$Utils$itemNotInBox, 'itemByIdOrLog_', itemId, box.aK, $elm$core$Maybe$Nothing);
				}
			},
			A2($author$project$Box$byIdOrLog, boxId, model));
	});
var $author$project$Box$topicProps = F3(
	function (topicId, boxId, model) {
		var _v0 = A3($author$project$Box$itemByIdOrLog_, topicId, boxId, model);
		if (!_v0.$) {
			var boxItem = _v0.a;
			var _v1 = boxItem.ac;
			if (!_v1.$) {
				var props = _v1.a;
				return $elm$core$Maybe$Just(props);
			} else {
				return A3($author$project$Utils$topicMismatch, 'topicProps', topicId, $elm$core$Maybe$Nothing);
			}
		} else {
			return A3(
				$author$project$Utils$fail,
				'topicProps',
				{a4: boxId, bD: topicId},
				$elm$core$Maybe$Nothing);
		}
	});
var $author$project$Main$moveTopicToBox = F7(
	function (topicId, boxId, origPos, targetBoxId, targetPath, pos, model) {
		var props_ = A2(
			$elm$core$Maybe$andThen,
			function (props) {
				return $elm$core$Maybe$Just(
					$author$project$ModelParts$TopicP(
						_Utils_update(
							props,
							{av: pos})));
			},
			A3($author$project$Box$topicProps, topicId, boxId, model));
		if (!props_.$) {
			var props = props_.a;
			return $author$project$Box$Size$auto(
				A3(
					$author$project$Feature$SelAPI$select,
					targetBoxId,
					targetPath,
					A4(
						$author$project$Box$addItem,
						topicId,
						props,
						targetBoxId,
						A4(
							$author$project$Box$setTopicPos,
							topicId,
							boxId,
							origPos,
							A3($author$project$Box$removeItem, topicId, boxId, model)))));
		} else {
			return model;
		}
	});
var $elm_community$undo_redo$UndoList$new = F2(
	function (event, _v0) {
		var past = _v0.s;
		var present = _v0.aw;
		return A3(
			$elm_community$undo_redo$UndoList$UndoList,
			A2($elm$core$List$cons, present, past),
			event,
			_List_Nil);
	});
var $author$project$Undo$push = F2(
	function (undoModel, _v0) {
		var model = _v0.a;
		var cmd = _v0.b;
		return _Utils_Tuple2(
			A2($elm_community$undo_redo$UndoList$new, model, undoModel),
			cmd);
	});
var $author$project$Main$select = F3(
	function (itemId, boxPath, model) {
		return _Utils_Tuple2(
			A3($author$project$Feature$SelAPI$select, itemId, boxPath, model),
			$elm$core$Platform$Cmd$none);
	});
var $author$project$ModelParts$encodeDisplayName = function (displayMode) {
	return $elm$json$Json$Encode$string(
		function () {
			if (!displayMode.$) {
				if (!displayMode.a) {
					var _v1 = displayMode.a;
					return 'LabelOnly';
				} else {
					var _v2 = displayMode.a;
					return 'Detail';
				}
			} else {
				switch (displayMode.a) {
					case 0:
						var _v3 = displayMode.a;
						return 'BlackBox';
					case 1:
						var _v4 = displayMode.a;
						return 'WhiteBox';
					default:
						var _v5 = displayMode.a;
						return 'Unboxed';
				}
			}
		}());
};
var $author$project$ModelParts$encodeVisibility = function (visibility) {
	return $elm$json$Json$Encode$string(
		function () {
			if (!visibility.$) {
				if (!visibility.a) {
					var _v1 = visibility.a;
					return 'Pinned';
				} else {
					var _v2 = visibility.a;
					return 'Visible';
				}
			} else {
				return 'Removed';
			}
		}());
};
var $elm$json$Json$Encode$int = _Json_wrap;
var $elm$json$Json$Encode$object = function (pairs) {
	return _Json_wrap(
		A3(
			$elm$core$List$foldl,
			F2(
				function (_v0, obj) {
					var k = _v0.a;
					var v = _v0.b;
					return A3(_Json_addField, k, v, obj);
				}),
			_Json_emptyObject(0),
			pairs));
};
var $author$project$ModelParts$encodeBoxItem = function (item) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'id',
				$elm$json$Json$Encode$int(item.aK)),
				_Utils_Tuple2(
				'boxAssocId',
				$elm$json$Json$Encode$int(item.cX)),
				_Utils_Tuple2(
				'visibility',
				$author$project$ModelParts$encodeVisibility(item.al)),
				function () {
				var _v0 = item.ac;
				if (!_v0.$) {
					var topicProps = _v0.a;
					return _Utils_Tuple2(
						'topicProps',
						$elm$json$Json$Encode$object(
							_List_fromArray(
								[
									_Utils_Tuple2(
									'pos',
									$elm$json$Json$Encode$object(
										_List_fromArray(
											[
												_Utils_Tuple2(
												'x',
												$elm$json$Json$Encode$int(topicProps.av.d1)),
												_Utils_Tuple2(
												'y',
												$elm$json$Json$Encode$int(topicProps.av.d3))
											]))),
									_Utils_Tuple2(
									'display',
									$author$project$ModelParts$encodeDisplayName(topicProps.aI))
								])));
				} else {
					var assosProps = _v0.a;
					return _Utils_Tuple2(
						'assocProps',
						$elm$json$Json$Encode$object(_List_Nil));
				}
			}()
			]));
};
var $elm$json$Json$Encode$list = F2(
	function (func, entries) {
		return _Json_wrap(
			A3(
				$elm$core$List$foldl,
				_Json_addEntry(func),
				_Json_emptyArray(0),
				entries));
	});
var $author$project$ModelParts$encodeBox = function (box) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'id',
				$elm$json$Json$Encode$int(box.aK)),
				_Utils_Tuple2(
				'rect',
				$elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'x1',
							$elm$json$Json$Encode$int(box.aO.d2)),
							_Utils_Tuple2(
							'y1',
							$elm$json$Json$Encode$int(box.aO.d4)),
							_Utils_Tuple2(
							'x2',
							$elm$json$Json$Encode$int(box.aO.a0)),
							_Utils_Tuple2(
							'y2',
							$elm$json$Json$Encode$int(box.aO.a1))
						]))),
				_Utils_Tuple2(
				'scroll',
				$elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'x',
							$elm$json$Json$Encode$int(box.aU.d1)),
							_Utils_Tuple2(
							'y',
							$elm$json$Json$Encode$int(box.aU.d3))
						]))),
				_Utils_Tuple2(
				'items',
				A2(
					$elm$json$Json$Encode$list,
					$author$project$ModelParts$encodeBoxItem,
					$elm$core$Dict$values(box.b7)))
			]));
};
var $author$project$ModelParts$encodeAssocType = function (assocType) {
	return $elm$json$Json$Encode$string(
		function () {
			if (!assocType) {
				return 'Hierarchy';
			} else {
				return 'Crosslink';
			}
		}());
};
var $author$project$ModelParts$encodeTextSize = function (size) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'view',
				$elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'w',
							$elm$json$Json$Encode$int(size.d_.cN)),
							_Utils_Tuple2(
							'h',
							$elm$json$Json$Encode$int(size.d_.b_))
						]))),
				_Utils_Tuple2(
				'editor',
				$elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'w',
							$elm$json$Json$Encode$int(size.c8.cN)),
							_Utils_Tuple2(
							'h',
							$elm$json$Json$Encode$int(size.c8.b_))
						])))
			]));
};
var $elm$core$Set$foldl = F3(
	function (func, initialState, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$foldl,
			F3(
				function (key, _v1, state) {
					return A2(func, key, state);
				}),
			initialState,
			dict);
	});
var $elm$json$Json$Encode$set = F2(
	function (func, entries) {
		return _Json_wrap(
			A3(
				$elm$core$Set$foldl,
				_Json_addEntry(func),
				_Json_emptyArray(0),
				entries));
	});
var $author$project$ModelParts$encodeItem = function (item) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				function () {
				var _v0 = item.b2;
				if (!_v0.$) {
					var topic = _v0.a;
					return _Utils_Tuple2(
						'topic',
						$elm$json$Json$Encode$object(
							_List_fromArray(
								[
									_Utils_Tuple2(
									'id',
									$elm$json$Json$Encode$int(topic.aK)),
									_Utils_Tuple2(
									'icon',
									$elm$json$Json$Encode$string(
										A2($elm$core$Maybe$withDefault, '', topic.aa))),
									_Utils_Tuple2(
									'text',
									$elm$json$Json$Encode$string(topic.dX)),
									_Utils_Tuple2(
									'size',
									$author$project$ModelParts$encodeTextSize(topic.bo)),
									_Utils_Tuple2(
									'assocIds',
									A2($elm$json$Json$Encode$set, $elm$json$Json$Encode$int, item.bH))
								])));
				} else {
					var assoc = _v0.a;
					return _Utils_Tuple2(
						'assoc',
						$elm$json$Json$Encode$object(
							_List_fromArray(
								[
									_Utils_Tuple2(
									'id',
									$elm$json$Json$Encode$int(assoc.aK)),
									_Utils_Tuple2(
									'type',
									$author$project$ModelParts$encodeAssocType(assoc.cT)),
									_Utils_Tuple2(
									'player1',
									$elm$json$Json$Encode$int(assoc.dK)),
									_Utils_Tuple2(
									'player2',
									$elm$json$Json$Encode$int(assoc.dL)),
									_Utils_Tuple2(
									'assocIds',
									A2($elm$json$Json$Encode$set, $elm$json$Json$Encode$int, item.bH))
								])));
				}
			}()
			]));
};
var $author$project$Model$encode = function (model) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'items',
				A2(
					$elm$json$Json$Encode$list,
					$author$project$ModelParts$encodeItem,
					$elm$core$Dict$values(model.b7))),
				_Utils_Tuple2(
				'boxes',
				A2(
					$elm$json$Json$Encode$list,
					$author$project$ModelParts$encodeBox,
					$elm$core$Dict$values(model.bL))),
				_Utils_Tuple2(
				'boxId',
				$elm$json$Json$Encode$int(model.a4)),
				_Utils_Tuple2(
				'nextId',
				$elm$json$Json$Encode$int(model.dw))
			]));
};
var $author$project$Storage$storeModel = _Platform_outgoingPort('storeModel', $elm$core$Basics$identity);
var $author$project$Storage$store = function (model) {
	return _Utils_Tuple2(
		model,
		$author$project$Storage$storeModel(
			$author$project$Model$encode(model)));
};
var $elm_community$undo_redo$UndoList$mapPresent = F2(
	function (f, _v0) {
		var past = _v0.s;
		var present = _v0.aw;
		var future = _v0.u;
		return A3(
			$elm_community$undo_redo$UndoList$UndoList,
			past,
			f(present),
			future);
	});
var $author$project$Undo$swap = F2(
	function (undoModel, _v0) {
		var model = _v0.a;
		var cmd = _v0.b;
		return _Utils_Tuple2(
			A2(
				$elm_community$undo_redo$UndoList$mapPresent,
				function (_v1) {
					return model;
				},
				undoModel),
			cmd);
	});
var $author$project$Item$updateTopic = F3(
	function (topicId, transform, model) {
		return A3(
			$author$project$Item$update,
			topicId,
			function (item) {
				var _v0 = item.b2;
				if (!_v0.$) {
					var topic = _v0.a;
					return _Utils_update(
						item,
						{
							b2: $author$project$ModelParts$Topic(
								transform(topic))
						});
				} else {
					return A3($author$project$Utils$topicMismatch, 'updateTopic', topicId, item);
				}
			},
			model);
	});
var $author$project$Feature$IconAPI$setIcon = F2(
	function (iconName, model) {
		var _v0 = $author$project$Feature$SelAPI$single(model);
		if (!_v0.$) {
			var _v1 = _v0.a;
			var id = _v1.a;
			return A3(
				$author$project$Item$updateTopic,
				id,
				function (topic) {
					return _Utils_update(
						topic,
						{aa: iconName});
				},
				model);
		} else {
			return model;
		}
	});
var $author$project$Feature$IconAPI$update = F2(
	function (msg, undoModel) {
		var present = undoModel.aw;
		var maybeIcon = msg;
		return A2(
			$author$project$Undo$push,
			undoModel,
			$author$project$Storage$store(
				$author$project$Feature$IconAPI$closePicker(
					A2($author$project$Feature$IconAPI$setIcon, maybeIcon, present))));
	});
var $author$project$Feature$Mouse$DraftAssoc = 1;
var $author$project$Feature$Mouse$Drag = F6(
	function (a, b, c, d, e, f) {
		return {$: 3, a: a, b: b, c: c, d: d, e: e, f: f};
	});
var $author$project$Feature$MouseAPI$setDragState = F2(
	function (dragState, model) {
		var mouse = model.dt;
		return _Utils_update(
			model,
			{
				dt: _Utils_update(
					mouse,
					{c6: dragState})
			});
	});
var $author$project$Feature$MouseAPI$hover = F4(
	function (_class, targetId, targetPath, model) {
		var _v0 = model.dt.c6;
		switch (_v0.$) {
			case 3:
				var dragMode = _v0.a;
				var id = _v0.b;
				var boxPath = _v0.c;
				var origPos = _v0.d;
				var lastPos = _v0.e;
				var isSelf = _Utils_eq(
					_Utils_Tuple2(
						id,
						$author$project$Box$firstId(boxPath)),
					_Utils_Tuple2(
						targetId,
						$author$project$Box$firstId(targetPath)));
				var isBox = A2($author$project$Item$isBox, targetId, model);
				var target = ((!isSelf) && (isBox || (dragMode === 1))) ? $elm$core$Maybe$Just(
					_Utils_Tuple2(targetId, targetPath)) : $elm$core$Maybe$Nothing;
				return A2(
					$author$project$Feature$MouseAPI$setDragState,
					A6($author$project$Feature$Mouse$Drag, dragMode, id, boxPath, origPos, lastPos, target),
					model);
			case 4:
				return A2(
					$author$project$Feature$MouseAPI$setDragState,
					$author$project$Feature$Mouse$NoDrag(
						$elm$core$Maybe$Just(
							_Utils_Tuple2(targetId, targetPath))),
					model);
			default:
				return model;
		}
	});
var $author$project$Model$Cancel = function (a) {
	return {$: 4, a: a};
};
var $author$project$Utils$command = function (msg) {
	return A2(
		$elm$core$Task$perform,
		function (_v0) {
			return msg;
		},
		$elm$core$Task$succeed(0));
};
var $author$project$Feature$MouseAPI$mouseDown = $author$project$Utils$command(
	$author$project$Model$Cancel($elm$core$Maybe$Nothing));
var $author$project$Feature$Mouse$Time = function (a) {
	return {$: 6, a: a};
};
var $author$project$Feature$Mouse$WaitForStartTime = F4(
	function (a, b, c, d) {
		return {$: 0, a: a, b: b, c: c, d: d};
	});
var $elm$time$Time$Name = function (a) {
	return {$: 0, a: a};
};
var $elm$time$Time$Offset = function (a) {
	return {$: 1, a: a};
};
var $elm$time$Time$Zone = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$time$Time$customZone = $elm$time$Time$Zone;
var $elm$time$Time$Posix = $elm$core$Basics$identity;
var $elm$time$Time$millisToPosix = $elm$core$Basics$identity;
var $elm$time$Time$now = _Time_now($elm$time$Time$millisToPosix);
var $author$project$Feature$MouseAPI$mouseDownOnItem = F5(
	function (_class, id, boxPath, pos, model) {
		return _Utils_Tuple2(
			A2(
				$author$project$Feature$MouseAPI$setDragState,
				A4($author$project$Feature$Mouse$WaitForStartTime, _class, id, boxPath, pos),
				model),
			$elm$core$Platform$Cmd$batch(
				_List_fromArray(
					[
						$author$project$Utils$command(
						$author$project$Model$Cancel(
							$elm$core$Maybe$Just(
								_Utils_Tuple2(id, boxPath)))),
						A2(
						$elm$core$Task$perform,
						A2($elm$core$Basics$composeL, $author$project$Model$Mouse, $author$project$Feature$Mouse$Time),
						$elm$time$Time$now)
					])));
	});
var $author$project$Feature$Mouse$WaitForEndTime = F5(
	function (a, b, c, d, e) {
		return {$: 2, a: a, b: b, c: c, d: d, e: e};
	});
var $author$project$Feature$MouseAPI$performDrag = F2(
	function (pos, model) {
		var _v0 = model.dt.c6;
		if (_v0.$ === 3) {
			var dragMode = _v0.a;
			var id = _v0.b;
			var boxPath = _v0.c;
			var origPos = _v0.d;
			var lastPos = _v0.e;
			var target = _v0.f;
			var delta = A2($author$project$ModelParts$Point, pos.d1 - lastPos.d1, pos.d3 - lastPos.d3);
			var boxId = $author$project$Box$firstId(boxPath);
			var newModel = function () {
				if (!dragMode) {
					return A4($author$project$Box$setTopicPosByDelta, id, boxId, delta, model);
				} else {
					return model;
				}
			}();
			return $author$project$Box$Size$auto(
				A2(
					$author$project$Feature$MouseAPI$setDragState,
					A6($author$project$Feature$Mouse$Drag, dragMode, id, boxPath, origPos, pos, target),
					newModel));
		} else {
			return A3(
				$author$project$Utils$logError,
				'performDrag',
				'Received \"Move\" message when dragState is ' + $author$project$Utils$toString(model.dt.c6),
				model);
		}
	});
var $author$project$Feature$MouseAPI$mouseMove = F2(
	function (pos, model) {
		var _v0 = model.dt.c6;
		switch (_v0.$) {
			case 1:
				var time = _v0.a;
				var _class = _v0.b;
				var id = _v0.c;
				var boxPath = _v0.d;
				var pos_ = _v0.e;
				return _Utils_Tuple2(
					A2(
						$author$project$Feature$MouseAPI$setDragState,
						A5($author$project$Feature$Mouse$WaitForEndTime, time, _class, id, boxPath, pos_),
						model),
					A2(
						$elm$core$Task$perform,
						A2($elm$core$Basics$composeL, $author$project$Model$Mouse, $author$project$Feature$Mouse$Time),
						$elm$time$Time$now));
			case 3:
				return _Utils_Tuple2(
					A2($author$project$Feature$MouseAPI$performDrag, pos, model),
					$elm$core$Platform$Cmd$none);
			default:
				return A3(
					$author$project$Utils$logError,
					'mouseMove',
					'Received \"Move\" message when dragState is ' + $author$project$Utils$toString(model.dt.c6),
					_Utils_Tuple2(model, $elm$core$Platform$Cmd$none));
		}
	});
var $author$project$Model$AddAssoc = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $author$project$Model$ItemClicked = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $author$project$Model$MoveTopicToBox = F6(
	function (a, b, c, d, e, f) {
		return {$: 1, a: a, b: b, c: c, d: d, e: e, f: f};
	});
var $author$project$Model$TopicDragged = {$: 2};
var $elm$random$Random$Generate = $elm$core$Basics$identity;
var $elm$random$Random$Seed = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$core$Bitwise$shiftRightZfBy = _Bitwise_shiftRightZfBy;
var $elm$random$Random$next = function (_v0) {
	var state0 = _v0.a;
	var incr = _v0.b;
	return A2($elm$random$Random$Seed, ((state0 * 1664525) + incr) >>> 0, incr);
};
var $elm$random$Random$initialSeed = function (x) {
	var _v0 = $elm$random$Random$next(
		A2($elm$random$Random$Seed, 0, 1013904223));
	var state1 = _v0.a;
	var incr = _v0.b;
	var state2 = (state1 + x) >>> 0;
	return $elm$random$Random$next(
		A2($elm$random$Random$Seed, state2, incr));
};
var $elm$time$Time$posixToMillis = function (_v0) {
	var millis = _v0;
	return millis;
};
var $elm$random$Random$init = A2(
	$elm$core$Task$andThen,
	function (time) {
		return $elm$core$Task$succeed(
			$elm$random$Random$initialSeed(
				$elm$time$Time$posixToMillis(time)));
	},
	$elm$time$Time$now);
var $elm$random$Random$step = F2(
	function (_v0, seed) {
		var generator = _v0;
		return generator(seed);
	});
var $elm$random$Random$onEffects = F3(
	function (router, commands, seed) {
		if (!commands.b) {
			return $elm$core$Task$succeed(seed);
		} else {
			var generator = commands.a;
			var rest = commands.b;
			var _v1 = A2($elm$random$Random$step, generator, seed);
			var value = _v1.a;
			var newSeed = _v1.b;
			return A2(
				$elm$core$Task$andThen,
				function (_v2) {
					return A3($elm$random$Random$onEffects, router, rest, newSeed);
				},
				A2($elm$core$Platform$sendToApp, router, value));
		}
	});
var $elm$random$Random$onSelfMsg = F3(
	function (_v0, _v1, seed) {
		return $elm$core$Task$succeed(seed);
	});
var $elm$random$Random$Generator = $elm$core$Basics$identity;
var $elm$random$Random$map = F2(
	function (func, _v0) {
		var genA = _v0;
		return function (seed0) {
			var _v1 = genA(seed0);
			var a = _v1.a;
			var seed1 = _v1.b;
			return _Utils_Tuple2(
				func(a),
				seed1);
		};
	});
var $elm$random$Random$cmdMap = F2(
	function (func, _v0) {
		var generator = _v0;
		return A2($elm$random$Random$map, func, generator);
	});
_Platform_effectManagers['Random'] = _Platform_createManager($elm$random$Random$init, $elm$random$Random$onEffects, $elm$random$Random$onSelfMsg, $elm$random$Random$cmdMap);
var $elm$random$Random$command = _Platform_leaf('Random');
var $elm$random$Random$generate = F2(
	function (tagger, generator) {
		return $elm$random$Random$command(
			A2($elm$random$Random$map, tagger, generator));
	});
var $elm$core$Bitwise$and = _Bitwise_and;
var $elm$core$Bitwise$xor = _Bitwise_xor;
var $elm$random$Random$peel = function (_v0) {
	var state = _v0.a;
	var word = (state ^ (state >>> ((state >>> 28) + 4))) * 277803737;
	return ((word >>> 22) ^ word) >>> 0;
};
var $elm$random$Random$int = F2(
	function (a, b) {
		return function (seed0) {
			var _v0 = (_Utils_cmp(a, b) < 0) ? _Utils_Tuple2(a, b) : _Utils_Tuple2(b, a);
			var lo = _v0.a;
			var hi = _v0.b;
			var range = (hi - lo) + 1;
			if (!((range - 1) & range)) {
				return _Utils_Tuple2(
					(((range - 1) & $elm$random$Random$peel(seed0)) >>> 0) + lo,
					$elm$random$Random$next(seed0));
			} else {
				var threshhold = (((-range) >>> 0) % range) >>> 0;
				var accountForBias = function (seed) {
					accountForBias:
					while (true) {
						var x = $elm$random$Random$peel(seed);
						var seedN = $elm$random$Random$next(seed);
						if (_Utils_cmp(x, threshhold) < 0) {
							var $temp$seed = seedN;
							seed = $temp$seed;
							continue accountForBias;
						} else {
							return _Utils_Tuple2((x % range) + lo, seedN);
						}
					}
				};
				return accountForBias(seed0);
			}
		};
	});
var $elm$random$Random$map2 = F3(
	function (func, _v0, _v1) {
		var genA = _v0;
		var genB = _v1;
		return function (seed0) {
			var _v2 = genA(seed0);
			var a = _v2.a;
			var seed1 = _v2.b;
			var _v3 = genB(seed1);
			var b = _v3.a;
			var seed2 = _v3.b;
			return _Utils_Tuple2(
				A2(func, a, b),
				seed2);
		};
	});
var $author$project$Config$whiteBoxRange = A2($author$project$ModelParts$Size, 250, 150);
var $author$project$Feature$MouseAPI$point = function () {
	var rw = $author$project$Config$whiteBoxRange.cN;
	var rh = $author$project$Config$whiteBoxRange.b_;
	var cy = $author$project$Config$topicH2 + $author$project$Config$whiteBoxPadding;
	var cx = $author$project$Config$topicW2 + $author$project$Config$whiteBoxPadding;
	return A3(
		$elm$random$Random$map2,
		F2(
			function (x, y) {
				return A2($author$project$ModelParts$Point, cx + x, cy + y);
			}),
		A2($elm$random$Random$int, 0, rw),
		A2($elm$random$Random$int, 0, rh));
}();
var $author$project$Feature$MouseAPI$mouseUp = function (model) {
	var cmd = function () {
		var _v0 = model.dt.c6;
		switch (_v0.$) {
			case 3:
				if (!_v0.a) {
					if (!_v0.f.$) {
						var _v1 = _v0.a;
						var id = _v0.b;
						var boxPath = _v0.c;
						var origPos = _v0.d;
						var _v2 = _v0.f.a;
						var targetId = _v2.a;
						var targetPath = _v2.b;
						var boxId = $author$project$Box$firstId(boxPath);
						var droppedOnSourceBox = _Utils_eq(boxId, targetId);
						var msg = A5($author$project$Model$MoveTopicToBox, id, boxId, origPos, targetId, targetPath);
						var _v3 = A2(
							$author$project$Utils$info,
							'mouseUp',
							'dropped ' + ($elm$core$String$fromInt(id) + (' (box ' + ($author$project$Box$fromPath(boxPath) + (') on ' + ($elm$core$String$fromInt(targetId) + (' (box ' + ($author$project$Box$fromPath(targetPath) + (') --> ' + ((!droppedOnSourceBox) ? 'move topic' : 'abort'))))))))));
						var _v4 = !droppedOnSourceBox;
						if (_v4) {
							return A2($elm$random$Random$generate, msg, $author$project$Feature$MouseAPI$point);
						} else {
							return $elm$core$Platform$Cmd$none;
						}
					} else {
						var _v5 = _v0.a;
						var _v6 = A2($author$project$Utils$info, 'mouseUp', 'topic drag ended w/o target');
						return $author$project$Utils$command($author$project$Model$TopicDragged);
					}
				} else {
					if (!_v0.f.$) {
						var _v7 = _v0.a;
						var id = _v0.b;
						var boxPath = _v0.c;
						var _v8 = _v0.f.a;
						var targetId = _v8.a;
						var targetPath = _v8.b;
						var boxId = $author$project$Box$firstId(boxPath);
						var isSameBox = _Utils_eq(
							boxId,
							$author$project$Box$firstId(targetPath));
						var _v9 = A2(
							$author$project$Utils$info,
							'mouseUp',
							'assoc drawn from ' + ($elm$core$String$fromInt(id) + (' (box ' + ($author$project$Box$fromPath(boxPath) + (') to ' + ($elm$core$String$fromInt(targetId) + (' (box ' + ($author$project$Box$fromPath(targetPath) + (') --> ' + (isSameBox ? 'create assoc' : 'abort'))))))))));
						if (isSameBox) {
							return $author$project$Utils$command(
								A3($author$project$Model$AddAssoc, id, targetId, boxId));
						} else {
							return $elm$core$Platform$Cmd$none;
						}
					} else {
						var _v11 = _v0.a;
						var _v12 = A2($author$project$Utils$info, 'mouseUp', 'assoc ended w/o target');
						return $elm$core$Platform$Cmd$none;
					}
				}
			case 1:
				var id = _v0.c;
				var boxPath = _v0.d;
				var _v13 = A2($author$project$Utils$info, 'mouseUp', 'item not moved -> ItemClicked');
				return $author$project$Utils$command(
					A2($author$project$Model$ItemClicked, id, boxPath));
			default:
				return A3(
					$author$project$Utils$logError,
					'mouseUp',
					'Received \"Up\" message when dragState is ' + $author$project$Utils$toString(model.dt.c6),
					$elm$core$Platform$Cmd$none);
		}
	}();
	return _Utils_Tuple2(
		A2(
			$author$project$Feature$MouseAPI$setDragState,
			$author$project$Feature$Mouse$NoDrag($elm$core$Maybe$Nothing),
			model),
		cmd);
};
var $author$project$Feature$Mouse$DragEngaged = F5(
	function (a, b, c, d, e) {
		return {$: 1, a: a, b: b, c: c, d: d, e: e};
	});
var $author$project$Feature$Mouse$DragTopic = 0;
var $author$project$Config$assocDelayMillis = 200;
var $author$project$Box$topicPos = F3(
	function (topicId, boxId, model) {
		var _v0 = A3($author$project$Box$topicProps, topicId, boxId, model);
		if (!_v0.$) {
			var pos = _v0.a.av;
			return $elm$core$Maybe$Just(pos);
		} else {
			return A3(
				$author$project$Utils$fail,
				'topicPos',
				{a4: boxId, bD: topicId},
				$elm$core$Maybe$Nothing);
		}
	});
var $author$project$Feature$MouseAPI$timeArrived = F2(
	function (time, undoModel) {
		var present = undoModel.aw;
		var _v0 = present.dt.c6;
		switch (_v0.$) {
			case 0:
				var _class = _v0.a;
				var id = _v0.b;
				var boxPath = _v0.c;
				var pos = _v0.d;
				var dragState = A5($author$project$Feature$Mouse$DragEngaged, time, _class, id, boxPath, pos);
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						A2($author$project$Feature$MouseAPI$setDragState, dragState, present),
						$elm$core$Platform$Cmd$none));
			case 2:
				var startTime = _v0.a;
				var _class = _v0.b;
				var id = _v0.c;
				var boxPath = _v0.d;
				var pos = _v0.e;
				var maybeOrigPos = A3(
					$author$project$Box$topicPos,
					id,
					$author$project$Box$firstId(boxPath),
					present);
				var delay = $elm$time$Time$posixToMillis(time) - $elm$time$Time$posixToMillis(startTime);
				var _v1 = function () {
					var _v2 = _Utils_cmp(delay, $author$project$Config$assocDelayMillis) > 0;
					if (_v2) {
						return _Utils_Tuple2(1, $author$project$Undo$swap);
					} else {
						return _Utils_Tuple2(0, $author$project$Undo$push);
					}
				}();
				var dragMode = _v1.a;
				var undo = _v1.b;
				var dragState = function () {
					if (_class === 'dmx-topic') {
						if (!maybeOrigPos.$) {
							var origPos = maybeOrigPos.a;
							return A6($author$project$Feature$Mouse$Drag, dragMode, id, boxPath, origPos, pos, $elm$core$Maybe$Nothing);
						} else {
							return $author$project$Feature$Mouse$NoDrag($elm$core$Maybe$Nothing);
						}
					} else {
						return $author$project$Feature$Mouse$NoDrag($elm$core$Maybe$Nothing);
					}
				}();
				return A2(
					undo,
					undoModel,
					_Utils_Tuple2(
						A2($author$project$Feature$MouseAPI$setDragState, dragState, present),
						$elm$core$Platform$Cmd$none));
			default:
				return A3(
					$author$project$Utils$logError,
					'timeArrived',
					'Received Time when dragState is not WaitFor..Time',
					_Utils_Tuple2(undoModel, $elm$core$Platform$Cmd$none));
		}
	});
var $author$project$Feature$MouseAPI$unhover = F4(
	function (_class, targetId, targetPath, model) {
		var _v0 = model.dt.c6;
		switch (_v0.$) {
			case 3:
				var dragMode = _v0.a;
				var id = _v0.b;
				var boxPath = _v0.c;
				var origPos = _v0.d;
				var lastPos = _v0.e;
				return A2(
					$author$project$Feature$MouseAPI$setDragState,
					A6($author$project$Feature$Mouse$Drag, dragMode, id, boxPath, origPos, lastPos, $elm$core$Maybe$Nothing),
					model);
			case 4:
				return A2(
					$author$project$Feature$MouseAPI$setDragState,
					$author$project$Feature$Mouse$NoDrag($elm$core$Maybe$Nothing),
					model);
			default:
				return model;
		}
	});
var $author$project$Feature$MouseAPI$update = F2(
	function (msg, undoModel) {
		var present = undoModel.aw;
		switch (msg.$) {
			case 0:
				return _Utils_Tuple2(undoModel, $author$project$Feature$MouseAPI$mouseDown);
			case 1:
				var _class = msg.a;
				var id = msg.b;
				var boxPath = msg.c;
				var pos = msg.d;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					A5($author$project$Feature$MouseAPI$mouseDownOnItem, _class, id, boxPath, pos, present));
			case 2:
				var pos = msg.a;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					A2($author$project$Feature$MouseAPI$mouseMove, pos, present));
			case 3:
				return A2(
					$author$project$Undo$swap,
					undoModel,
					$author$project$Feature$MouseAPI$mouseUp(present));
			case 4:
				var _class = msg.a;
				var id = msg.b;
				var boxPath = msg.c;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						A4($author$project$Feature$MouseAPI$hover, _class, id, boxPath, present),
						$elm$core$Platform$Cmd$none));
			case 5:
				var _class = msg.a;
				var id = msg.b;
				var boxPath = msg.c;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						A4($author$project$Feature$MouseAPI$unhover, _class, id, boxPath, present),
						$elm$core$Platform$Cmd$none));
			default:
				var time = msg.a;
				return A2($author$project$Feature$MouseAPI$timeArrived, time, undoModel);
		}
	});
var $author$project$Feature$NavAPI$boxIdFromHash = function (hash) {
	var _v0 = $elm$core$String$isEmpty(hash);
	if (_v0) {
		return $elm$core$Maybe$Nothing;
	} else {
		var _v1 = A2($elm$core$String$startsWith, '#', hash);
		if (_v1) {
			var _v2 = $elm$core$String$toInt(
				A2($elm$core$String$dropLeft, 1, hash));
			if (!_v2.$) {
				var boxId = _v2.a;
				return $elm$core$Maybe$Just(boxId);
			} else {
				return A3($author$project$Utils$logError, 'boxIdFromHash', 'not a number after hash in \"' + (hash + '\"'), $elm$core$Maybe$Nothing);
			}
		} else {
			return A3($author$project$Utils$logError, 'boxIdFromHash', '\"' + (hash + '\" is not a hash'), $elm$core$Maybe$Nothing);
		}
	}
};
var $author$project$Feature$NavAPI$setHash = _Platform_outgoingPort('setHash', $elm$json$Json$Encode$string);
var $author$project$Feature$NavAPI$pushUrl = function (boxId) {
	return $author$project$Feature$NavAPI$setHash(
		'#' + $elm$core$String$fromInt(boxId));
};
var $elm$browser$Browser$Dom$setViewportOf = _Browser_setViewportOf;
var $author$project$Feature$NavAPI$setViewport = function (model) {
	var _v0 = A2($author$project$Box$byIdOrLog, model.a4, model);
	if (!_v0.$) {
		var box = _v0.a;
		return A2(
			$elm$core$Task$attempt,
			function (result) {
				if (!result.$) {
					return $author$project$Model$NoOp;
				} else {
					var e = result.a;
					return A3(
						$author$project$Utils$logError,
						'setViewport',
						$author$project$Utils$toString(e),
						$author$project$Model$NoOp);
				}
			},
			A3($elm$browser$Browser$Dom$setViewportOf, 'main', box.aU.d1, box.aU.d3));
	} else {
		return A3($author$project$Utils$fail, 'setViewport', model.a4, $elm$core$Platform$Cmd$none);
	}
};
var $author$project$Feature$NavAPI$setFullscreenBox = F2(
	function (boxId, model) {
		var newModel = _Utils_update(
			model,
			{a4: boxId});
		return _Utils_Tuple2(
			$author$project$Box$Size$auto(newModel),
			$elm$core$Platform$Cmd$batch(
				_List_fromArray(
					[
						$author$project$Feature$NavAPI$setViewport(newModel),
						$author$project$Utils$command(
						$author$project$Model$Cancel($elm$core$Maybe$Nothing))
					])));
	});
var $author$project$Storage$storeWith = function (_v0) {
	var model = _v0.a;
	var cmd = _v0.b;
	return _Utils_Tuple2(
		model,
		$elm$core$Platform$Cmd$batch(
			_List_fromArray(
				[
					cmd,
					$author$project$Storage$storeModel(
					$author$project$Model$encode(model))
				])));
};
var $author$project$Feature$NavAPI$hashChanged = F2(
	function (hash, undoModel) {
		var present = undoModel.aw;
		var _v0 = $author$project$Feature$NavAPI$boxIdFromHash(hash);
		if (!_v0.$) {
			var boxId = _v0.a;
			return $author$project$Undo$reset(
				$author$project$Storage$storeWith(
					A2($author$project$Feature$NavAPI$setFullscreenBox, boxId, present)));
		} else {
			var _v1 = A2(
				$author$project$Utils$info,
				'hashChanged',
				'No hash -> redirect to ' + $elm$core$String$fromInt(present.a4));
			return _Utils_Tuple2(
				undoModel,
				$author$project$Feature$NavAPI$pushUrl(present.a4));
		}
	});
var $author$project$Feature$NavAPI$update = F2(
	function (msg, undoModel) {
		var present = undoModel.aw;
		var hash = msg;
		return A2($author$project$Feature$NavAPI$hashChanged, hash, undoModel);
	});
var $author$project$Feature$Search$Topics = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$core$String$toLower = _String_toLower;
var $author$project$Feature$SearchAPI$isMatch = F2(
	function (text, searchTerm) {
		return (!$elm$core$String$isEmpty(searchTerm)) && A2(
			$elm$core$String$contains,
			$elm$core$String$toLower(searchTerm),
			$elm$core$String$toLower(text));
	});
var $author$project$Feature$SearchAPI$searchTopics = function (model) {
	var topicIds = A3(
		$elm$core$Dict$foldr,
		F3(
			function (id, item, topicIdsAcc) {
				var _v0 = item.b2;
				if (!_v0.$) {
					var text = _v0.a.dX;
					var _v1 = A2($author$project$Feature$SearchAPI$isMatch, text, model.C.cH);
					if (_v1) {
						return A2($elm$core$List$cons, id, topicIdsAcc);
					} else {
						return topicIdsAcc;
					}
				} else {
					return topicIdsAcc;
				}
			}),
		_List_Nil,
		model.b7);
	return A2(
		$author$project$Feature$SearchAPI$setResult,
		A2($author$project$Feature$Search$Topics, topicIds, $elm$core$Maybe$Nothing),
		model);
};
var $author$project$Feature$SearchAPI$onInputFocused = $author$project$Feature$SearchAPI$searchTopics;
var $author$project$Feature$Search$RelTopics = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$Feature$SearchAPI$onRelTopicHovered = F2(
	function (relTopicId, model) {
		var _v0 = model.C.cw;
		if (_v0.$ === 1) {
			var relTopicIds = _v0.a;
			return $author$project$Box$Size$auto(
				A2(
					$author$project$Feature$SearchAPI$setResult,
					A2(
						$author$project$Feature$Search$RelTopics,
						relTopicIds,
						$elm$core$Maybe$Just(relTopicId)),
					model));
		} else {
			return A3($author$project$Utils$logError, 'onRelTopicHovered', 'search.result is not RelTopics', model);
		}
	});
var $author$project$Feature$SearchAPI$onRelTopicUnhovered = function (model) {
	var _v0 = model.C.cw;
	if (_v0.$ === 1) {
		var relTopicIds = _v0.a;
		return $author$project$Box$Size$auto(
			A2(
				$author$project$Feature$SearchAPI$setResult,
				A2($author$project$Feature$Search$RelTopics, relTopicIds, $elm$core$Maybe$Nothing),
				model));
	} else {
		return A3($author$project$Utils$logError, 'onRelTopicUnhovered', 'search.result is not RelTopics', model);
	}
};
var $author$project$Feature$SearchAPI$onTopicHovered = F2(
	function (topicId, model) {
		var _v0 = model.C.cw;
		if (!_v0.$) {
			var topicIds = _v0.a;
			return $author$project$Box$Size$auto(
				A2(
					$author$project$Feature$SearchAPI$setResult,
					A2(
						$author$project$Feature$Search$Topics,
						topicIds,
						$elm$core$Maybe$Just(topicId)),
					model));
		} else {
			return A3($author$project$Utils$logError, 'onTopicHovered', 'search.result is not Topics', model);
		}
	});
var $author$project$Feature$SearchAPI$onTopicUnhovered = function (model) {
	var _v0 = model.C.cw;
	if (!_v0.$) {
		var topicIds = _v0.a;
		return $author$project$Box$Size$auto(
			A2(
				$author$project$Feature$SearchAPI$setResult,
				A2($author$project$Feature$Search$Topics, topicIds, $elm$core$Maybe$Nothing),
				model));
	} else {
		return A3($author$project$Utils$logError, 'onTopicUnhovered', 'search.result is not Topics', model);
	}
};
var $author$project$Box$initItemProps_ = F3(
	function (itemId, boxId, model) {
		var _v0 = A2($author$project$Item$byId, itemId, model);
		if (!_v0.$) {
			var item = _v0.a;
			var _v1 = item.b2;
			if (!_v1.$) {
				return $author$project$ModelParts$TopicP(
					A3($author$project$Box$initTopicProps, itemId, boxId, model));
			} else {
				return $author$project$ModelParts$AssocP(
					{});
			}
		} else {
			return $author$project$ModelParts$AssocP(
				{});
		}
	});
var $author$project$Box$showItem_ = F3(
	function (itemId, boxId, model) {
		return A3(
			$author$project$Box$update,
			boxId,
			function (box) {
				return _Utils_update(
					box,
					{
						b7: A3(
							$elm$core$Dict$update,
							itemId,
							function (maybeItem) {
								if (!maybeItem.$) {
									var boxItem = maybeItem.a;
									return $elm$core$Maybe$Just(
										_Utils_update(
											boxItem,
											{
												al: function () {
													var _v1 = boxItem.al;
													if (!_v1.$) {
														return boxItem.al;
													} else {
														return $author$project$ModelParts$Visible(1);
													}
												}()
											}));
								} else {
									return $elm$core$Maybe$Nothing;
								}
							},
							box.b7)
					});
			},
			model);
	});
var $author$project$Box$revealItem = F3(
	function (itemId, boxId, model) {
		if (A3($author$project$Box$hasItem, boxId, itemId, model)) {
			var _v0 = A2(
				$author$project$Utils$info,
				'revealItem',
				$elm$core$String$fromInt(itemId) + (' is in ' + $elm$core$String$fromInt(boxId)));
			return A3($author$project$Box$showItem_, itemId, boxId, model);
		} else {
			var props = A3($author$project$Box$initItemProps_, itemId, boxId, model);
			var _v1 = A2(
				$author$project$Utils$info,
				'revealItem',
				$elm$core$String$fromInt(itemId) + (' not in ' + $elm$core$String$fromInt(boxId)));
			return A4($author$project$Box$addItem, itemId, props, boxId, model);
		}
	});
var $author$project$Feature$SearchAPI$revealRelTopic = F2(
	function (_v0, model) {
		var topicId = _v0.a;
		var assocId = _v0.b;
		var _v1 = $author$project$Feature$SelAPI$revelationBoxPath(model);
		if ((!_v1.$) && _v1.a.b) {
			var boxPath = _v1.a;
			var boxId = boxPath.a;
			return $author$project$Box$Size$auto(
				A3(
					$author$project$Feature$SelAPI$select,
					topicId,
					boxPath,
					$author$project$Feature$SearchAPI$closeMenu(
						A3(
							$author$project$Box$revealItem,
							assocId,
							boxId,
							A3($author$project$Box$revealItem, topicId, boxId, model)))));
		} else {
			return model;
		}
	});
var $author$project$Feature$SearchAPI$revealTopic = F2(
	function (topicId, model) {
		var _v0 = $author$project$Feature$SelAPI$revelationBoxPath(model);
		if ((!_v0.$) && _v0.a.b) {
			var boxPath = _v0.a;
			var boxId = boxPath.a;
			return $author$project$Box$Size$auto(
				A3(
					$author$project$Feature$SelAPI$select,
					topicId,
					boxPath,
					$author$project$Feature$SearchAPI$closeMenu(
						A3($author$project$Box$revealItem, topicId, boxId, model))));
		} else {
			return model;
		}
	});
var $author$project$Feature$SearchAPI$setTerm = F2(
	function (term, model) {
		var search = model.C;
		return _Utils_update(
			model,
			{
				C: _Utils_update(
					search,
					{cH: term})
			});
	});
var $author$project$Feature$SearchAPI$setSearchTerm = F2(
	function (term, model) {
		return $author$project$Feature$SearchAPI$searchTopics(
			A2($author$project$Feature$SearchAPI$setTerm, term, model));
	});
var $author$project$Feature$SearchAPI$update = F2(
	function (msg, undoModel) {
		var present = undoModel.aw;
		switch (msg.$) {
			case 0:
				var term = msg.a;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						A2($author$project$Feature$SearchAPI$setSearchTerm, term, present),
						$elm$core$Platform$Cmd$none));
			case 1:
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						$author$project$Feature$SearchAPI$onInputFocused(present),
						$elm$core$Platform$Cmd$none));
			case 2:
				var topicId = msg.a;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						A2($author$project$Feature$SearchAPI$onTopicHovered, topicId, present),
						$elm$core$Platform$Cmd$none));
			case 3:
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						$author$project$Feature$SearchAPI$onTopicUnhovered(present),
						$elm$core$Platform$Cmd$none));
			case 4:
				var topicId = msg.a;
				return A2(
					$author$project$Undo$push,
					undoModel,
					$author$project$Storage$store(
						A2($author$project$Feature$SearchAPI$revealTopic, topicId, present)));
			case 5:
				var relTopicId = msg.a;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						A2($author$project$Feature$SearchAPI$onRelTopicHovered, relTopicId, present),
						$elm$core$Platform$Cmd$none));
			case 6:
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						$author$project$Feature$SearchAPI$onRelTopicUnhovered(present),
						$elm$core$Platform$Cmd$none));
			case 7:
				var relTopicId = msg.a;
				return A2(
					$author$project$Undo$push,
					undoModel,
					$author$project$Storage$store(
						A2($author$project$Feature$SearchAPI$revealRelTopic, relTopicId, present)));
			default:
				var boxId = msg.a;
				return _Utils_Tuple2(
					undoModel,
					$author$project$Feature$NavAPI$pushUrl(boxId));
		}
	});
var $author$project$ModelParts$Editor = 1;
var $author$project$Feature$TextAPI$setMeasureText = F2(
	function (text_, model) {
		var text = model.dX;
		return _Utils_update(
			model,
			{
				dX: _Utils_update(
					text,
					{cc: text_})
			});
	});
var $author$project$Feature$TextAPI$measureText = F3(
	function (topicId, text, model) {
		return _Utils_Tuple2(
			A2($author$project$Feature$TextAPI$setMeasureText, text, model),
			A3($author$project$Feature$TextAPI$measureElement, 'measure', topicId, 1));
	});
var $author$project$Feature$TextAPI$setTopicText = F3(
	function (topicId, text, model) {
		return A3(
			$author$project$Item$updateTopic,
			topicId,
			function (topic) {
				return _Utils_update(
					topic,
					{dX: text});
			},
			model);
	});
var $author$project$Feature$TextAPI$insertImage = F3(
	function (topicId, imageId, model) {
		var _v0 = A2($author$project$Item$topicById, topicId, model);
		if (!_v0.$) {
			var text = _v0.a.dX;
			var image = '![image](app://image/' + ($elm$core$String$fromInt(imageId) + ')');
			var newText = _Utils_ap(text, image);
			return A3(
				$author$project$Feature$TextAPI$measureText,
				topicId,
				newText,
				A3($author$project$Feature$TextAPI$setTopicText, topicId, newText, model));
		} else {
			return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
		}
	});
var $author$project$Feature$TextAPI$onTextInput = F2(
	function (text, model) {
		var _v0 = model.dX.c7;
		if (!_v0.$) {
			var topicId = _v0.a;
			return A3($author$project$Feature$TextAPI$setTopicText, topicId, text, model);
		} else {
			return A3($author$project$Utils$logError, 'onTextInput', 'called when text.edit is NoEdit', model);
		}
	});
var $author$project$Feature$TextAPI$onTextareaInput = F2(
	function (text, model) {
		var _v0 = model.dX.c7;
		if (!_v0.$) {
			var topicId = _v0.a;
			return A3(
				$author$project$Feature$TextAPI$measureText,
				topicId,
				text,
				A3($author$project$Feature$TextAPI$setTopicText, topicId, text, model));
		} else {
			return A3(
				$author$project$Utils$logError,
				'onTextareaInput',
				'called when text.edit is NoEdit',
				_Utils_Tuple2(model, $elm$core$Platform$Cmd$none));
		}
	});
var $author$project$Item$setTopicSize = F4(
	function (topicId, sizeField, size, model) {
		return A3(
			$author$project$Item$updateTopic,
			topicId,
			function (topic) {
				var size_ = topic.bo;
				return _Utils_update(
					topic,
					{
						bo: function () {
							if (!sizeField) {
								return _Utils_update(
									size_,
									{
										d_: _Utils_update(
											size,
											{cN: size.cN - $author$project$Config$topicHeight})
									});
							} else {
								return _Utils_update(
									size_,
									{c8: size});
							}
						}()
					});
			},
			model);
	});
var $author$project$Feature$TextAPI$update = F2(
	function (msg, undoModel) {
		var present = undoModel.aw;
		switch (msg.$) {
			case 0:
				var text = msg.a;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					$author$project$Storage$store(
						A2($author$project$Feature$TextAPI$onTextInput, text, present)));
			case 1:
				var text = msg.a;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					$author$project$Storage$storeWith(
						A2($author$project$Feature$TextAPI$onTextareaInput, text, present)));
			case 2:
				var topicId = msg.a;
				var sizeField = msg.b;
				var size = msg.c;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					$author$project$Storage$store(
						$author$project$Box$Size$auto(
							A4($author$project$Item$setTopicSize, topicId, sizeField, size, present))));
			case 3:
				return A2(
					$author$project$Undo$swap,
					undoModel,
					$author$project$Feature$TextAPI$leaveEdit(present));
			default:
				var _v1 = msg.a;
				var topicId = _v1.a;
				var imageId = _v1.b;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					A3($author$project$Feature$TextAPI$insertImage, topicId, imageId, present));
		}
	});
var $author$project$Box$addBox = F2(
	function (boxId, model) {
		return _Utils_update(
			model,
			{
				bL: A3(
					$elm$core$Dict$insert,
					boxId,
					A4(
						$author$project$ModelParts$Box,
						boxId,
						A4($author$project$ModelParts$Rectangle, 0, 0, 0, 0),
						A2($author$project$ModelParts$Point, 0, 0),
						$elm$core$Dict$empty),
					model.bL)
			});
	});
var $author$project$Config$contentFontSize = 13;
var $author$project$Config$topicDetailPadding = 8;
var $author$project$Config$topicLineHeight = 1.5;
var $author$project$Config$topicDetailSize = A2(
	$author$project$ModelParts$Size,
	$author$project$Config$topicWidth - $author$project$Config$topicHeight,
	$elm$core$Basics$round(($author$project$Config$topicLineHeight * $author$project$Config$contentFontSize) + (2 * ($author$project$Config$topicDetailPadding + $author$project$Config$topicBorderWidth))));
var $author$project$Item$addTopic = F3(
	function (text, icon, model) {
		var id = model.dw;
		var topic = A4(
			$author$project$ModelParts$TopicInfo,
			id,
			icon,
			text,
			A2($author$project$ModelParts$TextSize, $author$project$Config$topicDetailSize, $author$project$Config$topicDetailSize));
		var item = A3(
			$author$project$ModelParts$Item,
			id,
			$author$project$ModelParts$Topic(topic),
			$elm$core$Set$empty);
		return _Utils_Tuple2(
			$author$project$Item$nextId(
				_Utils_update(
					model,
					{
						b7: A3($elm$core$Dict$insert, id, item, model.b7)
					})),
			id);
	});
var $elm$browser$Browser$Dom$focus = _Browser_call('focus');
var $author$project$Feature$TextAPI$focus = function (model) {
	var elemId = function () {
		var _v1 = model.dX.c7;
		if (!_v1.$) {
			var id = _v1.a;
			var boxPath = _v1.b;
			return A3($author$project$Box$elemId, 'input', id, boxPath);
		} else {
			return A3($author$project$Utils$logError, 'focus', 'called when text.edit is NoEdit', '');
		}
	}();
	return A2(
		$elm$core$Task$attempt,
		function (result) {
			if (!result.$) {
				return $author$project$Model$NoOp;
			} else {
				var e = result.a;
				return A3(
					$author$project$Utils$logError,
					'focus',
					$author$project$Utils$toString(e),
					$author$project$Model$NoOp);
			}
		},
		$elm$browser$Browser$Dom$focus(elemId));
};
var $author$project$Box$updateDisplayMode = F4(
	function (topicId, boxId, transform, model) {
		return A4(
			$author$project$Box$updateTopicProps_,
			topicId,
			boxId,
			function (props) {
				return _Utils_update(
					props,
					{
						aI: transform(props.aI)
					});
			},
			model);
	});
var $author$project$Feature$TextAPI$switchTopicDisplay = F3(
	function (topicId, boxId, model) {
		return A4(
			$author$project$Box$updateDisplayMode,
			topicId,
			boxId,
			function (displayMode) {
				if (!displayMode.$) {
					return $author$project$ModelParts$TopicD(1);
				} else {
					return displayMode;
				}
			},
			model);
	});
var $author$project$Feature$TextAPI$enterEdit = F3(
	function (topicId, boxPath, model) {
		var newModel = $author$project$Box$Size$auto(
			A3(
				$author$project$Feature$TextAPI$switchTopicDisplay,
				topicId,
				$author$project$Box$firstId(boxPath),
				A2(
					$author$project$Feature$TextAPI$setEditState,
					A2($author$project$Feature$Text$Edit, topicId, boxPath),
					model)));
		return _Utils_Tuple2(
			newModel,
			$author$project$Feature$TextAPI$focus(newModel));
	});
var $author$project$Config$initBoxIcon = $elm$core$Maybe$Just('archive');
var $author$project$Config$initBoxText = 'New Box';
var $author$project$Feature$ToolAPI$addBox = function (model) {
	var boxId = model.a4;
	var props = $author$project$ModelParts$TopicP(
		A2(
			$author$project$ModelParts$TopicProps,
			A2($author$project$Box$initTopicPos, boxId, model),
			$author$project$ModelParts$BoxD(0)));
	var _v0 = A3($author$project$Item$addTopic, $author$project$Config$initBoxText, $author$project$Config$initBoxIcon, model);
	var newModel = _v0.a;
	var topicId = _v0.b;
	return A3(
		$author$project$Feature$TextAPI$enterEdit,
		topicId,
		_List_fromArray(
			[boxId]),
		A3(
			$author$project$Feature$SelAPI$select,
			topicId,
			_List_fromArray(
				[boxId]),
			A4(
				$author$project$Box$addItem,
				topicId,
				props,
				boxId,
				A2($author$project$Box$addBox, topicId, newModel))));
};
var $author$project$Config$initTopicIcon = $elm$core$Maybe$Just('disc');
var $author$project$Config$initTopicText = 'New Topic';
var $author$project$Feature$ToolAPI$addTopic = function (model) {
	var boxId = model.a4;
	var props = $author$project$ModelParts$TopicP(
		A2(
			$author$project$ModelParts$TopicProps,
			A2($author$project$Box$initTopicPos, boxId, model),
			$author$project$ModelParts$TopicD(0)));
	var _v0 = A3($author$project$Item$addTopic, $author$project$Config$initTopicText, $author$project$Config$initTopicIcon, model);
	var newModel = _v0.a;
	var topicId = _v0.b;
	return A3(
		$author$project$Feature$TextAPI$enterEdit,
		topicId,
		_List_fromArray(
			[boxId]),
		A3(
			$author$project$Feature$SelAPI$select,
			topicId,
			_List_fromArray(
				[boxId]),
			A4($author$project$Box$addItem, topicId, props, boxId, newModel)));
};
var $author$project$Item$assocIds = F2(
	function (itemId, model) {
		var _v0 = A2($author$project$Item$byId, itemId, model);
		if (!_v0.$) {
			var item = _v0.a;
			return item.bH;
		} else {
			return $elm$core$Set$empty;
		}
	});
var $elm$core$Set$remove = F2(
	function (key, _v0) {
		var dict = _v0;
		return A2($elm$core$Dict$remove, key, dict);
	});
var $author$project$Box$deleteAssocId_ = F3(
	function (assocId, itemId, model) {
		return A3(
			$author$project$Item$update,
			itemId,
			function (item) {
				return _Utils_update(
					item,
					{
						bH: A2($elm$core$Set$remove, assocId, item.bH)
					});
			},
			model);
	});
var $author$project$Box$deleteAssocRefs_ = F2(
	function (assocId, model) {
		var _v0 = A2($author$project$Item$byId, assocId, model);
		if (!_v0.$) {
			var info = _v0.a.b2;
			if (info.$ === 1) {
				var assoc = info.a;
				return A3(
					$author$project$Box$deleteAssocId_,
					assoc.aK,
					assoc.dL,
					A3($author$project$Box$deleteAssocId_, assoc.aK, assoc.dK, model));
			} else {
				return model;
			}
		} else {
			return model;
		}
	});
var $author$project$Box$deleteItem__ = F2(
	function (itemId, model) {
		return _Utils_update(
			model,
			{
				bL: A2(
					$elm$core$Dict$map,
					F2(
						function (_v0, box) {
							return _Utils_update(
								box,
								{
									b7: A2($elm$core$Dict$remove, itemId, box.b7)
								});
						}),
					model.bL),
				b7: A2($elm$core$Dict$remove, itemId, model.b7)
			});
	});
var $elm$core$Set$foldr = F3(
	function (func, initialState, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$foldr,
			F3(
				function (key, _v1, state) {
					return A2(func, key, state);
				}),
			initialState,
			dict);
	});
var $author$project$Box$deleteItem_ = F2(
	function (itemId, model) {
		return A2(
			$author$project$Box$deleteItem__,
			itemId,
			A2(
				$author$project$Box$deleteAssocRefs_,
				itemId,
				A3(
					$elm$core$Set$foldr,
					$author$project$Box$deleteItem_,
					model,
					A2($author$project$Item$assocIds, itemId, model))));
	});
var $author$project$Box$resetAllEmptyBoxes = function (model) {
	return A3(
		$elm$core$List$foldr,
		$author$project$Box$resetEmptyBox_,
		model,
		$elm$core$Dict$keys(model.bL));
};
var $author$project$Box$deleteItem = F2(
	function (itemId, model) {
		return $author$project$Box$resetAllEmptyBoxes(
			A2($author$project$Box$deleteItem_, itemId, model));
	});
var $author$project$Feature$ToolAPI$delete = function (model) {
	var newModel = A3(
		$elm$core$List$foldr,
		F2(
			function (itemId, modelAcc) {
				return A2($author$project$Box$deleteItem, itemId, modelAcc);
			}),
		model,
		A2($elm$core$List$map, $elm$core$Tuple$first, model.ax.b7));
	return $author$project$Box$Size$auto(
		$author$project$Feature$SelAPI$clear(newModel));
};
var $author$project$Feature$ToolAPI$edit = function (model) {
	var _v0 = $author$project$Feature$SelAPI$single(model);
	if (!_v0.$) {
		var _v1 = _v0.a;
		var topicId = _v1.a;
		var boxPath = _v1.b;
		return A3($author$project$Feature$TextAPI$enterEdit, topicId, boxPath, model);
	} else {
		return A3(
			$author$project$Utils$logError,
			'edit',
			'called when there is no single selection',
			_Utils_Tuple2(model, $elm$core$Platform$Cmd$none));
	}
};
var $elm$json$Json$Encode$null = _Json_encodeNull;
var $author$project$Storage$exportJSON = _Platform_outgoingPort(
	'exportJSON',
	function ($) {
		return $elm$json$Json$Encode$null;
	});
var $author$project$Storage$importJSON = _Platform_outgoingPort(
	'importJSON',
	function ($) {
		return $elm$json$Json$Encode$null;
	});
var $author$project$Feature$TextAPI$imageFilePicker = _Platform_outgoingPort(
	'imageFilePicker',
	function ($) {
		var a = $.a;
		var b = $.b;
		return A2(
			$elm$json$Json$Encode$list,
			$elm$core$Basics$identity,
			_List_fromArray(
				[
					$elm$json$Json$Encode$int(a),
					$elm$json$Json$Encode$int(b)
				]));
	});
var $author$project$Feature$TextAPI$openImageFilePicker = F2(
	function (topicId, model) {
		var imageId = model.dw;
		return _Utils_Tuple2(
			$author$project$Item$nextId(model),
			$author$project$Feature$TextAPI$imageFilePicker(
				_Utils_Tuple2(topicId, imageId)));
	});
var $author$project$Feature$Icon$Open = 0;
var $author$project$Feature$IconAPI$openPicker = function (model) {
	var icon = model.aa;
	return _Utils_update(
		model,
		{
			aa: _Utils_update(
				icon,
				{cl: 0})
		});
};
var $author$project$Model$initTransient = function (model) {
	return _Utils_update(
		model,
		{aa: $author$project$Feature$Icon$init, dt: $author$project$Feature$Mouse$init, C: $author$project$Feature$Search$init, ax: $author$project$Feature$Sel$init, dX: $author$project$Feature$Text$init});
};
var $elm_community$undo_redo$UndoList$redo = function (_v0) {
	var past = _v0.s;
	var present = _v0.aw;
	var future = _v0.u;
	if (!future.b) {
		return A3($elm_community$undo_redo$UndoList$UndoList, past, present, future);
	} else {
		var x = future.a;
		var xs = future.b;
		return A3(
			$elm_community$undo_redo$UndoList$UndoList,
			A2($elm$core$List$cons, present, past),
			x,
			xs);
	}
};
var $author$project$Undo$redo = function (undoModel) {
	var newUndoModel = $elm_community$undo_redo$UndoList$redo(undoModel);
	var newModel = $author$project$Model$initTransient(newUndoModel.aw);
	return A2(
		$author$project$Undo$swap,
		newUndoModel,
		$author$project$Storage$store(newModel));
};
var $author$project$Feature$ToolAPI$remove = function (model) {
	var newModel = A3(
		$elm$core$List$foldr,
		F2(
			function (_v0, modelAcc) {
				var itemId = _v0.a;
				var boxPath = _v0.b;
				return A3(
					$author$project$Box$removeItem,
					itemId,
					$author$project$Box$firstId(boxPath),
					modelAcc);
			}),
		model,
		model.ax.b7);
	return $author$project$Box$Size$auto(
		$author$project$Feature$SelAPI$clear(newModel));
};
var $author$project$Box$isPinned = function (item) {
	return _Utils_eq(
		item.al,
		$author$project$ModelParts$Visible(0));
};
var $author$project$Box$Transfer$boxItems_ = F3(
	function (contentItems, targetItems, model) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (boxItem, targetItemsAcc) {
					var _v0 = A2($elm$core$Dict$get, boxItem.aK, targetItemsAcc);
					if (!_v0.$) {
						var item = _v0.a;
						if ($author$project$Box$isPinned(item)) {
							return A3($author$project$Box$removeItem_, boxItem.cX, targetItemsAcc, model);
						} else {
							var items = A3($author$project$Box$removeItem_, boxItem.aK, targetItemsAcc, model);
							var _v1 = A2($author$project$Box$byId, boxItem.aK, model);
							if (!_v1.$) {
								var box_ = _v1.a;
								return A3($author$project$Box$Transfer$boxItems_, box_.b7, items, model);
							} else {
								return items;
							}
						}
					} else {
						return targetItemsAcc;
					}
				}),
			targetItems,
			A2(
				$elm$core$List$filter,
				$author$project$Box$isVisible,
				$elm$core$Dict$values(contentItems)));
	});
var $author$project$Box$Transfer$transferContent = F4(
	function (boxId, targetBoxId, transfer, model) {
		var _v0 = A2($author$project$Box$byIdOrLog, boxId, model);
		if (!_v0.$) {
			var box_ = _v0.a;
			return A3(
				$author$project$Box$update,
				targetBoxId,
				function (targetBox) {
					return _Utils_update(
						targetBox,
						{
							b7: A3(transfer, box_.b7, targetBox.b7, model)
						});
				},
				model);
		} else {
			return model;
		}
	});
var $author$project$Box$Transfer$boxContent = F3(
	function (boxId, targetBoxId, model) {
		return A4($author$project$Box$Transfer$transferContent, boxId, targetBoxId, $author$project$Box$Transfer$boxItems_, model);
	});
var $author$project$Box$displayMode = F3(
	function (topicId, boxId, model) {
		var _v0 = A3($author$project$Box$topicProps, topicId, boxId, model);
		if (!_v0.$) {
			var props = _v0.a;
			return $elm$core$Maybe$Just(props.aI);
		} else {
			return A3(
				$author$project$Utils$fail,
				'displayMode',
				{a4: boxId, bD: topicId},
				$elm$core$Maybe$Nothing);
		}
	});
var $author$project$Box$setDisplayMode = F4(
	function (topicId, boxId, display, model) {
		return A4(
			$author$project$Box$updateDisplayMode,
			topicId,
			boxId,
			function (_v0) {
				return display;
			},
			model);
	});
var $author$project$Feature$ToolAPI$toggleDisplay = F3(
	function (topicId, boxId, model) {
		var _v0 = function () {
			var _v1 = A3($author$project$Box$displayMode, topicId, boxId, model);
			if (!_v1.$) {
				if (!_v1.a.$) {
					if (!_v1.a.a) {
						var _v2 = _v1.a.a;
						return _Utils_Tuple2(
							model,
							$elm$core$Maybe$Just(
								$author$project$ModelParts$TopicD(1)));
					} else {
						var _v3 = _v1.a.a;
						return _Utils_Tuple2(
							model,
							$elm$core$Maybe$Just(
								$author$project$ModelParts$TopicD(0)));
					}
				} else {
					switch (_v1.a.a) {
						case 0:
							var _v4 = _v1.a.a;
							return _Utils_Tuple2(
								model,
								$elm$core$Maybe$Just(
									$author$project$ModelParts$BoxD(1)));
						case 1:
							var _v5 = _v1.a.a;
							return _Utils_Tuple2(
								model,
								$elm$core$Maybe$Just(
									$author$project$ModelParts$BoxD(0)));
						default:
							var _v6 = _v1.a.a;
							return _Utils_Tuple2(
								A3($author$project$Box$Transfer$boxContent, topicId, boxId, model),
								$elm$core$Maybe$Just(
									$author$project$ModelParts$BoxD(0)));
					}
				}
			} else {
				return _Utils_Tuple2(model, $elm$core$Maybe$Nothing);
			}
		}();
		var newModel = _v0.a;
		var newDisplayMode = _v0.b;
		var _v7 = _Utils_Tuple2(newModel, newDisplayMode);
		if (!_v7.b.$) {
			var newModel_ = _v7.a;
			var displayMode = _v7.b.a;
			return $author$project$Box$Size$auto(
				A4($author$project$Box$setDisplayMode, topicId, boxId, displayMode, newModel_));
		} else {
			return model;
		}
	});
var $author$project$Item$otherPlayerId = F3(
	function (assocId, playerId, model) {
		var _v0 = A2($author$project$Item$assocById, assocId, model);
		if (!_v0.$) {
			var player1 = _v0.a.dK;
			var player2 = _v0.a.dL;
			return _Utils_eq(playerId, player1) ? player2 : (_Utils_eq(playerId, player2) ? player1 : A3(
				$author$project$Utils$logError,
				'otherPlayerId',
				$elm$core$String$fromInt(playerId) + (' is not a player in assoc ' + $elm$core$String$fromInt(assocId)),
				-1));
		} else {
			return -1;
		}
	});
var $author$project$Item$relatedItems = F2(
	function (itemId, model) {
		return A3(
			$elm$core$Set$foldr,
			F2(
				function (assocId, relItemsAcc) {
					return A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							A3($author$project$Item$otherPlayerId, assocId, itemId, model),
							assocId),
						relItemsAcc);
				}),
			_List_Nil,
			A2($author$project$Item$assocIds, itemId, model));
	});
var $author$project$Feature$SearchAPI$traverse = function (model) {
	var relTopicIds = function () {
		var _v0 = $author$project$Feature$SelAPI$single(model);
		if (!_v0.$) {
			var _v1 = _v0.a;
			var itemId = _v1.a;
			return A2($author$project$Item$relatedItems, itemId, model);
		} else {
			return _List_Nil;
		}
	}();
	return A2(
		$author$project$Feature$SearchAPI$setResult,
		A2($author$project$Feature$Search$RelTopics, relTopicIds, $elm$core$Maybe$Nothing),
		model);
};
var $author$project$Box$Transfer$targetAssocItem = F2(
	function (assocId, targetItems) {
		var _v0 = A2($elm$core$Dict$get, assocId, targetItems);
		if (!_v0.$) {
			var item = _v0.a;
			return _Utils_update(
				item,
				{
					al: $author$project$ModelParts$Visible(1)
				});
		} else {
			return A4(
				$author$project$ModelParts$BoxItem,
				assocId,
				-1,
				$author$project$ModelParts$Visible(1),
				$author$project$ModelParts$AssocP($author$project$ModelParts$AssocProps));
		}
	});
var $author$project$Box$Transfer$unboxAssoc = F2(
	function (boxItem, targetItems) {
		var assocToInsert = A2($author$project$Box$Transfer$targetAssocItem, boxItem.aK, targetItems);
		return A3($elm$core$Dict$insert, assocToInsert.aK, assocToInsert, targetItems);
	});
var $author$project$Box$Transfer$isAbort = function (item) {
	var _v0 = item.ac;
	if (!_v0.$) {
		var props = _v0.a;
		var _v1 = props.aI;
		if (_v1.$ === 1) {
			switch (_v1.a) {
				case 0:
					var _v2 = _v1.a;
					return true;
				case 1:
					var _v3 = _v1.a;
					return true;
				default:
					var _v4 = _v1.a;
					return false;
			}
		} else {
			return false;
		}
	} else {
		return false;
	}
};
var $author$project$Box$Transfer$setUnboxed = function (item) {
	return _Utils_update(
		item,
		{
			ac: function () {
				var _v0 = item.ac;
				if (!_v0.$) {
					var props = _v0.a;
					return $author$project$ModelParts$TopicP(
						_Utils_update(
							props,
							{
								aI: $author$project$ModelParts$BoxD(2)
							}));
				} else {
					var props = _v0.a;
					return $author$project$ModelParts$AssocP(props);
				}
			}()
		});
};
var $author$project$Box$Transfer$unboxTopic = F3(
	function (boxItem, targetItems, model) {
		var assocToInsert = A2($author$project$Box$Transfer$targetAssocItem, boxItem.cX, targetItems);
		var _v0 = function () {
			var _v1 = A2($elm$core$Dict$get, boxItem.aK, targetItems);
			if (!_v1.$) {
				var item = _v1.a;
				var isPinned = $author$project$Box$isVisible(item) ? 0 : 1;
				var newItem = _Utils_update(
					item,
					{
						al: $author$project$ModelParts$Visible(isPinned)
					});
				var _v2 = A2($author$project$Utils$info, 'unboxTopic', newItem);
				return _Utils_Tuple2(
					newItem,
					$author$project$Box$Transfer$isAbort(item));
			} else {
				return A2($author$project$Item$isBox, boxItem.aK, model) ? _Utils_Tuple2(
					$author$project$Box$Transfer$setUnboxed(boxItem),
					false) : _Utils_Tuple2(boxItem, false);
			}
		}();
		var topicToInsert = _v0.a;
		var abort = _v0.b;
		return _Utils_Tuple2(
			A3(
				$elm$core$Dict$insert,
				assocToInsert.aK,
				assocToInsert,
				A3($elm$core$Dict$insert, topicToInsert.aK, topicToInsert, targetItems)),
			abort);
	});
var $author$project$Box$Transfer$unboxItems_ = F3(
	function (contentItems, targetItems, model) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (boxItem, targetItemsAcc) {
					var _v0 = boxItem.ac;
					if (!_v0.$) {
						var _v1 = A3($author$project$Box$Transfer$unboxTopic, boxItem, targetItemsAcc, model);
						var items = _v1.a;
						var abort = _v1.b;
						if (abort) {
							return items;
						} else {
							var _v2 = A2($author$project$Box$byId, boxItem.aK, model);
							if (!_v2.$) {
								var box_ = _v2.a;
								return A3($author$project$Box$Transfer$unboxItems_, box_.b7, items, model);
							} else {
								return items;
							}
						}
					} else {
						return A2($author$project$Box$Transfer$unboxAssoc, boxItem, targetItemsAcc);
					}
				}),
			targetItems,
			A2(
				$elm$core$List$filter,
				$author$project$Box$isVisible,
				$elm$core$Dict$values(contentItems)));
	});
var $author$project$Box$Transfer$unboxContent = F3(
	function (boxId, targetBoxId, model) {
		return A4($author$project$Box$Transfer$transferContent, boxId, targetBoxId, $author$project$Box$Transfer$unboxItems_, model);
	});
var $author$project$Feature$ToolAPI$unbox = F3(
	function (boxId, targetBoxId, model) {
		return $author$project$Box$Size$auto(
			A4(
				$author$project$Box$setDisplayMode,
				boxId,
				targetBoxId,
				$author$project$ModelParts$BoxD(2),
				A3($author$project$Box$Transfer$unboxContent, boxId, targetBoxId, model)));
	});
var $elm_community$undo_redo$UndoList$undo = function (_v0) {
	var past = _v0.s;
	var present = _v0.aw;
	var future = _v0.u;
	if (!past.b) {
		return A3($elm_community$undo_redo$UndoList$UndoList, past, present, future);
	} else {
		var x = past.a;
		var xs = past.b;
		return A3(
			$elm_community$undo_redo$UndoList$UndoList,
			xs,
			x,
			A2($elm$core$List$cons, present, future));
	}
};
var $author$project$Undo$undo = function (undoModel) {
	var newUndoModel = $elm_community$undo_redo$UndoList$undo(undoModel);
	var newModel = $author$project$Model$initTransient(newUndoModel.aw);
	return A2(
		$author$project$Undo$swap,
		newUndoModel,
		$author$project$Storage$store(newModel));
};
var $author$project$Feature$ToolAPI$update = F2(
	function (msg, undoModel) {
		var present = undoModel.aw;
		switch (msg.$) {
			case 0:
				return _Utils_Tuple2(
					undoModel,
					$author$project$Feature$NavAPI$pushUrl($author$project$ModelParts$rootBoxId));
			case 1:
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						present,
						$author$project$Storage$importJSON(0)));
			case 2:
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						present,
						$author$project$Storage$exportJSON(0)));
			case 3:
				return A2(
					$author$project$Undo$push,
					undoModel,
					$author$project$Storage$storeWith(
						$author$project$Feature$ToolAPI$addTopic(present)));
			case 4:
				return A2(
					$author$project$Undo$push,
					undoModel,
					$author$project$Storage$storeWith(
						$author$project$Feature$ToolAPI$addBox(present)));
			case 5:
				return $author$project$Undo$undo(undoModel);
			case 6:
				return $author$project$Undo$redo(undoModel);
			case 7:
				return A2(
					$author$project$Undo$push,
					undoModel,
					$author$project$Storage$storeWith(
						$author$project$Feature$ToolAPI$edit(present)));
			case 8:
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						$author$project$Feature$IconAPI$openPicker(present),
						$elm$core$Platform$Cmd$none));
			case 9:
				return A2(
					$author$project$Undo$swap,
					undoModel,
					_Utils_Tuple2(
						$author$project$Feature$SearchAPI$traverse(present),
						$elm$core$Platform$Cmd$none));
			case 10:
				return A2(
					$author$project$Undo$push,
					undoModel,
					$author$project$Storage$store(
						$author$project$Feature$ToolAPI$delete(present)));
			case 11:
				return A2(
					$author$project$Undo$push,
					undoModel,
					$author$project$Storage$store(
						$author$project$Feature$ToolAPI$remove(present)));
			case 12:
				var boxId = msg.a;
				return _Utils_Tuple2(
					undoModel,
					$author$project$Feature$NavAPI$pushUrl(boxId));
			case 13:
				var boxId = msg.a;
				var targetBoxId = msg.b;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					$author$project$Storage$store(
						A3($author$project$Feature$ToolAPI$unbox, boxId, targetBoxId, present)));
			case 14:
				var topicId = msg.a;
				var boxId = msg.b;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					$author$project$Storage$store(
						A3($author$project$Feature$ToolAPI$toggleDisplay, topicId, boxId, present)));
			case 15:
				var topicId = msg.a;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					$author$project$Storage$storeWith(
						A2($author$project$Feature$TextAPI$openImageFilePicker, topicId, present)));
			default:
				return A2(
					$author$project$Undo$swap,
					undoModel,
					$author$project$Feature$TextAPI$leaveEdit(present));
		}
	});
var $author$project$Box$updateScrollPos = F3(
	function (boxId, transform, model) {
		return A3(
			$author$project$Box$update,
			boxId,
			function (box) {
				return _Utils_update(
					box,
					{
						aU: transform(box.aU)
					});
			},
			model);
	});
var $author$project$Main$updateScrollPos = F2(
	function (pos, model) {
		return A3(
			$author$project$Box$updateScrollPos,
			model.a4,
			function (_v0) {
				return pos;
			},
			model);
	});
var $author$project$Main$update = F2(
	function (msg, undoModel) {
		var present = undoModel.aw;
		var _v0 = function () {
			if (msg.$ === 7) {
				return msg;
			} else {
				return A2($author$project$Utils$info, 'update', msg);
			}
		}();
		switch (msg.$) {
			case 0:
				var player1 = msg.a;
				var player2 = msg.b;
				var boxId = msg.c;
				return A2(
					$author$project$Undo$push,
					undoModel,
					$author$project$Storage$store(
						A4($author$project$Main$addAssoc, player1, player2, boxId, present)));
			case 1:
				var topicId = msg.a;
				var boxId = msg.b;
				var origPos = msg.c;
				var targetId = msg.d;
				var targetPath = msg.e;
				var pos = msg.f;
				return A2(
					$author$project$Undo$push,
					undoModel,
					$author$project$Storage$store(
						A7($author$project$Main$moveTopicToBox, topicId, boxId, origPos, targetId, targetPath, pos, present)));
			case 2:
				return A2(
					$author$project$Undo$swap,
					undoModel,
					$author$project$Storage$store(present));
			case 3:
				var itemId = msg.a;
				var boxPath = msg.b;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					A3($author$project$Main$select, itemId, boxPath, present));
			case 4:
				var maybeTarget = msg.a;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					A2($author$project$Main$cancelUI, maybeTarget, present));
			case 5:
				var toolMsg = msg.a;
				return A2($author$project$Feature$ToolAPI$update, toolMsg, undoModel);
			case 6:
				var textMsg = msg.a;
				return A2($author$project$Feature$TextAPI$update, textMsg, undoModel);
			case 7:
				var mouseMsg = msg.a;
				return A2($author$project$Feature$MouseAPI$update, mouseMsg, undoModel);
			case 8:
				var searchMsg = msg.a;
				return A2($author$project$Feature$SearchAPI$update, searchMsg, undoModel);
			case 9:
				var iconMenuMsg = msg.a;
				return A2($author$project$Feature$IconAPI$update, iconMenuMsg, undoModel);
			case 10:
				var navMsg = msg.a;
				return A2($author$project$Feature$NavAPI$update, navMsg, undoModel);
			case 11:
				var pos = msg.a;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					$author$project$Storage$store(
						A2($author$project$Main$updateScrollPos, pos, present)));
			case 12:
				var _v3 = msg.a;
				var imageId = _v3.a;
				var url = _v3.b;
				return A2(
					$author$project$Undo$swap,
					undoModel,
					A3($author$project$Main$cacheImageUrl, imageId, url, present));
			default:
				return _Utils_Tuple2(undoModel, $elm$core$Platform$Cmd$none);
		}
	});
var $author$project$AppEmbed$updateWithEvidence = F2(
	function (msg, undoModel) {
		var _v0 = A2($author$project$Main$update, msg, undoModel);
		var newUndo = _v0.a;
		var cmd = _v0.b;
		return _Utils_Tuple2(
			newUndo,
			$elm$core$Platform$Cmd$batch(
				_List_fromArray(
					[
						cmd,
						A3($author$project$AppEmbed$semanticEvidence, msg, undoModel, newUndo)
					])));
	});
var $author$project$Map$Model$assocsToRender = F2(
	function (box, model) {
		return A3($author$project$Map$Model$itemsToRender, box, $author$project$Box$isAssoc, model);
	});
var $elm$html$Html$div = _VirtualDom_node('div');
var $author$project$Config$blackBoxOffset = 5;
var $author$project$Feature$SelAPI$isSelectedPath = F3(
	function (itemId, boxPath, model) {
		return A2(
			$elm$core$List$member,
			_Utils_Tuple2(itemId, boxPath),
			model.ax.b7);
	});
var $elm$virtual_dom$VirtualDom$style = _VirtualDom_style;
var $elm$html$Html$Attributes$style = $elm$virtual_dom$VirtualDom$style;
var $author$project$Map$selectionStyle = F3(
	function (topicId, boxPath, model) {
		var _v0 = A3($author$project$Feature$SelAPI$isSelectedPath, topicId, boxPath, model);
		if (_v0) {
			return _List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'box-shadow', 'gray 5px 5px 5px')
				]);
		} else {
			return _List_Nil;
		}
	});
var $author$project$Map$isTarget = F3(
	function (topicId, boxPath, target_) {
		if (!target_.$) {
			var target = target_.a;
			return _Utils_eq(
				target,
				_Utils_Tuple2(topicId, boxPath));
		} else {
			return false;
		}
	});
var $elm$core$Basics$neq = _Utils_notEqual;
var $author$project$Map$topicBorderStyle = F3(
	function (id, boxPath, model) {
		var isTarget_ = A2($author$project$Map$isTarget, id, boxPath);
		var targeted = function () {
			var _v0 = model.dt.c6;
			_v0$2:
			while (true) {
				if (_v0.$ === 3) {
					if (!_v0.a) {
						if (_v0.c.b) {
							var _v1 = _v0.a;
							var _v2 = _v0.c;
							var boxId_ = _v2.a;
							var target = _v0.f;
							return isTarget_(target) && (!_Utils_eq(boxId_, id));
						} else {
							break _v0$2;
						}
					} else {
						var _v3 = _v0.a;
						var boxPath_ = _v0.c;
						var target = _v0.f;
						return isTarget_(target) && _Utils_eq(boxPath_, boxPath);
					}
				} else {
					break _v0$2;
				}
			}
			return false;
		}();
		return _List_fromArray(
			[
				A2(
				$elm$html$Html$Attributes$style,
				'border-width',
				$elm$core$String$fromInt($author$project$Config$topicBorderWidth) + 'px'),
				A2(
				$elm$html$Html$Attributes$style,
				'border-style',
				targeted ? 'dashed' : 'solid'),
				A2($elm$html$Html$Attributes$style, 'box-sizing', 'border-box'),
				A2($elm$html$Html$Attributes$style, 'background-color', 'white')
			]);
	});
var $author$project$Config$topicRadius = 7;
var $author$project$Map$ghostTopicStyle = F3(
	function (topic, boxPath, model) {
		return _Utils_ap(
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'position', 'absolute'),
					A2(
					$elm$html$Html$Attributes$style,
					'left',
					$elm$core$String$fromInt($author$project$Config$blackBoxOffset) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'top',
					$elm$core$String$fromInt($author$project$Config$blackBoxOffset) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromInt($author$project$Config$topicSize.cN) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromInt($author$project$Config$topicSize.b_) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'border-radius',
					$elm$core$String$fromInt($author$project$Config$topicRadius) + 'px'),
					A2($elm$html$Html$Attributes$style, 'z-index', '-1')
				]),
			_Utils_ap(
				A3($author$project$Map$topicBorderStyle, topic.aK, boxPath, model),
				A3($author$project$Map$selectionStyle, topic.aK, boxPath, model)));
	});
var $author$project$Map$topicFlexboxStyle = F4(
	function (topic, props, boxPath, model) {
		var r12 = $elm$core$String$fromInt($author$project$Config$topicRadius) + 'px';
		var r34 = function () {
			var _v0 = props.aI;
			if ((_v0.$ === 1) && (_v0.a === 1)) {
				var _v1 = _v0.a;
				return '0';
			} else {
				return r12;
			}
		}();
		return _Utils_ap(
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'display', 'flex'),
					A2($elm$html$Html$Attributes$style, 'align-items', 'center'),
					A2($elm$html$Html$Attributes$style, 'gap', '8px'),
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromInt($author$project$Config$topicSize.cN) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromInt($author$project$Config$topicSize.b_) + 'px'),
					A2($elm$html$Html$Attributes$style, 'border-radius', r12 + (' ' + (r12 + (' ' + (r34 + (' ' + r34))))))
				]),
			A3($author$project$Map$topicBorderStyle, topic.aK, boxPath, model));
	});
var $author$project$Map$topicPosStyle = function (_v0) {
	var pos = _v0.av;
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$Attributes$style,
			'left',
			$elm$core$String$fromInt(pos.d1 - $author$project$Config$topicW2) + 'px'),
			A2(
			$elm$html$Html$Attributes$style,
			'top',
			$elm$core$String$fromInt(pos.d3 - $author$project$Config$topicH2) + 'px')
		]);
};
var $author$project$Map$itemCountStyle = _List_fromArray(
	[
		A2(
		$elm$html$Html$Attributes$style,
		'font-size',
		$elm$core$String$fromInt($author$project$Config$contentFontSize) + 'px'),
		A2($elm$html$Html$Attributes$style, 'position', 'absolute'),
		A2($elm$html$Html$Attributes$style, 'left', 'calc(100% + 12px)')
	]);
var $elm$virtual_dom$VirtualDom$text = _VirtualDom_text;
var $elm$html$Html$text = $elm$virtual_dom$VirtualDom$text;
var $author$project$Map$viewItemCount = F3(
	function (topicId, props, model) {
		var itemCount = function () {
			var _v0 = props.aI;
			if (!_v0.$) {
				return 0;
			} else {
				var _v1 = A2($author$project$Box$byIdOrLog, topicId, model);
				if (!_v1.$) {
					var box = _v1.a;
					return $elm$core$List$length(
						A2(
							$elm$core$List$filter,
							$author$project$Box$isVisible,
							$elm$core$Dict$values(box.b7)));
				} else {
					return 0;
				}
			}
		}();
		return _List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				$author$project$Map$itemCountStyle,
				_List_fromArray(
					[
						$elm$html$Html$text(
						$elm$core$String$fromInt(itemCount))
					]))
			]);
	});
var $author$project$Map$iconBoxStyle = function (props) {
	var r1 = $elm$core$String$fromInt($author$project$Config$topicRadius) + 'px';
	var r4 = function () {
		var _v0 = props.aI;
		if ((_v0.$ === 1) && (_v0.a === 1)) {
			var _v1 = _v0.a;
			return '0';
		} else {
			return r1;
		}
	}();
	return _List_fromArray(
		[
			A2($elm$html$Html$Attributes$style, 'flex', 'none'),
			A2(
			$elm$html$Html$Attributes$style,
			'width',
			$elm$core$String$fromInt($author$project$Config$topicSize.b_) + 'px'),
			A2(
			$elm$html$Html$Attributes$style,
			'height',
			$elm$core$String$fromInt($author$project$Config$topicSize.b_) + 'px'),
			A2($elm$html$Html$Attributes$style, 'border-radius', r1 + (' 0 0 ' + r4)),
			A2($elm$html$Html$Attributes$style, 'background-color', 'black')
		]);
};
var $author$project$Config$mainFont = 'sans-serif';
var $author$project$Config$topicLabelWeight = 'bold';
var $author$project$Map$inputStyle = _List_fromArray(
	[
		A2($elm$html$Html$Attributes$style, 'font-family', $author$project$Config$mainFont),
		A2(
		$elm$html$Html$Attributes$style,
		'font-size',
		$elm$core$String$fromInt($author$project$Config$contentFontSize) + 'px'),
		A2($elm$html$Html$Attributes$style, 'font-weight', $author$project$Config$topicLabelWeight),
		A2($elm$html$Html$Attributes$style, 'width', '100%'),
		A2($elm$html$Html$Attributes$style, 'position', 'relative'),
		A2($elm$html$Html$Attributes$style, 'left', '-4px')
	]);
var $author$project$Feature$TextAPI$isEdit = F3(
	function (topicId, boxPath, model) {
		return _Utils_eq(
			model.dX.c7,
			A2($author$project$Feature$Text$Edit, topicId, boxPath));
	});
var $author$project$Config$topicIconSize = 16;
var $author$project$Map$topicIconStyle = _List_fromArray(
	[
		A2($elm$html$Html$Attributes$style, 'position', 'relative'),
		A2(
		$elm$html$Html$Attributes$style,
		'top',
		$elm$core$String$fromInt((($author$project$Config$topicSize.b_ - $author$project$Config$topicIconSize) / 2) | 0) + 'px'),
		A2(
		$elm$html$Html$Attributes$style,
		'left',
		$elm$core$String$fromInt((($author$project$Config$topicSize.b_ - $author$project$Config$topicIconSize) / 2) | 0) + 'px'),
		A2($elm$html$Html$Attributes$style, 'color', 'white')
	]);
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$String$lines = _String_lines;
var $author$project$Item$topicLabel = function (topic) {
	var _v0 = $elm$core$List$head(
		$elm$core$String$lines(topic.dX));
	if (!_v0.$) {
		var line = _v0.a;
		return line;
	} else {
		return '';
	}
};
var $author$project$Map$topicLabelStyle = _List_fromArray(
	[
		A2(
		$elm$html$Html$Attributes$style,
		'font-size',
		$elm$core$String$fromInt($author$project$Config$contentFontSize) + 'px'),
		A2($elm$html$Html$Attributes$style, 'font-weight', $author$project$Config$topicLabelWeight),
		A2($elm$html$Html$Attributes$style, 'overflow', 'hidden'),
		A2($elm$html$Html$Attributes$style, 'text-overflow', 'ellipsis'),
		A2($elm$html$Html$Attributes$style, 'white-space', 'nowrap')
	]);
var $author$project$Feature$Text$LeaveEdit = {$: 3};
var $author$project$Feature$Text$OnTextInput = function (a) {
	return {$: 0, a: a};
};
var $elm$html$Html$Attributes$stringProperty = F2(
	function (key, string) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$string(string));
	});
var $elm$html$Html$Attributes$id = $elm$html$Html$Attributes$stringProperty('id');
var $elm$html$Html$input = _VirtualDom_node('input');
var $elm$html$Html$Events$keyCode = A2($elm$json$Json$Decode$field, 'keyCode', $elm$json$Json$Decode$int);
var $author$project$Utils$keyDecoder = F2(
	function (key, msg) {
		var isKey = function (code) {
			return _Utils_eq(code, key) ? $elm$json$Json$Decode$succeed(msg) : $elm$json$Json$Decode$fail('not that key');
		};
		return A2($elm$json$Json$Decode$andThen, isKey, $elm$html$Html$Events$keyCode);
	});
var $elm$virtual_dom$VirtualDom$Normal = function (a) {
	return {$: 0, a: a};
};
var $elm$virtual_dom$VirtualDom$on = _VirtualDom_on;
var $elm$html$Html$Events$on = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$Normal(decoder));
	});
var $author$project$Utils$onEnterOrEsc = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'keydown',
		$elm$json$Json$Decode$oneOf(
			_List_fromArray(
				[
					A2($author$project$Utils$keyDecoder, 13, msg),
					A2($author$project$Utils$keyDecoder, 27, msg)
				])));
};
var $elm$html$Html$Events$alwaysStop = function (x) {
	return _Utils_Tuple2(x, true);
};
var $elm$virtual_dom$VirtualDom$MayStopPropagation = function (a) {
	return {$: 1, a: a};
};
var $elm$html$Html$Events$stopPropagationOn = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$MayStopPropagation(decoder));
	});
var $elm$json$Json$Decode$at = F2(
	function (fields, decoder) {
		return A3($elm$core$List$foldr, $elm$json$Json$Decode$field, decoder, fields);
	});
var $elm$html$Html$Events$targetValue = A2(
	$elm$json$Json$Decode$at,
	_List_fromArray(
		['target', 'value']),
	$elm$json$Json$Decode$string);
var $elm$html$Html$Events$onInput = function (tagger) {
	return A2(
		$elm$html$Html$Events$stopPropagationOn,
		'input',
		A2(
			$elm$json$Json$Decode$map,
			$elm$html$Html$Events$alwaysStop,
			A2($elm$json$Json$Decode$map, tagger, $elm$html$Html$Events$targetValue)));
};
var $author$project$Utils$stopPropagation = F2(
	function (eventName, msg) {
		return A2(
			$elm$html$Html$Events$stopPropagationOn,
			eventName,
			$elm$json$Json$Decode$succeed(
				_Utils_Tuple2(msg, true)));
	});
var $author$project$Utils$onMouseDownStop = function (msg) {
	return A2($author$project$Utils$stopPropagation, 'mousedown', msg);
};
var $elm$html$Html$Attributes$value = $elm$html$Html$Attributes$stringProperty('value');
var $author$project$Feature$TextAPI$viewInput = F3(
	function (topic, boxPath, style) {
		return A2(
			$elm$html$Html$input,
			_Utils_ap(
				_List_fromArray(
					[
						$elm$html$Html$Attributes$id(
						A3($author$project$Box$elemId, 'input', topic.aK, boxPath)),
						$elm$html$Html$Attributes$value(topic.dX),
						$elm$html$Html$Events$onInput(
						A2($elm$core$Basics$composeL, $author$project$Model$Text, $author$project$Feature$Text$OnTextInput)),
						$author$project$Utils$onEnterOrEsc(
						$author$project$Model$Text($author$project$Feature$Text$LeaveEdit)),
						$author$project$Utils$onMouseDownStop($author$project$Model$NoOp)
					]),
				style),
			_List_Nil);
	});
var $feathericons$elm_feather$FeatherIcons$Icon = $elm$core$Basics$identity;
var $feathericons$elm_feather$FeatherIcons$defaultAttributes = function (name) {
	return {
		aG: $elm$core$Maybe$Just('feather feather-' + name),
		bo: 24,
		ay: '',
		aV: 2,
		a$: '0 0 24 24'
	};
};
var $feathericons$elm_feather$FeatherIcons$makeBuilder = F2(
	function (name, src) {
		return {
			E: $feathericons$elm_feather$FeatherIcons$defaultAttributes(name),
			bq: src
		};
	});
var $elm$svg$Svg$Attributes$points = _VirtualDom_attribute('points');
var $elm$svg$Svg$trustedNode = _VirtualDom_nodeNS('http://www.w3.org/2000/svg');
var $elm$svg$Svg$polyline = $elm$svg$Svg$trustedNode('polyline');
var $feathericons$elm_feather$FeatherIcons$activity = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'activity',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('22 12 18 12 15 21 9 3 6 12 2 12')
				]),
			_List_Nil)
		]));
var $elm$svg$Svg$Attributes$d = _VirtualDom_attribute('d');
var $elm$svg$Svg$path = $elm$svg$Svg$trustedNode('path');
var $elm$svg$Svg$polygon = $elm$svg$Svg$trustedNode('polygon');
var $feathericons$elm_feather$FeatherIcons$airplay = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'airplay',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5 17H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-1')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12 15 17 21 7 21 12 15')
				]),
			_List_Nil)
		]));
var $elm$svg$Svg$circle = $elm$svg$Svg$trustedNode('circle');
var $elm$svg$Svg$Attributes$cx = _VirtualDom_attribute('cx');
var $elm$svg$Svg$Attributes$cy = _VirtualDom_attribute('cy');
var $elm$svg$Svg$line = $elm$svg$Svg$trustedNode('line');
var $elm$svg$Svg$Attributes$r = _VirtualDom_attribute('r');
var $elm$svg$Svg$Attributes$x1 = _VirtualDom_attribute('x1');
var $elm$svg$Svg$Attributes$x2 = _VirtualDom_attribute('x2');
var $elm$svg$Svg$Attributes$y1 = _VirtualDom_attribute('y1');
var $elm$svg$Svg$Attributes$y2 = _VirtualDom_attribute('y2');
var $feathericons$elm_feather$FeatherIcons$alertCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'alert-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$alertOctagon = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'alert-octagon',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7.86 2 16.14 2 22 7.86 22 16.14 16.14 22 7.86 22 2 16.14 2 7.86 7.86 2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$alertTriangle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'alert-triangle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('13')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('17'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('17')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$alignCenter = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'align-center',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18'),
					$elm$svg$Svg$Attributes$y1('10'),
					$elm$svg$Svg$Attributes$x2('6'),
					$elm$svg$Svg$Attributes$y2('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('14'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('6'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$alignJustify = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'align-justify',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('10'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('14'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$alignLeft = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'align-left',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17'),
					$elm$svg$Svg$Attributes$y1('10'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('14'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$alignRight = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'align-right',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('10'),
					$elm$svg$Svg$Attributes$x2('7'),
					$elm$svg$Svg$Attributes$y2('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('14'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('7'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$anchor = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'anchor',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('5'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('22'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5 12H2a10 10 0 0 0 20 0h-3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$aperture = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'aperture',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('14.31'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('20.05'),
					$elm$svg$Svg$Attributes$y2('17.94')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9.69'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('21.17'),
					$elm$svg$Svg$Attributes$y2('8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('7.38'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('13.12'),
					$elm$svg$Svg$Attributes$y2('2.06')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9.69'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('3.95'),
					$elm$svg$Svg$Attributes$y2('6.06')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('14.31'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('2.83'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16.62'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('10.88'),
					$elm$svg$Svg$Attributes$y2('21.94')
				]),
			_List_Nil)
		]));
var $elm$svg$Svg$Attributes$height = _VirtualDom_attribute('height');
var $elm$svg$Svg$rect = $elm$svg$Svg$trustedNode('rect');
var $elm$svg$Svg$Attributes$width = _VirtualDom_attribute('width');
var $elm$svg$Svg$Attributes$x = _VirtualDom_attribute('x');
var $elm$svg$Svg$Attributes$y = _VirtualDom_attribute('y');
var $feathericons$elm_feather$FeatherIcons$archive = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'archive',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('21 8 21 21 3 21 3 8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('1'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('22'),
					$elm$svg$Svg$Attributes$height('5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('10'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('14'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowDown = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-down',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('5'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('19')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('19 12 12 19 5 12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowDownCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-down-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('8 12 12 16 16 12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowDownLeft = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-down-left',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17'),
					$elm$svg$Svg$Attributes$y1('7'),
					$elm$svg$Svg$Attributes$x2('7'),
					$elm$svg$Svg$Attributes$y2('17')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('17 17 7 17 7 7')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowDownRight = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-down-right',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('7'),
					$elm$svg$Svg$Attributes$y1('7'),
					$elm$svg$Svg$Attributes$x2('17'),
					$elm$svg$Svg$Attributes$y2('17')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('17 7 17 17 7 17')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowLeft = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-left',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('19'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('5'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12 19 5 12 12 5')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowLeftCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-left-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12 8 8 12 12 16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('8'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowRight = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-right',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('5'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('19'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12 5 19 12 12 19')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowRightCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-right-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12 16 16 12 12 8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowUp = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-up',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('19'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('5 12 12 5 19 12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowUpCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-up-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('16 12 12 8 8 12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('8')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowUpLeft = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-up-left',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17'),
					$elm$svg$Svg$Attributes$y1('17'),
					$elm$svg$Svg$Attributes$x2('7'),
					$elm$svg$Svg$Attributes$y2('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7 17 7 7 17 7')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$arrowUpRight = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'arrow-up-right',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('7'),
					$elm$svg$Svg$Attributes$y1('17'),
					$elm$svg$Svg$Attributes$x2('17'),
					$elm$svg$Svg$Attributes$y2('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7 7 17 7 17 17')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$atSign = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'at-sign',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-3.92 7.94')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$award = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'award',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('8'),
					$elm$svg$Svg$Attributes$r('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('8.21 13.89 7 23 12 20 17 23 15.79 13.88')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$barChart = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'bar-chart',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('18'),
					$elm$svg$Svg$Attributes$y2('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('6'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('6'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$barChart2 = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'bar-chart-2',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('18'),
					$elm$svg$Svg$Attributes$y2('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('6'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('6'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil)
		]));
var $elm$svg$Svg$Attributes$rx = _VirtualDom_attribute('rx');
var $elm$svg$Svg$Attributes$ry = _VirtualDom_attribute('ry');
var $feathericons$elm_feather$FeatherIcons$battery = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'battery',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('1'),
					$elm$svg$Svg$Attributes$y('6'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('12'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('23'),
					$elm$svg$Svg$Attributes$y1('13'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('11')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$batteryCharging = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'battery-charging',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5 18H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h3.19M15 6h2a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-3.19')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('23'),
					$elm$svg$Svg$Attributes$y1('13'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('11')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('11 6 7 12 13 12 9 18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$bell = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'bell',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M13.73 21a2 2 0 0 1-3.46 0')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$bellOff = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'bell-off',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M13.73 21a2 2 0 0 1-3.46 0')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18.63 13A17.89 17.89 0 0 1 18 8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M6.26 6.26A5.86 5.86 0 0 0 6 8c0 7-3 9-3 9h14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18 8a6 6 0 0 0-9.33-5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$bluetooth = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'bluetooth',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('6.5 6.5 17.5 17.5 12 23 12 1 17.5 6.5 6.5 17.5')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$bold = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'bold',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M6 4h8a4 4 0 0 1 4 4 4 4 0 0 1-4 4H6z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M6 12h9a4 4 0 0 1 4 4 4 4 0 0 1-4 4H6z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$book = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'book',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4 19.5A2.5 2.5 0 0 1 6.5 17H20')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$bookOpen = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'book-open',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$bookmark = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'bookmark',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$box = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'box',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('3.27 6.96 12 12.01 20.73 6.96')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('22.08'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$briefcase = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'briefcase',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('2'),
					$elm$svg$Svg$Attributes$y('7'),
					$elm$svg$Svg$Attributes$width('20'),
					$elm$svg$Svg$Attributes$height('14'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$calendar = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'calendar',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('4'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('18'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('8'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3'),
					$elm$svg$Svg$Attributes$y1('10'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('10')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$camera = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'camera',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('13'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cameraOff = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'camera-off',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 21H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h3m3-3h6l2 3h4a2 2 0 0 1 2 2v9.34m-7.72-2.06a4 4 0 1 1-5.56-5.56')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cast = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'cast',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M2 16.1A5 5 0 0 1 5.9 20M2 12.05A9 9 0 0 1 9.95 20M2 8V6a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('2'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('2.01'),
					$elm$svg$Svg$Attributes$y2('20')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$check = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'check',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('20 6 9 17 4 12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$checkCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'check-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22 11.08V12a10 10 0 1 1-5.93-9.14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('22 4 12 14.01 9 11.01')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$checkSquare = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'check-square',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('9 11 12 14 22 4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$chevronDown = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'chevron-down',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('6 9 12 15 18 9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$chevronLeft = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'chevron-left',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('15 18 9 12 15 6')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$chevronRight = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'chevron-right',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('9 18 15 12 9 6')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$chevronUp = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'chevron-up',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('18 15 12 9 6 15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$chevronsDown = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'chevrons-down',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7 13 12 18 17 13')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7 6 12 11 17 6')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$chevronsLeft = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'chevrons-left',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('11 17 6 12 11 7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('18 17 13 12 18 7')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$chevronsRight = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'chevrons-right',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('13 17 18 12 13 7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('6 17 11 12 6 7')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$chevronsUp = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'chevrons-up',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('17 11 12 6 7 11')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('17 18 12 13 7 18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$chrome = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'chrome',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21.17'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3.95'),
					$elm$svg$Svg$Attributes$y1('6.06'),
					$elm$svg$Svg$Attributes$x2('8.54'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('10.88'),
					$elm$svg$Svg$Attributes$y1('21.94'),
					$elm$svg$Svg$Attributes$x2('15.46'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$circle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$clipboard = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'clipboard',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('8'),
					$elm$svg$Svg$Attributes$y('2'),
					$elm$svg$Svg$Attributes$width('8'),
					$elm$svg$Svg$Attributes$height('4'),
					$elm$svg$Svg$Attributes$rx('1'),
					$elm$svg$Svg$Attributes$ry('1')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$clock = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'clock',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12 6 12 12 16 14')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cloud = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'cloud',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cloudDrizzle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'cloud-drizzle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('19'),
					$elm$svg$Svg$Attributes$x2('8'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('13'),
					$elm$svg$Svg$Attributes$x2('8'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('19'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('13'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('15'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('17')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20 16.58A5 5 0 0 0 18 7h-1.26A8 8 0 1 0 4 15.25')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cloudLightning = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'cloud-lightning',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M19 16.9A5 5 0 0 0 18 7h-1.26a8 8 0 1 0-11.62 9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('13 11 9 17 15 17 11 23')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cloudOff = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'cloud-off',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22.61 16.95A5 5 0 0 0 18 10h-1.26a8 8 0 0 0-7.05-6M5 5a8 8 0 0 0 4 15h9a5 5 0 0 0 1.7-.3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cloudRain = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'cloud-rain',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('13'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('13'),
					$elm$svg$Svg$Attributes$x2('8'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('15'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20 16.58A5 5 0 0 0 18 7h-1.26A8 8 0 1 0 4 15.25')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cloudSnow = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'cloud-snow',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20 17.58A5 5 0 0 0 18 8h-1.26A8 8 0 1 0 4 16.25')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('8.01'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('8.01'),
					$elm$svg$Svg$Attributes$y2('20')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('22'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('22')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('16.01'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('16.01'),
					$elm$svg$Svg$Attributes$y2('20')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$code = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'code',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('16 18 22 12 16 6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('8 6 2 12 8 18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$codepen = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'codepen',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12 2 22 8.5 22 15.5 12 22 2 15.5 2 8.5 12 2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('22'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('15.5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('22 8.5 12 15.5 2 8.5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('2 15.5 12 8.5 22 15.5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('8.5')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$codesandbox = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'codesandbox',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7.5 4.21 12 6.81 16.5 4.21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7.5 19.79 7.5 14.6 3 12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('21 12 16.5 14.6 16.5 19.79')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('3.27 6.96 12 12.01 20.73 6.96')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('22.08'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$coffee = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'coffee',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18 8h1a4 4 0 0 1 0 8h-1')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('6'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('6'),
					$elm$svg$Svg$Attributes$y2('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('10'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('10'),
					$elm$svg$Svg$Attributes$y2('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('14'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('14'),
					$elm$svg$Svg$Attributes$y2('4')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$columns = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'columns',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M12 3h7a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-7m0-18H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h7m0-18v18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$command = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'command',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18 3a3 3 0 0 0-3 3v12a3 3 0 0 0 3 3 3 3 0 0 0 3-3 3 3 0 0 0-3-3H6a3 3 0 0 0-3 3 3 3 0 0 0 3 3 3 3 0 0 0 3-3V6a3 3 0 0 0-3-3 3 3 0 0 0-3 3 3 3 0 0 0 3 3h12a3 3 0 0 0 3-3 3 3 0 0 0-3-3z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$compass = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'compass',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$copy = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'copy',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('9'),
					$elm$svg$Svg$Attributes$y('9'),
					$elm$svg$Svg$Attributes$width('13'),
					$elm$svg$Svg$Attributes$height('13'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cornerDownLeft = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'corner-down-left',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('9 10 4 15 9 20')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20 4v7a4 4 0 0 1-4 4H4')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cornerDownRight = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'corner-down-right',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('15 10 20 15 15 20')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4 4v7a4 4 0 0 0 4 4h12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cornerLeftDown = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'corner-left-down',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('14 15 9 20 4 15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20 4h-7a4 4 0 0 0-4 4v12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cornerLeftUp = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'corner-left-up',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('14 9 9 4 4 9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20 20h-7a4 4 0 0 1-4-4V4')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cornerRightDown = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'corner-right-down',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('10 15 15 20 20 15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4 4h7a4 4 0 0 1 4 4v12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cornerRightUp = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'corner-right-up',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('10 9 15 4 20 9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4 20h7a4 4 0 0 0 4-4V4')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cornerUpLeft = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'corner-up-left',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('9 14 4 9 9 4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20 20v-7a4 4 0 0 0-4-4H4')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cornerUpRight = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'corner-up-right',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('15 14 20 9 15 4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4 20v-7a4 4 0 0 1 4-4h12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$cpu = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'cpu',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('4'),
					$elm$svg$Svg$Attributes$y('4'),
					$elm$svg$Svg$Attributes$width('16'),
					$elm$svg$Svg$Attributes$height('16'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('9'),
					$elm$svg$Svg$Attributes$y('9'),
					$elm$svg$Svg$Attributes$width('6'),
					$elm$svg$Svg$Attributes$height('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('9'),
					$elm$svg$Svg$Attributes$y2('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('15'),
					$elm$svg$Svg$Attributes$y2('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('9'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('15'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('20'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('20'),
					$elm$svg$Svg$Attributes$y1('14'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('4'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('14'),
					$elm$svg$Svg$Attributes$x2('4'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$creditCard = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'credit-card',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('1'),
					$elm$svg$Svg$Attributes$y('4'),
					$elm$svg$Svg$Attributes$width('22'),
					$elm$svg$Svg$Attributes$height('16'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('10'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('10')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$crop = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'crop',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M6.13 1L6 16a2 2 0 0 0 2 2h15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M1 6.13L16 6a2 2 0 0 1 2 2v15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$crosshair = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'crosshair',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('22'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('18'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('6'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('2'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('22'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil)
		]));
var $elm$svg$Svg$ellipse = $elm$svg$Svg$trustedNode('ellipse');
var $feathericons$elm_feather$FeatherIcons$database = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'database',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$ellipse,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('5'),
					$elm$svg$Svg$Attributes$rx('9'),
					$elm$svg$Svg$Attributes$ry('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 12c0 1.66-4 3-9 3s-9-1.34-9-3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$delete = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'delete',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 4H8l-7 8 7 8h13a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('18'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$disc = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'disc',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$divide = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'divide',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('6'),
					$elm$svg$Svg$Attributes$r('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('5'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('19'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('18'),
					$elm$svg$Svg$Attributes$r('2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$divideCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'divide-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$divideSquare = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'divide-square',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('18'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('8')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$dollarSign = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'dollar-sign',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$download = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'download',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7 10 12 15 17 10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('15'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$downloadCloud = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'download-cloud',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('8 17 12 21 16 17')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20.88 18.09A5 5 0 0 0 18 9h-1.26A8 8 0 1 0 3 16.29')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$dribbble = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'dribbble',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M8.56 2.75c4.37 6.03 6.02 9.42 8.03 17.72m2.54-15.38c-3.72 4.35-8.94 5.66-16.88 5.85m19.5 1.9c-3.5-.93-6.63-.82-8.94 0-2.58.92-5.01 2.86-7.44 6.32')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$droplet = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'droplet',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$edit = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'edit',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$edit2 = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'edit-2',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$edit3 = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'edit-3',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M12 20h9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$externalLink = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'external-link',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('15 3 21 3 21 9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('10'),
					$elm$svg$Svg$Attributes$y1('14'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$eye = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'eye',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$eyeOff = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'eye-off',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$facebook = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'facebook',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$fastForward = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'fast-forward',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('13 19 22 12 13 5 13 19')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('2 19 11 12 2 5 2 19')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$feather = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'feather',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20.24 12.24a6 6 0 0 0-8.49-8.49L5 10.5V19h8.5z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('2'),
					$elm$svg$Svg$Attributes$y2('22')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17.5'),
					$elm$svg$Svg$Attributes$y1('15'),
					$elm$svg$Svg$Attributes$x2('9'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$figma = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'figma',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5 5.5A3.5 3.5 0 0 1 8.5 2H12v7H8.5A3.5 3.5 0 0 1 5 5.5z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M12 2h3.5a3.5 3.5 0 1 1 0 7H12V2z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M12 12.5a3.5 3.5 0 1 1 7 0 3.5 3.5 0 1 1-7 0z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5 19.5A3.5 3.5 0 0 1 8.5 16H12v3.5a3.5 3.5 0 1 1-7 0z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5 12.5A3.5 3.5 0 0 1 8.5 9H12v7H8.5A3.5 3.5 0 0 1 5 12.5z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$file = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'file',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('13 2 13 9 20 9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$fileMinus = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'file-minus',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('14 2 14 8 20 8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('15'),
					$elm$svg$Svg$Attributes$x2('15'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$filePlus = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'file-plus',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('14 2 14 8 20 8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('15'),
					$elm$svg$Svg$Attributes$x2('15'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$fileText = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'file-text',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('14 2 14 8 20 8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('13'),
					$elm$svg$Svg$Attributes$x2('8'),
					$elm$svg$Svg$Attributes$y2('13')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('17'),
					$elm$svg$Svg$Attributes$x2('8'),
					$elm$svg$Svg$Attributes$y2('17')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('10 9 9 9 8 9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$film = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'film',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('2'),
					$elm$svg$Svg$Attributes$y('2'),
					$elm$svg$Svg$Attributes$width('20'),
					$elm$svg$Svg$Attributes$height('20'),
					$elm$svg$Svg$Attributes$rx('2.18'),
					$elm$svg$Svg$Attributes$ry('2.18')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('7'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('7'),
					$elm$svg$Svg$Attributes$y2('22')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('17'),
					$elm$svg$Svg$Attributes$y2('22')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('2'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('22'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('2'),
					$elm$svg$Svg$Attributes$y1('7'),
					$elm$svg$Svg$Attributes$x2('7'),
					$elm$svg$Svg$Attributes$y2('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('2'),
					$elm$svg$Svg$Attributes$y1('17'),
					$elm$svg$Svg$Attributes$x2('7'),
					$elm$svg$Svg$Attributes$y2('17')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17'),
					$elm$svg$Svg$Attributes$y1('17'),
					$elm$svg$Svg$Attributes$x2('22'),
					$elm$svg$Svg$Attributes$y2('17')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17'),
					$elm$svg$Svg$Attributes$y1('7'),
					$elm$svg$Svg$Attributes$x2('22'),
					$elm$svg$Svg$Attributes$y2('7')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$filter = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'filter',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$flag = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'flag',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4'),
					$elm$svg$Svg$Attributes$y1('22'),
					$elm$svg$Svg$Attributes$x2('4'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$folder = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'folder',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$folderMinus = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'folder-minus',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('14'),
					$elm$svg$Svg$Attributes$x2('15'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$folderPlus = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'folder-plus',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('11'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('17')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('14'),
					$elm$svg$Svg$Attributes$x2('15'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$framer = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'framer',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5 16V9h14V2H5l14 14h-7m-7 0l7 7v-7m-7 0h7')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$frown = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'frown',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 16s-1.5-2-4-2-4 2-4 2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('9.01'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('15.01'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$gift = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'gift',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('20 12 20 22 4 22 4 12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('2'),
					$elm$svg$Svg$Attributes$y('7'),
					$elm$svg$Svg$Attributes$width('20'),
					$elm$svg$Svg$Attributes$height('5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('22'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$gitBranch = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'git-branch',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('6'),
					$elm$svg$Svg$Attributes$y1('3'),
					$elm$svg$Svg$Attributes$x2('6'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('18'),
					$elm$svg$Svg$Attributes$cy('6'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('6'),
					$elm$svg$Svg$Attributes$cy('18'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18 9a9 9 0 0 1-9 9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$gitCommit = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'git-commit',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1.05'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('7'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17.01'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('22.96'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$gitMerge = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'git-merge',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('18'),
					$elm$svg$Svg$Attributes$cy('18'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('6'),
					$elm$svg$Svg$Attributes$cy('6'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M6 21V9a9 9 0 0 0 9 9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$gitPullRequest = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'git-pull-request',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('18'),
					$elm$svg$Svg$Attributes$cy('18'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('6'),
					$elm$svg$Svg$Attributes$cy('6'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M13 6h3a2 2 0 0 1 2 2v7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('6'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('6'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$github = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'github',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$gitlab = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'gitlab',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22.65 14.39L12 22.13 1.35 14.39a.84.84 0 0 1-.3-.94l1.22-3.78 2.44-7.51A.42.42 0 0 1 4.82 2a.43.43 0 0 1 .58 0 .42.42 0 0 1 .11.18l2.44 7.49h8.1l2.44-7.51A.42.42 0 0 1 18.6 2a.43.43 0 0 1 .58 0 .42.42 0 0 1 .11.18l2.44 7.51L23 13.45a.84.84 0 0 1-.35.94z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$globe = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'globe',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('2'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('22'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$grid = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'grid',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('7'),
					$elm$svg$Svg$Attributes$height('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('14'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('7'),
					$elm$svg$Svg$Attributes$height('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('14'),
					$elm$svg$Svg$Attributes$y('14'),
					$elm$svg$Svg$Attributes$width('7'),
					$elm$svg$Svg$Attributes$height('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('14'),
					$elm$svg$Svg$Attributes$width('7'),
					$elm$svg$Svg$Attributes$height('7')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$hardDrive = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'hard-drive',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('22'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('2'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('6'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('6.01'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('10'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('10.01'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$hash = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'hash',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('20'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4'),
					$elm$svg$Svg$Attributes$y1('15'),
					$elm$svg$Svg$Attributes$x2('20'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('10'),
					$elm$svg$Svg$Attributes$y1('3'),
					$elm$svg$Svg$Attributes$x2('8'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('3'),
					$elm$svg$Svg$Attributes$x2('14'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$headphones = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'headphones',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M3 18v-6a9 9 0 0 1 18 0v6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$heart = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'heart',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$helpCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'help-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('17'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('17')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$hexagon = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'hexagon',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$home = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'home',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('9 22 9 12 15 12 15 22')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$image = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'image',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('18'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('8.5'),
					$elm$svg$Svg$Attributes$cy('8.5'),
					$elm$svg$Svg$Attributes$r('1.5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('21 15 16 10 5 21')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$inbox = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'inbox',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('22 12 16 12 14 15 10 15 8 12 2 12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$info = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'info',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('8')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$instagram = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'instagram',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('2'),
					$elm$svg$Svg$Attributes$y('2'),
					$elm$svg$Svg$Attributes$width('20'),
					$elm$svg$Svg$Attributes$height('20'),
					$elm$svg$Svg$Attributes$rx('5'),
					$elm$svg$Svg$Attributes$ry('5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17.5'),
					$elm$svg$Svg$Attributes$y1('6.5'),
					$elm$svg$Svg$Attributes$x2('17.51'),
					$elm$svg$Svg$Attributes$y2('6.5')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$italic = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'italic',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('19'),
					$elm$svg$Svg$Attributes$y1('4'),
					$elm$svg$Svg$Attributes$x2('10'),
					$elm$svg$Svg$Attributes$y2('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('14'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('5'),
					$elm$svg$Svg$Attributes$y2('20')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('4'),
					$elm$svg$Svg$Attributes$x2('9'),
					$elm$svg$Svg$Attributes$y2('20')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$key = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'key',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$layers = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'layers',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12 2 2 7 12 12 22 7 12 2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('2 17 12 22 22 17')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('2 12 12 17 22 12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$layout = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'layout',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('18'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('9'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$lifeBuoy = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'life-buoy',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4.93'),
					$elm$svg$Svg$Attributes$y1('4.93'),
					$elm$svg$Svg$Attributes$x2('9.17'),
					$elm$svg$Svg$Attributes$y2('9.17')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('14.83'),
					$elm$svg$Svg$Attributes$y1('14.83'),
					$elm$svg$Svg$Attributes$x2('19.07'),
					$elm$svg$Svg$Attributes$y2('19.07')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('14.83'),
					$elm$svg$Svg$Attributes$y1('9.17'),
					$elm$svg$Svg$Attributes$x2('19.07'),
					$elm$svg$Svg$Attributes$y2('4.93')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('14.83'),
					$elm$svg$Svg$Attributes$y1('9.17'),
					$elm$svg$Svg$Attributes$x2('18.36'),
					$elm$svg$Svg$Attributes$y2('5.64')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4.93'),
					$elm$svg$Svg$Attributes$y1('19.07'),
					$elm$svg$Svg$Attributes$x2('9.17'),
					$elm$svg$Svg$Attributes$y2('14.83')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$link = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'link',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$link2 = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'link-2',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M15 7h3a5 5 0 0 1 5 5 5 5 0 0 1-5 5h-3m-6 0H6a5 5 0 0 1-5-5 5 5 0 0 1 5-5h3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$linkedin = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'linkedin',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('2'),
					$elm$svg$Svg$Attributes$y('9'),
					$elm$svg$Svg$Attributes$width('4'),
					$elm$svg$Svg$Attributes$height('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('4'),
					$elm$svg$Svg$Attributes$cy('4'),
					$elm$svg$Svg$Attributes$r('2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$list = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'list',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('3.01'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('3.01'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('3.01'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$loader = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'loader',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('22')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4.93'),
					$elm$svg$Svg$Attributes$y1('4.93'),
					$elm$svg$Svg$Attributes$x2('7.76'),
					$elm$svg$Svg$Attributes$y2('7.76')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16.24'),
					$elm$svg$Svg$Attributes$y1('16.24'),
					$elm$svg$Svg$Attributes$x2('19.07'),
					$elm$svg$Svg$Attributes$y2('19.07')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('2'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('6'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('22'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4.93'),
					$elm$svg$Svg$Attributes$y1('19.07'),
					$elm$svg$Svg$Attributes$x2('7.76'),
					$elm$svg$Svg$Attributes$y2('16.24')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16.24'),
					$elm$svg$Svg$Attributes$y1('7.76'),
					$elm$svg$Svg$Attributes$x2('19.07'),
					$elm$svg$Svg$Attributes$y2('4.93')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$lock = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'lock',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('11'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('11'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M7 11V7a5 5 0 0 1 10 0v4')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$logIn = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'log-in',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('10 17 15 12 10 7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$logOut = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'log-out',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('16 17 21 12 16 7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('9'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$mail = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'mail',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('22,6 12,13 2,6')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$map = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'map',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('8'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('22')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$mapPin = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'map-pin',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('10'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$maximize = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'maximize',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$maximize2 = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'maximize-2',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('15 3 21 3 21 9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('9 21 3 21 3 15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('3'),
					$elm$svg$Svg$Attributes$x2('14'),
					$elm$svg$Svg$Attributes$y2('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('10'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$meh = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'meh',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('15'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('9.01'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('15.01'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$menu = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'menu',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$messageCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'message-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$messageSquare = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'message-square',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$mic = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'mic',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M19 10v2a7 7 0 0 1-14 0v-2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('19'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('23'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$micOff = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'mic-off',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M9 9v3a3 3 0 0 0 5.12 2.12M15 9.34V4a3 3 0 0 0-5.94-.6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M17 16.95A7 7 0 0 1 5 12v-2m14 0v2a7 7 0 0 1-.11 1.23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('19'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('23'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$minimize = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'minimize',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M8 3v3a2 2 0 0 1-2 2H3m18 0h-3a2 2 0 0 1-2-2V3m0 18v-3a2 2 0 0 1 2-2h3M3 16h3a2 2 0 0 1 2 2v3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$minimize2 = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'minimize-2',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('4 14 10 14 10 20')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('20 10 14 10 14 4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('14'),
					$elm$svg$Svg$Attributes$y1('10'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('10'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$minus = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'minus',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('5'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('19'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$minusCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'minus-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$minusSquare = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'minus-square',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('18'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$monitor = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'monitor',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('2'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('20'),
					$elm$svg$Svg$Attributes$height('14'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('17'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$moon = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'moon',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$moreHorizontal = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'more-horizontal',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('1')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('19'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('1')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('5'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('1')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$moreVertical = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'more-vertical',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('1')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('5'),
					$elm$svg$Svg$Attributes$r('1')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('19'),
					$elm$svg$Svg$Attributes$r('1')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$mousePointer = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'mouse-pointer',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M3 3l7.07 16.97 2.51-7.39 7.39-2.51L3 3z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M13 13l6 6')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$move = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'move',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('5 9 2 12 5 15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('9 5 12 2 15 5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('15 19 12 22 9 19')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('19 9 22 12 19 15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('2'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('22'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('22')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$music = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'music',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M9 18V5l12-2v13')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('6'),
					$elm$svg$Svg$Attributes$cy('18'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('18'),
					$elm$svg$Svg$Attributes$cy('16'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$navigation = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'navigation',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('3 11 22 2 13 21 11 13 3 11')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$navigation2 = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'navigation-2',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12 2 19 21 12 17 5 21 12 2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$octagon = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'octagon',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7.86 2 16.14 2 22 7.86 22 16.14 16.14 22 7.86 22 2 16.14 2 7.86 7.86 2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$package = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'package',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16.5'),
					$elm$svg$Svg$Attributes$y1('9.4'),
					$elm$svg$Svg$Attributes$x2('7.5'),
					$elm$svg$Svg$Attributes$y2('4.21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('3.27 6.96 12 12.01 20.73 6.96')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('22.08'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$paperclip = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'paperclip',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$pause = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'pause',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('6'),
					$elm$svg$Svg$Attributes$y('4'),
					$elm$svg$Svg$Attributes$width('4'),
					$elm$svg$Svg$Attributes$height('16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('14'),
					$elm$svg$Svg$Attributes$y('4'),
					$elm$svg$Svg$Attributes$width('4'),
					$elm$svg$Svg$Attributes$height('16')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$pauseCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'pause-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('10'),
					$elm$svg$Svg$Attributes$y1('15'),
					$elm$svg$Svg$Attributes$x2('10'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('14'),
					$elm$svg$Svg$Attributes$y1('15'),
					$elm$svg$Svg$Attributes$x2('14'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$penTool = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'pen-tool',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M12 19l7-7 3 3-7 7-3-3z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18 13l-1.5-7.5L2 2l3.5 14.5L13 18l5-5z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M2 2l7.586 7.586')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('11'),
					$elm$svg$Svg$Attributes$cy('11'),
					$elm$svg$Svg$Attributes$r('2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$percent = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'percent',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('19'),
					$elm$svg$Svg$Attributes$y1('5'),
					$elm$svg$Svg$Attributes$x2('5'),
					$elm$svg$Svg$Attributes$y2('19')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('6.5'),
					$elm$svg$Svg$Attributes$cy('6.5'),
					$elm$svg$Svg$Attributes$r('2.5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('17.5'),
					$elm$svg$Svg$Attributes$cy('17.5'),
					$elm$svg$Svg$Attributes$r('2.5')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$phone = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'phone',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$phoneCall = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'phone-call',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M15.05 5A5 5 0 0 1 19 8.95M15.05 1A9 9 0 0 1 23 8.94m-1 7.98v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$phoneForwarded = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'phone-forwarded',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('19 1 23 5 19 9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('5'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$phoneIncoming = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'phone-incoming',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('16 2 16 8 22 8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('23'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$phoneMissed = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'phone-missed',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('23'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('17'),
					$elm$svg$Svg$Attributes$y2('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$phoneOff = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'phone-off',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M10.68 13.31a16 16 0 0 0 3.41 2.6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7 2 2 0 0 1 1.72 2v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.42 19.42 0 0 1-3.33-2.67m-2.67-3.34a19.79 19.79 0 0 1-3.07-8.63A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('23'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('1'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$phoneOutgoing = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'phone-outgoing',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('23 7 23 1 17 1')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('16'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('1')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$pieChart = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'pie-chart',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21.21 15.89A10 10 0 1 1 8 2.83')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22 12A10 10 0 0 0 12 2v10z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$play = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'play',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('5 3 19 12 5 21 5 3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$playCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'play-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('10 8 16 12 10 16 10 8')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$plus = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'plus',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('5'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('19')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('5'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('19'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$plusCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'plus-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$plusSquare = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'plus-square',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('18'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('16'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$pocket = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'pocket',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4 3h16a2 2 0 0 1 2 2v6a10 10 0 0 1-10 10A10 10 0 0 1 2 11V5a2 2 0 0 1 2-2z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('8 10 12 14 16 10')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$power = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'power',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M18.36 6.64a9 9 0 1 1-12.73 0')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$printer = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'printer',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('6 9 6 2 18 2 18 9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('6'),
					$elm$svg$Svg$Attributes$y('14'),
					$elm$svg$Svg$Attributes$width('12'),
					$elm$svg$Svg$Attributes$height('8')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$radio = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'radio',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16.24 7.76a6 6 0 0 1 0 8.49m-8.48-.01a6 6 0 0 1 0-8.49m11.31-2.82a10 10 0 0 1 0 14.14m-14.14 0a10 10 0 0 1 0-14.14')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$refreshCcw = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'refresh-ccw',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('1 4 1 10 7 10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('23 20 23 14 17 14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$refreshCw = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'refresh-cw',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('23 4 23 10 17 10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('1 20 1 14 7 14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$repeat = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'repeat',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('17 1 21 5 17 9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M3 11V9a4 4 0 0 1 4-4h14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7 23 3 19 7 15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 13v2a4 4 0 0 1-4 4H3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$rewind = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'rewind',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('11 19 2 12 11 5 11 19')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('22 19 13 12 22 5 22 19')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$rotateCcw = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'rotate-ccw',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('1 4 1 10 7 10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M3.51 15a9 9 0 1 0 2.13-9.36L1 10')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$rotateCw = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'rotate-cw',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('23 4 23 10 17 10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20.49 15a9 9 0 1 1-2.12-9.36L23 10')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$rss = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'rss',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4 11a9 9 0 0 1 9 9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4 4a16 16 0 0 1 16 16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('5'),
					$elm$svg$Svg$Attributes$cy('19'),
					$elm$svg$Svg$Attributes$r('1')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$save = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'save',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('17 21 17 13 7 13 7 21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7 3 7 8 15 8')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$scissors = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'scissors',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('6'),
					$elm$svg$Svg$Attributes$cy('6'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('6'),
					$elm$svg$Svg$Attributes$cy('18'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('20'),
					$elm$svg$Svg$Attributes$y1('4'),
					$elm$svg$Svg$Attributes$x2('8.12'),
					$elm$svg$Svg$Attributes$y2('15.88')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('14.47'),
					$elm$svg$Svg$Attributes$y1('14.48'),
					$elm$svg$Svg$Attributes$x2('20'),
					$elm$svg$Svg$Attributes$y2('20')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8.12'),
					$elm$svg$Svg$Attributes$y1('8.12'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$search = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'search',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('11'),
					$elm$svg$Svg$Attributes$cy('11'),
					$elm$svg$Svg$Attributes$r('8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('16.65'),
					$elm$svg$Svg$Attributes$y2('16.65')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$send = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'send',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('22'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('11'),
					$elm$svg$Svg$Attributes$y2('13')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('22 2 15 22 11 13 2 9 22 2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$server = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'server',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('2'),
					$elm$svg$Svg$Attributes$y('2'),
					$elm$svg$Svg$Attributes$width('20'),
					$elm$svg$Svg$Attributes$height('8'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('2'),
					$elm$svg$Svg$Attributes$y('14'),
					$elm$svg$Svg$Attributes$width('20'),
					$elm$svg$Svg$Attributes$height('8'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('6'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('6.01'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('6'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('6.01'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$settings = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'settings',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$share = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'share',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('16 6 12 2 8 6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$share2 = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'share-2',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('18'),
					$elm$svg$Svg$Attributes$cy('5'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('6'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('18'),
					$elm$svg$Svg$Attributes$cy('19'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8.59'),
					$elm$svg$Svg$Attributes$y1('13.51'),
					$elm$svg$Svg$Attributes$x2('15.42'),
					$elm$svg$Svg$Attributes$y2('17.49')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15.41'),
					$elm$svg$Svg$Attributes$y1('6.51'),
					$elm$svg$Svg$Attributes$x2('8.59'),
					$elm$svg$Svg$Attributes$y2('10.49')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$shield = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'shield',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$shieldOff = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'shield-off',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M19.69 14a6.9 6.9 0 0 0 .31-2V5l-8-3-3.16 1.18')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M4.73 4.73L4 5v7c0 6 8 10 8 10a20.29 20.29 0 0 0 5.62-4.38')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$shoppingBag = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'shopping-bag',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('3'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 10a4 4 0 0 1-8 0')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$shoppingCart = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'shopping-cart',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('9'),
					$elm$svg$Svg$Attributes$cy('21'),
					$elm$svg$Svg$Attributes$r('1')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('20'),
					$elm$svg$Svg$Attributes$cy('21'),
					$elm$svg$Svg$Attributes$r('1')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$shuffle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'shuffle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('16 3 21 3 21 8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('21 16 21 21 16 21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('15'),
					$elm$svg$Svg$Attributes$x2('21'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4'),
					$elm$svg$Svg$Attributes$y1('4'),
					$elm$svg$Svg$Attributes$x2('9'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$sidebar = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'sidebar',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('18'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('3'),
					$elm$svg$Svg$Attributes$x2('9'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$skipBack = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'skip-back',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('19 20 9 12 19 4 19 20')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('5'),
					$elm$svg$Svg$Attributes$y1('19'),
					$elm$svg$Svg$Attributes$x2('5'),
					$elm$svg$Svg$Attributes$y2('5')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$skipForward = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'skip-forward',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('5 4 15 12 5 20 5 4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('19'),
					$elm$svg$Svg$Attributes$y1('5'),
					$elm$svg$Svg$Attributes$x2('19'),
					$elm$svg$Svg$Attributes$y2('19')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$slack = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'slack',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M14.5 10c-.83 0-1.5-.67-1.5-1.5v-5c0-.83.67-1.5 1.5-1.5s1.5.67 1.5 1.5v5c0 .83-.67 1.5-1.5 1.5z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20.5 10H19V8.5c0-.83.67-1.5 1.5-1.5s1.5.67 1.5 1.5-.67 1.5-1.5 1.5z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M9.5 14c.83 0 1.5.67 1.5 1.5v5c0 .83-.67 1.5-1.5 1.5S8 21.33 8 20.5v-5c0-.83.67-1.5 1.5-1.5z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M3.5 14H5v1.5c0 .83-.67 1.5-1.5 1.5S2 16.33 2 15.5 2.67 14 3.5 14z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M14 14.5c0-.83.67-1.5 1.5-1.5h5c.83 0 1.5.67 1.5 1.5s-.67 1.5-1.5 1.5h-5c-.83 0-1.5-.67-1.5-1.5z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M15.5 19H14v1.5c0 .83.67 1.5 1.5 1.5s1.5-.67 1.5-1.5-.67-1.5-1.5-1.5z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M10 9.5C10 8.67 9.33 8 8.5 8h-5C2.67 8 2 8.67 2 9.5S2.67 11 3.5 11h5c.83 0 1.5-.67 1.5-1.5z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M8.5 5H10V3.5C10 2.67 9.33 2 8.5 2S7 2.67 7 3.5 7.67 5 8.5 5z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$slash = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'slash',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4.93'),
					$elm$svg$Svg$Attributes$y1('4.93'),
					$elm$svg$Svg$Attributes$x2('19.07'),
					$elm$svg$Svg$Attributes$y2('19.07')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$sliders = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'sliders',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('4'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4'),
					$elm$svg$Svg$Attributes$y1('10'),
					$elm$svg$Svg$Attributes$x2('4'),
					$elm$svg$Svg$Attributes$y2('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('20'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('20'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('20'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('20'),
					$elm$svg$Svg$Attributes$y2('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('14'),
					$elm$svg$Svg$Attributes$x2('7'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('15'),
					$elm$svg$Svg$Attributes$y2('8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$smartphone = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'smartphone',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('5'),
					$elm$svg$Svg$Attributes$y('2'),
					$elm$svg$Svg$Attributes$width('14'),
					$elm$svg$Svg$Attributes$height('20'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$smile = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'smile',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M8 14s1.5 2 4 2 4-2 4-2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('9.01'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('15.01'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$speaker = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'speaker',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('4'),
					$elm$svg$Svg$Attributes$y('2'),
					$elm$svg$Svg$Attributes$width('16'),
					$elm$svg$Svg$Attributes$height('20'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('14'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('6')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$square = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'square',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('18'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$star = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'star',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$stopCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'stop-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('9'),
					$elm$svg$Svg$Attributes$y('9'),
					$elm$svg$Svg$Attributes$width('6'),
					$elm$svg$Svg$Attributes$height('6')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$sun = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'sun',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4.22'),
					$elm$svg$Svg$Attributes$y1('4.22'),
					$elm$svg$Svg$Attributes$x2('5.64'),
					$elm$svg$Svg$Attributes$y2('5.64')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18.36'),
					$elm$svg$Svg$Attributes$y1('18.36'),
					$elm$svg$Svg$Attributes$x2('19.78'),
					$elm$svg$Svg$Attributes$y2('19.78')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('12')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4.22'),
					$elm$svg$Svg$Attributes$y1('19.78'),
					$elm$svg$Svg$Attributes$x2('5.64'),
					$elm$svg$Svg$Attributes$y2('18.36')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18.36'),
					$elm$svg$Svg$Attributes$y1('5.64'),
					$elm$svg$Svg$Attributes$x2('19.78'),
					$elm$svg$Svg$Attributes$y2('4.22')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$sunrise = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'sunrise',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M17 18a5 5 0 0 0-10 0')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('2'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4.22'),
					$elm$svg$Svg$Attributes$y1('10.22'),
					$elm$svg$Svg$Attributes$x2('5.64'),
					$elm$svg$Svg$Attributes$y2('11.64')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18.36'),
					$elm$svg$Svg$Attributes$y1('11.64'),
					$elm$svg$Svg$Attributes$x2('19.78'),
					$elm$svg$Svg$Attributes$y2('10.22')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('23'),
					$elm$svg$Svg$Attributes$y1('22'),
					$elm$svg$Svg$Attributes$x2('1'),
					$elm$svg$Svg$Attributes$y2('22')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('8 6 12 2 16 6')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$sunset = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'sunset',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M17 18a5 5 0 0 0-10 0')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4.22'),
					$elm$svg$Svg$Attributes$y1('10.22'),
					$elm$svg$Svg$Attributes$x2('5.64'),
					$elm$svg$Svg$Attributes$y2('11.64')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('3'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18.36'),
					$elm$svg$Svg$Attributes$y1('11.64'),
					$elm$svg$Svg$Attributes$x2('19.78'),
					$elm$svg$Svg$Attributes$y2('10.22')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('23'),
					$elm$svg$Svg$Attributes$y1('22'),
					$elm$svg$Svg$Attributes$x2('1'),
					$elm$svg$Svg$Attributes$y2('22')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('16 5 12 9 8 5')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$tablet = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'tablet',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('4'),
					$elm$svg$Svg$Attributes$y('2'),
					$elm$svg$Svg$Attributes$width('16'),
					$elm$svg$Svg$Attributes$height('20'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('18'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$tag = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'tag',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('7'),
					$elm$svg$Svg$Attributes$y1('7'),
					$elm$svg$Svg$Attributes$x2('7.01'),
					$elm$svg$Svg$Attributes$y2('7')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$target = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'target',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$terminal = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'terminal',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('4 17 10 11 4 5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('19'),
					$elm$svg$Svg$Attributes$x2('20'),
					$elm$svg$Svg$Attributes$y2('19')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$thermometer = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'thermometer',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$thumbsDown = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'thumbs-down',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M10 15v4a3 3 0 0 0 3 3l4-9V2H5.72a2 2 0 0 0-2 1.7l-1.38 9a2 2 0 0 0 2 2.3zm7-13h2.67A2.31 2.31 0 0 1 22 4v7a2.31 2.31 0 0 1-2.33 2H17')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$thumbsUp = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'thumbs-up',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$toggleLeft = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'toggle-left',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('1'),
					$elm$svg$Svg$Attributes$y('5'),
					$elm$svg$Svg$Attributes$width('22'),
					$elm$svg$Svg$Attributes$height('14'),
					$elm$svg$Svg$Attributes$rx('7'),
					$elm$svg$Svg$Attributes$ry('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('8'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$toggleRight = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'toggle-right',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('1'),
					$elm$svg$Svg$Attributes$y('5'),
					$elm$svg$Svg$Attributes$width('22'),
					$elm$svg$Svg$Attributes$height('14'),
					$elm$svg$Svg$Attributes$rx('7'),
					$elm$svg$Svg$Attributes$ry('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('16'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('3')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$tool = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'tool',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$trash = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'trash',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('3 6 5 6 21 6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$trash2 = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'trash-2',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('3 6 5 6 21 6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('10'),
					$elm$svg$Svg$Attributes$y1('11'),
					$elm$svg$Svg$Attributes$x2('10'),
					$elm$svg$Svg$Attributes$y2('17')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('14'),
					$elm$svg$Svg$Attributes$y1('11'),
					$elm$svg$Svg$Attributes$x2('14'),
					$elm$svg$Svg$Attributes$y2('17')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$trello = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'trello',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('18'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('7'),
					$elm$svg$Svg$Attributes$y('7'),
					$elm$svg$Svg$Attributes$width('3'),
					$elm$svg$Svg$Attributes$height('9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('14'),
					$elm$svg$Svg$Attributes$y('7'),
					$elm$svg$Svg$Attributes$width('3'),
					$elm$svg$Svg$Attributes$height('5')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$trendingDown = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'trending-down',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('23 18 13.5 8.5 8.5 13.5 1 6')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('17 18 23 18 23 12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$trendingUp = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'trending-up',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('23 6 13.5 15.5 8.5 10.5 1 18')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('17 6 23 6 23 12')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$triangle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'triangle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$truck = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'truck',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('1'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('15'),
					$elm$svg$Svg$Attributes$height('13')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('16 8 20 8 23 11 23 16 16 16 16 8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('5.5'),
					$elm$svg$Svg$Attributes$cy('18.5'),
					$elm$svg$Svg$Attributes$r('2.5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('18.5'),
					$elm$svg$Svg$Attributes$cy('18.5'),
					$elm$svg$Svg$Attributes$r('2.5')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$tv = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'tv',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('2'),
					$elm$svg$Svg$Attributes$y('7'),
					$elm$svg$Svg$Attributes$width('20'),
					$elm$svg$Svg$Attributes$height('15'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('17 2 12 7 7 2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$twitch = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'twitch',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 2H3v16h5v4l4-4h5l4-4V2zm-10 9V7m5 4V7')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$twitter = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'twitter',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M23 3a10.9 10.9 0 0 1-3.14 1.53 4.48 4.48 0 0 0-7.86 3v1A10.66 10.66 0 0 1 3 4s-4 9 5 13a11.64 11.64 0 0 1-7 2c9 5 20 0 20-11.5a4.5 4.5 0 0 0-.08-.83A7.72 7.72 0 0 0 23 3z')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$type_ = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'type',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('4 7 4 4 20 4 20 7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('15'),
					$elm$svg$Svg$Attributes$y2('20')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('4'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('20')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$umbrella = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'umbrella',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M23 12a11.05 11.05 0 0 0-22 0zm-5 7a3 3 0 0 1-6 0v-7')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$underline = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'underline',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M6 3v7a6 6 0 0 0 6 6 6 6 0 0 0 6-6V3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('4'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('20'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$unlock = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'unlock',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('11'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('11'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M7 11V7a5 5 0 0 1 9.9-1')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$upload = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'upload',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('17 8 12 3 7 8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('3'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$uploadCloud = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'upload-cloud',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('16 16 12 12 8 16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('12'),
					$elm$svg$Svg$Attributes$x2('12'),
					$elm$svg$Svg$Attributes$y2('21')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20.39 18.39A5 5 0 0 0 18 9h-1.26A8 8 0 1 0 3 16.3')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('16 16 12 12 8 16')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$user = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'user',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('7'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$userCheck = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'user-check',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('8.5'),
					$elm$svg$Svg$Attributes$cy('7'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('17 11 19 13 23 9')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$userMinus = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'user-minus',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('8.5'),
					$elm$svg$Svg$Attributes$cy('7'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('23'),
					$elm$svg$Svg$Attributes$y1('11'),
					$elm$svg$Svg$Attributes$x2('17'),
					$elm$svg$Svg$Attributes$y2('11')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$userPlus = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'user-plus',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('8.5'),
					$elm$svg$Svg$Attributes$cy('7'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('20'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('20'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('23'),
					$elm$svg$Svg$Attributes$y1('11'),
					$elm$svg$Svg$Attributes$x2('17'),
					$elm$svg$Svg$Attributes$y2('11')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$userX = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'user-x',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('8.5'),
					$elm$svg$Svg$Attributes$cy('7'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('13')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('23'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('18'),
					$elm$svg$Svg$Attributes$y2('13')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$users = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'users',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('9'),
					$elm$svg$Svg$Attributes$cy('7'),
					$elm$svg$Svg$Attributes$r('4')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M23 21v-2a4 4 0 0 0-3-3.87')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 3.13a4 4 0 0 1 0 7.75')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$video = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'video',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('23 7 16 12 23 17 23 7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('1'),
					$elm$svg$Svg$Attributes$y('5'),
					$elm$svg$Svg$Attributes$width('15'),
					$elm$svg$Svg$Attributes$height('14'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$videoOff = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'video-off',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16 16v1a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h2m5.66 0H14a2 2 0 0 1 2 2v3.34l1 1L23 7v10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$voicemail = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'voicemail',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('5.5'),
					$elm$svg$Svg$Attributes$cy('11.5'),
					$elm$svg$Svg$Attributes$r('4.5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('18.5'),
					$elm$svg$Svg$Attributes$cy('11.5'),
					$elm$svg$Svg$Attributes$r('4.5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('5.5'),
					$elm$svg$Svg$Attributes$y1('16'),
					$elm$svg$Svg$Attributes$x2('18.5'),
					$elm$svg$Svg$Attributes$y2('16')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$volume = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'volume',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('11 5 6 9 2 9 2 15 6 15 11 19 11 5')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$volume1 = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'volume-1',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('11 5 6 9 2 9 2 15 6 15 11 19 11 5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M15.54 8.46a5 5 0 0 1 0 7.07')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$volume2 = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'volume-2',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('11 5 6 9 2 9 2 15 6 15 11 19 11 5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$volumeX = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'volume-x',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('11 5 6 9 2 9 2 15 6 15 11 19 11 5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('23'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('17'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('17'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$watch = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'watch',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('7')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12 9 12 12 13.5 13.5')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16.51 17.35l-.35 3.83a2 2 0 0 1-2 1.82H9.83a2 2 0 0 1-2-1.82l-.35-3.83m.01-10.7l.35-3.83A2 2 0 0 1 9.83 1h4.35a2 2 0 0 1 2 1.82l.35 3.83')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$wifi = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'wifi',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5 12.55a11 11 0 0 1 14.08 0')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M1.42 9a16 16 0 0 1 21.16 0')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M8.53 16.11a6 6 0 0 1 6.95 0')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('20')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$wifiOff = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'wifi-off',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M16.72 11.06A10.94 10.94 0 0 1 19 12.55')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M5 12.55a10.94 10.94 0 0 1 5.17-2.39')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M10.71 5.05A16 16 0 0 1 22.58 9')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M1.42 9a15.91 15.91 0 0 1 4.7-2.88')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M8.53 16.11a6 6 0 0 1 6.95 0')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('12'),
					$elm$svg$Svg$Attributes$y1('20'),
					$elm$svg$Svg$Attributes$x2('12.01'),
					$elm$svg$Svg$Attributes$y2('20')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$wind = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'wind',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M9.59 4.59A2 2 0 1 1 11 8H2m10.59 11.41A2 2 0 1 0 14 16H2m15.73-8.27A2.5 2.5 0 1 1 19.5 12H2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$x = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'x',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('18'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('6'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('6'),
					$elm$svg$Svg$Attributes$y1('6'),
					$elm$svg$Svg$Attributes$x2('18'),
					$elm$svg$Svg$Attributes$y2('18')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$xCircle = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'x-circle',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('12'),
					$elm$svg$Svg$Attributes$cy('12'),
					$elm$svg$Svg$Attributes$r('10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('9'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('15'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$xOctagon = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'x-octagon',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('7.86 2 16.14 2 22 7.86 22 16.14 16.14 22 7.86 22 2 16.14 2 7.86 7.86 2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('9'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('15'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$xSquare = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'x-square',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x('3'),
					$elm$svg$Svg$Attributes$y('3'),
					$elm$svg$Svg$Attributes$width('18'),
					$elm$svg$Svg$Attributes$height('18'),
					$elm$svg$Svg$Attributes$rx('2'),
					$elm$svg$Svg$Attributes$ry('2')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('9'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('15'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('15'),
					$elm$svg$Svg$Attributes$y1('9'),
					$elm$svg$Svg$Attributes$x2('9'),
					$elm$svg$Svg$Attributes$y2('15')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$youtube = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'youtube',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$path,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$d('M22.54 6.42a2.78 2.78 0 0 0-1.94-2C18.88 4 12 4 12 4s-6.88 0-8.6.46a2.78 2.78 0 0 0-1.94 2A29 29 0 0 0 1 11.75a29 29 0 0 0 .46 5.33A2.78 2.78 0 0 0 3.4 19c1.72.46 8.6.46 8.6.46s6.88 0 8.6-.46a2.78 2.78 0 0 0 1.94-2 29 29 0 0 0 .46-5.25 29 29 0 0 0-.46-5.33z')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('9.75 15.02 15.5 11.75 9.75 8.48 9.75 15.02')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$zap = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'zap',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('13 2 3 14 12 14 11 22 21 10 12 10 13 2')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$zapOff = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'zap-off',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('12.41 6.75 13 2 10.57 4.92')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('18.57 12.91 21 10 15.66 10')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polyline,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('8 8 3 14 12 14 11 22 16 16')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('1'),
					$elm$svg$Svg$Attributes$y1('1'),
					$elm$svg$Svg$Attributes$x2('23'),
					$elm$svg$Svg$Attributes$y2('23')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$zoomIn = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'zoom-in',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('11'),
					$elm$svg$Svg$Attributes$cy('11'),
					$elm$svg$Svg$Attributes$r('8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('16.65'),
					$elm$svg$Svg$Attributes$y2('16.65')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('11'),
					$elm$svg$Svg$Attributes$y1('8'),
					$elm$svg$Svg$Attributes$x2('11'),
					$elm$svg$Svg$Attributes$y2('14')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('11'),
					$elm$svg$Svg$Attributes$x2('14'),
					$elm$svg$Svg$Attributes$y2('11')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$zoomOut = A2(
	$feathericons$elm_feather$FeatherIcons$makeBuilder,
	'zoom-out',
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('11'),
					$elm$svg$Svg$Attributes$cy('11'),
					$elm$svg$Svg$Attributes$r('8')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('21'),
					$elm$svg$Svg$Attributes$y1('21'),
					$elm$svg$Svg$Attributes$x2('16.65'),
					$elm$svg$Svg$Attributes$y2('16.65')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('8'),
					$elm$svg$Svg$Attributes$y1('11'),
					$elm$svg$Svg$Attributes$x2('14'),
					$elm$svg$Svg$Attributes$y2('11')
				]),
			_List_Nil)
		]));
var $feathericons$elm_feather$FeatherIcons$icons = $elm$core$Dict$fromList(
	_List_fromArray(
		[
			_Utils_Tuple2('activity', $feathericons$elm_feather$FeatherIcons$activity),
			_Utils_Tuple2('airplay', $feathericons$elm_feather$FeatherIcons$airplay),
			_Utils_Tuple2('alert-circle', $feathericons$elm_feather$FeatherIcons$alertCircle),
			_Utils_Tuple2('alert-octagon', $feathericons$elm_feather$FeatherIcons$alertOctagon),
			_Utils_Tuple2('alert-triangle', $feathericons$elm_feather$FeatherIcons$alertTriangle),
			_Utils_Tuple2('align-center', $feathericons$elm_feather$FeatherIcons$alignCenter),
			_Utils_Tuple2('align-justify', $feathericons$elm_feather$FeatherIcons$alignJustify),
			_Utils_Tuple2('align-left', $feathericons$elm_feather$FeatherIcons$alignLeft),
			_Utils_Tuple2('align-right', $feathericons$elm_feather$FeatherIcons$alignRight),
			_Utils_Tuple2('anchor', $feathericons$elm_feather$FeatherIcons$anchor),
			_Utils_Tuple2('aperture', $feathericons$elm_feather$FeatherIcons$aperture),
			_Utils_Tuple2('archive', $feathericons$elm_feather$FeatherIcons$archive),
			_Utils_Tuple2('arrow-down-circle', $feathericons$elm_feather$FeatherIcons$arrowDownCircle),
			_Utils_Tuple2('arrow-down-left', $feathericons$elm_feather$FeatherIcons$arrowDownLeft),
			_Utils_Tuple2('arrow-down-right', $feathericons$elm_feather$FeatherIcons$arrowDownRight),
			_Utils_Tuple2('arrow-down', $feathericons$elm_feather$FeatherIcons$arrowDown),
			_Utils_Tuple2('arrow-left-circle', $feathericons$elm_feather$FeatherIcons$arrowLeftCircle),
			_Utils_Tuple2('arrow-left', $feathericons$elm_feather$FeatherIcons$arrowLeft),
			_Utils_Tuple2('arrow-right-circle', $feathericons$elm_feather$FeatherIcons$arrowRightCircle),
			_Utils_Tuple2('arrow-right', $feathericons$elm_feather$FeatherIcons$arrowRight),
			_Utils_Tuple2('arrow-up-circle', $feathericons$elm_feather$FeatherIcons$arrowUpCircle),
			_Utils_Tuple2('arrow-up-left', $feathericons$elm_feather$FeatherIcons$arrowUpLeft),
			_Utils_Tuple2('arrow-up-right', $feathericons$elm_feather$FeatherIcons$arrowUpRight),
			_Utils_Tuple2('arrow-up', $feathericons$elm_feather$FeatherIcons$arrowUp),
			_Utils_Tuple2('at-sign', $feathericons$elm_feather$FeatherIcons$atSign),
			_Utils_Tuple2('award', $feathericons$elm_feather$FeatherIcons$award),
			_Utils_Tuple2('bar-chart-2', $feathericons$elm_feather$FeatherIcons$barChart2),
			_Utils_Tuple2('bar-chart', $feathericons$elm_feather$FeatherIcons$barChart),
			_Utils_Tuple2('battery-charging', $feathericons$elm_feather$FeatherIcons$batteryCharging),
			_Utils_Tuple2('battery', $feathericons$elm_feather$FeatherIcons$battery),
			_Utils_Tuple2('bell-off', $feathericons$elm_feather$FeatherIcons$bellOff),
			_Utils_Tuple2('bell', $feathericons$elm_feather$FeatherIcons$bell),
			_Utils_Tuple2('bluetooth', $feathericons$elm_feather$FeatherIcons$bluetooth),
			_Utils_Tuple2('bold', $feathericons$elm_feather$FeatherIcons$bold),
			_Utils_Tuple2('book-open', $feathericons$elm_feather$FeatherIcons$bookOpen),
			_Utils_Tuple2('book', $feathericons$elm_feather$FeatherIcons$book),
			_Utils_Tuple2('bookmark', $feathericons$elm_feather$FeatherIcons$bookmark),
			_Utils_Tuple2('box', $feathericons$elm_feather$FeatherIcons$box),
			_Utils_Tuple2('briefcase', $feathericons$elm_feather$FeatherIcons$briefcase),
			_Utils_Tuple2('calendar', $feathericons$elm_feather$FeatherIcons$calendar),
			_Utils_Tuple2('camera-off', $feathericons$elm_feather$FeatherIcons$cameraOff),
			_Utils_Tuple2('camera', $feathericons$elm_feather$FeatherIcons$camera),
			_Utils_Tuple2('cast', $feathericons$elm_feather$FeatherIcons$cast),
			_Utils_Tuple2('check-circle', $feathericons$elm_feather$FeatherIcons$checkCircle),
			_Utils_Tuple2('check-square', $feathericons$elm_feather$FeatherIcons$checkSquare),
			_Utils_Tuple2('check', $feathericons$elm_feather$FeatherIcons$check),
			_Utils_Tuple2('chevron-down', $feathericons$elm_feather$FeatherIcons$chevronDown),
			_Utils_Tuple2('chevron-left', $feathericons$elm_feather$FeatherIcons$chevronLeft),
			_Utils_Tuple2('chevron-right', $feathericons$elm_feather$FeatherIcons$chevronRight),
			_Utils_Tuple2('chevron-up', $feathericons$elm_feather$FeatherIcons$chevronUp),
			_Utils_Tuple2('chevrons-down', $feathericons$elm_feather$FeatherIcons$chevronsDown),
			_Utils_Tuple2('chevrons-left', $feathericons$elm_feather$FeatherIcons$chevronsLeft),
			_Utils_Tuple2('chevrons-right', $feathericons$elm_feather$FeatherIcons$chevronsRight),
			_Utils_Tuple2('chevrons-up', $feathericons$elm_feather$FeatherIcons$chevronsUp),
			_Utils_Tuple2('chrome', $feathericons$elm_feather$FeatherIcons$chrome),
			_Utils_Tuple2('circle', $feathericons$elm_feather$FeatherIcons$circle),
			_Utils_Tuple2('clipboard', $feathericons$elm_feather$FeatherIcons$clipboard),
			_Utils_Tuple2('clock', $feathericons$elm_feather$FeatherIcons$clock),
			_Utils_Tuple2('cloud-drizzle', $feathericons$elm_feather$FeatherIcons$cloudDrizzle),
			_Utils_Tuple2('cloud-lightning', $feathericons$elm_feather$FeatherIcons$cloudLightning),
			_Utils_Tuple2('cloud-off', $feathericons$elm_feather$FeatherIcons$cloudOff),
			_Utils_Tuple2('cloud-rain', $feathericons$elm_feather$FeatherIcons$cloudRain),
			_Utils_Tuple2('cloud-snow', $feathericons$elm_feather$FeatherIcons$cloudSnow),
			_Utils_Tuple2('cloud', $feathericons$elm_feather$FeatherIcons$cloud),
			_Utils_Tuple2('code', $feathericons$elm_feather$FeatherIcons$code),
			_Utils_Tuple2('codepen', $feathericons$elm_feather$FeatherIcons$codepen),
			_Utils_Tuple2('codesandbox', $feathericons$elm_feather$FeatherIcons$codesandbox),
			_Utils_Tuple2('coffee', $feathericons$elm_feather$FeatherIcons$coffee),
			_Utils_Tuple2('columns', $feathericons$elm_feather$FeatherIcons$columns),
			_Utils_Tuple2('command', $feathericons$elm_feather$FeatherIcons$command),
			_Utils_Tuple2('compass', $feathericons$elm_feather$FeatherIcons$compass),
			_Utils_Tuple2('copy', $feathericons$elm_feather$FeatherIcons$copy),
			_Utils_Tuple2('corner-down-left', $feathericons$elm_feather$FeatherIcons$cornerDownLeft),
			_Utils_Tuple2('corner-down-right', $feathericons$elm_feather$FeatherIcons$cornerDownRight),
			_Utils_Tuple2('corner-left-down', $feathericons$elm_feather$FeatherIcons$cornerLeftDown),
			_Utils_Tuple2('corner-left-up', $feathericons$elm_feather$FeatherIcons$cornerLeftUp),
			_Utils_Tuple2('corner-right-down', $feathericons$elm_feather$FeatherIcons$cornerRightDown),
			_Utils_Tuple2('corner-right-up', $feathericons$elm_feather$FeatherIcons$cornerRightUp),
			_Utils_Tuple2('corner-up-left', $feathericons$elm_feather$FeatherIcons$cornerUpLeft),
			_Utils_Tuple2('corner-up-right', $feathericons$elm_feather$FeatherIcons$cornerUpRight),
			_Utils_Tuple2('cpu', $feathericons$elm_feather$FeatherIcons$cpu),
			_Utils_Tuple2('credit-card', $feathericons$elm_feather$FeatherIcons$creditCard),
			_Utils_Tuple2('crop', $feathericons$elm_feather$FeatherIcons$crop),
			_Utils_Tuple2('crosshair', $feathericons$elm_feather$FeatherIcons$crosshair),
			_Utils_Tuple2('database', $feathericons$elm_feather$FeatherIcons$database),
			_Utils_Tuple2('delete', $feathericons$elm_feather$FeatherIcons$delete),
			_Utils_Tuple2('disc', $feathericons$elm_feather$FeatherIcons$disc),
			_Utils_Tuple2('divide-circle', $feathericons$elm_feather$FeatherIcons$divideCircle),
			_Utils_Tuple2('divide-square', $feathericons$elm_feather$FeatherIcons$divideSquare),
			_Utils_Tuple2('divide', $feathericons$elm_feather$FeatherIcons$divide),
			_Utils_Tuple2('dollar-sign', $feathericons$elm_feather$FeatherIcons$dollarSign),
			_Utils_Tuple2('download-cloud', $feathericons$elm_feather$FeatherIcons$downloadCloud),
			_Utils_Tuple2('download', $feathericons$elm_feather$FeatherIcons$download),
			_Utils_Tuple2('dribbble', $feathericons$elm_feather$FeatherIcons$dribbble),
			_Utils_Tuple2('droplet', $feathericons$elm_feather$FeatherIcons$droplet),
			_Utils_Tuple2('edit-2', $feathericons$elm_feather$FeatherIcons$edit2),
			_Utils_Tuple2('edit-3', $feathericons$elm_feather$FeatherIcons$edit3),
			_Utils_Tuple2('edit', $feathericons$elm_feather$FeatherIcons$edit),
			_Utils_Tuple2('external-link', $feathericons$elm_feather$FeatherIcons$externalLink),
			_Utils_Tuple2('eye-off', $feathericons$elm_feather$FeatherIcons$eyeOff),
			_Utils_Tuple2('eye', $feathericons$elm_feather$FeatherIcons$eye),
			_Utils_Tuple2('facebook', $feathericons$elm_feather$FeatherIcons$facebook),
			_Utils_Tuple2('fast-forward', $feathericons$elm_feather$FeatherIcons$fastForward),
			_Utils_Tuple2('feather', $feathericons$elm_feather$FeatherIcons$feather),
			_Utils_Tuple2('figma', $feathericons$elm_feather$FeatherIcons$figma),
			_Utils_Tuple2('file-minus', $feathericons$elm_feather$FeatherIcons$fileMinus),
			_Utils_Tuple2('file-plus', $feathericons$elm_feather$FeatherIcons$filePlus),
			_Utils_Tuple2('file-text', $feathericons$elm_feather$FeatherIcons$fileText),
			_Utils_Tuple2('file', $feathericons$elm_feather$FeatherIcons$file),
			_Utils_Tuple2('film', $feathericons$elm_feather$FeatherIcons$film),
			_Utils_Tuple2('filter', $feathericons$elm_feather$FeatherIcons$filter),
			_Utils_Tuple2('flag', $feathericons$elm_feather$FeatherIcons$flag),
			_Utils_Tuple2('folder-minus', $feathericons$elm_feather$FeatherIcons$folderMinus),
			_Utils_Tuple2('folder-plus', $feathericons$elm_feather$FeatherIcons$folderPlus),
			_Utils_Tuple2('folder', $feathericons$elm_feather$FeatherIcons$folder),
			_Utils_Tuple2('framer', $feathericons$elm_feather$FeatherIcons$framer),
			_Utils_Tuple2('frown', $feathericons$elm_feather$FeatherIcons$frown),
			_Utils_Tuple2('gift', $feathericons$elm_feather$FeatherIcons$gift),
			_Utils_Tuple2('git-branch', $feathericons$elm_feather$FeatherIcons$gitBranch),
			_Utils_Tuple2('git-commit', $feathericons$elm_feather$FeatherIcons$gitCommit),
			_Utils_Tuple2('git-merge', $feathericons$elm_feather$FeatherIcons$gitMerge),
			_Utils_Tuple2('git-pull-request', $feathericons$elm_feather$FeatherIcons$gitPullRequest),
			_Utils_Tuple2('github', $feathericons$elm_feather$FeatherIcons$github),
			_Utils_Tuple2('gitlab', $feathericons$elm_feather$FeatherIcons$gitlab),
			_Utils_Tuple2('globe', $feathericons$elm_feather$FeatherIcons$globe),
			_Utils_Tuple2('grid', $feathericons$elm_feather$FeatherIcons$grid),
			_Utils_Tuple2('hard-drive', $feathericons$elm_feather$FeatherIcons$hardDrive),
			_Utils_Tuple2('hash', $feathericons$elm_feather$FeatherIcons$hash),
			_Utils_Tuple2('headphones', $feathericons$elm_feather$FeatherIcons$headphones),
			_Utils_Tuple2('heart', $feathericons$elm_feather$FeatherIcons$heart),
			_Utils_Tuple2('help-circle', $feathericons$elm_feather$FeatherIcons$helpCircle),
			_Utils_Tuple2('hexagon', $feathericons$elm_feather$FeatherIcons$hexagon),
			_Utils_Tuple2('home', $feathericons$elm_feather$FeatherIcons$home),
			_Utils_Tuple2('image', $feathericons$elm_feather$FeatherIcons$image),
			_Utils_Tuple2('inbox', $feathericons$elm_feather$FeatherIcons$inbox),
			_Utils_Tuple2('info', $feathericons$elm_feather$FeatherIcons$info),
			_Utils_Tuple2('instagram', $feathericons$elm_feather$FeatherIcons$instagram),
			_Utils_Tuple2('italic', $feathericons$elm_feather$FeatherIcons$italic),
			_Utils_Tuple2('key', $feathericons$elm_feather$FeatherIcons$key),
			_Utils_Tuple2('layers', $feathericons$elm_feather$FeatherIcons$layers),
			_Utils_Tuple2('layout', $feathericons$elm_feather$FeatherIcons$layout),
			_Utils_Tuple2('life-buoy', $feathericons$elm_feather$FeatherIcons$lifeBuoy),
			_Utils_Tuple2('link-2', $feathericons$elm_feather$FeatherIcons$link2),
			_Utils_Tuple2('link', $feathericons$elm_feather$FeatherIcons$link),
			_Utils_Tuple2('linkedin', $feathericons$elm_feather$FeatherIcons$linkedin),
			_Utils_Tuple2('list', $feathericons$elm_feather$FeatherIcons$list),
			_Utils_Tuple2('loader', $feathericons$elm_feather$FeatherIcons$loader),
			_Utils_Tuple2('lock', $feathericons$elm_feather$FeatherIcons$lock),
			_Utils_Tuple2('log-in', $feathericons$elm_feather$FeatherIcons$logIn),
			_Utils_Tuple2('log-out', $feathericons$elm_feather$FeatherIcons$logOut),
			_Utils_Tuple2('mail', $feathericons$elm_feather$FeatherIcons$mail),
			_Utils_Tuple2('map-pin', $feathericons$elm_feather$FeatherIcons$mapPin),
			_Utils_Tuple2('map', $feathericons$elm_feather$FeatherIcons$map),
			_Utils_Tuple2('maximize-2', $feathericons$elm_feather$FeatherIcons$maximize2),
			_Utils_Tuple2('maximize', $feathericons$elm_feather$FeatherIcons$maximize),
			_Utils_Tuple2('meh', $feathericons$elm_feather$FeatherIcons$meh),
			_Utils_Tuple2('menu', $feathericons$elm_feather$FeatherIcons$menu),
			_Utils_Tuple2('message-circle', $feathericons$elm_feather$FeatherIcons$messageCircle),
			_Utils_Tuple2('message-square', $feathericons$elm_feather$FeatherIcons$messageSquare),
			_Utils_Tuple2('mic-off', $feathericons$elm_feather$FeatherIcons$micOff),
			_Utils_Tuple2('mic', $feathericons$elm_feather$FeatherIcons$mic),
			_Utils_Tuple2('minimize-2', $feathericons$elm_feather$FeatherIcons$minimize2),
			_Utils_Tuple2('minimize', $feathericons$elm_feather$FeatherIcons$minimize),
			_Utils_Tuple2('minus-circle', $feathericons$elm_feather$FeatherIcons$minusCircle),
			_Utils_Tuple2('minus-square', $feathericons$elm_feather$FeatherIcons$minusSquare),
			_Utils_Tuple2('minus', $feathericons$elm_feather$FeatherIcons$minus),
			_Utils_Tuple2('monitor', $feathericons$elm_feather$FeatherIcons$monitor),
			_Utils_Tuple2('moon', $feathericons$elm_feather$FeatherIcons$moon),
			_Utils_Tuple2('more-horizontal', $feathericons$elm_feather$FeatherIcons$moreHorizontal),
			_Utils_Tuple2('more-vertical', $feathericons$elm_feather$FeatherIcons$moreVertical),
			_Utils_Tuple2('mouse-pointer', $feathericons$elm_feather$FeatherIcons$mousePointer),
			_Utils_Tuple2('move', $feathericons$elm_feather$FeatherIcons$move),
			_Utils_Tuple2('music', $feathericons$elm_feather$FeatherIcons$music),
			_Utils_Tuple2('navigation-2', $feathericons$elm_feather$FeatherIcons$navigation2),
			_Utils_Tuple2('navigation', $feathericons$elm_feather$FeatherIcons$navigation),
			_Utils_Tuple2('octagon', $feathericons$elm_feather$FeatherIcons$octagon),
			_Utils_Tuple2('package', $feathericons$elm_feather$FeatherIcons$package),
			_Utils_Tuple2('paperclip', $feathericons$elm_feather$FeatherIcons$paperclip),
			_Utils_Tuple2('pause-circle', $feathericons$elm_feather$FeatherIcons$pauseCircle),
			_Utils_Tuple2('pause', $feathericons$elm_feather$FeatherIcons$pause),
			_Utils_Tuple2('pen-tool', $feathericons$elm_feather$FeatherIcons$penTool),
			_Utils_Tuple2('percent', $feathericons$elm_feather$FeatherIcons$percent),
			_Utils_Tuple2('phone-call', $feathericons$elm_feather$FeatherIcons$phoneCall),
			_Utils_Tuple2('phone-forwarded', $feathericons$elm_feather$FeatherIcons$phoneForwarded),
			_Utils_Tuple2('phone-incoming', $feathericons$elm_feather$FeatherIcons$phoneIncoming),
			_Utils_Tuple2('phone-missed', $feathericons$elm_feather$FeatherIcons$phoneMissed),
			_Utils_Tuple2('phone-off', $feathericons$elm_feather$FeatherIcons$phoneOff),
			_Utils_Tuple2('phone-outgoing', $feathericons$elm_feather$FeatherIcons$phoneOutgoing),
			_Utils_Tuple2('phone', $feathericons$elm_feather$FeatherIcons$phone),
			_Utils_Tuple2('pie-chart', $feathericons$elm_feather$FeatherIcons$pieChart),
			_Utils_Tuple2('play-circle', $feathericons$elm_feather$FeatherIcons$playCircle),
			_Utils_Tuple2('play', $feathericons$elm_feather$FeatherIcons$play),
			_Utils_Tuple2('plus-circle', $feathericons$elm_feather$FeatherIcons$plusCircle),
			_Utils_Tuple2('plus-square', $feathericons$elm_feather$FeatherIcons$plusSquare),
			_Utils_Tuple2('plus', $feathericons$elm_feather$FeatherIcons$plus),
			_Utils_Tuple2('pocket', $feathericons$elm_feather$FeatherIcons$pocket),
			_Utils_Tuple2('power', $feathericons$elm_feather$FeatherIcons$power),
			_Utils_Tuple2('printer', $feathericons$elm_feather$FeatherIcons$printer),
			_Utils_Tuple2('radio', $feathericons$elm_feather$FeatherIcons$radio),
			_Utils_Tuple2('refresh-ccw', $feathericons$elm_feather$FeatherIcons$refreshCcw),
			_Utils_Tuple2('refresh-cw', $feathericons$elm_feather$FeatherIcons$refreshCw),
			_Utils_Tuple2('repeat', $feathericons$elm_feather$FeatherIcons$repeat),
			_Utils_Tuple2('rewind', $feathericons$elm_feather$FeatherIcons$rewind),
			_Utils_Tuple2('rotate-ccw', $feathericons$elm_feather$FeatherIcons$rotateCcw),
			_Utils_Tuple2('rotate-cw', $feathericons$elm_feather$FeatherIcons$rotateCw),
			_Utils_Tuple2('rss', $feathericons$elm_feather$FeatherIcons$rss),
			_Utils_Tuple2('save', $feathericons$elm_feather$FeatherIcons$save),
			_Utils_Tuple2('scissors', $feathericons$elm_feather$FeatherIcons$scissors),
			_Utils_Tuple2('search', $feathericons$elm_feather$FeatherIcons$search),
			_Utils_Tuple2('send', $feathericons$elm_feather$FeatherIcons$send),
			_Utils_Tuple2('server', $feathericons$elm_feather$FeatherIcons$server),
			_Utils_Tuple2('settings', $feathericons$elm_feather$FeatherIcons$settings),
			_Utils_Tuple2('share-2', $feathericons$elm_feather$FeatherIcons$share2),
			_Utils_Tuple2('share', $feathericons$elm_feather$FeatherIcons$share),
			_Utils_Tuple2('shield-off', $feathericons$elm_feather$FeatherIcons$shieldOff),
			_Utils_Tuple2('shield', $feathericons$elm_feather$FeatherIcons$shield),
			_Utils_Tuple2('shopping-bag', $feathericons$elm_feather$FeatherIcons$shoppingBag),
			_Utils_Tuple2('shopping-cart', $feathericons$elm_feather$FeatherIcons$shoppingCart),
			_Utils_Tuple2('shuffle', $feathericons$elm_feather$FeatherIcons$shuffle),
			_Utils_Tuple2('sidebar', $feathericons$elm_feather$FeatherIcons$sidebar),
			_Utils_Tuple2('skip-back', $feathericons$elm_feather$FeatherIcons$skipBack),
			_Utils_Tuple2('skip-forward', $feathericons$elm_feather$FeatherIcons$skipForward),
			_Utils_Tuple2('slack', $feathericons$elm_feather$FeatherIcons$slack),
			_Utils_Tuple2('slash', $feathericons$elm_feather$FeatherIcons$slash),
			_Utils_Tuple2('sliders', $feathericons$elm_feather$FeatherIcons$sliders),
			_Utils_Tuple2('smartphone', $feathericons$elm_feather$FeatherIcons$smartphone),
			_Utils_Tuple2('smile', $feathericons$elm_feather$FeatherIcons$smile),
			_Utils_Tuple2('speaker', $feathericons$elm_feather$FeatherIcons$speaker),
			_Utils_Tuple2('square', $feathericons$elm_feather$FeatherIcons$square),
			_Utils_Tuple2('star', $feathericons$elm_feather$FeatherIcons$star),
			_Utils_Tuple2('stop-circle', $feathericons$elm_feather$FeatherIcons$stopCircle),
			_Utils_Tuple2('sun', $feathericons$elm_feather$FeatherIcons$sun),
			_Utils_Tuple2('sunrise', $feathericons$elm_feather$FeatherIcons$sunrise),
			_Utils_Tuple2('sunset', $feathericons$elm_feather$FeatherIcons$sunset),
			_Utils_Tuple2('tablet', $feathericons$elm_feather$FeatherIcons$tablet),
			_Utils_Tuple2('tag', $feathericons$elm_feather$FeatherIcons$tag),
			_Utils_Tuple2('target', $feathericons$elm_feather$FeatherIcons$target),
			_Utils_Tuple2('terminal', $feathericons$elm_feather$FeatherIcons$terminal),
			_Utils_Tuple2('thermometer', $feathericons$elm_feather$FeatherIcons$thermometer),
			_Utils_Tuple2('thumbs-down', $feathericons$elm_feather$FeatherIcons$thumbsDown),
			_Utils_Tuple2('thumbs-up', $feathericons$elm_feather$FeatherIcons$thumbsUp),
			_Utils_Tuple2('toggle-left', $feathericons$elm_feather$FeatherIcons$toggleLeft),
			_Utils_Tuple2('toggle-right', $feathericons$elm_feather$FeatherIcons$toggleRight),
			_Utils_Tuple2('tool', $feathericons$elm_feather$FeatherIcons$tool),
			_Utils_Tuple2('trash-2', $feathericons$elm_feather$FeatherIcons$trash2),
			_Utils_Tuple2('trash', $feathericons$elm_feather$FeatherIcons$trash),
			_Utils_Tuple2('trello', $feathericons$elm_feather$FeatherIcons$trello),
			_Utils_Tuple2('trending-down', $feathericons$elm_feather$FeatherIcons$trendingDown),
			_Utils_Tuple2('trending-up', $feathericons$elm_feather$FeatherIcons$trendingUp),
			_Utils_Tuple2('triangle', $feathericons$elm_feather$FeatherIcons$triangle),
			_Utils_Tuple2('truck', $feathericons$elm_feather$FeatherIcons$truck),
			_Utils_Tuple2('tv', $feathericons$elm_feather$FeatherIcons$tv),
			_Utils_Tuple2('twitch', $feathericons$elm_feather$FeatherIcons$twitch),
			_Utils_Tuple2('twitter', $feathericons$elm_feather$FeatherIcons$twitter),
			_Utils_Tuple2('type', $feathericons$elm_feather$FeatherIcons$type_),
			_Utils_Tuple2('umbrella', $feathericons$elm_feather$FeatherIcons$umbrella),
			_Utils_Tuple2('underline', $feathericons$elm_feather$FeatherIcons$underline),
			_Utils_Tuple2('unlock', $feathericons$elm_feather$FeatherIcons$unlock),
			_Utils_Tuple2('upload-cloud', $feathericons$elm_feather$FeatherIcons$uploadCloud),
			_Utils_Tuple2('upload', $feathericons$elm_feather$FeatherIcons$upload),
			_Utils_Tuple2('user-check', $feathericons$elm_feather$FeatherIcons$userCheck),
			_Utils_Tuple2('user-minus', $feathericons$elm_feather$FeatherIcons$userMinus),
			_Utils_Tuple2('user-plus', $feathericons$elm_feather$FeatherIcons$userPlus),
			_Utils_Tuple2('user-x', $feathericons$elm_feather$FeatherIcons$userX),
			_Utils_Tuple2('user', $feathericons$elm_feather$FeatherIcons$user),
			_Utils_Tuple2('users', $feathericons$elm_feather$FeatherIcons$users),
			_Utils_Tuple2('video-off', $feathericons$elm_feather$FeatherIcons$videoOff),
			_Utils_Tuple2('video', $feathericons$elm_feather$FeatherIcons$video),
			_Utils_Tuple2('voicemail', $feathericons$elm_feather$FeatherIcons$voicemail),
			_Utils_Tuple2('volume-1', $feathericons$elm_feather$FeatherIcons$volume1),
			_Utils_Tuple2('volume-2', $feathericons$elm_feather$FeatherIcons$volume2),
			_Utils_Tuple2('volume-x', $feathericons$elm_feather$FeatherIcons$volumeX),
			_Utils_Tuple2('volume', $feathericons$elm_feather$FeatherIcons$volume),
			_Utils_Tuple2('watch', $feathericons$elm_feather$FeatherIcons$watch),
			_Utils_Tuple2('wifi-off', $feathericons$elm_feather$FeatherIcons$wifiOff),
			_Utils_Tuple2('wifi', $feathericons$elm_feather$FeatherIcons$wifi),
			_Utils_Tuple2('wind', $feathericons$elm_feather$FeatherIcons$wind),
			_Utils_Tuple2('x-circle', $feathericons$elm_feather$FeatherIcons$xCircle),
			_Utils_Tuple2('x-octagon', $feathericons$elm_feather$FeatherIcons$xOctagon),
			_Utils_Tuple2('x-square', $feathericons$elm_feather$FeatherIcons$xSquare),
			_Utils_Tuple2('x', $feathericons$elm_feather$FeatherIcons$x),
			_Utils_Tuple2('youtube', $feathericons$elm_feather$FeatherIcons$youtube),
			_Utils_Tuple2('zap-off', $feathericons$elm_feather$FeatherIcons$zapOff),
			_Utils_Tuple2('zap', $feathericons$elm_feather$FeatherIcons$zap),
			_Utils_Tuple2('zoom-in', $feathericons$elm_feather$FeatherIcons$zoomIn),
			_Utils_Tuple2('zoom-out', $feathericons$elm_feather$FeatherIcons$zoomOut)
		]));
var $elm$svg$Svg$Attributes$class = _VirtualDom_attribute('class');
var $elm$svg$Svg$Attributes$fill = _VirtualDom_attribute('fill');
var $elm$core$String$fromFloat = _String_fromNumber;
var $elm$virtual_dom$VirtualDom$map = _VirtualDom_map;
var $elm$svg$Svg$map = $elm$virtual_dom$VirtualDom$map;
var $elm$svg$Svg$Attributes$stroke = _VirtualDom_attribute('stroke');
var $elm$svg$Svg$Attributes$strokeLinecap = _VirtualDom_attribute('stroke-linecap');
var $elm$svg$Svg$Attributes$strokeLinejoin = _VirtualDom_attribute('stroke-linejoin');
var $elm$svg$Svg$Attributes$strokeWidth = _VirtualDom_attribute('stroke-width');
var $elm$svg$Svg$svg = $elm$svg$Svg$trustedNode('svg');
var $elm$svg$Svg$Attributes$viewBox = _VirtualDom_attribute('viewBox');
var $feathericons$elm_feather$FeatherIcons$toHtml = F2(
	function (attributes, _v0) {
		var src = _v0.bq;
		var attrs = _v0.E;
		var strSize = $elm$core$String$fromFloat(attrs.bo);
		var baseAttributes = _List_fromArray(
			[
				$elm$svg$Svg$Attributes$fill('none'),
				$elm$svg$Svg$Attributes$height(
				_Utils_ap(strSize, attrs.ay)),
				$elm$svg$Svg$Attributes$width(
				_Utils_ap(strSize, attrs.ay)),
				$elm$svg$Svg$Attributes$stroke('currentColor'),
				$elm$svg$Svg$Attributes$strokeLinecap('round'),
				$elm$svg$Svg$Attributes$strokeLinejoin('round'),
				$elm$svg$Svg$Attributes$strokeWidth(
				$elm$core$String$fromFloat(attrs.aV)),
				$elm$svg$Svg$Attributes$viewBox(attrs.a$)
			]);
		var combinedAttributes = _Utils_ap(
			function () {
				var _v1 = attrs.aG;
				if (!_v1.$) {
					var c = _v1.a;
					return A2(
						$elm$core$List$cons,
						$elm$svg$Svg$Attributes$class(c),
						baseAttributes);
				} else {
					return baseAttributes;
				}
			}(),
			attributes);
		return A2(
			$elm$svg$Svg$svg,
			combinedAttributes,
			A2(
				$elm$core$List$map,
				$elm$svg$Svg$map($elm$core$Basics$never),
				src));
	});
var $feathericons$elm_feather$FeatherIcons$withSize = F2(
	function (size, _v0) {
		var attrs = _v0.E;
		var src = _v0.bq;
		return {
			E: _Utils_update(
				attrs,
				{bo: size}),
			bq: src
		};
	});
var $author$project$Feature$IconAPI$view = F3(
	function (iconName, size, style_) {
		var _v0 = A2($elm$core$Dict$get, iconName, $feathericons$elm_feather$FeatherIcons$icons);
		if (!_v0.$) {
			var icon = _v0.a;
			return A2(
				$feathericons$elm_feather$FeatherIcons$toHtml,
				style_,
				A2($feathericons$elm_feather$FeatherIcons$withSize, size, icon));
		} else {
			return $elm$html$Html$text('??');
		}
	});
var $author$project$Feature$IconAPI$viewTopicIcon = F4(
	function (topicId, size, style_, model) {
		var _v0 = A2($author$project$Item$topicById, topicId, model);
		if (!_v0.$) {
			var topic = _v0.a;
			var _v1 = topic.aa;
			if (!_v1.$) {
				var iconName = _v1.a;
				return A3($author$project$Feature$IconAPI$view, iconName, size, style_);
			} else {
				return $elm$html$Html$text('');
			}
		} else {
			return $elm$html$Html$text('?');
		}
	});
var $author$project$Map$viewLabelTopic = F4(
	function (topic, props, boxPath, model) {
		var textElem = function () {
			var _v0 = A3($author$project$Feature$TextAPI$isEdit, topic.aK, boxPath, model);
			if (_v0) {
				return A3($author$project$Feature$TextAPI$viewInput, topic, boxPath, $author$project$Map$inputStyle);
			} else {
				return A2(
					$elm$html$Html$div,
					$author$project$Map$topicLabelStyle,
					_List_fromArray(
						[
							$elm$html$Html$text(
							$author$project$Item$topicLabel(topic))
						]));
			}
		}();
		return _List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				$author$project$Map$iconBoxStyle(props),
				_List_fromArray(
					[
						A4($author$project$Feature$IconAPI$viewTopicIcon, topic.aK, $author$project$Config$topicIconSize, $author$project$Map$topicIconStyle, model)
					])),
				textElem
			]);
	});
var $author$project$Map$blackBoxTopic = F4(
	function (topic, props, boxPath, model) {
		return _Utils_Tuple2(
			$author$project$Map$topicPosStyle(props),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					A4($author$project$Map$topicFlexboxStyle, topic, props, boxPath, model),
					_Utils_ap(
						A4($author$project$Map$viewLabelTopic, topic, props, boxPath, model),
						A3($author$project$Map$viewItemCount, topic.aK, props, model))),
					A2(
					$elm$html$Html$div,
					A3($author$project$Map$ghostTopicStyle, topic, boxPath, model),
					_List_Nil)
				]));
	});
var $author$project$Map$detailTextStyle = F3(
	function (topicId, boxPath, model) {
		var r = $elm$core$String$fromInt($author$project$Config$topicRadius) + 'px';
		return _Utils_ap(
			_List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					'font-size',
					$elm$core$String$fromInt($author$project$Config$contentFontSize) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromInt($author$project$Config$topicDetailMaxWidth) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'line-height',
					$elm$core$String$fromFloat($author$project$Config$topicLineHeight)),
					A2(
					$elm$html$Html$Attributes$style,
					'padding',
					$elm$core$String$fromInt($author$project$Config$topicDetailPadding) + 'px'),
					A2($elm$html$Html$Attributes$style, 'border-radius', '0 ' + (r + (' ' + (r + (' ' + r)))))
				]),
			_Utils_ap(
				A3($author$project$Map$topicBorderStyle, topicId, boxPath, model),
				A3($author$project$Map$selectionStyle, topicId, boxPath, model)));
	});
var $author$project$Map$detailTopicIconBoxStyle = _List_fromArray(
	[
		A2(
		$elm$html$Html$Attributes$style,
		'padding-left',
		$elm$core$String$fromInt($author$project$Config$topicBorderWidth) + 'px'),
		A2(
		$elm$html$Html$Attributes$style,
		'width',
		$elm$core$String$fromInt($author$project$Config$topicSize.b_ - $author$project$Config$topicBorderWidth) + 'px')
	]);
var $author$project$Map$detailTopicStyle = function (_v0) {
	var pos = _v0.av;
	return _List_fromArray(
		[
			A2($elm$html$Html$Attributes$style, 'display', 'flex'),
			A2(
			$elm$html$Html$Attributes$style,
			'left',
			$elm$core$String$fromInt(pos.d1 - $author$project$Config$topicW2) + 'px'),
			A2(
			$elm$html$Html$Attributes$style,
			'top',
			$elm$core$String$fromInt(pos.d3 - $author$project$Config$topicH2) + 'px')
		]);
};
var $elm$html$Html$a = _VirtualDom_node('a');
var $elm$html$Html$Attributes$align = $elm$html$Html$Attributes$stringProperty('align');
var $elm$html$Html$Attributes$alt = $elm$html$Html$Attributes$stringProperty('alt');
var $elm$html$Html$blockquote = _VirtualDom_node('blockquote');
var $elm$html$Html$br = _VirtualDom_node('br');
var $elm$json$Json$Encode$bool = _Json_wrap;
var $elm$html$Html$Attributes$boolProperty = F2(
	function (key, bool) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$bool(bool));
	});
var $elm$html$Html$Attributes$checked = $elm$html$Html$Attributes$boolProperty('checked');
var $elm$html$Html$Attributes$class = $elm$html$Html$Attributes$stringProperty('className');
var $elm$html$Html$code = _VirtualDom_node('code');
var $elm$html$Html$del = _VirtualDom_node('del');
var $elm$html$Html$Attributes$disabled = $elm$html$Html$Attributes$boolProperty('disabled');
var $elm$html$Html$em = _VirtualDom_node('em');
var $elm$html$Html$h1 = _VirtualDom_node('h1');
var $elm$html$Html$h2 = _VirtualDom_node('h2');
var $elm$html$Html$h3 = _VirtualDom_node('h3');
var $elm$html$Html$h4 = _VirtualDom_node('h4');
var $elm$html$Html$h5 = _VirtualDom_node('h5');
var $elm$html$Html$h6 = _VirtualDom_node('h6');
var $elm$html$Html$hr = _VirtualDom_node('hr');
var $elm$html$Html$Attributes$href = function (url) {
	return A2(
		$elm$html$Html$Attributes$stringProperty,
		'href',
		_VirtualDom_noJavaScriptUri(url));
};
var $elm$html$Html$img = _VirtualDom_node('img');
var $elm$html$Html$li = _VirtualDom_node('li');
var $elm$core$Maybe$map = F2(
	function (f, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return $elm$core$Maybe$Just(
				f(value));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $elm$html$Html$ol = _VirtualDom_node('ol');
var $dillonkearns$elm_markdown$Markdown$HtmlRenderer$HtmlRenderer = $elm$core$Basics$identity;
var $elm$core$Result$mapError = F2(
	function (f, result) {
		if (!result.$) {
			var v = result.a;
			return $elm$core$Result$Ok(v);
		} else {
			var e = result.a;
			return $elm$core$Result$Err(
				f(e));
		}
	});
var $dillonkearns$elm_markdown$Markdown$Html$resultOr = F2(
	function (ra, rb) {
		if (ra.$ === 1) {
			var singleError = ra.a;
			if (!rb.$) {
				var okValue = rb.a;
				return $elm$core$Result$Ok(okValue);
			} else {
				var errorsSoFar = rb.a;
				return $elm$core$Result$Err(
					A2($elm$core$List$cons, singleError, errorsSoFar));
			}
		} else {
			var okValue = ra.a;
			return $elm$core$Result$Ok(okValue);
		}
	});
var $dillonkearns$elm_markdown$Markdown$Html$attributesToString = function (attributes) {
	return A2(
		$elm$core$String$join,
		' ',
		A2(
			$elm$core$List$map,
			function (_v0) {
				var name = _v0.ce;
				var value = _v0.cL;
				return name + ('=\"' + (value + '\"'));
			},
			attributes));
};
var $dillonkearns$elm_markdown$Markdown$Html$tagToString = F2(
	function (tagName, attributes) {
		return $elm$core$List$isEmpty(attributes) ? ('<' + (tagName + '>')) : ('<' + (tagName + (' ' + ($dillonkearns$elm_markdown$Markdown$Html$attributesToString(attributes) + '>'))));
	});
var $dillonkearns$elm_markdown$Markdown$Html$oneOf = function (decoders) {
	var unwrappedDecoders = A2(
		$elm$core$List$map,
		function (_v4) {
			var rawDecoder = _v4;
			return rawDecoder;
		},
		decoders);
	return function (rawDecoder) {
		return F3(
			function (tagName, attributes, innerBlocks) {
				return A2(
					$elm$core$Result$mapError,
					function (errors) {
						if (!errors.b) {
							return 'Ran into a oneOf with no possibilities!';
						} else {
							if (!errors.b.b) {
								var singleError = errors.a;
								return 'Problem with the given value:\n\n' + (A2($dillonkearns$elm_markdown$Markdown$Html$tagToString, tagName, attributes) + ('\n\n' + (singleError + '\n')));
							} else {
								return 'oneOf failed parsing this value:\n    ' + (A2($dillonkearns$elm_markdown$Markdown$Html$tagToString, tagName, attributes) + ('\n\nParsing failed in the following 2 ways:\n\n\n' + (A2(
									$elm$core$String$join,
									'\n\n',
									A2(
										$elm$core$List$indexedMap,
										F2(
											function (index, error) {
												return '(' + ($elm$core$String$fromInt(index + 1) + (') ' + error));
											}),
										errors)) + '\n')));
							}
						}
					},
					A3(rawDecoder, tagName, attributes, innerBlocks));
			});
	}(
		A3(
			$elm$core$List$foldl,
			F2(
				function (decoder, soFar) {
					return F3(
						function (tagName, attributes, children) {
							return A2(
								$dillonkearns$elm_markdown$Markdown$Html$resultOr,
								A3(decoder, tagName, attributes, children),
								A3(soFar, tagName, attributes, children));
						});
				}),
			F3(
				function (_v0, _v1, _v2) {
					return $elm$core$Result$Err(_List_Nil);
				}),
			unwrappedDecoders));
};
var $elm$html$Html$p = _VirtualDom_node('p');
var $elm$html$Html$pre = _VirtualDom_node('pre');
var $elm$core$List$singleton = function (value) {
	return _List_fromArray(
		[value]);
};
var $elm$html$Html$Attributes$src = function (url) {
	return A2(
		$elm$html$Html$Attributes$stringProperty,
		'src',
		_VirtualDom_noJavaScriptOrHtmlUri(url));
};
var $elm$html$Html$Attributes$start = function (n) {
	return A2(
		$elm$html$Html$Attributes$stringProperty,
		'start',
		$elm$core$String$fromInt(n));
};
var $elm$html$Html$strong = _VirtualDom_node('strong');
var $elm$html$Html$table = _VirtualDom_node('table');
var $elm$html$Html$tbody = _VirtualDom_node('tbody');
var $elm$html$Html$td = _VirtualDom_node('td');
var $elm$html$Html$th = _VirtualDom_node('th');
var $elm$html$Html$thead = _VirtualDom_node('thead');
var $elm$html$Html$Attributes$title = $elm$html$Html$Attributes$stringProperty('title');
var $elm$html$Html$tr = _VirtualDom_node('tr');
var $elm$html$Html$Attributes$type_ = $elm$html$Html$Attributes$stringProperty('type');
var $elm$html$Html$ul = _VirtualDom_node('ul');
var $elm$core$String$words = _String_words;
var $dillonkearns$elm_markdown$Markdown$Renderer$defaultHtmlRenderer = {
	a3: $elm$html$Html$blockquote(_List_Nil),
	a5: function (_v0) {
		var body = _v0.cW;
		var language = _v0.dn;
		var classes = function () {
			var _v1 = A2($elm$core$Maybe$map, $elm$core$String$words, language);
			if ((!_v1.$) && _v1.a.b) {
				var _v2 = _v1.a;
				var actualLanguage = _v2.a;
				return _List_fromArray(
					[
						$elm$html$Html$Attributes$class('language-' + actualLanguage)
					]);
			} else {
				return _List_Nil;
			}
		}();
		return A2(
			$elm$html$Html$pre,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$elm$html$Html$code,
					classes,
					_List_fromArray(
						[
							$elm$html$Html$text(body)
						]))
				]));
	},
	a6: function (content) {
		return A2(
			$elm$html$Html$code,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text(content)
				]));
	},
	a8: function (children) {
		return A2($elm$html$Html$em, _List_Nil, children);
	},
	ba: A2($elm$html$Html$br, _List_Nil, _List_Nil),
	bb: function (_v3) {
		var level = _v3.cb;
		var children = _v3.bN;
		switch (level) {
			case 0:
				return A2($elm$html$Html$h1, _List_Nil, children);
			case 1:
				return A2($elm$html$Html$h2, _List_Nil, children);
			case 2:
				return A2($elm$html$Html$h3, _List_Nil, children);
			case 3:
				return A2($elm$html$Html$h4, _List_Nil, children);
			case 4:
				return A2($elm$html$Html$h5, _List_Nil, children);
			default:
				return A2($elm$html$Html$h6, _List_Nil, children);
		}
	},
	bc: $dillonkearns$elm_markdown$Markdown$Html$oneOf(_List_Nil),
	bd: function (imageInfo) {
		var _v5 = imageInfo.dY;
		if (!_v5.$) {
			var title = _v5.a;
			return A2(
				$elm$html$Html$img,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$src(imageInfo.bq),
						$elm$html$Html$Attributes$alt(imageInfo.a2),
						$elm$html$Html$Attributes$title(title)
					]),
				_List_Nil);
		} else {
			return A2(
				$elm$html$Html$img,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$src(imageInfo.bq),
						$elm$html$Html$Attributes$alt(imageInfo.a2)
					]),
				_List_Nil);
		}
	},
	bg: F2(
		function (link, content) {
			var _v6 = link.dY;
			if (!_v6.$) {
				var title = _v6.a;
				return A2(
					$elm$html$Html$a,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$href(link.c3),
							$elm$html$Html$Attributes$title(title)
						]),
					content);
			} else {
				return A2(
					$elm$html$Html$a,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$href(link.c3)
						]),
					content);
			}
		}),
	bk: F2(
		function (startingIndex, items) {
			return A2(
				$elm$html$Html$ol,
				function () {
					if (startingIndex === 1) {
						return _List_fromArray(
							[
								$elm$html$Html$Attributes$start(startingIndex)
							]);
					} else {
						return _List_Nil;
					}
				}(),
				A2(
					$elm$core$List$map,
					function (itemBlocks) {
						return A2($elm$html$Html$li, _List_Nil, itemBlocks);
					},
					items));
		}),
	bl: $elm$html$Html$p(_List_Nil),
	bt: function (children) {
		return A2($elm$html$Html$del, _List_Nil, children);
	},
	bu: function (children) {
		return A2($elm$html$Html$strong, _List_Nil, children);
	},
	bw: $elm$html$Html$table(_List_Nil),
	bx: $elm$html$Html$tbody(_List_Nil),
	by: function (maybeAlignment) {
		var attrs = A2(
			$elm$core$Maybe$withDefault,
			_List_Nil,
			A2(
				$elm$core$Maybe$map,
				$elm$core$List$singleton,
				A2(
					$elm$core$Maybe$map,
					$elm$html$Html$Attributes$align,
					A2(
						$elm$core$Maybe$map,
						function (alignment) {
							switch (alignment) {
								case 0:
									return 'left';
								case 2:
									return 'center';
								default:
									return 'right';
							}
						},
						maybeAlignment))));
		return $elm$html$Html$td(attrs);
	},
	bz: $elm$html$Html$thead(_List_Nil),
	bA: function (maybeAlignment) {
		var attrs = A2(
			$elm$core$Maybe$withDefault,
			_List_Nil,
			A2(
				$elm$core$Maybe$map,
				$elm$core$List$singleton,
				A2(
					$elm$core$Maybe$map,
					$elm$html$Html$Attributes$align,
					A2(
						$elm$core$Maybe$map,
						function (alignment) {
							switch (alignment) {
								case 0:
									return 'left';
								case 2:
									return 'center';
								default:
									return 'right';
							}
						},
						maybeAlignment))));
		return $elm$html$Html$th(attrs);
	},
	aW: $elm$html$Html$tr(_List_Nil),
	dX: $elm$html$Html$text,
	bC: A2($elm$html$Html$hr, _List_Nil, _List_Nil),
	bE: function (items) {
		return A2(
			$elm$html$Html$ul,
			_List_Nil,
			A2(
				$elm$core$List$map,
				function (item) {
					var task = item.a;
					var children = item.b;
					var checkbox = function () {
						switch (task) {
							case 0:
								return $elm$html$Html$text('');
							case 1:
								return A2(
									$elm$html$Html$input,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$disabled(true),
											$elm$html$Html$Attributes$checked(false),
											$elm$html$Html$Attributes$type_('checkbox')
										]),
									_List_Nil);
							default:
								return A2(
									$elm$html$Html$input,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$disabled(true),
											$elm$html$Html$Attributes$checked(true),
											$elm$html$Html$Attributes$type_('checkbox')
										]),
									_List_Nil);
						}
					}();
					return A2(
						$elm$html$Html$li,
						_List_Nil,
						A2($elm$core$List$cons, checkbox, children));
				},
				items));
	}
};
var $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine = {$: 10};
var $dillonkearns$elm_markdown$Markdown$Block$BlockQuote = function (a) {
	return {$: 3, a: a};
};
var $dillonkearns$elm_markdown$Markdown$RawBlock$BlockQuote = function (a) {
	return {$: 11, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$Cdata = function (a) {
	return {$: 4, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$CodeBlock = function (a) {
	return {$: 7, a: a};
};
var $dillonkearns$elm_markdown$Markdown$RawBlock$CodeBlock = function (a) {
	return {$: 5, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$CodeSpan = function (a) {
	return {$: 6, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$CompletedTask = 2;
var $elm$parser$Parser$Advanced$Done = function (a) {
	return {$: 1, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$Emphasis = function (a) {
	return {$: 3, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Inline$Emphasis = F2(
	function (a, b) {
		return {$: 6, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$Parser$EmptyBlock = {$: 0};
var $elm$parser$Parser$Expecting = function (a) {
	return {$: 0, a: a};
};
var $elm$parser$Parser$ExpectingSymbol = function (a) {
	return {$: 8, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$HardLineBreak = {$: 8};
var $dillonkearns$elm_markdown$Markdown$Block$Heading = F2(
	function (a, b) {
		return {$: 4, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$RawBlock$Heading = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$RawBlock$Html = function (a) {
	return {$: 2, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$HtmlBlock = function (a) {
	return {$: 0, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$HtmlComment = function (a) {
	return {$: 1, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$HtmlDeclaration = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$Block$HtmlElement = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $dillonkearns$elm_markdown$Markdown$Block$HtmlInline = function (a) {
	return {$: 0, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$Image = F3(
	function (a, b, c) {
		return {$: 2, a: a, b: b, c: c};
	});
var $dillonkearns$elm_markdown$Markdown$Block$IncompleteTask = 1;
var $dillonkearns$elm_markdown$Markdown$RawBlock$IndentedCodeBlock = function (a) {
	return {$: 6, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Parser$InlineProblem = function (a) {
	return {$: 2, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$Link = F3(
	function (a, b, c) {
		return {$: 1, a: a, b: b, c: c};
	});
var $dillonkearns$elm_markdown$Markdown$Block$ListItem = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$parser$Parser$Advanced$Loop = function (a) {
	return {$: 0, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$NoTask = 0;
var $dillonkearns$elm_markdown$Markdown$RawBlock$OpenBlockOrParagraph = function (a) {
	return {$: 1, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$OrderedList = F3(
	function (a, b, c) {
		return {$: 2, a: a, b: b, c: c};
	});
var $dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock = F6(
	function (a, b, c, d, e, f) {
		return {$: 4, a: a, b: b, c: c, d: d, e: e, f: f};
	});
var $dillonkearns$elm_markdown$Markdown$Block$Paragraph = function (a) {
	return {$: 5, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock = function (a) {
	return {$: 1, a: a};
};
var $dillonkearns$elm_markdown$Markdown$RawBlock$ParsedBlockQuote = function (a) {
	return {$: 12, a: a};
};
var $elm$parser$Parser$Problem = function (a) {
	return {$: 12, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$ProcessingInstruction = function (a) {
	return {$: 2, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$Strikethrough = function (a) {
	return {$: 5, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$Strong = function (a) {
	return {$: 4, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$Table = F2(
	function (a, b) {
		return {$: 6, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$RawBlock$Table = function (a) {
	return {$: 8, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Table$Table = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$Table$TableDelimiterRow = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$Block$Text = function (a) {
	return {$: 7, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Block$ThematicBreak = {$: 8};
var $dillonkearns$elm_markdown$Markdown$RawBlock$ThematicBreak = {$: 7};
var $elm$parser$Parser$Advanced$Token = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$Block$UnorderedList = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock = F4(
	function (a, b, c, d) {
		return {$: 3, a: a, b: b, c: c, d: d};
	});
var $dillonkearns$elm_markdown$Markdown$RawBlock$UnparsedInlines = $elm$core$Basics$identity;
var $dillonkearns$elm_markdown$Markdown$Parser$addReference = F2(
	function (state, linkRef) {
		return {
			a: A2($elm$core$List$cons, linkRef, state.a),
			b: state.b
		};
	});
var $elm$parser$Parser$Advanced$Bad = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $elm$parser$Parser$Advanced$Good = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $elm$parser$Parser$Advanced$Parser = $elm$core$Basics$identity;
var $elm$parser$Parser$Advanced$andThen = F2(
	function (callback, _v0) {
		var parseA = _v0;
		return function (s0) {
			var _v1 = parseA(s0);
			if (_v1.$ === 1) {
				var p = _v1.a;
				var x = _v1.b;
				return A2($elm$parser$Parser$Advanced$Bad, p, x);
			} else {
				var p1 = _v1.a;
				var a = _v1.b;
				var s1 = _v1.c;
				var _v2 = callback(a);
				var parseB = _v2;
				var _v3 = parseB(s1);
				if (_v3.$ === 1) {
					var p2 = _v3.a;
					var x = _v3.b;
					return A2($elm$parser$Parser$Advanced$Bad, p1 || p2, x);
				} else {
					var p2 = _v3.a;
					var b = _v3.b;
					var s2 = _v3.c;
					return A3($elm$parser$Parser$Advanced$Good, p1 || p2, b, s2);
				}
			}
		};
	});
var $elm$parser$Parser$Advanced$backtrackable = function (_v0) {
	var parse = _v0;
	return function (s0) {
		var _v1 = parse(s0);
		if (_v1.$ === 1) {
			var x = _v1.b;
			return A2($elm$parser$Parser$Advanced$Bad, false, x);
		} else {
			var a = _v1.b;
			var s1 = _v1.c;
			return A3($elm$parser$Parser$Advanced$Good, false, a, s1);
		}
	};
};
var $elm$parser$Parser$Advanced$isSubChar = _Parser_isSubChar;
var $elm$parser$Parser$Advanced$chompWhileHelp = F5(
	function (isGood, offset, row, col, s0) {
		chompWhileHelp:
		while (true) {
			var newOffset = A3($elm$parser$Parser$Advanced$isSubChar, isGood, offset, s0.bq);
			if (_Utils_eq(newOffset, -1)) {
				return A3(
					$elm$parser$Parser$Advanced$Good,
					_Utils_cmp(s0.e, offset) < 0,
					0,
					{bO: col, h: s0.h, j: s0.j, e: offset, dT: row, bq: s0.bq});
			} else {
				if (_Utils_eq(newOffset, -2)) {
					var $temp$isGood = isGood,
						$temp$offset = offset + 1,
						$temp$row = row + 1,
						$temp$col = 1,
						$temp$s0 = s0;
					isGood = $temp$isGood;
					offset = $temp$offset;
					row = $temp$row;
					col = $temp$col;
					s0 = $temp$s0;
					continue chompWhileHelp;
				} else {
					var $temp$isGood = isGood,
						$temp$offset = newOffset,
						$temp$row = row,
						$temp$col = col + 1,
						$temp$s0 = s0;
					isGood = $temp$isGood;
					offset = $temp$offset;
					row = $temp$row;
					col = $temp$col;
					s0 = $temp$s0;
					continue chompWhileHelp;
				}
			}
		}
	});
var $elm$parser$Parser$Advanced$chompWhile = function (isGood) {
	return function (s) {
		return A5($elm$parser$Parser$Advanced$chompWhileHelp, isGood, s.e, s.dT, s.bO, s);
	};
};
var $elm$core$Basics$always = F2(
	function (a, _v0) {
		return a;
	});
var $elm$parser$Parser$Advanced$map2 = F3(
	function (func, _v0, _v1) {
		var parseA = _v0;
		var parseB = _v1;
		return function (s0) {
			var _v2 = parseA(s0);
			if (_v2.$ === 1) {
				var p = _v2.a;
				var x = _v2.b;
				return A2($elm$parser$Parser$Advanced$Bad, p, x);
			} else {
				var p1 = _v2.a;
				var a = _v2.b;
				var s1 = _v2.c;
				var _v3 = parseB(s1);
				if (_v3.$ === 1) {
					var p2 = _v3.a;
					var x = _v3.b;
					return A2($elm$parser$Parser$Advanced$Bad, p1 || p2, x);
				} else {
					var p2 = _v3.a;
					var b = _v3.b;
					var s2 = _v3.c;
					return A3(
						$elm$parser$Parser$Advanced$Good,
						p1 || p2,
						A2(func, a, b),
						s2);
				}
			}
		};
	});
var $elm$parser$Parser$Advanced$ignorer = F2(
	function (keepParser, ignoreParser) {
		return A3($elm$parser$Parser$Advanced$map2, $elm$core$Basics$always, keepParser, ignoreParser);
	});
var $dillonkearns$elm_markdown$Whitespace$isSpaceOrTab = function (_char) {
	switch (_char) {
		case ' ':
			return true;
		case '\t':
			return true;
		default:
			return false;
	}
};
var $dillonkearns$elm_markdown$Parser$Token$carriageReturn = A2(
	$elm$parser$Parser$Advanced$Token,
	'\u000D',
	$elm$parser$Parser$Expecting('a carriage return'));
var $dillonkearns$elm_markdown$Parser$Token$newline = A2(
	$elm$parser$Parser$Advanced$Token,
	'\n',
	$elm$parser$Parser$Expecting('a newline'));
var $elm$parser$Parser$Advanced$Empty = {$: 0};
var $elm$parser$Parser$Advanced$Append = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $elm$parser$Parser$Advanced$oneOfHelp = F3(
	function (s0, bag, parsers) {
		oneOfHelp:
		while (true) {
			if (!parsers.b) {
				return A2($elm$parser$Parser$Advanced$Bad, false, bag);
			} else {
				var parse = parsers.a;
				var remainingParsers = parsers.b;
				var _v1 = parse(s0);
				if (!_v1.$) {
					var step = _v1;
					return step;
				} else {
					var step = _v1;
					var p = step.a;
					var x = step.b;
					if (p) {
						return step;
					} else {
						var $temp$s0 = s0,
							$temp$bag = A2($elm$parser$Parser$Advanced$Append, bag, x),
							$temp$parsers = remainingParsers;
						s0 = $temp$s0;
						bag = $temp$bag;
						parsers = $temp$parsers;
						continue oneOfHelp;
					}
				}
			}
		}
	});
var $elm$parser$Parser$Advanced$oneOf = function (parsers) {
	return function (s) {
		return A3($elm$parser$Parser$Advanced$oneOfHelp, s, $elm$parser$Parser$Advanced$Empty, parsers);
	};
};
var $elm$parser$Parser$Advanced$succeed = function (a) {
	return function (s) {
		return A3($elm$parser$Parser$Advanced$Good, false, a, s);
	};
};
var $elm$parser$Parser$Advanced$AddRight = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $elm$parser$Parser$Advanced$DeadEnd = F4(
	function (row, col, problem, contextStack) {
		return {bO: col, c1: contextStack, dM: problem, dT: row};
	});
var $elm$parser$Parser$Advanced$fromState = F2(
	function (s, x) {
		return A2(
			$elm$parser$Parser$Advanced$AddRight,
			$elm$parser$Parser$Advanced$Empty,
			A4($elm$parser$Parser$Advanced$DeadEnd, s.dT, s.bO, x, s.h));
	});
var $elm$parser$Parser$Advanced$isSubString = _Parser_isSubString;
var $elm$parser$Parser$Advanced$token = function (_v0) {
	var str = _v0.a;
	var expecting = _v0.b;
	var progress = !$elm$core$String$isEmpty(str);
	return function (s) {
		var _v1 = A5($elm$parser$Parser$Advanced$isSubString, str, s.e, s.dT, s.bO, s.bq);
		var newOffset = _v1.a;
		var newRow = _v1.b;
		var newCol = _v1.c;
		return _Utils_eq(newOffset, -1) ? A2(
			$elm$parser$Parser$Advanced$Bad,
			false,
			A2($elm$parser$Parser$Advanced$fromState, s, expecting)) : A3(
			$elm$parser$Parser$Advanced$Good,
			progress,
			0,
			{bO: newCol, h: s.h, j: s.j, e: newOffset, dT: newRow, bq: s.bq});
	};
};
var $dillonkearns$elm_markdown$Whitespace$lineEnd = $elm$parser$Parser$Advanced$oneOf(
	_List_fromArray(
		[
			$elm$parser$Parser$Advanced$token($dillonkearns$elm_markdown$Parser$Token$newline),
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$token($dillonkearns$elm_markdown$Parser$Token$carriageReturn),
			$elm$parser$Parser$Advanced$oneOf(
				_List_fromArray(
					[
						$elm$parser$Parser$Advanced$token($dillonkearns$elm_markdown$Parser$Token$newline),
						$elm$parser$Parser$Advanced$succeed(0)
					])))
		]));
var $elm$parser$Parser$Advanced$map = F2(
	function (func, _v0) {
		var parse = _v0;
		return function (s0) {
			var _v1 = parse(s0);
			if (!_v1.$) {
				var p = _v1.a;
				var a = _v1.b;
				var s1 = _v1.c;
				return A3(
					$elm$parser$Parser$Advanced$Good,
					p,
					func(a),
					s1);
			} else {
				var p = _v1.a;
				var x = _v1.b;
				return A2($elm$parser$Parser$Advanced$Bad, p, x);
			}
		};
	});
var $dillonkearns$elm_markdown$Markdown$Parser$blankLine = A2(
	$elm$parser$Parser$Advanced$map,
	function (_v0) {
		return $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine;
	},
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$backtrackable(
			$elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$Whitespace$isSpaceOrTab)),
		$dillonkearns$elm_markdown$Whitespace$lineEnd));
var $dillonkearns$elm_markdown$Parser$Token$space = A2(
	$elm$parser$Parser$Advanced$Token,
	' ',
	$elm$parser$Parser$Expecting('a space'));
var $elm$parser$Parser$Advanced$symbol = $elm$parser$Parser$Advanced$token;
var $dillonkearns$elm_markdown$Markdown$Parser$blockQuoteStarts = _List_fromArray(
	[
		$elm$parser$Parser$Advanced$symbol(
		A2(
			$elm$parser$Parser$Advanced$Token,
			'>',
			$elm$parser$Parser$Expecting('>'))),
		A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$backtrackable(
			$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$space)),
		$elm$parser$Parser$Advanced$oneOf(
			_List_fromArray(
				[
					$elm$parser$Parser$Advanced$symbol(
					A2(
						$elm$parser$Parser$Advanced$Token,
						'>',
						$elm$parser$Parser$Expecting(' >'))),
					$elm$parser$Parser$Advanced$symbol(
					A2(
						$elm$parser$Parser$Advanced$Token,
						' >',
						$elm$parser$Parser$Expecting('  >'))),
					$elm$parser$Parser$Advanced$symbol(
					A2(
						$elm$parser$Parser$Advanced$Token,
						'  >',
						$elm$parser$Parser$Expecting('   >')))
				])))
	]);
var $dillonkearns$elm_markdown$Whitespace$isLineEnd = function (_char) {
	switch (_char) {
		case '\n':
			return true;
		case '\u000D':
			return true;
		default:
			return false;
	}
};
var $dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd = $elm$parser$Parser$Advanced$chompWhile(
	A2($elm$core$Basics$composeL, $elm$core$Basics$not, $dillonkearns$elm_markdown$Whitespace$isLineEnd));
var $elm$parser$Parser$Advanced$mapChompedString = F2(
	function (func, _v0) {
		var parse = _v0;
		return function (s0) {
			var _v1 = parse(s0);
			if (_v1.$ === 1) {
				var p = _v1.a;
				var x = _v1.b;
				return A2($elm$parser$Parser$Advanced$Bad, p, x);
			} else {
				var p = _v1.a;
				var a = _v1.b;
				var s1 = _v1.c;
				return A3(
					$elm$parser$Parser$Advanced$Good,
					p,
					A2(
						func,
						A3($elm$core$String$slice, s0.e, s1.e, s0.bq),
						a),
					s1);
			}
		};
	});
var $elm$parser$Parser$Advanced$getChompedString = function (parser) {
	return A2($elm$parser$Parser$Advanced$mapChompedString, $elm$core$Basics$always, parser);
};
var $elm$parser$Parser$Advanced$keeper = F2(
	function (parseFunc, parseArg) {
		return A3($elm$parser$Parser$Advanced$map2, $elm$core$Basics$apL, parseFunc, parseArg);
	});
var $elm$parser$Parser$Advanced$end = function (x) {
	return function (s) {
		return _Utils_eq(
			$elm$core$String$length(s.bq),
			s.e) ? A3($elm$parser$Parser$Advanced$Good, false, 0, s) : A2(
			$elm$parser$Parser$Advanced$Bad,
			false,
			A2($elm$parser$Parser$Advanced$fromState, s, x));
	};
};
var $dillonkearns$elm_markdown$Helpers$endOfFile = $elm$parser$Parser$Advanced$end(
	$elm$parser$Parser$Expecting('the end of the input'));
var $dillonkearns$elm_markdown$Helpers$lineEndOrEnd = $elm$parser$Parser$Advanced$oneOf(
	_List_fromArray(
		[$dillonkearns$elm_markdown$Whitespace$lineEnd, $dillonkearns$elm_markdown$Helpers$endOfFile]));
var $dillonkearns$elm_markdown$Markdown$Parser$blockQuote = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed($dillonkearns$elm_markdown$Markdown$RawBlock$BlockQuote),
			$elm$parser$Parser$Advanced$oneOf($dillonkearns$elm_markdown$Markdown$Parser$blockQuoteStarts)),
		$elm$parser$Parser$Advanced$oneOf(
			_List_fromArray(
				[
					$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$space),
					$elm$parser$Parser$Advanced$succeed(0)
				]))),
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$getChompedString($dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd),
		$dillonkearns$elm_markdown$Helpers$lineEndOrEnd));
var $elm$core$List$append = F2(
	function (xs, ys) {
		if (!ys.b) {
			return xs;
		} else {
			return A3($elm$core$List$foldr, $elm$core$List$cons, ys, xs);
		}
	});
var $elm$core$List$concat = function (lists) {
	return A3($elm$core$List$foldr, $elm$core$List$append, _List_Nil, lists);
};
var $elm$core$List$concatMap = F2(
	function (f, list) {
		return $elm$core$List$concat(
			A2($elm$core$List$map, f, list));
	});
var $dillonkearns$elm_markdown$Markdown$Parser$problemToString = function (problem) {
	switch (problem.$) {
		case 0:
			var string = problem.a;
			return 'Expecting ' + string;
		case 1:
			return 'Expecting int';
		case 2:
			return 'Expecting hex';
		case 3:
			return 'Expecting octal';
		case 4:
			return 'Expecting binary';
		case 5:
			return 'Expecting float';
		case 6:
			return 'Expecting number';
		case 7:
			return 'Expecting variable';
		case 8:
			var string = problem.a;
			return 'Expecting symbol ' + string;
		case 9:
			var string = problem.a;
			return 'Expecting keyword ' + string;
		case 10:
			return 'Expecting keyword end';
		case 11:
			return 'Unexpected char';
		case 12:
			var problemDescription = problem.a;
			return problemDescription;
		default:
			return 'Bad repeat';
	}
};
var $dillonkearns$elm_markdown$Markdown$Parser$deadEndToString = function (deadEnd) {
	return 'Problem at row ' + ($elm$core$String$fromInt(deadEnd.dT) + ('\n' + $dillonkearns$elm_markdown$Markdown$Parser$problemToString(deadEnd.dM)));
};
var $dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString = function (deadEnds) {
	return A2(
		$elm$core$String$join,
		'\n',
		A2($elm$core$List$map, $dillonkearns$elm_markdown$Markdown$Parser$deadEndToString, deadEnds));
};
var $elm$core$String$endsWith = _String_endsWith;
var $dillonkearns$elm_markdown$Markdown$Parser$endWithOpenBlockOrParagraph = function (block) {
	endWithOpenBlockOrParagraph:
	while (true) {
		switch (block.$) {
			case 1:
				var str = block.a;
				return !A2($elm$core$String$endsWith, str, '\n');
			case 12:
				var blocks = block.a;
				if (blocks.b) {
					var last = blocks.a;
					var $temp$block = last;
					block = $temp$block;
					continue endWithOpenBlockOrParagraph;
				} else {
					return false;
				}
			case 4:
				var blockslist = block.e;
				if (blockslist.b) {
					var blocks = blockslist.a;
					if (blocks.b) {
						var last = blocks.a;
						var $temp$block = last;
						block = $temp$block;
						continue endWithOpenBlockOrParagraph;
					} else {
						return false;
					}
				} else {
					return false;
				}
			case 0:
				return true;
			default:
				return false;
		}
	}
};
var $dillonkearns$elm_markdown$HtmlParser$Cdata = function (a) {
	return {$: 3, a: a};
};
var $dillonkearns$elm_markdown$HtmlParser$Element = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $dillonkearns$elm_markdown$HtmlParser$Text = function (a) {
	return {$: 1, a: a};
};
var $elm$parser$Parser$Advanced$chompIf = F2(
	function (isGood, expecting) {
		return function (s) {
			var newOffset = A3($elm$parser$Parser$Advanced$isSubChar, isGood, s.e, s.bq);
			return _Utils_eq(newOffset, -1) ? A2(
				$elm$parser$Parser$Advanced$Bad,
				false,
				A2($elm$parser$Parser$Advanced$fromState, s, expecting)) : (_Utils_eq(newOffset, -2) ? A3(
				$elm$parser$Parser$Advanced$Good,
				true,
				0,
				{bO: 1, h: s.h, j: s.j, e: s.e + 1, dT: s.dT + 1, bq: s.bq}) : A3(
				$elm$parser$Parser$Advanced$Good,
				true,
				0,
				{bO: s.bO + 1, h: s.h, j: s.j, e: newOffset, dT: s.dT, bq: s.bq}));
		};
	});
var $dillonkearns$elm_markdown$HtmlParser$expectTagNameCharacter = $elm$parser$Parser$Expecting('at least 1 tag name character');
var $dillonkearns$elm_markdown$HtmlParser$tagNameCharacter = function (c) {
	switch (c) {
		case ' ':
			return false;
		case '\u000D':
			return false;
		case '\n':
			return false;
		case '\t':
			return false;
		case '/':
			return false;
		case '<':
			return false;
		case '>':
			return false;
		case '\"':
			return false;
		case '\'':
			return false;
		case '=':
			return false;
		default:
			return true;
	}
};
var $dillonkearns$elm_markdown$HtmlParser$tagName = A2(
	$elm$parser$Parser$Advanced$mapChompedString,
	F2(
		function (name, _v0) {
			return $elm$core$String$toLower(name);
		}),
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		A2($elm$parser$Parser$Advanced$chompIf, $dillonkearns$elm_markdown$HtmlParser$tagNameCharacter, $dillonkearns$elm_markdown$HtmlParser$expectTagNameCharacter),
		$elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$HtmlParser$tagNameCharacter)));
var $dillonkearns$elm_markdown$HtmlParser$attributeName = $dillonkearns$elm_markdown$HtmlParser$tagName;
var $dillonkearns$elm_markdown$HtmlParser$symbol = function (str) {
	return $elm$parser$Parser$Advanced$token(
		A2(
			$elm$parser$Parser$Advanced$Token,
			str,
			$elm$parser$Parser$ExpectingSymbol(str)));
};
var $elm$parser$Parser$Advanced$loopHelp = F4(
	function (p, state, callback, s0) {
		loopHelp:
		while (true) {
			var _v0 = callback(state);
			var parse = _v0;
			var _v1 = parse(s0);
			if (!_v1.$) {
				var p1 = _v1.a;
				var step = _v1.b;
				var s1 = _v1.c;
				if (!step.$) {
					var newState = step.a;
					var $temp$p = p || p1,
						$temp$state = newState,
						$temp$callback = callback,
						$temp$s0 = s1;
					p = $temp$p;
					state = $temp$state;
					callback = $temp$callback;
					s0 = $temp$s0;
					continue loopHelp;
				} else {
					var result = step.a;
					return A3($elm$parser$Parser$Advanced$Good, p || p1, result, s1);
				}
			} else {
				var p1 = _v1.a;
				var x = _v1.b;
				return A2($elm$parser$Parser$Advanced$Bad, p || p1, x);
			}
		}
	});
var $elm$parser$Parser$Advanced$loop = F2(
	function (state, callback) {
		return function (s) {
			return A4($elm$parser$Parser$Advanced$loopHelp, false, state, callback, s);
		};
	});
var $dillonkearns$elm_markdown$HtmlParser$entities = $elm$core$Dict$fromList(
	_List_fromArray(
		[
			_Utils_Tuple2('amp', '&'),
			_Utils_Tuple2('lt', '<'),
			_Utils_Tuple2('gt', '>'),
			_Utils_Tuple2('apos', '\''),
			_Utils_Tuple2('quot', '\"')
		]));
var $elm$core$Char$fromCode = _Char_fromCode;
var $elm$core$Result$fromMaybe = F2(
	function (err, maybe) {
		if (!maybe.$) {
			var v = maybe.a;
			return $elm$core$Result$Ok(v);
		} else {
			return $elm$core$Result$Err(err);
		}
	});
var $elm$core$String$cons = _String_cons;
var $elm$core$String$fromChar = function (_char) {
	return A2($elm$core$String$cons, _char, '');
};
var $elm$core$Basics$pow = _Basics_pow;
var $rtfeldman$elm_hex$Hex$fromStringHelp = F3(
	function (position, chars, accumulated) {
		fromStringHelp:
		while (true) {
			if (!chars.b) {
				return $elm$core$Result$Ok(accumulated);
			} else {
				var _char = chars.a;
				var rest = chars.b;
				switch (_char) {
					case '0':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated;
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '1':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + A2($elm$core$Basics$pow, 16, position);
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '2':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (2 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '3':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (3 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '4':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (4 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '5':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (5 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '6':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (6 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '7':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (7 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '8':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (8 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case '9':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (9 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'a':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (10 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'b':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (11 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'c':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (12 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'd':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (13 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'e':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (14 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					case 'f':
						var $temp$position = position - 1,
							$temp$chars = rest,
							$temp$accumulated = accumulated + (15 * A2($elm$core$Basics$pow, 16, position));
						position = $temp$position;
						chars = $temp$chars;
						accumulated = $temp$accumulated;
						continue fromStringHelp;
					default:
						var nonHex = _char;
						return $elm$core$Result$Err(
							$elm$core$String$fromChar(nonHex) + ' is not a valid hexadecimal character.');
				}
			}
		}
	});
var $elm$core$Result$map = F2(
	function (func, ra) {
		if (!ra.$) {
			var a = ra.a;
			return $elm$core$Result$Ok(
				func(a));
		} else {
			var e = ra.a;
			return $elm$core$Result$Err(e);
		}
	});
var $elm$core$List$tail = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(xs);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$String$foldr = _String_foldr;
var $elm$core$String$toList = function (string) {
	return A3($elm$core$String$foldr, $elm$core$List$cons, _List_Nil, string);
};
var $rtfeldman$elm_hex$Hex$fromString = function (str) {
	if ($elm$core$String$isEmpty(str)) {
		return $elm$core$Result$Err('Empty strings are not valid hexadecimal strings.');
	} else {
		var result = function () {
			if (A2($elm$core$String$startsWith, '-', str)) {
				var list = A2(
					$elm$core$Maybe$withDefault,
					_List_Nil,
					$elm$core$List$tail(
						$elm$core$String$toList(str)));
				return A2(
					$elm$core$Result$map,
					$elm$core$Basics$negate,
					A3(
						$rtfeldman$elm_hex$Hex$fromStringHelp,
						$elm$core$List$length(list) - 1,
						list,
						0));
			} else {
				return A3(
					$rtfeldman$elm_hex$Hex$fromStringHelp,
					$elm$core$String$length(str) - 1,
					$elm$core$String$toList(str),
					0);
			}
		}();
		var formatError = function (err) {
			return A2(
				$elm$core$String$join,
				' ',
				_List_fromArray(
					['\"' + (str + '\"'), 'is not a valid hexadecimal string because', err]));
		};
		return A2($elm$core$Result$mapError, formatError, result);
	}
};
var $dillonkearns$elm_markdown$HtmlParser$decodeEscape = function (s) {
	return A2($elm$core$String$startsWith, '#x', s) ? A2(
		$elm$core$Result$mapError,
		$elm$parser$Parser$Problem,
		A2(
			$elm$core$Result$map,
			$elm$core$Char$fromCode,
			$rtfeldman$elm_hex$Hex$fromString(
				A2($elm$core$String$dropLeft, 2, s)))) : (A2($elm$core$String$startsWith, '#', s) ? A2(
		$elm$core$Result$fromMaybe,
		$elm$parser$Parser$Problem('Invalid escaped character: ' + s),
		A2(
			$elm$core$Maybe$map,
			$elm$core$Char$fromCode,
			$elm$core$String$toInt(
				A2($elm$core$String$dropLeft, 1, s)))) : A2(
		$elm$core$Result$fromMaybe,
		$elm$parser$Parser$Problem('No entity named \"&' + (s + ';\" found.')),
		A2($elm$core$Dict$get, s, $dillonkearns$elm_markdown$HtmlParser$entities)));
};
var $elm$parser$Parser$Advanced$problem = function (x) {
	return function (s) {
		return A2(
			$elm$parser$Parser$Advanced$Bad,
			false,
			A2($elm$parser$Parser$Advanced$fromState, s, x));
	};
};
var $dillonkearns$elm_markdown$HtmlParser$escapedChar = function (end_) {
	var process = function (entityStr) {
		var _v0 = $dillonkearns$elm_markdown$HtmlParser$decodeEscape(entityStr);
		if (!_v0.$) {
			var c = _v0.a;
			return $elm$parser$Parser$Advanced$succeed(c);
		} else {
			var e = _v0.a;
			return $elm$parser$Parser$Advanced$problem(e);
		}
	};
	var isEntityChar = function (c) {
		return (!_Utils_eq(c, end_)) && (c !== ';');
	};
	return A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
			$dillonkearns$elm_markdown$HtmlParser$symbol('&')),
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$andThen,
				process,
				$elm$parser$Parser$Advanced$getChompedString(
					A2(
						$elm$parser$Parser$Advanced$ignorer,
						A2(
							$elm$parser$Parser$Advanced$chompIf,
							isEntityChar,
							$elm$parser$Parser$Expecting('an entity character')),
						$elm$parser$Parser$Advanced$chompWhile(isEntityChar)))),
			$dillonkearns$elm_markdown$HtmlParser$symbol(';')));
};
var $dillonkearns$elm_markdown$HtmlParser$textStringStep = F3(
	function (closingChar, predicate, accum) {
		return A2(
			$elm$parser$Parser$Advanced$andThen,
			function (soFar) {
				return $elm$parser$Parser$Advanced$oneOf(
					_List_fromArray(
						[
							A2(
							$elm$parser$Parser$Advanced$map,
							function (escaped) {
								return $elm$parser$Parser$Advanced$Loop(
									_Utils_ap(
										accum,
										_Utils_ap(
											soFar,
											$elm$core$String$fromChar(escaped))));
							},
							$dillonkearns$elm_markdown$HtmlParser$escapedChar(closingChar)),
							$elm$parser$Parser$Advanced$succeed(
							$elm$parser$Parser$Advanced$Done(
								_Utils_ap(accum, soFar)))
						]));
			},
			$elm$parser$Parser$Advanced$getChompedString(
				$elm$parser$Parser$Advanced$chompWhile(predicate)));
	});
var $dillonkearns$elm_markdown$HtmlParser$textString = function (closingChar) {
	var predicate = function (c) {
		return (!_Utils_eq(c, closingChar)) && (c !== '&');
	};
	return A2(
		$elm$parser$Parser$Advanced$loop,
		'',
		A2($dillonkearns$elm_markdown$HtmlParser$textStringStep, closingChar, predicate));
};
var $dillonkearns$elm_markdown$HtmlParser$attributeValue = $elm$parser$Parser$Advanced$oneOf(
	_List_fromArray(
		[
			A2(
			$elm$parser$Parser$Advanced$keeper,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
				$dillonkearns$elm_markdown$HtmlParser$symbol('\"')),
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				$dillonkearns$elm_markdown$HtmlParser$textString('\"'),
				$dillonkearns$elm_markdown$HtmlParser$symbol('\"'))),
			A2(
			$elm$parser$Parser$Advanced$keeper,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
				$dillonkearns$elm_markdown$HtmlParser$symbol('\'')),
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				$dillonkearns$elm_markdown$HtmlParser$textString('\''),
				$dillonkearns$elm_markdown$HtmlParser$symbol('\'')))
		]));
var $dillonkearns$elm_markdown$HtmlParser$keepOldest = F2(
	function (_new, mValue) {
		if (!mValue.$) {
			var v = mValue.a;
			return $elm$core$Maybe$Just(v);
		} else {
			return $elm$core$Maybe$Just(_new);
		}
	});
var $dillonkearns$elm_markdown$HtmlParser$isWhitespace = function (c) {
	switch (c) {
		case ' ':
			return true;
		case '\u000D':
			return true;
		case '\n':
			return true;
		case '\t':
			return true;
		default:
			return false;
	}
};
var $dillonkearns$elm_markdown$HtmlParser$whiteSpace = $elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$HtmlParser$isWhitespace);
var $dillonkearns$elm_markdown$HtmlParser$attributesStep = function (attrs) {
	var process = F2(
		function (name, value) {
			return $elm$parser$Parser$Advanced$Loop(
				A3(
					$elm$core$Dict$update,
					$elm$core$String$toLower(name),
					$dillonkearns$elm_markdown$HtmlParser$keepOldest(value),
					attrs));
		});
	return $elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$parser$Parser$Advanced$keeper,
				A2(
					$elm$parser$Parser$Advanced$keeper,
					$elm$parser$Parser$Advanced$succeed(process),
					A2(
						$elm$parser$Parser$Advanced$ignorer,
						A2(
							$elm$parser$Parser$Advanced$ignorer,
							A2($elm$parser$Parser$Advanced$ignorer, $dillonkearns$elm_markdown$HtmlParser$attributeName, $dillonkearns$elm_markdown$HtmlParser$whiteSpace),
							$dillonkearns$elm_markdown$HtmlParser$symbol('=')),
						$dillonkearns$elm_markdown$HtmlParser$whiteSpace)),
				A2($elm$parser$Parser$Advanced$ignorer, $dillonkearns$elm_markdown$HtmlParser$attributeValue, $dillonkearns$elm_markdown$HtmlParser$whiteSpace)),
				$elm$parser$Parser$Advanced$succeed(
				$elm$parser$Parser$Advanced$Done(attrs))
			]));
};
var $dillonkearns$elm_markdown$HtmlParser$attributes = A2(
	$elm$parser$Parser$Advanced$map,
	A2(
		$elm$core$Dict$foldl,
		F3(
			function (key, value, accum) {
				return A2(
					$elm$core$List$cons,
					{ce: key, cL: value},
					accum);
			}),
		_List_Nil),
	A2($elm$parser$Parser$Advanced$loop, $elm$core$Dict$empty, $dillonkearns$elm_markdown$HtmlParser$attributesStep));
var $elm$parser$Parser$Advanced$chompUntilEndOr = function (str) {
	return function (s) {
		var _v0 = A5(_Parser_findSubString, str, s.e, s.dT, s.bO, s.bq);
		var newOffset = _v0.a;
		var newRow = _v0.b;
		var newCol = _v0.c;
		var adjustedOffset = (newOffset < 0) ? $elm$core$String$length(s.bq) : newOffset;
		return A3(
			$elm$parser$Parser$Advanced$Good,
			_Utils_cmp(s.e, adjustedOffset) < 0,
			0,
			{bO: newCol, h: s.h, j: s.j, e: adjustedOffset, dT: newRow, bq: s.bq});
	};
};
var $dillonkearns$elm_markdown$HtmlParser$cdata = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
		$dillonkearns$elm_markdown$HtmlParser$symbol('<![CDATA[')),
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$getChompedString(
			$elm$parser$Parser$Advanced$chompUntilEndOr(']]>')),
		$dillonkearns$elm_markdown$HtmlParser$symbol(']]>')));
var $dillonkearns$elm_markdown$HtmlParser$childrenStep = F2(
	function (options, accum) {
		return A2(
			$elm$parser$Parser$Advanced$map,
			function (f) {
				return f(accum);
			},
			$elm$parser$Parser$Advanced$oneOf(options));
	});
var $dillonkearns$elm_markdown$HtmlParser$fail = function (str) {
	return $elm$parser$Parser$Advanced$problem(
		$elm$parser$Parser$Problem(str));
};
var $dillonkearns$elm_markdown$HtmlParser$closingTag = function (startTagName) {
	var closingTagName = A2(
		$elm$parser$Parser$Advanced$andThen,
		function (endTagName) {
			return _Utils_eq(startTagName, endTagName) ? $elm$parser$Parser$Advanced$succeed(0) : $dillonkearns$elm_markdown$HtmlParser$fail('tag name mismatch: ' + (startTagName + (' and ' + endTagName)));
		},
		$dillonkearns$elm_markdown$HtmlParser$tagName);
	return A2(
		$elm$parser$Parser$Advanced$ignorer,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$dillonkearns$elm_markdown$HtmlParser$symbol('</'),
					$dillonkearns$elm_markdown$HtmlParser$whiteSpace),
				closingTagName),
			$dillonkearns$elm_markdown$HtmlParser$whiteSpace),
		$dillonkearns$elm_markdown$HtmlParser$symbol('>'));
};
var $dillonkearns$elm_markdown$HtmlParser$Comment = function (a) {
	return {$: 2, a: a};
};
var $dillonkearns$elm_markdown$HtmlParser$toToken = function (str) {
	return A2(
		$elm$parser$Parser$Advanced$Token,
		str,
		$elm$parser$Parser$Expecting(str));
};
var $dillonkearns$elm_markdown$HtmlParser$comment = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$succeed($dillonkearns$elm_markdown$HtmlParser$Comment),
		$elm$parser$Parser$Advanced$token(
			$dillonkearns$elm_markdown$HtmlParser$toToken('<!--'))),
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$getChompedString(
			$elm$parser$Parser$Advanced$chompUntilEndOr('-->')),
		$elm$parser$Parser$Advanced$token(
			$dillonkearns$elm_markdown$HtmlParser$toToken('-->'))));
var $dillonkearns$elm_markdown$HtmlParser$Declaration = F2(
	function (a, b) {
		return {$: 5, a: a, b: b};
	});
var $dillonkearns$elm_markdown$HtmlParser$expectUppercaseCharacter = $elm$parser$Parser$Expecting('at least 1 uppercase character');
var $dillonkearns$elm_markdown$HtmlParser$allUppercase = $elm$parser$Parser$Advanced$getChompedString(
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		A2($elm$parser$Parser$Advanced$chompIf, $elm$core$Char$isUpper, $dillonkearns$elm_markdown$HtmlParser$expectUppercaseCharacter),
		$elm$parser$Parser$Advanced$chompWhile($elm$core$Char$isUpper)));
var $dillonkearns$elm_markdown$HtmlParser$oneOrMoreWhiteSpace = A2(
	$elm$parser$Parser$Advanced$ignorer,
	A2(
		$elm$parser$Parser$Advanced$chompIf,
		$dillonkearns$elm_markdown$HtmlParser$isWhitespace,
		$elm$parser$Parser$Expecting('at least one whitespace')),
	$elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$HtmlParser$isWhitespace));
var $dillonkearns$elm_markdown$HtmlParser$docType = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed($dillonkearns$elm_markdown$HtmlParser$Declaration),
			$dillonkearns$elm_markdown$HtmlParser$symbol('<!')),
		A2($elm$parser$Parser$Advanced$ignorer, $dillonkearns$elm_markdown$HtmlParser$allUppercase, $dillonkearns$elm_markdown$HtmlParser$oneOrMoreWhiteSpace)),
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$getChompedString(
			$elm$parser$Parser$Advanced$chompUntilEndOr('>')),
		$dillonkearns$elm_markdown$HtmlParser$symbol('>')));
var $dillonkearns$elm_markdown$HtmlParser$ProcessingInstruction = function (a) {
	return {$: 4, a: a};
};
var $dillonkearns$elm_markdown$HtmlParser$processingInstruction = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$succeed($dillonkearns$elm_markdown$HtmlParser$ProcessingInstruction),
		$dillonkearns$elm_markdown$HtmlParser$symbol('<?')),
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$getChompedString(
			$elm$parser$Parser$Advanced$chompUntilEndOr('?>')),
		$dillonkearns$elm_markdown$HtmlParser$symbol('?>')));
var $dillonkearns$elm_markdown$HtmlParser$isNotTextNodeIgnoreChar = function (c) {
	switch (c) {
		case '<':
			return false;
		case '&':
			return false;
		default:
			return true;
	}
};
var $dillonkearns$elm_markdown$HtmlParser$textNodeStringStepOptions = _List_fromArray(
	[
		A2(
		$elm$parser$Parser$Advanced$map,
		function (_v0) {
			return $elm$parser$Parser$Advanced$Loop(0);
		},
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$chompIf,
				$dillonkearns$elm_markdown$HtmlParser$isNotTextNodeIgnoreChar,
				$elm$parser$Parser$Expecting('is not & or <')),
			$elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$HtmlParser$isNotTextNodeIgnoreChar))),
		A2(
		$elm$parser$Parser$Advanced$map,
		function (_v1) {
			return $elm$parser$Parser$Advanced$Loop(0);
		},
		$dillonkearns$elm_markdown$HtmlParser$escapedChar('<')),
		$elm$parser$Parser$Advanced$succeed(
		$elm$parser$Parser$Advanced$Done(0))
	]);
var $dillonkearns$elm_markdown$HtmlParser$textNodeStringStep = function (_v0) {
	return $elm$parser$Parser$Advanced$oneOf($dillonkearns$elm_markdown$HtmlParser$textNodeStringStepOptions);
};
var $dillonkearns$elm_markdown$HtmlParser$textNodeString = $elm$parser$Parser$Advanced$getChompedString(
	A2($elm$parser$Parser$Advanced$loop, 0, $dillonkearns$elm_markdown$HtmlParser$textNodeStringStep));
var $dillonkearns$elm_markdown$HtmlParser$children = function (startTagName) {
	return A2(
		$elm$parser$Parser$Advanced$loop,
		_List_Nil,
		$dillonkearns$elm_markdown$HtmlParser$childrenStep(
			$dillonkearns$elm_markdown$HtmlParser$childrenStepOptions(startTagName)));
};
var $dillonkearns$elm_markdown$HtmlParser$childrenStepOptions = function (startTagName) {
	return _List_fromArray(
		[
			A2(
			$elm$parser$Parser$Advanced$map,
			F2(
				function (_v1, accum) {
					return $elm$parser$Parser$Advanced$Done(
						$elm$core$List$reverse(accum));
				}),
			$dillonkearns$elm_markdown$HtmlParser$closingTag(startTagName)),
			A2(
			$elm$parser$Parser$Advanced$andThen,
			function (text) {
				return $elm$core$String$isEmpty(text) ? A2(
					$elm$parser$Parser$Advanced$map,
					F2(
						function (_v2, accum) {
							return $elm$parser$Parser$Advanced$Done(
								$elm$core$List$reverse(accum));
						}),
					$dillonkearns$elm_markdown$HtmlParser$closingTag(startTagName)) : $elm$parser$Parser$Advanced$succeed(
					function (accum) {
						return $elm$parser$Parser$Advanced$Loop(
							A2(
								$elm$core$List$cons,
								$dillonkearns$elm_markdown$HtmlParser$Text(text),
								accum));
					});
			},
			$dillonkearns$elm_markdown$HtmlParser$textNodeString),
			A2(
			$elm$parser$Parser$Advanced$map,
			F2(
				function (_new, accum) {
					return $elm$parser$Parser$Advanced$Loop(
						A2($elm$core$List$cons, _new, accum));
				}),
			$dillonkearns$elm_markdown$HtmlParser$cyclic$html())
		]);
};
var $dillonkearns$elm_markdown$HtmlParser$elementContinuation = function (startTagName) {
	return A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$keeper,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$succeed(
					$dillonkearns$elm_markdown$HtmlParser$Element(startTagName)),
				$dillonkearns$elm_markdown$HtmlParser$whiteSpace),
			A2($elm$parser$Parser$Advanced$ignorer, $dillonkearns$elm_markdown$HtmlParser$attributes, $dillonkearns$elm_markdown$HtmlParser$whiteSpace)),
		$elm$parser$Parser$Advanced$oneOf(
			_List_fromArray(
				[
					A2(
					$elm$parser$Parser$Advanced$map,
					function (_v0) {
						return _List_Nil;
					},
					$dillonkearns$elm_markdown$HtmlParser$symbol('/>')),
					A2(
					$elm$parser$Parser$Advanced$keeper,
					A2(
						$elm$parser$Parser$Advanced$ignorer,
						$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
						$dillonkearns$elm_markdown$HtmlParser$symbol('>')),
					$dillonkearns$elm_markdown$HtmlParser$children(startTagName))
				])));
};
function $dillonkearns$elm_markdown$HtmlParser$cyclic$html() {
	return $elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				A2($elm$parser$Parser$Advanced$map, $dillonkearns$elm_markdown$HtmlParser$Cdata, $dillonkearns$elm_markdown$HtmlParser$cdata),
				$dillonkearns$elm_markdown$HtmlParser$processingInstruction,
				$dillonkearns$elm_markdown$HtmlParser$comment,
				$dillonkearns$elm_markdown$HtmlParser$docType,
				$dillonkearns$elm_markdown$HtmlParser$cyclic$element()
			]));
}
function $dillonkearns$elm_markdown$HtmlParser$cyclic$element() {
	return A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
			$dillonkearns$elm_markdown$HtmlParser$symbol('<')),
		A2($elm$parser$Parser$Advanced$andThen, $dillonkearns$elm_markdown$HtmlParser$elementContinuation, $dillonkearns$elm_markdown$HtmlParser$tagName));
}
var $dillonkearns$elm_markdown$HtmlParser$html = $dillonkearns$elm_markdown$HtmlParser$cyclic$html();
$dillonkearns$elm_markdown$HtmlParser$cyclic$html = function () {
	return $dillonkearns$elm_markdown$HtmlParser$html;
};
var $dillonkearns$elm_markdown$HtmlParser$element = $dillonkearns$elm_markdown$HtmlParser$cyclic$element();
$dillonkearns$elm_markdown$HtmlParser$cyclic$element = function () {
	return $dillonkearns$elm_markdown$HtmlParser$element;
};
var $dillonkearns$elm_markdown$Parser$Token$tab = A2(
	$elm$parser$Parser$Advanced$Token,
	'\t',
	$elm$parser$Parser$Expecting('a tab'));
var $dillonkearns$elm_markdown$Markdown$Parser$exactlyFourSpaces = $elm$parser$Parser$Advanced$oneOf(
	_List_fromArray(
		[
			$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$tab),
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$backtrackable(
				$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$space)),
			$elm$parser$Parser$Advanced$oneOf(
				_List_fromArray(
					[
						$elm$parser$Parser$Advanced$symbol(
						A2(
							$elm$parser$Parser$Advanced$Token,
							'   ',
							$elm$parser$Parser$ExpectingSymbol('Indentation'))),
						$elm$parser$Parser$Advanced$symbol(
						A2(
							$elm$parser$Parser$Advanced$Token,
							' \t',
							$elm$parser$Parser$ExpectingSymbol('Indentation'))),
						$elm$parser$Parser$Advanced$symbol(
						A2(
							$elm$parser$Parser$Advanced$Token,
							'  \t',
							$elm$parser$Parser$ExpectingSymbol('Indentation')))
					])))
		]));
var $dillonkearns$elm_markdown$Markdown$Parser$indentedCodeBlock = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$succeed($dillonkearns$elm_markdown$Markdown$RawBlock$IndentedCodeBlock),
		$dillonkearns$elm_markdown$Markdown$Parser$exactlyFourSpaces),
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$getChompedString($dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd),
		$dillonkearns$elm_markdown$Helpers$lineEndOrEnd));
var $elm$core$Basics$modBy = _Basics_modBy;
var $dillonkearns$elm_markdown$Markdown$Helpers$isEven = function (_int) {
	return !A2($elm$core$Basics$modBy, 2, _int);
};
var $dillonkearns$elm_markdown$Markdown$Block$Loose = 0;
var $dillonkearns$elm_markdown$Markdown$Block$Tight = 1;
var $dillonkearns$elm_markdown$Markdown$Parser$isTightBoolToListDisplay = function (isTight) {
	return isTight ? 1 : 0;
};
var $dillonkearns$elm_markdown$Markdown$Parser$joinRawStringsWith = F3(
	function (joinWith, string1, string2) {
		var _v0 = _Utils_Tuple2(string1, string2);
		if (_v0.a === '') {
			return string2;
		} else {
			if (_v0.b === '') {
				return string1;
			} else {
				return _Utils_ap(
					string1,
					_Utils_ap(joinWith, string2));
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$Parser$joinStringsPreserveAll = F2(
	function (string1, string2) {
		return string1 + ('\n' + string2);
	});
var $elm$core$Tuple$mapSecond = F2(
	function (func, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			x,
			func(y));
	});
var $dillonkearns$elm_markdown$Markdown$Parser$innerParagraphParser = A2(
	$elm$parser$Parser$Advanced$mapChompedString,
	F2(
		function (rawLine, _v0) {
			return $dillonkearns$elm_markdown$Markdown$RawBlock$OpenBlockOrParagraph(rawLine);
		}),
	$dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd);
var $dillonkearns$elm_markdown$Markdown$Parser$openBlockOrParagraphParser = A2($elm$parser$Parser$Advanced$ignorer, $dillonkearns$elm_markdown$Markdown$Parser$innerParagraphParser, $dillonkearns$elm_markdown$Helpers$lineEndOrEnd);
var $dillonkearns$elm_markdown$Markdown$OrderedList$ListItem = F4(
	function (order, intended, marker, body) {
		return {cW: body, dk: intended, dq: marker, dJ: order};
	});
var $elm$parser$Parser$Advanced$getCol = function (s) {
	return A3($elm$parser$Parser$Advanced$Good, false, s.bO, s);
};
var $dillonkearns$elm_markdown$Markdown$OrderedList$orderedListEmptyItemParser = A2(
	$elm$parser$Parser$Advanced$keeper,
	$elm$parser$Parser$Advanced$succeed(
		function (bodyStartPos) {
			return _Utils_Tuple2(bodyStartPos, '');
		}),
	A2($elm$parser$Parser$Advanced$ignorer, $elm$parser$Parser$Advanced$getCol, $dillonkearns$elm_markdown$Helpers$lineEndOrEnd));
var $dillonkearns$elm_markdown$Parser$Extra$chompOneOrMore = function (condition) {
	return A2(
		$elm$parser$Parser$Advanced$ignorer,
		A2(
			$elm$parser$Parser$Advanced$chompIf,
			condition,
			$elm$parser$Parser$Problem('Expected one or more character')),
		$elm$parser$Parser$Advanced$chompWhile(condition));
};
var $dillonkearns$elm_markdown$Markdown$OrderedList$orderedListItemBodyParser = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed(
				F2(
					function (bodyStartPos, item) {
						return _Utils_Tuple2(bodyStartPos, item);
					})),
			$dillonkearns$elm_markdown$Parser$Extra$chompOneOrMore($dillonkearns$elm_markdown$Whitespace$isSpaceOrTab)),
		$elm$parser$Parser$Advanced$getCol),
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$getChompedString($dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd),
		$dillonkearns$elm_markdown$Helpers$lineEndOrEnd));
var $dillonkearns$elm_markdown$Markdown$OrderedList$Dot = 0;
var $dillonkearns$elm_markdown$Markdown$OrderedList$Paren = 1;
var $dillonkearns$elm_markdown$Parser$Token$closingParen = A2(
	$elm$parser$Parser$Advanced$Token,
	')',
	$elm$parser$Parser$Expecting('a `)`'));
var $dillonkearns$elm_markdown$Parser$Token$dot = A2(
	$elm$parser$Parser$Advanced$Token,
	'.',
	$elm$parser$Parser$Expecting('a `.`'));
var $dillonkearns$elm_markdown$Markdown$OrderedList$orderedListMarkerParser = $elm$parser$Parser$Advanced$oneOf(
	_List_fromArray(
		[
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed(0),
			$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$dot)),
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed(1),
			$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$closingParen))
		]));
var $dillonkearns$elm_markdown$Parser$Extra$positiveInteger = A2(
	$elm$parser$Parser$Advanced$mapChompedString,
	F2(
		function (str, _v0) {
			return A2(
				$elm$core$Maybe$withDefault,
				0,
				$elm$core$String$toInt(str));
		}),
	$dillonkearns$elm_markdown$Parser$Extra$chompOneOrMore($elm$core$Char$isDigit));
var $dillonkearns$elm_markdown$Markdown$OrderedList$positiveIntegerMaxOf9Digits = A2(
	$elm$parser$Parser$Advanced$andThen,
	function (parsed) {
		return (parsed <= 999999999) ? $elm$parser$Parser$Advanced$succeed(parsed) : $elm$parser$Parser$Advanced$problem(
			$elm$parser$Parser$Problem('Starting numbers must be nine digits or less.'));
	},
	$dillonkearns$elm_markdown$Parser$Extra$positiveInteger);
var $dillonkearns$elm_markdown$Whitespace$space = $elm$parser$Parser$Advanced$token($dillonkearns$elm_markdown$Parser$Token$space);
var $elm$core$List$repeatHelp = F3(
	function (result, n, value) {
		repeatHelp:
		while (true) {
			if (n <= 0) {
				return result;
			} else {
				var $temp$result = A2($elm$core$List$cons, value, result),
					$temp$n = n - 1,
					$temp$value = value;
				result = $temp$result;
				n = $temp$n;
				value = $temp$value;
				continue repeatHelp;
			}
		}
	});
var $elm$core$List$repeat = F2(
	function (n, value) {
		return A3($elm$core$List$repeatHelp, _List_Nil, n, value);
	});
var $dillonkearns$elm_markdown$Parser$Extra$upTo = F2(
	function (n, parser) {
		var _v0 = A2($elm$core$List$repeat, n, parser);
		if (!_v0.b) {
			return $elm$parser$Parser$Advanced$succeed(0);
		} else {
			var firstParser = _v0.a;
			var remainingParsers = _v0.b;
			return A3(
				$elm$core$List$foldl,
				F2(
					function (p, parsers) {
						return $elm$parser$Parser$Advanced$oneOf(
							_List_fromArray(
								[
									A2($elm$parser$Parser$Advanced$ignorer, p, parsers),
									$elm$parser$Parser$Advanced$succeed(0)
								]));
					}),
				$elm$parser$Parser$Advanced$oneOf(
					_List_fromArray(
						[
							firstParser,
							$elm$parser$Parser$Advanced$succeed(0)
						])),
				remainingParsers);
		}
	});
var $dillonkearns$elm_markdown$Markdown$OrderedList$validateStartsWith1 = function (parsed) {
	if (parsed === 1) {
		return $elm$parser$Parser$Advanced$succeed(parsed);
	} else {
		return $elm$parser$Parser$Advanced$problem(
			$elm$parser$Parser$Problem('Lists inside a paragraph or after a paragraph without a blank line must start with 1'));
	}
};
var $dillonkearns$elm_markdown$Markdown$OrderedList$orderedListOrderParser = function (previousWasBody) {
	return previousWasBody ? A2(
		$elm$parser$Parser$Advanced$andThen,
		$dillonkearns$elm_markdown$Markdown$OrderedList$validateStartsWith1,
		A2(
			$elm$parser$Parser$Advanced$keeper,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
				A2($dillonkearns$elm_markdown$Parser$Extra$upTo, 3, $dillonkearns$elm_markdown$Whitespace$space)),
			$dillonkearns$elm_markdown$Markdown$OrderedList$positiveIntegerMaxOf9Digits)) : A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
			A2($dillonkearns$elm_markdown$Parser$Extra$upTo, 3, $dillonkearns$elm_markdown$Whitespace$space)),
		$dillonkearns$elm_markdown$Markdown$OrderedList$positiveIntegerMaxOf9Digits);
};
var $elm$core$Bitwise$shiftRightBy = _Bitwise_shiftRightBy;
var $elm$core$String$repeatHelp = F3(
	function (n, chunk, result) {
		return (n <= 0) ? result : A3(
			$elm$core$String$repeatHelp,
			n >> 1,
			_Utils_ap(chunk, chunk),
			(!(n & 1)) ? result : _Utils_ap(result, chunk));
	});
var $elm$core$String$repeat = F2(
	function (n, chunk) {
		return A3($elm$core$String$repeatHelp, n, chunk, '');
	});
var $dillonkearns$elm_markdown$Markdown$OrderedList$parser = function (previousWasBody) {
	var parseSubsequentItem = F5(
		function (start, order, marker, mid, _v0) {
			var end = _v0.a;
			var body = _v0.b;
			return ((end - mid) <= 4) ? A4($dillonkearns$elm_markdown$Markdown$OrderedList$ListItem, order, end - start, marker, body) : A4(
				$dillonkearns$elm_markdown$Markdown$OrderedList$ListItem,
				order,
				(mid - start) + 1,
				marker,
				_Utils_ap(
					A2($elm$core$String$repeat, (end - mid) - 1, ' '),
					body));
		});
	return A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$keeper,
			A2(
				$elm$parser$Parser$Advanced$keeper,
				A2(
					$elm$parser$Parser$Advanced$keeper,
					A2(
						$elm$parser$Parser$Advanced$keeper,
						$elm$parser$Parser$Advanced$succeed(parseSubsequentItem),
						$elm$parser$Parser$Advanced$getCol),
					$elm$parser$Parser$Advanced$backtrackable(
						$dillonkearns$elm_markdown$Markdown$OrderedList$orderedListOrderParser(previousWasBody))),
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$Markdown$OrderedList$orderedListMarkerParser)),
			$elm$parser$Parser$Advanced$getCol),
		previousWasBody ? $dillonkearns$elm_markdown$Markdown$OrderedList$orderedListItemBodyParser : $elm$parser$Parser$Advanced$oneOf(
			_List_fromArray(
				[$dillonkearns$elm_markdown$Markdown$OrderedList$orderedListEmptyItemParser, $dillonkearns$elm_markdown$Markdown$OrderedList$orderedListItemBodyParser])));
};
var $dillonkearns$elm_markdown$Markdown$Parser$orderedListBlock = function (previousWasBody) {
	return A2(
		$elm$parser$Parser$Advanced$map,
		function (item) {
			return A6($dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock, true, item.dk, item.dq, item.dJ, _List_Nil, item.cW);
		},
		$dillonkearns$elm_markdown$Markdown$OrderedList$parser(previousWasBody));
};
var $dillonkearns$elm_markdown$Markdown$Inline$CodeInline = function (a) {
	return {$: 2, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Inline$HardLineBreak = {$: 1};
var $dillonkearns$elm_markdown$Markdown$Inline$HtmlInline = function (a) {
	return {$: 5, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Inline$Image = F3(
	function (a, b, c) {
		return {$: 4, a: a, b: b, c: c};
	});
var $dillonkearns$elm_markdown$Markdown$Inline$Link = F3(
	function (a, b, c) {
		return {$: 3, a: a, b: b, c: c};
	});
var $dillonkearns$elm_markdown$Markdown$Inline$Strikethrough = function (a) {
	return {$: 7, a: a};
};
var $dillonkearns$elm_markdown$Markdown$Inline$Text = function (a) {
	return {$: 0, a: a};
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$matchToInline = function (_v0) {
	var match = _v0;
	var _v1 = match.n;
	switch (_v1.$) {
		case 0:
			return $dillonkearns$elm_markdown$Markdown$Inline$Text(match.dX);
		case 1:
			return $dillonkearns$elm_markdown$Markdown$Inline$HardLineBreak;
		case 2:
			return $dillonkearns$elm_markdown$Markdown$Inline$CodeInline(match.dX);
		case 3:
			var _v2 = _v1.a;
			var text = _v2.a;
			var url = _v2.b;
			return A3(
				$dillonkearns$elm_markdown$Markdown$Inline$Link,
				url,
				$elm$core$Maybe$Nothing,
				_List_fromArray(
					[
						$dillonkearns$elm_markdown$Markdown$Inline$Text(text)
					]));
		case 4:
			var _v3 = _v1.a;
			var url = _v3.a;
			var maybeTitle = _v3.b;
			return A3(
				$dillonkearns$elm_markdown$Markdown$Inline$Link,
				url,
				maybeTitle,
				$dillonkearns$elm_markdown$Markdown$InlineParser$matchesToInlines(match.v));
		case 5:
			var _v4 = _v1.a;
			var url = _v4.a;
			var maybeTitle = _v4.b;
			return A3(
				$dillonkearns$elm_markdown$Markdown$Inline$Image,
				url,
				maybeTitle,
				$dillonkearns$elm_markdown$Markdown$InlineParser$matchesToInlines(match.v));
		case 6:
			var model = _v1.a;
			return $dillonkearns$elm_markdown$Markdown$Inline$HtmlInline(model);
		case 7:
			var length = _v1.a;
			return A2(
				$dillonkearns$elm_markdown$Markdown$Inline$Emphasis,
				length,
				$dillonkearns$elm_markdown$Markdown$InlineParser$matchesToInlines(match.v));
		default:
			return $dillonkearns$elm_markdown$Markdown$Inline$Strikethrough(
				$dillonkearns$elm_markdown$Markdown$InlineParser$matchesToInlines(match.v));
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$matchesToInlines = function (matches) {
	return A2($elm$core$List$map, $dillonkearns$elm_markdown$Markdown$InlineParser$matchToInline, matches);
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$Match = $elm$core$Basics$identity;
var $dillonkearns$elm_markdown$Markdown$InlineParser$prepareChildMatch = F2(
	function (parentMatch, childMatch) {
		return {i: childMatch.i - parentMatch.x, v: childMatch.v, k: childMatch.k - parentMatch.x, dX: childMatch.dX, I: childMatch.I - parentMatch.x, x: childMatch.x - parentMatch.x, n: childMatch.n};
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$addChild = F2(
	function (parentMatch, childMatch) {
		return {
			i: parentMatch.i,
			v: A2(
				$elm$core$List$cons,
				A2($dillonkearns$elm_markdown$Markdown$InlineParser$prepareChildMatch, parentMatch, childMatch),
				parentMatch.v),
			k: parentMatch.k,
			dX: parentMatch.dX,
			I: parentMatch.I,
			x: parentMatch.x,
			n: parentMatch.n
		};
	});
var $elm$core$List$sortBy = _List_sortBy;
var $dillonkearns$elm_markdown$Markdown$InlineParser$organizeChildren = function (_v4) {
	var match = _v4;
	return {
		i: match.i,
		v: $dillonkearns$elm_markdown$Markdown$InlineParser$organizeMatches(match.v),
		k: match.k,
		dX: match.dX,
		I: match.I,
		x: match.x,
		n: match.n
	};
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$organizeMatches = function (matches) {
	var _v2 = A2(
		$elm$core$List$sortBy,
		function (_v3) {
			var match = _v3;
			return match.k;
		},
		matches);
	if (!_v2.b) {
		return _List_Nil;
	} else {
		var first = _v2.a;
		var rest = _v2.b;
		return A3($dillonkearns$elm_markdown$Markdown$InlineParser$organizeMatchesHelp, rest, first, _List_Nil);
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$organizeMatchesHelp = F3(
	function (remaining, _v0, matchesTail) {
		organizeMatchesHelp:
		while (true) {
			var prevMatch = _v0;
			if (!remaining.b) {
				return A2(
					$elm$core$List$cons,
					$dillonkearns$elm_markdown$Markdown$InlineParser$organizeChildren(prevMatch),
					matchesTail);
			} else {
				var match = remaining.a;
				var rest = remaining.b;
				if (_Utils_cmp(prevMatch.i, match.k) < 1) {
					var $temp$remaining = rest,
						$temp$_v0 = match,
						$temp$matchesTail = A2(
						$elm$core$List$cons,
						$dillonkearns$elm_markdown$Markdown$InlineParser$organizeChildren(prevMatch),
						matchesTail);
					remaining = $temp$remaining;
					_v0 = $temp$_v0;
					matchesTail = $temp$matchesTail;
					continue organizeMatchesHelp;
				} else {
					if ((_Utils_cmp(prevMatch.k, match.k) < 0) && (_Utils_cmp(prevMatch.i, match.i) > 0)) {
						var $temp$remaining = rest,
							$temp$_v0 = A2($dillonkearns$elm_markdown$Markdown$InlineParser$addChild, prevMatch, match),
							$temp$matchesTail = matchesTail;
						remaining = $temp$remaining;
						_v0 = $temp$_v0;
						matchesTail = $temp$matchesTail;
						continue organizeMatchesHelp;
					} else {
						var $temp$remaining = rest,
							$temp$_v0 = prevMatch,
							$temp$matchesTail = matchesTail;
						remaining = $temp$remaining;
						_v0 = $temp$_v0;
						matchesTail = $temp$matchesTail;
						continue organizeMatchesHelp;
					}
				}
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$NormalType = {$: 0};
var $dillonkearns$elm_markdown$Markdown$Helpers$containsAmpersand = function (string) {
	return A2($elm$core$String$contains, '&', string);
};
var $elm$regex$Regex$Match = F4(
	function (match, index, number, submatches) {
		return {d: index, as: match, dE: number, bv: submatches};
	});
var $elm$regex$Regex$fromStringWith = _Regex_fromStringWith;
var $elm$regex$Regex$fromString = function (string) {
	return A2(
		$elm$regex$Regex$fromStringWith,
		{c$: false, du: false},
		string);
};
var $elm$regex$Regex$never = _Regex_never;
var $dillonkearns$elm_markdown$Markdown$Entity$decimalRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('&#([0-9]{1,8});'));
var $elm$regex$Regex$replace = _Regex_replaceAtMost(_Regex_infinity);
var $elm$core$Basics$ge = _Utils_ge;
var $dillonkearns$elm_markdown$Markdown$Entity$isBadEndUnicode = function (_int) {
	var remain_ = A2($elm$core$Basics$modBy, 16, _int);
	var remain = A2($elm$core$Basics$modBy, 131070, _int);
	return (_int >= 131070) && ((((0 <= remain) && (remain <= 15)) || ((65536 <= remain) && (remain <= 65551))) && ((remain_ === 14) || (remain_ === 15)));
};
var $dillonkearns$elm_markdown$Markdown$Entity$isValidUnicode = function (_int) {
	return (_int === 9) || ((_int === 10) || ((_int === 13) || ((_int === 133) || (((32 <= _int) && (_int <= 126)) || (((160 <= _int) && (_int <= 55295)) || (((57344 <= _int) && (_int <= 64975)) || (((65008 <= _int) && (_int <= 65533)) || ((65536 <= _int) && (_int <= 1114109)))))))));
};
var $dillonkearns$elm_markdown$Markdown$Entity$validUnicode = function (_int) {
	return ($dillonkearns$elm_markdown$Markdown$Entity$isValidUnicode(_int) && (!$dillonkearns$elm_markdown$Markdown$Entity$isBadEndUnicode(_int))) ? $elm$core$String$fromChar(
		$elm$core$Char$fromCode(_int)) : $elm$core$String$fromChar(
		$elm$core$Char$fromCode(65533));
};
var $dillonkearns$elm_markdown$Markdown$Entity$replaceDecimal = function (match) {
	var _v0 = match.bv;
	if (_v0.b && (!_v0.a.$)) {
		var first = _v0.a.a;
		var _v1 = $elm$core$String$toInt(first);
		if (!_v1.$) {
			var v = _v1.a;
			return $dillonkearns$elm_markdown$Markdown$Entity$validUnicode(v);
		} else {
			return match.as;
		}
	} else {
		return match.as;
	}
};
var $dillonkearns$elm_markdown$Markdown$Entity$replaceDecimals = A2($elm$regex$Regex$replace, $dillonkearns$elm_markdown$Markdown$Entity$decimalRegex, $dillonkearns$elm_markdown$Markdown$Entity$replaceDecimal);
var $dillonkearns$elm_markdown$Markdown$Entity$entitiesRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('&([0-9a-zA-Z]+);'));
var $dillonkearns$elm_markdown$Markdown$Entity$entities = $elm$core$Dict$fromList(
	_List_fromArray(
		[
			_Utils_Tuple2('quot', 34),
			_Utils_Tuple2('amp', 38),
			_Utils_Tuple2('apos', 39),
			_Utils_Tuple2('lt', 60),
			_Utils_Tuple2('gt', 62),
			_Utils_Tuple2('nbsp', 160),
			_Utils_Tuple2('iexcl', 161),
			_Utils_Tuple2('cent', 162),
			_Utils_Tuple2('pound', 163),
			_Utils_Tuple2('curren', 164),
			_Utils_Tuple2('yen', 165),
			_Utils_Tuple2('brvbar', 166),
			_Utils_Tuple2('sect', 167),
			_Utils_Tuple2('uml', 168),
			_Utils_Tuple2('copy', 169),
			_Utils_Tuple2('ordf', 170),
			_Utils_Tuple2('laquo', 171),
			_Utils_Tuple2('not', 172),
			_Utils_Tuple2('shy', 173),
			_Utils_Tuple2('reg', 174),
			_Utils_Tuple2('macr', 175),
			_Utils_Tuple2('deg', 176),
			_Utils_Tuple2('plusmn', 177),
			_Utils_Tuple2('sup2', 178),
			_Utils_Tuple2('sup3', 179),
			_Utils_Tuple2('acute', 180),
			_Utils_Tuple2('micro', 181),
			_Utils_Tuple2('para', 182),
			_Utils_Tuple2('middot', 183),
			_Utils_Tuple2('cedil', 184),
			_Utils_Tuple2('sup1', 185),
			_Utils_Tuple2('ordm', 186),
			_Utils_Tuple2('raquo', 187),
			_Utils_Tuple2('frac14', 188),
			_Utils_Tuple2('frac12', 189),
			_Utils_Tuple2('frac34', 190),
			_Utils_Tuple2('iquest', 191),
			_Utils_Tuple2('Agrave', 192),
			_Utils_Tuple2('Aacute', 193),
			_Utils_Tuple2('Acirc', 194),
			_Utils_Tuple2('Atilde', 195),
			_Utils_Tuple2('Auml', 196),
			_Utils_Tuple2('Aring', 197),
			_Utils_Tuple2('AElig', 198),
			_Utils_Tuple2('Ccedil', 199),
			_Utils_Tuple2('Egrave', 200),
			_Utils_Tuple2('Eacute', 201),
			_Utils_Tuple2('Ecirc', 202),
			_Utils_Tuple2('Euml', 203),
			_Utils_Tuple2('Igrave', 204),
			_Utils_Tuple2('Iacute', 205),
			_Utils_Tuple2('Icirc', 206),
			_Utils_Tuple2('Iuml', 207),
			_Utils_Tuple2('ETH', 208),
			_Utils_Tuple2('Ntilde', 209),
			_Utils_Tuple2('Ograve', 210),
			_Utils_Tuple2('Oacute', 211),
			_Utils_Tuple2('Ocirc', 212),
			_Utils_Tuple2('Otilde', 213),
			_Utils_Tuple2('Ouml', 214),
			_Utils_Tuple2('times', 215),
			_Utils_Tuple2('Oslash', 216),
			_Utils_Tuple2('Ugrave', 217),
			_Utils_Tuple2('Uacute', 218),
			_Utils_Tuple2('Ucirc', 219),
			_Utils_Tuple2('Uuml', 220),
			_Utils_Tuple2('Yacute', 221),
			_Utils_Tuple2('THORN', 222),
			_Utils_Tuple2('szlig', 223),
			_Utils_Tuple2('agrave', 224),
			_Utils_Tuple2('aacute', 225),
			_Utils_Tuple2('acirc', 226),
			_Utils_Tuple2('atilde', 227),
			_Utils_Tuple2('auml', 228),
			_Utils_Tuple2('aring', 229),
			_Utils_Tuple2('aelig', 230),
			_Utils_Tuple2('ccedil', 231),
			_Utils_Tuple2('egrave', 232),
			_Utils_Tuple2('eacute', 233),
			_Utils_Tuple2('ecirc', 234),
			_Utils_Tuple2('euml', 235),
			_Utils_Tuple2('igrave', 236),
			_Utils_Tuple2('iacute', 237),
			_Utils_Tuple2('icirc', 238),
			_Utils_Tuple2('iuml', 239),
			_Utils_Tuple2('eth', 240),
			_Utils_Tuple2('ntilde', 241),
			_Utils_Tuple2('ograve', 242),
			_Utils_Tuple2('oacute', 243),
			_Utils_Tuple2('ocirc', 244),
			_Utils_Tuple2('otilde', 245),
			_Utils_Tuple2('ouml', 246),
			_Utils_Tuple2('divide', 247),
			_Utils_Tuple2('oslash', 248),
			_Utils_Tuple2('ugrave', 249),
			_Utils_Tuple2('uacute', 250),
			_Utils_Tuple2('ucirc', 251),
			_Utils_Tuple2('uuml', 252),
			_Utils_Tuple2('yacute', 253),
			_Utils_Tuple2('thorn', 254),
			_Utils_Tuple2('yuml', 255),
			_Utils_Tuple2('OElig', 338),
			_Utils_Tuple2('oelig', 339),
			_Utils_Tuple2('Scaron', 352),
			_Utils_Tuple2('scaron', 353),
			_Utils_Tuple2('Yuml', 376),
			_Utils_Tuple2('fnof', 402),
			_Utils_Tuple2('circ', 710),
			_Utils_Tuple2('tilde', 732),
			_Utils_Tuple2('Alpha', 913),
			_Utils_Tuple2('Beta', 914),
			_Utils_Tuple2('Gamma', 915),
			_Utils_Tuple2('Delta', 916),
			_Utils_Tuple2('Epsilon', 917),
			_Utils_Tuple2('Zeta', 918),
			_Utils_Tuple2('Eta', 919),
			_Utils_Tuple2('Theta', 920),
			_Utils_Tuple2('Iota', 921),
			_Utils_Tuple2('Kappa', 922),
			_Utils_Tuple2('Lambda', 923),
			_Utils_Tuple2('Mu', 924),
			_Utils_Tuple2('Nu', 925),
			_Utils_Tuple2('Xi', 926),
			_Utils_Tuple2('Omicron', 927),
			_Utils_Tuple2('Pi', 928),
			_Utils_Tuple2('Rho', 929),
			_Utils_Tuple2('Sigma', 931),
			_Utils_Tuple2('Tau', 932),
			_Utils_Tuple2('Upsilon', 933),
			_Utils_Tuple2('Phi', 934),
			_Utils_Tuple2('Chi', 935),
			_Utils_Tuple2('Psi', 936),
			_Utils_Tuple2('Omega', 937),
			_Utils_Tuple2('alpha', 945),
			_Utils_Tuple2('beta', 946),
			_Utils_Tuple2('gamma', 947),
			_Utils_Tuple2('delta', 948),
			_Utils_Tuple2('epsilon', 949),
			_Utils_Tuple2('zeta', 950),
			_Utils_Tuple2('eta', 951),
			_Utils_Tuple2('theta', 952),
			_Utils_Tuple2('iota', 953),
			_Utils_Tuple2('kappa', 954),
			_Utils_Tuple2('lambda', 955),
			_Utils_Tuple2('mu', 956),
			_Utils_Tuple2('nu', 957),
			_Utils_Tuple2('xi', 958),
			_Utils_Tuple2('omicron', 959),
			_Utils_Tuple2('pi', 960),
			_Utils_Tuple2('rho', 961),
			_Utils_Tuple2('sigmaf', 962),
			_Utils_Tuple2('sigma', 963),
			_Utils_Tuple2('tau', 964),
			_Utils_Tuple2('upsilon', 965),
			_Utils_Tuple2('phi', 966),
			_Utils_Tuple2('chi', 967),
			_Utils_Tuple2('psi', 968),
			_Utils_Tuple2('omega', 969),
			_Utils_Tuple2('thetasym', 977),
			_Utils_Tuple2('upsih', 978),
			_Utils_Tuple2('piv', 982),
			_Utils_Tuple2('ensp', 8194),
			_Utils_Tuple2('emsp', 8195),
			_Utils_Tuple2('thinsp', 8201),
			_Utils_Tuple2('zwnj', 8204),
			_Utils_Tuple2('zwj', 8205),
			_Utils_Tuple2('lrm', 8206),
			_Utils_Tuple2('rlm', 8207),
			_Utils_Tuple2('ndash', 8211),
			_Utils_Tuple2('mdash', 8212),
			_Utils_Tuple2('lsquo', 8216),
			_Utils_Tuple2('rsquo', 8217),
			_Utils_Tuple2('sbquo', 8218),
			_Utils_Tuple2('ldquo', 8220),
			_Utils_Tuple2('rdquo', 8221),
			_Utils_Tuple2('bdquo', 8222),
			_Utils_Tuple2('dagger', 8224),
			_Utils_Tuple2('Dagger', 8225),
			_Utils_Tuple2('bull', 8226),
			_Utils_Tuple2('hellip', 8230),
			_Utils_Tuple2('permil', 8240),
			_Utils_Tuple2('prime', 8242),
			_Utils_Tuple2('Prime', 8243),
			_Utils_Tuple2('lsaquo', 8249),
			_Utils_Tuple2('rsaquo', 8250),
			_Utils_Tuple2('oline', 8254),
			_Utils_Tuple2('frasl', 8260),
			_Utils_Tuple2('euro', 8364),
			_Utils_Tuple2('image', 8465),
			_Utils_Tuple2('weierp', 8472),
			_Utils_Tuple2('real', 8476),
			_Utils_Tuple2('trade', 8482),
			_Utils_Tuple2('alefsym', 8501),
			_Utils_Tuple2('larr', 8592),
			_Utils_Tuple2('uarr', 8593),
			_Utils_Tuple2('rarr', 8594),
			_Utils_Tuple2('darr', 8595),
			_Utils_Tuple2('harr', 8596),
			_Utils_Tuple2('crarr', 8629),
			_Utils_Tuple2('lArr', 8656),
			_Utils_Tuple2('uArr', 8657),
			_Utils_Tuple2('rArr', 8658),
			_Utils_Tuple2('dArr', 8659),
			_Utils_Tuple2('hArr', 8660),
			_Utils_Tuple2('forall', 8704),
			_Utils_Tuple2('part', 8706),
			_Utils_Tuple2('exist', 8707),
			_Utils_Tuple2('empty', 8709),
			_Utils_Tuple2('nabla', 8711),
			_Utils_Tuple2('isin', 8712),
			_Utils_Tuple2('notin', 8713),
			_Utils_Tuple2('ni', 8715),
			_Utils_Tuple2('prod', 8719),
			_Utils_Tuple2('sum', 8721),
			_Utils_Tuple2('minus', 8722),
			_Utils_Tuple2('lowast', 8727),
			_Utils_Tuple2('radic', 8730),
			_Utils_Tuple2('prop', 8733),
			_Utils_Tuple2('infin', 8734),
			_Utils_Tuple2('ang', 8736),
			_Utils_Tuple2('and', 8743),
			_Utils_Tuple2('or', 8744),
			_Utils_Tuple2('cap', 8745),
			_Utils_Tuple2('cup', 8746),
			_Utils_Tuple2('int', 8747),
			_Utils_Tuple2('there4', 8756),
			_Utils_Tuple2('sim', 8764),
			_Utils_Tuple2('cong', 8773),
			_Utils_Tuple2('asymp', 8776),
			_Utils_Tuple2('ne', 8800),
			_Utils_Tuple2('equiv', 8801),
			_Utils_Tuple2('le', 8804),
			_Utils_Tuple2('ge', 8805),
			_Utils_Tuple2('sub', 8834),
			_Utils_Tuple2('sup', 8835),
			_Utils_Tuple2('nsub', 8836),
			_Utils_Tuple2('sube', 8838),
			_Utils_Tuple2('supe', 8839),
			_Utils_Tuple2('oplus', 8853),
			_Utils_Tuple2('otimes', 8855),
			_Utils_Tuple2('perp', 8869),
			_Utils_Tuple2('sdot', 8901),
			_Utils_Tuple2('lceil', 8968),
			_Utils_Tuple2('rceil', 8969),
			_Utils_Tuple2('lfloor', 8970),
			_Utils_Tuple2('rfloor', 8971),
			_Utils_Tuple2('lang', 9001),
			_Utils_Tuple2('rang', 9002),
			_Utils_Tuple2('loz', 9674),
			_Utils_Tuple2('spades', 9824),
			_Utils_Tuple2('clubs', 9827),
			_Utils_Tuple2('hearts', 9829),
			_Utils_Tuple2('diams', 9830)
		]));
var $dillonkearns$elm_markdown$Markdown$Entity$replaceEntity = function (match) {
	var _v0 = match.bv;
	if (_v0.b && (!_v0.a.$)) {
		var first = _v0.a.a;
		var _v1 = A2($elm$core$Dict$get, first, $dillonkearns$elm_markdown$Markdown$Entity$entities);
		if (!_v1.$) {
			var code = _v1.a;
			return $elm$core$String$fromChar(
				$elm$core$Char$fromCode(code));
		} else {
			return match.as;
		}
	} else {
		return match.as;
	}
};
var $dillonkearns$elm_markdown$Markdown$Entity$replaceEntities = A2($elm$regex$Regex$replace, $dillonkearns$elm_markdown$Markdown$Entity$entitiesRegex, $dillonkearns$elm_markdown$Markdown$Entity$replaceEntity);
var $dillonkearns$elm_markdown$Markdown$Helpers$escapableRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('(\\\\+)([!\"#$%&\\\'()*+,./:;<=>?@[\\\\\\]^_`{|}~-])'));
var $dillonkearns$elm_markdown$Markdown$Helpers$replaceEscapable = A2(
	$elm$regex$Regex$replace,
	$dillonkearns$elm_markdown$Markdown$Helpers$escapableRegex,
	function (regexMatch) {
		var _v0 = regexMatch.bv;
		if (((_v0.b && (!_v0.a.$)) && _v0.b.b) && (!_v0.b.a.$)) {
			var backslashes = _v0.a.a;
			var _v1 = _v0.b;
			var escapedStr = _v1.a.a;
			return _Utils_ap(
				A2(
					$elm$core$String$repeat,
					($elm$core$String$length(backslashes) / 2) | 0,
					'\\'),
				escapedStr);
		} else {
			return regexMatch.as;
		}
	});
var $dillonkearns$elm_markdown$Markdown$Entity$hexadecimalRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('&#[Xx]([0-9a-fA-F]{1,8});'));
var $elm$core$String$foldl = _String_foldl;
var $dillonkearns$elm_markdown$Markdown$Entity$hexToInt = function (string) {
	var folder = F2(
		function (hexDigit, _int) {
			return ((_int * 16) + A2(
				$elm$core$Basics$modBy,
				39,
				$elm$core$Char$toCode(hexDigit))) - 9;
		});
	return A3(
		$elm$core$String$foldl,
		folder,
		0,
		$elm$core$String$toLower(string));
};
var $dillonkearns$elm_markdown$Markdown$Entity$replaceHexadecimal = function (match) {
	var _v0 = match.bv;
	if (_v0.b && (!_v0.a.$)) {
		var first = _v0.a.a;
		return $dillonkearns$elm_markdown$Markdown$Entity$validUnicode(
			$dillonkearns$elm_markdown$Markdown$Entity$hexToInt(first));
	} else {
		return match.as;
	}
};
var $dillonkearns$elm_markdown$Markdown$Entity$replaceHexadecimals = A2($elm$regex$Regex$replace, $dillonkearns$elm_markdown$Markdown$Entity$hexadecimalRegex, $dillonkearns$elm_markdown$Markdown$Entity$replaceHexadecimal);
var $dillonkearns$elm_markdown$Markdown$Helpers$formatStr = function (str) {
	var withEscapes = $dillonkearns$elm_markdown$Markdown$Helpers$replaceEscapable(str);
	return $dillonkearns$elm_markdown$Markdown$Helpers$containsAmpersand(withEscapes) ? $dillonkearns$elm_markdown$Markdown$Entity$replaceHexadecimals(
		$dillonkearns$elm_markdown$Markdown$Entity$replaceDecimals(
			$dillonkearns$elm_markdown$Markdown$Entity$replaceEntities(withEscapes))) : withEscapes;
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$normalMatch = function (text) {
	return {
		i: 0,
		v: _List_Nil,
		k: 0,
		dX: $dillonkearns$elm_markdown$Markdown$Helpers$formatStr(text),
		I: 0,
		x: 0,
		n: $dillonkearns$elm_markdown$Markdown$InlineParser$NormalType
	};
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$parseTextMatch = F3(
	function (rawText, _v2, parsedMatches) {
		var matchModel = _v2;
		var updtMatch = {
			i: matchModel.i,
			v: A3($dillonkearns$elm_markdown$Markdown$InlineParser$parseTextMatches, matchModel.dX, _List_Nil, matchModel.v),
			k: matchModel.k,
			dX: matchModel.dX,
			I: matchModel.I,
			x: matchModel.x,
			n: matchModel.n
		};
		if (!parsedMatches.b) {
			var finalStr = A2($elm$core$String$dropLeft, matchModel.i, rawText);
			return $elm$core$String$isEmpty(finalStr) ? _List_fromArray(
				[updtMatch]) : _List_fromArray(
				[
					updtMatch,
					$dillonkearns$elm_markdown$Markdown$InlineParser$normalMatch(finalStr)
				]);
		} else {
			var matchHead = parsedMatches.a;
			var _v4 = matchHead.n;
			if (!_v4.$) {
				return A2($elm$core$List$cons, updtMatch, parsedMatches);
			} else {
				return _Utils_eq(matchModel.i, matchHead.k) ? A2($elm$core$List$cons, updtMatch, parsedMatches) : ((_Utils_cmp(matchModel.i, matchHead.k) < 0) ? A2(
					$elm$core$List$cons,
					updtMatch,
					A2(
						$elm$core$List$cons,
						$dillonkearns$elm_markdown$Markdown$InlineParser$normalMatch(
							A3($elm$core$String$slice, matchModel.i, matchHead.k, rawText)),
						parsedMatches)) : parsedMatches);
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$parseTextMatches = F3(
	function (rawText, parsedMatches, matches) {
		parseTextMatches:
		while (true) {
			if (!matches.b) {
				if (!parsedMatches.b) {
					return $elm$core$String$isEmpty(rawText) ? _List_Nil : _List_fromArray(
						[
							$dillonkearns$elm_markdown$Markdown$InlineParser$normalMatch(rawText)
						]);
				} else {
					var matchModel = parsedMatches.a;
					return (matchModel.k > 0) ? A2(
						$elm$core$List$cons,
						$dillonkearns$elm_markdown$Markdown$InlineParser$normalMatch(
							A2($elm$core$String$left, matchModel.k, rawText)),
						parsedMatches) : parsedMatches;
				}
			} else {
				var match = matches.a;
				var matchesTail = matches.b;
				var $temp$rawText = rawText,
					$temp$parsedMatches = A3($dillonkearns$elm_markdown$Markdown$InlineParser$parseTextMatch, rawText, match, parsedMatches),
					$temp$matches = matchesTail;
				rawText = $temp$rawText;
				parsedMatches = $temp$parsedMatches;
				matches = $temp$matches;
				continue parseTextMatches;
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$cleanAngleBracketTokens = F3(
	function (tokensL, tokensR, countL) {
		cleanAngleBracketTokens:
		while (true) {
			if (!tokensR.b) {
				return _List_Nil;
			} else {
				var hd1 = tokensR.a;
				var rest1 = tokensR.b;
				if (!tokensL.b) {
					if (countL > 1) {
						var $temp$tokensL = tokensL,
							$temp$tokensR = rest1,
							$temp$countL = countL - 1;
						tokensL = $temp$tokensL;
						tokensR = $temp$tokensR;
						countL = $temp$countL;
						continue cleanAngleBracketTokens;
					} else {
						if (countL === 1) {
							return A2(
								$elm$core$List$cons,
								hd1,
								A3($dillonkearns$elm_markdown$Markdown$InlineParser$cleanAngleBracketTokens, tokensL, rest1, countL - 1));
						} else {
							var $temp$tokensL = tokensL,
								$temp$tokensR = rest1,
								$temp$countL = 0;
							tokensL = $temp$tokensL;
							tokensR = $temp$tokensR;
							countL = $temp$countL;
							continue cleanAngleBracketTokens;
						}
					}
				} else {
					var hd = tokensL.a;
					var rest = tokensL.b;
					if (_Utils_cmp(hd.d, hd1.d) < 0) {
						if (!countL) {
							return A2(
								$elm$core$List$cons,
								hd,
								A3($dillonkearns$elm_markdown$Markdown$InlineParser$cleanAngleBracketTokens, rest, tokensR, countL + 1));
						} else {
							var $temp$tokensL = rest,
								$temp$tokensR = tokensR,
								$temp$countL = countL + 1;
							tokensL = $temp$tokensL;
							tokensR = $temp$tokensR;
							countL = $temp$countL;
							continue cleanAngleBracketTokens;
						}
					} else {
						if (countL > 1) {
							var $temp$tokensL = tokensL,
								$temp$tokensR = rest1,
								$temp$countL = countL - 1;
							tokensL = $temp$tokensL;
							tokensR = $temp$tokensR;
							countL = $temp$countL;
							continue cleanAngleBracketTokens;
						} else {
							if (countL === 1) {
								return A2(
									$elm$core$List$cons,
									hd1,
									A3($dillonkearns$elm_markdown$Markdown$InlineParser$cleanAngleBracketTokens, tokensL, rest1, countL - 1));
							} else {
								var $temp$tokensL = tokensL,
									$temp$tokensR = rest1,
									$temp$countL = 0;
								tokensL = $temp$tokensL;
								tokensR = $temp$tokensR;
								countL = $temp$countL;
								continue cleanAngleBracketTokens;
							}
						}
					}
				}
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$angleBracketLTokenRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('(\\\\*)(\\<)'));
var $elm$regex$Regex$find = _Regex_findAtMost(_Regex_infinity);
var $dillonkearns$elm_markdown$Markdown$InlineParser$AngleBracketOpen = {$: 4};
var $dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToAngleBracketLToken = function (regMatch) {
	var _v0 = regMatch.bv;
	if ((_v0.b && _v0.b.b) && (!_v0.b.a.$)) {
		var maybeBackslashes = _v0.a;
		var _v1 = _v0.b;
		var backslashesLength = A2(
			$elm$core$Maybe$withDefault,
			0,
			A2($elm$core$Maybe$map, $elm$core$String$length, maybeBackslashes));
		return $dillonkearns$elm_markdown$Markdown$Helpers$isEven(backslashesLength) ? $elm$core$Maybe$Just(
			{d: regMatch.d + backslashesLength, bf: 1, f: $dillonkearns$elm_markdown$Markdown$InlineParser$AngleBracketOpen}) : $elm$core$Maybe$Nothing;
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$findAngleBracketLTokens = function (str) {
	return A2(
		$elm$core$List$filterMap,
		$dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToAngleBracketLToken,
		A2($elm$regex$Regex$find, $dillonkearns$elm_markdown$Markdown$InlineParser$angleBracketLTokenRegex, str));
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$angleBracketRTokenRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('(\\\\*)(\\>)'));
var $dillonkearns$elm_markdown$Markdown$InlineParser$AngleBracketClose = function (a) {
	return {$: 5, a: a};
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$Escaped = 0;
var $dillonkearns$elm_markdown$Markdown$InlineParser$NotEscaped = 1;
var $dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToAngleBracketRToken = function (regMatch) {
	var _v0 = regMatch.bv;
	if ((_v0.b && _v0.b.b) && (!_v0.b.a.$)) {
		var maybeBackslashes = _v0.a;
		var _v1 = _v0.b;
		var backslashesLength = A2(
			$elm$core$Maybe$withDefault,
			0,
			A2($elm$core$Maybe$map, $elm$core$String$length, maybeBackslashes));
		return $elm$core$Maybe$Just(
			{
				d: regMatch.d + backslashesLength,
				bf: 1,
				f: $dillonkearns$elm_markdown$Markdown$Helpers$isEven(backslashesLength) ? $dillonkearns$elm_markdown$Markdown$InlineParser$AngleBracketClose(1) : $dillonkearns$elm_markdown$Markdown$InlineParser$AngleBracketClose(0)
			});
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$findAngleBracketRTokens = function (str) {
	return A2(
		$elm$core$List$filterMap,
		$dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToAngleBracketRToken,
		A2($elm$regex$Regex$find, $dillonkearns$elm_markdown$Markdown$InlineParser$angleBracketRTokenRegex, str));
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$asteriskEmphasisTokenRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('(\\\\*)([^*])?(\\*+)([^*])?'));
var $dillonkearns$elm_markdown$Markdown$InlineParser$EmphasisToken = F2(
	function (a, b) {
		return {$: 7, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$isPunctuation = function (c) {
	switch (c) {
		case '!':
			return true;
		case '\"':
			return true;
		case '#':
			return true;
		case '%':
			return true;
		case '&':
			return true;
		case '\'':
			return true;
		case '(':
			return true;
		case ')':
			return true;
		case '*':
			return true;
		case ',':
			return true;
		case '-':
			return true;
		case '.':
			return true;
		case '/':
			return true;
		case ':':
			return true;
		case ';':
			return true;
		case '?':
			return true;
		case '@':
			return true;
		case '[':
			return true;
		case ']':
			return true;
		case '_':
			return true;
		case '{':
			return true;
		case '}':
			return true;
		case '~':
			return true;
		default:
			return false;
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$containPunctuation = A2(
	$elm$core$String$foldl,
	F2(
		function (c, accum) {
			return accum || $dillonkearns$elm_markdown$Markdown$InlineParser$isPunctuation(c);
		}),
	false);
var $dillonkearns$elm_markdown$Markdown$InlineParser$isWhitespace = function (c) {
	switch (c) {
		case ' ':
			return true;
		case '\u000C':
			return true;
		case '\n':
			return true;
		case '\u000D':
			return true;
		case '\t':
			return true;
		case '\u000B':
			return true;
		case '\u00A0':
			return true;
		case '\u2028':
			return true;
		case '\u2029':
			return true;
		default:
			return false;
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$containSpace = A2(
	$elm$core$String$foldl,
	F2(
		function (c, accum) {
			return accum || $dillonkearns$elm_markdown$Markdown$InlineParser$isWhitespace(c);
		}),
	false);
var $dillonkearns$elm_markdown$Markdown$InlineParser$getFringeRank = function (mstring) {
	if (!mstring.$) {
		var string = mstring.a;
		return ($elm$core$String$isEmpty(string) || $dillonkearns$elm_markdown$Markdown$InlineParser$containSpace(string)) ? 0 : ($dillonkearns$elm_markdown$Markdown$InlineParser$containPunctuation(string) ? 1 : 2);
	} else {
		return 0;
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToEmphasisToken = F3(
	function (_char, rawText, regMatch) {
		var _v0 = regMatch.bv;
		if ((((_v0.b && _v0.b.b) && _v0.b.b.b) && (!_v0.b.b.a.$)) && _v0.b.b.b.b) {
			var maybeBackslashes = _v0.a;
			var _v1 = _v0.b;
			var maybeLeftFringe = _v1.a;
			var _v2 = _v1.b;
			var delimiter = _v2.a.a;
			var _v3 = _v2.b;
			var maybeRightFringe = _v3.a;
			var rFringeRank = $dillonkearns$elm_markdown$Markdown$InlineParser$getFringeRank(maybeRightFringe);
			var leftFringeLength = function () {
				if (!maybeLeftFringe.$) {
					var left = maybeLeftFringe.a;
					return $elm$core$String$length(left);
				} else {
					return 0;
				}
			}();
			var mLeftFringe = ((!(!regMatch.d)) && (!leftFringeLength)) ? $elm$core$Maybe$Just(
				A3($elm$core$String$slice, regMatch.d - 1, regMatch.d, rawText)) : maybeLeftFringe;
			var backslashesLength = function () {
				if (!maybeBackslashes.$) {
					var backslashes = maybeBackslashes.a;
					return $elm$core$String$length(backslashes);
				} else {
					return 0;
				}
			}();
			var isEscaped = ((!$dillonkearns$elm_markdown$Markdown$Helpers$isEven(backslashesLength)) && (!leftFringeLength)) || function () {
				if ((!mLeftFringe.$) && (mLeftFringe.a === '\\')) {
					return true;
				} else {
					return false;
				}
			}();
			var delimiterLength = isEscaped ? ($elm$core$String$length(delimiter) - 1) : $elm$core$String$length(delimiter);
			var lFringeRank = isEscaped ? 1 : $dillonkearns$elm_markdown$Markdown$InlineParser$getFringeRank(mLeftFringe);
			if ((delimiterLength <= 0) || ((_char === '_') && ((lFringeRank === 2) && (rFringeRank === 2)))) {
				return $elm$core$Maybe$Nothing;
			} else {
				var index = ((regMatch.d + backslashesLength) + leftFringeLength) + (isEscaped ? 1 : 0);
				return $elm$core$Maybe$Just(
					{
						d: index,
						bf: delimiterLength,
						f: A2(
							$dillonkearns$elm_markdown$Markdown$InlineParser$EmphasisToken,
							_char,
							{aM: lFringeRank, aQ: rFringeRank})
					});
			}
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$findAsteriskEmphasisTokens = function (str) {
	return A2(
		$elm$core$List$filterMap,
		A2($dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToEmphasisToken, '*', str),
		A2($elm$regex$Regex$find, $dillonkearns$elm_markdown$Markdown$InlineParser$asteriskEmphasisTokenRegex, str));
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$codeTokenRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('(\\\\*)(\\`+)'));
var $dillonkearns$elm_markdown$Markdown$InlineParser$CodeToken = function (a) {
	return {$: 0, a: a};
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToCodeToken = function (regMatch) {
	var _v0 = regMatch.bv;
	if ((_v0.b && _v0.b.b) && (!_v0.b.a.$)) {
		var maybeBackslashes = _v0.a;
		var _v1 = _v0.b;
		var backtick = _v1.a.a;
		var backslashesLength = A2(
			$elm$core$Maybe$withDefault,
			0,
			A2($elm$core$Maybe$map, $elm$core$String$length, maybeBackslashes));
		return $elm$core$Maybe$Just(
			{
				d: regMatch.d + backslashesLength,
				bf: $elm$core$String$length(backtick),
				f: $dillonkearns$elm_markdown$Markdown$Helpers$isEven(backslashesLength) ? $dillonkearns$elm_markdown$Markdown$InlineParser$CodeToken(1) : $dillonkearns$elm_markdown$Markdown$InlineParser$CodeToken(0)
			});
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$findCodeTokens = function (str) {
	return A2(
		$elm$core$List$filterMap,
		$dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToCodeToken,
		A2($elm$regex$Regex$find, $dillonkearns$elm_markdown$Markdown$InlineParser$codeTokenRegex, str));
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$hardBreakTokenRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('(?:(\\\\+)|( {2,}))\\n'));
var $dillonkearns$elm_markdown$Markdown$InlineParser$HardLineBreakToken = {$: 8};
var $dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToHardBreakToken = function (regMatch) {
	var _v0 = regMatch.bv;
	_v0$2:
	while (true) {
		if (_v0.b) {
			if (!_v0.a.$) {
				var backslashes = _v0.a.a;
				var backslashesLength = $elm$core$String$length(backslashes);
				return (!$dillonkearns$elm_markdown$Markdown$Helpers$isEven(backslashesLength)) ? $elm$core$Maybe$Just(
					{d: (regMatch.d + backslashesLength) - 1, bf: 2, f: $dillonkearns$elm_markdown$Markdown$InlineParser$HardLineBreakToken}) : $elm$core$Maybe$Nothing;
			} else {
				if (_v0.b.b && (!_v0.b.a.$)) {
					var _v1 = _v0.b;
					return $elm$core$Maybe$Just(
						{
							d: regMatch.d,
							bf: $elm$core$String$length(regMatch.as),
							f: $dillonkearns$elm_markdown$Markdown$InlineParser$HardLineBreakToken
						});
				} else {
					break _v0$2;
				}
			}
		} else {
			break _v0$2;
		}
	}
	return $elm$core$Maybe$Nothing;
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToSoftHardBreakToken = function (regMatch) {
	var _v0 = regMatch.bv;
	_v0$2:
	while (true) {
		if (_v0.b) {
			if (!_v0.a.$) {
				var backslashes = _v0.a.a;
				var backslashesLength = $elm$core$String$length(backslashes);
				return $dillonkearns$elm_markdown$Markdown$Helpers$isEven(backslashesLength) ? $elm$core$Maybe$Just(
					{d: regMatch.d + backslashesLength, bf: 1, f: $dillonkearns$elm_markdown$Markdown$InlineParser$HardLineBreakToken}) : $elm$core$Maybe$Just(
					{d: (regMatch.d + backslashesLength) - 1, bf: 2, f: $dillonkearns$elm_markdown$Markdown$InlineParser$HardLineBreakToken});
			} else {
				if (_v0.b.b) {
					var _v1 = _v0.b;
					return $elm$core$Maybe$Just(
						{
							d: regMatch.d,
							bf: $elm$core$String$length(regMatch.as),
							f: $dillonkearns$elm_markdown$Markdown$InlineParser$HardLineBreakToken
						});
				} else {
					break _v0$2;
				}
			}
		} else {
			break _v0$2;
		}
	}
	return $elm$core$Maybe$Nothing;
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$softAsHardLineBreak = false;
var $dillonkearns$elm_markdown$Markdown$InlineParser$softAsHardLineBreakTokenRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('(?:(\\\\+)|( *))\\n'));
var $dillonkearns$elm_markdown$Markdown$InlineParser$findHardBreakTokens = function (str) {
	return $dillonkearns$elm_markdown$Markdown$InlineParser$softAsHardLineBreak ? A2(
		$elm$core$List$filterMap,
		$dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToSoftHardBreakToken,
		A2($elm$regex$Regex$find, $dillonkearns$elm_markdown$Markdown$InlineParser$softAsHardLineBreakTokenRegex, str)) : A2(
		$elm$core$List$filterMap,
		$dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToHardBreakToken,
		A2($elm$regex$Regex$find, $dillonkearns$elm_markdown$Markdown$InlineParser$hardBreakTokenRegex, str));
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$linkImageCloseTokenRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('(\\\\*)(\\])'));
var $dillonkearns$elm_markdown$Markdown$InlineParser$SquareBracketClose = {$: 3};
var $dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToLinkImageCloseToken = function (regMatch) {
	var _v0 = regMatch.bv;
	if ((_v0.b && _v0.b.b) && (!_v0.b.a.$)) {
		var maybeBackslashes = _v0.a;
		var _v1 = _v0.b;
		var backslashesLength = A2(
			$elm$core$Maybe$withDefault,
			0,
			A2($elm$core$Maybe$map, $elm$core$String$length, maybeBackslashes));
		return $dillonkearns$elm_markdown$Markdown$Helpers$isEven(backslashesLength) ? $elm$core$Maybe$Just(
			{d: regMatch.d + backslashesLength, bf: 1, f: $dillonkearns$elm_markdown$Markdown$InlineParser$SquareBracketClose}) : $elm$core$Maybe$Nothing;
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$findLinkImageCloseTokens = function (str) {
	return A2(
		$elm$core$List$filterMap,
		$dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToLinkImageCloseToken,
		A2($elm$regex$Regex$find, $dillonkearns$elm_markdown$Markdown$InlineParser$linkImageCloseTokenRegex, str));
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$linkImageOpenTokenRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('(\\\\*)(\\!)?(\\[)'));
var $dillonkearns$elm_markdown$Markdown$InlineParser$Active = 0;
var $dillonkearns$elm_markdown$Markdown$InlineParser$ImageOpenToken = {$: 2};
var $dillonkearns$elm_markdown$Markdown$InlineParser$LinkOpenToken = function (a) {
	return {$: 1, a: a};
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToLinkImageOpenToken = function (regMatch) {
	var _v0 = regMatch.bv;
	if (((_v0.b && _v0.b.b) && _v0.b.b.b) && (!_v0.b.b.a.$)) {
		var maybeBackslashes = _v0.a;
		var _v1 = _v0.b;
		var maybeImageOpen = _v1.a;
		var _v2 = _v1.b;
		var backslashesLength = A2(
			$elm$core$Maybe$withDefault,
			0,
			A2($elm$core$Maybe$map, $elm$core$String$length, maybeBackslashes));
		var isEscaped = !$dillonkearns$elm_markdown$Markdown$Helpers$isEven(backslashesLength);
		var index = isEscaped ? ((regMatch.d + backslashesLength) + 1) : (regMatch.d + backslashesLength);
		if (isEscaped) {
			if (!maybeImageOpen.$) {
				return $elm$core$Maybe$Just(
					{
						d: index,
						bf: 1,
						f: $dillonkearns$elm_markdown$Markdown$InlineParser$LinkOpenToken(0)
					});
			} else {
				return $elm$core$Maybe$Nothing;
			}
		} else {
			if (!maybeImageOpen.$) {
				return $elm$core$Maybe$Just(
					{d: index, bf: 2, f: $dillonkearns$elm_markdown$Markdown$InlineParser$ImageOpenToken});
			} else {
				return $elm$core$Maybe$Just(
					{
						d: index,
						bf: 1,
						f: $dillonkearns$elm_markdown$Markdown$InlineParser$LinkOpenToken(0)
					});
			}
		}
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$findLinkImageOpenTokens = function (str) {
	return A2(
		$elm$core$List$filterMap,
		$dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToLinkImageOpenToken,
		A2($elm$regex$Regex$find, $dillonkearns$elm_markdown$Markdown$InlineParser$linkImageOpenTokenRegex, str));
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$StrikethroughToken = function (a) {
	return {$: 9, a: a};
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToStrikethroughToken = function (regMatch) {
	var _v0 = regMatch.bv;
	if ((_v0.b && _v0.b.b) && (!_v0.b.a.$)) {
		var maybeBackslashes = _v0.a;
		var _v1 = _v0.b;
		var tilde = _v1.a.a;
		var backslashesLength = A2(
			$elm$core$Maybe$withDefault,
			0,
			A2($elm$core$Maybe$map, $elm$core$String$length, maybeBackslashes));
		var _v2 = $dillonkearns$elm_markdown$Markdown$Helpers$isEven(backslashesLength) ? _Utils_Tuple2(
			$elm$core$String$length(tilde),
			$dillonkearns$elm_markdown$Markdown$InlineParser$StrikethroughToken(1)) : _Utils_Tuple2(
			$elm$core$String$length(tilde),
			$dillonkearns$elm_markdown$Markdown$InlineParser$StrikethroughToken(0));
		var length = _v2.a;
		var meaning = _v2.b;
		return $elm$core$Maybe$Just(
			{d: regMatch.d + backslashesLength, bf: length, f: meaning});
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$strikethroughTokenRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('(\\\\*)(~{2,})([^~])?'));
var $dillonkearns$elm_markdown$Markdown$InlineParser$findStrikethroughTokens = function (str) {
	return A2(
		$elm$core$List$filterMap,
		$dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToStrikethroughToken,
		A2($elm$regex$Regex$find, $dillonkearns$elm_markdown$Markdown$InlineParser$strikethroughTokenRegex, str));
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$underlineEmphasisTokenRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('(\\\\*)([^_])?(\\_+)([^_])?'));
var $dillonkearns$elm_markdown$Markdown$InlineParser$findUnderlineEmphasisTokens = function (str) {
	return A2(
		$elm$core$List$filterMap,
		A2($dillonkearns$elm_markdown$Markdown$InlineParser$regMatchToEmphasisToken, '_', str),
		A2($elm$regex$Regex$find, $dillonkearns$elm_markdown$Markdown$InlineParser$underlineEmphasisTokenRegex, str));
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$mergeByIndex = F2(
	function (left, right) {
		if (left.b) {
			var lfirst = left.a;
			var lrest = left.b;
			if (right.b) {
				var rfirst = right.a;
				var rrest = right.b;
				return (_Utils_cmp(lfirst.d, rfirst.d) < 0) ? A2(
					$elm$core$List$cons,
					lfirst,
					A2($dillonkearns$elm_markdown$Markdown$InlineParser$mergeByIndex, lrest, right)) : A2(
					$elm$core$List$cons,
					rfirst,
					A2($dillonkearns$elm_markdown$Markdown$InlineParser$mergeByIndex, left, rrest));
			} else {
				return left;
			}
		} else {
			return right;
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$tokenize = function (rawText) {
	return A2(
		$dillonkearns$elm_markdown$Markdown$InlineParser$mergeByIndex,
		A3(
			$dillonkearns$elm_markdown$Markdown$InlineParser$cleanAngleBracketTokens,
			A2(
				$elm$core$List$sortBy,
				function ($) {
					return $.d;
				},
				$dillonkearns$elm_markdown$Markdown$InlineParser$findAngleBracketLTokens(rawText)),
			A2(
				$elm$core$List$sortBy,
				function ($) {
					return $.d;
				},
				$dillonkearns$elm_markdown$Markdown$InlineParser$findAngleBracketRTokens(rawText)),
			0),
		A2(
			$dillonkearns$elm_markdown$Markdown$InlineParser$mergeByIndex,
			$dillonkearns$elm_markdown$Markdown$InlineParser$findHardBreakTokens(rawText),
			A2(
				$dillonkearns$elm_markdown$Markdown$InlineParser$mergeByIndex,
				$dillonkearns$elm_markdown$Markdown$InlineParser$findLinkImageCloseTokens(rawText),
				A2(
					$dillonkearns$elm_markdown$Markdown$InlineParser$mergeByIndex,
					$dillonkearns$elm_markdown$Markdown$InlineParser$findLinkImageOpenTokens(rawText),
					A2(
						$dillonkearns$elm_markdown$Markdown$InlineParser$mergeByIndex,
						$dillonkearns$elm_markdown$Markdown$InlineParser$findStrikethroughTokens(rawText),
						A2(
							$dillonkearns$elm_markdown$Markdown$InlineParser$mergeByIndex,
							$dillonkearns$elm_markdown$Markdown$InlineParser$findUnderlineEmphasisTokens(rawText),
							A2(
								$dillonkearns$elm_markdown$Markdown$InlineParser$mergeByIndex,
								$dillonkearns$elm_markdown$Markdown$InlineParser$findAsteriskEmphasisTokens(rawText),
								$dillonkearns$elm_markdown$Markdown$InlineParser$findCodeTokens(rawText))))))));
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$CodeType = {$: 2};
var $dillonkearns$elm_markdown$Markdown$InlineParser$EmphasisType = function (a) {
	return {$: 7, a: a};
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$HtmlType = function (a) {
	return {$: 6, a: a};
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$ImageType = function (a) {
	return {$: 5, a: a};
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$Inactive = 1;
var $dillonkearns$elm_markdown$Markdown$InlineParser$LinkType = function (a) {
	return {$: 4, a: a};
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$StrikethroughType = {$: 8};
var $dillonkearns$elm_markdown$Markdown$InlineParser$AutolinkType = function (a) {
	return {$: 3, a: a};
};
var $elm$regex$Regex$contains = _Regex_contains;
var $dillonkearns$elm_markdown$Markdown$InlineParser$decodeUrlRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('%(?:3B|2C|2F|3F|3A|40|26|3D|2B|24|23|25)'));
var $elm$url$Url$percentDecode = _Url_percentDecode;
var $elm$url$Url$percentEncode = _Url_percentEncode;
var $dillonkearns$elm_markdown$Markdown$InlineParser$encodeUrl = A2(
	$elm$core$Basics$composeR,
	$elm$url$Url$percentEncode,
	A2(
		$elm$regex$Regex$replace,
		$dillonkearns$elm_markdown$Markdown$InlineParser$decodeUrlRegex,
		function (match) {
			return A2(
				$elm$core$Maybe$withDefault,
				match.as,
				$elm$url$Url$percentDecode(match.as));
		}));
var $dillonkearns$elm_markdown$Markdown$InlineParser$urlRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('^([A-Za-z][A-Za-z0-9.+\\-]{1,31}:[^<>\\x00-\\x20]*)$'));
var $dillonkearns$elm_markdown$Markdown$InlineParser$autolinkToMatch = function (_v0) {
	var match = _v0;
	return A2($elm$regex$Regex$contains, $dillonkearns$elm_markdown$Markdown$InlineParser$urlRegex, match.dX) ? $elm$core$Result$Ok(
		_Utils_update(
			match,
			{
				n: $dillonkearns$elm_markdown$Markdown$InlineParser$AutolinkType(
					_Utils_Tuple2(
						match.dX,
						$dillonkearns$elm_markdown$Markdown$InlineParser$encodeUrl(match.dX)))
			})) : $elm$core$Result$Err(match);
};
var $elm$regex$Regex$findAtMost = _Regex_findAtMost;
var $dillonkearns$elm_markdown$Markdown$Helpers$insideSquareBracketRegex = '[^\\[\\]\\\\]*(?:\\\\.[^\\[\\]\\\\]*)*';
var $dillonkearns$elm_markdown$Markdown$InlineParser$refLabelRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('^\\[\\s*(' + ($dillonkearns$elm_markdown$Markdown$Helpers$insideSquareBracketRegex + ')\\s*\\]')));
var $dillonkearns$elm_markdown$Markdown$Helpers$cleanWhitespaces = function (original) {
	return original;
};
var $dillonkearns$elm_markdown$Markdown$Helpers$prepareRefLabel = A2($elm$core$Basics$composeR, $dillonkearns$elm_markdown$Markdown$Helpers$cleanWhitespaces, $elm$core$String$toLower);
var $dillonkearns$elm_markdown$Markdown$InlineParser$prepareUrlAndTitle = F2(
	function (rawUrl, maybeTitle) {
		return _Utils_Tuple2(
			$dillonkearns$elm_markdown$Markdown$InlineParser$encodeUrl(
				$dillonkearns$elm_markdown$Markdown$Helpers$formatStr(rawUrl)),
			A2($elm$core$Maybe$map, $dillonkearns$elm_markdown$Markdown$Helpers$formatStr, maybeTitle));
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$refRegexToMatch = F3(
	function (matchModel, references, maybeRegexMatch) {
		var refLabel = function (str) {
			return $elm$core$String$isEmpty(str) ? matchModel.dX : str;
		}(
			A2(
				$elm$core$Maybe$withDefault,
				matchModel.dX,
				A2(
					$elm$core$Maybe$withDefault,
					$elm$core$Maybe$Nothing,
					A2(
						$elm$core$Maybe$andThen,
						A2(
							$elm$core$Basics$composeR,
							function ($) {
								return $.bv;
							},
							$elm$core$List$head),
						maybeRegexMatch))));
		var _v0 = A2(
			$elm$core$Dict$get,
			$dillonkearns$elm_markdown$Markdown$Helpers$prepareRefLabel(refLabel),
			references);
		if (_v0.$ === 1) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v1 = _v0.a;
			var rawUrl = _v1.a;
			var maybeTitle = _v1.b;
			var type_ = function () {
				var _v3 = matchModel.n;
				if (_v3.$ === 5) {
					return $dillonkearns$elm_markdown$Markdown$InlineParser$ImageType(
						A2($dillonkearns$elm_markdown$Markdown$InlineParser$prepareUrlAndTitle, rawUrl, maybeTitle));
				} else {
					return $dillonkearns$elm_markdown$Markdown$InlineParser$LinkType(
						A2($dillonkearns$elm_markdown$Markdown$InlineParser$prepareUrlAndTitle, rawUrl, maybeTitle));
				}
			}();
			var regexMatchLength = function () {
				if (!maybeRegexMatch.$) {
					var match = maybeRegexMatch.a.as;
					return $elm$core$String$length(match);
				} else {
					return 0;
				}
			}();
			return $elm$core$Maybe$Just(
				_Utils_update(
					matchModel,
					{i: matchModel.i + regexMatchLength, n: type_}));
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$checkForInlineReferences = F3(
	function (remainText, _v0, references) {
		var tempMatch = _v0;
		var matches = A3($elm$regex$Regex$findAtMost, 1, $dillonkearns$elm_markdown$Markdown$InlineParser$refLabelRegex, remainText);
		return A3(
			$dillonkearns$elm_markdown$Markdown$InlineParser$refRegexToMatch,
			tempMatch,
			references,
			$elm$core$List$head(matches));
	});
var $dillonkearns$elm_markdown$Markdown$Helpers$lineEndChars = '\\f\\v\\r\\n';
var $dillonkearns$elm_markdown$Markdown$Helpers$whiteSpaceChars = ' \\t\\f\\v\\r\\n';
var $dillonkearns$elm_markdown$Markdown$InlineParser$hrefRegex = '(?:<([^<>' + ($dillonkearns$elm_markdown$Markdown$Helpers$lineEndChars + (']*)>|([^' + ($dillonkearns$elm_markdown$Markdown$Helpers$whiteSpaceChars + ('\\(\\)\\\\]*(?:\\\\.[^' + ($dillonkearns$elm_markdown$Markdown$Helpers$whiteSpaceChars + '\\(\\)\\\\]*)*))')))));
var $dillonkearns$elm_markdown$Markdown$Helpers$titleRegex = '(?:[' + ($dillonkearns$elm_markdown$Markdown$Helpers$whiteSpaceChars + (']+' + ('(?:\'([^\'\\\\]*(?:\\\\.[^\'\\\\]*)*)\'|' + ('\"([^\"\\\\]*(?:\\\\.[^\"\\\\]*)*)\"|' + '\\(([^\\)\\\\]*(?:\\\\.[^\\)\\\\]*)*)\\)))?'))));
var $dillonkearns$elm_markdown$Markdown$InlineParser$inlineLinkTypeOrImageTypeRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('^\\(\\s*' + ($dillonkearns$elm_markdown$Markdown$InlineParser$hrefRegex + ($dillonkearns$elm_markdown$Markdown$Helpers$titleRegex + '\\s*\\)'))));
var $dillonkearns$elm_markdown$Markdown$Helpers$returnFirstJust = function (maybes) {
	var process = F2(
		function (a, maybeFound) {
			if (!maybeFound.$) {
				var found = maybeFound.a;
				return $elm$core$Maybe$Just(found);
			} else {
				return a;
			}
		});
	return A3($elm$core$List$foldl, process, $elm$core$Maybe$Nothing, maybes);
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$inlineLinkTypeOrImageTypeRegexToMatch = F2(
	function (matchModel, regexMatch) {
		var _v0 = regexMatch.bv;
		if ((((_v0.b && _v0.b.b) && _v0.b.b.b) && _v0.b.b.b.b) && _v0.b.b.b.b.b) {
			var maybeRawUrlAngleBrackets = _v0.a;
			var _v1 = _v0.b;
			var maybeRawUrlWithoutBrackets = _v1.a;
			var _v2 = _v1.b;
			var maybeTitleSingleQuotes = _v2.a;
			var _v3 = _v2.b;
			var maybeTitleDoubleQuotes = _v3.a;
			var _v4 = _v3.b;
			var maybeTitleParenthesis = _v4.a;
			var maybeTitle = $dillonkearns$elm_markdown$Markdown$Helpers$returnFirstJust(
				_List_fromArray(
					[maybeTitleSingleQuotes, maybeTitleDoubleQuotes, maybeTitleParenthesis]));
			var toMatch = function (rawUrl) {
				return _Utils_update(
					matchModel,
					{
						i: matchModel.i + $elm$core$String$length(regexMatch.as),
						n: function () {
							var _v5 = matchModel.n;
							if (_v5.$ === 5) {
								return $dillonkearns$elm_markdown$Markdown$InlineParser$ImageType;
							} else {
								return $dillonkearns$elm_markdown$Markdown$InlineParser$LinkType;
							}
						}()(
							A2($dillonkearns$elm_markdown$Markdown$InlineParser$prepareUrlAndTitle, rawUrl, maybeTitle))
					});
			};
			var maybeRawUrl = $dillonkearns$elm_markdown$Markdown$Helpers$returnFirstJust(
				_List_fromArray(
					[maybeRawUrlAngleBrackets, maybeRawUrlWithoutBrackets]));
			return $elm$core$Maybe$Just(
				toMatch(
					A2($elm$core$Maybe$withDefault, '', maybeRawUrl)));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$checkForInlineLinkTypeOrImageType = F3(
	function (remainText, _v0, refs) {
		var tempMatch = _v0;
		var _v1 = A3($elm$regex$Regex$findAtMost, 1, $dillonkearns$elm_markdown$Markdown$InlineParser$inlineLinkTypeOrImageTypeRegex, remainText);
		if (_v1.b) {
			var first = _v1.a;
			var _v2 = A2($dillonkearns$elm_markdown$Markdown$InlineParser$inlineLinkTypeOrImageTypeRegexToMatch, tempMatch, first);
			if (!_v2.$) {
				var match = _v2.a;
				return $elm$core$Maybe$Just(match);
			} else {
				return A3($dillonkearns$elm_markdown$Markdown$InlineParser$checkForInlineReferences, remainText, tempMatch, refs);
			}
		} else {
			return A3($dillonkearns$elm_markdown$Markdown$InlineParser$checkForInlineReferences, remainText, tempMatch, refs);
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$checkParsedAheadOverlapping = F2(
	function (_v0, remainMatches) {
		var match = _v0;
		var overlappingMatches = $elm$core$List$filter(
			function (_v1) {
				var testMatch = _v1;
				return (_Utils_cmp(match.i, testMatch.k) > 0) && (_Utils_cmp(match.i, testMatch.i) < 0);
			});
		return ($elm$core$List$isEmpty(remainMatches) || $elm$core$List$isEmpty(
			overlappingMatches(remainMatches))) ? $elm$core$Maybe$Just(
			A2($elm$core$List$cons, match, remainMatches)) : $elm$core$Maybe$Nothing;
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$emailRegex = A2(
	$elm$core$Maybe$withDefault,
	$elm$regex$Regex$never,
	$elm$regex$Regex$fromString('^([a-zA-Z0-9.!#$%&\'*+\\/=?^_`{|}~\\-]+@[a-zA-Z0-9](?:[a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?)*)$'));
var $dillonkearns$elm_markdown$Markdown$InlineParser$emailAutolinkTypeToMatch = function (_v0) {
	var match = _v0;
	return A2($elm$regex$Regex$contains, $dillonkearns$elm_markdown$Markdown$InlineParser$emailRegex, match.dX) ? $elm$core$Result$Ok(
		_Utils_update(
			match,
			{
				n: $dillonkearns$elm_markdown$Markdown$InlineParser$AutolinkType(
					_Utils_Tuple2(
						match.dX,
						'mailto:' + $dillonkearns$elm_markdown$Markdown$InlineParser$encodeUrl(match.dX)))
			})) : $elm$core$Result$Err(match);
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$findTokenHelp = F3(
	function (innerTokens, isToken, tokens) {
		findTokenHelp:
		while (true) {
			if (!tokens.b) {
				return $elm$core$Maybe$Nothing;
			} else {
				var nextToken = tokens.a;
				var remainingTokens = tokens.b;
				if (isToken(nextToken)) {
					return $elm$core$Maybe$Just(
						_Utils_Tuple3(
							nextToken,
							$elm$core$List$reverse(innerTokens),
							remainingTokens));
				} else {
					var $temp$innerTokens = A2($elm$core$List$cons, nextToken, innerTokens),
						$temp$isToken = isToken,
						$temp$tokens = remainingTokens;
					innerTokens = $temp$innerTokens;
					isToken = $temp$isToken;
					tokens = $temp$tokens;
					continue findTokenHelp;
				}
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$findToken = F2(
	function (isToken, tokens) {
		return A3($dillonkearns$elm_markdown$Markdown$InlineParser$findTokenHelp, _List_Nil, isToken, tokens);
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$HtmlToken = F2(
	function (a, b) {
		return {$: 6, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$NotOpening = 0;
var $elm$parser$Parser$Advanced$getOffset = function (s) {
	return A3($elm$parser$Parser$Advanced$Good, false, s.e, s);
};
var $elm$parser$Parser$Advanced$bagToList = F2(
	function (bag, list) {
		bagToList:
		while (true) {
			switch (bag.$) {
				case 0:
					return list;
				case 1:
					var bag1 = bag.a;
					var x = bag.b;
					var $temp$bag = bag1,
						$temp$list = A2($elm$core$List$cons, x, list);
					bag = $temp$bag;
					list = $temp$list;
					continue bagToList;
				default:
					var bag1 = bag.a;
					var bag2 = bag.b;
					var $temp$bag = bag1,
						$temp$list = A2($elm$parser$Parser$Advanced$bagToList, bag2, list);
					bag = $temp$bag;
					list = $temp$list;
					continue bagToList;
			}
		}
	});
var $elm$parser$Parser$Advanced$run = F2(
	function (_v0, src) {
		var parse = _v0;
		var _v1 = parse(
			{bO: 1, h: _List_Nil, j: 1, e: 0, dT: 1, bq: src});
		if (!_v1.$) {
			var value = _v1.b;
			return $elm$core$Result$Ok(value);
		} else {
			var bag = _v1.b;
			return $elm$core$Result$Err(
				A2($elm$parser$Parser$Advanced$bagToList, bag, _List_Nil));
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$htmlToToken = F2(
	function (rawText, _v0) {
		var match = _v0;
		var consumedCharacters = A2(
			$elm$parser$Parser$Advanced$keeper,
			A2(
				$elm$parser$Parser$Advanced$keeper,
				A2(
					$elm$parser$Parser$Advanced$keeper,
					$elm$parser$Parser$Advanced$succeed(
						F3(
							function (startOffset, htmlTag, endOffset) {
								return {b1: htmlTag, bf: endOffset - startOffset};
							})),
					$elm$parser$Parser$Advanced$getOffset),
				$dillonkearns$elm_markdown$HtmlParser$html),
			$elm$parser$Parser$Advanced$getOffset);
		var parsed = A2(
			$elm$parser$Parser$Advanced$run,
			consumedCharacters,
			A2($elm$core$String$dropLeft, match.k, rawText));
		if (!parsed.$) {
			var htmlTag = parsed.a.b1;
			var length = parsed.a.bf;
			var htmlToken = A2($dillonkearns$elm_markdown$Markdown$InlineParser$HtmlToken, 0, htmlTag);
			return $elm$core$Maybe$Just(
				{d: match.k, bf: length, f: htmlToken});
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $dillonkearns$elm_markdown$Markdown$Helpers$ifError = F2(
	function (_function, result) {
		if (!result.$) {
			return result;
		} else {
			var err = result.a;
			return _function(err);
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$isCodeTokenPair = F2(
	function (closeToken, openToken) {
		var _v0 = openToken.f;
		if (!_v0.$) {
			if (!_v0.a) {
				var _v1 = _v0.a;
				return _Utils_eq(openToken.bf - 1, closeToken.bf);
			} else {
				var _v2 = _v0.a;
				return _Utils_eq(openToken.bf, closeToken.bf);
			}
		} else {
			return false;
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$isLinkTypeOrImageOpenToken = function (token) {
	var _v0 = token.f;
	switch (_v0.$) {
		case 1:
			return true;
		case 2:
			return true;
		default:
			return false;
	}
};
var $dillonkearns$elm_markdown$Markdown$InlineParser$isOpenEmphasisToken = F2(
	function (closeToken, openToken) {
		var _v0 = openToken.f;
		if (_v0.$ === 7) {
			var openChar = _v0.a;
			var open = _v0.b;
			var _v1 = closeToken.f;
			if (_v1.$ === 7) {
				var closeChar = _v1.a;
				var close = _v1.b;
				return _Utils_eq(openChar, closeChar) ? ((_Utils_eq(open.aM, open.aQ) || _Utils_eq(close.aM, close.aQ)) ? ((!(!A2($elm$core$Basics$modBy, 3, closeToken.bf + openToken.bf))) || ((!A2($elm$core$Basics$modBy, 3, closeToken.bf)) && (!A2($elm$core$Basics$modBy, 3, openToken.bf)))) : true) : false;
			} else {
				return false;
			}
		} else {
			return false;
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$isStrikethroughTokenPair = F2(
	function (closeToken, openToken) {
		var _v0 = function () {
			var _v1 = openToken.f;
			if (_v1.$ === 9) {
				if (!_v1.a) {
					var _v2 = _v1.a;
					return _Utils_Tuple2(true, openToken.bf - 1);
				} else {
					var _v3 = _v1.a;
					return _Utils_Tuple2(true, openToken.bf);
				}
			} else {
				return _Utils_Tuple2(false, 0);
			}
		}();
		var openTokenIsStrikethrough = _v0.a;
		var openTokenLength = _v0.b;
		var _v4 = function () {
			var _v5 = closeToken.f;
			if (_v5.$ === 9) {
				if (!_v5.a) {
					var _v6 = _v5.a;
					return _Utils_Tuple2(true, closeToken.bf - 1);
				} else {
					var _v7 = _v5.a;
					return _Utils_Tuple2(true, closeToken.bf);
				}
			} else {
				return _Utils_Tuple2(false, 0);
			}
		}();
		var closeTokenIsStrikethrough = _v4.a;
		var closeTokenLength = _v4.b;
		return closeTokenIsStrikethrough && (openTokenIsStrikethrough && _Utils_eq(closeTokenLength, openTokenLength));
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$HardLineBreakType = {$: 1};
var $dillonkearns$elm_markdown$Markdown$InlineParser$tokenToMatch = F2(
	function (token, type_) {
		return {i: token.d + token.bf, v: _List_Nil, k: token.d, dX: '', I: 0, x: 0, n: type_};
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$lineBreakTTM = F2(
	function (remaining, matches) {
		lineBreakTTM:
		while (true) {
			if (!remaining.b) {
				return matches;
			} else {
				var token = remaining.a;
				var tokensTail = remaining.b;
				var _v1 = token.f;
				if (_v1.$ === 8) {
					var $temp$remaining = tokensTail,
						$temp$matches = A2(
						$elm$core$List$cons,
						A2($dillonkearns$elm_markdown$Markdown$InlineParser$tokenToMatch, token, $dillonkearns$elm_markdown$Markdown$InlineParser$HardLineBreakType),
						matches);
					remaining = $temp$remaining;
					matches = $temp$matches;
					continue lineBreakTTM;
				} else {
					var $temp$remaining = tokensTail,
						$temp$matches = matches;
					remaining = $temp$remaining;
					matches = $temp$matches;
					continue lineBreakTTM;
				}
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$removeParsedAheadTokens = F2(
	function (_v0, tokensTail) {
		var match = _v0;
		return A2(
			$elm$core$List$filter,
			function (token) {
				return _Utils_cmp(token.d, match.i) > -1;
			},
			tokensTail);
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$angleBracketsToMatch = F6(
	function (closeToken, escaped, matches, references, rawText, _v44) {
		var openToken = _v44.a;
		var remainTokens = _v44.c;
		var result = A2(
			$dillonkearns$elm_markdown$Markdown$Helpers$ifError,
			$dillonkearns$elm_markdown$Markdown$InlineParser$emailAutolinkTypeToMatch,
			$dillonkearns$elm_markdown$Markdown$InlineParser$autolinkToMatch(
				A7(
					$dillonkearns$elm_markdown$Markdown$InlineParser$tokenPairToMatch,
					references,
					rawText,
					function (s) {
						return s;
					},
					$dillonkearns$elm_markdown$Markdown$InlineParser$CodeType,
					openToken,
					closeToken,
					_List_Nil)));
		if (result.$ === 1) {
			var tempMatch = result.a;
			if (escaped === 1) {
				var _v47 = A2($dillonkearns$elm_markdown$Markdown$InlineParser$htmlToToken, rawText, tempMatch);
				if (!_v47.$) {
					var newToken = _v47.a;
					return $elm$core$Maybe$Just(
						_Utils_Tuple2(
							A2($elm$core$List$cons, newToken, remainTokens),
							matches));
				} else {
					return $elm$core$Maybe$Nothing;
				}
			} else {
				return $elm$core$Maybe$Nothing;
			}
		} else {
			var newMatch = result.a;
			return $elm$core$Maybe$Just(
				_Utils_Tuple2(
					remainTokens,
					A2($elm$core$List$cons, newMatch, matches)));
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$codeAutolinkTypeHtmlTagTTM = F5(
	function (remaining, tokens, matches, references, rawText) {
		codeAutolinkTypeHtmlTagTTM:
		while (true) {
			if (!remaining.b) {
				return A5(
					$dillonkearns$elm_markdown$Markdown$InlineParser$htmlElementTTM,
					$elm$core$List$reverse(tokens),
					_List_Nil,
					matches,
					references,
					rawText);
			} else {
				var token = remaining.a;
				var tokensTail = remaining.b;
				var _v36 = token.f;
				switch (_v36.$) {
					case 0:
						var _v37 = A2(
							$dillonkearns$elm_markdown$Markdown$InlineParser$findToken,
							$dillonkearns$elm_markdown$Markdown$InlineParser$isCodeTokenPair(token),
							tokens);
						if (!_v37.$) {
							var code = _v37.a;
							var _v38 = A5($dillonkearns$elm_markdown$Markdown$InlineParser$codeToMatch, token, matches, references, rawText, code);
							var newTokens = _v38.a;
							var newMatches = _v38.b;
							var $temp$remaining = tokensTail,
								$temp$tokens = newTokens,
								$temp$matches = newMatches,
								$temp$references = references,
								$temp$rawText = rawText;
							remaining = $temp$remaining;
							tokens = $temp$tokens;
							matches = $temp$matches;
							references = $temp$references;
							rawText = $temp$rawText;
							continue codeAutolinkTypeHtmlTagTTM;
						} else {
							var $temp$remaining = tokensTail,
								$temp$tokens = A2($elm$core$List$cons, token, tokens),
								$temp$matches = matches,
								$temp$references = references,
								$temp$rawText = rawText;
							remaining = $temp$remaining;
							tokens = $temp$tokens;
							matches = $temp$matches;
							references = $temp$references;
							rawText = $temp$rawText;
							continue codeAutolinkTypeHtmlTagTTM;
						}
					case 5:
						var isEscaped = _v36.a;
						var isAngleBracketOpen = function (_v43) {
							var meaning = _v43.f;
							if (meaning.$ === 4) {
								return true;
							} else {
								return false;
							}
						};
						var _v39 = A2($dillonkearns$elm_markdown$Markdown$InlineParser$findToken, isAngleBracketOpen, tokens);
						if (!_v39.$) {
							var found = _v39.a;
							var _v40 = A6($dillonkearns$elm_markdown$Markdown$InlineParser$angleBracketsToMatch, token, isEscaped, matches, references, rawText, found);
							if (!_v40.$) {
								var _v41 = _v40.a;
								var newTokens = _v41.a;
								var newMatches = _v41.b;
								var $temp$remaining = tokensTail,
									$temp$tokens = A2(
									$elm$core$List$filter,
									A2($elm$core$Basics$composeL, $elm$core$Basics$not, isAngleBracketOpen),
									newTokens),
									$temp$matches = newMatches,
									$temp$references = references,
									$temp$rawText = rawText;
								remaining = $temp$remaining;
								tokens = $temp$tokens;
								matches = $temp$matches;
								references = $temp$references;
								rawText = $temp$rawText;
								continue codeAutolinkTypeHtmlTagTTM;
							} else {
								var $temp$remaining = tokensTail,
									$temp$tokens = A2(
									$elm$core$List$filter,
									A2($elm$core$Basics$composeL, $elm$core$Basics$not, isAngleBracketOpen),
									tokens),
									$temp$matches = matches,
									$temp$references = references,
									$temp$rawText = rawText;
								remaining = $temp$remaining;
								tokens = $temp$tokens;
								matches = $temp$matches;
								references = $temp$references;
								rawText = $temp$rawText;
								continue codeAutolinkTypeHtmlTagTTM;
							}
						} else {
							var $temp$remaining = tokensTail,
								$temp$tokens = A2(
								$elm$core$List$filter,
								A2($elm$core$Basics$composeL, $elm$core$Basics$not, isAngleBracketOpen),
								tokens),
								$temp$matches = matches,
								$temp$references = references,
								$temp$rawText = rawText;
							remaining = $temp$remaining;
							tokens = $temp$tokens;
							matches = $temp$matches;
							references = $temp$references;
							rawText = $temp$rawText;
							continue codeAutolinkTypeHtmlTagTTM;
						}
					default:
						var $temp$remaining = tokensTail,
							$temp$tokens = A2($elm$core$List$cons, token, tokens),
							$temp$matches = matches,
							$temp$references = references,
							$temp$rawText = rawText;
						remaining = $temp$remaining;
						tokens = $temp$tokens;
						matches = $temp$matches;
						references = $temp$references;
						rawText = $temp$rawText;
						continue codeAutolinkTypeHtmlTagTTM;
				}
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$codeToMatch = F5(
	function (closeToken, matches, references, rawText, _v32) {
		var openToken = _v32.a;
		var remainTokens = _v32.c;
		var updatedOpenToken = function () {
			var _v33 = openToken.f;
			if ((!_v33.$) && (!_v33.a)) {
				var _v34 = _v33.a;
				return _Utils_update(
					openToken,
					{d: openToken.d + 1, bf: openToken.bf - 1});
			} else {
				return openToken;
			}
		}();
		var match = A7($dillonkearns$elm_markdown$Markdown$InlineParser$tokenPairToMatch, references, rawText, $dillonkearns$elm_markdown$Markdown$Helpers$cleanWhitespaces, $dillonkearns$elm_markdown$Markdown$InlineParser$CodeType, updatedOpenToken, closeToken, _List_Nil);
		return _Utils_Tuple2(
			remainTokens,
			A2($elm$core$List$cons, match, matches));
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$emphasisTTM = F5(
	function (remaining, tokens, matches, references, rawText) {
		emphasisTTM:
		while (true) {
			if (!remaining.b) {
				return A5(
					$dillonkearns$elm_markdown$Markdown$InlineParser$strikethroughTTM,
					$elm$core$List$reverse(tokens),
					_List_Nil,
					matches,
					references,
					rawText);
			} else {
				var token = remaining.a;
				var tokensTail = remaining.b;
				var _v27 = token.f;
				if (_v27.$ === 7) {
					var _char = _v27.a;
					var leftFringeRank = _v27.b.aM;
					var rightFringeRank = _v27.b.aQ;
					if (_Utils_eq(leftFringeRank, rightFringeRank)) {
						if ((!(!rightFringeRank)) && ((_char !== '_') || (rightFringeRank === 1))) {
							var _v28 = A2(
								$dillonkearns$elm_markdown$Markdown$InlineParser$findToken,
								$dillonkearns$elm_markdown$Markdown$InlineParser$isOpenEmphasisToken(token),
								tokens);
							if (!_v28.$) {
								var found = _v28.a;
								var _v29 = A5($dillonkearns$elm_markdown$Markdown$InlineParser$emphasisToMatch, references, rawText, token, tokensTail, found);
								var newRemaining = _v29.a;
								var match = _v29.b;
								var newTokens = _v29.c;
								var $temp$remaining = newRemaining,
									$temp$tokens = newTokens,
									$temp$matches = A2($elm$core$List$cons, match, matches),
									$temp$references = references,
									$temp$rawText = rawText;
								remaining = $temp$remaining;
								tokens = $temp$tokens;
								matches = $temp$matches;
								references = $temp$references;
								rawText = $temp$rawText;
								continue emphasisTTM;
							} else {
								var $temp$remaining = tokensTail,
									$temp$tokens = A2($elm$core$List$cons, token, tokens),
									$temp$matches = matches,
									$temp$references = references,
									$temp$rawText = rawText;
								remaining = $temp$remaining;
								tokens = $temp$tokens;
								matches = $temp$matches;
								references = $temp$references;
								rawText = $temp$rawText;
								continue emphasisTTM;
							}
						} else {
							var $temp$remaining = tokensTail,
								$temp$tokens = tokens,
								$temp$matches = matches,
								$temp$references = references,
								$temp$rawText = rawText;
							remaining = $temp$remaining;
							tokens = $temp$tokens;
							matches = $temp$matches;
							references = $temp$references;
							rawText = $temp$rawText;
							continue emphasisTTM;
						}
					} else {
						if (_Utils_cmp(leftFringeRank, rightFringeRank) < 0) {
							var $temp$remaining = tokensTail,
								$temp$tokens = A2($elm$core$List$cons, token, tokens),
								$temp$matches = matches,
								$temp$references = references,
								$temp$rawText = rawText;
							remaining = $temp$remaining;
							tokens = $temp$tokens;
							matches = $temp$matches;
							references = $temp$references;
							rawText = $temp$rawText;
							continue emphasisTTM;
						} else {
							var _v30 = A2(
								$dillonkearns$elm_markdown$Markdown$InlineParser$findToken,
								$dillonkearns$elm_markdown$Markdown$InlineParser$isOpenEmphasisToken(token),
								tokens);
							if (!_v30.$) {
								var found = _v30.a;
								var _v31 = A5($dillonkearns$elm_markdown$Markdown$InlineParser$emphasisToMatch, references, rawText, token, tokensTail, found);
								var newRemaining = _v31.a;
								var match = _v31.b;
								var newTokens = _v31.c;
								var $temp$remaining = newRemaining,
									$temp$tokens = newTokens,
									$temp$matches = A2($elm$core$List$cons, match, matches),
									$temp$references = references,
									$temp$rawText = rawText;
								remaining = $temp$remaining;
								tokens = $temp$tokens;
								matches = $temp$matches;
								references = $temp$references;
								rawText = $temp$rawText;
								continue emphasisTTM;
							} else {
								var $temp$remaining = tokensTail,
									$temp$tokens = tokens,
									$temp$matches = matches,
									$temp$references = references,
									$temp$rawText = rawText;
								remaining = $temp$remaining;
								tokens = $temp$tokens;
								matches = $temp$matches;
								references = $temp$references;
								rawText = $temp$rawText;
								continue emphasisTTM;
							}
						}
					}
				} else {
					var $temp$remaining = tokensTail,
						$temp$tokens = A2($elm$core$List$cons, token, tokens),
						$temp$matches = matches,
						$temp$references = references,
						$temp$rawText = rawText;
					remaining = $temp$remaining;
					tokens = $temp$tokens;
					matches = $temp$matches;
					references = $temp$references;
					rawText = $temp$rawText;
					continue emphasisTTM;
				}
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$emphasisToMatch = F5(
	function (references, rawText, closeToken, tokensTail, _v25) {
		var openToken = _v25.a;
		var innerTokens = _v25.b;
		var remainTokens = _v25.c;
		var remainLength = openToken.bf - closeToken.bf;
		var updt = (!remainLength) ? {aH: closeToken, au: openToken, aP: remainTokens, aZ: tokensTail} : ((remainLength > 0) ? {
			aH: closeToken,
			au: _Utils_update(
				openToken,
				{d: openToken.d + remainLength, bf: closeToken.bf}),
			aP: A2(
				$elm$core$List$cons,
				_Utils_update(
					openToken,
					{bf: remainLength}),
				remainTokens),
			aZ: tokensTail
		} : {
			aH: _Utils_update(
				closeToken,
				{bf: openToken.bf}),
			au: openToken,
			aP: remainTokens,
			aZ: A2(
				$elm$core$List$cons,
				_Utils_update(
					closeToken,
					{d: closeToken.d + openToken.bf, bf: -remainLength}),
				tokensTail)
		});
		var match = A7(
			$dillonkearns$elm_markdown$Markdown$InlineParser$tokenPairToMatch,
			references,
			rawText,
			function (s) {
				return s;
			},
			$dillonkearns$elm_markdown$Markdown$InlineParser$EmphasisType(updt.au.bf),
			updt.au,
			updt.aH,
			$elm$core$List$reverse(innerTokens));
		return _Utils_Tuple3(updt.aZ, match, updt.aP);
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$htmlElementTTM = F5(
	function (remaining, tokens, matches, references, rawText) {
		htmlElementTTM:
		while (true) {
			if (!remaining.b) {
				return A5(
					$dillonkearns$elm_markdown$Markdown$InlineParser$linkImageTypeTTM,
					$elm$core$List$reverse(tokens),
					_List_Nil,
					matches,
					references,
					rawText);
			} else {
				var token = remaining.a;
				var tokensTail = remaining.b;
				var _v23 = token.f;
				if (_v23.$ === 6) {
					var isOpen = _v23.a;
					var htmlModel = _v23.b;
					var $temp$remaining = tokensTail,
						$temp$tokens = tokens,
						$temp$matches = A2(
						$elm$core$List$cons,
						A2(
							$dillonkearns$elm_markdown$Markdown$InlineParser$tokenToMatch,
							token,
							$dillonkearns$elm_markdown$Markdown$InlineParser$HtmlType(htmlModel)),
						matches),
						$temp$references = references,
						$temp$rawText = rawText;
					remaining = $temp$remaining;
					tokens = $temp$tokens;
					matches = $temp$matches;
					references = $temp$references;
					rawText = $temp$rawText;
					continue htmlElementTTM;
				} else {
					var $temp$remaining = tokensTail,
						$temp$tokens = A2($elm$core$List$cons, token, tokens),
						$temp$matches = matches,
						$temp$references = references,
						$temp$rawText = rawText;
					remaining = $temp$remaining;
					tokens = $temp$tokens;
					matches = $temp$matches;
					references = $temp$references;
					rawText = $temp$rawText;
					continue htmlElementTTM;
				}
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$linkImageTypeTTM = F5(
	function (remaining, tokens, matches, references, rawText) {
		linkImageTypeTTM:
		while (true) {
			if (!remaining.b) {
				return A5(
					$dillonkearns$elm_markdown$Markdown$InlineParser$emphasisTTM,
					$elm$core$List$reverse(tokens),
					_List_Nil,
					matches,
					references,
					rawText);
			} else {
				var token = remaining.a;
				var tokensTail = remaining.b;
				var _v18 = token.f;
				if (_v18.$ === 3) {
					var _v19 = A2($dillonkearns$elm_markdown$Markdown$InlineParser$findToken, $dillonkearns$elm_markdown$Markdown$InlineParser$isLinkTypeOrImageOpenToken, tokens);
					if (!_v19.$) {
						var found = _v19.a;
						var _v20 = A6($dillonkearns$elm_markdown$Markdown$InlineParser$linkOrImageTypeToMatch, token, tokensTail, matches, references, rawText, found);
						if (!_v20.$) {
							var _v21 = _v20.a;
							var x = _v21.a;
							var newMatches = _v21.b;
							var newTokens = _v21.c;
							var $temp$remaining = x,
								$temp$tokens = newTokens,
								$temp$matches = newMatches,
								$temp$references = references,
								$temp$rawText = rawText;
							remaining = $temp$remaining;
							tokens = $temp$tokens;
							matches = $temp$matches;
							references = $temp$references;
							rawText = $temp$rawText;
							continue linkImageTypeTTM;
						} else {
							var $temp$remaining = tokensTail,
								$temp$tokens = tokens,
								$temp$matches = matches,
								$temp$references = references,
								$temp$rawText = rawText;
							remaining = $temp$remaining;
							tokens = $temp$tokens;
							matches = $temp$matches;
							references = $temp$references;
							rawText = $temp$rawText;
							continue linkImageTypeTTM;
						}
					} else {
						var $temp$remaining = tokensTail,
							$temp$tokens = tokens,
							$temp$matches = matches,
							$temp$references = references,
							$temp$rawText = rawText;
						remaining = $temp$remaining;
						tokens = $temp$tokens;
						matches = $temp$matches;
						references = $temp$references;
						rawText = $temp$rawText;
						continue linkImageTypeTTM;
					}
				} else {
					var $temp$remaining = tokensTail,
						$temp$tokens = A2($elm$core$List$cons, token, tokens),
						$temp$matches = matches,
						$temp$references = references,
						$temp$rawText = rawText;
					remaining = $temp$remaining;
					tokens = $temp$tokens;
					matches = $temp$matches;
					references = $temp$references;
					rawText = $temp$rawText;
					continue linkImageTypeTTM;
				}
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$linkOrImageTypeToMatch = F6(
	function (closeToken, tokensTail, oldMatches, references, rawText, _v8) {
		var openToken = _v8.a;
		var innerTokens = _v8.b;
		var remainTokens = _v8.c;
		var removeOpenToken = _Utils_Tuple3(
			tokensTail,
			oldMatches,
			_Utils_ap(innerTokens, remainTokens));
		var remainText = A2($elm$core$String$dropLeft, closeToken.d + 1, rawText);
		var inactivateLinkOpenToken = function (token) {
			var _v16 = token.f;
			if (_v16.$ === 1) {
				return _Utils_update(
					token,
					{
						f: $dillonkearns$elm_markdown$Markdown$InlineParser$LinkOpenToken(1)
					});
			} else {
				return token;
			}
		};
		var findTempMatch = function (isLinkType) {
			return A7(
				$dillonkearns$elm_markdown$Markdown$InlineParser$tokenPairToMatch,
				references,
				rawText,
				function (s) {
					return s;
				},
				isLinkType ? $dillonkearns$elm_markdown$Markdown$InlineParser$LinkType(
					_Utils_Tuple2('', $elm$core$Maybe$Nothing)) : $dillonkearns$elm_markdown$Markdown$InlineParser$ImageType(
					_Utils_Tuple2('', $elm$core$Maybe$Nothing)),
				openToken,
				closeToken,
				$elm$core$List$reverse(innerTokens));
		};
		var _v9 = openToken.f;
		switch (_v9.$) {
			case 2:
				var tempMatch = findTempMatch(false);
				var _v10 = A3($dillonkearns$elm_markdown$Markdown$InlineParser$checkForInlineLinkTypeOrImageType, remainText, tempMatch, references);
				if (_v10.$ === 1) {
					return $elm$core$Maybe$Just(removeOpenToken);
				} else {
					var match = _v10.a;
					var _v11 = A2($dillonkearns$elm_markdown$Markdown$InlineParser$checkParsedAheadOverlapping, match, oldMatches);
					if (!_v11.$) {
						var matches = _v11.a;
						return $elm$core$Maybe$Just(
							_Utils_Tuple3(
								A2($dillonkearns$elm_markdown$Markdown$InlineParser$removeParsedAheadTokens, match, tokensTail),
								matches,
								remainTokens));
					} else {
						return $elm$core$Maybe$Just(removeOpenToken);
					}
				}
			case 1:
				if (!_v9.a) {
					var _v12 = _v9.a;
					var tempMatch = findTempMatch(true);
					var _v13 = A3($dillonkearns$elm_markdown$Markdown$InlineParser$checkForInlineLinkTypeOrImageType, remainText, tempMatch, references);
					if (_v13.$ === 1) {
						return $elm$core$Maybe$Just(removeOpenToken);
					} else {
						var match = _v13.a;
						var _v14 = A2($dillonkearns$elm_markdown$Markdown$InlineParser$checkParsedAheadOverlapping, match, oldMatches);
						if (!_v14.$) {
							var matches = _v14.a;
							return $elm$core$Maybe$Just(
								_Utils_Tuple3(
									A2($dillonkearns$elm_markdown$Markdown$InlineParser$removeParsedAheadTokens, match, tokensTail),
									matches,
									A2($elm$core$List$map, inactivateLinkOpenToken, remainTokens)));
						} else {
							return $elm$core$Maybe$Just(removeOpenToken);
						}
					}
				} else {
					var _v15 = _v9.a;
					return $elm$core$Maybe$Just(removeOpenToken);
				}
			default:
				return $elm$core$Maybe$Nothing;
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$strikethroughTTM = F5(
	function (remaining, tokens, matches, references, rawText) {
		strikethroughTTM:
		while (true) {
			if (!remaining.b) {
				return A2(
					$dillonkearns$elm_markdown$Markdown$InlineParser$lineBreakTTM,
					$elm$core$List$reverse(tokens),
					matches);
			} else {
				var token = remaining.a;
				var tokensTail = remaining.b;
				var _v5 = token.f;
				if (_v5.$ === 9) {
					var _v6 = A2(
						$dillonkearns$elm_markdown$Markdown$InlineParser$findToken,
						$dillonkearns$elm_markdown$Markdown$InlineParser$isStrikethroughTokenPair(token),
						tokens);
					if (!_v6.$) {
						var content = _v6.a;
						var _v7 = A5($dillonkearns$elm_markdown$Markdown$InlineParser$strikethroughToMatch, token, matches, references, rawText, content);
						var newTokens = _v7.a;
						var newMatches = _v7.b;
						var $temp$remaining = tokensTail,
							$temp$tokens = newTokens,
							$temp$matches = newMatches,
							$temp$references = references,
							$temp$rawText = rawText;
						remaining = $temp$remaining;
						tokens = $temp$tokens;
						matches = $temp$matches;
						references = $temp$references;
						rawText = $temp$rawText;
						continue strikethroughTTM;
					} else {
						var $temp$remaining = tokensTail,
							$temp$tokens = A2($elm$core$List$cons, token, tokens),
							$temp$matches = matches,
							$temp$references = references,
							$temp$rawText = rawText;
						remaining = $temp$remaining;
						tokens = $temp$tokens;
						matches = $temp$matches;
						references = $temp$references;
						rawText = $temp$rawText;
						continue strikethroughTTM;
					}
				} else {
					var $temp$remaining = tokensTail,
						$temp$tokens = A2($elm$core$List$cons, token, tokens),
						$temp$matches = matches,
						$temp$references = references,
						$temp$rawText = rawText;
					remaining = $temp$remaining;
					tokens = $temp$tokens;
					matches = $temp$matches;
					references = $temp$references;
					rawText = $temp$rawText;
					continue strikethroughTTM;
				}
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$strikethroughToMatch = F5(
	function (closeToken, matches, references, rawText, _v1) {
		var openToken = _v1.a;
		var remainTokens = _v1.c;
		var updatedOpenToken = function () {
			var _v2 = openToken.f;
			if ((_v2.$ === 9) && (!_v2.a)) {
				var _v3 = _v2.a;
				return _Utils_update(
					openToken,
					{d: openToken.d + 1, bf: openToken.bf - 1});
			} else {
				return openToken;
			}
		}();
		var match = A7($dillonkearns$elm_markdown$Markdown$InlineParser$tokenPairToMatch, references, rawText, $dillonkearns$elm_markdown$Markdown$Helpers$cleanWhitespaces, $dillonkearns$elm_markdown$Markdown$InlineParser$StrikethroughType, updatedOpenToken, closeToken, _List_Nil);
		return _Utils_Tuple2(
			remainTokens,
			A2($elm$core$List$cons, match, matches));
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$tokenPairToMatch = F7(
	function (references, rawText, processText, type_, openToken, closeToken, innerTokens) {
		var textStart = openToken.d + openToken.bf;
		var textEnd = closeToken.d;
		var text = processText(
			A3($elm$core$String$slice, textStart, textEnd, rawText));
		var start = openToken.d;
		var end = closeToken.d + closeToken.bf;
		var match = {i: end, v: _List_Nil, k: start, dX: text, I: textEnd, x: textStart, n: type_};
		var matches = A2(
			$elm$core$List$map,
			function (_v0) {
				var matchModel = _v0;
				return A2($dillonkearns$elm_markdown$Markdown$InlineParser$prepareChildMatch, match, matchModel);
			},
			A4($dillonkearns$elm_markdown$Markdown$InlineParser$tokensToMatches, innerTokens, _List_Nil, references, rawText));
		return {i: end, v: matches, k: start, dX: text, I: textEnd, x: textStart, n: type_};
	});
var $dillonkearns$elm_markdown$Markdown$InlineParser$tokensToMatches = F4(
	function (tokens, matches, references, rawText) {
		return A5($dillonkearns$elm_markdown$Markdown$InlineParser$codeAutolinkTypeHtmlTagTTM, tokens, _List_Nil, matches, references, rawText);
	});
var $elm$core$String$trim = _String_trim;
var $dillonkearns$elm_markdown$Markdown$InlineParser$parse = F2(
	function (refs, rawText_) {
		var rawText = $elm$core$String$trim(rawText_);
		var tokens = $dillonkearns$elm_markdown$Markdown$InlineParser$tokenize(rawText);
		return $dillonkearns$elm_markdown$Markdown$InlineParser$matchesToInlines(
			A3(
				$dillonkearns$elm_markdown$Markdown$InlineParser$parseTextMatches,
				rawText,
				_List_Nil,
				$dillonkearns$elm_markdown$Markdown$InlineParser$organizeMatches(
					A4($dillonkearns$elm_markdown$Markdown$InlineParser$tokensToMatches, tokens, _List_Nil, refs, rawText))));
	});
var $dillonkearns$elm_markdown$Markdown$Parser$thisIsDefinitelyNotAnHtmlTag = $elm$parser$Parser$Advanced$oneOf(
	_List_fromArray(
		[
			$elm$parser$Parser$Advanced$token(
			A2(
				$elm$parser$Parser$Advanced$Token,
				' ',
				$elm$parser$Parser$Expecting(' '))),
			$elm$parser$Parser$Advanced$token(
			A2(
				$elm$parser$Parser$Advanced$Token,
				'>',
				$elm$parser$Parser$Expecting('>'))),
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				A2(
					$elm$parser$Parser$Advanced$chompIf,
					$elm$core$Char$isAlpha,
					$elm$parser$Parser$Expecting('Alpha')),
				$elm$parser$Parser$Advanced$chompWhile(
					function (c) {
						return $elm$core$Char$isAlphaNum(c) || (c === '-');
					})),
			$elm$parser$Parser$Advanced$oneOf(
				_List_fromArray(
					[
						$elm$parser$Parser$Advanced$token(
						A2(
							$elm$parser$Parser$Advanced$Token,
							':',
							$elm$parser$Parser$Expecting(':'))),
						$elm$parser$Parser$Advanced$token(
						A2(
							$elm$parser$Parser$Advanced$Token,
							'@',
							$elm$parser$Parser$Expecting('@'))),
						$elm$parser$Parser$Advanced$token(
						A2(
							$elm$parser$Parser$Advanced$Token,
							'\\',
							$elm$parser$Parser$Expecting('\\'))),
						$elm$parser$Parser$Advanced$token(
						A2(
							$elm$parser$Parser$Advanced$Token,
							'+',
							$elm$parser$Parser$Expecting('+'))),
						$elm$parser$Parser$Advanced$token(
						A2(
							$elm$parser$Parser$Advanced$Token,
							'.',
							$elm$parser$Parser$Expecting('.')))
					])))
		]));
var $dillonkearns$elm_markdown$Markdown$Parser$parseAsParagraphInsteadOfHtmlBlock = $elm$parser$Parser$Advanced$backtrackable(
	A2(
		$elm$parser$Parser$Advanced$mapChompedString,
		F2(
			function (rawLine, _v0) {
				return $dillonkearns$elm_markdown$Markdown$RawBlock$OpenBlockOrParagraph(rawLine);
			}),
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$elm$parser$Parser$Advanced$token(
						A2(
							$elm$parser$Parser$Advanced$Token,
							'<',
							$elm$parser$Parser$Expecting('<'))),
					$dillonkearns$elm_markdown$Markdown$Parser$thisIsDefinitelyNotAnHtmlTag),
				$dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd),
			$dillonkearns$elm_markdown$Helpers$lineEndOrEnd)));
var $dillonkearns$elm_markdown$Markdown$Table$TableHeader = $elm$core$Basics$identity;
var $dillonkearns$elm_markdown$Parser$Token$parseString = function (str) {
	return $elm$parser$Parser$Advanced$token(
		A2(
			$elm$parser$Parser$Advanced$Token,
			str,
			$elm$parser$Parser$Expecting(str)));
};
var $dillonkearns$elm_markdown$Markdown$TableParser$parseCellHelper = function (_v0) {
	var curr = _v0.a;
	var acc = _v0.b;
	var _return = A2(
		$elm$core$Maybe$withDefault,
		$elm$parser$Parser$Advanced$Done(acc),
		A2(
			$elm$core$Maybe$map,
			function (cell) {
				return $elm$parser$Parser$Advanced$Done(
					A2($elm$core$List$cons, cell, acc));
			},
			curr));
	var finishCell = A2(
		$elm$core$Maybe$withDefault,
		$elm$parser$Parser$Advanced$Loop(
			_Utils_Tuple2($elm$core$Maybe$Nothing, acc)),
		A2(
			$elm$core$Maybe$map,
			function (cell) {
				return $elm$parser$Parser$Advanced$Loop(
					_Utils_Tuple2(
						$elm$core$Maybe$Nothing,
						A2($elm$core$List$cons, cell, acc)));
			},
			curr));
	var addToCurrent = function (c) {
		return _Utils_ap(
			A2($elm$core$Maybe$withDefault, '', curr),
			c);
	};
	var continueCell = function (c) {
		return $elm$parser$Parser$Advanced$Loop(
			_Utils_Tuple2(
				$elm$core$Maybe$Just(
					addToCurrent(c)),
				acc));
	};
	return $elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$parser$Parser$Advanced$map,
				function (_v1) {
					return _return;
				},
				$dillonkearns$elm_markdown$Parser$Token$parseString('|\n')),
				A2(
				$elm$parser$Parser$Advanced$map,
				function (_v2) {
					return _return;
				},
				$dillonkearns$elm_markdown$Parser$Token$parseString('\n')),
				A2(
				$elm$parser$Parser$Advanced$map,
				function (_v3) {
					return _return;
				},
				$elm$parser$Parser$Advanced$end(
					$elm$parser$Parser$Expecting('end'))),
				A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$backtrackable(
					$elm$parser$Parser$Advanced$succeed(
						continueCell('|'))),
				$dillonkearns$elm_markdown$Parser$Token$parseString('\\\\|')),
				A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$backtrackable(
					$elm$parser$Parser$Advanced$succeed(
						continueCell('\\'))),
				$dillonkearns$elm_markdown$Parser$Token$parseString('\\\\')),
				A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$backtrackable(
					$elm$parser$Parser$Advanced$succeed(
						continueCell('|'))),
				$dillonkearns$elm_markdown$Parser$Token$parseString('\\|')),
				A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$backtrackable(
					$elm$parser$Parser$Advanced$succeed(finishCell)),
				$dillonkearns$elm_markdown$Parser$Token$parseString('|')),
				A2(
				$elm$parser$Parser$Advanced$mapChompedString,
				F2(
					function (_char, _v4) {
						return continueCell(_char);
					}),
				A2(
					$elm$parser$Parser$Advanced$chompIf,
					$elm$core$Basics$always(true),
					$elm$parser$Parser$Problem('No character found')))
			]));
};
var $dillonkearns$elm_markdown$Markdown$TableParser$parseCells = A2(
	$elm$parser$Parser$Advanced$map,
	A2(
		$elm$core$List$foldl,
		F2(
			function (cell, acc) {
				return A2(
					$elm$core$List$cons,
					$elm$core$String$trim(cell),
					acc);
			}),
		_List_Nil),
	A2(
		$elm$parser$Parser$Advanced$loop,
		_Utils_Tuple2($elm$core$Maybe$Nothing, _List_Nil),
		$dillonkearns$elm_markdown$Markdown$TableParser$parseCellHelper));
var $dillonkearns$elm_markdown$Markdown$TableParser$rowParser = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
		$elm$parser$Parser$Advanced$oneOf(
			_List_fromArray(
				[
					$dillonkearns$elm_markdown$Parser$Token$parseString('|'),
					$elm$parser$Parser$Advanced$succeed(0)
				]))),
	$dillonkearns$elm_markdown$Markdown$TableParser$parseCells);
var $dillonkearns$elm_markdown$Markdown$TableParser$parseHeader = F2(
	function (_v0, headersRow) {
		var columnAlignments = _v0.b;
		var headersWithAlignment = function (headers) {
			return A3(
				$elm$core$List$map2,
				F2(
					function (headerCell, alignment) {
						return {aD: alignment, ai: headerCell};
					}),
				headers,
				columnAlignments);
		};
		var combineHeaderAndDelimiter = function (headers) {
			return _Utils_eq(
				$elm$core$List$length(headers),
				$elm$core$List$length(columnAlignments)) ? $elm$core$Result$Ok(
				headersWithAlignment(headers)) : $elm$core$Result$Err(
				'Tables must have the same number of header columns (' + ($elm$core$String$fromInt(
					$elm$core$List$length(headers)) + (') as delimiter columns (' + ($elm$core$String$fromInt(
					$elm$core$List$length(columnAlignments)) + ')'))));
		};
		var _v1 = A2($elm$parser$Parser$Advanced$run, $dillonkearns$elm_markdown$Markdown$TableParser$rowParser, headersRow);
		if (!_v1.$) {
			var headers = _v1.a;
			return combineHeaderAndDelimiter(headers);
		} else {
			return $elm$core$Result$Err('Unable to parse previous line as a table header');
		}
	});
var $dillonkearns$elm_markdown$Markdown$CodeBlock$CodeBlock = F2(
	function (language, body) {
		return {cW: body, dn: language};
	});
var $dillonkearns$elm_markdown$Markdown$CodeBlock$infoString = function (fenceCharacter) {
	var toInfoString = F2(
		function (str, _v2) {
			var _v1 = $elm$core$String$trim(str);
			if (_v1 === '') {
				return $elm$core$Maybe$Nothing;
			} else {
				var trimmed = _v1;
				return $elm$core$Maybe$Just(trimmed);
			}
		});
	var _v0 = fenceCharacter.aL;
	if (!_v0) {
		return A2(
			$elm$parser$Parser$Advanced$mapChompedString,
			toInfoString,
			$elm$parser$Parser$Advanced$chompWhile(
				function (c) {
					return (c !== '`') && (!$dillonkearns$elm_markdown$Whitespace$isLineEnd(c));
				}));
	} else {
		return A2(
			$elm$parser$Parser$Advanced$mapChompedString,
			toInfoString,
			$elm$parser$Parser$Advanced$chompWhile(
				A2($elm$core$Basics$composeL, $elm$core$Basics$not, $dillonkearns$elm_markdown$Whitespace$isLineEnd)));
	}
};
var $dillonkearns$elm_markdown$Markdown$CodeBlock$Backtick = 0;
var $dillonkearns$elm_markdown$Parser$Token$backtick = A2(
	$elm$parser$Parser$Advanced$Token,
	'`',
	$elm$parser$Parser$Expecting('a \'`\''));
var $dillonkearns$elm_markdown$Markdown$CodeBlock$backtick = {aE: '`', aL: 0, aY: $dillonkearns$elm_markdown$Parser$Token$backtick};
var $dillonkearns$elm_markdown$Markdown$CodeBlock$colToIndentation = function (_int) {
	switch (_int) {
		case 1:
			return $elm$parser$Parser$Advanced$succeed(0);
		case 2:
			return $elm$parser$Parser$Advanced$succeed(1);
		case 3:
			return $elm$parser$Parser$Advanced$succeed(2);
		case 4:
			return $elm$parser$Parser$Advanced$succeed(3);
		default:
			return $elm$parser$Parser$Advanced$problem(
				$elm$parser$Parser$Expecting('Fenced code blocks should be indented no more than 3 spaces'));
	}
};
var $dillonkearns$elm_markdown$Markdown$CodeBlock$fenceOfAtLeast = F2(
	function (minLength, fenceCharacter) {
		var builtTokens = A3(
			$elm$core$List$foldl,
			F2(
				function (t, p) {
					return A2($elm$parser$Parser$Advanced$ignorer, p, t);
				}),
			$elm$parser$Parser$Advanced$succeed(0),
			A2(
				$elm$core$List$repeat,
				minLength,
				$elm$parser$Parser$Advanced$token(fenceCharacter.aY)));
		return A2(
			$elm$parser$Parser$Advanced$mapChompedString,
			F2(
				function (str, _v0) {
					return _Utils_Tuple2(
						fenceCharacter,
						$elm$core$String$length(str));
				}),
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				builtTokens,
				$elm$parser$Parser$Advanced$chompWhile(
					$elm$core$Basics$eq(fenceCharacter.aE))));
	});
var $dillonkearns$elm_markdown$Markdown$CodeBlock$Tilde = 1;
var $dillonkearns$elm_markdown$Parser$Token$tilde = A2(
	$elm$parser$Parser$Advanced$Token,
	'~',
	$elm$parser$Parser$Expecting('a `~`'));
var $dillonkearns$elm_markdown$Markdown$CodeBlock$tilde = {aE: '~', aL: 1, aY: $dillonkearns$elm_markdown$Parser$Token$tilde};
var $dillonkearns$elm_markdown$Whitespace$upToThreeSpaces = $elm$parser$Parser$Advanced$oneOf(
	_List_fromArray(
		[
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				$dillonkearns$elm_markdown$Whitespace$space,
				$elm$parser$Parser$Advanced$oneOf(
					_List_fromArray(
						[
							$dillonkearns$elm_markdown$Whitespace$space,
							$elm$parser$Parser$Advanced$succeed(0)
						]))),
			$elm$parser$Parser$Advanced$oneOf(
				_List_fromArray(
					[
						$dillonkearns$elm_markdown$Whitespace$space,
						$elm$parser$Parser$Advanced$succeed(0)
					]))),
			$elm$parser$Parser$Advanced$succeed(0)
		]));
var $dillonkearns$elm_markdown$Markdown$CodeBlock$openingFence = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed(
				F2(
					function (indent, _v0) {
						var character = _v0.a;
						var length = _v0.b;
						return {aF: character, be: indent, bf: length};
					})),
			$dillonkearns$elm_markdown$Whitespace$upToThreeSpaces),
		A2($elm$parser$Parser$Advanced$andThen, $dillonkearns$elm_markdown$Markdown$CodeBlock$colToIndentation, $elm$parser$Parser$Advanced$getCol)),
	$elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				A2($dillonkearns$elm_markdown$Markdown$CodeBlock$fenceOfAtLeast, 3, $dillonkearns$elm_markdown$Markdown$CodeBlock$backtick),
				A2($dillonkearns$elm_markdown$Markdown$CodeBlock$fenceOfAtLeast, 3, $dillonkearns$elm_markdown$Markdown$CodeBlock$tilde)
			])));
var $elm$parser$Parser$ExpectingEnd = {$: 10};
var $dillonkearns$elm_markdown$Whitespace$isSpace = $elm$core$Basics$eq(' ');
var $dillonkearns$elm_markdown$Markdown$CodeBlock$closingFence = F2(
	function (minLength, fenceCharacter) {
		return A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					A2(
						$elm$parser$Parser$Advanced$ignorer,
						$elm$parser$Parser$Advanced$succeed(0),
						$dillonkearns$elm_markdown$Whitespace$upToThreeSpaces),
					A2($dillonkearns$elm_markdown$Markdown$CodeBlock$fenceOfAtLeast, minLength, fenceCharacter)),
				$elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$Whitespace$isSpace)),
			$dillonkearns$elm_markdown$Helpers$lineEndOrEnd);
	});
var $dillonkearns$elm_markdown$Markdown$CodeBlock$codeBlockLine = function (indented) {
	return A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
			A2($dillonkearns$elm_markdown$Parser$Extra$upTo, indented, $dillonkearns$elm_markdown$Whitespace$space)),
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2($elm$parser$Parser$Advanced$ignorer, $elm$parser$Parser$Advanced$getOffset, $dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd),
			$dillonkearns$elm_markdown$Helpers$lineEndOrEnd));
};
var $elm$parser$Parser$Advanced$getSource = function (s) {
	return A3($elm$parser$Parser$Advanced$Good, false, s.bq, s);
};
var $dillonkearns$elm_markdown$Markdown$CodeBlock$remainingBlockHelp = function (_v0) {
	var fence = _v0.a;
	var body = _v0.b;
	return $elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$succeed(
					$elm$parser$Parser$Advanced$Done(body)),
				$elm$parser$Parser$Advanced$end($elm$parser$Parser$ExpectingEnd)),
				A2(
				$elm$parser$Parser$Advanced$mapChompedString,
				F2(
					function (lineEnd, _v1) {
						return $elm$parser$Parser$Advanced$Loop(
							_Utils_Tuple2(
								fence,
								_Utils_ap(body, lineEnd)));
					}),
				$dillonkearns$elm_markdown$Whitespace$lineEnd),
				$elm$parser$Parser$Advanced$backtrackable(
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$elm$parser$Parser$Advanced$succeed(
						$elm$parser$Parser$Advanced$Done(body)),
					A2($dillonkearns$elm_markdown$Markdown$CodeBlock$closingFence, fence.bf, fence.aF))),
				A2(
				$elm$parser$Parser$Advanced$keeper,
				A2(
					$elm$parser$Parser$Advanced$keeper,
					A2(
						$elm$parser$Parser$Advanced$keeper,
						$elm$parser$Parser$Advanced$succeed(
							F3(
								function (start, end, source) {
									return $elm$parser$Parser$Advanced$Loop(
										_Utils_Tuple2(
											fence,
											_Utils_ap(
												body,
												A3($elm$core$String$slice, start, end, source))));
								})),
						$dillonkearns$elm_markdown$Markdown$CodeBlock$codeBlockLine(fence.be)),
					$elm$parser$Parser$Advanced$getOffset),
				$elm$parser$Parser$Advanced$getSource)
			]));
};
var $dillonkearns$elm_markdown$Markdown$CodeBlock$remainingBlock = function (fence) {
	return A2(
		$elm$parser$Parser$Advanced$loop,
		_Utils_Tuple2(fence, ''),
		$dillonkearns$elm_markdown$Markdown$CodeBlock$remainingBlockHelp);
};
var $dillonkearns$elm_markdown$Markdown$CodeBlock$parser = A2(
	$elm$parser$Parser$Advanced$andThen,
	function (fence) {
		return A2(
			$elm$parser$Parser$Advanced$keeper,
			A2(
				$elm$parser$Parser$Advanced$keeper,
				$elm$parser$Parser$Advanced$succeed($dillonkearns$elm_markdown$Markdown$CodeBlock$CodeBlock),
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$dillonkearns$elm_markdown$Markdown$CodeBlock$infoString(fence.aF),
					$dillonkearns$elm_markdown$Helpers$lineEndOrEnd)),
			$dillonkearns$elm_markdown$Markdown$CodeBlock$remainingBlock(fence));
	},
	$dillonkearns$elm_markdown$Markdown$CodeBlock$openingFence);
var $elm$core$String$dropRight = F2(
	function (n, string) {
		return (n < 1) ? string : A3($elm$core$String$slice, 0, -n, string);
	});
var $dillonkearns$elm_markdown$Markdown$Heading$dropTrailingHashes = function (headingString) {
	dropTrailingHashes:
	while (true) {
		if (A2($elm$core$String$endsWith, '#', headingString)) {
			var $temp$headingString = A2($elm$core$String$dropRight, 1, headingString);
			headingString = $temp$headingString;
			continue dropTrailingHashes;
		} else {
			return headingString;
		}
	}
};
var $elm$core$String$trimRight = _String_trimRight;
var $dillonkearns$elm_markdown$Markdown$Heading$dropClosingSequence = function (headingString) {
	var droppedTrailingHashesString = $dillonkearns$elm_markdown$Markdown$Heading$dropTrailingHashes(headingString);
	return (A2($elm$core$String$endsWith, ' ', droppedTrailingHashesString) || $elm$core$String$isEmpty(droppedTrailingHashesString)) ? $elm$core$String$trimRight(droppedTrailingHashesString) : headingString;
};
var $dillonkearns$elm_markdown$Parser$Token$hash = A2(
	$elm$parser$Parser$Advanced$Token,
	'#',
	$elm$parser$Parser$Expecting('a `#`'));
var $dillonkearns$elm_markdown$Markdown$Heading$isHash = function (c) {
	if ('#' === c) {
		return true;
	} else {
		return false;
	}
};
var $elm$parser$Parser$Advanced$spaces = $elm$parser$Parser$Advanced$chompWhile(
	function (c) {
		return (c === ' ') || ((c === '\n') || (c === '\r'));
	});
var $dillonkearns$elm_markdown$Markdown$Heading$parser = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$succeed($dillonkearns$elm_markdown$Markdown$RawBlock$Heading),
				A2(
					$elm$parser$Parser$Advanced$andThen,
					function (startingSpaces) {
						var startSpace = $elm$core$String$length(startingSpaces);
						return (startSpace >= 4) ? $elm$parser$Parser$Advanced$problem(
							$elm$parser$Parser$Expecting('heading with < 4 spaces in front')) : $elm$parser$Parser$Advanced$succeed(startSpace);
					},
					$elm$parser$Parser$Advanced$getChompedString($elm$parser$Parser$Advanced$spaces))),
			$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$hash)),
		A2(
			$elm$parser$Parser$Advanced$andThen,
			function (additionalHashes) {
				var level = $elm$core$String$length(additionalHashes) + 1;
				return (level >= 7) ? $elm$parser$Parser$Advanced$problem(
					$elm$parser$Parser$Expecting('heading with < 7 #\'s')) : $elm$parser$Parser$Advanced$succeed(level);
			},
			$elm$parser$Parser$Advanced$getChompedString(
				$elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$Markdown$Heading$isHash)))),
	$elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$succeed(''),
				$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$newline)),
				A2(
				$elm$parser$Parser$Advanced$keeper,
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
					$elm$parser$Parser$Advanced$oneOf(
						_List_fromArray(
							[
								$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$space),
								$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$tab)
							]))),
				A2(
					$elm$parser$Parser$Advanced$mapChompedString,
					F2(
						function (headingText, _v0) {
							return $dillonkearns$elm_markdown$Markdown$Heading$dropClosingSequence(
								$elm$core$String$trim(headingText));
						}),
					$dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd))
			])));
var $elm$parser$Parser$Advanced$findSubString = _Parser_findSubString;
var $elm$parser$Parser$Advanced$fromInfo = F4(
	function (row, col, x, context) {
		return A2(
			$elm$parser$Parser$Advanced$AddRight,
			$elm$parser$Parser$Advanced$Empty,
			A4($elm$parser$Parser$Advanced$DeadEnd, row, col, x, context));
	});
var $elm$parser$Parser$Advanced$chompUntil = function (_v0) {
	var str = _v0.a;
	var expecting = _v0.b;
	return function (s) {
		var _v1 = A5($elm$parser$Parser$Advanced$findSubString, str, s.e, s.dT, s.bO, s.bq);
		var newOffset = _v1.a;
		var newRow = _v1.b;
		var newCol = _v1.c;
		return _Utils_eq(newOffset, -1) ? A2(
			$elm$parser$Parser$Advanced$Bad,
			false,
			A4($elm$parser$Parser$Advanced$fromInfo, newRow, newCol, expecting, s.h)) : A3(
			$elm$parser$Parser$Advanced$Good,
			_Utils_cmp(s.e, newOffset) < 0,
			0,
			{bO: newCol, h: s.h, j: s.j, e: newOffset, dT: newRow, bq: s.bq});
	};
};
var $dillonkearns$elm_markdown$Parser$Token$greaterThan = A2(
	$elm$parser$Parser$Advanced$Token,
	'>',
	$elm$parser$Parser$Expecting('a `>`'));
var $elm$parser$Parser$Advanced$Located = F3(
	function (row, col, context) {
		return {bO: col, h: context, dT: row};
	});
var $elm$parser$Parser$Advanced$changeContext = F2(
	function (newContext, s) {
		return {bO: s.bO, h: newContext, j: s.j, e: s.e, dT: s.dT, bq: s.bq};
	});
var $elm$parser$Parser$Advanced$inContext = F2(
	function (context, _v0) {
		var parse = _v0;
		return function (s0) {
			var _v1 = parse(
				A2(
					$elm$parser$Parser$Advanced$changeContext,
					A2(
						$elm$core$List$cons,
						A3($elm$parser$Parser$Advanced$Located, s0.dT, s0.bO, context),
						s0.h),
					s0));
			if (!_v1.$) {
				var p = _v1.a;
				var a = _v1.b;
				var s1 = _v1.c;
				return A3(
					$elm$parser$Parser$Advanced$Good,
					p,
					a,
					A2($elm$parser$Parser$Advanced$changeContext, s0.h, s1));
			} else {
				var step = _v1;
				return step;
			}
		};
	});
var $dillonkearns$elm_markdown$Whitespace$isWhitespace = function (_char) {
	switch (_char) {
		case ' ':
			return true;
		case '\n':
			return true;
		case '\t':
			return true;
		case '\u000B':
			return true;
		case '\u000C':
			return true;
		case '\u000D':
			return true;
		default:
			return false;
	}
};
var $dillonkearns$elm_markdown$Parser$Token$lessThan = A2(
	$elm$parser$Parser$Advanced$Token,
	'<',
	$elm$parser$Parser$Expecting('a `<`'));
var $dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$destinationParser = A2(
	$elm$parser$Parser$Advanced$inContext,
	'link destination',
	$elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$parser$Parser$Advanced$keeper,
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$elm$parser$Parser$Advanced$succeed($elm$url$Url$percentEncode),
					$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$lessThan)),
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$elm$parser$Parser$Advanced$getChompedString(
						$elm$parser$Parser$Advanced$chompUntil($dillonkearns$elm_markdown$Parser$Token$greaterThan)),
					$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$greaterThan))),
				$elm$parser$Parser$Advanced$getChompedString(
				$dillonkearns$elm_markdown$Parser$Extra$chompOneOrMore(
					A2($elm$core$Basics$composeL, $elm$core$Basics$not, $dillonkearns$elm_markdown$Whitespace$isWhitespace)))
			])));
var $dillonkearns$elm_markdown$Parser$Token$closingSquareBracket = A2(
	$elm$parser$Parser$Advanced$Token,
	']',
	$elm$parser$Parser$Expecting('a `]`'));
var $dillonkearns$elm_markdown$Parser$Token$openingSquareBracket = A2(
	$elm$parser$Parser$Advanced$Token,
	'[',
	$elm$parser$Parser$Expecting('a `[`'));
var $dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$labelParser = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$succeed($dillonkearns$elm_markdown$Markdown$Helpers$prepareRefLabel),
		$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$openingSquareBracket)),
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$getChompedString(
			$elm$parser$Parser$Advanced$chompUntil($dillonkearns$elm_markdown$Parser$Token$closingSquareBracket)),
		$elm$parser$Parser$Advanced$symbol(
			A2(
				$elm$parser$Parser$Advanced$Token,
				']:',
				$elm$parser$Parser$Expecting(']:')))));
var $dillonkearns$elm_markdown$Parser$Token$doubleQuote = A2(
	$elm$parser$Parser$Advanced$Token,
	'\"',
	$elm$parser$Parser$Expecting('a double quote'));
var $dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$hasNoBlankLine = function (str) {
	return A2($elm$core$String$contains, '\n\n', str) ? $elm$parser$Parser$Advanced$problem(
		$elm$parser$Parser$Expecting('no blank line')) : $elm$parser$Parser$Advanced$succeed(str);
};
var $dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$onlyWhitespaceTillNewline = A2(
	$elm$parser$Parser$Advanced$ignorer,
	$elm$parser$Parser$Advanced$chompWhile(
		function (c) {
			return (!$dillonkearns$elm_markdown$Whitespace$isLineEnd(c)) && $dillonkearns$elm_markdown$Whitespace$isWhitespace(c);
		}),
	$dillonkearns$elm_markdown$Helpers$lineEndOrEnd);
var $dillonkearns$elm_markdown$Whitespace$requiredWhitespace = A2(
	$elm$parser$Parser$Advanced$ignorer,
	A2(
		$elm$parser$Parser$Advanced$chompIf,
		$dillonkearns$elm_markdown$Whitespace$isWhitespace,
		$elm$parser$Parser$Expecting('Required whitespace')),
	$elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$Whitespace$isWhitespace));
var $dillonkearns$elm_markdown$Parser$Token$singleQuote = A2(
	$elm$parser$Parser$Advanced$Token,
	'\'',
	$elm$parser$Parser$Expecting('a single quote'));
var $dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$titleParser = function () {
	var inSingleQuotes = A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed($elm$core$Maybe$Just),
			$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$singleQuote)),
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				A2(
					$elm$parser$Parser$Advanced$andThen,
					$dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$hasNoBlankLine,
					$elm$parser$Parser$Advanced$getChompedString(
						$elm$parser$Parser$Advanced$chompUntil($dillonkearns$elm_markdown$Parser$Token$singleQuote))),
				$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$singleQuote)),
			$dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$onlyWhitespaceTillNewline));
	var inDoubleQuotes = A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed($elm$core$Maybe$Just),
			$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$doubleQuote)),
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				A2(
					$elm$parser$Parser$Advanced$andThen,
					$dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$hasNoBlankLine,
					$elm$parser$Parser$Advanced$getChompedString(
						$elm$parser$Parser$Advanced$chompUntil($dillonkearns$elm_markdown$Parser$Token$doubleQuote))),
				$elm$parser$Parser$Advanced$symbol($dillonkearns$elm_markdown$Parser$Token$doubleQuote)),
			$dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$onlyWhitespaceTillNewline));
	return A2(
		$elm$parser$Parser$Advanced$inContext,
		'title',
		$elm$parser$Parser$Advanced$oneOf(
			_List_fromArray(
				[
					$elm$parser$Parser$Advanced$backtrackable(
					A2(
						$elm$parser$Parser$Advanced$keeper,
						A2(
							$elm$parser$Parser$Advanced$ignorer,
							$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
							$dillonkearns$elm_markdown$Whitespace$requiredWhitespace),
						$elm$parser$Parser$Advanced$oneOf(
							_List_fromArray(
								[
									inDoubleQuotes,
									inSingleQuotes,
									$elm$parser$Parser$Advanced$succeed($elm$core$Maybe$Nothing)
								])))),
					A2(
					$elm$parser$Parser$Advanced$ignorer,
					$elm$parser$Parser$Advanced$succeed($elm$core$Maybe$Nothing),
					$dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$onlyWhitespaceTillNewline)
				])));
}();
var $dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$parser = A2(
	$elm$parser$Parser$Advanced$inContext,
	'link reference definition',
	A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$keeper,
			A2(
				$elm$parser$Parser$Advanced$keeper,
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$elm$parser$Parser$Advanced$succeed(
						F3(
							function (label, destination, title) {
								return _Utils_Tuple2(
									label,
									{c3: destination, dY: title});
							})),
					$dillonkearns$elm_markdown$Whitespace$upToThreeSpaces),
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					A2(
						$elm$parser$Parser$Advanced$ignorer,
						A2(
							$elm$parser$Parser$Advanced$ignorer,
							$dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$labelParser,
							$elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$Whitespace$isSpaceOrTab)),
						$elm$parser$Parser$Advanced$oneOf(
							_List_fromArray(
								[
									$dillonkearns$elm_markdown$Whitespace$lineEnd,
									$elm$parser$Parser$Advanced$succeed(0)
								]))),
					$elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$Whitespace$isSpaceOrTab))),
			$dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$destinationParser),
		$dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$titleParser));
var $dillonkearns$elm_markdown$ThematicBreak$ThematicBreak = 0;
var $dillonkearns$elm_markdown$ThematicBreak$whitespace = $elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$Whitespace$isSpaceOrTab);
var $dillonkearns$elm_markdown$ThematicBreak$withChar = function (tchar) {
	var token = $dillonkearns$elm_markdown$Parser$Token$parseString(
		$elm$core$String$fromChar(tchar));
	return A2(
		$elm$parser$Parser$Advanced$ignorer,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					A2(
						$elm$parser$Parser$Advanced$ignorer,
						A2(
							$elm$parser$Parser$Advanced$ignorer,
							A2(
								$elm$parser$Parser$Advanced$ignorer,
								$elm$parser$Parser$Advanced$succeed(0),
								token),
							$dillonkearns$elm_markdown$ThematicBreak$whitespace),
						token),
					$dillonkearns$elm_markdown$ThematicBreak$whitespace),
				token),
			$elm$parser$Parser$Advanced$chompWhile(
				function (c) {
					return _Utils_eq(c, tchar) || $dillonkearns$elm_markdown$Whitespace$isSpaceOrTab(c);
				})),
		$dillonkearns$elm_markdown$Helpers$lineEndOrEnd);
};
var $dillonkearns$elm_markdown$ThematicBreak$parseThematicBreak = $elm$parser$Parser$Advanced$oneOf(
	_List_fromArray(
		[
			$dillonkearns$elm_markdown$ThematicBreak$withChar('-'),
			$dillonkearns$elm_markdown$ThematicBreak$withChar('*'),
			$dillonkearns$elm_markdown$ThematicBreak$withChar('_')
		]));
var $dillonkearns$elm_markdown$ThematicBreak$parser = $elm$parser$Parser$Advanced$oneOf(
	_List_fromArray(
		[
			A2(
			$elm$parser$Parser$Advanced$keeper,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					A2(
						$elm$parser$Parser$Advanced$ignorer,
						$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
						$dillonkearns$elm_markdown$Whitespace$space),
					$elm$parser$Parser$Advanced$oneOf(
						_List_fromArray(
							[
								$dillonkearns$elm_markdown$Whitespace$space,
								$elm$parser$Parser$Advanced$succeed(0)
							]))),
				$elm$parser$Parser$Advanced$oneOf(
					_List_fromArray(
						[
							$dillonkearns$elm_markdown$Whitespace$space,
							$elm$parser$Parser$Advanced$succeed(0)
						]))),
			$dillonkearns$elm_markdown$ThematicBreak$parseThematicBreak),
			$dillonkearns$elm_markdown$ThematicBreak$parseThematicBreak
		]));
var $dillonkearns$elm_markdown$Markdown$RawBlock$LevelOne = 0;
var $dillonkearns$elm_markdown$Markdown$RawBlock$LevelTwo = 1;
var $dillonkearns$elm_markdown$Markdown$RawBlock$SetextLine = F2(
	function (a, b) {
		return {$: 13, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Parser$Token$equals = A2(
	$elm$parser$Parser$Advanced$Token,
	'=',
	$elm$parser$Parser$Expecting('a `=`'));
var $dillonkearns$elm_markdown$Parser$Token$minus = A2(
	$elm$parser$Parser$Advanced$Token,
	'-',
	$elm$parser$Parser$Expecting('a `-`'));
var $dillonkearns$elm_markdown$Markdown$Parser$setextLineParser = function () {
	var setextLevel = F3(
		function (level, levelToken, levelChar) {
			return A2(
				$elm$parser$Parser$Advanced$ignorer,
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$elm$parser$Parser$Advanced$succeed(level),
					$elm$parser$Parser$Advanced$token(levelToken)),
				$elm$parser$Parser$Advanced$chompWhile(
					$elm$core$Basics$eq(levelChar)));
		});
	return A2(
		$elm$parser$Parser$Advanced$mapChompedString,
		F2(
			function (raw, level) {
				return A2($dillonkearns$elm_markdown$Markdown$RawBlock$SetextLine, level, raw);
			}),
		A2(
			$elm$parser$Parser$Advanced$keeper,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
				$dillonkearns$elm_markdown$Whitespace$upToThreeSpaces),
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$elm$parser$Parser$Advanced$oneOf(
						_List_fromArray(
							[
								A3(setextLevel, 0, $dillonkearns$elm_markdown$Parser$Token$equals, '='),
								A3(setextLevel, 1, $dillonkearns$elm_markdown$Parser$Token$minus, '-')
							])),
					$elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$Whitespace$isSpaceOrTab)),
				$dillonkearns$elm_markdown$Helpers$lineEndOrEnd)));
}();
var $dillonkearns$elm_markdown$Markdown$RawBlock$TableDelimiter = function (a) {
	return {$: 9, a: a};
};
var $dillonkearns$elm_markdown$Markdown$TableParser$chompSinglelineWhitespace = $elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$Whitespace$isSpaceOrTab);
var $dillonkearns$elm_markdown$Parser$Extra$maybeChomp = function (condition) {
	return $elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$parser$Parser$Advanced$chompIf,
				condition,
				$elm$parser$Parser$Problem('Character not found')),
				$elm$parser$Parser$Advanced$succeed(0)
			]));
};
var $dillonkearns$elm_markdown$Markdown$TableParser$requirePipeIfNotFirst = function (columns) {
	return $elm$core$List$isEmpty(columns) ? $elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				$dillonkearns$elm_markdown$Parser$Token$parseString('|'),
				$elm$parser$Parser$Advanced$succeed(0)
			])) : $dillonkearns$elm_markdown$Parser$Token$parseString('|');
};
var $dillonkearns$elm_markdown$Markdown$TableParser$delimiterRowHelp = function (revDelimiterColumns) {
	return $elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				$elm$parser$Parser$Advanced$backtrackable(
				A2(
					$elm$parser$Parser$Advanced$map,
					function (_v0) {
						return $elm$parser$Parser$Advanced$Done(revDelimiterColumns);
					},
					$dillonkearns$elm_markdown$Parser$Token$parseString('|\n'))),
				A2(
				$elm$parser$Parser$Advanced$map,
				function (_v1) {
					return $elm$parser$Parser$Advanced$Done(revDelimiterColumns);
				},
				$dillonkearns$elm_markdown$Parser$Token$parseString('\n')),
				A2(
				$elm$parser$Parser$Advanced$map,
				function (_v2) {
					return $elm$parser$Parser$Advanced$Done(revDelimiterColumns);
				},
				$elm$parser$Parser$Advanced$end(
					$elm$parser$Parser$Expecting('end'))),
				$elm$parser$Parser$Advanced$backtrackable(
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					A2(
						$elm$parser$Parser$Advanced$ignorer,
						$elm$parser$Parser$Advanced$succeed(
							$elm$parser$Parser$Advanced$Done(revDelimiterColumns)),
						$dillonkearns$elm_markdown$Parser$Token$parseString('|')),
					$elm$parser$Parser$Advanced$end(
						$elm$parser$Parser$Expecting('end')))),
				A2(
				$elm$parser$Parser$Advanced$keeper,
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					A2(
						$elm$parser$Parser$Advanced$ignorer,
						$elm$parser$Parser$Advanced$succeed(
							function (column) {
								return $elm$parser$Parser$Advanced$Loop(
									A2($elm$core$List$cons, column, revDelimiterColumns));
							}),
						$dillonkearns$elm_markdown$Markdown$TableParser$requirePipeIfNotFirst(revDelimiterColumns)),
					$dillonkearns$elm_markdown$Markdown$TableParser$chompSinglelineWhitespace),
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$elm$parser$Parser$Advanced$getChompedString(
						A2(
							$elm$parser$Parser$Advanced$ignorer,
							A2(
								$elm$parser$Parser$Advanced$ignorer,
								A2(
									$elm$parser$Parser$Advanced$ignorer,
									$elm$parser$Parser$Advanced$succeed(0),
									$dillonkearns$elm_markdown$Parser$Extra$maybeChomp(
										function (c) {
											return c === ':';
										})),
								$dillonkearns$elm_markdown$Parser$Extra$chompOneOrMore(
									function (c) {
										return c === '-';
									})),
							$dillonkearns$elm_markdown$Parser$Extra$maybeChomp(
								function (c) {
									return c === ':';
								}))),
					$dillonkearns$elm_markdown$Markdown$TableParser$chompSinglelineWhitespace))
			]));
};
var $dillonkearns$elm_markdown$Markdown$Block$AlignCenter = 2;
var $dillonkearns$elm_markdown$Markdown$Block$AlignLeft = 0;
var $dillonkearns$elm_markdown$Markdown$Block$AlignRight = 1;
var $dillonkearns$elm_markdown$Markdown$TableParser$delimiterToAlignment = function (cell) {
	var _v0 = _Utils_Tuple2(
		A2($elm$core$String$startsWith, ':', cell),
		A2($elm$core$String$endsWith, ':', cell));
	if (_v0.a) {
		if (_v0.b) {
			return $elm$core$Maybe$Just(2);
		} else {
			return $elm$core$Maybe$Just(0);
		}
	} else {
		if (_v0.b) {
			return $elm$core$Maybe$Just(1);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	}
};
var $dillonkearns$elm_markdown$Markdown$TableParser$delimiterRowParser = A2(
	$elm$parser$Parser$Advanced$andThen,
	function (delimiterRow) {
		var trimmed = delimiterRow.a.cK;
		var headers = delimiterRow.b;
		return $elm$core$List$isEmpty(headers) ? $elm$parser$Parser$Advanced$problem(
			$elm$parser$Parser$Expecting('Must have at least one column in delimiter row.')) : ((($elm$core$List$length(headers) === 1) && (!(A2($elm$core$String$startsWith, '|', trimmed) && A2($elm$core$String$endsWith, '|', trimmed)))) ? $elm$parser$Parser$Advanced$problem(
			$elm$parser$Parser$Problem('Tables with a single column must have pipes at the start and end of the delimiter row to avoid ambiguity.')) : $elm$parser$Parser$Advanced$succeed(delimiterRow));
	},
	A2(
		$elm$parser$Parser$Advanced$mapChompedString,
		F2(
			function (delimiterText, revDelimiterColumns) {
				return A2(
					$dillonkearns$elm_markdown$Markdown$Table$TableDelimiterRow,
					{
						cs: delimiterText,
						cK: $elm$core$String$trim(delimiterText)
					},
					A2(
						$elm$core$List$map,
						$dillonkearns$elm_markdown$Markdown$TableParser$delimiterToAlignment,
						$elm$core$List$reverse(revDelimiterColumns)));
			}),
		A2($elm$parser$Parser$Advanced$loop, _List_Nil, $dillonkearns$elm_markdown$Markdown$TableParser$delimiterRowHelp)));
var $dillonkearns$elm_markdown$Markdown$Parser$tableDelimiterInOpenParagraph = A2($elm$parser$Parser$Advanced$map, $dillonkearns$elm_markdown$Markdown$RawBlock$TableDelimiter, $dillonkearns$elm_markdown$Markdown$TableParser$delimiterRowParser);
var $elm$core$List$all = F2(
	function (isOkay, list) {
		return !A2(
			$elm$core$List$any,
			A2($elm$core$Basics$composeL, $elm$core$Basics$not, isOkay),
			list);
	});
var $elm$core$List$takeReverse = F3(
	function (n, list, kept) {
		takeReverse:
		while (true) {
			if (n <= 0) {
				return kept;
			} else {
				if (!list.b) {
					return kept;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs,
						$temp$kept = A2($elm$core$List$cons, x, kept);
					n = $temp$n;
					list = $temp$list;
					kept = $temp$kept;
					continue takeReverse;
				}
			}
		}
	});
var $elm$core$List$takeTailRec = F2(
	function (n, list) {
		return $elm$core$List$reverse(
			A3($elm$core$List$takeReverse, n, list, _List_Nil));
	});
var $elm$core$List$takeFast = F3(
	function (ctr, n, list) {
		if (n <= 0) {
			return _List_Nil;
		} else {
			var _v0 = _Utils_Tuple2(n, list);
			_v0$1:
			while (true) {
				_v0$5:
				while (true) {
					if (!_v0.b.b) {
						return list;
					} else {
						if (_v0.b.b.b) {
							switch (_v0.a) {
								case 1:
									break _v0$1;
								case 2:
									var _v2 = _v0.b;
									var x = _v2.a;
									var _v3 = _v2.b;
									var y = _v3.a;
									return _List_fromArray(
										[x, y]);
								case 3:
									if (_v0.b.b.b.b) {
										var _v4 = _v0.b;
										var x = _v4.a;
										var _v5 = _v4.b;
										var y = _v5.a;
										var _v6 = _v5.b;
										var z = _v6.a;
										return _List_fromArray(
											[x, y, z]);
									} else {
										break _v0$5;
									}
								default:
									if (_v0.b.b.b.b && _v0.b.b.b.b.b) {
										var _v7 = _v0.b;
										var x = _v7.a;
										var _v8 = _v7.b;
										var y = _v8.a;
										var _v9 = _v8.b;
										var z = _v9.a;
										var _v10 = _v9.b;
										var w = _v10.a;
										var tl = _v10.b;
										return (ctr > 1000) ? A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A2($elm$core$List$takeTailRec, n - 4, tl))))) : A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A3($elm$core$List$takeFast, ctr + 1, n - 4, tl)))));
									} else {
										break _v0$5;
									}
							}
						} else {
							if (_v0.a === 1) {
								break _v0$1;
							} else {
								break _v0$5;
							}
						}
					}
				}
				return list;
			}
			var _v1 = _v0.b;
			var x = _v1.a;
			return _List_fromArray(
				[x]);
		}
	});
var $elm$core$List$take = F2(
	function (n, list) {
		return A3($elm$core$List$takeFast, 0, n, list);
	});
var $dillonkearns$elm_markdown$Markdown$TableParser$standardizeRowLength = F2(
	function (expectedLength, row) {
		var rowLength = $elm$core$List$length(row);
		var _v0 = A2($elm$core$Basics$compare, expectedLength, rowLength);
		switch (_v0) {
			case 0:
				return A2($elm$core$List$take, expectedLength, row);
			case 1:
				return row;
			default:
				return _Utils_ap(
					row,
					A2($elm$core$List$repeat, expectedLength - rowLength, ''));
		}
	});
var $dillonkearns$elm_markdown$Markdown$TableParser$bodyRowParser = function (expectedRowLength) {
	return A2(
		$elm$parser$Parser$Advanced$andThen,
		function (row) {
			return ($elm$core$List$isEmpty(row) || A2($elm$core$List$all, $elm$core$String$isEmpty, row)) ? $elm$parser$Parser$Advanced$problem(
				$elm$parser$Parser$Problem('A line must have at least one column')) : $elm$parser$Parser$Advanced$succeed(
				A2($dillonkearns$elm_markdown$Markdown$TableParser$standardizeRowLength, expectedRowLength, row));
		},
		$dillonkearns$elm_markdown$Markdown$TableParser$rowParser);
};
var $dillonkearns$elm_markdown$Markdown$Parser$tableRowIfTableStarted = function (_v0) {
	var headers = _v0.a;
	var body = _v0.b;
	return A2(
		$elm$parser$Parser$Advanced$map,
		function (row) {
			return $dillonkearns$elm_markdown$Markdown$RawBlock$Table(
				A2(
					$dillonkearns$elm_markdown$Markdown$Table$Table,
					headers,
					_Utils_ap(
						body,
						_List_fromArray(
							[row]))));
		},
		$dillonkearns$elm_markdown$Markdown$TableParser$bodyRowParser(
			$elm$core$List$length(headers)));
};
var $dillonkearns$elm_markdown$Markdown$Block$H1 = 0;
var $dillonkearns$elm_markdown$Markdown$Block$H2 = 1;
var $dillonkearns$elm_markdown$Markdown$Block$H3 = 2;
var $dillonkearns$elm_markdown$Markdown$Block$H4 = 3;
var $dillonkearns$elm_markdown$Markdown$Block$H5 = 4;
var $dillonkearns$elm_markdown$Markdown$Block$H6 = 5;
var $dillonkearns$elm_markdown$Markdown$Parser$toHeading = function (level) {
	switch (level) {
		case 1:
			return $elm$core$Result$Ok(0);
		case 2:
			return $elm$core$Result$Ok(1);
		case 3:
			return $elm$core$Result$Ok(2);
		case 4:
			return $elm$core$Result$Ok(3);
		case 5:
			return $elm$core$Result$Ok(4);
		case 6:
			return $elm$core$Result$Ok(5);
		default:
			return $elm$core$Result$Err(
				$elm$parser$Parser$Expecting(
					'A heading with 1 to 6 #\'s, but found ' + $elm$core$String$fromInt(level)));
	}
};
var $dillonkearns$elm_markdown$Markdown$ListItem$EmptyItem = {$: 2};
var $dillonkearns$elm_markdown$Markdown$ListItem$PlainItem = function (a) {
	return {$: 1, a: a};
};
var $dillonkearns$elm_markdown$Markdown$ListItem$TaskItem = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $dillonkearns$elm_markdown$Markdown$UnorderedList$getIntendedCodeItem = F4(
	function (markerStartPos, listMarker, markerEndPos, _v0) {
		var bodyStartPos = _v0.a;
		var item = _v0.b;
		var spaceNum = bodyStartPos - markerEndPos;
		if (spaceNum <= 4) {
			return _Utils_Tuple3(listMarker, bodyStartPos - markerStartPos, item);
		} else {
			var intendedCodeItem = function () {
				switch (item.$) {
					case 0:
						var completion = item.a;
						var string = item.b;
						return A2(
							$dillonkearns$elm_markdown$Markdown$ListItem$TaskItem,
							completion,
							_Utils_ap(
								A2($elm$core$String$repeat, spaceNum - 1, ' '),
								string));
					case 1:
						var string = item.a;
						return $dillonkearns$elm_markdown$Markdown$ListItem$PlainItem(
							_Utils_ap(
								A2($elm$core$String$repeat, spaceNum - 1, ' '),
								string));
					default:
						return $dillonkearns$elm_markdown$Markdown$ListItem$EmptyItem;
				}
			}();
			return _Utils_Tuple3(listMarker, (markerEndPos - markerStartPos) + 1, intendedCodeItem);
		}
	});
var $dillonkearns$elm_markdown$Markdown$UnorderedList$unorderedListEmptyItemParser = A2(
	$elm$parser$Parser$Advanced$keeper,
	$elm$parser$Parser$Advanced$succeed(
		function (bodyStartPos) {
			return _Utils_Tuple2(bodyStartPos, $dillonkearns$elm_markdown$Markdown$ListItem$EmptyItem);
		}),
	A2($elm$parser$Parser$Advanced$ignorer, $elm$parser$Parser$Advanced$getCol, $dillonkearns$elm_markdown$Helpers$lineEndOrEnd));
var $dillonkearns$elm_markdown$Markdown$ListItem$Complete = 1;
var $dillonkearns$elm_markdown$Markdown$ListItem$Incomplete = 0;
var $dillonkearns$elm_markdown$Markdown$ListItem$taskItemParser = $elm$parser$Parser$Advanced$oneOf(
	_List_fromArray(
		[
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed(1),
			$elm$parser$Parser$Advanced$symbol(
				A2(
					$elm$parser$Parser$Advanced$Token,
					'[x] ',
					$elm$parser$Parser$ExpectingSymbol('[x] ')))),
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed(1),
			$elm$parser$Parser$Advanced$symbol(
				A2(
					$elm$parser$Parser$Advanced$Token,
					'[X] ',
					$elm$parser$Parser$ExpectingSymbol('[X] ')))),
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed(0),
			$elm$parser$Parser$Advanced$symbol(
				A2(
					$elm$parser$Parser$Advanced$Token,
					'[ ] ',
					$elm$parser$Parser$ExpectingSymbol('[ ] '))))
		]));
var $dillonkearns$elm_markdown$Markdown$ListItem$parser = A2(
	$elm$parser$Parser$Advanced$keeper,
	$elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$parser$Parser$Advanced$keeper,
				$elm$parser$Parser$Advanced$succeed($dillonkearns$elm_markdown$Markdown$ListItem$TaskItem),
				A2(
					$elm$parser$Parser$Advanced$ignorer,
					$dillonkearns$elm_markdown$Markdown$ListItem$taskItemParser,
					$elm$parser$Parser$Advanced$chompWhile($dillonkearns$elm_markdown$Whitespace$isSpaceOrTab))),
				$elm$parser$Parser$Advanced$succeed($dillonkearns$elm_markdown$Markdown$ListItem$PlainItem)
			])),
	A2(
		$elm$parser$Parser$Advanced$ignorer,
		$elm$parser$Parser$Advanced$getChompedString($dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd),
		$dillonkearns$elm_markdown$Helpers$lineEndOrEnd));
var $dillonkearns$elm_markdown$Markdown$UnorderedList$unorderedListItemBodyParser = A2(
	$elm$parser$Parser$Advanced$keeper,
	A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed(
				F2(
					function (bodyStartPos, item) {
						return _Utils_Tuple2(bodyStartPos, item);
					})),
			$dillonkearns$elm_markdown$Parser$Extra$chompOneOrMore($dillonkearns$elm_markdown$Whitespace$isSpaceOrTab)),
		$elm$parser$Parser$Advanced$getCol),
	$dillonkearns$elm_markdown$Markdown$ListItem$parser);
var $dillonkearns$elm_markdown$Markdown$UnorderedList$Asterisk = 2;
var $dillonkearns$elm_markdown$Markdown$UnorderedList$Minus = 0;
var $dillonkearns$elm_markdown$Markdown$UnorderedList$Plus = 1;
var $dillonkearns$elm_markdown$Markdown$UnorderedList$unorderedListMarkerParser = $elm$parser$Parser$Advanced$oneOf(
	_List_fromArray(
		[
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			A2(
				$elm$parser$Parser$Advanced$ignorer,
				$elm$parser$Parser$Advanced$succeed(0),
				A2($dillonkearns$elm_markdown$Parser$Extra$upTo, 3, $dillonkearns$elm_markdown$Whitespace$space)),
			$elm$parser$Parser$Advanced$symbol(
				A2(
					$elm$parser$Parser$Advanced$Token,
					'-',
					$elm$parser$Parser$ExpectingSymbol('-')))),
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed(1),
			$elm$parser$Parser$Advanced$symbol(
				A2(
					$elm$parser$Parser$Advanced$Token,
					'+',
					$elm$parser$Parser$ExpectingSymbol('+')))),
			A2(
			$elm$parser$Parser$Advanced$ignorer,
			$elm$parser$Parser$Advanced$succeed(2),
			$elm$parser$Parser$Advanced$symbol(
				A2(
					$elm$parser$Parser$Advanced$Token,
					'*',
					$elm$parser$Parser$ExpectingSymbol('*'))))
		]));
var $dillonkearns$elm_markdown$Markdown$UnorderedList$parser = function (previousWasBody) {
	return A2(
		$elm$parser$Parser$Advanced$keeper,
		A2(
			$elm$parser$Parser$Advanced$keeper,
			A2(
				$elm$parser$Parser$Advanced$keeper,
				A2(
					$elm$parser$Parser$Advanced$keeper,
					$elm$parser$Parser$Advanced$succeed($dillonkearns$elm_markdown$Markdown$UnorderedList$getIntendedCodeItem),
					$elm$parser$Parser$Advanced$getCol),
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$Markdown$UnorderedList$unorderedListMarkerParser)),
			$elm$parser$Parser$Advanced$getCol),
		previousWasBody ? $dillonkearns$elm_markdown$Markdown$UnorderedList$unorderedListItemBodyParser : $elm$parser$Parser$Advanced$oneOf(
			_List_fromArray(
				[$dillonkearns$elm_markdown$Markdown$UnorderedList$unorderedListEmptyItemParser, $dillonkearns$elm_markdown$Markdown$UnorderedList$unorderedListItemBodyParser])));
};
var $dillonkearns$elm_markdown$Markdown$Parser$unorderedListBlock = function (previousWasBody) {
	var parseListItem = F2(
		function (listmarker, unparsedListItem) {
			switch (unparsedListItem.$) {
				case 0:
					var completion = unparsedListItem.a;
					var body = unparsedListItem.b;
					return {
						cW: body,
						dq: listmarker,
						o: $elm$core$Maybe$Just(
							function () {
								if (completion === 1) {
									return true;
								} else {
									return false;
								}
							}())
					};
				case 1:
					var body = unparsedListItem.a;
					return {cW: body, dq: listmarker, o: $elm$core$Maybe$Nothing};
				default:
					return {cW: '', dq: listmarker, o: $elm$core$Maybe$Nothing};
			}
		});
	return A2(
		$elm$parser$Parser$Advanced$map,
		function (_v0) {
			var listmarker = _v0.a;
			var intended = _v0.b;
			var unparsedListItem = _v0.c;
			return A4(
				$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
				true,
				intended,
				_List_Nil,
				A2(parseListItem, listmarker, unparsedListItem));
		},
		$dillonkearns$elm_markdown$Markdown$UnorderedList$parser(previousWasBody));
};
var $elm$core$Result$withDefault = F2(
	function (def, result) {
		if (!result.$) {
			var a = result.a;
			return a;
		} else {
			return def;
		}
	});
var $dillonkearns$elm_markdown$Markdown$Parser$childToBlocks = F2(
	function (node, blocks) {
		switch (node.$) {
			case 0:
				var tag = node.a;
				var attributes = node.b;
				var children = node.c;
				var _v106 = $dillonkearns$elm_markdown$Markdown$Parser$nodesToBlocks(children);
				if (!_v106.$) {
					var childrenAsBlocks = _v106.a;
					var block = $dillonkearns$elm_markdown$Markdown$Block$HtmlBlock(
						A3($dillonkearns$elm_markdown$Markdown$Block$HtmlElement, tag, attributes, childrenAsBlocks));
					return $elm$core$Result$Ok(
						A2($elm$core$List$cons, block, blocks));
				} else {
					var err = _v106.a;
					return $elm$core$Result$Err(err);
				}
			case 1:
				var innerText = node.a;
				var _v107 = $dillonkearns$elm_markdown$Markdown$Parser$parse(innerText);
				if (!_v107.$) {
					var value = _v107.a;
					return $elm$core$Result$Ok(
						_Utils_ap(
							$elm$core$List$reverse(value),
							blocks));
				} else {
					var error = _v107.a;
					return $elm$core$Result$Err(
						$elm$parser$Parser$Expecting(
							A2(
								$elm$core$String$join,
								'\n',
								A2($elm$core$List$map, $dillonkearns$elm_markdown$Markdown$Parser$deadEndToString, error))));
				}
			case 2:
				var string = node.a;
				return $elm$core$Result$Ok(
					A2(
						$elm$core$List$cons,
						$dillonkearns$elm_markdown$Markdown$Block$HtmlBlock(
							$dillonkearns$elm_markdown$Markdown$Block$HtmlComment(string)),
						blocks));
			case 3:
				var string = node.a;
				return $elm$core$Result$Ok(
					A2(
						$elm$core$List$cons,
						$dillonkearns$elm_markdown$Markdown$Block$HtmlBlock(
							$dillonkearns$elm_markdown$Markdown$Block$Cdata(string)),
						blocks));
			case 4:
				var string = node.a;
				return $elm$core$Result$Ok(
					A2(
						$elm$core$List$cons,
						$dillonkearns$elm_markdown$Markdown$Block$HtmlBlock(
							$dillonkearns$elm_markdown$Markdown$Block$ProcessingInstruction(string)),
						blocks));
			default:
				var declarationType = node.a;
				var content = node.b;
				return $elm$core$Result$Ok(
					A2(
						$elm$core$List$cons,
						$dillonkearns$elm_markdown$Markdown$Block$HtmlBlock(
							A2($dillonkearns$elm_markdown$Markdown$Block$HtmlDeclaration, declarationType, content)),
						blocks));
		}
	});
var $dillonkearns$elm_markdown$Markdown$Parser$completeBlocks = function (state) {
	var _v91 = state.b;
	_v91$5:
	while (true) {
		if (_v91.b) {
			switch (_v91.a.$) {
				case 11:
					var body2 = _v91.a.a;
					var rest = _v91.b;
					var _v92 = A2(
						$elm$parser$Parser$Advanced$run,
						$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
						body2);
					if (!_v92.$) {
						var value = _v92.a;
						return $elm$parser$Parser$Advanced$succeed(
							{
								a: _Utils_ap(state.a, value.a),
								b: A2(
									$elm$core$List$cons,
									$dillonkearns$elm_markdown$Markdown$RawBlock$ParsedBlockQuote(value.b),
									rest)
							});
					} else {
						var error = _v92.a;
						return $elm$parser$Parser$Advanced$problem(
							$elm$parser$Parser$Problem(
								$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(error)));
					}
				case 3:
					var _v93 = _v91.a;
					var tight = _v93.a;
					var intended = _v93.b;
					var closeListItems = _v93.c;
					var openListItem = _v93.d;
					var rest = _v91.b;
					var _v94 = A2(
						$elm$parser$Parser$Advanced$run,
						$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
						openListItem.cW);
					if (!_v94.$) {
						var value = _v94.a;
						var tight2 = A2($elm$core$List$member, $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine, value.b) ? false : tight;
						return $elm$parser$Parser$Advanced$succeed(
							{
								a: _Utils_ap(state.a, value.a),
								b: A2(
									$elm$core$List$cons,
									A4(
										$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
										tight2,
										intended,
										A2(
											$elm$core$List$cons,
											{cW: value.b, o: openListItem.o},
											closeListItems),
										openListItem),
									rest)
							});
					} else {
						var e = _v94.a;
						return $elm$parser$Parser$Advanced$problem(
							$elm$parser$Parser$Problem(
								$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
					}
				case 4:
					var _v99 = _v91.a;
					var tight = _v99.a;
					var intended = _v99.b;
					var marker = _v99.c;
					var order = _v99.d;
					var closeListItems = _v99.e;
					var openListItem = _v99.f;
					var rest = _v91.b;
					var _v100 = A2(
						$elm$parser$Parser$Advanced$run,
						$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
						openListItem);
					if (!_v100.$) {
						var value = _v100.a;
						var tight2 = A2($elm$core$List$member, $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine, value.b) ? false : tight;
						return $elm$parser$Parser$Advanced$succeed(
							{
								a: _Utils_ap(state.a, value.a),
								b: A2(
									$elm$core$List$cons,
									A6(
										$dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock,
										tight2,
										intended,
										marker,
										order,
										A2($elm$core$List$cons, value.b, closeListItems),
										openListItem),
									rest)
							});
					} else {
						var e = _v100.a;
						return $elm$parser$Parser$Advanced$problem(
							$elm$parser$Parser$Problem(
								$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
					}
				case 10:
					if (_v91.b.b) {
						switch (_v91.b.a.$) {
							case 3:
								var _v95 = _v91.a;
								var _v96 = _v91.b;
								var _v97 = _v96.a;
								var tight = _v97.a;
								var intended = _v97.b;
								var closeListItems = _v97.c;
								var openListItem = _v97.d;
								var rest = _v96.b;
								var _v98 = A2(
									$elm$parser$Parser$Advanced$run,
									$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
									openListItem.cW);
								if (!_v98.$) {
									var value = _v98.a;
									var tight2 = A2($elm$core$List$member, $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine, value.b) ? false : tight;
									return $elm$parser$Parser$Advanced$succeed(
										{
											a: _Utils_ap(state.a, value.a),
											b: A2(
												$elm$core$List$cons,
												A4(
													$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
													tight2,
													intended,
													A2(
														$elm$core$List$cons,
														{cW: value.b, o: openListItem.o},
														closeListItems),
													openListItem),
												rest)
										});
								} else {
									var e = _v98.a;
									return $elm$parser$Parser$Advanced$problem(
										$elm$parser$Parser$Problem(
											$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
								}
							case 4:
								var _v101 = _v91.a;
								var _v102 = _v91.b;
								var _v103 = _v102.a;
								var tight = _v103.a;
								var intended = _v103.b;
								var marker = _v103.c;
								var order = _v103.d;
								var closeListItems = _v103.e;
								var openListItem = _v103.f;
								var rest = _v102.b;
								var _v104 = A2(
									$elm$parser$Parser$Advanced$run,
									$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
									openListItem);
								if (!_v104.$) {
									var value = _v104.a;
									var tight2 = A2($elm$core$List$member, $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine, value.b) ? false : tight;
									return $elm$parser$Parser$Advanced$succeed(
										{
											a: _Utils_ap(state.a, value.a),
											b: A2(
												$elm$core$List$cons,
												A6(
													$dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock,
													tight2,
													intended,
													marker,
													order,
													A2($elm$core$List$cons, value.b, closeListItems),
													openListItem),
												rest)
										});
								} else {
									var e = _v104.a;
									return $elm$parser$Parser$Advanced$problem(
										$elm$parser$Parser$Problem(
											$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
								}
							default:
								break _v91$5;
						}
					} else {
						break _v91$5;
					}
				default:
					break _v91$5;
			}
		} else {
			break _v91$5;
		}
	}
	return $elm$parser$Parser$Advanced$succeed(state);
};
var $dillonkearns$elm_markdown$Markdown$Parser$completeOrMergeBlocks = F2(
	function (state, newRawBlock) {
		var _v41 = _Utils_Tuple2(newRawBlock, state.b);
		_v41$13:
		while (true) {
			if (_v41.b.b) {
				switch (_v41.b.a.$) {
					case 5:
						if (_v41.a.$ === 5) {
							var block1 = _v41.a.a;
							var _v42 = _v41.b;
							var block2 = _v42.a.a;
							var rest = _v42.b;
							return $elm$parser$Parser$Advanced$succeed(
								{
									a: state.a,
									b: A2(
										$elm$core$List$cons,
										$dillonkearns$elm_markdown$Markdown$RawBlock$CodeBlock(
											{
												cW: A2($dillonkearns$elm_markdown$Markdown$Parser$joinStringsPreserveAll, block2.cW, block1.cW),
												dn: $elm$core$Maybe$Nothing
											}),
										rest)
								});
						} else {
							break _v41$13;
						}
					case 6:
						switch (_v41.a.$) {
							case 6:
								var block1 = _v41.a.a;
								var _v43 = _v41.b;
								var block2 = _v43.a.a;
								var rest = _v43.b;
								return $elm$parser$Parser$Advanced$succeed(
									{
										a: state.a,
										b: A2(
											$elm$core$List$cons,
											$dillonkearns$elm_markdown$Markdown$RawBlock$IndentedCodeBlock(
												A2($dillonkearns$elm_markdown$Markdown$Parser$joinStringsPreserveAll, block2, block1)),
											rest)
									});
							case 10:
								var _v44 = _v41.a;
								var _v45 = _v41.b;
								var block = _v45.a.a;
								var rest = _v45.b;
								return $elm$parser$Parser$Advanced$succeed(
									{
										a: state.a,
										b: A2(
											$elm$core$List$cons,
											$dillonkearns$elm_markdown$Markdown$RawBlock$IndentedCodeBlock(
												A2($dillonkearns$elm_markdown$Markdown$Parser$joinStringsPreserveAll, block, '\n')),
											rest)
									});
							default:
								break _v41$13;
						}
					case 11:
						var _v46 = _v41.b;
						var body2 = _v46.a.a;
						var rest = _v46.b;
						switch (newRawBlock.$) {
							case 11:
								var body1 = newRawBlock.a;
								return $elm$parser$Parser$Advanced$succeed(
									{
										a: state.a,
										b: A2(
											$elm$core$List$cons,
											$dillonkearns$elm_markdown$Markdown$RawBlock$BlockQuote(
												A2($dillonkearns$elm_markdown$Markdown$Parser$joinStringsPreserveAll, body2, body1)),
											rest)
									});
							case 1:
								var body1 = newRawBlock.a;
								var _v48 = A2(
									$elm$parser$Parser$Advanced$run,
									$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
									body2);
								if (!_v48.$) {
									var value = _v48.a;
									var _v49 = value.b;
									if (_v49.b) {
										var last = _v49.a;
										if ($dillonkearns$elm_markdown$Markdown$Parser$endWithOpenBlockOrParagraph(last) && (!A2($elm$core$String$endsWith, '\n', body2))) {
											return $elm$parser$Parser$Advanced$succeed(
												{
													a: state.a,
													b: A2(
														$elm$core$List$cons,
														$dillonkearns$elm_markdown$Markdown$RawBlock$BlockQuote(
															A2($dillonkearns$elm_markdown$Markdown$Parser$joinStringsPreserveAll, body2, body1)),
														rest)
												});
										} else {
											var _v50 = A2(
												$elm$parser$Parser$Advanced$run,
												$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
												body2);
											if (!_v50.$) {
												var value1 = _v50.a;
												return $elm$parser$Parser$Advanced$succeed(
													{
														a: _Utils_ap(state.a, value.a),
														b: A2(
															$elm$core$List$cons,
															newRawBlock,
															A2(
																$elm$core$List$cons,
																$dillonkearns$elm_markdown$Markdown$RawBlock$ParsedBlockQuote(value1.b),
																rest))
													});
											} else {
												var e1 = _v50.a;
												return $elm$parser$Parser$Advanced$problem(
													$elm$parser$Parser$Problem(
														$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e1)));
											}
										}
									} else {
										var _v51 = A2(
											$elm$parser$Parser$Advanced$run,
											$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
											body2);
										if (!_v51.$) {
											var value1 = _v51.a;
											return $elm$parser$Parser$Advanced$succeed(
												{
													a: _Utils_ap(state.a, value.a),
													b: A2(
														$elm$core$List$cons,
														newRawBlock,
														A2(
															$elm$core$List$cons,
															$dillonkearns$elm_markdown$Markdown$RawBlock$ParsedBlockQuote(value1.b),
															rest))
												});
										} else {
											var e1 = _v51.a;
											return $elm$parser$Parser$Advanced$problem(
												$elm$parser$Parser$Problem(
													$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e1)));
										}
									}
								} else {
									var e = _v48.a;
									return $elm$parser$Parser$Advanced$problem(
										$elm$parser$Parser$Problem(
											$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
								}
							case 6:
								var body1 = newRawBlock.a;
								var _v52 = A2(
									$elm$parser$Parser$Advanced$run,
									$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
									body2);
								if (!_v52.$) {
									var value = _v52.a;
									var _v53 = value.b;
									if (_v53.b && (_v53.a.$ === 1)) {
										return $elm$parser$Parser$Advanced$succeed(
											{
												a: state.a,
												b: A2(
													$elm$core$List$cons,
													$dillonkearns$elm_markdown$Markdown$RawBlock$BlockQuote(
														A3($dillonkearns$elm_markdown$Markdown$Parser$joinRawStringsWith, ' ', body2, body1)),
													rest)
											});
									} else {
										var _v54 = A2(
											$elm$parser$Parser$Advanced$run,
											$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
											body2);
										if (!_v54.$) {
											var value1 = _v54.a;
											return $elm$parser$Parser$Advanced$succeed(
												{
													a: _Utils_ap(state.a, value.a),
													b: A2(
														$elm$core$List$cons,
														newRawBlock,
														A2(
															$elm$core$List$cons,
															$dillonkearns$elm_markdown$Markdown$RawBlock$ParsedBlockQuote(value1.b),
															rest))
												});
										} else {
											var e1 = _v54.a;
											return $elm$parser$Parser$Advanced$problem(
												$elm$parser$Parser$Problem(
													$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e1)));
										}
									}
								} else {
									var e = _v52.a;
									return $elm$parser$Parser$Advanced$problem(
										$elm$parser$Parser$Problem(
											$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
								}
							default:
								var _v55 = A2(
									$elm$parser$Parser$Advanced$run,
									$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
									body2);
								if (!_v55.$) {
									var value = _v55.a;
									return $elm$parser$Parser$Advanced$succeed(
										{
											a: _Utils_ap(state.a, value.a),
											b: A2(
												$elm$core$List$cons,
												newRawBlock,
												A2(
													$elm$core$List$cons,
													$dillonkearns$elm_markdown$Markdown$RawBlock$ParsedBlockQuote(value.b),
													rest))
										});
								} else {
									var e = _v55.a;
									return $elm$parser$Parser$Advanced$problem(
										$elm$parser$Parser$Problem(
											$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
								}
						}
					case 3:
						var _v56 = _v41.b;
						var _v57 = _v56.a;
						var tight = _v57.a;
						var intended1 = _v57.b;
						var closeListItems2 = _v57.c;
						var openListItem2 = _v57.d;
						var rest = _v56.b;
						switch (newRawBlock.$) {
							case 3:
								var intended2 = newRawBlock.b;
								var openListItem1 = newRawBlock.d;
								if (_Utils_eq(openListItem2.dq, openListItem1.dq)) {
									var _v59 = A2(
										$elm$parser$Parser$Advanced$run,
										$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
										openListItem2.cW);
									if (!_v59.$) {
										var value = _v59.a;
										return A2($elm$core$List$member, $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine, value.b) ? $elm$parser$Parser$Advanced$succeed(
											{
												a: _Utils_ap(state.a, value.a),
												b: A2(
													$elm$core$List$cons,
													A4(
														$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
														false,
														intended2,
														A2(
															$elm$core$List$cons,
															{cW: value.b, o: openListItem2.o},
															closeListItems2),
														openListItem1),
													rest)
											}) : $elm$parser$Parser$Advanced$succeed(
											{
												a: _Utils_ap(state.a, value.a),
												b: A2(
													$elm$core$List$cons,
													A4(
														$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
														tight,
														intended2,
														A2(
															$elm$core$List$cons,
															{cW: value.b, o: openListItem2.o},
															closeListItems2),
														openListItem1),
													rest)
											});
									} else {
										var e = _v59.a;
										return $elm$parser$Parser$Advanced$problem(
											$elm$parser$Parser$Problem(
												$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
									}
								} else {
									var _v60 = A2(
										$elm$parser$Parser$Advanced$run,
										$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
										openListItem2.cW);
									if (!_v60.$) {
										var value = _v60.a;
										var tight2 = A2($elm$core$List$member, $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine, value.b) ? false : tight;
										return $elm$parser$Parser$Advanced$succeed(
											{
												a: _Utils_ap(state.a, value.a),
												b: A2(
													$elm$core$List$cons,
													newRawBlock,
													A2(
														$elm$core$List$cons,
														A4(
															$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
															tight2,
															intended1,
															A2(
																$elm$core$List$cons,
																{cW: value.b, o: openListItem2.o},
																closeListItems2),
															openListItem1),
														rest))
											});
									} else {
										var e = _v60.a;
										return $elm$parser$Parser$Advanced$problem(
											$elm$parser$Parser$Problem(
												$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
									}
								}
							case 1:
								var body1 = newRawBlock.a;
								return $elm$parser$Parser$Advanced$succeed(
									{
										a: state.a,
										b: A2(
											$elm$core$List$cons,
											A4(
												$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
												tight,
												intended1,
												closeListItems2,
												_Utils_update(
													openListItem2,
													{
														cW: A3($dillonkearns$elm_markdown$Markdown$Parser$joinRawStringsWith, '\n', openListItem2.cW, body1)
													})),
											rest)
									});
							default:
								var _v61 = A2(
									$elm$parser$Parser$Advanced$run,
									$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
									openListItem2.cW);
								if (!_v61.$) {
									var value = _v61.a;
									var tight2 = A2($elm$core$List$member, $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine, value.b) ? false : tight;
									return $elm$parser$Parser$Advanced$succeed(
										{
											a: _Utils_ap(state.a, value.a),
											b: A2(
												$elm$core$List$cons,
												newRawBlock,
												A2(
													$elm$core$List$cons,
													A4(
														$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
														tight2,
														intended1,
														A2(
															$elm$core$List$cons,
															{cW: value.b, o: openListItem2.o},
															closeListItems2),
														openListItem2),
													rest))
										});
								} else {
									var e = _v61.a;
									return $elm$parser$Parser$Advanced$problem(
										$elm$parser$Parser$Problem(
											$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
								}
						}
					case 4:
						var _v62 = _v41.b;
						var _v63 = _v62.a;
						var tight = _v63.a;
						var intended1 = _v63.b;
						var marker = _v63.c;
						var order = _v63.d;
						var closeListItems2 = _v63.e;
						var openListItem2 = _v63.f;
						var rest = _v62.b;
						switch (newRawBlock.$) {
							case 4:
								var intended2 = newRawBlock.b;
								var marker2 = newRawBlock.c;
								var openListItem1 = newRawBlock.f;
								if (_Utils_eq(marker, marker2)) {
									var _v65 = A2(
										$elm$parser$Parser$Advanced$run,
										$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
										openListItem2);
									if (!_v65.$) {
										var value = _v65.a;
										var tight2 = A2($elm$core$List$member, $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine, value.b) ? false : tight;
										return $elm$parser$Parser$Advanced$succeed(
											{
												a: _Utils_ap(state.a, value.a),
												b: A2(
													$elm$core$List$cons,
													A6(
														$dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock,
														tight2,
														intended2,
														marker,
														order,
														A2($elm$core$List$cons, value.b, closeListItems2),
														openListItem1),
													rest)
											});
									} else {
										var e = _v65.a;
										return $elm$parser$Parser$Advanced$problem(
											$elm$parser$Parser$Problem(
												$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
									}
								} else {
									var _v66 = A2(
										$elm$parser$Parser$Advanced$run,
										$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
										openListItem2);
									if (!_v66.$) {
										var value = _v66.a;
										var tight2 = A2($elm$core$List$member, $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine, value.b) ? false : tight;
										return $elm$parser$Parser$Advanced$succeed(
											{
												a: _Utils_ap(state.a, value.a),
												b: A2(
													$elm$core$List$cons,
													newRawBlock,
													A2(
														$elm$core$List$cons,
														A6(
															$dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock,
															tight2,
															intended1,
															marker,
															order,
															A2($elm$core$List$cons, value.b, closeListItems2),
															openListItem2),
														rest))
											});
									} else {
										var e = _v66.a;
										return $elm$parser$Parser$Advanced$problem(
											$elm$parser$Parser$Problem(
												$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
									}
								}
							case 1:
								var body1 = newRawBlock.a;
								return $elm$parser$Parser$Advanced$succeed(
									{
										a: state.a,
										b: A2(
											$elm$core$List$cons,
											A6($dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock, tight, intended1, marker, order, closeListItems2, openListItem2 + ('\n' + body1)),
											rest)
									});
							default:
								var _v67 = A2(
									$elm$parser$Parser$Advanced$run,
									$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
									openListItem2);
								if (!_v67.$) {
									var value = _v67.a;
									var tight2 = A2($elm$core$List$member, $dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine, value.b) ? false : tight;
									return $elm$parser$Parser$Advanced$succeed(
										{
											a: _Utils_ap(state.a, value.a),
											b: A2(
												$elm$core$List$cons,
												newRawBlock,
												A2(
													$elm$core$List$cons,
													A6(
														$dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock,
														tight2,
														intended1,
														marker,
														order,
														A2($elm$core$List$cons, value.b, closeListItems2),
														openListItem2),
													rest))
										});
								} else {
									var e = _v67.a;
									return $elm$parser$Parser$Advanced$problem(
										$elm$parser$Parser$Problem(
											$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
								}
						}
					case 1:
						switch (_v41.a.$) {
							case 1:
								var body1 = _v41.a.a;
								var _v68 = _v41.b;
								var body2 = _v68.a.a;
								var rest = _v68.b;
								return $elm$parser$Parser$Advanced$succeed(
									{
										a: state.a,
										b: A2(
											$elm$core$List$cons,
											$dillonkearns$elm_markdown$Markdown$RawBlock$OpenBlockOrParagraph(
												A3($dillonkearns$elm_markdown$Markdown$Parser$joinRawStringsWith, '\n', body2, body1)),
											rest)
									});
							case 13:
								if (!_v41.a.a) {
									var _v69 = _v41.a;
									var _v70 = _v69.a;
									var _v71 = _v41.b;
									var unparsedInlines = _v71.a.a;
									var rest = _v71.b;
									return $elm$parser$Parser$Advanced$succeed(
										{
											a: state.a,
											b: A2(
												$elm$core$List$cons,
												A2($dillonkearns$elm_markdown$Markdown$RawBlock$Heading, 1, unparsedInlines),
												rest)
										});
								} else {
									var _v72 = _v41.a;
									var _v73 = _v72.a;
									var _v74 = _v41.b;
									var unparsedInlines = _v74.a.a;
									var rest = _v74.b;
									return $elm$parser$Parser$Advanced$succeed(
										{
											a: state.a,
											b: A2(
												$elm$core$List$cons,
												A2($dillonkearns$elm_markdown$Markdown$RawBlock$Heading, 2, unparsedInlines),
												rest)
										});
								}
							case 9:
								var _v75 = _v41.a.a;
								var text = _v75.a;
								var alignments = _v75.b;
								var _v76 = _v41.b;
								var rawHeaders = _v76.a.a;
								var rest = _v76.b;
								var _v77 = A2(
									$dillonkearns$elm_markdown$Markdown$TableParser$parseHeader,
									A2($dillonkearns$elm_markdown$Markdown$Table$TableDelimiterRow, text, alignments),
									rawHeaders);
								if (!_v77.$) {
									var headers = _v77.a;
									return $elm$parser$Parser$Advanced$succeed(
										{
											a: state.a,
											b: A2(
												$elm$core$List$cons,
												$dillonkearns$elm_markdown$Markdown$RawBlock$Table(
													A2($dillonkearns$elm_markdown$Markdown$Table$Table, headers, _List_Nil)),
												rest)
										});
								} else {
									return $elm$parser$Parser$Advanced$succeed(
										{
											a: state.a,
											b: A2(
												$elm$core$List$cons,
												$dillonkearns$elm_markdown$Markdown$RawBlock$OpenBlockOrParagraph(
													A3($dillonkearns$elm_markdown$Markdown$Parser$joinRawStringsWith, '\n', rawHeaders, text.cs)),
												rest)
										});
								}
							default:
								break _v41$13;
						}
					case 8:
						if (_v41.a.$ === 8) {
							var updatedTable = _v41.a.a;
							var _v78 = _v41.b;
							var rest = _v78.b;
							return $elm$parser$Parser$Advanced$succeed(
								{
									a: state.a,
									b: A2(
										$elm$core$List$cons,
										$dillonkearns$elm_markdown$Markdown$RawBlock$Table(updatedTable),
										rest)
								});
						} else {
							break _v41$13;
						}
					case 10:
						if (_v41.b.b.b) {
							switch (_v41.b.b.a.$) {
								case 4:
									var _v79 = _v41.b;
									var _v80 = _v79.a;
									var _v81 = _v79.b;
									var _v82 = _v81.a;
									var tight = _v82.a;
									var intended1 = _v82.b;
									var marker = _v82.c;
									var order = _v82.d;
									var closeListItems2 = _v82.e;
									var openListItem2 = _v82.f;
									var rest = _v81.b;
									var _v83 = A2(
										$elm$parser$Parser$Advanced$run,
										$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
										openListItem2);
									if (!_v83.$) {
										var value = _v83.a;
										if (newRawBlock.$ === 4) {
											var intended2 = newRawBlock.b;
											var openListItem = newRawBlock.f;
											return $elm$parser$Parser$Advanced$succeed(
												{
													a: _Utils_ap(state.a, value.a),
													b: A2(
														$elm$core$List$cons,
														A6(
															$dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock,
															false,
															intended2,
															marker,
															order,
															A2($elm$core$List$cons, value.b, closeListItems2),
															openListItem),
														rest)
												});
										} else {
											return $elm$parser$Parser$Advanced$succeed(
												{
													a: _Utils_ap(state.a, value.a),
													b: A2(
														$elm$core$List$cons,
														newRawBlock,
														A2(
															$elm$core$List$cons,
															$dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine,
															A2(
																$elm$core$List$cons,
																A6(
																	$dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock,
																	tight,
																	intended1,
																	marker,
																	order,
																	A2($elm$core$List$cons, value.b, closeListItems2),
																	openListItem2),
																rest)))
												});
										}
									} else {
										var e = _v83.a;
										return $elm$parser$Parser$Advanced$problem(
											$elm$parser$Parser$Problem(
												$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
									}
								case 3:
									var _v85 = _v41.b;
									var _v86 = _v85.a;
									var _v87 = _v85.b;
									var _v88 = _v87.a;
									var tight = _v88.a;
									var intended1 = _v88.b;
									var closeListItems2 = _v88.c;
									var openListItem2 = _v88.d;
									var rest = _v87.b;
									var _v89 = A2(
										$elm$parser$Parser$Advanced$run,
										$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
										openListItem2.cW);
									if (!_v89.$) {
										var value = _v89.a;
										if (newRawBlock.$ === 3) {
											var openListItem = newRawBlock.d;
											return $elm$parser$Parser$Advanced$succeed(
												{
													a: _Utils_ap(state.a, value.a),
													b: A2(
														$elm$core$List$cons,
														A4(
															$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
															false,
															intended1,
															A2(
																$elm$core$List$cons,
																{cW: value.b, o: openListItem2.o},
																closeListItems2),
															openListItem),
														rest)
												});
										} else {
											return $elm$parser$Parser$Advanced$succeed(
												{
													a: _Utils_ap(state.a, value.a),
													b: A2(
														$elm$core$List$cons,
														newRawBlock,
														A2(
															$elm$core$List$cons,
															$dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine,
															A2(
																$elm$core$List$cons,
																A4(
																	$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
																	tight,
																	intended1,
																	A2(
																		$elm$core$List$cons,
																		{cW: value.b, o: openListItem2.o},
																		closeListItems2),
																	openListItem2),
																rest)))
												});
										}
									} else {
										var e = _v89.a;
										return $elm$parser$Parser$Advanced$problem(
											$elm$parser$Parser$Problem(
												$dillonkearns$elm_markdown$Markdown$Parser$deadEndsToString(e)));
									}
								default:
									break _v41$13;
							}
						} else {
							break _v41$13;
						}
					default:
						break _v41$13;
				}
			} else {
				break _v41$13;
			}
		}
		return $elm$parser$Parser$Advanced$succeed(
			{
				a: state.a,
				b: A2($elm$core$List$cons, newRawBlock, state.b)
			});
	});
var $dillonkearns$elm_markdown$Markdown$Parser$inlineParseHelper = F2(
	function (referencesDict, _v36) {
		var unparsedInlines = _v36;
		var mappedReferencesDict = $elm$core$Dict$fromList(
			A2(
				$elm$core$List$map,
				$elm$core$Tuple$mapSecond(
					function (_v37) {
						var destination = _v37.c3;
						var title = _v37.dY;
						return _Utils_Tuple2(destination, title);
					}),
				referencesDict));
		return A2(
			$elm$core$List$map,
			$dillonkearns$elm_markdown$Markdown$Parser$mapInline,
			A2($dillonkearns$elm_markdown$Markdown$InlineParser$parse, mappedReferencesDict, unparsedInlines));
	});
var $dillonkearns$elm_markdown$Markdown$Parser$mapInline = function (inline) {
	switch (inline.$) {
		case 0:
			var string = inline.a;
			return $dillonkearns$elm_markdown$Markdown$Block$Text(string);
		case 1:
			return $dillonkearns$elm_markdown$Markdown$Block$HardLineBreak;
		case 2:
			var string = inline.a;
			return $dillonkearns$elm_markdown$Markdown$Block$CodeSpan(string);
		case 3:
			var string = inline.a;
			var maybeString = inline.b;
			var inlines = inline.c;
			return A3(
				$dillonkearns$elm_markdown$Markdown$Block$Link,
				string,
				maybeString,
				A2($elm$core$List$map, $dillonkearns$elm_markdown$Markdown$Parser$mapInline, inlines));
		case 4:
			var string = inline.a;
			var maybeString = inline.b;
			var inlines = inline.c;
			return A3(
				$dillonkearns$elm_markdown$Markdown$Block$Image,
				string,
				maybeString,
				A2($elm$core$List$map, $dillonkearns$elm_markdown$Markdown$Parser$mapInline, inlines));
		case 5:
			var node = inline.a;
			return $dillonkearns$elm_markdown$Markdown$Block$HtmlInline(
				$dillonkearns$elm_markdown$Markdown$Parser$nodeToRawBlock(node));
		case 6:
			var level = inline.a;
			var inlines = inline.b;
			switch (level) {
				case 1:
					return $dillonkearns$elm_markdown$Markdown$Block$Emphasis(
						A2($elm$core$List$map, $dillonkearns$elm_markdown$Markdown$Parser$mapInline, inlines));
				case 2:
					return $dillonkearns$elm_markdown$Markdown$Block$Strong(
						A2($elm$core$List$map, $dillonkearns$elm_markdown$Markdown$Parser$mapInline, inlines));
				default:
					return $dillonkearns$elm_markdown$Markdown$Helpers$isEven(level) ? $dillonkearns$elm_markdown$Markdown$Block$Strong(
						_List_fromArray(
							[
								$dillonkearns$elm_markdown$Markdown$Parser$mapInline(
								A2($dillonkearns$elm_markdown$Markdown$Inline$Emphasis, level - 2, inlines))
							])) : $dillonkearns$elm_markdown$Markdown$Block$Emphasis(
						_List_fromArray(
							[
								$dillonkearns$elm_markdown$Markdown$Parser$mapInline(
								A2($dillonkearns$elm_markdown$Markdown$Inline$Emphasis, level - 1, inlines))
							]));
			}
		default:
			var inlines = inline.a;
			return $dillonkearns$elm_markdown$Markdown$Block$Strikethrough(
				A2($elm$core$List$map, $dillonkearns$elm_markdown$Markdown$Parser$mapInline, inlines));
	}
};
var $dillonkearns$elm_markdown$Markdown$Parser$nodeToRawBlock = function (node) {
	switch (node.$) {
		case 1:
			return $dillonkearns$elm_markdown$Markdown$Block$HtmlComment('TODO this never happens, but use types to drop this case.');
		case 0:
			var tag = node.a;
			var attributes = node.b;
			var children = node.c;
			var parseChild = function (child) {
				if (child.$ === 1) {
					var text = child.a;
					return $dillonkearns$elm_markdown$Markdown$Parser$textNodeToBlocks(text);
				} else {
					return _List_fromArray(
						[
							$dillonkearns$elm_markdown$Markdown$Block$HtmlBlock(
							$dillonkearns$elm_markdown$Markdown$Parser$nodeToRawBlock(child))
						]);
				}
			};
			return A3(
				$dillonkearns$elm_markdown$Markdown$Block$HtmlElement,
				tag,
				attributes,
				A2($elm$core$List$concatMap, parseChild, children));
		case 2:
			var string = node.a;
			return $dillonkearns$elm_markdown$Markdown$Block$HtmlComment(string);
		case 3:
			var string = node.a;
			return $dillonkearns$elm_markdown$Markdown$Block$Cdata(string);
		case 4:
			var string = node.a;
			return $dillonkearns$elm_markdown$Markdown$Block$ProcessingInstruction(string);
		default:
			var declarationType = node.a;
			var content = node.b;
			return A2($dillonkearns$elm_markdown$Markdown$Block$HtmlDeclaration, declarationType, content);
	}
};
var $dillonkearns$elm_markdown$Markdown$Parser$nodesToBlocks = function (children) {
	return A2($dillonkearns$elm_markdown$Markdown$Parser$nodesToBlocksHelp, children, _List_Nil);
};
var $dillonkearns$elm_markdown$Markdown$Parser$nodesToBlocksHelp = F2(
	function (remaining, soFar) {
		nodesToBlocksHelp:
		while (true) {
			if (remaining.b) {
				var node = remaining.a;
				var rest = remaining.b;
				var _v31 = A2($dillonkearns$elm_markdown$Markdown$Parser$childToBlocks, node, soFar);
				if (!_v31.$) {
					var newSoFar = _v31.a;
					var $temp$remaining = rest,
						$temp$soFar = newSoFar;
					remaining = $temp$remaining;
					soFar = $temp$soFar;
					continue nodesToBlocksHelp;
				} else {
					var e = _v31.a;
					return $elm$core$Result$Err(e);
				}
			} else {
				return $elm$core$Result$Ok(
					$elm$core$List$reverse(soFar));
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$Parser$parse = function (input) {
	var _v27 = A2(
		$elm$parser$Parser$Advanced$run,
		A2(
			$elm$parser$Parser$Advanced$ignorer,
			$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser(),
			$dillonkearns$elm_markdown$Helpers$endOfFile),
		input);
	if (_v27.$ === 1) {
		var e = _v27.a;
		return $elm$core$Result$Err(e);
	} else {
		var v = _v27.a;
		var _v28 = $dillonkearns$elm_markdown$Markdown$Parser$parseAllInlines(v);
		if (_v28.$ === 1) {
			var e = _v28.a;
			return A2(
				$elm$parser$Parser$Advanced$run,
				$elm$parser$Parser$Advanced$problem(e),
				'');
		} else {
			var blocks = _v28.a;
			var isNotEmptyParagraph = function (block) {
				if ((block.$ === 5) && (!block.a.b)) {
					return false;
				} else {
					return true;
				}
			};
			return $elm$core$Result$Ok(
				A2($elm$core$List$filter, isNotEmptyParagraph, blocks));
		}
	}
};
var $dillonkearns$elm_markdown$Markdown$Parser$parseAllInlines = function (state) {
	return A3($dillonkearns$elm_markdown$Markdown$Parser$parseAllInlinesHelp, state, state.b, _List_Nil);
};
var $dillonkearns$elm_markdown$Markdown$Parser$parseAllInlinesHelp = F3(
	function (state, rawBlocks, parsedBlocks) {
		parseAllInlinesHelp:
		while (true) {
			if (rawBlocks.b) {
				var rawBlock = rawBlocks.a;
				var rest = rawBlocks.b;
				var _v26 = A2($dillonkearns$elm_markdown$Markdown$Parser$parseInlines, state.a, rawBlock);
				switch (_v26.$) {
					case 1:
						var newParsedBlock = _v26.a;
						var $temp$state = state,
							$temp$rawBlocks = rest,
							$temp$parsedBlocks = A2($elm$core$List$cons, newParsedBlock, parsedBlocks);
						state = $temp$state;
						rawBlocks = $temp$rawBlocks;
						parsedBlocks = $temp$parsedBlocks;
						continue parseAllInlinesHelp;
					case 0:
						var $temp$state = state,
							$temp$rawBlocks = rest,
							$temp$parsedBlocks = parsedBlocks;
						state = $temp$state;
						rawBlocks = $temp$rawBlocks;
						parsedBlocks = $temp$parsedBlocks;
						continue parseAllInlinesHelp;
					default:
						var e = _v26.a;
						return $elm$core$Result$Err(e);
				}
			} else {
				return $elm$core$Result$Ok(parsedBlocks);
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$Parser$parseHeaderInlines = F2(
	function (linkReferences, header) {
		return A2(
			$elm$core$List$map,
			function (_v24) {
				var label = _v24.ai;
				var alignment = _v24.aD;
				return A3(
					$dillonkearns$elm_markdown$Markdown$Parser$parseRawInline,
					linkReferences,
					function (parsedHeaderLabel) {
						return {aD: alignment, ai: parsedHeaderLabel};
					},
					label);
			},
			header);
	});
var $dillonkearns$elm_markdown$Markdown$Parser$parseInlines = F2(
	function (linkReferences, rawBlock) {
		switch (rawBlock.$) {
			case 0:
				var level = rawBlock.a;
				var unparsedInlines = rawBlock.b;
				var _v17 = $dillonkearns$elm_markdown$Markdown$Parser$toHeading(level);
				if (!_v17.$) {
					var parsedLevel = _v17.a;
					return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock(
						A2(
							$dillonkearns$elm_markdown$Markdown$Block$Heading,
							parsedLevel,
							A2($dillonkearns$elm_markdown$Markdown$Parser$inlineParseHelper, linkReferences, unparsedInlines)));
				} else {
					var e = _v17.a;
					return $dillonkearns$elm_markdown$Markdown$Parser$InlineProblem(e);
				}
			case 1:
				var unparsedInlines = rawBlock.a;
				return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock(
					$dillonkearns$elm_markdown$Markdown$Block$Paragraph(
						A2($dillonkearns$elm_markdown$Markdown$Parser$inlineParseHelper, linkReferences, unparsedInlines)));
			case 2:
				var html = rawBlock.a;
				return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock(
					$dillonkearns$elm_markdown$Markdown$Block$HtmlBlock(html));
			case 3:
				var tight = rawBlock.a;
				var unparsedItems = rawBlock.c;
				var parseItem = F2(
					function (rawBlockTask, rawBlocks) {
						var blocksTask = function () {
							if (!rawBlockTask.$) {
								if (!rawBlockTask.a) {
									return 1;
								} else {
									return 2;
								}
							} else {
								return 0;
							}
						}();
						var blocks = function () {
							var _v18 = $dillonkearns$elm_markdown$Markdown$Parser$parseAllInlines(
								{a: linkReferences, b: rawBlocks});
							if (!_v18.$) {
								var parsedBlocks = _v18.a;
								return parsedBlocks;
							} else {
								return _List_Nil;
							}
						}();
						return A2($dillonkearns$elm_markdown$Markdown$Block$ListItem, blocksTask, blocks);
					});
				return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock(
					A2(
						$dillonkearns$elm_markdown$Markdown$Block$UnorderedList,
						$dillonkearns$elm_markdown$Markdown$Parser$isTightBoolToListDisplay(tight),
						$elm$core$List$reverse(
							A2(
								$elm$core$List$map,
								function (item) {
									return A2(parseItem, item.o, item.cW);
								},
								unparsedItems))));
			case 4:
				var tight = rawBlock.a;
				var startingIndex = rawBlock.d;
				var unparsedItems = rawBlock.e;
				var parseItem = function (rawBlocks) {
					var _v20 = $dillonkearns$elm_markdown$Markdown$Parser$parseAllInlines(
						{a: linkReferences, b: rawBlocks});
					if (!_v20.$) {
						var parsedBlocks = _v20.a;
						return parsedBlocks;
					} else {
						return _List_Nil;
					}
				};
				return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock(
					A3(
						$dillonkearns$elm_markdown$Markdown$Block$OrderedList,
						$dillonkearns$elm_markdown$Markdown$Parser$isTightBoolToListDisplay(tight),
						startingIndex,
						$elm$core$List$reverse(
							A2($elm$core$List$map, parseItem, unparsedItems))));
			case 5:
				var codeBlock = rawBlock.a;
				return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock(
					$dillonkearns$elm_markdown$Markdown$Block$CodeBlock(codeBlock));
			case 7:
				return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock($dillonkearns$elm_markdown$Markdown$Block$ThematicBreak);
			case 10:
				return $dillonkearns$elm_markdown$Markdown$Parser$EmptyBlock;
			case 11:
				return $dillonkearns$elm_markdown$Markdown$Parser$EmptyBlock;
			case 12:
				var rawBlocks = rawBlock.a;
				var _v21 = $dillonkearns$elm_markdown$Markdown$Parser$parseAllInlines(
					{a: linkReferences, b: rawBlocks});
				if (!_v21.$) {
					var parsedBlocks = _v21.a;
					return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock(
						$dillonkearns$elm_markdown$Markdown$Block$BlockQuote(parsedBlocks));
				} else {
					var e = _v21.a;
					return $dillonkearns$elm_markdown$Markdown$Parser$InlineProblem(e);
				}
			case 6:
				var codeBlockBody = rawBlock.a;
				return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock(
					$dillonkearns$elm_markdown$Markdown$Block$CodeBlock(
						{cW: codeBlockBody, dn: $elm$core$Maybe$Nothing}));
			case 8:
				var _v22 = rawBlock.a;
				var header = _v22.a;
				var rows = _v22.b;
				return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock(
					A2(
						$dillonkearns$elm_markdown$Markdown$Block$Table,
						A2($dillonkearns$elm_markdown$Markdown$Parser$parseHeaderInlines, linkReferences, header),
						A2($dillonkearns$elm_markdown$Markdown$Parser$parseRowInlines, linkReferences, rows)));
			case 9:
				var _v23 = rawBlock.a;
				var text = _v23.a;
				return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock(
					$dillonkearns$elm_markdown$Markdown$Block$Paragraph(
						A2($dillonkearns$elm_markdown$Markdown$Parser$inlineParseHelper, linkReferences, text.cs)));
			default:
				var raw = rawBlock.b;
				return $dillonkearns$elm_markdown$Markdown$Parser$ParsedBlock(
					$dillonkearns$elm_markdown$Markdown$Block$Paragraph(
						A2($dillonkearns$elm_markdown$Markdown$Parser$inlineParseHelper, linkReferences, raw)));
		}
	});
var $dillonkearns$elm_markdown$Markdown$Parser$parseRawInline = F3(
	function (linkReferences, wrap, unparsedInlines) {
		return wrap(
			A2($dillonkearns$elm_markdown$Markdown$Parser$inlineParseHelper, linkReferences, unparsedInlines));
	});
var $dillonkearns$elm_markdown$Markdown$Parser$parseRowInlines = F2(
	function (linkReferences, rows) {
		return A2(
			$elm$core$List$map,
			function (row) {
				return A2(
					$elm$core$List$map,
					function (column) {
						return A3($dillonkearns$elm_markdown$Markdown$Parser$parseRawInline, linkReferences, $elm$core$Basics$identity, column);
					},
					row);
			},
			rows);
	});
var $dillonkearns$elm_markdown$Markdown$Parser$stepRawBlock = function (revStmts) {
	return $elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$parser$Parser$Advanced$map,
				function (_v2) {
					return $elm$parser$Parser$Advanced$Done(revStmts);
				},
				$dillonkearns$elm_markdown$Helpers$endOfFile),
				A2(
				$elm$parser$Parser$Advanced$map,
				function (reference) {
					return $elm$parser$Parser$Advanced$Loop(
						A2($dillonkearns$elm_markdown$Markdown$Parser$addReference, revStmts, reference));
				},
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$Markdown$LinkReferenceDefinition$parser)),
				function () {
				var _v3 = revStmts.b;
				_v3$6:
				while (true) {
					if (_v3.b) {
						switch (_v3.a.$) {
							case 1:
								return A2(
									$elm$parser$Parser$Advanced$map,
									function (block) {
										return $elm$parser$Parser$Advanced$Loop(block);
									},
									A2(
										$elm$parser$Parser$Advanced$andThen,
										$dillonkearns$elm_markdown$Markdown$Parser$completeOrMergeBlocks(revStmts),
										$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockAfterOpenBlockOrParagraphParser()));
							case 8:
								var table = _v3.a.a;
								return A2(
									$elm$parser$Parser$Advanced$map,
									function (block) {
										return $elm$parser$Parser$Advanced$Loop(block);
									},
									A2(
										$elm$parser$Parser$Advanced$andThen,
										$dillonkearns$elm_markdown$Markdown$Parser$completeOrMergeBlocks(revStmts),
										$elm$parser$Parser$Advanced$oneOf(
											_List_fromArray(
												[
													$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockNotAfterOpenBlockOrParagraphParser(),
													$dillonkearns$elm_markdown$Markdown$Parser$tableRowIfTableStarted(table)
												]))));
							case 3:
								var _v4 = _v3.a;
								var tight = _v4.a;
								var intended = _v4.b;
								var closeListItems = _v4.c;
								var openListItem = _v4.d;
								var rest = _v3.b;
								var completeOrMergeUnorderedListBlockBlankLine = F2(
									function (state, newString) {
										return _Utils_update(
											state,
											{
												b: A2(
													$elm$core$List$cons,
													$dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine,
													A2(
														$elm$core$List$cons,
														A4(
															$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
															tight,
															intended,
															closeListItems,
															_Utils_update(
																openListItem,
																{
																	cW: A3($dillonkearns$elm_markdown$Markdown$Parser$joinRawStringsWith, '', openListItem.cW, newString)
																})),
														rest))
											});
									});
								var completeOrMergeUnorderedListBlock = F2(
									function (state, newString) {
										return _Utils_update(
											state,
											{
												b: A2(
													$elm$core$List$cons,
													A4(
														$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
														tight,
														intended,
														closeListItems,
														_Utils_update(
															openListItem,
															{
																cW: A3($dillonkearns$elm_markdown$Markdown$Parser$joinRawStringsWith, '\n', openListItem.cW, newString)
															})),
													rest)
											});
									});
								return $elm$parser$Parser$Advanced$oneOf(
									_List_fromArray(
										[
											A2(
											$elm$parser$Parser$Advanced$map,
											function (block) {
												return $elm$parser$Parser$Advanced$Loop(block);
											},
											A2(
												$elm$parser$Parser$Advanced$map,
												function (_v5) {
													return A2(completeOrMergeUnorderedListBlockBlankLine, revStmts, '\n');
												},
												$dillonkearns$elm_markdown$Markdown$Parser$blankLine)),
											A2(
											$elm$parser$Parser$Advanced$map,
											function (block) {
												return $elm$parser$Parser$Advanced$Loop(block);
											},
											A2(
												$elm$parser$Parser$Advanced$map,
												completeOrMergeUnorderedListBlock(revStmts),
												A2(
													$elm$parser$Parser$Advanced$keeper,
													A2(
														$elm$parser$Parser$Advanced$ignorer,
														$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
														$elm$parser$Parser$Advanced$symbol(
															A2(
																$elm$parser$Parser$Advanced$Token,
																A2($elm$core$String$repeat, intended, ' '),
																$elm$parser$Parser$ExpectingSymbol('Indentation')))),
													A2(
														$elm$parser$Parser$Advanced$ignorer,
														$elm$parser$Parser$Advanced$getChompedString($dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd),
														$dillonkearns$elm_markdown$Helpers$lineEndOrEnd)))),
											A2(
											$elm$parser$Parser$Advanced$map,
											function (block) {
												return $elm$parser$Parser$Advanced$Loop(block);
											},
											A2(
												$elm$parser$Parser$Advanced$andThen,
												$dillonkearns$elm_markdown$Markdown$Parser$completeOrMergeBlocks(revStmts),
												$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockAfterList()))
										]));
							case 4:
								var _v10 = _v3.a;
								var tight = _v10.a;
								var intended = _v10.b;
								var marker = _v10.c;
								var order = _v10.d;
								var closeListItems = _v10.e;
								var openListItem = _v10.f;
								var rest = _v3.b;
								var completeOrMergeUnorderedListBlockBlankLine = F2(
									function (state, newString) {
										return _Utils_update(
											state,
											{
												b: A2(
													$elm$core$List$cons,
													$dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine,
													A2(
														$elm$core$List$cons,
														A6($dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock, tight, intended, marker, order, closeListItems, openListItem + ('\n' + newString)),
														rest))
											});
									});
								var completeOrMergeUnorderedListBlock = F2(
									function (state, newString) {
										return _Utils_update(
											state,
											{
												b: A2(
													$elm$core$List$cons,
													A6($dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock, tight, intended, marker, order, closeListItems, openListItem + ('\n' + newString)),
													rest)
											});
									});
								return $elm$parser$Parser$Advanced$oneOf(
									_List_fromArray(
										[
											A2(
											$elm$parser$Parser$Advanced$map,
											function (block) {
												return $elm$parser$Parser$Advanced$Loop(block);
											},
											A2(
												$elm$parser$Parser$Advanced$map,
												function (_v11) {
													return A2(completeOrMergeUnorderedListBlockBlankLine, revStmts, '\n');
												},
												$dillonkearns$elm_markdown$Markdown$Parser$blankLine)),
											A2(
											$elm$parser$Parser$Advanced$map,
											function (block) {
												return $elm$parser$Parser$Advanced$Loop(block);
											},
											A2(
												$elm$parser$Parser$Advanced$map,
												completeOrMergeUnorderedListBlock(revStmts),
												A2(
													$elm$parser$Parser$Advanced$keeper,
													A2(
														$elm$parser$Parser$Advanced$ignorer,
														$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
														$elm$parser$Parser$Advanced$symbol(
															A2(
																$elm$parser$Parser$Advanced$Token,
																A2($elm$core$String$repeat, intended, ' '),
																$elm$parser$Parser$ExpectingSymbol('Indentation')))),
													A2(
														$elm$parser$Parser$Advanced$ignorer,
														$elm$parser$Parser$Advanced$getChompedString($dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd),
														$dillonkearns$elm_markdown$Helpers$lineEndOrEnd)))),
											A2(
											$elm$parser$Parser$Advanced$map,
											function (block) {
												return $elm$parser$Parser$Advanced$Loop(block);
											},
											A2(
												$elm$parser$Parser$Advanced$andThen,
												$dillonkearns$elm_markdown$Markdown$Parser$completeOrMergeBlocks(revStmts),
												$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockAfterList()))
										]));
							case 10:
								if (_v3.b.b) {
									switch (_v3.b.a.$) {
										case 3:
											var _v6 = _v3.a;
											var _v7 = _v3.b;
											var _v8 = _v7.a;
											var tight = _v8.a;
											var intended = _v8.b;
											var closeListItems = _v8.c;
											var openListItem = _v8.d;
											var rest = _v7.b;
											var completeOrMergeUnorderedListBlockBlankLine = F2(
												function (state, newString) {
													return _Utils_update(
														state,
														{
															b: A2(
																$elm$core$List$cons,
																$dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine,
																A2(
																	$elm$core$List$cons,
																	A4(
																		$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
																		tight,
																		intended,
																		closeListItems,
																		_Utils_update(
																			openListItem,
																			{
																				cW: A3($dillonkearns$elm_markdown$Markdown$Parser$joinRawStringsWith, '', openListItem.cW, newString)
																			})),
																	rest))
														});
												});
											var completeOrMergeUnorderedListBlock = F2(
												function (state, newString) {
													return _Utils_update(
														state,
														{
															b: A2(
																$elm$core$List$cons,
																A4(
																	$dillonkearns$elm_markdown$Markdown$RawBlock$UnorderedListBlock,
																	tight,
																	intended,
																	closeListItems,
																	_Utils_update(
																		openListItem,
																		{
																			cW: A3($dillonkearns$elm_markdown$Markdown$Parser$joinRawStringsWith, '\n', openListItem.cW, newString)
																		})),
																rest)
														});
												});
											return ($elm$core$String$trim(openListItem.cW) === '') ? A2(
												$elm$parser$Parser$Advanced$map,
												function (block) {
													return $elm$parser$Parser$Advanced$Loop(block);
												},
												A2(
													$elm$parser$Parser$Advanced$andThen,
													$dillonkearns$elm_markdown$Markdown$Parser$completeOrMergeBlocks(revStmts),
													$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockNotAfterOpenBlockOrParagraphParser())) : $elm$parser$Parser$Advanced$oneOf(
												_List_fromArray(
													[
														A2(
														$elm$parser$Parser$Advanced$map,
														function (block) {
															return $elm$parser$Parser$Advanced$Loop(block);
														},
														A2(
															$elm$parser$Parser$Advanced$map,
															function (_v9) {
																return A2(completeOrMergeUnorderedListBlockBlankLine, revStmts, '\n');
															},
															$dillonkearns$elm_markdown$Markdown$Parser$blankLine)),
														A2(
														$elm$parser$Parser$Advanced$map,
														function (block) {
															return $elm$parser$Parser$Advanced$Loop(block);
														},
														A2(
															$elm$parser$Parser$Advanced$map,
															completeOrMergeUnorderedListBlock(revStmts),
															A2(
																$elm$parser$Parser$Advanced$keeper,
																A2(
																	$elm$parser$Parser$Advanced$ignorer,
																	$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
																	$elm$parser$Parser$Advanced$symbol(
																		A2(
																			$elm$parser$Parser$Advanced$Token,
																			A2($elm$core$String$repeat, intended, ' '),
																			$elm$parser$Parser$ExpectingSymbol('Indentation')))),
																A2(
																	$elm$parser$Parser$Advanced$ignorer,
																	$elm$parser$Parser$Advanced$getChompedString($dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd),
																	$dillonkearns$elm_markdown$Helpers$lineEndOrEnd)))),
														A2(
														$elm$parser$Parser$Advanced$map,
														function (block) {
															return $elm$parser$Parser$Advanced$Loop(block);
														},
														A2(
															$elm$parser$Parser$Advanced$andThen,
															$dillonkearns$elm_markdown$Markdown$Parser$completeOrMergeBlocks(revStmts),
															$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockNotAfterOpenBlockOrParagraphParser()))
													]));
										case 4:
											var _v12 = _v3.a;
											var _v13 = _v3.b;
											var _v14 = _v13.a;
											var tight = _v14.a;
											var intended = _v14.b;
											var marker = _v14.c;
											var order = _v14.d;
											var closeListItems = _v14.e;
											var openListItem = _v14.f;
											var rest = _v13.b;
											var completeOrMergeUnorderedListBlockBlankLine = F2(
												function (state, newString) {
													return _Utils_update(
														state,
														{
															b: A2(
																$elm$core$List$cons,
																$dillonkearns$elm_markdown$Markdown$RawBlock$BlankLine,
																A2(
																	$elm$core$List$cons,
																	A6($dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock, tight, intended, marker, order, closeListItems, openListItem + ('\n' + newString)),
																	rest))
														});
												});
											var completeOrMergeUnorderedListBlock = F2(
												function (state, newString) {
													return _Utils_update(
														state,
														{
															b: A2(
																$elm$core$List$cons,
																A6($dillonkearns$elm_markdown$Markdown$RawBlock$OrderedListBlock, tight, intended, marker, order, closeListItems, openListItem + ('\n' + newString)),
																rest)
														});
												});
											return ($elm$core$String$trim(openListItem) === '') ? A2(
												$elm$parser$Parser$Advanced$map,
												function (block) {
													return $elm$parser$Parser$Advanced$Loop(block);
												},
												A2(
													$elm$parser$Parser$Advanced$andThen,
													$dillonkearns$elm_markdown$Markdown$Parser$completeOrMergeBlocks(revStmts),
													$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockNotAfterOpenBlockOrParagraphParser())) : $elm$parser$Parser$Advanced$oneOf(
												_List_fromArray(
													[
														A2(
														$elm$parser$Parser$Advanced$map,
														function (block) {
															return $elm$parser$Parser$Advanced$Loop(block);
														},
														A2(
															$elm$parser$Parser$Advanced$map,
															function (_v15) {
																return A2(completeOrMergeUnorderedListBlockBlankLine, revStmts, '\n');
															},
															$dillonkearns$elm_markdown$Markdown$Parser$blankLine)),
														A2(
														$elm$parser$Parser$Advanced$map,
														function (block) {
															return $elm$parser$Parser$Advanced$Loop(block);
														},
														A2(
															$elm$parser$Parser$Advanced$map,
															completeOrMergeUnorderedListBlock(revStmts),
															A2(
																$elm$parser$Parser$Advanced$keeper,
																A2(
																	$elm$parser$Parser$Advanced$ignorer,
																	$elm$parser$Parser$Advanced$succeed($elm$core$Basics$identity),
																	$elm$parser$Parser$Advanced$symbol(
																		A2(
																			$elm$parser$Parser$Advanced$Token,
																			A2($elm$core$String$repeat, intended, ' '),
																			$elm$parser$Parser$ExpectingSymbol('Indentation')))),
																A2(
																	$elm$parser$Parser$Advanced$ignorer,
																	$elm$parser$Parser$Advanced$getChompedString($dillonkearns$elm_markdown$Helpers$chompUntilLineEndOrEnd),
																	$dillonkearns$elm_markdown$Helpers$lineEndOrEnd)))),
														A2(
														$elm$parser$Parser$Advanced$map,
														function (block) {
															return $elm$parser$Parser$Advanced$Loop(block);
														},
														A2(
															$elm$parser$Parser$Advanced$andThen,
															$dillonkearns$elm_markdown$Markdown$Parser$completeOrMergeBlocks(revStmts),
															$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockNotAfterOpenBlockOrParagraphParser()))
													]));
										default:
											break _v3$6;
									}
								} else {
									break _v3$6;
								}
							default:
								break _v3$6;
						}
					} else {
						break _v3$6;
					}
				}
				return A2(
					$elm$parser$Parser$Advanced$map,
					function (block) {
						return $elm$parser$Parser$Advanced$Loop(block);
					},
					A2(
						$elm$parser$Parser$Advanced$andThen,
						$dillonkearns$elm_markdown$Markdown$Parser$completeOrMergeBlocks(revStmts),
						$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockNotAfterOpenBlockOrParagraphParser()));
			}(),
				A2(
				$elm$parser$Parser$Advanced$map,
				function (block) {
					return $elm$parser$Parser$Advanced$Loop(block);
				},
				A2(
					$elm$parser$Parser$Advanced$andThen,
					$dillonkearns$elm_markdown$Markdown$Parser$completeOrMergeBlocks(revStmts),
					$dillonkearns$elm_markdown$Markdown$Parser$openBlockOrParagraphParser))
			]));
};
var $dillonkearns$elm_markdown$Markdown$Parser$textNodeToBlocks = function (textNodeValue) {
	return A2(
		$elm$core$Result$withDefault,
		_List_Nil,
		$dillonkearns$elm_markdown$Markdown$Parser$parse(textNodeValue));
};
var $dillonkearns$elm_markdown$Markdown$Parser$xmlNodeToHtmlNode = function (xmlNode) {
	switch (xmlNode.$) {
		case 1:
			var innerText = xmlNode.a;
			return $elm$parser$Parser$Advanced$succeed(
				$dillonkearns$elm_markdown$Markdown$RawBlock$OpenBlockOrParagraph(innerText));
		case 0:
			var tag = xmlNode.a;
			var attributes = xmlNode.b;
			var children = xmlNode.c;
			var _v1 = $dillonkearns$elm_markdown$Markdown$Parser$nodesToBlocks(children);
			if (!_v1.$) {
				var parsedChildren = _v1.a;
				return $elm$parser$Parser$Advanced$succeed(
					$dillonkearns$elm_markdown$Markdown$RawBlock$Html(
						A3($dillonkearns$elm_markdown$Markdown$Block$HtmlElement, tag, attributes, parsedChildren)));
			} else {
				var err = _v1.a;
				return $elm$parser$Parser$Advanced$problem(err);
			}
		case 2:
			var string = xmlNode.a;
			return $elm$parser$Parser$Advanced$succeed(
				$dillonkearns$elm_markdown$Markdown$RawBlock$Html(
					$dillonkearns$elm_markdown$Markdown$Block$HtmlComment(string)));
		case 3:
			var string = xmlNode.a;
			return $elm$parser$Parser$Advanced$succeed(
				$dillonkearns$elm_markdown$Markdown$RawBlock$Html(
					$dillonkearns$elm_markdown$Markdown$Block$Cdata(string)));
		case 4:
			var string = xmlNode.a;
			return $elm$parser$Parser$Advanced$succeed(
				$dillonkearns$elm_markdown$Markdown$RawBlock$Html(
					$dillonkearns$elm_markdown$Markdown$Block$ProcessingInstruction(string)));
		default:
			var declarationType = xmlNode.a;
			var content = xmlNode.b;
			return $elm$parser$Parser$Advanced$succeed(
				$dillonkearns$elm_markdown$Markdown$RawBlock$Html(
					A2($dillonkearns$elm_markdown$Markdown$Block$HtmlDeclaration, declarationType, content)));
	}
};
function $dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser() {
	return A2(
		$elm$parser$Parser$Advanced$andThen,
		$dillonkearns$elm_markdown$Markdown$Parser$completeBlocks,
		A2(
			$elm$parser$Parser$Advanced$loop,
			{a: _List_Nil, b: _List_Nil},
			$dillonkearns$elm_markdown$Markdown$Parser$stepRawBlock));
}
function $dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockNotAfterOpenBlockOrParagraphParser() {
	return $elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				$dillonkearns$elm_markdown$Markdown$Parser$parseAsParagraphInsteadOfHtmlBlock,
				$dillonkearns$elm_markdown$Markdown$Parser$blankLine,
				$dillonkearns$elm_markdown$Markdown$Parser$blockQuote,
				A2(
				$elm$parser$Parser$Advanced$map,
				$dillonkearns$elm_markdown$Markdown$RawBlock$CodeBlock,
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$Markdown$CodeBlock$parser)),
				$dillonkearns$elm_markdown$Markdown$Parser$indentedCodeBlock,
				A2(
				$elm$parser$Parser$Advanced$map,
				function (_v40) {
					return $dillonkearns$elm_markdown$Markdown$RawBlock$ThematicBreak;
				},
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$ThematicBreak$parser)),
				$dillonkearns$elm_markdown$Markdown$Parser$unorderedListBlock(false),
				$dillonkearns$elm_markdown$Markdown$Parser$orderedListBlock(false),
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$Markdown$Heading$parser),
				$dillonkearns$elm_markdown$Markdown$Parser$cyclic$htmlParser()
			]));
}
function $dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockAfterOpenBlockOrParagraphParser() {
	return $elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				$dillonkearns$elm_markdown$Markdown$Parser$parseAsParagraphInsteadOfHtmlBlock,
				$dillonkearns$elm_markdown$Markdown$Parser$blankLine,
				$dillonkearns$elm_markdown$Markdown$Parser$blockQuote,
				A2(
				$elm$parser$Parser$Advanced$map,
				$dillonkearns$elm_markdown$Markdown$RawBlock$CodeBlock,
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$Markdown$CodeBlock$parser)),
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$Markdown$Parser$setextLineParser),
				A2(
				$elm$parser$Parser$Advanced$map,
				function (_v39) {
					return $dillonkearns$elm_markdown$Markdown$RawBlock$ThematicBreak;
				},
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$ThematicBreak$parser)),
				$dillonkearns$elm_markdown$Markdown$Parser$unorderedListBlock(true),
				$dillonkearns$elm_markdown$Markdown$Parser$orderedListBlock(true),
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$Markdown$Heading$parser),
				$dillonkearns$elm_markdown$Markdown$Parser$cyclic$htmlParser(),
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$Markdown$Parser$tableDelimiterInOpenParagraph)
			]));
}
function $dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockAfterList() {
	return $elm$parser$Parser$Advanced$oneOf(
		_List_fromArray(
			[
				$dillonkearns$elm_markdown$Markdown$Parser$parseAsParagraphInsteadOfHtmlBlock,
				$dillonkearns$elm_markdown$Markdown$Parser$blankLine,
				$dillonkearns$elm_markdown$Markdown$Parser$blockQuote,
				A2(
				$elm$parser$Parser$Advanced$map,
				$dillonkearns$elm_markdown$Markdown$RawBlock$CodeBlock,
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$Markdown$CodeBlock$parser)),
				A2(
				$elm$parser$Parser$Advanced$map,
				function (_v38) {
					return $dillonkearns$elm_markdown$Markdown$RawBlock$ThematicBreak;
				},
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$ThematicBreak$parser)),
				$dillonkearns$elm_markdown$Markdown$Parser$unorderedListBlock(false),
				$dillonkearns$elm_markdown$Markdown$Parser$orderedListBlock(false),
				$elm$parser$Parser$Advanced$backtrackable($dillonkearns$elm_markdown$Markdown$Heading$parser),
				$dillonkearns$elm_markdown$Markdown$Parser$cyclic$htmlParser()
			]));
}
function $dillonkearns$elm_markdown$Markdown$Parser$cyclic$htmlParser() {
	return A2($elm$parser$Parser$Advanced$andThen, $dillonkearns$elm_markdown$Markdown$Parser$xmlNodeToHtmlNode, $dillonkearns$elm_markdown$HtmlParser$html);
}
var $dillonkearns$elm_markdown$Markdown$Parser$rawBlockParser = $dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser();
$dillonkearns$elm_markdown$Markdown$Parser$cyclic$rawBlockParser = function () {
	return $dillonkearns$elm_markdown$Markdown$Parser$rawBlockParser;
};
var $dillonkearns$elm_markdown$Markdown$Parser$mergeableBlockNotAfterOpenBlockOrParagraphParser = $dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockNotAfterOpenBlockOrParagraphParser();
$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockNotAfterOpenBlockOrParagraphParser = function () {
	return $dillonkearns$elm_markdown$Markdown$Parser$mergeableBlockNotAfterOpenBlockOrParagraphParser;
};
var $dillonkearns$elm_markdown$Markdown$Parser$mergeableBlockAfterOpenBlockOrParagraphParser = $dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockAfterOpenBlockOrParagraphParser();
$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockAfterOpenBlockOrParagraphParser = function () {
	return $dillonkearns$elm_markdown$Markdown$Parser$mergeableBlockAfterOpenBlockOrParagraphParser;
};
var $dillonkearns$elm_markdown$Markdown$Parser$mergeableBlockAfterList = $dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockAfterList();
$dillonkearns$elm_markdown$Markdown$Parser$cyclic$mergeableBlockAfterList = function () {
	return $dillonkearns$elm_markdown$Markdown$Parser$mergeableBlockAfterList;
};
var $dillonkearns$elm_markdown$Markdown$Parser$htmlParser = $dillonkearns$elm_markdown$Markdown$Parser$cyclic$htmlParser();
$dillonkearns$elm_markdown$Markdown$Parser$cyclic$htmlParser = function () {
	return $dillonkearns$elm_markdown$Markdown$Parser$htmlParser;
};
var $elm$core$Result$map2 = F3(
	function (func, ra, rb) {
		if (ra.$ === 1) {
			var x = ra.a;
			return $elm$core$Result$Err(x);
		} else {
			var a = ra.a;
			if (rb.$ === 1) {
				var x = rb.a;
				return $elm$core$Result$Err(x);
			} else {
				var b = rb.a;
				return $elm$core$Result$Ok(
					A2(func, a, b));
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$Renderer$combineResults = A2(
	$elm$core$List$foldr,
	$elm$core$Result$map2($elm$core$List$cons),
	$elm$core$Result$Ok(_List_Nil));
var $elm$core$Result$andThen = F2(
	function (callback, result) {
		if (!result.$) {
			var value = result.a;
			return callback(value);
		} else {
			var msg = result.a;
			return $elm$core$Result$Err(msg);
		}
	});
var $dillonkearns$elm_markdown$Markdown$Block$foldl = F3(
	function (_function, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var block = list.a;
				var remainingBlocks = list.b;
				switch (block.$) {
					case 0:
						var html = block.a;
						if (!html.$) {
							var children = html.c;
							var $temp$function = _function,
								$temp$acc = A2(_function, block, acc),
								$temp$list = _Utils_ap(children, remainingBlocks);
							_function = $temp$function;
							acc = $temp$acc;
							list = $temp$list;
							continue foldl;
						} else {
							var $temp$function = _function,
								$temp$acc = A2(_function, block, acc),
								$temp$list = remainingBlocks;
							_function = $temp$function;
							acc = $temp$acc;
							list = $temp$list;
							continue foldl;
						}
					case 1:
						var blocks = block.b;
						var childBlocks = A2(
							$elm$core$List$concatMap,
							function (_v3) {
								var children = _v3.b;
								return children;
							},
							blocks);
						var $temp$function = _function,
							$temp$acc = A2(_function, block, acc),
							$temp$list = _Utils_ap(childBlocks, remainingBlocks);
						_function = $temp$function;
						acc = $temp$acc;
						list = $temp$list;
						continue foldl;
					case 2:
						var blocks = block.c;
						var $temp$function = _function,
							$temp$acc = A2(_function, block, acc),
							$temp$list = _Utils_ap(
							$elm$core$List$concat(blocks),
							remainingBlocks);
						_function = $temp$function;
						acc = $temp$acc;
						list = $temp$list;
						continue foldl;
					case 3:
						var blocks = block.a;
						var $temp$function = _function,
							$temp$acc = A2(_function, block, acc),
							$temp$list = _Utils_ap(blocks, remainingBlocks);
						_function = $temp$function;
						acc = $temp$acc;
						list = $temp$list;
						continue foldl;
					case 4:
						var $temp$function = _function,
							$temp$acc = A2(_function, block, acc),
							$temp$list = remainingBlocks;
						_function = $temp$function;
						acc = $temp$acc;
						list = $temp$list;
						continue foldl;
					case 5:
						var $temp$function = _function,
							$temp$acc = A2(_function, block, acc),
							$temp$list = remainingBlocks;
						_function = $temp$function;
						acc = $temp$acc;
						list = $temp$list;
						continue foldl;
					case 6:
						var $temp$function = _function,
							$temp$acc = A2(_function, block, acc),
							$temp$list = remainingBlocks;
						_function = $temp$function;
						acc = $temp$acc;
						list = $temp$list;
						continue foldl;
					case 7:
						var $temp$function = _function,
							$temp$acc = A2(_function, block, acc),
							$temp$list = remainingBlocks;
						_function = $temp$function;
						acc = $temp$acc;
						list = $temp$list;
						continue foldl;
					default:
						var $temp$function = _function,
							$temp$acc = A2(_function, block, acc),
							$temp$list = remainingBlocks;
						_function = $temp$function;
						acc = $temp$acc;
						list = $temp$list;
						continue foldl;
				}
			}
		}
	});
var $dillonkearns$elm_markdown$Markdown$Block$extractInlineBlockText = function (block) {
	switch (block.$) {
		case 5:
			var inlines = block.a;
			return $dillonkearns$elm_markdown$Markdown$Block$extractInlineText(inlines);
		case 0:
			var html = block.a;
			if (!html.$) {
				var blocks = html.c;
				return A3(
					$dillonkearns$elm_markdown$Markdown$Block$foldl,
					F2(
						function (nestedBlock, soFar) {
							return _Utils_ap(
								soFar,
								$dillonkearns$elm_markdown$Markdown$Block$extractInlineBlockText(nestedBlock));
						}),
					'',
					blocks);
			} else {
				return '';
			}
		case 1:
			var items = block.b;
			return A2(
				$elm$core$String$join,
				'\n',
				A2(
					$elm$core$List$map,
					function (_v4) {
						var blocks = _v4.b;
						return A2(
							$elm$core$String$join,
							'\n',
							A2($elm$core$List$map, $dillonkearns$elm_markdown$Markdown$Block$extractInlineBlockText, blocks));
					},
					items));
		case 2:
			var items = block.c;
			return A2(
				$elm$core$String$join,
				'\n',
				A2(
					$elm$core$List$map,
					function (blocks) {
						return A2(
							$elm$core$String$join,
							'\n',
							A2($elm$core$List$map, $dillonkearns$elm_markdown$Markdown$Block$extractInlineBlockText, blocks));
					},
					items));
		case 3:
			var blocks = block.a;
			return A2(
				$elm$core$String$join,
				'\n',
				A2($elm$core$List$map, $dillonkearns$elm_markdown$Markdown$Block$extractInlineBlockText, blocks));
		case 4:
			var inlines = block.b;
			return $dillonkearns$elm_markdown$Markdown$Block$extractInlineText(inlines);
		case 6:
			var header = block.a;
			var rows = block.b;
			return A2(
				$elm$core$String$join,
				'\n',
				$elm$core$List$concat(
					_List_fromArray(
						[
							A2(
							$elm$core$List$map,
							$dillonkearns$elm_markdown$Markdown$Block$extractInlineText,
							A2(
								$elm$core$List$map,
								function ($) {
									return $.ai;
								},
								header)),
							$elm$core$List$concat(
							A2(
								$elm$core$List$map,
								$elm$core$List$map($dillonkearns$elm_markdown$Markdown$Block$extractInlineText),
								rows))
						])));
		case 7:
			var body = block.a.cW;
			return body;
		default:
			return '';
	}
};
var $dillonkearns$elm_markdown$Markdown$Block$extractInlineText = function (inlines) {
	return A3($elm$core$List$foldl, $dillonkearns$elm_markdown$Markdown$Block$extractTextHelp, '', inlines);
};
var $dillonkearns$elm_markdown$Markdown$Block$extractTextHelp = F2(
	function (inline, text) {
		switch (inline.$) {
			case 7:
				var str = inline.a;
				return _Utils_ap(text, str);
			case 8:
				return text + ' ';
			case 6:
				var str = inline.a;
				return _Utils_ap(text, str);
			case 1:
				var inlines = inline.c;
				return _Utils_ap(
					text,
					$dillonkearns$elm_markdown$Markdown$Block$extractInlineText(inlines));
			case 2:
				var inlines = inline.c;
				return _Utils_ap(
					text,
					$dillonkearns$elm_markdown$Markdown$Block$extractInlineText(inlines));
			case 0:
				var html = inline.a;
				if (!html.$) {
					var blocks = html.c;
					return A3(
						$dillonkearns$elm_markdown$Markdown$Block$foldl,
						F2(
							function (block, soFar) {
								return _Utils_ap(
									soFar,
									$dillonkearns$elm_markdown$Markdown$Block$extractInlineBlockText(block));
							}),
						text,
						blocks);
				} else {
					return text;
				}
			case 4:
				var inlines = inline.a;
				return _Utils_ap(
					text,
					$dillonkearns$elm_markdown$Markdown$Block$extractInlineText(inlines));
			case 3:
				var inlines = inline.a;
				return _Utils_ap(
					text,
					$dillonkearns$elm_markdown$Markdown$Block$extractInlineText(inlines));
			default:
				var inlines = inline.a;
				return _Utils_ap(
					text,
					$dillonkearns$elm_markdown$Markdown$Block$extractInlineText(inlines));
		}
	});
var $elm$core$Tuple$pair = F2(
	function (a, b) {
		return _Utils_Tuple2(a, b);
	});
var $dillonkearns$elm_markdown$Markdown$Renderer$renderHtml = F5(
	function (tagName, attributes, children, _v0, renderedChildren) {
		var htmlRenderer = _v0;
		return A2(
			$elm$core$Result$andThen,
			function (okChildren) {
				return A2(
					$elm$core$Result$map,
					function (myRenderer) {
						return myRenderer(okChildren);
					},
					A3(htmlRenderer, tagName, attributes, children));
			},
			$dillonkearns$elm_markdown$Markdown$Renderer$combineResults(renderedChildren));
	});
var $dillonkearns$elm_markdown$Markdown$Renderer$foldThing = F3(
	function (renderer, topLevelInline, soFar) {
		var _v12 = A2($dillonkearns$elm_markdown$Markdown$Renderer$renderSingleInline, renderer, topLevelInline);
		if (!_v12.$) {
			var inline = _v12.a;
			return A2($elm$core$List$cons, inline, soFar);
		} else {
			return soFar;
		}
	});
var $dillonkearns$elm_markdown$Markdown$Renderer$renderHelper = F2(
	function (renderer, blocks) {
		return A2(
			$elm$core$List$filterMap,
			$dillonkearns$elm_markdown$Markdown$Renderer$renderHelperSingle(renderer),
			blocks);
	});
var $dillonkearns$elm_markdown$Markdown$Renderer$renderHelperSingle = function (renderer) {
	return function (block) {
		switch (block.$) {
			case 4:
				var level = block.a;
				var content = block.b;
				return $elm$core$Maybe$Just(
					A2(
						$elm$core$Result$map,
						function (children) {
							return renderer.bb(
								{
									bN: children,
									cb: level,
									dN: $dillonkearns$elm_markdown$Markdown$Block$extractInlineText(content)
								});
						},
						A2($dillonkearns$elm_markdown$Markdown$Renderer$renderStyled, renderer, content)));
			case 5:
				var content = block.a;
				return $elm$core$Maybe$Just(
					A2(
						$elm$core$Result$map,
						renderer.bl,
						A2($dillonkearns$elm_markdown$Markdown$Renderer$renderStyled, renderer, content)));
			case 0:
				var html = block.a;
				if (!html.$) {
					var tag = html.a;
					var attributes = html.b;
					var children = html.c;
					return $elm$core$Maybe$Just(
						A4($dillonkearns$elm_markdown$Markdown$Renderer$renderHtmlNode, renderer, tag, attributes, children));
				} else {
					return $elm$core$Maybe$Nothing;
				}
			case 1:
				var tight = block.a;
				var items = block.b;
				return $elm$core$Maybe$Just(
					A2(
						$elm$core$Result$map,
						function (listItems) {
							return renderer.bE(
								A2(
									$elm$core$List$map,
									function (_v7) {
										var task = _v7.a;
										var children = _v7.b;
										return A2(
											$dillonkearns$elm_markdown$Markdown$Block$ListItem,
											task,
											$elm$core$List$concat(children));
									},
									listItems));
						},
						$dillonkearns$elm_markdown$Markdown$Renderer$combineResults(
							A2(
								$elm$core$List$map,
								function (_v4) {
									var task = _v4.a;
									var children = _v4.b;
									return A2(
										$elm$core$Result$map,
										$dillonkearns$elm_markdown$Markdown$Block$ListItem(task),
										$dillonkearns$elm_markdown$Markdown$Renderer$combineResults(
											function (blocks) {
												return A2(
													$elm$core$List$filterMap,
													function (listItemBlock) {
														var _v5 = _Utils_Tuple2(tight, listItemBlock);
														if ((_v5.a === 1) && (_v5.b.$ === 5)) {
															var _v6 = _v5.a;
															var content = _v5.b.a;
															return $elm$core$Maybe$Just(
																A2($dillonkearns$elm_markdown$Markdown$Renderer$renderStyled, renderer, content));
														} else {
															return A2(
																$elm$core$Maybe$map,
																$elm$core$Result$map($elm$core$List$singleton),
																A2($dillonkearns$elm_markdown$Markdown$Renderer$renderHelperSingle, renderer, listItemBlock));
														}
													},
													blocks);
											}(children)));
								},
								items))));
			case 2:
				var tight = block.a;
				var startingIndex = block.b;
				var items = block.c;
				return $elm$core$Maybe$Just(
					A2(
						$elm$core$Result$map,
						function (listItems) {
							return A2(
								renderer.bk,
								startingIndex,
								A2(
									$elm$core$List$map,
									function (children) {
										return $elm$core$List$concat(children);
									},
									listItems));
						},
						$dillonkearns$elm_markdown$Markdown$Renderer$combineResults(
							A2(
								$elm$core$List$map,
								function (itemsblocks) {
									return $dillonkearns$elm_markdown$Markdown$Renderer$combineResults(
										function (blocks) {
											return A2(
												$elm$core$List$filterMap,
												function (listItemBlock) {
													var _v8 = _Utils_Tuple2(tight, listItemBlock);
													if ((_v8.a === 1) && (_v8.b.$ === 5)) {
														var _v9 = _v8.a;
														var content = _v8.b.a;
														return $elm$core$Maybe$Just(
															A2($dillonkearns$elm_markdown$Markdown$Renderer$renderStyled, renderer, content));
													} else {
														return A2(
															$elm$core$Maybe$map,
															$elm$core$Result$map($elm$core$List$singleton),
															A2($dillonkearns$elm_markdown$Markdown$Renderer$renderHelperSingle, renderer, listItemBlock));
													}
												},
												blocks);
										}(itemsblocks));
								},
								items))));
			case 7:
				var codeBlock = block.a;
				return $elm$core$Maybe$Just(
					$elm$core$Result$Ok(
						renderer.a5(codeBlock)));
			case 8:
				return $elm$core$Maybe$Just(
					$elm$core$Result$Ok(renderer.bC));
			case 3:
				var nestedBlocks = block.a;
				return $elm$core$Maybe$Just(
					A2(
						$elm$core$Result$map,
						renderer.a3,
						$dillonkearns$elm_markdown$Markdown$Renderer$combineResults(
							A2($dillonkearns$elm_markdown$Markdown$Renderer$renderHelper, renderer, nestedBlocks))));
			default:
				var header = block.a;
				var rows = block.b;
				var renderedHeaderCells = $dillonkearns$elm_markdown$Markdown$Renderer$combineResults(
					A2(
						$elm$core$List$map,
						function (_v11) {
							var label = _v11.ai;
							var alignment = _v11.aD;
							return A2(
								$elm$core$Result$map,
								$elm$core$Tuple$pair(alignment),
								A2($dillonkearns$elm_markdown$Markdown$Renderer$renderStyled, renderer, label));
						},
						header));
				var renderedHeader = A2(
					$elm$core$Result$map,
					function (listListView) {
						return renderer.bz(
							$elm$core$List$singleton(
								renderer.aW(
									A2(
										$elm$core$List$map,
										function (_v10) {
											var maybeAlignment = _v10.a;
											var item = _v10.b;
											return A2(renderer.bA, maybeAlignment, item);
										},
										listListView))));
					},
					renderedHeaderCells);
				var renderedBody = function (r) {
					return $elm$core$List$isEmpty(r) ? _List_Nil : _List_fromArray(
						[
							renderer.bx(r)
						]);
				};
				var alignmentForColumn = function (columnIndex) {
					return A2(
						$elm$core$Maybe$andThen,
						function ($) {
							return $.aD;
						},
						$elm$core$List$head(
							A2($elm$core$List$drop, columnIndex, header)));
				};
				var renderRow = function (cells) {
					return A2(
						$elm$core$Result$map,
						renderer.aW,
						A2(
							$elm$core$Result$map,
							$elm$core$List$indexedMap(
								F2(
									function (index, cell) {
										return A2(
											renderer.by,
											alignmentForColumn(index),
											cell);
									})),
							$dillonkearns$elm_markdown$Markdown$Renderer$combineResults(
								A2(
									$elm$core$List$map,
									$dillonkearns$elm_markdown$Markdown$Renderer$renderStyled(renderer),
									cells))));
				};
				var renderedRows = $dillonkearns$elm_markdown$Markdown$Renderer$combineResults(
					A2($elm$core$List$map, renderRow, rows));
				return $elm$core$Maybe$Just(
					A3(
						$elm$core$Result$map2,
						F2(
							function (h, r) {
								return renderer.bw(
									A2(
										$elm$core$List$cons,
										h,
										renderedBody(r)));
							}),
						renderedHeader,
						renderedRows));
		}
	};
};
var $dillonkearns$elm_markdown$Markdown$Renderer$renderHtmlNode = F4(
	function (renderer, tag, attributes, children) {
		return A5(
			$dillonkearns$elm_markdown$Markdown$Renderer$renderHtml,
			tag,
			attributes,
			children,
			renderer.bc,
			A2($dillonkearns$elm_markdown$Markdown$Renderer$renderHelper, renderer, children));
	});
var $dillonkearns$elm_markdown$Markdown$Renderer$renderSingleInline = F2(
	function (renderer, inline) {
		switch (inline.$) {
			case 4:
				var innerInlines = inline.a;
				return $elm$core$Maybe$Just(
					A2(
						$elm$core$Result$map,
						renderer.bu,
						A2($dillonkearns$elm_markdown$Markdown$Renderer$renderStyled, renderer, innerInlines)));
			case 3:
				var innerInlines = inline.a;
				return $elm$core$Maybe$Just(
					A2(
						$elm$core$Result$map,
						renderer.a8,
						A2($dillonkearns$elm_markdown$Markdown$Renderer$renderStyled, renderer, innerInlines)));
			case 5:
				var innerInlines = inline.a;
				return $elm$core$Maybe$Just(
					A2(
						$elm$core$Result$map,
						renderer.bt,
						A2($dillonkearns$elm_markdown$Markdown$Renderer$renderStyled, renderer, innerInlines)));
			case 2:
				var src = inline.a;
				var title = inline.b;
				var children = inline.c;
				return $elm$core$Maybe$Just(
					$elm$core$Result$Ok(
						renderer.bd(
							{
								a2: $dillonkearns$elm_markdown$Markdown$Block$extractInlineText(children),
								bq: src,
								dY: title
							})));
			case 7:
				var string = inline.a;
				return $elm$core$Maybe$Just(
					$elm$core$Result$Ok(
						renderer.dX(string)));
			case 6:
				var string = inline.a;
				return $elm$core$Maybe$Just(
					$elm$core$Result$Ok(
						renderer.a6(string)));
			case 1:
				var destination = inline.a;
				var title = inline.b;
				var inlines = inline.c;
				return $elm$core$Maybe$Just(
					A2(
						$elm$core$Result$andThen,
						function (children) {
							return $elm$core$Result$Ok(
								A2(
									renderer.bg,
									{c3: destination, dY: title},
									children));
						},
						A2($dillonkearns$elm_markdown$Markdown$Renderer$renderStyled, renderer, inlines)));
			case 8:
				return $elm$core$Maybe$Just(
					$elm$core$Result$Ok(renderer.ba));
			default:
				var html = inline.a;
				if (!html.$) {
					var tag = html.a;
					var attributes = html.b;
					var children = html.c;
					return $elm$core$Maybe$Just(
						A4($dillonkearns$elm_markdown$Markdown$Renderer$renderHtmlNode, renderer, tag, attributes, children));
				} else {
					return $elm$core$Maybe$Nothing;
				}
		}
	});
var $dillonkearns$elm_markdown$Markdown$Renderer$renderStyled = F2(
	function (renderer, styledStrings) {
		return $dillonkearns$elm_markdown$Markdown$Renderer$combineResults(
			A3(
				$elm$core$List$foldr,
				$dillonkearns$elm_markdown$Markdown$Renderer$foldThing(renderer),
				_List_Nil,
				styledStrings));
	});
var $dillonkearns$elm_markdown$Markdown$Renderer$render = F2(
	function (renderer, ast) {
		return $dillonkearns$elm_markdown$Markdown$Renderer$combineResults(
			A2($dillonkearns$elm_markdown$Markdown$Renderer$renderHelper, renderer, ast));
	});
var $author$project$Feature$TextAPI$imageIdFromUrl = function (url) {
	return A2(
		$elm$core$Maybe$andThen,
		$elm$core$String$toInt,
		$elm$core$List$head(
			$elm$core$List$reverse(
				A2($elm$core$String$split, '/', url))));
};
var $author$project$Feature$TextAPI$resolveImageUrl = F4(
	function (url, title, altInlines, model) {
		var newUrl = function () {
			var _v0 = $author$project$Feature$TextAPI$imageIdFromUrl(url);
			if (!_v0.$) {
				var imageId = _v0.a;
				var _v1 = A2($elm$core$Dict$get, imageId, model.dh);
				if (!_v1.$) {
					var blobUrl = _v1.a;
					return blobUrl;
				} else {
					var _v2 = A2(
						$author$project$Utils$info,
						'resolveImageUrl',
						_Utils_Tuple2('MISSING', imageId));
					return url;
				}
			} else {
				var _v3 = A2(
					$author$project$Utils$info,
					'resolveImageUrl',
					_Utils_Tuple2('INVALID', url));
				return url;
			}
		}();
		return A3($dillonkearns$elm_markdown$Markdown$Block$Image, newUrl, title, altInlines);
	});
var $dillonkearns$elm_markdown$Markdown$Block$walk = F2(
	function (_function, block) {
		switch (block.$) {
			case 3:
				var blocks = block.a;
				return _function(
					$dillonkearns$elm_markdown$Markdown$Block$BlockQuote(
						A2(
							$elm$core$List$map,
							$dillonkearns$elm_markdown$Markdown$Block$walk(_function),
							blocks)));
			case 0:
				var html = block.a;
				if (!html.$) {
					var string = html.a;
					var htmlAttributes = html.b;
					var blocks = html.c;
					return _function(
						$dillonkearns$elm_markdown$Markdown$Block$HtmlBlock(
							A3(
								$dillonkearns$elm_markdown$Markdown$Block$HtmlElement,
								string,
								htmlAttributes,
								A2(
									$elm$core$List$map,
									$dillonkearns$elm_markdown$Markdown$Block$walk(_function),
									blocks))));
				} else {
					return _function(block);
				}
			case 1:
				return _function(block);
			case 2:
				return _function(block);
			case 4:
				return _function(block);
			case 5:
				return _function(block);
			case 6:
				return _function(block);
			case 7:
				return _function(block);
			default:
				return _function(block);
		}
	});
var $dillonkearns$elm_markdown$Markdown$Block$inlineParserWalk = F2(
	function (_function, inline) {
		switch (inline.$) {
			case 1:
				var url = inline.a;
				var maybeTitle = inline.b;
				var inlines = inline.c;
				return _function(
					A3(
						$dillonkearns$elm_markdown$Markdown$Block$Link,
						url,
						maybeTitle,
						A2(
							$elm$core$List$map,
							$dillonkearns$elm_markdown$Markdown$Block$inlineParserWalk(_function),
							inlines)));
			case 2:
				var url = inline.a;
				var maybeTitle = inline.b;
				var inlines = inline.c;
				return _function(
					A3(
						$dillonkearns$elm_markdown$Markdown$Block$Image,
						url,
						maybeTitle,
						A2(
							$elm$core$List$map,
							$dillonkearns$elm_markdown$Markdown$Block$inlineParserWalk(_function),
							inlines)));
			case 3:
				var inlines = inline.a;
				return _function(
					$dillonkearns$elm_markdown$Markdown$Block$Emphasis(
						A2(
							$elm$core$List$map,
							$dillonkearns$elm_markdown$Markdown$Block$inlineParserWalk(_function),
							inlines)));
			case 5:
				var inlines = inline.a;
				return _function(
					$dillonkearns$elm_markdown$Markdown$Block$Strikethrough(
						A2(
							$elm$core$List$map,
							$dillonkearns$elm_markdown$Markdown$Block$inlineParserWalk(_function),
							inlines)));
			case 0:
				var html = inline.a;
				if (!html.$) {
					var string = html.a;
					var htmlAttributes = html.b;
					var children = html.c;
					return $dillonkearns$elm_markdown$Markdown$Block$HtmlInline(
						A3(
							$dillonkearns$elm_markdown$Markdown$Block$HtmlElement,
							string,
							htmlAttributes,
							A2(
								$elm$core$List$map,
								$dillonkearns$elm_markdown$Markdown$Block$walkInlines(_function),
								children)));
				} else {
					return _function(inline);
				}
			case 4:
				var inlines = inline.a;
				return $dillonkearns$elm_markdown$Markdown$Block$Strong(
					A2(
						$elm$core$List$map,
						$dillonkearns$elm_markdown$Markdown$Block$inlineParserWalk(_function),
						inlines));
			case 6:
				return _function(inline);
			case 7:
				return _function(inline);
			default:
				return _function(inline);
		}
	});
var $dillonkearns$elm_markdown$Markdown$Block$walkInlines = F2(
	function (_function, block) {
		return A2(
			$dillonkearns$elm_markdown$Markdown$Block$walk,
			$dillonkearns$elm_markdown$Markdown$Block$walkInlinesHelp(_function),
			block);
	});
var $dillonkearns$elm_markdown$Markdown$Block$walkInlinesHelp = F2(
	function (_function, block) {
		switch (block.$) {
			case 5:
				var inlines = block.a;
				return $dillonkearns$elm_markdown$Markdown$Block$Paragraph(
					A2(
						$elm$core$List$map,
						$dillonkearns$elm_markdown$Markdown$Block$inlineParserWalk(_function),
						inlines));
			case 1:
				var tight = block.a;
				var listItems = block.b;
				return A2(
					$dillonkearns$elm_markdown$Markdown$Block$UnorderedList,
					tight,
					A2(
						$elm$core$List$map,
						function (_v1) {
							var task = _v1.a;
							var children = _v1.b;
							return A2(
								$dillonkearns$elm_markdown$Markdown$Block$ListItem,
								task,
								A2(
									$elm$core$List$map,
									function (child) {
										return A2($dillonkearns$elm_markdown$Markdown$Block$walkInlinesHelp, _function, child);
									},
									children));
						},
						listItems));
			case 2:
				var tight = block.a;
				var startIndex = block.b;
				var listItems = block.c;
				return A3(
					$dillonkearns$elm_markdown$Markdown$Block$OrderedList,
					tight,
					startIndex,
					A2(
						$elm$core$List$map,
						function (blocks) {
							return A2(
								$elm$core$List$map,
								function (child) {
									return A2($dillonkearns$elm_markdown$Markdown$Block$walkInlinesHelp, _function, child);
								},
								blocks);
						},
						listItems));
			case 3:
				var children = block.a;
				return $dillonkearns$elm_markdown$Markdown$Block$BlockQuote(
					A2(
						$elm$core$List$map,
						$dillonkearns$elm_markdown$Markdown$Block$walkInlinesHelp(_function),
						children));
			case 4:
				var level = block.a;
				var children = block.b;
				return A2(
					$dillonkearns$elm_markdown$Markdown$Block$Heading,
					level,
					A2($elm$core$List$map, _function, children));
			case 6:
				var header = block.a;
				var rows = block.b;
				return A2(
					$dillonkearns$elm_markdown$Markdown$Block$Table,
					A2(
						$elm$core$List$map,
						function (_v2) {
							var alignment = _v2.aD;
							var label = _v2.ai;
							return {
								aD: alignment,
								ai: A2($elm$core$List$map, _function, label)
							};
						},
						header),
					A2(
						$elm$core$List$map,
						$elm$core$List$map(
							$elm$core$List$map(_function)),
						rows));
			case 0:
				var html = block.a;
				if (!html.$) {
					var string = html.a;
					var htmlAttributes = html.b;
					var blocks = html.c;
					return $dillonkearns$elm_markdown$Markdown$Block$HtmlBlock(
						A3(
							$dillonkearns$elm_markdown$Markdown$Block$HtmlElement,
							string,
							htmlAttributes,
							A2(
								$elm$core$List$map,
								$dillonkearns$elm_markdown$Markdown$Block$walkInlinesHelp(_function),
								blocks)));
				} else {
					return block;
				}
			case 7:
				return block;
			default:
				return block;
		}
	});
var $author$project$Feature$TextAPI$resolveImageUrls = F2(
	function (model, blocks) {
		return A2(
			$elm$core$List$map,
			$dillonkearns$elm_markdown$Markdown$Block$walkInlines(
				function (inline) {
					if (inline.$ === 2) {
						var url = inline.a;
						var title = inline.b;
						var altInlines = inline.c;
						return A4($author$project$Feature$TextAPI$resolveImageUrl, url, title, altInlines, model);
					} else {
						return inline;
					}
				}),
			blocks);
	});
var $author$project$Feature$TextAPI$markdown = F2(
	function (source, model) {
		return A2(
			$elm$core$Result$withDefault,
			_List_fromArray(
				[
					$elm$html$Html$text('Markdown Problem!')
				]),
			A2(
				$dillonkearns$elm_markdown$Markdown$Renderer$render,
				$dillonkearns$elm_markdown$Markdown$Renderer$defaultHtmlRenderer,
				A2(
					$author$project$Feature$TextAPI$resolveImageUrls,
					model,
					A2(
						$elm$core$Result$withDefault,
						_List_Nil,
						$dillonkearns$elm_markdown$Markdown$Parser$parse(source)))));
	});
var $author$project$Config$editorFont = 'monospace';
var $author$project$Map$textEditorStyle = F2(
	function (topicId, model) {
		var height = function () {
			var _v0 = A3(
				$author$project$Item$topicSize,
				topicId,
				function ($) {
					return $.c8;
				},
				model);
			if (!_v0.$) {
				var size = _v0.a;
				return size.b_;
			} else {
				return 0;
			}
		}();
		return _List_fromArray(
			[
				A2($elm$html$Html$Attributes$style, 'position', 'relative'),
				A2(
				$elm$html$Html$Attributes$style,
				'top',
				$elm$core$String$fromInt(-$author$project$Config$topicBorderWidth) + 'px'),
				A2(
				$elm$html$Html$Attributes$style,
				'height',
				$elm$core$String$fromInt(height) + 'px'),
				A2($elm$html$Html$Attributes$style, 'font-family', $author$project$Config$editorFont),
				A2($elm$html$Html$Attributes$style, 'border-color', 'black'),
				A2($elm$html$Html$Attributes$style, 'resize', 'none')
			]);
	});
var $author$project$Map$textViewStyle = _List_fromArray(
	[
		A2(
		$elm$html$Html$Attributes$style,
		'min-width',
		$elm$core$String$fromInt($author$project$Config$topicSize.cN - $author$project$Config$topicSize.b_) + 'px'),
		A2($elm$html$Html$Attributes$style, 'max-width', 'max-content')
	]);
var $author$project$Feature$Text$OnTextareaInput = function (a) {
	return {$: 1, a: a};
};
var $author$project$Utils$onEsc = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'keydown',
		A2($author$project$Utils$keyDecoder, 27, msg));
};
var $elm$html$Html$textarea = _VirtualDom_node('textarea');
var $author$project$Feature$TextAPI$viewTextarea = F3(
	function (topic, boxPath, style) {
		return A2(
			$elm$html$Html$textarea,
			_Utils_ap(
				_List_fromArray(
					[
						$elm$html$Html$Attributes$id(
						A3($author$project$Box$elemId, 'input', topic.aK, boxPath)),
						$elm$html$Html$Attributes$value(topic.dX),
						$elm$html$Html$Events$onInput(
						A2($elm$core$Basics$composeL, $author$project$Model$Text, $author$project$Feature$Text$OnTextareaInput)),
						$author$project$Utils$onEsc(
						$author$project$Model$Text($author$project$Feature$Text$LeaveEdit)),
						$author$project$Utils$onMouseDownStop($author$project$Model$NoOp)
					]),
				style),
			_List_Nil);
	});
var $author$project$Map$detailTopic = F4(
	function (topic, props, boxPath, model) {
		var textElem = function () {
			var _v0 = A3($author$project$Feature$TextAPI$isEdit, topic.aK, boxPath, model);
			if (_v0) {
				return A3(
					$author$project$Feature$TextAPI$viewTextarea,
					topic,
					boxPath,
					_Utils_ap(
						A3($author$project$Map$detailTextStyle, topic.aK, boxPath, model),
						A2($author$project$Map$textEditorStyle, topic.aK, model)));
			} else {
				return A2(
					$elm$html$Html$div,
					_Utils_ap(
						A3($author$project$Map$detailTextStyle, topic.aK, boxPath, model),
						$author$project$Map$textViewStyle),
					A2($author$project$Feature$TextAPI$markdown, topic.dX, model));
			}
		}();
		return _Utils_Tuple2(
			$author$project$Map$detailTopicStyle(props),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_Utils_ap(
						$author$project$Map$iconBoxStyle(props),
						_Utils_ap(
							$author$project$Map$detailTopicIconBoxStyle,
							A3($author$project$Map$selectionStyle, topic.aK, boxPath, model))),
					_List_fromArray(
						[
							A4($author$project$Feature$IconAPI$viewTopicIcon, topic.aK, $author$project$Config$topicIconSize, $author$project$Map$topicIconStyle, model)
						])),
					textElem
				]));
	});
var $elm$svg$Svg$g = $elm$svg$Svg$trustedNode('g');
var $elm$svg$Svg$Attributes$transform = _VirtualDom_attribute('transform');
var $author$project$Map$gAttr = F3(
	function (boxId, boxRect, model) {
		return _List_fromArray(
			[
				$elm$svg$Svg$Attributes$transform(
				'translate(' + ($elm$core$String$fromInt(-boxRect.d2) + (' ' + ($elm$core$String$fromInt(-boxRect.d4) + ')'))))
			]);
	});
var $author$project$Feature$Mouse$Hover = F3(
	function (a, b, c) {
		return {$: 4, a: a, b: b, c: c};
	});
var $author$project$Feature$Mouse$Unhover = F3(
	function (a, b, c) {
		return {$: 5, a: a, b: b, c: c};
	});
var $elm$html$Html$Events$onMouseEnter = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseenter',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$html$Html$Events$onMouseLeave = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseleave',
		$elm$json$Json$Decode$succeed(msg));
};
var $author$project$Feature$MouseAPI$hoverHandler = F2(
	function (topicId, boxPath) {
		return _List_fromArray(
			[
				$elm$html$Html$Events$onMouseEnter(
				$author$project$Model$Mouse(
					A3($author$project$Feature$Mouse$Hover, 'dmx-topic', topicId, boxPath))),
				$elm$html$Html$Events$onMouseLeave(
				$author$project$Model$Mouse(
					A3($author$project$Feature$Mouse$Unhover, 'dmx-topic', topicId, boxPath)))
			]);
	});
var $author$project$Map$labelTopic = F4(
	function (topic, props, boxPath, model) {
		return _Utils_Tuple2(
			_Utils_ap(
				$author$project$Map$topicPosStyle(props),
				_Utils_ap(
					A4($author$project$Map$topicFlexboxStyle, topic, props, boxPath, model),
					A3($author$project$Map$selectionStyle, topic.aK, boxPath, model))),
			A4($author$project$Map$viewLabelTopic, topic, props, boxPath, model));
	});
var $author$project$Feature$Mouse$DownOnItem = F4(
	function (a, b, c, d) {
		return {$: 1, a: a, b: b, c: c, d: d};
	});
var $author$project$Feature$MouseAPI$mouseDownHandler = F2(
	function (topicId, boxPath) {
		return _List_fromArray(
			[
				A2(
				$elm$html$Html$Events$stopPropagationOn,
				'mousedown',
				A2(
					$elm$json$Json$Decode$andThen,
					function (pos) {
						return $elm$json$Json$Decode$succeed(
							_Utils_Tuple2(
								$author$project$Model$Mouse(
									A4($author$project$Feature$Mouse$DownOnItem, 'dmx-topic', topicId, boxPath, pos)),
								true));
					},
					$author$project$Utils$pointDecoder))
			]);
	});
var $author$project$Config$whiteBoxRadius = 14;
var $author$project$Map$nestedBoxStyle = F4(
	function (topicId, rect, boxPath, model) {
		var width = rect.a0 - rect.d2;
		var r = $elm$core$String$fromInt($author$project$Config$whiteBoxRadius) + 'px';
		var height = rect.a1 - rect.d4;
		return _Utils_ap(
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'position', 'absolute'),
					A2(
					$elm$html$Html$Attributes$style,
					'left',
					$elm$core$String$fromInt(-$author$project$Config$topicBorderWidth) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'top',
					$elm$core$String$fromInt($author$project$Config$topicSize.b_ - (2 * $author$project$Config$topicBorderWidth)) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromInt(width) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromInt(height) + 'px'),
					A2($elm$html$Html$Attributes$style, 'border-radius', '0 ' + (r + (' ' + (r + (' ' + r)))))
				]),
			_Utils_ap(
				A3($author$project$Map$topicBorderStyle, topicId, boxPath, model),
				A3($author$project$Map$selectionStyle, topicId, boxPath, model)));
	});
var $author$project$Map$svgStyle = _List_fromArray(
	[
		A2($elm$html$Html$Attributes$style, 'position', 'absolute'),
		A2($elm$html$Html$Attributes$style, 'top', '0'),
		A2($elm$html$Html$Attributes$style, 'left', '0')
	]);
var $author$project$Map$topicAttr = F2(
	function (topicId, boxPath) {
		return _List_fromArray(
			[
				$elm$html$Html$Attributes$id(
				A3($author$project$Box$elemId, 'topic', topicId, boxPath))
			]);
	});
var $author$project$Map$topicLayerStyle = function (boxRect) {
	return _List_fromArray(
		[
			A2($elm$html$Html$Attributes$style, 'position', 'absolute'),
			A2(
			$elm$html$Html$Attributes$style,
			'left',
			$elm$core$String$fromInt(-boxRect.d2) + 'px'),
			A2(
			$elm$html$Html$Attributes$style,
			'top',
			$elm$core$String$fromInt(-boxRect.d4) + 'px')
		]);
};
var $author$project$Config$topicLimboFilter = 'contrast(0.3) brightness(1.5)';
var $author$project$Map$topicStyle = F3(
	function (id, boxId, model) {
		var isSelected = A3($author$project$Feature$SelAPI$isSelected, id, boxId, model);
		var isLimbo = A3($author$project$Map$Model$isLimboTopic, id, boxId, model);
		var isDragging = function () {
			var _v0 = model.dt.c6;
			if ((_v0.$ === 3) && (!_v0.a)) {
				var _v1 = _v0.a;
				var id_ = _v0.b;
				return _Utils_eq(id_, id);
			} else {
				return false;
			}
		}();
		return _List_fromArray(
			[
				A2($elm$html$Html$Attributes$style, 'position', 'absolute'),
				A2(
				$elm$html$Html$Attributes$style,
				'filter',
				isLimbo ? $author$project$Config$topicLimboFilter : 'none'),
				A2(
				$elm$html$Html$Attributes$style,
				'z-index',
				isDragging ? '1' : (isSelected ? '3' : '2'))
			]);
	});
var $author$project$Map$unboxedTopic = F4(
	function (topic, props, boxPath, model) {
		var _v0 = A4($author$project$Map$labelTopic, topic, props, boxPath, model);
		var style = _v0.a;
		var children = _v0.b;
		return _Utils_Tuple2(
			style,
			_Utils_ap(
				children,
				A3($author$project$Map$viewItemCount, topic.aK, props, model)));
	});
var $elm$core$Maybe$map2 = F3(
	function (func, ma, mb) {
		if (ma.$ === 1) {
			return $elm$core$Maybe$Nothing;
		} else {
			var a = ma.a;
			if (mb.$ === 1) {
				return $elm$core$Maybe$Nothing;
			} else {
				var b = mb.a;
				return $elm$core$Maybe$Just(
					A2(func, a, b));
			}
		}
	});
var $author$project$Map$assocGeometry = F3(
	function (assoc, boxId, model) {
		var pos2 = A3($author$project$Box$topicPos, assoc.dL, boxId, model);
		var pos1 = A3($author$project$Box$topicPos, assoc.dK, boxId, model);
		var _v0 = A3(
			$elm$core$Maybe$map2,
			F2(
				function (p1, p2) {
					return _Utils_Tuple2(p1, p2);
				}),
			pos1,
			pos2);
		if (!_v0.$) {
			var geometry = _v0.a;
			return $elm$core$Maybe$Just(geometry);
		} else {
			return A3(
				$author$project$Utils$fail,
				'assocGeometry',
				{cS: assoc, a4: boxId},
				$elm$core$Maybe$Nothing);
		}
	});
var $elm$core$Basics$abs = function (n) {
	return (n < 0) ? (-n) : n;
};
var $author$project$Config$assocRadius = 14;
var $author$project$Config$assocColor = 'black';
var $author$project$Config$assocLimboColor = '#858585';
var $author$project$Config$assocWidth = 1.5;
var $author$project$Map$lineDasharray = function (assoc) {
	if (!assoc.$) {
		var assocType = assoc.a.cT;
		if (assocType === 1) {
			return '5 0';
		} else {
			return '5';
		}
	} else {
		return '5 0';
	}
};
var $elm$svg$Svg$Attributes$strokeDasharray = _VirtualDom_attribute('stroke-dasharray');
var $author$project$Map$lineStyle = F3(
	function (assoc, boxId, model) {
		var color = function () {
			if (!assoc.$) {
				var id = assoc.a.aK;
				var _v1 = A3($author$project$Map$Model$isLimboAssoc, id, boxId, model);
				if (_v1) {
					return $author$project$Config$assocLimboColor;
				} else {
					return $author$project$Config$assocColor;
				}
			} else {
				return $author$project$Config$assocLimboColor;
			}
		}();
		return _List_fromArray(
			[
				$elm$svg$Svg$Attributes$stroke(color),
				$elm$svg$Svg$Attributes$strokeWidth(
				$elm$core$String$fromFloat($author$project$Config$assocWidth) + 'px'),
				$elm$svg$Svg$Attributes$strokeDasharray(
				$author$project$Map$lineDasharray(assoc)),
				$elm$svg$Svg$Attributes$fill('none')
			]);
	});
var $author$project$Map$taxiLine = F5(
	function (pos1, pos2, assoc, boxId, model) {
		if (_Utils_cmp(
			$elm$core$Basics$abs(pos2.d1 - pos1.d1),
			2 * $author$project$Config$assocRadius) < 0) {
			var xm = ((pos1.d1 + pos2.d1) / 2) | 0;
			return A2(
				$elm$svg$Svg$path,
				_Utils_ap(
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$d(
							'M ' + ($elm$core$String$fromInt(xm) + (' ' + ($elm$core$String$fromInt(pos1.d3) + (' V ' + $elm$core$String$fromInt(pos2.d3))))))
						]),
					A3($author$project$Map$lineStyle, assoc, boxId, model)),
				_List_Nil);
		} else {
			if (_Utils_cmp(
				$elm$core$Basics$abs(pos2.d3 - pos1.d3),
				2 * $author$project$Config$assocRadius) < 0) {
				var ym = ((pos1.d3 + pos2.d3) / 2) | 0;
				return A2(
					$elm$svg$Svg$path,
					_Utils_ap(
						_List_fromArray(
							[
								$elm$svg$Svg$Attributes$d(
								'M ' + ($elm$core$String$fromInt(pos1.d1) + (' ' + ($elm$core$String$fromInt(ym) + (' H ' + $elm$core$String$fromInt(pos2.d1))))))
							]),
						A3($author$project$Map$lineStyle, assoc, boxId, model)),
					_List_Nil);
			} else {
				var ym = ((pos1.d3 + pos2.d3) / 2) | 0;
				var sy = (_Utils_cmp(pos2.d3, pos1.d3) > 0) ? (-1) : 1;
				var y1 = $elm$core$String$fromInt(ym + (sy * $author$project$Config$assocRadius));
				var y2 = $elm$core$String$fromInt(ym - (sy * $author$project$Config$assocRadius));
				var sx = (_Utils_cmp(pos2.d1, pos1.d1) > 0) ? 1 : (-1);
				var x1 = $elm$core$String$fromInt(pos1.d1 + (sx * $author$project$Config$assocRadius));
				var x2 = $elm$core$String$fromInt(pos2.d1 - (sx * $author$project$Config$assocRadius));
				var sweep1 = (sy === 1) ? ((sx === 1) ? 1 : 0) : ((sx === 1) ? 0 : 1);
				var sweep2 = 1 - sweep1;
				var sw2 = $elm$core$String$fromInt(sweep2);
				var sw1 = $elm$core$String$fromInt(sweep1);
				var r = $elm$core$String$fromInt($author$project$Config$assocRadius);
				return A2(
					$elm$svg$Svg$path,
					_Utils_ap(
						_List_fromArray(
							[
								$elm$svg$Svg$Attributes$d(
								'M ' + ($elm$core$String$fromInt(pos1.d1) + (' ' + ($elm$core$String$fromInt(pos1.d3) + (' V ' + (y1 + (' A ' + (r + (' ' + (r + (' 0 0 ' + (sw1 + (' ' + (x1 + (' ' + ($elm$core$String$fromInt(ym) + (' H ' + (x2 + (' A ' + (r + (' ' + (r + (' 0 0 ' + (sw2 + (' ' + ($elm$core$String$fromInt(pos2.d1) + (' ' + (y2 + (' V ' + $elm$core$String$fromInt(pos2.d3))))))))))))))))))))))))))))))
							]),
						A3($author$project$Map$lineStyle, assoc, boxId, model)),
					_List_Nil);
			}
		}
	});
var $author$project$Map$lineFunc = $author$project$Map$taxiLine;
var $author$project$Map$viewAssoc = F3(
	function (assoc, boxId, model) {
		var geom = A3($author$project$Map$assocGeometry, assoc, boxId, model);
		if (!geom.$) {
			var _v1 = geom.a;
			var pos1 = _v1.a;
			var pos2 = _v1.b;
			return A5(
				$author$project$Map$lineFunc,
				pos1,
				pos2,
				$elm$core$Maybe$Just(assoc),
				boxId,
				model);
		} else {
			return $elm$html$Html$text('');
		}
	});
var $author$project$Config$appHeaderHeight = 36;
var $author$project$Map$accumulateRect = F3(
	function (posAcc, boxId, model) {
		var _v0 = A2($author$project$Box$byIdOrLog, boxId, model);
		if (!_v0.$) {
			var box = _v0.a;
			return A2($author$project$ModelParts$Point, posAcc.d1 - box.aO.d2, posAcc.d3 - box.aO.d4);
		} else {
			return A2($author$project$ModelParts$Point, 0, 0);
		}
	});
var $author$project$Map$absPos = F3(
	function (boxPath, posAcc, model) {
		if (boxPath.b) {
			if (!boxPath.b.b) {
				var boxId = boxPath.a;
				return A3($author$project$Map$accumulateRect, posAcc, boxId, model);
			} else {
				var boxId = boxPath.a;
				var _v3 = boxPath.b;
				var parentBoxId = _v3.a;
				var boxIds = _v3.b;
				return A5($author$project$Map$accumulatePos, posAcc, boxId, parentBoxId, boxIds, model);
			}
		} else {
			return A3(
				$author$project$Utils$logError,
				'absPos',
				'boxPath is empty!',
				A2($author$project$ModelParts$Point, 0, 0));
		}
	});
var $author$project$Map$accumulatePos = F5(
	function (posAcc, boxId, parentBoxId, boxIds, model) {
		var _v0 = A3($author$project$Map$accumulateRect, posAcc, boxId, model);
		var x = _v0.d1;
		var y = _v0.d3;
		var _v1 = A3($author$project$Box$topicPos, boxId, parentBoxId, model);
		if (!_v1.$) {
			var boxPos = _v1.a;
			return A3(
				$author$project$Map$absPos,
				A2($elm$core$List$cons, parentBoxId, boxIds),
				A2($author$project$ModelParts$Point, (x + boxPos.d1) - $author$project$Config$topicW2, (y + boxPos.d3) + $author$project$Config$topicH2),
				model);
		} else {
			return A2($author$project$ModelParts$Point, 0, 0);
		}
	});
var $author$project$Map$relPos = F3(
	function (pos, boxPath, model) {
		var posAbs = A3(
			$author$project$Map$absPos,
			boxPath,
			A2($author$project$ModelParts$Point, 0, 0),
			model);
		return A2($author$project$ModelParts$Point, pos.d1 - posAbs.d1, pos.d3 - posAbs.d3);
	});
var $author$project$Map$viewAssocDraft = F2(
	function (boxId, model) {
		var _v0 = model.dt.c6;
		if ((_v0.$ === 3) && (_v0.a === 1)) {
			var _v1 = _v0.a;
			var boxPath = _v0.c;
			var origPos = _v0.d;
			var pos = _v0.e;
			var _v2 = _Utils_Tuple2(
				_Utils_eq(
					$author$project$Box$firstId(boxPath),
					boxId),
				A2($author$project$Box$byIdOrLog, model.a4, model));
			if (_v2.a && (!_v2.b.$)) {
				var box = _v2.b.a;
				var pagePos = A2($author$project$ModelParts$Point, pos.d1 + box.aU.d1, (pos.d3 + box.aU.d3) - $author$project$Config$appHeaderHeight);
				return _List_fromArray(
					[
						A5(
						$author$project$Map$lineFunc,
						origPos,
						A3($author$project$Map$relPos, pagePos, boxPath, model),
						$elm$core$Maybe$Nothing,
						boxId,
						model)
					]);
			} else {
				return _List_Nil;
			}
		} else {
			return _List_Nil;
		}
	});
var $author$project$Feature$MouseAPI$isHovered = F3(
	function (itemId, boxId, model) {
		var _v0 = model.dt.c6;
		if (((_v0.$ === 4) && (!_v0.a.$)) && _v0.a.a.b.b) {
			var _v1 = _v0.a.a;
			var itemId_ = _v1.a;
			var _v2 = _v1.b;
			var boxId_ = _v2.a;
			return _Utils_eq(itemId, itemId_) && _Utils_eq(boxId, boxId_);
		} else {
			return false;
		}
	});
var $author$project$Feature$Tool$ToggleDisplay = F2(
	function (a, b) {
		return {$: 14, a: a, b: b};
	});
var $author$project$Model$Tool = function (a) {
	return {$: 5, a: a};
};
var $elm$html$Html$button = _VirtualDom_node('button');
var $author$project$Feature$ToolAPI$caretStyle = _List_fromArray(
	[
		A2($elm$html$Html$Attributes$style, 'position', 'absolute'),
		A2($elm$html$Html$Attributes$style, 'top', '1px'),
		A2($elm$html$Html$Attributes$style, 'left', '-27px'),
		A2($elm$html$Html$Attributes$style, 'background-color', 'transparent'),
		A2($elm$html$Html$Attributes$style, 'border', 'none')
	]);
var $elm$html$Html$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $author$project$Feature$ToolAPI$viewCaret = F3(
	function (itemId, boxId, model) {
		if (A2($author$project$Item$isBox, itemId, model) && A2($author$project$Box$isEmpty, itemId, model)) {
			return _List_Nil;
		} else {
			var icon = function () {
				var _v0 = A3($author$project$Box$displayMode, itemId, boxId, model);
				if (!_v0.$) {
					if (!_v0.a.$) {
						if (!_v0.a.a) {
							var _v1 = _v0.a.a;
							return 'chevron-right';
						} else {
							var _v2 = _v0.a.a;
							return 'chevron-down';
						}
					} else {
						switch (_v0.a.a) {
							case 0:
								var _v3 = _v0.a.a;
								return 'chevron-right';
							case 1:
								var _v4 = _v0.a.a;
								return 'chevron-down';
							default:
								var _v5 = _v0.a.a;
								return 'chevron-down';
						}
					}
				} else {
					return '??';
				}
			}();
			return _List_fromArray(
				[
					A2(
					$elm$html$Html$button,
					_Utils_ap(
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick(
								$author$project$Model$Tool(
									A2($author$project$Feature$Tool$ToggleDisplay, itemId, boxId))),
								$author$project$Utils$onMouseDownStop($author$project$Model$NoOp)
							]),
						$author$project$Feature$ToolAPI$caretStyle),
					_List_fromArray(
						[
							A3($author$project$Feature$IconAPI$view, icon, 20, _List_Nil)
						]))
				]);
		}
	});
var $author$project$Feature$Tool$Image = function (a) {
	return {$: 15, a: a};
};
var $author$project$Feature$Tool$LeaveEdit = {$: 16};
var $author$project$Config$toolbarColor = '#e9e9ed';
var $author$project$Feature$ToolAPI$toolbarStyle = F3(
	function (itemId, boxId, model) {
		var offset = function () {
			var _v0 = A3($author$project$Box$displayMode, itemId, boxId, model);
			_v0$2:
			while (true) {
				if (!_v0.$) {
					if (!_v0.a.$) {
						if (_v0.a.a === 1) {
							var _v1 = _v0.a.a;
							return 1;
						} else {
							break _v0$2;
						}
					} else {
						if (!_v0.a.a) {
							var _v2 = _v0.a.a;
							return 1;
						} else {
							break _v0$2;
						}
					}
				} else {
					break _v0$2;
				}
			}
			return 0;
		}();
		return _List_fromArray(
			[
				A2($elm$html$Html$Attributes$style, 'position', 'absolute'),
				A2(
				$elm$html$Html$Attributes$style,
				'top',
				$elm$core$String$fromInt(offset - 30) + 'px'),
				A2(
				$elm$html$Html$Attributes$style,
				'left',
				$elm$core$String$fromInt(offset - 1) + 'px'),
				A2($elm$html$Html$Attributes$style, 'white-space', 'nowrap'),
				A2($elm$html$Html$Attributes$style, 'background-color', $author$project$Config$toolbarColor),
				A2(
				$elm$html$Html$Attributes$style,
				'border-radius',
				$elm$core$String$fromInt($author$project$Config$topicRadius) + 'px'),
				A2($elm$html$Html$Attributes$style, 'padding', '4px 3px 0'),
				A2($elm$html$Html$Attributes$style, 'z-index', '2')
			]);
	});
var $author$project$Config$itemToolbarIconSize = 18;
var $author$project$Feature$ToolAPI$iconButtonStyle = _List_fromArray(
	[
		A2($elm$html$Html$Attributes$style, 'border', 'none'),
		A2($elm$html$Html$Attributes$style, 'background-color', 'transparent'),
		A2($elm$html$Html$Attributes$style, 'margin', '0 2px')
	]);
var $author$project$Feature$ToolAPI$viewIconButton = F7(
	function (label, icon, iconSize, msg, isDisabled, shouldCancel, extraStyle) {
		var stop = function () {
			if (shouldCancel) {
				return _List_Nil;
			} else {
				return _List_fromArray(
					[
						$author$project$Utils$onMouseDownStop($author$project$Model$NoOp)
					]);
			}
		}();
		return A2(
			$elm$html$Html$button,
			_Utils_ap(
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('tool'),
						$elm$html$Html$Attributes$title(label),
						$elm$html$Html$Events$onClick(msg),
						$elm$html$Html$Attributes$disabled(isDisabled)
					]),
				_Utils_ap(
					stop,
					_Utils_ap($author$project$Feature$ToolAPI$iconButtonStyle, extraStyle))),
			_List_fromArray(
				[
					A3($author$project$Feature$IconAPI$view, icon, iconSize, _List_Nil)
				]));
	});
var $author$project$Feature$ToolAPI$viewItemButton = F5(
	function (label, icon, msg, isDisabled, shouldCancel) {
		return A7($author$project$Feature$ToolAPI$viewIconButton, label, icon, $author$project$Config$itemToolbarIconSize, msg, isDisabled, shouldCancel, _List_Nil);
	});
var $author$project$Feature$ToolAPI$viewTextToolbar = F3(
	function (itemId, boxId, model) {
		return A2(
			$elm$html$Html$div,
			A3($author$project$Feature$ToolAPI$toolbarStyle, itemId, boxId, model),
			_List_fromArray(
				[
					A5(
					$author$project$Feature$ToolAPI$viewItemButton,
					'Insert Image',
					'image',
					$author$project$Model$Tool(
						$author$project$Feature$Tool$Image(itemId)),
					false,
					false),
					A5(
					$author$project$Feature$ToolAPI$viewItemButton,
					'Done',
					'check',
					$author$project$Model$Tool($author$project$Feature$Tool$LeaveEdit),
					false,
					false)
				]));
	});
var $author$project$Feature$Tool$Delete = {$: 10};
var $author$project$Feature$Tool$Edit = {$: 7};
var $author$project$Feature$Tool$Fullscreen = function (a) {
	return {$: 12, a: a};
};
var $author$project$Feature$Tool$Icon = {$: 8};
var $author$project$Feature$Tool$Remove = {$: 11};
var $author$project$Feature$Tool$Traverse = {$: 9};
var $author$project$Feature$Tool$Unbox = F2(
	function (a, b) {
		return {$: 13, a: a, b: b};
	});
var $author$project$Box$isUnboxed = F3(
	function (topicId, boxId, model) {
		return _Utils_eq(
			A3($author$project$Box$displayMode, topicId, boxId, model),
			$elm$core$Maybe$Just(
				$author$project$ModelParts$BoxD(2)));
	});
var $author$project$Feature$IconAPI$pickerStyle = _List_fromArray(
	[
		A2($elm$html$Html$Attributes$style, 'position', 'absolute'),
		A2($elm$html$Html$Attributes$style, 'left', '35px'),
		A2($elm$html$Html$Attributes$style, 'width', '288px'),
		A2($elm$html$Html$Attributes$style, 'white-space', 'initial'),
		A2($elm$html$Html$Attributes$style, 'background-color', 'white'),
		A2($elm$html$Html$Attributes$style, 'border', '1px solid lightgray')
	]);
var $author$project$Model$Icon = function (a) {
	return {$: 9, a: a};
};
var $author$project$Feature$Icon$IconSelected = $elm$core$Basics$identity;
var $author$project$Feature$IconAPI$iconButtonStyle = _List_fromArray(
	[
		A2($elm$html$Html$Attributes$style, 'border', 'none'),
		A2($elm$html$Html$Attributes$style, 'margin', '8px'),
		A2($elm$html$Html$Attributes$style, 'background-color', 'transparent')
	]);
var $author$project$Feature$IconAPI$viewIconList = A2(
	$elm$core$List$map,
	function (_v0) {
		var iconName = _v0.a;
		var icon = _v0.b;
		return A2(
			$elm$html$Html$button,
			_Utils_ap(
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('tool'),
						$elm$html$Html$Attributes$title(iconName),
						$elm$html$Html$Events$onClick(
						$author$project$Model$Icon(
							$elm$core$Maybe$Just(iconName))),
						$author$project$Utils$onMouseDownStop($author$project$Model$NoOp)
					]),
				$author$project$Feature$IconAPI$iconButtonStyle),
			_List_fromArray(
				[
					A2($feathericons$elm_feather$FeatherIcons$toHtml, _List_Nil, icon)
				]));
	},
	$elm$core$Dict$toList($feathericons$elm_feather$FeatherIcons$icons));
var $author$project$Feature$IconAPI$viewPicker = function (model) {
	var _v0 = model.aa.cl;
	if (!_v0) {
		return _List_fromArray(
			[
				A2($elm$html$Html$div, $author$project$Feature$IconAPI$pickerStyle, $author$project$Feature$IconAPI$viewIconList)
			]);
	} else {
		return _List_Nil;
	}
};
var $elm$html$Html$span = _VirtualDom_node('span');
var $author$project$Feature$ToolAPI$viewSpacer = A2(
	$elm$html$Html$span,
	_List_fromArray(
		[
			A2($elm$html$Html$Attributes$style, 'display', 'inline-block'),
			A2($elm$html$Html$Attributes$style, 'width', '14px')
		]),
	_List_Nil);
var $author$project$Feature$Search$RelTopicClicked = function (a) {
	return {$: 7, a: a};
};
var $author$project$Feature$Search$RelTopicHovered = function (a) {
	return {$: 5, a: a};
};
var $author$project$Feature$Search$RelTopicUnhovered = function (a) {
	return {$: 6, a: a};
};
var $author$project$Model$Search = function (a) {
	return {$: 8, a: a};
};
var $author$project$Box$hasDeepItem = F3(
	function (boxId, itemId, model) {
		if (_Utils_eq(itemId, boxId)) {
			return true;
		} else {
			var _v0 = A2($author$project$Box$byId, boxId, model);
			if (!_v0.$) {
				var box = _v0.a;
				return A2(
					$elm$core$List$any,
					function (id) {
						return A3($author$project$Box$hasDeepItem, id, itemId, model);
					},
					$elm$core$Dict$keys(box.b7));
			} else {
				return false;
			}
		}
	});
var $author$project$Feature$SearchAPI$isItemDisabled = F2(
	function (topicId, model) {
		var _v0 = $author$project$Feature$SelAPI$revelationBoxId(model);
		if (!_v0.$) {
			var boxId = _v0.a;
			return A3($author$project$Box$hasDeepItem, topicId, boxId, model);
		} else {
			return false;
		}
	});
var $author$project$Feature$SearchAPI$isRelTopicHover = F2(
	function (relTopic, model) {
		var _v0 = model.C.cw;
		if ((_v0.$ === 1) && (!_v0.b.$)) {
			var relTopic_ = _v0.b.a;
			return _Utils_eq(relTopic_, relTopic);
		} else {
			return false;
		}
	});
var $author$project$Config$disabledColor = '#b0b0b0';
var $author$project$Config$hoverColor = '#d0d0d7';
var $author$project$Feature$SearchAPI$menuItemStyle = F2(
	function (isDisabled, isHover) {
		var _v0 = function () {
			if (isDisabled) {
				return _Utils_Tuple3($author$project$Config$disabledColor, 'unset', 'none');
			} else {
				return _Utils_Tuple3(
					'unset',
					isHover ? $author$project$Config$hoverColor : 'unset',
					'unset');
			}
		}();
		var color = _v0.a;
		var bgColor = _v0.b;
		var pointerEvents = _v0.c;
		return _List_fromArray(
			[
				A2($elm$html$Html$Attributes$style, 'display', 'flex'),
				A2($elm$html$Html$Attributes$style, 'align-items', 'center'),
				A2($elm$html$Html$Attributes$style, 'gap', '8px'),
				A2($elm$html$Html$Attributes$style, 'color', color),
				A2($elm$html$Html$Attributes$style, 'background-color', bgColor),
				A2($elm$html$Html$Attributes$style, 'padding', '0 8px'),
				A2($elm$html$Html$Attributes$style, 'pointer-events', pointerEvents)
			]);
	});
var $author$project$Feature$SearchAPI$menuStyle = _List_fromArray(
	[
		A2($elm$html$Html$Attributes$style, 'position', 'absolute'),
		A2($elm$html$Html$Attributes$style, 'width', '210px'),
		A2($elm$html$Html$Attributes$style, 'padding', '3px 0'),
		A2(
		$elm$html$Html$Attributes$style,
		'font-size',
		$elm$core$String$fromInt($author$project$Config$contentFontSize) + 'px'),
		A2($elm$html$Html$Attributes$style, 'line-height', '2'),
		A2($elm$html$Html$Attributes$style, 'background-color', 'white'),
		A2($elm$html$Html$Attributes$style, 'border', '1px solid lightgray')
	]);
var $elm$html$Html$Events$onMouseOut = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseout',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$html$Html$Events$onMouseOver = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseover',
		$elm$json$Json$Decode$succeed(msg));
};
var $author$project$Feature$SearchAPI$traversalResultStyle = _List_fromArray(
	[
		A2($elm$html$Html$Attributes$style, 'left', '65px')
	]);
var $author$project$Feature$Search$Fullscreen = function (a) {
	return {$: 8, a: a};
};
var $author$project$Feature$SearchAPI$fullscreenButtonStyle = _List_fromArray(
	[
		A2($elm$html$Html$Attributes$style, 'border', 'none'),
		A2($elm$html$Html$Attributes$style, 'background-color', 'transparent'),
		A2($elm$html$Html$Attributes$style, 'pointer-events', 'initial')
	]);
var $author$project$Utils$onClickStop = function (msg) {
	return A2($author$project$Utils$stopPropagation, 'click', msg);
};
var $author$project$Utils$onMouseOutStop = function (msg) {
	return A2($author$project$Utils$stopPropagation, 'mouseout', msg);
};
var $author$project$Utils$onMouseOverStop = function (msg) {
	return A2($author$project$Utils$stopPropagation, 'mouseover', msg);
};
var $author$project$Feature$SearchAPI$viewFullscreenButton = F2(
	function (id, model) {
		var isDisabled = _Utils_eq(model.a4, id);
		var _v0 = A2($author$project$Item$isBox, id, model);
		if (_v0) {
			return A2(
				$elm$html$Html$button,
				_Utils_ap(
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('tool'),
							$elm$html$Html$Attributes$title('Fullscreen'),
							$elm$html$Html$Attributes$disabled(isDisabled),
							$author$project$Utils$onClickStop(
							$author$project$Model$Search(
								$author$project$Feature$Search$Fullscreen(id))),
							$author$project$Utils$onMouseOverStop($author$project$Model$NoOp),
							$author$project$Utils$onMouseOutStop($author$project$Model$NoOp)
						]),
					$author$project$Feature$SearchAPI$fullscreenButtonStyle),
				_List_fromArray(
					[
						A3($author$project$Feature$IconAPI$view, 'maximize-2', 16, _List_Nil)
					]));
		} else {
			return $elm$html$Html$text('');
		}
	});
var $author$project$Feature$SearchAPI$viewItemText = function (topic) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				A2($elm$html$Html$Attributes$style, 'flex', 'auto'),
				A2($elm$html$Html$Attributes$style, 'overflow', 'hidden'),
				A2($elm$html$Html$Attributes$style, 'text-overflow', 'ellipsis'),
				A2($elm$html$Html$Attributes$style, 'white-space', 'nowrap')
			]),
		_List_fromArray(
			[
				$elm$html$Html$text(
				$author$project$Item$topicLabel(topic))
			]));
};
var $author$project$Feature$SearchAPI$viewTopicIcon = F2(
	function (topic, model) {
		return A4(
			$author$project$Feature$IconAPI$viewTopicIcon,
			topic.aK,
			$author$project$Config$topicIconSize,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'flex', 'none')
				]),
			model);
	});
var $author$project$Feature$SearchAPI$viewTraversalMenu = F2(
	function (relTopicIds, model) {
		return A2(
			$elm$html$Html$div,
			_Utils_ap(
				_List_fromArray(
					[
						$author$project$Utils$onMouseDownStop($author$project$Model$NoOp)
					]),
				_Utils_ap($author$project$Feature$SearchAPI$traversalResultStyle, $author$project$Feature$SearchAPI$menuStyle)),
			A2(
				$elm$core$List$map,
				function (relTopic) {
					var id = relTopic.a;
					var assocId = relTopic.b;
					var isHover = A2($author$project$Feature$SearchAPI$isRelTopicHover, relTopic, model);
					var isDisabled = A2($author$project$Feature$SearchAPI$isItemDisabled, id, model);
					var _v0 = A2($author$project$Item$topicById, id, model);
					if (!_v0.$) {
						var topic = _v0.a;
						return A2(
							$elm$html$Html$div,
							_Utils_ap(
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick(
										$author$project$Model$Search(
											$author$project$Feature$Search$RelTopicClicked(
												_Utils_Tuple2(id, assocId)))),
										$elm$html$Html$Events$onMouseOver(
										$author$project$Model$Search(
											$author$project$Feature$Search$RelTopicHovered(
												_Utils_Tuple2(id, assocId)))),
										$elm$html$Html$Events$onMouseOut(
										$author$project$Model$Search(
											$author$project$Feature$Search$RelTopicUnhovered(
												_Utils_Tuple2(id, assocId))))
									]),
								A2($author$project$Feature$SearchAPI$menuItemStyle, isDisabled, isHover)),
							_List_fromArray(
								[
									A2($author$project$Feature$SearchAPI$viewTopicIcon, topic, model),
									$author$project$Feature$SearchAPI$viewItemText(topic),
									A2($author$project$Feature$SearchAPI$viewFullscreenButton, id, model)
								]));
					} else {
						return $elm$html$Html$text('??');
					}
				},
				relTopicIds));
	});
var $author$project$Feature$SearchAPI$viewTraversalResult = function (model) {
	var _v0 = model.C.cw;
	if (_v0.$ === 1) {
		var relTopicIds = _v0.a;
		return (!$elm$core$List$isEmpty(relTopicIds)) ? _List_fromArray(
			[
				A2($author$project$Feature$SearchAPI$viewTraversalMenu, relTopicIds, model)
			]) : _List_Nil;
	} else {
		return _List_Nil;
	}
};
var $author$project$Feature$ToolAPI$viewToolbar = F3(
	function (itemId, boxId, model) {
		var topicTools = _List_fromArray(
			[
				A5(
				$author$project$Feature$ToolAPI$viewItemButton,
				'Edit',
				'edit-3',
				$author$project$Model$Tool($author$project$Feature$Tool$Edit),
				false,
				true),
				A5(
				$author$project$Feature$ToolAPI$viewItemButton,
				'Select Icon',
				'smile',
				$author$project$Model$Tool($author$project$Feature$Tool$Icon),
				false,
				true),
				A5(
				$author$project$Feature$ToolAPI$viewItemButton,
				'Traverse',
				'share-2',
				$author$project$Model$Tool($author$project$Feature$Tool$Traverse),
				false,
				true),
				A5(
				$author$project$Feature$ToolAPI$viewItemButton,
				'Delete',
				'trash',
				$author$project$Model$Tool($author$project$Feature$Tool$Delete),
				false,
				true),
				A5(
				$author$project$Feature$ToolAPI$viewItemButton,
				'Remove',
				'x',
				$author$project$Model$Tool($author$project$Feature$Tool$Remove),
				false,
				true)
			]);
		var boxTools = function () {
			if (A2($author$project$Item$isBox, itemId, model)) {
				var disabled = A2($author$project$Box$isEmpty, itemId, model) || A3($author$project$Box$isUnboxed, itemId, boxId, model);
				return _List_fromArray(
					[
						$author$project$Feature$ToolAPI$viewSpacer,
						A5(
						$author$project$Feature$ToolAPI$viewItemButton,
						'Fullscreen',
						'maximize-2',
						$author$project$Model$Tool(
							$author$project$Feature$Tool$Fullscreen(itemId)),
						false,
						true),
						A5(
						$author$project$Feature$ToolAPI$viewItemButton,
						'Unbox',
						'external-link',
						$author$project$Model$Tool(
							A2($author$project$Feature$Tool$Unbox, itemId, boxId)),
						disabled,
						true)
					]);
			} else {
				return _List_Nil;
			}
		}();
		return A2(
			$elm$html$Html$div,
			A3($author$project$Feature$ToolAPI$toolbarStyle, itemId, boxId, model),
			_Utils_ap(
				topicTools,
				_Utils_ap(
					boxTools,
					_Utils_ap(
						$author$project$Feature$IconAPI$viewPicker(model),
						$author$project$Feature$SearchAPI$viewTraversalResult(model)))));
	});
var $author$project$Feature$ToolAPI$viewItemTools = F3(
	function (itemId, boxPath, model) {
		var boxId = $author$project$Box$firstId(boxPath);
		var caret = function () {
			var _v0 = A3($author$project$Feature$MouseAPI$isHovered, itemId, boxId, model);
			if (_v0) {
				return A3($author$project$Feature$ToolAPI$viewCaret, itemId, boxId, model);
			} else {
				return _List_Nil;
			}
		}();
		var toolbar = A3($author$project$Feature$SelAPI$isSelectedPath, itemId, boxPath, model) ? (A3($author$project$Feature$TextAPI$isEdit, itemId, boxPath, model) ? (A2($author$project$Item$isBox, itemId, model) ? _List_Nil : _List_fromArray(
			[
				A3($author$project$Feature$ToolAPI$viewTextToolbar, itemId, boxId, model)
			])) : _List_fromArray(
			[
				A3($author$project$Feature$ToolAPI$viewToolbar, itemId, boxId, model)
			])) : _List_Nil;
		return _Utils_ap(toolbar, caret);
	});
var $author$project$Map$viewLimboAssoc = F2(
	function (boxId, model) {
		var _v0 = $author$project$Map$Model$limboState(model);
		if ((!_v0.$) && (!_v0.a.b.$)) {
			var _v1 = _v0.a;
			var topicId = _v1.a;
			var assocId = _v1.b.a;
			var limboBoxId = _v1.c;
			if (_Utils_eq(boxId, limboBoxId)) {
				if (A3($author$project$Box$hasItem, boxId, assocId, model)) {
					var _v2 = A2(
						$author$project$Utils$info,
						'viewLimboAssoc',
						_Utils_Tuple3(assocId, 'is in box', boxId));
					return _List_Nil;
				} else {
					var _v3 = A2(
						$author$project$Utils$info,
						'viewLimboAssoc',
						_Utils_Tuple3(assocId, 'not in box', boxId));
					var _v4 = A2($author$project$Item$assocById, assocId, model);
					if (!_v4.$) {
						var assoc = _v4.a;
						if (A3($author$project$Box$hasItem, boxId, topicId, model)) {
							return _List_fromArray(
								[
									A3($author$project$Map$viewAssoc, assoc, boxId, model)
								]);
						} else {
							var sourceTopicId = A3($author$project$Item$otherPlayerId, assocId, topicId, model);
							var _v5 = A3($author$project$Box$topicPos, sourceTopicId, boxId, model);
							if (!_v5.$) {
								var pos = _v5.a;
								return _List_fromArray(
									[
										A5(
										$author$project$Map$lineFunc,
										pos,
										A2($author$project$Box$initTopicPos, boxId, model),
										$elm$core$Maybe$Just(assoc),
										boxId,
										model)
									]);
							} else {
								return _List_Nil;
							}
						}
					} else {
						return _List_Nil;
					}
				}
			} else {
				return _List_Nil;
			}
		} else {
			return _List_Nil;
		}
	});
var $author$project$Map$boxInfo = F3(
	function (boxId, boxPath, model) {
		var _v15 = A2($author$project$Box$byIdOrLog, boxId, model);
		if (!_v15.$) {
			var box = _v15.a;
			return _Utils_Tuple3(
				A3($author$project$Map$viewItems, box, boxPath, model),
				box.aO,
				_Utils_Tuple2(
					{
						b_: $elm$core$String$fromInt(box.aO.a1 - box.aO.d4),
						cN: $elm$core$String$fromInt(box.aO.a0 - box.aO.d2)
					},
					_Utils_eq(model.a4, boxId) ? _List_Nil : A4($author$project$Map$nestedBoxStyle, boxId, box.aO, boxPath, model)));
		} else {
			return A3(
				$author$project$Utils$fail,
				'boxInfo',
				{a4: boxId, cY: boxPath},
				_Utils_Tuple3(
					_Utils_Tuple2(_List_Nil, _List_Nil),
					A4($author$project$ModelParts$Rectangle, 0, 0, 0, 0),
					_Utils_Tuple2(
						{b_: '0', cN: '0'},
						_List_Nil)));
		}
	});
var $author$project$Map$view = F3(
	function (boxId, boxPath, model) {
		var _v12 = A3($author$project$Map$boxInfo, boxId, boxPath, model);
		var _v13 = _v12.a;
		var topics = _v13.a;
		var assocs = _v13.b;
		var boxRect = _v12.b;
		var _v14 = _v12.c;
		var svgSize = _v14.a;
		var boxStyle = _v14.b;
		return A2(
			$elm$html$Html$div,
			boxStyle,
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					$author$project$Map$topicLayerStyle(boxRect),
					topics),
					A2(
					$elm$svg$Svg$svg,
					_Utils_ap(
						_List_fromArray(
							[
								$elm$svg$Svg$Attributes$width(svgSize.cN),
								$elm$svg$Svg$Attributes$height(svgSize.b_)
							]),
						$author$project$Map$svgStyle),
					_List_fromArray(
						[
							A2(
							$elm$svg$Svg$g,
							A3($author$project$Map$gAttr, boxId, boxRect, model),
							_Utils_ap(
								assocs,
								_Utils_ap(
									A2($author$project$Map$viewLimboAssoc, boxId, model),
									A2($author$project$Map$viewAssocDraft, boxId, model))))
						]))
				]));
	});
var $author$project$Map$viewItems = F3(
	function (box, boxPath, model) {
		var newPath = A2($elm$core$List$cons, box.aK, boxPath);
		var topics = A2(
			$elm$core$List$map,
			function (_v10) {
				var id = _v10.aK;
				var props = _v10.ac;
				var _v11 = _Utils_Tuple2(
					A2($author$project$Item$topicById, id, model),
					props);
				if ((!_v11.a.$) && (!_v11.b.$)) {
					var topic = _v11.a.a;
					var tProps = _v11.b.a;
					return A4($author$project$Map$viewTopic, topic, tProps, newPath, model);
				} else {
					return A3(
						$author$project$Utils$logError,
						'viewItems',
						'problem with topic ' + $elm$core$String$fromInt(id),
						$elm$html$Html$text(''));
				}
			},
			A2($author$project$Map$Model$topicsToRender, box, model));
		var assocs = A2(
			$elm$core$List$map,
			function (_v8) {
				var id = _v8.aK;
				var _v9 = A2($author$project$Item$assocById, id, model);
				if (!_v9.$) {
					var assoc = _v9.a;
					return A3($author$project$Map$viewAssoc, assoc, box.aK, model);
				} else {
					return A3(
						$author$project$Utils$logError,
						'viewItems',
						'problem with assoc ' + $elm$core$String$fromInt(id),
						$elm$html$Html$text(''));
				}
			},
			A2($author$project$Map$Model$assocsToRender, box, model));
		return _Utils_Tuple2(topics, assocs);
	});
var $author$project$Map$viewTopic = F4(
	function (topic, props, boxPath, model) {
		var render = function () {
			var _v2 = props.aI;
			if (!_v2.$) {
				if (!_v2.a) {
					var _v3 = _v2.a;
					return $author$project$Map$labelTopic;
				} else {
					var _v4 = _v2.a;
					return $author$project$Map$detailTopic;
				}
			} else {
				switch (_v2.a) {
					case 0:
						var _v5 = _v2.a;
						return $author$project$Map$blackBoxTopic;
					case 1:
						var _v6 = _v2.a;
						return $author$project$Map$whiteBoxTopic;
					default:
						var _v7 = _v2.a;
						return $author$project$Map$unboxedTopic;
				}
			}
		}();
		var boxId = $author$project$Box$firstId(boxPath);
		var _v1 = A4(render, topic, props, boxPath, model);
		var style = _v1.a;
		var children = _v1.b;
		return A2(
			$elm$html$Html$div,
			_Utils_ap(
				A2($author$project$Map$topicAttr, topic.aK, boxPath),
				_Utils_ap(
					A2($author$project$Feature$MouseAPI$hoverHandler, topic.aK, boxPath),
					_Utils_ap(
						A2($author$project$Feature$MouseAPI$mouseDownHandler, topic.aK, boxPath),
						_Utils_ap(
							A3($author$project$Map$topicStyle, topic.aK, boxId, model),
							style)))),
			_Utils_ap(
				children,
				A3($author$project$Feature$ToolAPI$viewItemTools, topic.aK, boxPath, model)));
	});
var $author$project$Map$whiteBoxTopic = F4(
	function (topic, props, boxPath, model) {
		var _v0 = A4($author$project$Map$labelTopic, topic, props, boxPath, model);
		var style = _v0.a;
		var children = _v0.b;
		return _Utils_Tuple2(
			style,
			_Utils_ap(
				children,
				_Utils_ap(
					A3($author$project$Map$viewItemCount, topic.aK, props, model),
					_List_fromArray(
						[
							A3($author$project$Map$view, topic.aK, boxPath, model)
						]))));
	});
var $author$project$AppEmbed$view = function (undo) {
	var model = undo.aw;
	var currentBoxId = model.a4;
	return A3($author$project$Map$view, currentBoxId, _List_Nil, model);
};
var $author$project$AppEmbed$main = $elm$browser$Browser$element(
	{dj: $author$project$AppEmbed$init, dU: $author$project$AppEmbed$subscriptions, dZ: $author$project$AppEmbed$updateWithEvidence, d_: $author$project$AppEmbed$view});
_Platform_export({'AppEmbed':{'init':$author$project$AppEmbed$main($elm$json$Json$Decode$value)(0)}});}(this));