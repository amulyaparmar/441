import { chatterDB } from './main.js'
import { createHash, randomUUID } from 'crypto'
import type { PostgresError } from 'postgres'
import type { Request, Response } from 'express'

interface Chatt {
    username: string
    message: string
}

export async function getchatts(req: Request, res: Response) {
    try {
        const chatts = await chatterDB`SELECT username, message, id, time FROM chatts ORDER BY time DESC`.values()
        res.json(chatts)
    } catch (error) {
        res.status(500).json(`${error as PostgresError}`)
    }
}

export async function postchatt(req: Request, res: Response) {
    let chatt: Chatt
    try {
        chatt = req.body
    } catch (error) {
        res.status(422).json(error)
        return
    }
    try {
        await chatterDB`INSERT INTO chatts (username, message, id) VALUES (${chatt.username}, ${chatt.message}, ${randomUUID()})`
        res.json({})
    } catch (error) {
        res.status(400).json(`${error as PostgresError}`)
    }
}
