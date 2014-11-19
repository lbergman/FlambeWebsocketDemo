import flambe.asset.AssetPack;
import flambe.asset.Manifest;
import flambe.display.EmitterMold;
import flambe.display.EmitterSprite;
import flambe.input.PointerEvent;
import flambe.input.TouchPoint;
import flambe.display.FillSprite;
import flambe.display.ImageSprite;
import flambe.display.Sprite;
import flambe.Entity;
import flambe.math.Point;
import flambe.script.CallFunction;
import flambe.script.Delay;
import flambe.script.Script;
import flambe.script.Sequence;
import flambe.System;
import model.vo.InitResponseDataVO;
import model.vo.MoveDataVO;
import service.SocketService;

/**
 * Sample application for testing websockets with Flambe.
 * 
 * @author mail@leobergman.se
 */
class Main
{
	static var _service:SocketService;
	static var _emitters:Array<EmitterSprite> = [];
	static var _ownEmitter:EmitterSprite;
	static var _bootPack:AssetPack;
	
	/**
	 * Static entry
	 */
    static function main()
    {
        System.init();

        var loader = System.loadAssetPack(Manifest.fromAssets("bootstrap"));
        loader.success.connect(onLoadBootstrapSuccess);
    }

	/**
	 * Loading complete, start application
	 * @param	pack
	 */
    static function onLoadBootstrapSuccess(pack:AssetPack)
    {
		_bootPack = pack;
		
		setupWebsocket("localhost", 8080);
		
		var bg = new FillSprite(0x000000, System.stage.width, System.stage.height);
        System.root.addChild(new Entity().add(bg));
		bg.pointerMove.connect(onPointerMove);
    }
	
	/**
	 * Start socket service and add listeners
	 * @param	host
	 * @param	port
	 */
	static function setupWebsocket(host:String, port:Int) 
	{
		_service = new SocketService(host, port);
		_service.onInit.connect(onInitMessage);
		_service.onConnect.connect(onConnectMessage);
		_service.onMove.connect(onMoveMessage);
	}

	/**
	 * Add an emmitter
	 * @param	clientId - the clientId of the peer controlling the emitter position (used to determine EmitterMold to use)
	 * @return - The added emitter
	 */
	static function addEmitter(clientId:Int):EmitterSprite 
	{
		var index = (clientId % 4)+1;
		var mold = new EmitterMold(_bootPack, "particle" + index);
		var emitter:EmitterSprite = mold.createEmitter();
		_emitters[clientId] = emitter;
		System.root.addChild(new Entity().add(emitter));
		return emitter;
	}
	
	/**
	 * Handle pointer movement
	 * @param	event
	 */
	static function onPointerMove(event:PointerEvent)
	{
		if (_ownEmitter == null) return;
		_ownEmitter.emitX._ = event.viewX;
		_ownEmitter.emitY._ = event.viewY;
		_service.sendPosition(Std.int(event.viewX), Std.int(event.viewY));
	}
	
	/**
	 * Handle init event returned after we connect with websocket
	 * @param	vo
	 */
	static function onInitMessage(vo:InitResponseDataVO)
	{
		// create and position emitters for already connected peers
		var n = vo.clients.length;
		for (i in 0...n)
		{
			var client = vo.clients[i];
			if (client != vo.clientId)
			{
				var em:EmitterSprite = addEmitter(client);
				var pos = vo.positions[i];
				if (pos != null)
				{
					em.emitX._ = pos.x;
					em.emitY._ = pos.y;
				}
			}
		}
		// create own emitter
		_ownEmitter = addEmitter(vo.clientId);
	}
	
	/**
	 * Handle when new peers connect
	 * @param	clientId
	 */
	static function onConnectMessage(clientId:Int)
	{
		addEmitter(clientId);
	}

	/**
	 * Handle movement from peer
	 * @param	moveData
	 * @param	clientId
	 */	
	static function onMoveMessage(moveData:MoveDataVO, clientId:Int)
	{
		var emitter:EmitterSprite = _emitters[clientId];
		if (emitter != null)
		{
			emitter.emitX._ = moveData.x;
			emitter.emitY._ = moveData.y;
		}
	}
}
