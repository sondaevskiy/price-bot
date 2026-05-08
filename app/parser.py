import httpx
import re
import traceback


def extract_wb_article(url: str) -> str | None:
    match = re.search(r"/catalog/(\d+)/", url)
    return match.group(1) if match else None


async def get_wb_price(url: str) -> dict | None:
    article = extract_wb_article(url)
    print(f"Article extracted: {article}")
    if not article:
        return None

    api_url = (
        f"https://card.wb.ru/cards/v1/detail"
        f"?appType=1&curr=rub&dest=-1257786&nm={article}"
    )

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) "
                      "Chrome/120.0.0.0 Safari/537.36",
        "Accept": "*/*",
        "Accept-Language": "ru-RU,ru;q=0.9",
        "Origin": "https://www.wildberries.ru",
        "Referer": "https://www.wildberries.ru/",
    }

    async with httpx.AsyncClient(follow_redirects=True) as client:
        try:
            response = await client.get(api_url, headers=headers, timeout=15)
            print(f"Status: {response.status_code}")
            print(f"Body: {response.text[:500]}")

            data = response.json()

            products = data.get("data", {}).get("products", [])
            print(f"Products found: {len(products)}")

            if not products:
                return None

            product = products[0]
            title = product.get("name", "Без названия")

            sizes = product.get("sizes", [])
            price = None
            for size in sizes:
                price_data = size.get("price", {})
                if price_data.get("total"):
                    price = price_data["total"] // 100
                    break

            if not price:
                price = product.get("salePriceU", 0) // 100

            original_price = product.get("priceU", 0) // 100

            print(f"Title: {title}, Price: {price}, Original: {original_price}")

            return {
                "title": title,
                "price": price,
                "original_price": original_price,
                "article": article
            }

        except Exception as e:
            print(f"Parser error: {e}")
            traceback.print_exc()
            return None
