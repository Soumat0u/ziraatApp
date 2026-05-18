import time
from django.core.management.base import BaseCommand
from api.models import Medicine, Category
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support.ui import Select

class Command(BaseCommand):
    help = "Bakanlık Ruhsat sayfasındaki tüm ticari ilaç bilgilerini yüksek hızda çeker."

    def handle(self, *args, **options):
        self.stdout.write("Turbo tarama başlatılıyor (Daha dayanıklı mod)...")
        
        chrome_options = webdriver.ChromeOptions()
        chrome_options.add_argument('--headless')
        # Pencere boyutunu büyük tutmak 'not interactable' hatasını engeller
        chrome_options.add_argument('--window-size=1920,1080') 
        chrome_options.add_argument('--disable-gpu')
        
        prefs = {"profile.managed_default_content_settings.images": 2}
        chrome_options.add_experimental_option("prefs", prefs)

        driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)
        wait = WebDriverWait(driver, 15)
        
        try:
            driver.get("https://bku.tarimorman.gov.tr/BKURuhsat/Index")
            
            # 1. Kayıt sayısını 100 yapma (JS ile zorla seçtiriyoruz)
            try:
                length_select = wait.until(EC.presence_of_element_located((By.NAME, "tablo_length")))
                # Elementin üzerine scroll yap (Headless modda hayat kurtarır)
                driver.execute_script("arguments[0].scrollIntoView();", length_select)
                time.sleep(1)
                
                select = Select(length_select)
                select.select_by_value("100")
                self.stdout.write(self.style.SUCCESS("Sayfa başına 100 kayıt ayarlandı."))
                time.sleep(2)
            except Exception as e:
                self.stdout.write(self.style.WARNING(f"Dropdown seçilemedi, varsayılanla devam ediliyor..."))

            category, _ = Category.objects.get_or_create(name="Ruhsatlı Ürünler")
            page_count = 1
            
            while True:
                start_time = time.time()
                
                # Tablonun yüklenmesini bekle
                wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#tablo tbody tr")))
                rows = driver.find_elements(By.CSS_SELECTOR, "#tablo tbody tr")

                product_list = []
                for row in rows:
                    try:
                        cols = row.find_elements(By.TAG_NAME, "td")
                        if len(cols) >= 7:
                            product_list.append(Medicine(
                                name=cols[0].text.strip(), # Ticari İsim (İlaç)
                                active_ingredient=cols[2].text.strip(), # Aktif Madde
                                formulation=cols[6].text.strip(), # Formülasyon
                                category=category
                            ))
                    except: continue

                if product_list:
                    Medicine.objects.bulk_create(product_list, ignore_conflicts=True)
                
                self.stdout.write(f"Sayfa {page_count} bitti. ({len(product_list)} kayıt, {time.time() - start_time:.2f} sn)")

                # Sonraki sayfa
                try:
                    next_li = driver.find_element(By.ID, "tablo_next")
                    if "disabled" in next_li.get_attribute("class"):
                        self.stdout.write(self.style.SUCCESS("Tüm veriler başarıyla çekildi!"))
                        break
                    
                    next_link = next_li.find_element(By.TAG_NAME, "a")
                    # Tıklama işlemini JS ile yaparak 'interactable' hatasını bypass ediyoruz
                    driver.execute_script("arguments[0].click();", next_link)
                    
                    page_count += 1
                    time.sleep(1.2) # Hızlı internet için ideal bekleme
                except:
                    break

        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Ana döngü hatası: {e}"))
        finally:
            driver.quit()