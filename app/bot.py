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


@dp.message(Command("list"))
async def list_items(message: Message):
    await message.answer("Пока нет отслеживаемых товаров. Добавь первый через /add")


@dp.message(Command("upgrade"))
async def upgrade(message: Message):
    await message.answer(
        "Тарифы:\n\n"
        "Бесплатный — 3 товара, проверка раз в 6 часов\n"
        "Базовый — 99 руб/мес, 20 товаров, раз в час\n"
        "Про — 249 руб/мес, 100 товаров, раз в 30 мин\n"
        "Безлимит — 499 руб/мес, без ограничений\n\n"
        "Оплата будет доступна в ближайшее время."
    )


@dp.message(lambda m: m.text and (
    "wildberries.ru" in m.text or "ozon.ru" in m.text
))
async def handle_link(message: Message):
    url = message.text.strip()
    await message.answer("Получаю цену, подожди секунду...")

    from app.parser import get_wb_price
    result = await get_wb_price(url)

    if result:
        await message.answer(
            f"Товар: {result['title']}\n\n"
            f"Цена сейчас: {result['price']} руб.\n"
            f"Обычная цена: {result['original_price']} руб.\n\n"
            "Буду следить и сообщу если подешевеет!"
        )
    else:
        await message.answer(
            "Не удалось получить цену. Проверь ссылку — она должна вести "
            "на конкретный товар Wildberries."
        )


async def main():
    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())
