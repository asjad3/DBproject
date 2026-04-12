import psycopg2
import psycopg2.pool
from dotenv import load_dotenv
import os

load_dotenv()

pool = psycopg2.pool.SimpleConnectionPool(
    minconn=1,
    maxconn=10,
    host=os.getenv("PG_HOST", "localhost"),
    port=os.getenv("PG_PORT", "5432"),
    user=os.getenv("PG_USER", "postgres"),
    password=os.getenv("PG_PASSWORD", ""),
    database=os.getenv("PG_DATABASE", "disasterlink"),
)


def get_connection():
    return pool.getconn()


def release_connection(conn):
    pool.putconn(conn)
