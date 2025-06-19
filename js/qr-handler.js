// QR kod yönetimi için fonksiyonlar
const SUPABASE_URL = 'https://ooutrusdflfvbjguuhqa.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vdXRydXNkZmxmdmJqZ3V1aHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTcxMDE3NzEsImV4cCI6MjAzMjY3Nzc3MX0.M10U2uvaq7jNj6gPU9JoE9JUSpe7LOof7-yMv3qhXX4';

// Supabase istemcisini başlat
let supabase = null;
let channel = null;
let tableNumber = null;
let menuItems = {};
let cart = [];

// Kategori görselleri için varsayılan değerler
const DEFAULT_IMAGES = {
    'starters': '../img/placeholders/starter-placeholder.svg',
    'mains': '../img/placeholders/main-placeholder.svg', 
    'drinks': '../img/placeholders/drink-placeholder.svg',
    'desserts': '../img/placeholders/dessert-placeholder.svg'
};

// Debug modu
const isDebugMode = true;
const logDebug = (message, data) => {
    if (isDebugMode) {
        console.log(`[DEBUG] ${message}`, data || '');
    }
};

document.addEventListener('DOMContentLoaded', () => {
    logDebug('QR Sayfası başlatılıyor...');
    initQrPage();
});

// QR sayfasını başlat
async function initQrPage() {
    try {
        // URL'den masa numarasını al
        const urlParams = new URLSearchParams(window.location.search);
        tableNumber = urlParams.get('table');
        
        logDebug('URL parametreleri:', urlParams.toString());
        logDebug('Masa numarası:', tableNumber);
        
        if (!tableNumber) {
            showError('Masa bilgisi bulunamadı. Lütfen QR kodu tekrar okutun.');
            return;
        }
        
        // HTML elementlerini kontrol et
        const tableNumberElement = document.getElementById('tableNumber');
        if (!tableNumberElement) {
            console.error('tableNumber elementi bulunamadı');
            showError('Sayfa doğru yüklenemedi. Lütfen sayfayı yenileyin.');
            return;
        }
        
        // Masa numarasını göster
        tableNumberElement.textContent = tableNumber;
        
        logDebug('Supabase bağlantısı kuruluyor...');
        
        // Supabase bağlantısını kontrol et
        if (!window.supabase) {
            console.error('Supabase kütüphanesi yüklenemedi');
            showError('Bağlantı kurulamadı. Lütfen sayfayı yenileyin.');
            return;
        }
        
        // Supabase bağlantısını oluştur
        supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        
        logDebug('Supabase bağlantısı kuruldu');
        
        // Yükleme ekranını gizle, içeriği göster
        document.getElementById('qrPage').classList.remove('hidden');
        document.getElementById('loadingPage').classList.add('hidden');
        
        // Gerçek zamanlı bağlantıyı kur
        setupRealtimeConnection(tableNumber);
        
        // Butonlara event listener'ları ekle
        document.getElementById('callWaiterButton').addEventListener('click', () => {
            callWaiter(tableNumber);
        });
        
        // Menü öğelerini yükle
        await loadMenuItems();
        
        // Kategori butonlarını dinle
        setupCategoryButtons();
        
        // Sepet butonuna tıklama olayı ekle
        document.getElementById('viewCartButton').addEventListener('click', toggleCartPanel);
        
        // Sipariş ver butonuna tıklama olayı ekle
        document.getElementById('placeOrderButton').addEventListener('click', placeOrder);
        
    } catch (err) {
        console.error('QR kod sayfası başlatma hatası:', err);
        showError('Bir hata oluştu. Lütfen tekrar deneyin veya sayfayı yenileyin.');
    }
}

// Menü öğelerini yükle
async function loadMenuItems() {
    try {
        logDebug('Menü öğeleri yükleniyor...');
        
        const { data, error } = await supabase
            .from('menu_items')
            .select('*')
            .eq('available', true)
            .order('category');
            
        if (error) {
            console.error('Menü öğeleri yüklenirken hata:', error);
            showError('Menü yüklenemedi. Lütfen sayfayı yenileyin.');
            return;
        }
        
        logDebug('Menü öğeleri yüklendi:', data ? data.length : 0);
        
        if (!data || data.length === 0) {
            document.getElementById('menuItemsContainer').innerHTML = '<p class="text-center py-4">Menüde ürün bulunamadı.</p>';
            return;
        }
        
        // Menü öğelerini işle ve UI'ı güncelle
        processMenuItems(data);
        
        // Gerçek zamanlı menü güncellemelerini dinle
        setupMenuRealtimeSubscription();
        setupProductRealtimeSubscription();
        
    } catch (err) {
        console.error('Menü yükleme hatası:', err);
        showError('Menü yüklenirken bir hata oluştu. Lütfen sayfayı yenileyin.');
    }
}

// Gerçek zamanlı bağlantıyı kur
function setupRealtimeConnection(tableNumber) {
    channel = supabase.channel(`table-${tableNumber}`)
        .on('broadcast', { event: 'waiter-response' }, (payload) => {
            if (payload.payload.tableNumber === tableNumber) {
                showWaiterResponse(payload.payload.message);
            }
        })
        .subscribe((status) => {
            console.log('Realtime bağlantı durumu:', status);
        });
}

// Garson çağırma fonksiyonu
async function callWaiter(tableNumber) {
    try {
        const callButton = document.getElementById('callWaiterButton');
        callButton.disabled = true;
        callButton.innerHTML = '<i class="ri-loader-2-line animate-spin mr-2"></i> Garson çağrılıyor...';
        
        // Önce masa ID'sini bul
        const { data: tableData, error: tableError } = await supabase
            .from('masalar')
            .select('id')
            .eq('masa_no', tableNumber)
            .single();
            
        if (tableError) {
            console.error('Masa ID bulunamadı:', tableError);
            showError('Garson çağrılırken bir hata oluştu.');
            callButton.disabled = false;
            callButton.innerHTML = '<i class="ri-user-voice-line mr-2"></i> Garsonu Çağır';
            return;
        }
        
        // Garson çağrı kaydını oluştur
        const { data, error } = await supabase
            .from('waiter_calls')
            .insert([
                { 
                    table_id: tableData.id,
                    table_number: tableNumber,
                    status: 'waiting',
                    created_at: new Date().toISOString()
                }
            ]);
            
        if (error) {
            console.error('Garson çağırma hatası:', error);
            showError('Garson çağrılırken bir hata oluştu.');
            callButton.disabled = false;
            callButton.innerHTML = '<i class="ri-user-voice-line mr-2"></i> Garsonu Çağır';
            return;
        }
            
        // Bildirim gönder
        await supabase.channel('waiter-notifications')
            .send({
                type: 'broadcast',
                event: 'waiter-call',
                payload: { 
                    tableNumber: tableNumber,
                    status: 'waiting',
                    time: new Date().toISOString()
                }
            });
            
        showSuccess('Garson çağrınız alındı. En kısa sürede sizinle ilgileneceğiz.');
        
        // 30 saniye sonra butonu tekrar aktif et
        setTimeout(() => {
            callButton.disabled = false;
            callButton.innerHTML = '<i class="ri-user-voice-line mr-2"></i> Garsonu Çağır';
        }, 30000);
        
    } catch (err) {
        console.error('Garson çağırma hatası:', err);
        showError('Bir hata oluştu. Lütfen tekrar deneyin.');
        
        const callButton = document.getElementById('callWaiterButton');
        callButton.disabled = false;
        callButton.innerHTML = '<i class="ri-user-voice-line mr-2"></i> Garsonu Çağır';
    }
}

// Uyarı mesajı göster
function showError(message) {
    const errorAlert = document.getElementById('errorAlert');
    errorAlert.textContent = message;
    errorAlert.classList.remove('hidden');
    
    setTimeout(() => {
        errorAlert.classList.add('hidden');
    }, 5000);
}

// Başarı mesajı göster
function showSuccess(message) {
    const successAlert = document.getElementById('successAlert');
    successAlert.textContent = message;
    successAlert.classList.remove('hidden');
    
    setTimeout(() => {
        successAlert.classList.add('hidden');
    }, 5000);
}

// Garsonun cevabını göster
function showWaiterResponse(message) {
    const responseAlert = document.getElementById('waiterResponseAlert');
    responseAlert.textContent = message || 'Garsonunuz geliyor.';
    responseAlert.classList.remove('hidden');
    
    setTimeout(() => {
        responseAlert.classList.add('hidden');
    }, 8000);
} 