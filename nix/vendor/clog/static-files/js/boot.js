var ws=null;
var adr; var adrc;
var clog={};
var pingerid;
var retryid;
var s = document.location.search;
var tokens;
var r = /[?&]?([^=]+)=([^&]*)/g;

clog['body']=document.body;
clog['head']=document.head;
clog['documentElement']=document.documentElement;
clog['window']=window;
clog['navigator']=navigator;
clog['document']=window.document;
clog['location']=window.location;

if (typeof clog_debug == 'undefined') {
    clog_debug = false;
}

function Guard_empty_selector() {
    if (typeof jQuery == 'undefined' || !jQuery.find || !jQuery.find.error) {
        return;
    }

    var original = jQuery.find.error;
    jQuery.find.error = function (msg) {
        if (msg === "#") {
            console.warn("Ignoring empty jQuery selector \"#\"");
            return;
        }
        return original.call(this, msg);
    }
}

function Clog_empty_selector_payload(payload) {
    return typeof payload === 'string' &&
        /^\s*clog\[''\]\s*=\s*\$\('#'\)\.get\(0\)\s*;?\s*$/.test(payload);
}

function Clog_set_connection_state(state) {
    clog['connection_state'] = state;
    if (document.documentElement) {
        document.documentElement.setAttribute('data-clog-connection-state', state);
    }
    if (document.body) {
        document.body.setAttribute('data-clog-connection-state', state);
    }
}

function Clog_disconnected_message(detail) {
    if (detail && detail.length > 0 && detail !== 'user') {
        return 'Disconnected from HyperDoc: ' + detail + '. Clicks will not open new panes until you reload to reconnect.';
    }
    return 'Disconnected from HyperDoc. Clicks will not open new panes until you reload to reconnect.';
}

function Clog_show_disconnected_state(detail) {
    var message = Clog_disconnected_message(detail);
    clog['disconnected_message'] = message;
    Clog_set_connection_state('disconnected');
    if (typeof clog['html_on_close'] === 'string' && clog['html_on_close'] !== "") {
        return message;
    }
    if (!document.body) {
        return message;
    }
    var banner = document.getElementById('clog-disconnected-banner');
    if (!banner) {
        banner = document.createElement('div');
        banner.id = 'clog-disconnected-banner';
        banner.setAttribute('role', 'status');
        banner.setAttribute('aria-live', 'polite');
        banner.style.cssText = 'position:fixed;top:0;left:0;right:0;z-index:2147483647;padding:8px 12px;background:#7a0018;color:#fff;font:14px/1.4 sans-serif;box-shadow:0 1px 4px rgba(0,0,0,.25)';
        document.body.appendChild(banner);
    }
    banner.textContent = message;
    return message;
}

function Clog_clear_disconnected_state() {
    clog['disconnected_message'] = "";
    Clog_set_connection_state('connected');
    var banner = document.getElementById('clog-disconnected-banner');
    if (banner) {
        banner.remove();
    }
}

function Clog_send(payload, options) {
    if (ws != null && ws.readyState == 1) {
        ws.send(payload);
        return true;
    }
    var context = options && options.context ? ' (' + options.context + ')' : "";
    var message = Clog_show_disconnected_state(options && options.reason ? options.reason : null);
    console.warn(message + context);
    return false;
}

function Clog_make_disconnected_socket(detail) {
    return {
        readyState: 3,
        send: function (payload) {
            return Clog_send(payload, {
                reason: detail,
                context: 'disconnected-session'
            });
        },
        close: function () {
            return false;
        }
    };
}

function Ping_ws() {
    if (ws != null && ws.readyState == 1) {
        ws.send ('0');
    }
}

function Shutdown_ws(event) {
    if (ws != null) {
	ws.onerror = null;
	ws.onclose = null;
	ws.close ();
    }
    ws = Clog_make_disconnected_socket(event && event.reason ? event.reason : null);
    clearInterval (pingerid);
    Clog_show_disconnected_state(event && event.reason ? event.reason : null);
    if (typeof clog['html_on_close'] === 'string' && clog['html_on_close'] !== "") {
        $(document.body).html(clog['html_on_close']);
    }
}

function Setup_ws() {
    ws.onmessage = function (event) {
        try {
            if (Clog_empty_selector_payload(event.data)) {
                if (!window.__clog_ignored_empty_selector_payloads) {
                    window.__clog_ignored_empty_selector_payloads = 0;
                }
                window.__clog_ignored_empty_selector_payloads += 1;
                return;
            }
            if (clog_debug == true) {
		console.log ('eval data = ' + event.data);
            }
            eval (event.data);
        } catch (e) {
            const payload = (event && typeof event.data === 'string')
                ? event.data
                : String(event && event.data);
            if (!window.__clog_eval_seq) window.__clog_eval_seq = 0;
            window.__clog_eval_seq += 1;
            const seq = window.__clog_eval_seq;
            window.__clog_last_eval_seq = seq;
            window.__clog_last_eval_payload = payload;
            console.error("[CLOG] eval error seq=", seq, e);
            console.error("[CLOG] eval error payload(first 800 chars)=", payload.slice(0, 800));
        }
    }

    var rc = function (event) {
	console.log (event);
	clearInterval (retryid);
	ws = null;
	ws = new WebSocket (adr  + '?r=' + clog['connection_id']);
        ws.onopen = function (event) {
            console.log ('reconnect successful');
            Clog_clear_disconnected_state();
            Setup_ws();
        }
        ws.onclose = function (event) {
            console.log ('reconnect failure');
	    console.log (Date.now());
	    retryid = setInterval(function () {rc("Failed reconnect - trying again")}, 500);
        }
    }

    ws.onerror = function (event) {
        console.log ('onerror: reconnect');
	rc("onerror - trying reconnect")
    }

    ws.onclose = function (event) {
        if (event.code && event.code === 1000) {
            console.log("WebSocket connection got normal close from server. Don't reconnect.");
            Shutdown_ws(event);
        } else {
	    rc("onclose - trying reconnnect");
        }
    }
}

function Open_ws() {
    if (location.protocol == 'https:') {
	adr = 'wss://' + location.hostname;
    } else {
	adr = 'ws://' + location.hostname;
    }

    if (location.port != '') { adr = adr + ':' + location.port; }
    adr = adr + '/clog';

    if (clog['connection_id']) {
      adrc = adr  + '?r=' + clog['connection_id'];
    } else { adrc = adr }

    try {
	console.log ('connecting to ' + adrc);
	ws = new WebSocket (adrc);
    } catch (e) {
	console.log ('trying again, connecting to ' + adrc);
	ws = new WebSocket (adrc);
    }

    Clog_set_connection_state('connecting');
    if (ws != null) {
	ws.onopen = function (event) {
            console.log ('connection successful');
            Clog_clear_disconnected_state();
            Setup_ws();
	}
	pingerid = setInterval (function () {Ping_ws ();}, 10000);
    } else {
	document.writeln ('If you are seeing this your browser or your connection to the internet is blocking websockets.');
    }
}

$( document ).ready(function() {
    Guard_empty_selector();
    if (ws == null) { Open_ws(); }
});
