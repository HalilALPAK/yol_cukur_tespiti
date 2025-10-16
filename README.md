# Pothole Detection with YOLO

---

## 1. English

### Project Overview

This project uses a custom-trained YOLO model (`yol_best.pt`) to detect potholes in road videos and images. The workflow includes training, testing, and visualizing pothole detections on both images and videos. Results are saved and visualized using OpenCV and Matplotlib.

### How to Use

1. **Install Requirements**
   - Python 3.8+
   - Install required packages:
     ```bash
     pip install ultralytics opencv-python matplotlib numpy
     ```
2. **Model & Data**
   - Place your trained model file as `yol_best.pt` in the workspace.
   - Place your test image (e.g., `yol_test.jpeg`) and video (e.g., `yol_test.mp4`) in the workspace.
3. **Run Inference on Image**
   - Use the provided notebook cell to run:
     ```python
     from ultralytics import YOLO
     import cv2
     import matplotlib.pyplot as plt
     model = YOLO('yol_best.pt')
     results = model('yol_test.jpeg')
     img_with_detections = results[0].plot()
     plt.imshow(cv2.cvtColor(img_with_detections, cv2.COLOR_BGR2RGB))
     plt.axis('off')
     plt.show()
     ```
4. **Run Inference on Video**

   - Use the provided notebook cell to process the video and save the result as `cukur_tespit_sonuc.mp4`.
   - The code will annotate potholes on each frame and plot statistics.

5. **N8N Webhook Integration (Advanced)**
   - Set up N8N workflow with webhook endpoint
   - Configure webhook URL in the code: `http://localhost:5678/webhook-test/[YOUR-WEBHOOK-ID]`
   - Real-time notifications with frame images sent to Telegram
   - Automatic alerts when potholes are detected

### N8N Webhook Features

- **Real-time Detection Alerts**: Instant notifications when potholes are detected
- **Frame Image Transmission**: Base64 encoded images with detection boxes
- **Telegram Integration**: Automatic messages with images sent to Telegram chat
- **JSON Payload**: Detailed information including timestamp, frame number, pothole count
- **Error Handling**: Robust connection and timeout management

### Webhook Payload Example

```json
{
  "event_type": "pothole_detected",
  "timestamp": "2025-10-16T12:43:26.968059",
  "video_timestamp": 0.04,
  "frame_number": 1,
  "pothole_count": 4,
  "detection_time": "0.0s",
  "message": "Frame 1'de 4 çukur tespit edildi!",
  "frame_image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ...",
  "frame_size": { "width": 1920, "height": 1080 }
}
```

### Output

- Annotated images and videos with detected potholes.
- Statistics and plots showing pothole counts over time.

### Sample Results

#### Image Detection

![yol_test](https://github.com/user-attachments/assets/f8f0c5c7-b01f-46d4-80af-0423bed786b6)

![test_result](https://github.com/user-attachments/assets/1182ab0b-7ef2-4eab-80f8-fdde29993b0e)

**Video features:**

- Real-time pothole counting on each frame
- Time stamps showing detection progress
- Statistics visualization showing pothole counts over time
- Output saved as annotated MP4 file
- **N8N Integration**: Webhook notifications with frame images
- **Telegram Alerts**: Automatic messages sent to Telegram with detection images

---

## 2. Türkçe

### Proje Özeti

Bu proje, özel olarak eğitilmiş bir YOLO modeli (`yol_best.pt`) ile yol videolarında ve görsellerinde çukur tespiti yapar. Akış; eğitim, test ve çukur tespitlerinin görselleştirilmesini içerir. Sonuçlar OpenCV ve Matplotlib ile kaydedilir ve görselleştirilir.

### Nasıl Kullanılır?

1. **Gereksinimleri Yükleyin**
   - Python 3.8+
   - Gerekli paketleri yükleyin:
     ```bash
     pip install ultralytics opencv-python matplotlib numpy
     ```
2. **Model ve Veri**
   - Eğitilmiş model dosyanızı `yol_best.pt` olarak workspace'e ekleyin.
   - Test görselinizi (örn. `yol_test.jpeg`) ve videonuzu (örn. `yol_test.mp4`) workspace'e ekleyin.
3. **Görselde Çukur Tespiti**
   - Notebook'taki ilgili hücreyi çalıştırın:
     ```python
     from ultralytics import YOLO
     import cv2
     import matplotlib.pyplot as plt
     model = YOLO('yol_best.pt')
     results = model('yol_test.jpeg')
     img_with_detections = results[0].plot()
     plt.imshow(cv2.cvtColor(img_with_detections, cv2.COLOR_BGR2RGB))
     plt.axis('off')
     plt.show()
     ```
4. **Videoda Çukur Tespiti**

   - Notebook'taki ilgili hücreyi çalıştırarak videoyu işleyin ve sonucu `cukur_tespit_sonuc.mp4` olarak kaydedin.
   - Kod, her karede tespit edilen çukurları işaretler ve istatistikleri çizer.

5. **N8N Webhook Entegrasyonu (İleri Seviye)**
   - N8N workflow'u webhook endpoint ile kurulum yapın
   - Kodda webhook URL'ini yapılandırın: `http://localhost:5678/webhook-test/[WEBHOOK-ID]`
   - Frame görselleri ile gerçek zamanlı Telegram bildirimleri
   - Çukur tespit edildiğinde otomatik uyarılar

### N8N Webhook Özellikleri

- **Gerçek Zamanlı Tespit Uyarıları**: Çukur tespit edildiğinde anında bildirimler
- **Frame Görsel Aktarımı**: Tespit kutuları ile base64 kodlu görüntüler
- **Telegram Entegrasyonu**: Telegram sohbetine görselli otomatik mesajlar
- **JSON Payload**: Zaman damgası, frame numarası, çukur sayısı gibi detaylı bilgiler
- **Hata Yönetimi**: Güçlü bağlantı ve timeout yönetimi

### Webhook Payload Örneği

```json
{
  "event_type": "pothole_detected",
  "timestamp": "2025-10-16T12:43:26.968059",
  "video_timestamp": 0.04,
  "frame_number": 1,
  "pothole_count": 4,
  "detection_time": "0.0s",
  "message": "Frame 1'de 4 çukur tespit edildi!",
  "frame_image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ...",
  "frame_size": { "width": 1920, "height": 1080 }
}
```

### Çıktı

- Çukur tespitli görseller ve videolar.
- Zaman içinde çukur sayısını gösteren istatistikler ve grafikler.

### Örnek Sonuçlar

#### Görsel Tespiti

![Görsel Tespit Sonucu](test_resu![yol_test](https://github.com/user-attachments/assets/6a1820dc-fa08-41ec-83bc-f9355242e698)
lt.jpg)


![test_result](https://github.com/user-attachments/assets/b894fd9f-70fd-4766-aa65-6c50b4962d43)


#### Video Tespiti


https://github.com/user-attachments/assets/8dbe1804-30b3-4a41-85c0-faa1aba89ce5



**Video özellikleri:**

- Her karede gerçek zamanlı çukur sayma
- Tespit ilerlemesini gösteren zaman damgaları
- Zaman içindeki çukur sayılarını gösteren istatistik görselleştirmesi
- Sonuç, açıklamalı MP4 dosyası olarak kaydedilir
- **N8N Entegrasyonu**: Frame görselleri ile webhook bildirimleri
- **Telegram Uyarıları**: Tespit görüntüleri ile Telegram'a otomatik mesajlar


<img width="1488" height="1012" alt="yol_tespit_telegram" src="https://github.com/user-attachments/assets/adeed9f3-046c-4762-add9-d129045b23bc" />

<img width="998" height="911" alt="yol_tespit_N8N" src="https://github.com/user-attachments/assets/53d3d784-18a8-44c8-8d02-d6c1a9debb2b" />


