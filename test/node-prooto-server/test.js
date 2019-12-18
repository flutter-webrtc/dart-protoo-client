'use strict';

process.env.DEBUG = 'protoo*';
const http = require('http');
const url = require('url');
const protooServer = require('protoo-server');

const CLIENT_WS_OPTIONS =
{
    retry:
    {
        retries: 0
    }
};

const httpServer = http.createServer();
const wsServer = new protooServer.WebSocketServer(httpServer);
const room = new protooServer.Room();

httpServer.listen(4442, '0.0.0.0', () => {


    wsServer.on('connectionrequest', (info, accept) => {
        console.log(`connectionrequest`);
        // The client indicates the peerId in the URL query.
        const u = url.parse(info.request.url, true);
        const peerId = u.query['peer-id'];
        const transport = accept();
        let peer;
        try {
            peer = room.createPeer(peerId, transport);

            peer.on('request', (request, accept, reject) => {
                console.log(`protoo "request" event [method:${request.method}, peer:${peer.id}]`);
                reject(501, 'fuck ~~~~');
            });

            peer.send('kicked', { reason: 'xxxxx', code: 486 }).then((data) => {
                console.log('kicked response: ' + data);
            }).catch((error) => {
                console.log('kicked error: ' + error);
            });
            console.log(`room.createPeer() succeeded [peerId:${peer.id}]`);
        }
        catch (error) {
            if (peerId === 'A' && room.hasPeer('A'))
                console.log('room.createPeer() failed for duplicated peer [peerId:A]');
            else
                console.log(`room.createPeer() failed: ${error}`);
        }
    });

});

