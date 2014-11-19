package flambe.system;

import flambe.util.Signal1;
import haxe.Json;

#if html
import js.html.*;
#else
import flash.utils.ByteArray;
import flash.system.Security;
import com.worlize.websocket.WebSocket;
import com.worlize.websocket.WebSocketErrorEvent;
import com.worlize.websocket.WebSocketEvent;
import com.worlize.websocket.WebSocketMessage;
#end

/**
 * UTF8 Text based WebSocket class for Flambe
 */
class FlambeWebSocket 
{
	private var _webSocketURI:String = "";
	private var _websocket:WebSocket;
	private var _clientId:Int = 0;
	private var _openSignal:Signal1<String> = new Signal1<String>();
	private var _closedSignal:Signal1<String> = new Signal1<String>();
	private var _messgeSignal:Signal1<String> = new Signal1<String>();
	private var _errorSignal:Signal1<String> = new Signal1<String>();
	
	public var onOpen(get, never):Signal1<String>;
	private inline function get_onOpen():Signal1<String> {
		return _openSignal;
	}
	
	public var onClosed(get, never):Signal1<String>;
	private inline function get_onClosed():Signal1<String> {
		return _closedSignal;
	}
	
	public var onMessage(get, never):Signal1<String>;
	private inline function get_onMessage():Signal1<String> {
		return _messgeSignal;
	}
	
	public var onError(get, never):Signal1<String>;
	private inline function get_onError():Signal1<String> {
		return _errorSignal;
	}
	
	/**
	 * Constructor
	 * @param	socketURI Socket URI to connect to; ensure server flash policy file for relevant connections
	 */
	public function new(socketURI:String) {
		_webSocketURI = socketURI;
	}
	
	public function connect()
	{
#if html
		_websocket = new WebSocket(_webSocketURI);
		_websocket.onopen = handleJSOpen;
		_websocket.onclose = handleJSClose;
		_websocket.onmessage = cast handleJSMessage;
		_websocket.onerror = cast handleJSError;
#elseif flash
		//Security.loadPolicyFile(_webSocketURI.split(":")[0]+":5000");
		_websocket = new WebSocket(_webSocketURI, "*");
		_websocket.addEventListener(WebSocketEvent.OPEN, handleFlashOpen);
		_websocket.addEventListener(WebSocketEvent.CLOSED, handleFlashClosed);
		_websocket.addEventListener(WebSocketEvent.MESSAGE, handleFlashMessage);
		_websocket.addEventListener(WebSocketErrorEvent.CONNECTION_FAIL, handleFlashConnFail);
		_websocket.connect();
#end
	}

#if flash
	private function handleFlashOpen(event:WebSocketEvent) {
		_openSignal.emit("Open");
	}

	private function handleFlashClosed(event:WebSocketEvent) {
		_closedSignal.emit("Closed");
	}

	private function handleFlashMessage(event:WebSocketEvent) {
		if (event.message.type == WebSocketMessage.TYPE_UTF8) {
			_messgeSignal.emit(event.message.utf8Data);
		}
	}
	
	private function handleFlashConnFail(event:WebSocketErrorEvent) {
		_errorSignal.emit("Error: " + event.text);
	}
	
	public function send(message:String)
	{
		_websocket.sendUTF(message);
	}
	
#elseif html
	private function handleJSOpen(evt)
	{
		_openSignal.emit("Open");
	}

	private function handleJSClose(evt)
	{
		_closedSignal.emit("Closed");
	}

	private function handleJSMessage(evt:MessageEvent)
	{
		_messgeSignal.emit(evt.data);
	}

	private function handleJSError(evt:MessageEvent)
	{
		_errorSignal.emit("Error: " + evt.data);
	}

	public function send(message:String)
	{
		_websocket.send(message);
	}
#end
}