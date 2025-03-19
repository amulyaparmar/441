from contextlib import asynccontextmanager
import handlers
from psycopg_pool import AsyncConnectionPool
from starlette.applications import Starlette
from starlette.routing import Route
from starlette.routing import Route, Mount
from starlette.staticfiles import StaticFiles


@asynccontextmanager
async def lifespan(server):
    server.pool = AsyncConnectionPool(
        "dbname=chatterdb user=chatter password=chattchatt host=localhost", open=False
    )
    await server.pool.open()
    yield
    await server.pool.close()


# must include the trailing '/'
routes = [
    Route("/getchatts/", handlers.getchatts, methods=["GET"]),
    Route("/postchatt/", handlers.postchatt, methods=["POST"]),
    Route("/getaudio/", handlers.getaudio, methods=["GET"]),
    Route("/postaudio/", handlers.postaudio, methods=["POST"]),
    Route("/postauth/", handlers.postauth, methods=["POST"]),
    Route("/adduser/", handlers.adduser, methods=["POST"]),
    Route("/getimages/", handlers.getimages, methods=["GET"]),
    Route("/postimages/", handlers.postimages, methods=["POST"]),
    # static files: https://www.starlette.io/staticfiles
    Mount("/media/", app=StaticFiles(directory=handlers.MEDIA_ROOT), name="media"),
]

# must come after route definitions
server = Starlette(routes=routes, lifespan=lifespan)
