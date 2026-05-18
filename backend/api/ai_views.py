from google import genai
import json
import time
from django.conf import settings
from django.db.models import Q
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from .models import Plant, Medicine, SellerInventory, ChatHistory
from .serializers import PlantSerializer, MedicineSerializer


# --- System Prompt: AI'ya Ziraat Mühendisi kimliği veriyoruz ---
SYSTEM_PROMPT = """
Sen deneyimli, samimi ve yardımsever bir Ziraat Mühendisisin, adın "ZiraatBot". Görevin çiftçilere tarımsal ilaçlar, gübreler, tohumlar ve bitki koruma konularında yardımcı olmaktır.
Kullanıcılara sıcak ve cana yakın bir şekilde yaklaş (Örneğin: "Merhaba, ben iyiyim! Tarım dışı konularda çok bilgim yok ama ekinleriniz için buradayım" gibi).

Kuralların:

1. SADECE tarım, ziraat ilaçları, gübreler, bitki hastalıkları, zararlılar ve ilgili konularda konuş.
2. Tarımla ilgisi olmayan sorularda kibarca ve samimi bir dille, "Bu konuda yardımcı olamıyorum, benim uzmanlık alanım tarlalar ve seralar 😊" gibi bir yanıt ver.
3. İlaç tavsiyesi verirken HER ZAMAN "Bu bilgiler genel bilgilendirme amaçlıdır. Uygulama öncesinde mutlaka bir zirai ilaç bayinize veya tarım il/ilçe müdürlüğüne danışınız." uyarısı ekle.
4. Cevaplarını Türkçe ver, çiftçilerin anlayacağı sade ve desteksiz bir dil kullan.
5. Eğer sana bir ürün bilgisi (ÜRÜN BİLGİSİ bloğu) verilmişse, cevabını mutlaka bu bilgilere dayandır.
6. Kısa, net ve anlaşılır cevaplar ver. Çiftçilerin anlayacağı sade bir dil kullan.
7. Her seferinde kendini tanıtmana gerek yok
8. " * " karakterlerini kullanma
"""


def _get_product_context(question: str) -> str:
    """
    Kullanıcının sorusundaki anahtar kelimelere göre veritabanındaki 
    ürünleri tarar ve eşleşen ürünlerin bilgisini bağlam olarak döndürür.
    """
    keywords = question.lower().split()
    
    # Search in Plants
    matched_plants = Plant.objects.none()
    for keyword in keywords:
        if len(keyword) < 3: continue
        results = Plant.objects.filter(plant_name__icontains=keyword) | \
                  Plant.objects.filter(disease_name__icontains=keyword) | \
                  Plant.objects.filter(active_ingredient__icontains=keyword)
        if results.exists():
            matched_plants = matched_plants | results
    
    # Search in Medicines
    matched_meds = Medicine.objects.none()
    for keyword in keywords:
        if len(keyword) < 3: continue
        results = Medicine.objects.filter(name__icontains=keyword) | \
                  Medicine.objects.filter(active_ingredient__icontains=keyword)
        if results.exists():
            matched_meds = matched_meds | results

    matched_plants = matched_plants.distinct()[:3]
    matched_meds = matched_meds.distinct()[:3]
    
    if not matched_plants.exists() and not matched_meds.exists():
        return ""
    
    context_parts = []
    
    for plant in matched_plants:
        context_parts.append(
            f"--- BİTKİ ÇÖZÜMÜ ---\n"
            f"Bitki: {plant.plant_name}\n"
            f"Hastalık/Zararlı: {plant.disease_name}\n"
            f"Tavsiye Edilen Etken Madde: {plant.active_ingredient}\n"
            f"Dozaj: {plant.dosage or '-'}\n"
            f"--- BİTKİ ÇÖZÜMÜ SONU ---"
        )

    for med in matched_meds:
        inventory_info = ""
        inventories = SellerInventory.objects.filter(medicine=med)
        if inventories.exists():
            inv = inventories.first()
            inventory_info = f"\n  - Fiyat: {inv.price} TL, Stok: {inv.stock_quantity} adet"
        
        context_parts.append(
            f"--- İLAÇ BİLGİSİ ---\n"
            f"İlaç Adı: {med.name}\n"
            f"Etken Madde: {med.active_ingredient}\n"
            f"Formülasyon: {med.formulation}\n"
            f"Kategori: {med.category.name if med.category else 'Belirtilmemiş'}\n"
            f"{inventory_info}\n"
            f"--- İLAÇ BİLGİSİ SONU ---"
        )
    
    return "\n\n".join(context_parts)


@api_view(['POST'])
@permission_classes([AllowAny])
def ai_ask(request):
    """
    POST /api/ai/ask/
    Body: { "question": "Magnezyum sülfat nasıl kullanılır?" }
    """
    question = request.data.get('question', '').strip()
    
    if not question:
        return Response(
            {'error': 'Lütfen bir soru giriniz.'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # API key kontrolü
    api_key = getattr(settings, 'GEMINI_API_KEY', None)
    if not api_key or api_key == 'BURAYA_API_KEY_YAPISTIRIN':
        return Response(
            {'error': 'AI servisi yapılandırılmamış. Lütfen yöneticiyle iletişime geçin.'},
            status=status.HTTP_503_SERVICE_UNAVAILABLE
        )
    
    try:
        # Gemini client oluştur (yeni google.genai SDK)
        client = genai.Client(api_key=api_key)
        
        # Ürün bağlamını (RAG) oluştur
        product_context = _get_product_context(question)
        
        # Tam mesajı oluştur
        full_prompt = SYSTEM_PROMPT
        if product_context:
            full_prompt += f"\n\nAşağıdaki ürün bilgilerini cevabında kullan:\n{product_context}"
        full_prompt += f"\n\nKullanıcının Sorusu: {question}"
        
        # Gemini'ye sor (Hata durumunda bekle ve tekrar dene)
        max_retries = 3
        answer = "Cevap alınamadı."
        
        for attempt in range(max_retries):
            try:
                response = client.models.generate_content(
                    model='gemini-2.0-flash',
                    contents=full_prompt,
                )
                answer = response.text
                break
            except Exception as inner_e:
                if attempt < max_retries - 1:
                    time.sleep(1.5)  # 1.5 saniye bekle ve tekrar dene
                else:
                    raise inner_e  # Son denemede de hata verirse yukarıya fırlat
        
        # Sohbet geçmişine kaydet (opsiyonel — ileride token ile)
        # TODO: Token-based auth ile kullanıcı belirleme
        
        return Response({
            'answer': answer,
            'has_product_context': bool(product_context),
        })
    
    except Exception as e:
        print(f"AI Error: {e}")
        return Response(
            {'error': f'AI yanıt veremedi: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([AllowAny])
def ai_history(request):
    """
    GET /api/ai/history/
    Kullanıcının sohbet geçmişini döndürür.
    """
    # TODO: Token-based auth ile kullanıcıya ait geçmişi filtrele
    return Response({'history': []})


# ═══════════════════════════════════════════════════════
# AKILLI ARAMA (AI-Powered Smart Search)
# ═══════════════════════════════════════════════════════

SMART_SEARCH_PROMPT = """Sen bir Ziraat Verileri Uzmanısın. Kullanıcıdan gelen doğal dildeki arama sorgusunu analiz ederek aşağıdaki JSON formatında filtreleme parametrelerine dönüştürmen gerekiyor.

### VERİ YAPISI:
1. Plant tablosu: plant_name, disease_name, active_ingredient, dosage
2. Medicine tablosu: name (ticari ilaç ismi), active_ingredient, formulation (SC, WP, EC vb.)

### KURALLAR:
- Bitki isimlerini BÜYÜK HARFLE yaz (ELMA, DOMATES, vb.)
- Hastalık ve zararlı isimlerini olduğu gibi yaz
- Sadece JSON döndür, başka hiçbir şey yazma
- Emin olmadığın alanları null yap

### ÇIKTI FORMATI (sadece bu JSON'u döndür):
{
  "target_table": "Plant" | "Medicine" | "Both",
  "filters": {
    "plant_name": "bitki adı veya null",
    "disease_name": "hastalık/zararlı adı veya null",
    "active_ingredient": "aktif madde veya null",
    "formulation": "SC, WP, EC vb. veya null",
    "brand_name": "ticari ilaç ismi veya null"
  },
  "search_type": "Bitki_Zararli_Eslesmesi" | "Ticari_Ilac_Arama" | "MRL_Sorgusu"
}

### KULLANICI SORGUSU:
"""


def _parse_query_with_ai(query: str, api_key: str) -> dict:
    """Gemini ile doğal dil sorgusunu yapılandırılmış filtrelere dönüştürür."""
    client = genai.Client(api_key=api_key)

    for attempt in range(2):
        try:
            response = client.models.generate_content(
                model='gemini-2.0-flash',
                contents=SMART_SEARCH_PROMPT + f'"{query}"',
            )
            raw = response.text.strip()
            # JSON bloğunu ayıkla (bazen ```json ... ``` ile sarılıyor)
            if '```' in raw:
                raw = raw.split('```')[1]
                if raw.startswith('json'):
                    raw = raw[4:]
            return json.loads(raw.strip())
        except Exception:
            if attempt == 0:
                time.sleep(1)
            continue
    return None


def _smart_query(parsed: dict) -> tuple:
    """Parsed filtrelerden Plant ve Medicine queryset'leri oluşturur."""
    filters = parsed.get('filters', {})
    target = parsed.get('target_table', 'Both')

    plants_qs = Plant.objects.none()
    meds_qs = Medicine.objects.none()

    # --- Plant sorgusu ---
    if target in ('Plant', 'Both'):
        q = Q()
        pn = filters.get('plant_name')
        dn = filters.get('disease_name')
        ai = filters.get('active_ingredient')

        if pn:
            q &= Q(plant_name__icontains=pn)
        if dn:
            q &= Q(disease_name__icontains=dn)
        if ai:
            q &= Q(active_ingredient__icontains=ai)

        if q:
            plants_qs = Plant.objects.filter(q).distinct()[:50]
        elif target == 'Plant':
            # Filtre yoksa ama hedef Plant ise genel arama
            plants_qs = Plant.objects.all()[:50]

    # --- Medicine sorgusu ---
    if target in ('Medicine', 'Both'):
        q = Q()
        bn = filters.get('brand_name')
        ai = filters.get('active_ingredient')
        fm = filters.get('formulation')

        if bn:
            q &= Q(name__icontains=bn)
        if ai:
            q &= Q(active_ingredient__icontains=ai)
        if fm:
            q &= Q(formulation__icontains=fm)

        if q:
            meds_qs = Medicine.objects.filter(q).distinct()[:50]
        elif target == 'Medicine':
            meds_qs = Medicine.objects.all()[:50]

    return plants_qs, meds_qs


@api_view(['POST'])
@permission_classes([AllowAny])
def ai_smart_search(request):
    """
    POST /api/ai/smart-search/
    Body: { "query": "Elmada karaleke için bakır içerikli ilaçlar" }
    """
    query = request.data.get('query', '').strip()

    if not query:
        return Response(
            {'error': 'Lütfen bir arama sorgusu giriniz.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    api_key = getattr(settings, 'GEMINI_API_KEY', None)
    if not api_key or api_key == 'BURAYA_API_KEY_YAPISTIRIN':
        return Response(
            {'error': 'AI servisi yapılandırılmamış.'},
            status=status.HTTP_503_SERVICE_UNAVAILABLE
        )

    try:
        # 1. Gemini ile sorguyu parse et
        parsed = _parse_query_with_ai(query, api_key)

        if not parsed:
            return Response(
                {'error': 'Sorgu analiz edilemedi. Lütfen farklı bir ifade deneyin.'},
                status=status.HTTP_422_UNPROCESSABLE_ENTITY
            )

        # 2. Veritabanını sorgula
        plants_qs, meds_qs = _smart_query(parsed)

        # 3. Serializer ile JSON'a çevir
        plants_data = PlantSerializer(plants_qs, many=True).data
        meds_data = MedicineSerializer(meds_qs, many=True).data

        return Response({
            'parsed_filters': parsed,
            'plants': plants_data,
            'plants_count': len(plants_data),
            'medicines': meds_data,
            'medicines_count': len(meds_data),
        })

    except Exception as e:
        print(f"Smart Search Error: {e}")
        return Response(
            {'error': f'Akıllı arama hatası: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
