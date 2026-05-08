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

@dp.message(Command("help"))
async def help_cmd(message: Message):
    await message.answer("Отправь ссылку на товар с WB или Ozon и я начну следить за ценой.")

async def main():
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
