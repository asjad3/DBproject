import psycopg2
import psycopg2.pool
from dotenv import load_dotenv
import os
import atexit

load_dotenv()

_pool = None


def _create_pool():
    return psycopg2.pool.SimpleConnectionPool(
        minconn=1,
        maxconn=10,
        host=os.getenv("PG_HOST", "localhost"),
        port=os.getenv("PG_PORT", "5432"),
        user=os.getenv("PG_USER", "postgres"),
        password=os.getenv("PG_PASSWORD", ""),
        database=os.getenv("PG_DATABASE", "disasterlink"),
        sslmode=os.getenv("PG_SSLMODE", "prefer"),
    )


def get_pool():
    global _pool
    if _pool is None:
        _pool = _create_pool()
        atexit.register(close_pool)
    return _pool


def get_connection():
    return get_pool().getconn()


def release_connection(conn):
    get_pool().putconn(conn)


def close_pool():
    global _pool
    if _pool is not None:
        _pool.closeall()
        _pool = None


from contextlib import contextmanager

@contextmanager
def get_cursor():
    """Context manager that yields a cursor and handles commit/rollback/close."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        yield cur
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        release_connection(conn)
