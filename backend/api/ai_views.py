from google import genai
import time
from django.conf import settings
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from .models import Product, SellerInventory, ChatHistory


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
    
    matched_products = Product.objects.none()
    
    # Tüm anahtar kelimeleri dene
    for keyword in keywords:
        if len(keyword) < 3:  # Çok kısa kelimeleri atla
            continue
        results = Product.objects.filter(name__icontains=keyword) | \
                  Product.objects.filter(active_ingredient__icontains=keyword)
        if results.exists():
            matched_products = matched_products | results
    
    matched_products = matched_products.distinct()[:5]  # En fazla 5 ürün
    
    if not matched_products.exists():
        return ""
    
    context_parts = []
    for product in matched_products:
        inventory_info = ""
        inventories = SellerInventory.objects.filter(product=product)
        if inventories.exists():
            inv = inventories.first()
            inventory_info = f"\n  - Fiyat: {inv.price} TL, Stok: {inv.stock_quantity} adet"
        
        context_parts.append(
            f"--- ÜRÜN BİLGİSİ ---\n"
            f"Ürün Adı: {product.name}\n"
            f"Etken Madde: {product.active_ingredient}\n"
            f"Kategori: {product.category.name if product.category else 'Belirtilmemiş'}\n"
            f"Kullanım Talimatı: {product.usage_instructions}\n"
            f"{inventory_info}\n"
            f"--- ÜRÜN BİLGİSİ SONU ---"
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
                    model='gemini-2.5-flash',
                    contents=full_prompt,
                )
                answer = response.text
                break
            except Exception as inner_e:
                if attempt < max_retries - 1:
                    time.sleep(1.5)  # 1.5 saniye bekle ve tekrar dene
                else:
                    raise inner_e  # Son denemede de hata verirse yukarıya fırlat
        
        # Sohbet geçmişine kaydet (opsiyonel, giriş yapmışsa)
        if request.user and request.user.is_authenticated:
            ChatHistory.objects.create(
                user=request.user,
                question=question,
                answer=answer,
                product_context=product_context[:500] if product_context else "",
            )
        
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
    if not request.user or not request.user.is_authenticated:
        return Response({'history': []})
    
    history = ChatHistory.objects.filter(user=request.user).order_by('-created_at')[:50]
    data = [
        {
            'id': h.id,
            'question': h.question,
            'answer': h.answer,
            'created_at': h.created_at.isoformat(),
        }
        for h in history
    ]
    return Response({'history': data})
