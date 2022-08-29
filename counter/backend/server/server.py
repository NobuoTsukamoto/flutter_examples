#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""

    Copyright (c) 2022 Nobuo Tsukamoto

    This software is released under the MIT License.
    See the LICENSE file in the project root for more information.
"""

from db import initialize_databese, get_history
from flask import Flask
import json

app = Flask(__name__)
app.config.from_pyfile("config.cfg")

initialize_databese(app.config["DB_PATH"])


@app.route("/history/", methods=["GET"])
def history():
    history = get_history(app.config["DB_PATH"])
    results = []
    for record in history:
        results.append({"date": record[2], "count": record[1]})

    return json.dumps(results)


def main():
    app.run(host="127.0.0.1", debug=True)


if __name__ == "__main__":
    main()
