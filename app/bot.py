import asyncio
import os
from aiogram import Bot, Dispatcher
from aiogram.types import Message
from aiogram.filters import Command

bot = Bot(token=os.getenv("BOT_TOKEN"))
dp = Dispatcher()

@dp.message(Command("start"))
async def start(message: Message):
    await message.answer(
        "Привет! Я слежу за ценами на Wildberries и Ozon.\n\n"
        "Отправь мне ссылку на товар — и я сообщу когда цена снизится.\n\n"
        "/add — добавить товар\n"
        "/list — мои товары\n"
        "/upgrade — тарифы"
    )

@dp.message(Command("add"))
async def add(message: Message):
    await message.answer(
        "Отправь ссылку на товар с Wildberries или Ozon.\n\n"
        "Пример:\n"
        "https://www.wildberries.ru/catalog/12345678/detail.aspx"
    )

@dp.message(lambda m: m.text and ("wildberries.ru" in m.text or "ozon.ru" in m.text))
async def handle_link(message: Message):
    url = message.text.strip()
    await message.answer(
        f"Ссылка получена, начинаю следить за ценой...\n\n"
        f"Товар: {url}\n\n"
        "Как только цена изменится — сразу сообщу!"
    )

@dp.message(Command("list"))
async def list_items(message: Me
