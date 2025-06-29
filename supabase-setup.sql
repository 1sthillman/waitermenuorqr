-- QR Sipariş Sistemi için Supabase Veritabanı Kurulumu

-- Masalar tablosu
CREATE TABLE IF NOT EXISTS masalar (
    id SERIAL PRIMARY KEY,
    masa_no INTEGER NOT NULL UNIQUE,
    durum VARCHAR(50) DEFAULT 'boş',
    son_guncelleme TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Menü öğeleri tablosu
CREATE TABLE IF NOT EXISTS menu_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    category VARCHAR(50) NOT NULL,
    image_url TEXT,
    available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Siparişler tablosu
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_number INTEGER NOT NULL,
    status VARCHAR(50) DEFAULT 'waiting',
    source VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    is_confirmed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (table_number) REFERENCES masalar(masa_no)
);

-- Sipariş kalemleri tablosu
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL,
    menu_item_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (menu_item_id) REFERENCES menu_items(id)
);

-- Garson çağrıları tablosu
CREATE TABLE IF NOT EXISTS waiter_calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_number INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'waiting',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (table_number) REFERENCES masalar(masa_no)
);

-- QR sipariş onayları tablosu
CREATE TABLE IF NOT EXISTS qr_order_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL,
    adisyon_siparis_id INTEGER,
    approval_status VARCHAR(20) DEFAULT 'beklemede',
    notes TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- Adisyon siparişleri tablosu
CREATE TABLE IF NOT EXISTS siparisler (
    id SERIAL PRIMARY KEY,
    masa_no INTEGER NOT NULL,
    durum VARCHAR(50) DEFAULT 'beklemede',
    toplam_fiyat DECIMAL(10, 2) NOT NULL,
    siparis_notu TEXT,
    is_qr_order BOOLEAN DEFAULT FALSE,
    qr_order_id UUID,
    onay_durumu VARCHAR(20) DEFAULT 'beklemede',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (masa_no) REFERENCES masalar(masa_no),
    FOREIGN KEY (qr_order_id) REFERENCES orders(id)
);

-- Örnek masalar
INSERT INTO masalar (masa_no, durum) VALUES 
(1, 'boş'),
(2, 'boş'),
(3, 'boş'),
(4, 'boş'),
(5, 'boş'),
(6, 'boş'),
(7, 'boş'),
(8, 'boş'),
(9, 'boş'),
(10, 'boş');

-- Örnek menü öğeleri
INSERT INTO menu_items (name, description, price, category, available) VALUES 
('Mercimek Çorbası', 'Geleneksel Türk mercimek çorbası', 35.00, 'starters', TRUE),
('Ezogelin Çorbası', 'Bulgur, mercimek ve baharatlarla hazırlanan çorba', 35.00, 'starters', TRUE),
('İşkembe Çorbası', 'Özel soslu işkembe çorbası', 45.00, 'starters', TRUE),
('Karışık Salata', 'Mevsim yeşillikleri ile hazırlanmış salata', 55.00, 'starters', TRUE),
('Adana Kebap', 'Özel baharatlarla hazırlanmış ızgara kebap', 120.00, 'mains', TRUE),
('Urfa Kebap', 'Acısız özel baharatlarla hazırlanmış ızgara kebap', 120.00, 'mains', TRUE),
('Tavuk Şiş', 'Özel marine edilmiş tavuk şiş', 100.00, 'mains', TRUE),
('Karışık Izgara', 'Köfte, pirzola, şiş ve kanat karışık ızgara', 180.00, 'mains', TRUE),
('Künefe', 'Özel peynirli kadayıf tatlısı', 70.00, 'desserts', TRUE),
('Baklava', 'Fıstıklı özel baklava', 80.00, 'desserts', TRUE),
('Sütlaç', 'Fırında pişirilmiş geleneksel sütlaç', 60.00, 'desserts', TRUE),
('Ayran', 'Taze ayran', 20.00, 'drinks', TRUE),
('Kola', 'Soğuk kola', 25.00, 'drinks', TRUE),
('Çay', 'Demli çay', 15.00, 'drinks', TRUE),
('Türk Kahvesi', 'Geleneksel Türk kahvesi', 30.00, 'drinks', TRUE),
('Su', 'Soğuk su', 10.00, 'drinks', TRUE);

-- Gerçek zamanlı bildirimler için fonksiyon ve tetikleyici
CREATE OR REPLACE FUNCTION notify_order_change()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify(
    'order_change',
    json_build_object(
      'id', NEW.id,
      'table_number', NEW.table_number,
      'status', NEW.status,
      'is_confirmed', NEW.is_confirmed
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER orders_change_trigger
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION notify_order_change();

-- Garson çağrıları için fonksiyon ve tetikleyici
CREATE OR REPLACE FUNCTION notify_waiter_call()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify(
    'waiter_call',
    json_build_object(
      'id', NEW.id,
      'table_number', NEW.table_number,
      'status', NEW.status
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER waiter_call_trigger
AFTER INSERT OR UPDATE ON waiter_calls
FOR EACH ROW
EXECUTE FUNCTION notify_waiter_call();

-- RLS (Row Level Security) politikaları
ALTER TABLE masalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE waiter_calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_order_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE siparisler ENABLE ROW LEVEL SECURITY;

-- Anonim (public) erişim politikaları
CREATE POLICY "Anonim kullanıcılar masaları görebilir" ON masalar FOR SELECT USING (true);
CREATE POLICY "Anonim kullanıcılar menüyü görebilir" ON menu_items FOR SELECT USING (available = true);
CREATE POLICY "Anonim kullanıcılar sipariş oluşturabilir" ON orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Anonim kullanıcılar siparişleri görebilir" ON orders FOR SELECT USING (true);
CREATE POLICY "Anonim kullanıcılar sipariş kalemlerini ekleyebilir" ON order_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Anonim kullanıcılar sipariş kalemlerini görebilir" ON order_items FOR SELECT USING (true);
CREATE POLICY "Anonim kullanıcılar garson çağrısı oluşturabilir" ON waiter_calls FOR INSERT WITH CHECK (true);
CREATE POLICY "Anonim kullanıcılar garson çağrılarını görebilir" ON waiter_calls FOR SELECT USING (true);

-- İndeksler
CREATE INDEX IF NOT EXISTS orders_table_number_idx ON orders(table_number);
CREATE INDEX IF NOT EXISTS orders_status_idx ON orders(status);
CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON order_items(order_id);
CREATE INDEX IF NOT EXISTS waiter_calls_table_number_idx ON waiter_calls(table_number);
CREATE INDEX IF NOT EXISTS waiter_calls_status_idx ON waiter_calls(status);
CREATE INDEX IF NOT EXISTS qr_order_approvals_order_id_idx ON qr_order_approvals(order_id);
CREATE INDEX IF NOT EXISTS siparisler_masa_no_idx ON siparisler(masa_no);
CREATE INDEX IF NOT EXISTS siparisler_qr_order_id_idx ON siparisler(qr_order_id);

-- Fonksiyonlar
CREATE OR REPLACE FUNCTION get_active_orders_by_table(table_num INTEGER)
RETURNS TABLE (
    id UUID,
    table_number INTEGER,
    status VARCHAR,
    total_amount DECIMAL,
    is_confirmed BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.id, o.table_number, o.status, o.total_amount, o.is_confirmed, o.created_at
    FROM orders o
    WHERE o.table_number = table_num
    AND o.status NOT IN ('completed', 'cancelled')
    ORDER BY o.created_at DESC;
END;
$$ LANGUAGE plpgsql;
