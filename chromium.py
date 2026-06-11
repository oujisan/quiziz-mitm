from playwright.sync_api import sync_playwright, Error as PlaywrightError

def run_isolated_browser():
    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=False,
            proxy={
                "server": "http://127.0.0.1:8080",
            },
            args=[
                "--ignore-certificate-errors",
                "--disable-quic"
            ]
        )
        
        context = browser.new_context(no_viewport=True)
        page = context.new_page()
        
        print("[*] Accessing the target via bundled Chromium...")
        page.goto("https://wayground.com")
        
        try:
            page.wait_for_timeout(9999999) 
        except PlaywrightError as e:
            if "Target page, context or browser has been closed" in str(e):
                print("\n[*] Browser closed by user. Terminating session gracefully.")
            else:
                raise e
        finally:
            if browser.is_connected():
                browser.close()

if __name__ == "__main__":
    run_isolated_browser()