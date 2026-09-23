"""Учебная функция для курса Terraform.

Точка входа — index.handler: файл index.py, функция handler.
Функция возвращает JSON, поэтому её удобно проверять командой curl
и прямым вызовом через командную строку:

    yc serverless function invoke <function_id>
"""

import json
import os
from datetime import datetime, timezone


def handler(event, context):
    """Обработчик запроса.

    event — то, что пришло от шлюза API или прямого вызова:
    путь, метод, заголовки, тело.

    ВАЖНО: при прямом вызове через командную строку event приходит
    пустым (None). Если этого не учесть, функция падает с ошибкой
    «'NoneType' object has no attribute 'get'» — мы получили её
    на живом стенде. Поэтому первым делом приводим событие к словарю.

    context — служебная информация: идентификатор запроса,
    оставшееся время работы и так далее.
    """
    event = event or {}

    # Заголовки запроса приходят в разном регистре, поэтому приводим
    # их к нижнему — иначе поиск нужного заголовка становится лотереей.
    raw_headers = event.get("headers") or {}
    headers = {str(k).lower(): v for k, v in raw_headers.items()}

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json; charset=utf-8"},
        "isBase64Encoded": False,
        "body": json.dumps(
            {
                "message": "Функция создана Terraform",
                "course": os.environ.get("COURSE", "неизвестно"),
                "lesson": os.environ.get("LESSON", "неизвестно"),
                "request_id": getattr(context, "request_id", "нет"),
                "time": datetime.now(timezone.utc).isoformat(),
                "user_agent": headers.get("user-agent", "не передан"),
                "event_keys": sorted(event.keys()),
            },
            ensure_ascii=False,
        ),
    }
