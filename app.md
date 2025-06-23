# Dori Eslatmasi

## Ilova haqida

**Dori Eslatmasi** — bu sog'lig'ingiz uchun dorilarni o'z vaqtida ichishni eslatib turadigan zamonaviy, qulay va ishonchli mobil ilova. Ilova Flutter frameworkida yozilgan va barcha asosiy platformalarda (Android, iOS, Windows, MacOS, Linux, Web) ishlaydi.

---

## Asosiy imkoniyatlar

- **Dori qo'shish:** Dori nomi, doza, kunlik ichish soni, vaqtlar va izoh kiritish.
- **Dori ro'yxati:** Barcha dorilarni ko'rish, navbatdagi doza vaqtini ko'rsatish.
- **Dorini ichilgan deb belgilash:** Har bir dori uchun bugungi doza ichilganini belgilash.
- **Dorini tahrirlash va o'chirish:** Dorilarni oson tahrirlash va o'chirish.
- **Bildirishnomalar:** Har bir dori uchun ichishdan oldin eslatma (notification) yuboriladi.
- **Sozlamalar:** Bildirishnomalarni test qilish, tozalash va ilova haqida ma'lumot olish.
- **Zamonaviy dizayn:** Gradientlar, pill-style badge'lar, katta tugmalar, qulay interfeys.

---

## Texnik arxitektura

- **Flutter:** UI va platformalararo logika uchun.
- **SQLite (sqflite):** Dorilar va loglarni lokal saqlash uchun.
- **flutter_local_notifications:** Bildirishnomalar uchun.
- **timezone:** To'g'ri vaqt zonasi vaqtlari uchun.

### Papkalar va asosiy fayllar

- `lib/main.dart` — Ilovaning kirish nuqtasi, navigatsiya va umumiy sozlamalar.
- `lib/screens/` — Barcha asosiy ekranlar:
  - `home_screen.dart` — Dorilar ro'yxati va asosiy boshqaruv.
  - `add_medication_screen.dart` — Dori qo'shish formasi.
  - `settings_screen.dart` — Sozlamalar va notification boshqaruvi.
  - `about_screen.dart` — Ilova haqida ma'lumot.
- `lib/models/medication.dart` — Dori modeli (id, nomi, doza, vaqtlar, izoh, h.k.).
- `lib/services/database_service.dart` — SQLite bilan ishlash va notificationlarni boshqarish.
- `lib/services/notification_service.dart` — Bildirishnomalarni rejalashtirish va boshqarish.

---

## Ma'lumotlar bazasi (SQLite)

- **medications** jadvali:
  - `id` — dori ID (autoincrement)
  - `name` — dori nomi
  - `dosage` — doza
  - `frequency` — kunlik ichish soni
  - `times` — vaqtlar (json ko'rinishida)
  - `notes` — izoh
  - `createdAt` — qachon qo'shilgan
  - `isActive` — faol yoki o'chirilgan
- **medication_logs** jadvali:
  - `id` — log ID
  - `medicationId` — dori ID
  - `takenAt` — qachon ichilgan

---

## Bildirishnomalar (Notifications)

- Har bir dori uchun har bir vaqtga alohida notification rejalashtiriladi.
- Notificationlar dori ichishdan 10 daqiqa oldin yuboriladi.
- Notificationlar ilova yopiq bo'lsa ham ishlaydi (permissionlar to'g'ri bo'lsa).
- Notificationlar o'chirilgan yoki tahrirlangan dori uchun avtomatik yangilanadi.

---

## UI/UX

- **Zamonaviy dizayn:** Gradient fonlar, pill-style badge'lar, katta tugmalar, soddalashtirilgan interfeys.
- **Foydalanuvchi uchun qulaylik:** Har bir amal uchun aniq xabar (snackbar), validatsiya va ogohlantirishlar.
- **Accessibility:** Ranglar va shriftlar kontrasti, tugmalar kattaligi.

---

## Kengaytirish va moslashuvchanlik

- **Yangi maydonlar:** Dori turi, ishlab chiqaruvchi, rasm va boshqalar qo'shish mumkin.
- **Statistika:** Qancha dori ichilgan, qoldirilgan, kunlik statistika va grafiklar.
- **Bulutli sinxronizatsiya:** Google Drive yoki Firebase orqali backup va sinxronizatsiya.
- **Multi-user:** Bir nechta foydalanuvchi uchun dori eslatmalari.

---

## Ishlatish bo'yicha ko'rsatma

1. Ilovani ishga tushiring.
2. Drawer menyudan yoki asosiy ekrandan "Dori qo'shish" tugmasini bosing.
3. Dori nomi, doza, vaqtlar va izohni kiriting.
4. Saqlangandan so'ng, dori ro'yxatda paydo bo'ladi va notificationlar avtomatik rejalashtiriladi.
5. Har bir dori uchun "Ichildi" tugmasi orqali bugungi doza ichilganini belgilang.
6. Sozlamalar bo'limida notificationlarni test qilish yoki tozalash mumkin.

---

## Dasturchilar uchun

- Kod toza, modulli va kengaytirishga tayyor.
- Har bir funksiya uchun alohida servis va model ishlatiladi.
- Linter va analyzer xatoliklari yo'q.
- Platformaga xos muammolar (masalan, Android NDK, permissionlar) README va kodda ko'rsatilgan.

---

## Muallif va aloqa

- Muallif: [Sizning ismingiz yoki jamoangiz]
- Email: info@dorieslatmasi.uz
- Telegram: @dorieslatmasi

---

**Dori Eslatmasi — sog'lig'ingiz uchun ishonchli yordamchi!**
