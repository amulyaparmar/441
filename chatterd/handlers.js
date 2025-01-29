import { chatterDB } from './main.js';
import { createHash, randomUUID } from 'crypto';
export async function getchatts(req, res) {
    try {
        const chatts = await chatterDB `SELECT username, message, id, time FROM chatts ORDER BY time DESC`.values();
        res.json(chatts);
    }
    catch (error) {
        res.status(500).json(`${error}`);
    }
}
export async function postchatt(req, res) {
    let chatt;
    try {
        chatt = req.body;
    }
    catch (error) {
        res.status(422).json(error);
        return;
    }
    try {
        await chatterDB `INSERT INTO chatts (username, message, id) VALUES (${chatt.username}, ${chatt.message}, ${randomUUID()})`;
        res.json({});
    }
    catch (error) {
        res.status(400).json(`${error}`);
    }
}
