#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
    TensorFlow Lite Object detection with OpenCV.

    Copyright (c) 2022 Nobuo Tsukamoto

    This software is released under the MIT License.
    See the LICENSE file in the project root for more information.
"""

import argparse
import os
import sqlite3
from datetime import datetime

import cv2
import numpy as np
import tflite_runtime.interpreter as tflite
import yaml
from croniter import croniter

WINDOW_NAME = "TF-lite object detection (OpenCV)"


def insert_databese(databese_name, count, image):
    try:
        connection = sqlite3.connect(databese_name)
        cursor = connection.cursor()
        sqlite_query = "INSERT INTO person_count(count, image) VALUES (?, ?)"
        _, encode_image = cv2.imencode(".png", image)
        cursor.execute(sqlite_query, (count, memoryview(encode_image)))
        connection.commit()
        cursor.close()
    except sqlite3.Error as error:
        print("Failed to insert blob data into sqlite table", error)
    finally:
        if connection:
            connection.close()


def set_input_tensor(interpreter, image):
    """Sets the input tensor.
    Args:
        interpreter: Interpreter object.
        image: a function that takes a (width, height) tuple,
        and returns an RGB image resized to those dimensions.
    """
    tensor_index = interpreter.get_input_details()[0]["index"]
    input_tensor = interpreter.tensor(tensor_index)()[0]
    input_tensor[:, :] = image.copy()


def get_output_tensor(interpreter, index):
    """Returns the output tensor at the given index.
    Args:
        interpreter
        index
    Returns:
        tensor
    """
    output_details = interpreter.get_output_details()[index]
    tensor = np.squeeze(interpreter.get_tensor(output_details["index"]))
    return tensor


def draw_rectangle(image, box, color, thickness=3):
    """Draws a rectangle.
    Args:
        image: The image to draw on.
        box: A list of 4 elements (x1, y1, x2, y2).
        color: Rectangle color.
        thickness: Thickness of lines.
    """
    b = np.array(box).astype(int)
    cv2.rectangle(image, (b[0], b[1]), (b[2], b[3]), color, thickness)


def draw_caption(image, box, caption):
    """Draws a caption above the box in an image.
    Args:
        image: The image to draw on.
        box: A list of 4 elements (x1, y1, x2, y2).
        caption: String containing the text to draw.
    """
    b = np.array(box).astype(int)
    cv2.putText(
        image, caption, (b[0], b[1]), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 0), 2
    )
    cv2.putText(
        image, caption, (b[0], b[1]), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 1
    )


def get_output(interpreter, score_threshold):
    """Returns list of detected objects.

    Args:
        interpreter
        score_threshold

    Returns: bounding_box, class_id, score
    """
    # Get all output details
    boxes = get_output_tensor(interpreter, 0)
    class_ids = get_output_tensor(interpreter, 1)
    scores = get_output_tensor(interpreter, 2)
    count = int(get_output_tensor(interpreter, 3))

    results = []
    for i in range(count):
        if scores[i] >= score_threshold:
            result = {
                "bounding_box": boxes[i],
                "class_id": class_ids[i],
                "score": scores[i],
            }
            results.append(result)
    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", help="File path of config file.", required=True)
    args = parser.parse_args()

    # Load config.
    try:
        with open(args.config) as file:
            configs = yaml.safe_load(file)
            server_configs = configs["server"]
            detector_configs = configs["detector"]
            
            # server configs
            database_path = server_configs["db_path"]

            # camera configs
            camera_num = detector_configs["camera"]["num"]
            camera_width = detector_configs["camera"]["width"]
            camera_height = detector_configs["camera"]["height"]
            camera_fps = detector_configs["camera"]["fps"]

            # model configs
            model_path = detector_configs["model"]["model_path"]
            num_threads = detector_configs["model"]["num_threads"]
            count_labels = detector_configs["model"]["count_labels"]
            score_threshold = detector_configs["model"]["score_threshold"]

    except Exception as e:
        print("Exception occurred while loading YAML... : ", e)
        return

    # Initialize TF-Lite interpreter.
    interpreter = tflite.Interpreter(model_path=model_path, num_threads=num_threads)
    interpreter.allocate_tensors()
    _, height, width, channel = interpreter.get_input_details()[0]["shape"]
    print("Interpreter(height, width, channel): ", height, width, channel)

    # Video capture.
    cap = cv2.VideoCapture(camera_num)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, camera_width)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, camera_height)
    cap.set(cv2.CAP_PROP_FPS, camera_fps)

    dt_now = datetime.now()
    iter = croniter("*/1 * * * *", dt_now)
    exec_time = iter.get_next(datetime)
    print(exec_time)

    while cap.isOpened():
        _, frame = cap.read()

        dt_now = datetime.now()
        if dt_now > exec_time:
            im = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            resize_im = cv2.resize(im, (width, height))
            set_input_tensor(interpreter, resize_im)

            interpreter.invoke()
            objs = get_output(interpreter, score_threshold)

            num_results = 0
            # Display result.
            for obj in objs:
                class_id = int(obj["class_id"])
                if class_id in count_labels:
                    caption = "{0}({1:.2f})".format(num_results, obj["score"])

                    # Convert the bounding box figures from relative coordinates
                    # to absolute coordinates based on the original resolution
                    ymin, xmin, ymax, xmax = obj["bounding_box"]
                    xmin = int(xmin * camera_width)
                    xmax = int(xmax * camera_width)
                    ymin = int(ymin * camera_height)
                    ymax = int(ymax * camera_height)

                    # Draw a rectangle and caption.
                    draw_rectangle(frame, (xmin, ymin, xmax, ymax), (255, 0, 0))
                    draw_caption(frame, (xmin, ymin, xmax, ymax), caption)

                    num_results += 1

            insert_databese(database_path, num_results, frame)

            # cv2.imwrite(
            #     os.path.join(".", "debug", dt_now.strftime("%Y%m%d_%H%M%S") + ".png"),
            #     frame,
            # )

            exec_time = iter.get_next(datetime)
            print(exec_time, dt_now, num_results)

        # Display
        cv2.imshow(WINDOW_NAME, frame)
        if cv2.waitKey(10) & 0xFF == ord("q"):
            break


if __name__ == "__main__":
    main()
