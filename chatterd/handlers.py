from dataclasses import dataclass
from datetime import datetime
from fastapi.encoders import jsonable_encoder
import main
from psycopg.errors import StringDataRightTruncation
from starlette.responses import JSONResponse
from typing import Optional
from uuid import UUID

@dataclass
class Chatt:
    username: str
    message: str

async def getchatts(request):
    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute('SELECT username, message, id, time FROM chatts ORDER BY time DESC;')
                return JSONResponse(jsonable_encoder(await cursor.fetchall()))
    except Exception as err:
        print(f'{err=}')
        return JSONResponse(f'{type(err).__name__}: {str(err)}', status_code = 500)

async def postchatt(request):
    try:
        # loading json (not multipart/form-data)
        chatt = Chatt(**(await request.json()))
    except Exception as err:
        print(f'{err=}')
        return JSONResponse(f'Unprocessable entity: {str(err)}', status_code=422)

    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute('INSERT INTO chatts (username, message, id) VALUES '
                    '(%s, %s, gen_random_uuid());', (chatt.username, chatt.message))
        return JSONResponse({})
    except StringDataRightTruncation as err:
        print(f'Message too long: {str(err)}')
        return JSONResponse(f'Message too long: {str(err)}', status_code = 400)
    except Exception as err:
        print(f'{err=}')
        return JSONResponse(f'{type(err).__name__}: {str(err)}', status_code = 500)

        
