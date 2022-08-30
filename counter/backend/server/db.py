#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""

    Copyright (c) 2022 Nobuo Tsukamoto

    This software is released under the MIT License.
    See the LICENSE file in the project root for more information.
"""

import os
import sqlite3


def initialize_databese(db_name):
    db_dir = os.path.dirname(db_name)
    if not os.path.isdir(db_dir):
        os.makedirs(db_dir)

    conn = sqlite3.connect(db_name)
    cur = conn.cursor()
    cur.execute(
        "CREATE TABLE IF NOT EXISTS "
        "person_count(id INTEGER PRIMARY KEY, "
        "count INTEGER NOT NULL, "
        "image BLOB, "
        "created TIMESTAMP DEFAULT (datetime(CURRENT_TIMESTAMP,'localtime')))"
    )
    conn.commit()
    conn.close


def get_history(db_name):
    results = []
    try:
        connection = sqlite3.connect(db_name)
        cursor = connection.cursor()
        cursor.execute(
            "SELECT id, count, created from person_count;"
        )
        results = cursor.fetchall()
        connection.close()

    except sqlite3.Error as error:
        print("Failed to insert blob data into sqlite table", error)

    finally:
        if connection:
            connection.close()

    return results


def get_last_image(db_name):
    try:
        connection = sqlite3.connect(db_name)
        connection.row_factory = sqlite3.Row
        connection.text_factory = bytes
        cursor = connection.cursor()
        cursor.execute(
            "SELECT image FROM person_count ORDER BY id DESC LIMIT 1;"
        )
        results = cursor.fetchall()
        connection.close
        im = results[0]["image"]

    except sqlite3.Error as error:
        print("Failed to insert blob data into sqlite table", error)

    finally:
        if connection:
            connection.close()

    return im 


