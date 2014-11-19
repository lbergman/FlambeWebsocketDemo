package service ;
import flambe.math.Point;
import flambe.util.Signal1;
import flambe.util.Signal2;
import flambe.system.FlambeWebSocket;
import haxe.Json;
import model.vo.ErrorResponseDataVO;
import model.vo.InitRequestDataVO;
import model.vo.InitResponseDataVO;
import model.vo.MoveDataVO;
import model.vo.RequestVO;
import model.vo.ResponseVO;

/**
 * Demonstrate using realtime communication with the FlambeWebSocket class
 * 
 * @author mail@leobergman.se
 */
class SocketService
{
	
	#if flash
	static inline var PLATFORM:String = "flash";
	#else
	static inline var PLATFORM:String = "js";
	#end
	
	static inline var ERROR:Int = 0;
	static inline var INIT:Int = 1;
	static inline var CONNECT:Int = 2;
	static inline var MOVE:Int = 3;
	
	static inline var PROTOCOL_VERSION:String = "0.0.0";
	
	var _mainSocket:FlambeWebSocket;
	var _clientId:Int;

	var _initSignal:Signal1<InitResponseDataVO> = new Signal1<InitResponseDataVO>();
	public var onInit(get, never):Signal1<InitResponseDataVO>;
	public function get_onInit():Signal1<InitResponseDataVO > {
		return _initSignal;
	}
	
	var _connectSignal:Signal1<Int> = new Signal1<Int>();
	public var onConnect(get, never):Signal1<Int>;
	public function get_onConnect():Signal1<Int > {
		return _connectSignal;
	}
	
	var _moveSignal:Signal2<MoveDataVO, Int> = new Signal2<MoveDataVO, Int>();
	public var onMove(get, never):Signal2<MoveDataVO, Int>;
	public function get_onMove():Signal2<MoveDataVO, Int> {
		return _moveSignal;
	}
	
	/**
	 * Constructor
	 * @param	host
	 * @param	port
	 */
	public function new(host:String, port:Int)
	{
		_mainSocket = new FlambeWebSocket("ws://"+host+":" + Std.string(port));
		
		_mainSocket.onOpen.connect(function(msg:String) {
			var data:InitRequestDataVO = {
				platform:PLATFORM, 
				version:PROTOCOL_VERSION
			};
			var obj:RequestVO= {
				id:INIT,
				clientId:_clientId,
				data:data
			};
			
			_mainSocket.send(Json.stringify(obj));
		});
		
		_mainSocket.onMessage.connect(parseMessage);
		_mainSocket.connect();
	}
	
	/**
	 * Send position to peers
	 * @param	xPos
	 * @param	yPos
	 */
	public function sendPosition(xPos:Int, yPos:Int) 
	{
		var data:MoveDataVO = {
			x:xPos, 
			y:yPos
		};
		var obj:RequestVO = {
			id:MOVE,
			clientId:_clientId,
			data:data
		};
		_mainSocket.send(Json.stringify(obj));
	}
	
	/**
	 * Parse message from socket server
	 * @param	msg
	 */
	function parseMessage(msg:String) 
	{
		var obj:ResponseVO = Json.parse(msg);
		var id:Int = obj.id;
		switch(id)
		{
			case INIT:
				var initData:InitResponseDataVO = obj.data;
				_clientId = initData.clientId;
				_initSignal.emit(initData);
				trace("got init response, assigned clientId:" + _clientId);
			case CONNECT:
				_connectSignal.emit(obj.sender);
				trace("got new peer, clientId:" + _clientId);
			case MOVE:
				var moveData:MoveDataVO = obj.data;
				_moveSignal.emit(moveData, obj.sender);
			case ERROR:
				var errorData:ErrorResponseDataVO = obj.data;
				trace("got error, message:" + errorData.msg);
		}
		
	}
}