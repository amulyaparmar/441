from dataclasses import dataclass
from datetime import datetime
from fastapi.encoders import jsonable_encoder
import main
from psycopg.errors import StringDataRightTruncation
from starlette.responses import JSONResponse
from typing import Optional
from uuid import UUID
from google.auth.transport import requests
from google.oauth2 import id_token
import hashlib, time
import os
from werkzeug.utils import secure_filename


@dataclass
class Chatt:
    username: str
    message: str
    audio: Optional[str] = None


@dataclass
class AuthChatt:
    chatterID: str
    message: str


@dataclass
class Chatter:
    clientID: str
    idToken: str


async def getchatts(request):
    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "SELECT username, message, id, time FROM chatts ORDER BY time DESC;"
                )
                return JSONResponse(jsonable_encoder(await cursor.fetchall()))
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"{type(err).__name__}: {str(err)}", status_code=500)


async def getaudio(request):
    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "SELECT username, message, id, time, audio FROM chatts ORDER BY time DESC;"
                )
                return JSONResponse(jsonable_encoder(await cursor.fetchall()))
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"{type(err).__name__}: {str(err)}", status_code=500)


async def postchatt(request):
    try:
        # loading json (not multipart/form-data)
        chatt = Chatt(**(await request.json()))
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"Unprocessable entity: {str(err)}", status_code=422)

    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "INSERT INTO chatts (username, message, id) VALUES "
                    "(%s, %s, gen_random_uuid());",
                    (chatt.username, chatt.message),
                )
        return JSONResponse({})
    except StringDataRightTruncation as err:
        print(f"Message too long: {str(err)}")
        return JSONResponse(f"Message too long: {str(err)}", status_code=400)
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"{type(err).__name__}: {str(err)}", status_code=500)


async def postaudio(request):
    try:
        # loading json (not multipart/form-data)
        chatt = Chatt(**(await request.json()))
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"Unprocessable entity: {str(err)}", status_code=422)

    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "INSERT INTO chatts (username, message, id, audio) VALUES "
                    "(%s, %s, gen_random_uuid(), %s);",
                    (chatt.username, chatt.message, chatt.audio),
                )
        return JSONResponse({})
    except StringDataRightTruncation as err:
        print(f"Message too long: {str(err)}")
        return JSONResponse(f"Message too long: {str(err)}", status_code=400)
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"{type(err).__name__}: {str(err)}", status_code=500)


async def adduser(request):
    try:
        chatter = Chatter(**(await request.json()))
    except Exception as err:
        print(f"{err=}")
        return JSONResponse("Unprocessable entity", status_code=422)

    now = time.time()  # secs since epoch (1/1/70, 00:00:00 UTC)

    try:
        # Collect user info from the Google idToken, verify_oauth2_token checks
        # the integrity of idToken and throws a "ValueError" if idToken or
        # clientID is corrupted or if user has been disconnected from Google
        # OAuth (requiring user to log back in to Google).
        # idToken has a lifetime of about 1 hour
        idinfo = id_token.verify_oauth2_token(
            chatter.idToken, requests.Request(), chatter.clientID
        )
    except ValueError as err:
        # Invalid or expired token
        print(f"Network Authentication Required: {str(err)}")
        return JSONResponse("Network Authentication Required", status_code=511)

    # get username
    try:
        username = idinfo["name"]
    except:
        username = "Profile NA"

    # Compute chatterID and add to database
    backendSecret = "ifyougiveamouse"  # TODO?? or server's private key
    nonce = str(now)
    hashable = chatter.idToken + backendSecret + nonce
    chatterID = hashlib.sha256(hashable.strip().encode("utf-8")).hexdigest()

    # Lifetime of chatterID is min of time to idToken expiration
    # (int()+1 is just ceil()) and target lifetime, which should
    # be less than idToken lifetime (~1 hour).
    lifetime = min(
        int(idinfo["exp"] - now) + 1, 60
    )  # secs, up to 1800, idToken lifetime

    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                # clean up db table of expired chatterIDs
                await cursor.execute(
                    "DELETE FROM chatters WHERE %s > expiration;", (now,)
                )

                # insert new chatterID
                # Ok for chatterID to expire about 1 sec beyond idToken expiration
                await cursor.execute(
                    "INSERT INTO chatters (chatterid, username, expiration) VALUES "
                    "(%s, %s, %s);",
                    (chatterID, username, now + lifetime),
                )
        # Return chatterID and its lifetime
        return JSONResponse({"chatterID": chatterID, "lifetime": lifetime})
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"{type(err).__name__}: {str(err)}", status_code=500)


async def postauth(request):
    try:
        # loading raw json (not form-encoded)
        chatt = AuthChatt(**(await request.json()))
    except Exception as err:
        print(f"{err=}")
        return JSONResponse("Unprocessable entity", status_code=422)

    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "SELECT username, expiration FROM chatters WHERE chatterID = %s;",
                    (chatt.chatterID,),
                )

                row = await cursor.fetchone()
                now = time.time()
                if row is None or now > row[1]:
                    # return an error if there is no chatter with that ID
                    return JSONResponse("Unauthorized", status_code=401)

                # else, insert into the chatts table
                await cursor.execute(
                    "INSERT INTO chatts (username, message, id) VALUES (%s, %s, gen_random_uuid());",
                    (row[0], chatt.message),
                )
        return JSONResponse({})
    except StringDataRightTruncation as err:
        print(f"Message too long: {str(err)}")
        return JSONResponse(f"Message too long", status_code=400)
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"{type(err).__name__}: {str(err)}", status_code=500)


MEDIA_ROOT = "/home/ubuntu/441/chatterd/media/"
MEDIA_MXSZ = 10485760  # 10 MB


async def saveFormFile(fields, media, url, username, ext):
    try:
        file = fields[media]
        if file.size > MEDIA_MXSZ:
            # but the whole file will still be received, just not saved
            raise BufferError
    except KeyError:
        return None  # not an error, media not sent
    except Exception:
        raise

    try:
        if not (filename := secure_filename(username)):
            raise NameError

        filename = f"{filename}-{str(time.time())}{ext}"
        filepath = os.path.join(MEDIA_ROOT, filename)

        # open(): https://docs.python.org/3/library/functions.html#open
        with open(filepath, "wb") as f:
            # write(): https://docs.python.org/3/tutorial/inputoutput.html#tut-files
            # form.UploadFile.read(): https://www.starlette.io/requests/#request-files
            f.write(await file.read(MEDIA_MXSZ))
            f.close()

        # url to string: https://stackoverflow.com/a/57514621/
        return f"{url}{filename}"
    except BaseException:
        raise


async def getaudio(request):
    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "SELECT username, message, id, time, audio FROM chatts ORDER BY time DESC;"
                )
                return JSONResponse(jsonable_encoder(await cursor.fetchall()))
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"{type(err).__name__}: {str(err)}", status_code=500)


async def postchatt(request):
    try:
        # loading json (not multipart/form-data)
        chatt = Chatt(**(await request.json()))
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"Unprocessable entity: {str(err)}", status_code=422)

    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "INSERT INTO chatts (username, message, id) VALUES "
                    "(%s, %s, gen_random_uuid());",
                    (chatt.username, chatt.message),
                )
        return JSONResponse({})
    except StringDataRightTruncation as err:
        print(f"Message too long: {str(err)}")
        return JSONResponse(f"Message too long: {str(err)}", status_code=400)
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"{type(err).__name__}: {str(err)}", status_code=500)


async def getimages(request):
    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "SELECT username, message, id, time, imageurl, videourl FROM chatts ORDER BY time DESC;"
                )
                return JSONResponse(jsonable_encoder(await cursor.fetchall()))
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"{type(err).__name__}: {str(err)}", status_code=500)


async def postimages(request):
    try:
        url = str(request.url_for("media", path="/"))
        # loading form-encoded data
        async with request.form() as fields:
            username = fields["username"]
            message = fields["message"]
            imageurl = await saveFormFile(fields, "image", url, username, ".jpeg")
            videourl = await saveFormFile(fields, "video", url, username, ".mp4")
    except BaseException as err:
        print(f"{err=}")
        return JSONResponse("Unprocessable entity", status_code=422)

    try:
        async with main.server.pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "INSERT INTO chatts (username, message, id, imageurl, videourl) VALUES "
                    "(%s, %s, gen_random_uuid(), %s, %s);",
                    (username, message, imageurl, videourl),
                )
        return JSONResponse({})
    except StringDataRightTruncation as err:
        print(f"Message too long: {str(err)}")
        return JSONResponse(f"Message too long", status_code=400)
    except Exception as err:
        print(f"{err=}")
        return JSONResponse(f"{type(err).__name__}: {str(err)}", status_code=500)
