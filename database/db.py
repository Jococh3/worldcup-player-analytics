import os

import mysql.connector
from mysql.connector import Error


def get_db_connection():
    """Return a new connection to the World Cup MySQL database."""

    try:
        return mysql.connector.connect(
            host=os.getenv("MYSQL_HOST", "127.0.0.1"),
            port=int(os.getenv("MYSQL_PORT", "3306")),
            user=os.getenv("MYSQL_USER", "root"),
            password=os.getenv("MYSQL_PASSWORD", ""),
            database=os.getenv("MYSQL_DATABASE", "worldcup"),
        )
    except Error as error:
        print(f"Database connection failed: {error}")
        return mysql.connector.connect(
    host="127.0.0.1",
    port=3306,
    user="root",
    password="",
    database="worldcup"
)