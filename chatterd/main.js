import { createSecureServer } from 'node:http2';
import express from 'express';
import http2Express from 'http2-express-bridge';
import morgan from 'morgan';
import postgres from 'postgres';
import { readFileSync } from 'node:fs';
import * as handlers from './handlers.js';
process.on('SIGTERM', () => {
    process.exit(0);
});
process.on('uncaughtException', (err) => {
    console.error(`Uncaught exception: ${err}\n` + `Stack trace: ${err.stack}`);
    process.exit(2);
});
export let chatterDB;
try {
    chatterDB = postgres('postgres://chatter:chattchatt@localhost/chatterdb');
    const app = http2Express(express)
        .use(morgan('common'))
        .use(express.json())
        .get('/getchatts/', handlers.getchatts)
        .post('/postchatt/', handlers.postchatt);
    const tls = {
        key: readFileSync("/home/ubuntu/441/chatterd.key"),
        cert: readFileSync("/home/ubuntu/441/chatterd.crt"),
        allowHTTP1: true
    };
    const server = createSecureServer(tls, app).listen({ host: '0.0.0.0', port: 443 }, () => {
        const address = server.address();
        console.log(`chatterd on https://${address.address}:${address.port}`);
    });
}
catch (error) {
    console.log(error);
    process.exit(1);
}
