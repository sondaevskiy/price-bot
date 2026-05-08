import httpx
import re

async def get_wb_price(url: str) -> dict | None:
    article = extract_wb_article(url)
    if not article:
        return None

    api_url = f"https://card.wb.ru/cards/v1/detail?appType=1&curr=rub&dest=-1257786&nm={article}"

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(api_url, headers=headers, timeout=10)
            data = response.json()

            product = data["data"]["products"][0]
            title = product["name"]
            price = product["salePriceU"] // 100
            original_price = product["priceU"] // 100

            return {
                "title": title,
                "price": price,
                "original_price": original_price,
                "article": article
            }
        except Exception:
            return None


def extract_wb_article(url: str) -> str | None:
    match = re.search(r"/catalog/(\d+)/", url)
    return match.group(1) if match else None
