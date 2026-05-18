import time
from django.core.management.base import BaseCommand
from api.models import Plant, Category
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support.ui import Select

class Command(BaseCommand):
    help = "Bakanlık sitesindeki tüm sayfaları gezer ve verileri PostgreSQL'e aktarır."

    def handle(self, *args, **options):
        self.stdout.write("Sistem başlatılıyor... Tarayıcı açılıyor.")
        
        driver_options = webdriver.ChromeOptions()
        driver_options.add_argument('--headless')
        driver_options.add_argument('--window-size=1920,1080')
        driver_options.add_argument('--disable-gpu')
        driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=driver_options)
        
        try:
            driver.get("https://bku.tarimorman.gov.tr/Kullanim/TavsiyeArama")
            wait = WebDriverWait(driver, 15) 

            # 1. Tablo gelince kayıt sayısını 100 yap (JS ile zorla seçtiriyoruz)
            try:
                self.stdout.write("Kayıt sayısı 100 olarak ayarlanıyor...")
                length_select_element = wait.until(EC.presence_of_element_located((By.NAME, "tablo_length")))
                
                # Elementin üzerine scroll yap (Headless modda görünürlük için)
                driver.execute_script("arguments[0].scrollIntoView();", length_select_element)
                time.sleep(1)
                
                select = Select(length_select_element)
                select.select_by_value("100")
                self.stdout.write(self.style.SUCCESS("Sayfa başına kayıt sayısı 100 yapıldı."))
                time.sleep(3) # 100 kaydın yüklenmesi için zaman tanı
            except Exception as e:
                self.stdout.write(self.style.WARNING(f"100 seçilemedi, varsayılanla devam ediliyor..."))

            category, _ = Category.objects.get_or_create(name="Genel")
            
            page_count = 1
            while True:
                self.stdout.write(f"Sayfa {page_count} taranıyor...")
                
                # Tablo satırlarının gelmesini bekle
                wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#tablo tbody tr")))
                
                rows = driver.find_elements(By.CSS_SELECTOR, "#tablo tbody tr")
                
                # Eğer ilk satırda veri yoksa döngüyü kır
                if not rows or "No records" in rows[0].text or "Eşleşen kayıt bulunamadı" in rows[0].text:
                    self.stdout.write("Çekilecek veri kalmadı.")
                    break

                for row in rows:
                    try:
                        cols = row.find_elements(By.TAG_NAME, "td")
                        if len(cols) >= 3:
                            p_name = cols[0].text.strip()
                            d_name = cols[1].text.strip()
                            ingr = cols[2].text.strip()
                            
                            # Sadece bitki adı VE hastalık adı gerçekten DOLUYSA kaydet
                            if p_name and d_name and p_name != "---":
                                Plant.objects.get_or_create(
                                    plant_name=p_name,
                                    disease_name=d_name,
                                    active_ingredient=ingr,
                                    category=category
                                )
                    except:
                        continue

                # 4. Sonraki Sayfa Mantığı
                try:
                    next_li = driver.find_element(By.ID, "tablo_next")
                    
                    if "disabled" in next_li.get_attribute("class"):
                        self.stdout.write(self.style.SUCCESS("Tüm sayfalar tarandı!"))
                        break
                    
                    next_link = next_li.find_element(By.TAG_NAME, "a")
                    driver.execute_script("arguments[0].click();", next_link)
                    
                    page_count += 1
                    time.sleep(4) # Sayfa geçiş beklemesi
                except Exception as e:
                    self.stdout.write(f"Son sayfaya gelindi veya hata: {e}")
                    break
                    
        except Exception as main_e:
            self.stdout.write(self.style.ERROR(f"Ana döngüde hata: {main_e}"))
            
        finally:
            self.stdout.write("İşlem bitti, tarayıcı kapatılıyor.")
            driver.quit()