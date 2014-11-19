/**
Simple Node.js server passing position data between peers using websockets, and serving flash policy file
*/
var WebSocketServer = require('ws').Server;
var socketPort = 8080;
var wss = new WebSocketServer({port: socketPort});

// event types
var ERROR = 0;
var INIT = 1;
var CONNECT = 2;
var MOVE = 3;

var VERSION = "0.0.0";

var latestClientId = 0;

var clients = [];
var positions = [];
var socketHolder = {};
wss.on('connection', function(ws) {
	latestClientId++;
	var index = clients.push(latestClientId) - 1;
	sendJson(CONNECT, latestClientId, {});
    ws.on('message', function(message) {
    	//console.log("got message:"+message);
    	var json = JSON.parse(message);
    	if(json.id === INIT){
			if(json.data.version != VERSION)
			{
				console.log("Version mismatch! Client:"+json.data.version+", Server:"+VERSION);
			}
			var obj = {name:"Table 1", clientId:latestClientId, clients:clients, positions:positions};
			socketHolder[latestClientId] = ws;
    		sendJson(INIT, latestClientId, obj, [latestClientId]);
    	} else if(json.id === MOVE) {
			positions[index] = {x:json.data.x, y:json.data.y};
			sendJson(MOVE, json.clientId, json.data);
		} else {
			console.log("--- Unknown message id:"+json.id+" from clientId:"+clientId);
    		sendJson(ERROR, json.clientId, {msg:"Unknown message id:"+json.id});
    	}
    });
	
	ws.on('close', function(connection) {
		var index = clients.splice(index, 1);
		var ws =  socketHolder[index];
		ws.terminate();
		delete socketHolder[index]
	});
});

// NOTE: Leaving recipients empty will result in message being sent to all clients apart from origin 
function sendJson(id /*string*/, clientId /*string*/, data /*Object*/, recipients /*optional Array*/) {
	var obj = {id:id, sender:clientId, data:data};
	var str = JSON.stringify(obj);
	var i = 0;
	if(recipients == null) {
		recipients = clients.slice();
		var index = recipients.indexOf(clientId);
		if (index > -1) {
			recipients.splice(index, 1);
		}
	}
	i = 0;
	while(i < recipients.length) {
		var ws =  socketHolder[recipients[i]];
		if(ws) {
			ws.send(str);
		}
		i++;
	}
}

console.log("--- Started WebSocket Server at port "+socketPort);

// flash policy file data
var policyXml = "<?xml version=\"1.0\"?>";
policyXml +=  "<!DOCTYPE cross-domain-policy SYSTEM \"http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd\">\n";
policyXml += "<cross-domain-policy>\n";
domains = ["*:*"];
domains.forEach(function (domain) {
	var parts = domain.split(':');
	//Write domain parts to policy data
	policyXml += "<allow-access-from domain=\"" + parts[0] + "\" to-ports=\"" + (parts[1] || '80') + "\"/>\n";
});
policyXml += "</cross-domain-policy>\n";

// Serve policy file on port 843. See http://www.adobe.com/devnet/flashplayer/articles/socket_policy_files.html
var policyPort = 843;
var net = require('net');
net.createServer(function (socket) {
	socket.write(policyXml);
    socket.end();
}).listen(policyPort);

console.log("--- Started Flash Policy Server at port "+policyPort);